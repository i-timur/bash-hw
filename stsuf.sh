set -euo pipefail

#Показывает, как запускать скрипт
usage() {
  cat <<'USAGE'
Использование:
  stsuf --path DIR
USAGE
}

#Переменная для входной опции
DIR=""

#Если ввод "нулевой" выводим подсказку и выход
if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

#Обработка аргументов. Если параметров нет - показывается usage, если неизвестный аргумент - ошибка и выход
while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)
      [[ $# -ge 2 ]] || { echo "Для --path нужен аргумент" >&2; exit 1; }
      DIR="$2"; shift 2;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Неизвестный аргумент: $1" >&2
      usage; exit 1;;
  esac
done

#Проверка, что каталог существует
[[ -d "$DIR" ]] || { echo "Ошибка: '$DIR' не каталог" >&2; exit 1; }

#объявляем массив для подсчета подходящих файлов
declare -A counts

#Поиск всех подходящих файлов
export LC_ALL=C
while IFS= read -r -d '' f; do
  #Определение суффикса файла
  base="$(basename -- "$f")"
  #Если имя содержит точку, берём всё после последней точки
  if [[ "$base" == *.* ]]; then
    idx="${base##*.}"
    #Особое правило для «скрытых» файлов
    if [[ "${base:0:1}" == "." && "$base" != *.*.* ]]; then
      key="no suffix"
    else
      suffix=".${idx}"
      key="$suffix"
    fi
  else
    #Если точки вообще нет
    key="no suffix"
  fi
  counts["$key"]=$(( ${counts["$key"]:-0} + 1 ))
done < <(find "$DIR" -type f -print0)

#Вывод результатов
{
  for k in "${!counts[@]}"; do
    printf "%d\t%s\n" "${counts[$k]}" "$k"
  done
} | sort -nr | awk -F'\t' '{print $2 ": " $1}'
