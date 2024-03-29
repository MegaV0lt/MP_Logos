# MP_Logos

Skript zum verlinken der Mediaportal-Kanallogos von "Jasmeet181"

Man benötigt das folgende GIT lokal auf der Festplatte:
https://github.com/Jasmeet181/mediaportal-de-logos

Die Logos liegen im PNG-Format und mit 190 Pixel Breite vor. 

Die Dateinamen passen nicht zum VDR-Schema. Darum liest das Skript die im GIT liegende 'LogoMapping.xml' aus um die Logos dann passend zu den Kanalnamen zu verlinken. Im Logoverzeichnis des Skins liegen dann nur Symlinks.

Zusätzlich kann man auf Wunsch die Logos mit einem Hintergrund versehen. In diesem Fall werden die Logos im Unterordner logos im Logoverzeichnis erstellt und verlinkt

Liste der Hintergründe und Auflösungen (Ordner backgrounds):
> 70x53: black, blue, reflection, transparent, white
> 
> 100x60: black, blue, reflection, transparent, white
> 
> 220x132: black, blue, reflection, transparent, white
> 
> 256x256: grey, reflection, transparent
> 
> 400x170: transparent
> 
> 400x240: blue, transparent
> 
> 800x450: transparent

Alle Einstellungen erfolgen in der *.conf. Eine Beispieldatei ligt bei (Umbenennen nach *.conf).

Die Konfigurationsdatei wird erwartet entweder im Skrptverzeichnis, im aktuellen Verzeichnis oder im eigenen /etc

Empfohen ist, die mp_logos.conf.dist nach ~/etc/mp_logos.conf zu kopieren.

Wenn das Skript via cron.weekly ausgeführt wird, kann es sein, dass die Varible 'HOME' auf '/' gesetzt wird. In dem Fall die Konfiguration nach /etc kopieren, bzw. zusätzlich verlinken.

Es _müssen_ die Varialen 'LOGODIR' und 'MP_LOGODIR' angepasst werden. Wenn keine Logdatei gewünscht, einfach 'LOGFILE' auskommentieren.
Das Skript am besten ein mal pro Woche ausführen (/etc/cron.weekly).

Es ist möglich eine Konfigurationsdatei (*.conf) mit -c ... anzugeben. Diese Datei wird dann verwendet.
Beispiel: 
> mp_logos.sh -c MySettings.conf
