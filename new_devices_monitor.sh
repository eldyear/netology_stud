#!/bin/bash

STATUS_FILE="known_devices.txt"
TEMP_FILE="current_devices.txt"
LOG_FILE="devices.log"
TIMESTAMP=$(date +"[%d.%m.%Y %H:%M:%S]")


if [ ! -f $STATUS_FILE ]; then
    touch $STATUS_FILE
fi

CLEAN_LIST=$(cat /proc/bus/input/devices | grep "^N:" | sed 's/^N: Name="//' | sed 's/"$//' | sort)

echo "$CLEAN_LIST" > "$TEMP_FILE"

NEW_DEVICES=$(comm -13 "$STATUS_FILE" "$TEMP_FILE")

FORMATTED_TABLE=$(
    echo "=========================================================================================="
    printf "| %-50s | %-10s | %-20s |\n" "УСТРОЙСТВО (NAME)" "VENDOR ID" "HANDLER(S)"
    echo "=========================================================================================="
    cat /proc/bus/input/devices | awk '
        BEGIN {
            FORMAT="| %-50.48s | %-10s | %-20s |\n";
        }
        /^N:/ {
            name=$0;
            sub(/^N: Name="/, "", name);
            sub(/"$/, "", name);
        }
        /^I:/ {
            vendor = ""; handlers = "";
            vendor=$0;
            sub(/.*Vendor=/, "", vendor);
            sub(/ Product.*/, "", vendor);
        }
        /^H:/ {
            handlers=$0;
            sub(/^H: Handlers=/, "", handlers);
            printf FORMAT, name, vendor, handlers;
        }'
)

NEW_COUNT=$(echo "$NEW_DEVICES" | grep -c .)

if [ "$NEW_COUNT" -gt 0 ]; then
    echo "$TIMESTAMP Всего новых устройств: $NEW_COUNT" >> "$LOG_FILE"
    echo "Новые устройства:" >> "$LOG_FILE"
    echo "$NEW_DEVICES" >> "$LOG_FILE"
    echo "==============================================" >> "$LOG_FILE"
fi

echo "$FORMATTED_TABLE"

mv "$TEMP_FILE" "$STATUS_FILE"