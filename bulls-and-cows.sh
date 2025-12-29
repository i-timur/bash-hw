# проверка минимальной версии bash
if [[ ${BASH_VERSINFO[0]} -lt 5 || ( ${BASH_VERSINFO[0]} -eq 5 && ${BASH_VERSINFO[1]} -lt 2 ) ]]; then
  echo "Нужен bash 5.2 или новее. Текущая версия: ${BASH_VERSION}" >&2
  exit 2
fi

# ловим Ctrl+C — информируем пользователя, не завершаем процесс
trap 'echo -e "\nДля выхода введите \"q\" или \"Q\". Игра продолжается...";' INT

# приветственный блок с правилами
cat <<'WELCOME'
********************************************************************************
* Я загадал 4-значное число с неповторяющимися цифрами. На каждом ходу делайте *
* попытку отгадать загаданное число. Попытка - это 4-значное число с           *
* неповторяющимися цифрами.                                                    *
********************************************************************************
WELCOME

# генератор целевого числа (4 разные цифры, первая != 0)
make_target() {
  local result="" d mask="::::::::::"
  while (( ${#result} < 4 )); do
    d=$((RANDOM % 10))
    if (( ${#result} == 0 && d == 0 )); then
      continue
    fi
    if [[ ${mask:d:1} != "#" ]]; then
      result+="$d"
      mask="${mask:0:d}#${mask:d+1}"
    fi
  done
  echo "$result"
}

target="$(make_target)"

# проверка корректности ввода по правилам игры
valid_input() {
  local g="$1"
  [[ "$g" =~ ^[1-9][0-9]{3}$ ]] || return 1
  local i j
  for ((i=0;i<4;i++)); do
    for ((j=i+1;j<4;j++)); do
      [[ ${g:i:1} != ${g:j:1} ]] || return 1
    done
  done
  return 0
}

# подсчет совпадений: other = совпадения на других позициях, place = совпадения на своих позициях
calc_hits() {
  local g="$1" t="$2"
  local other=0 place=0 i j
  for ((i=0;i<4;i++)); do
    if [[ ${g:i:1} == ${t:i:1} ]]; then
      ((place++))
    else
      for ((j=0;j<4;j++)); do
        if (( i != j )) && [[ ${g:i:1} == ${t:j:1} ]]; then
          ((other++))
          break
        fi
      done
    fi
  done
  echo "$other $place"
}

# массивы для истории попыток и результатов
declare -a log_guess=()
declare -a log_other=()
declare -a log_place=()

# номер хода
turn=0

# основной цикл: читаем ввод, валидируем, считаем совпадения и показываем историю
while true; do
  read -rp "Попытка $((turn+1)): " pick

  if [[ "$pick" == "q" || "$pick" == "Q" ]]; then
    exit 1
  fi

  if ! valid_input "$pick"; then
    echo "Неверный ввод. Ожидается 4 разные цифры, первая не 0. Или 'q'/'Q' для выхода."
    continue
  fi

  ((turn++))
  read -r other place < <(calc_hits "$pick" "$target")

  echo "Коров - $other  Быков - $place"
  log_guess+=("$pick")
  log_other+=("$other")
  log_place+=("$place")

  echo -e "\nИстория ходов:"
  for ((i=0;i<${#log_guess[@]};i++)); do
    echo "$((i+1)). ${log_guess[$i]} (Коров - ${log_other[$i]} Быков - ${log_place[$i]})"
  done
  echo

  if (( place == 4 )); then
    echo "Вы угадали число: $target"
    exit 0
  fi
done
