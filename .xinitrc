xset r rate 300 50 &
setxkbmap -layout pl &
setxkbmap -layout pl -option caps:swapescape &

while true
do
        TIME=$(date +"%A %Y-%m-%d %I:%M %p")
        TIME="$TIME $(date -u +"(%H:%M UTC)")"
        VOL=$(amixer get Master | tail -1 | sed 's/.*\[\([0-9]*%\)\].*/\1/')
        IP=$(for i in `ip r`; do echo $i; done | grep -A 1 src | tail -n1) # can get confused if you use vmware
        TEMP="$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))C"
        MPD="$(echo `mpc --format \[%title%]\ | head -n 1`)"

        if acpi -a | grep off-line > /dev/null
        then
                BAT="Bat. $(acpi -b | awk '{ print $4 " " $5 }' | tr -d ',')"
                xsetroot -name "$MPD $IP $BAT $VOL $TEMP  $(date)"
        else
                xsetroot -name "$MPD $IP $VOL $TEMP  $(date)"
        fi
        sleep 5s
done &

clipmenud &

exec dwm
