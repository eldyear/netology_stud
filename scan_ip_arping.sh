#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "Ошибка: Нужен root. Используйте: sudo $0"
    exit 1
fi

OCTET_REGEX='^([1-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'

check_octet() {
    if ! [[ "$1" =~ $OCTET_REGEX ]]; then
        echo "Ошибка: $2='$1' должен быть 1-255"
        exit 1
    fi
}

scan_ip() {
    arping -c 3 -i "$2" "$1" 2>/dev/null
}

if [[ $# -lt 2 ]]; then
    echo "Использование: $0 [префикс] [интерфейс] [подсеть] [хост]"
    echo "Примеры:"
    echo "  $0 192.168 eth0"
    echo "  $0 10.0 eth1 1"
    echo "  $0 172.16 eth0 20 50"
    exit 1
fi

PREFIX="$1"
INTERFACE="$2"
SUBNET="$3"
HOST="$4"

# Проверяем что префикс состоит из двух октетов через точку
if [[ ! "$PREFIX" =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo "Ошибка: Пример: 192.168"
    exit 1
fi

# Проверяем каждый октет префикса
IFS='.' read -r octet1 octet2 <<< "$PREFIX"
check_octet "$octet1" "первый октет префикса"
check_octet "$octet2" "второй октет префикса"

if [[ -z "$(ip link show "$INTERFACE" 2>/dev/null)" ]]; then
    echo "Ошибка: '$INTERFACE' не найден"
    exit 1
fi

if [[ -n "$SUBNET" ]]; then
    check_octet "$SUBNET" "подсеть"
fi

if [[ -n "$HOST" ]]; then
    check_octet "$HOST" "хост"
fi

echo "Начало сканирования: $PREFIX на $INTERFACE ..."

if [[ -n "$SUBNET" && -n "$HOST" ]]; then
    TARGET="$PREFIX.$SUBNET.$HOST"
    echo "Сканирую: $TARGET"
    scan_ip "$TARGET" "$INTERFACE"

elif [[ -n "$SUBNET" ]]; then
    echo "Сканирую подсеть: $PREFIX.$SUBNET.*"

    for host in {1..255}; do
        echo "Проверка: $PREFIX.$SUBNET.$host"
        scan_ip "$PREFIX.$SUBNET.$host" "$INTERFACE"
    done

else
    echo "Сканирую всю область: $PREFIX.*.*"

    for subnet in {1..255}; do
        echo "Подсеть: $PREFIX.$subnet.*"
        for host in {1..255}; do
            scan_ip "$PREFIX.$subnet.$host" "$INTERFACE"
        done
    done
fi

echo "Сканирование завершено"