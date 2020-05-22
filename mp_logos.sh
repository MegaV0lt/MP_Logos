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
VERSION=200522

# Sämtliche Einstellungen werden in der *.conf vorgenommen.
# ---> Bitte ab hier nichts mehr ändern! <---

### Variablen
SELF="$(readlink /proc/$$/fd/255)" || SELF="$0"  # Eigener Pfad (besseres $0)
SELF_NAME="${SELF##*/}"
printf -v RUNDATE '%(%d.%m.%Y %R)T' -1 # Aktuelles Datum und Zeit

### Funktionen
f_log() {     # Gibt die Meldung auf der Konsole und im Syslog aus
  [[ -n "$LOGGER" ]] && { "$LOGGER" --stderr --tag "$SELF_NAME" "$*" ;} || echo "$*"
  [[ -n "$LOGFILE" ]] && echo "$*" >> "$LOGFILE"  # Log in Datei
}

f_process_channellogo() {  # Verlinken der Senderlogos zu den gefundenen Kanälen
  local CHANNEL_PATH EXT='png' LOGO_FILE
  for var in FILE CHANNEL[*] MODE ; do
    [[ -z "${!var}" ]] && { f_log "Fehler: Variable $var ist nicht gesetzt!" ; exit 1 ;}
  done
  if [[ "$USE_SVG" == 'true' ]] ; then  # Die Originalen *.svg-Logos verwenden
    EXT='svg'  # Erweiterung der Logo-Datei
    if [[ "$LOGO_VARIANT" =~ 'Light' ]] ; then
      LOGO_FILE="${MP_LOGODIR}/${MODE}/${FILE%.*}.${EXT}"  # Light
    else
      LOGO_FILE="${MP_LOGODIR}/${MODE}/${FILE%.*} - Dark.${EXT}"  # Dark
      if [[ ! -e "$LOGO_FILE" ]] ; then
        f_log "==> Logo $LOGO_FILE nicht gefunden! Verwende 'Light'-Version."
        LOGO_FILE="${MP_LOGODIR}/${MODE}/${FILE%.*}.${EXT}"  # Fallback auf Light
      fi
    fi
  else  # Normaler Modus mit PNG-Logos
    LOGO_FILE="${MP_LOGODIR}/${MODE}/${LOGO_VARIANT}/${FILE}"
  fi
  [[ ! -e "$LOGO_FILE" ]] && { f_log "!!> Logo nicht gefunden! (${LOGO_FILE})" ; return ;}
  for channel in "${CHANNEL[@]}" ; do  # Einem Logo können mehrere Kanäle zugeordnet sein
    channel="${channel//\&amp;/\&}"    # HTML-Zeichen ersetzen
    if [[ "${TOLOWER:-ALL}" == 'ALL' ]] ; then
      channel="${channel,,}.${EXT}"    # Alles in kleinbuchstaben und mit .png
    else
      channel="${channel,,[A-Z]}.${EXT}"  # Nur A-Z in kleinbuchsaben
    fi
    if [[ "$LOGO_FILE" -nt "${LOGODIR}/${channel}" ]] ; then
      if [[ "$channel" =~ / ]] ; then  # Kanal mit / im Namen
        CHANNEL_PATH="${channel%%/*}"  # Der Teil vor dem lezten /
        mkdir --parents "${LOGODIR}/${CHANNEL_PATH}"
      fi
      f_log "Verlinke neue Datei (${FILE}) mit $channel" ; ((N_LOGO+=1))
      rm "${LOGODIR}/${channel}" &>/dev/null
      ln --symbolic "$LOGO_FILE" "${LOGODIR}/${channel}"  # Symlink erstellen
    fi
  done
}

f_element_in () {  # Der Suchstring ist das erste Element; der Rest das zu durchsuchende Array
  for e in "$@:2" ; do [[ "$e" = "$1" ]] && return 0 ; done
  return 1
}

### Start
SCRIPT_TIMING[0]=$SECONDS  # Startzeit merken (Sekunden)
f_log "==> $RUNDATE - $SELF_NAME #${VERSION} - Start..."

# Testen, ob Konfiguration angegeben wurde (-c …)
while getopts ":c:" opt ; do
  case "$opt" in
    c) CONFIG="$OPTARG"
       if [[ -f "$CONFIG" ]] ; then  # Konfig wurde angegeben und existiert
         source "$CONFIG" ; CONFLOADED='Angegebene' ; break
       else
         f_log "Fehler! Die angegebene Konfigurationsdatei fehlt! (\"${CONFIG}\")"
         exit 1
       fi
    ;;
    ?) ;;
  esac
done

# Konfigurationsdatei laden [Wenn Skript=mp_logos.sh Konfig=mp_logos.conf]
if [[ -z "$CONFLOADED" ]] ; then  # Konfiguration wurde noch nicht geladen
  # Suche Konfig im aktuellen Verzeichnis, im Verzeichnis des Skripts und im eigenen etc
  CONFIG_DIRS=('.' "${SELF%/*}" "${HOME}/etc" "${0%/*}") ; CONFIG_NAME="${SELF_NAME%.*}.conf"
  for dir in "${CONFIG_DIRS[@]}" ; do
    CONFIG="${dir}/${CONFIG_NAME}"
    if [[ -f "$CONFIG" ]] ; then
      source "$CONFIG" ; CONFLOADED='Gefundene'
      break  # Die erste gefundene Konfiguration wird verwendet
    fi
  done
  if [[ -z "$CONFLOADED" ]] ; then  # Konfiguration wurde nicht gefunden
    f_log "Fehler! Keine Konfigurationsdatei gefunden! (\"${CONFIG_DIRS[*]}\")" >&2
    exit 1
  fi
