#!/bin/bash

# Skript zum verlinken der Mediaportal-Kanallogos

# Man benötigt das folgende GIT lokal auf der Festplatte:
# https://github.com/Jasmeet181/mediaportal-de-logos

# Die Dateinamen passen nicht zum VDR-Schema. Darum liest das Skript
# die im GIT liegende 'LogoMapping.xml' aus um die Logos dann passend zu 
# verlinken. Im Logoverzeichnis des Skins liegen dann nur Symlinks.

# Die Logos liegen im PNG-Format und mit 190 Pixel Breite vor
# Es müssen die Varialen 'LOGODIR' und 'MP_LOGODIR' angepasst werden.
# Das Skript am besten ein mal pro Woche ausführen (/etc/cron.weekly)

# Wenn keine Logdatei benötigt wird, dann einfach LOGFILE auskommentieren
VERSION=200413

### Variablen
LOGODIR='/usr/local/src/_div/flatpluslogos'                # Logos für SkinFlatPlus
MP_LOGODIR='/usr/local/src/_div/mediaportal-de-logos.git'  # GIT
LOGO_VARIANT='Simple'  # Logos für dunklen oder hellen Hintergrund ('Simple' oder 'Dark')
MAPPING='LogoMapping.xml'              # Mapping der Sender zu den Logos
PROV='Astra 19.2E'                     # Provider (Siehe LogoMapping.xml)
SELF="$(readlink /proc/$$/fd/255)" || SELF="$0"  # Eigener Pfad (besseres $0)
SELF_NAME="${SELF##*/}"
CHANNELSCONF='/etc/vdr/channels.conf'  # VDR's Kanalliste
LOGGER='logger'                        # Logger oder auskommentieren für 'echo'
LOGFILE="/var/log/${SELF_NAME%.*}.log" # Log-Datei 
MAXLOGSIZE=$((1024*50))                # Log-Datei: Maximale Größe in Byte
printf -v RUNDATE '%(%d.%m.%Y %R)T' -1 # Aktuelles Datum und Zeit
#TEMPDIR=$(mktemp --directory)          # Temp-Dir im RAM

### Funktionen
f_log() {     # Gibt die Meldung auf der Konsole und im Syslog aus
  [[ -n "$LOGGER" ]] && { "$LOGGER" --stderr --tag "$SELF_NAME" "$*" ;} || echo "$*"
  [[ -n "$LOGFILE" ]] && echo "$*" >> "$LOGFILE"  # Log in Datei
}

f_process_channellogo() {  # Verlinken der Senderlogos zu den gefundenen Kanälen
  local CHANNEL_PATH LOGO_FILE
  if [[ -z "$FILE" || -z "${CHANNEL[*]}" ]] ; then
    f_log "Fehler: Logo (${FILE:-NULL}) oder Kanal (${CHANNEL[*]:-NULL}) nicht definiert!"
    exit 1
  fi
  [[ -z "$MODE" ]] && { f_log "Fehler: Variable MODE nicht gesetzt!" ; exit 1 ;}
  LOGO_FILE="${MP_LOGODIR}/${MODE}/${LOGO_VARIANT}/${FILE}"
    
  for channel in "${CHANNEL[@]}" ; do  # Einem Logo können mehrere Kanäle zugeordnet sein
    channel="${channel//\&amp;/\&}"    # HTML-Zeichen ersetzen
    channel="${channel,,}.png"         # Alles in kleinbuchstaben und mit .png
    if [[ "$LOGO_FILE" -nt "${LOGODIR}/${channel}" ]] ; then
      if [[ "$channel" =~ / ]] ; then  # Kanal mit / im Namen
        CHANNEL_PATH="${channel%%/*}"  # Der Teil vor dem lezten /
        mkdir --parent "${LOGODIR}/${CHANNEL_PATH}"
      fi
      f_log "Verlinke neue Datei (${FILE}) mit $channel" ; ((N_LOGO+=1))
      rm "${LOGODIR}/${channel}" &>/dev/null
      ln --symbolic "$LOGO_FILE" "${LOGODIR}/${channel}"  # Symlink erstellen
    fi
    find "$LOGODIR" -xtype l -delete >> "${LOGFILE:-/dev/null}"  # Alte (defekte) Symlinks löschen
  done
}

