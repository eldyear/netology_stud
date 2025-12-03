#!/bin/bash

# Переменные
PID_LIST=$(find /proc -maxdepth 1 -type d -regex '.*/[0-9]+' -exec basename {} \;) # Список PID процессов
LOG_FILE="process_monitor.log" # Файл лога
TIMESTAMP=$(date +"[%d.%m.%Y %H:%M:%S]") # Время запуска скрипта
STATUS_FILE="known_pids.txt" # Файл с известными PID процессами
TEMP_FILE="current_pids.txt" # Файл для хранения текущих PID процессов

# Создает файл с известными PID процессами, если он не существует
if [ ! -f $STATUS_FILE ]; then
    touch $STATUS_FILE
fi

# Сохраняет список PID процессов в файл
echo "$PID_LIST" | sort > $TEMP_FILE

# Находит новые PID процессов
NEW_PIDS=$(comm -13 $STATUS_FILE $TEMP_FILE)

# Выводит информацию в лог
echo "Скрипт запущен в $TIMESTAMP. Всего новых процессов: $(echo "$NEW_PIDS" | wc -l)" >> $LOG_FILE
echo "$NEW_PIDS" >> $LOG_FILE
echo "==============================================" >> $LOG_FILE

# Выводит информацию о новых процессах
echo "============================================================================"
printf "  %-10s   %-20.20s   %-5s   %-10s   %-15s  \n" "PID" "NAME" "STATE" "SIZE" "Max open files"
echo "============================================================================"
for i in $NEW_PIDS; do
    P_NAME=$(grep "Name" /proc/$i/status 2>/dev/null | awk '{print $2}')
    P_STATE=$(grep "State" /proc/$i/status 2>/dev/null | awk '{print $2}')
    P_SIZE=$(grep "FDSize" /proc/$i/status 2>/dev/null | awk '{print $2}')
    P_LIMITS=$(grep "Max open files" /proc/$i/limits 2>/dev/null | awk '{print $4}')
    
	printf "| %-10s | %-20.20s | %-5s | %-10s | %-15s |\n" "$i" "$P_NAME" "$P_STATE" "$P_SIZE" "$P_LIMITS" # Оформляет вывод в виде таблицы
    
done
echo "============================================================================"

echo "Перемещаем текущие PID в $STATUS_FILE" >> $LOG_FILE
mv "$TEMP_FILE" "$STATUS_FILE"