fi

f_log "$CONFLOADED Konfiguration: ${CONFIG}"
if [[ "${LOGO_VARIANT:=Light}" == 'Simple' ]] ; then  # Leere oder veraltete Variable
  f_log "!!!> Variable LOGO_VARIANT mit veralteten Wert 'Simple'!"
  f_log "!!!> Verwende den Vorgabewert 'Light'. Bitte Konfiguration anpassen!"
  LOGO_VARIANT='Light'  # Vorgabewert setzen
fi
LOGO_VARIANT=".$LOGO_VARIANT"  # Anpassung an Ordnerstruktur im GIT
[[ ! -e "$MP_LOGODIR" ]] && { f_log "==> Logo-Ordner (GIT) fehlt! (${MP_LOGODIR})" ; exit 1 ;}
[[ ! -e "$LOGODIR" ]] && { f_log "==> Logo-Ordner fehlt! (${LOGODIR})" ; exit 1 ;}

# Kanallogos (GIT) aktualisieren
cd "$MP_LOGODIR" || exit 1
git pull >> "${LOGFILE:-/dev/null}"

[[ ! -d "${MP_LOGODIR}/TV/${LOGO_VARIANT}" ]] && { f_log "Fehler: Ordner $LOGO_VARIANT fehlt!" ; exit 1 ;}

mapfile -t mapping < "$MAPPING"  # Sender-Mapping in Array einlesen
if [[ -n "$CHANNELSCONF" ]] ; then
  mapfile -t channelsconf < "$CHANNELSCONF"  # Kanalliste in Array einlesen
  for i in "${!channelsconf[@]}" ; do
    channelsconf[i]="${channelsconf[i]%%;*}"  # Nur den Kanalnamen
  done
fi
shopt -s extglob

for line in "${mapping[@]}" ; do
  case $line in
    *'<TV>'*) MODE='TV' ;;                     # TV
    *'<Radio>'*) MODE='Radio' ;;               # Radio
    *'<Channel>'*)                             # Neuer Kanal
      unset -v 'ITEM_NOPROV' 'ITEM' 'PROVIDER' 'FILE' 'CHANNEL'
    ;;
    *'Item'*'/>'*)                             # Item (Kanal) ohne Provider
      ITEM_NOPROV="${line#*Name=\"}" ; ITEM_NOPROV="${ITEM_NOPROV%\"*}"
      if [[ -n "$CHANNELSCONF" ]] ; then
        if f_element_in "$ITEM_NOPROV" "${channelsconf[@]}" ; then
          CHANNEL+=("$ITEM_NOPROV") ; ((NOPROV+=1))  # Kanal zur Liste
        fi
      fi
      [[ -z "$PROV" ]] && CHANNEL+=("$ITEM_NOPROV")  # Provider nicht gesetzt
    ;;
    *'Item Name'*'">'*)                        # Item (Kanal)
      ITEM="${line#*Name=\"}" ; ITEM="${ITEM%\"*}"
    ;;
    *'<Provider>'*)                            # Ein oder mehrere Provider
      PROVIDER="${line#*<Provider>}" ; PROVIDER="${PROVIDER%</Provider>*}"
      [[ "$PROVIDER" == "$PROV" || -z "$PROV" ]] && CHANNEL+=("$ITEM")
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
    ;;
    *) ;;
  esac
done

find "$LOGODIR" -xtype l -delete >> "${LOGFILE:-/dev/null}"  # Alte (defekte) Symlinks löschen

[[ -n "$PROV" ]] && f_log "==> ${NO_CHANNEL:-Keine} Kanäle ohne Provider (${PROV})"
[[ -n "$CHANNELSCONF" ]] &&f_log "==> ${NOPROV:-0} Kanäle ohne Provider wurden in der Kanalliste gefunden und verlinkt"
f_log "==> ${N_LOGO:-0} neue oder aktualisierte Kanäle verlinkt (Vorhandene Logos: ${LOGO})"
SCRIPT_TIMING[2]=$SECONDS  # Zeit nach der Statistik
SCRIPT_TIMING[10]=$((SCRIPT_TIMING[2] - SCRIPT_TIMING[0]))  # Gesamt
f_log "==> Skriptlaufzeit: $((SCRIPT_TIMING[10] / 60)) Minute(n) und $((SCRIPT_TIMING[10] % 60)) Sekunde(n)"
      
if [[ -e "$LOGFILE" ]] ; then       # Log-Datei umbenennen, wenn zu groß
  FILESIZE="$(stat --format=%s "$LOGFILE")"
  [[ $FILESIZE -gt $MAXLOGSIZE ]] && mv --force "$LOGFILE" "${LOGFILE}.old"
fi

exit