f_element_in () {  # Der Suchstring ist das erste Element; der Rest das zu durchsuchende Array
  for e in "$@:2" ; do [[ "$e" = "$1" ]] && return 0 ; done
  return 1
}

### Start
[[ -n "$LOGFILE" ]] && f_log "==> $RUNDATE - $SELF_NAME #${VERSION} - Start..."
[[ ! -e "$MP_LOGODIR" ]] && f_log "==> Logo-Dir not found! (${MP_LOGODIR})" && exit 1
[[ ! -e "$LOGODIR" ]] && f_log "==> Logo-Dir not found! (${LOGODIR})" && exit 1

# Kanallogos (GIT) aktualisieren
cd "$MP_LOGODIR" || exit 1
git pull >> "${LOGFILE:-/dev/null}"

mapfile -t mapping < "$MAPPING"  # Sender-Mapping in Array einlesen
mapfile -t channelsconf < "$CHANNELSCONF"  # Kanalliste in Array einlesen
for i in "${!channelsconf[@]}" ; do
  channelsconf[i]="${channelsconf[i]%%;*}"  # Nur den Kanalnamen
done
shopt -s extglob

for line in "${mapping[@]}" ; do
  case $line in
    *'<TV>'*) MODE='TV' ;;                     # TV
    *'<Radio>'*) MODE='Radio' ;;               # Radio
    *'<Channel>'*)                             # Neuer Kanal
      unset -v 'ITEM_NOPROV' 'ITEM' 'PROVIDER' 'FILE'
    ;;
    *'Item'*'/>'*)                             # Item (Kanal) ohne Provider
      ITEM_NOPROV="${line#*Name=\"}" ; ITEM_NOPROV="${ITEM_NOPROV%\"*}"
      if f_element_in "$ITEM_NOPROV" "${channelsconf[@]}" ; then
        CHANNEL+=("$ITEM_NOPROV")              # Kanal zur Liste
        ((NOPROV+=1))
      fi
    ;;
    *'Item Name'*'">'*)                        # Item (Kanal)
      ITEM="${line#*Name=\"}" ; ITEM="${ITEM%\"*}"
    ;;
    *'<Provider>'*)                            # Ein oder mehrere Provider
      PROVIDER="${line#*<Provider>}" ; PROVIDER="${PROVIDER%</Provider>*}"
      [[ "$PROVIDER" == "$PROV" ]] && CHANNEL+=("$ITEM")
    ;;
    *'<File>'*)                                # Logo-Datei
      FILE="${line#*<File>}" ; FILE="${FILE%</File>*}"
      ((LOGO+=1))
    ;;
    *'</Channel>'*)                            # Kanal-Ende
      if [[ -z "${CHANNEL[*]}" ]] ; then
        ((NO_CHANNEL+=1))
      else
        f_process_channellogo                  # Logo verlinken
      fi
      unset -v 'CHANNEL'
    ;;
    *) ;;
  esac
done

f_log "==> ${NO_CHANNEL:-0} von ${LOGO:-0} Logos ohne Kanal auf $PROV"
f_log "==> ${NOPROV:-0} Kanäle ohne Provider in der Kanalliste gefunden"
f_log "==> ${N_LOGO:-0} neue oder aktualisierte Logos verlinkt"

if [[ -e "$LOGFILE" ]] ; then       # Log-Datei umbenennen, wenn zu groß
  FILESIZE="$(stat --format=%s "$LOGFILE")"
  [[ $FILESIZE -gt $MAXLOGSIZE ]] && mv --force "$LOGFILE" "${LOGFILE}.old"
fi

#rm -rf "$TEMPDIR"

exit
