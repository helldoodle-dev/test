#!/usr/bin/env bash

clear

INTERVAL=1
iface=$(ip route | awk '/default/ {print $5; exit}')

prev_rx=$(cat /sys/class/net/$iface/statistics/rx_bytes)
prev_tx=$(cat /sys/class/net/$iface/statistics/tx_bytes)

tput civis   # скрыть курсор
trap "tput cnorm; exit" INT TERM

while true; do
    tput cup 0 0   # вернуть курсор в начало вместо clear

    # CPU
    cpu=$(top -bn1 | awk '/Cpu\(s\)/ {print 100-$8 "%"}')

    # Load
    load=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

    # RAM
    ram=$(free -m | awk '/Mem:/ {printf "%d/%d MB (%.1f%%)", $3, $2, $3/$2*100}')

    # Swap
    swap=$(free -m | awk '/Swap:/ {printf "%d/%d MB (%.1f%%)", $3, $2, ($2==0?0:$3/$2*100)}')

    # Disk
    disk=$(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')

    # Network
    rx=$(cat /sys/class/net/$iface/statistics/rx_bytes)
    tx=$(cat /sys/class/net/$iface/statistics/tx_bytes)

    rx_speed=$(( (rx-prev_rx)/1024 ))
    tx_speed=$(( (tx-prev_tx)/1024 ))

    prev_rx=$rx
    prev_tx=$tx

    printf "=========== SERVER MONITOR (%s) ===========\n\n" "$(date '+%H:%M:%S')"
    printf "%-15s %s\n" "CPU:" "$cpu"
    printf "%-15s %s\n" "Load avg:" "$load"
    printf "%-15s %s\n" "RAM:" "$ram"
    printf "%-15s %s\n" "Swap:" "$swap"
    printf "%-15s %s\n" "Disk (/):" "$disk"
    printf "%-15s ↓ %d KB/s ↑ %d KB/s (%s)\n" "Network:" "$rx_speed" "$tx_speed" "$iface"

    echo
    echo "Top CPU processes:"
    ps -eo pid,comm,%cpu --sort=-%cpu | head -6

    echo
    echo "Top RAM processes:"
    ps -eo pid,comm,%mem --sort=-%mem | head -6

    sleep $INTERVAL
done

