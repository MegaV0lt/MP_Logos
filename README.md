# MP_Logos

Skript zum verlinken der Mediaportal-Kanallogos

Man benötigt das folgende GIT lokal auf der Festplatte:
https://github.com/Jasmeet181/mediaportal-de-logos

Die Dateinamen passen nicht zum VDR-Schema. Darum liest das Skript die im GIT liegende 'LogoMapping.xml' aus um die Logos dann passend zu verlinken. Im Logoverzeichnis des Skins liegen dann nur Symlinks.

Die Logos liegen im PNG-Format und mit 190 Pixel Breite vor. Es müssen die Varialen 'LOGODIR' und 'MP_LOGODIR' angepasst werden. Das Skript am besten ein mal pro Woche ausführen (/etc/cron.weekly)

Wenn keine Logdatei benötigt wird, dann einfach LOGFILE auskommentieren
