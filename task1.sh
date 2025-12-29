#!/bin/bash

# Цвета для вывода (ANSI)
GGRN=$'\e[32m'
GRED=$'\e[31m'
RSET=$'\e[0m'

# счётчики и метрики раундов
round=0
wins=0
losses=0

# два параллельных массива: последние числа и их результаты
history_nums=()
history_res=()

#база игры - это цикл while, в котором выводится число раунда и условия игры
while true; do
    ((round++))
    echo "Раунд: $round"
    read -p "Введите число 0-9 (q - выйти): " guess

    # выход по q
    if [[ "$guess" == "q" ]]; then
        echo "Игра завершена!"
        break
    fi

    # проверка корректности ввода
    if ! [[ "$guess" =~ ^[0-9]$ ]]; then
        echo "Ошибка: введите 0-9 или q"
        ((round--))
        continue
    fi

    # загадываем случайное число
    target=$((RANDOM % 10))

    # угадывание
    if [[ "$guess" -eq "$target" ]]; then
        echo -e "${GGRN}Угадали! Загаданное: $target${RSET}"
        ((wins++))
        success=1
    else
        echo -e "${GRED}Не угадали. Загаданное: $target${RSET}"
        ((losses++))
        success=0
    fi

    # сохраняем историю (параллельные массивы)
    history_nums+=("$target")
    history_res+=("$success")

    # держим только последние 10 записей
    if [[ ${#history_nums[@]} -gt 10 ]]; then
        history_nums=("${history_nums[@]: -10}")
        history_res=("${history_res[@]: -10}")
    fi

    # проценты
    total=$((wins + losses))
    if [[ $total -gt 0 ]]; then
        win_pct=$((100 * wins / total))
        loss_pct=$((100 - win_pct))
    else
        win_pct=0
        loss_pct=0
    fi
    echo -e "Попаданий: ${win_pct}% Промахов: ${loss_pct}%"

    # вывод истории с подсветкой
    echo -n "Последние: "
    for i in "${!history_nums[@]}"; do
        n="${history_nums[$i]}"
        if [[ "${history_res[$i]}" -eq 1 ]]; then
            echo -ne "${GGRN}${n}${RSET} "
        else
            echo -ne "${GRED}${n}${RSET} "
        fi
    done
    echo -e "\n"
done
