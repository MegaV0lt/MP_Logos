# MP_Logos

Skript zum verlinken der Mediaportal-Kanallogos von "Jasmeet181"

Man benötigt das folgende GIT lokal auf der Festplatte:
https://github.com/Jasmeet181/mediaportal-de-logos

Die Dateinamen passen nicht zum VDR-Schema. Darum liest das Skript die im GIT liegende 'LogoMapping.xml' aus um die Logos dann passend zu den Kanalnamen zu verlinken. Im Logoverzeichnis des Skins liegen dann nur Symlinks.

Die Logos liegen im PNG-Format und mit 190 Pixel Breite vor. 

Alle Einstellungen erfolgen in der *.conf. Eine Beispieldatei ligt bei (Umbenennen nach *.conf).

Die Konfigurationsdatei wird erwartet entweder im Skrptverzeichnis, im aktuellen Verzeichnis oder im eigenen /etc

Empfohen ist, die mp_logos.conf.dist nach ~/etc/mp_logos.conf zu kopieren.

Wenn das Skript via cron.weekly ausgeführt wird, kann es sein, dass die Varible 'HOME' auf '/' gesetzt wird. In dem Fall die Konfiguration nach /etc kopieren, bzw. zusätzlich verlinken.

Es _müssen_ die Varialen 'LOGODIR' und 'MP_LOGODIR' angepasst werden. Wenn keine Logdatei gewünscht, einfach 'LOGFILE' auskommentieren.
Das Skript am besten ein mal pro Woche ausführen (/etc/cron.weekly).

Es ist möglich eine Konfigurationsdatei (*.conf) mit -c ... anzugeben. Diese Datei wird dann verwendet.
Beispiel: 
> mp_logos.sh -c MySettings.conf
