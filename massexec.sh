set -euo pipefail

#Функция печатает справку по ключам и формату запуска.
print_usage() {
  cat <<'USAGE'
Использование:
  massexec.sh [--path dirpath] [--mask mask] [--number number] command

--path dirpath   Каталог с файлами (по умолчанию текущий).
--mask mask      Шаблон имен (Pattern Matching, по умолчанию *).
--number number  Максимум параллельных процессов (>0). По умолчанию = кол-ву ядер.
command          Исполняемая команда (должна существовать и быть исполнимой), например: gzip
USAGE
}

#Значения по умолчанию для всех опций
DIRPATH="."
MASK="*"
NUMBER=""
COMMAND=""

#разбираем входные аргументы на корректность ввода
while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)
      [[ $# -ge 2 ]] || { echo "Ошибка: для --path нужен аргумент" >&2; exit 1; }
      DIRPATH="$2"; shift 2;;
    --mask)
      [[ $# -ge 2 ]] || { echo "Ошибка: для --mask нужен аргумент" >&2; exit 1; }
      MASK="$2"; shift 2;;
    --number)
      [[ $# -ge 2 ]] || { echo "Ошибка: для --number нужен аргумент" >&2; exit 1; }
      NUMBER="$2"; shift 2;;
    -h|--help)
      print_usage; exit 0;;
    --*)
      echo "Неизвестная опция: $1" >&2; exit 1;;
    *)
      COMMAND="$1"; shift; break;;
  esac
done

#Валидации входных данных
[[ -d "$DIRPATH" ]] || { echo "Ошибка: нет каталога: $DIRPATH" >&2; exit 1; }
[[ -n "$MASK" ]] || { echo "Ошибка: маска не может быть пустой" >&2; exit 1; }

#Подбор --number по умолчанию, согласно условиям задания
if [[ -z "${NUMBER}" ]]; then
  if command -v nproc >/dev/null 2>&1; then
    NUMBER="$(nproc)"
  elif command -v getconf >/dev/null 2>&1; then
    NUMBER="$(getconf _NPROCESSORS_ONLN || echo 1)"
  else
    NUMBER="1"
  fi
fi
#проверка, что --number - это целое число
[[ "$NUMBER" =~ ^[1-9][0-9]*$ ]] || { echo "Ошибка: --number должно быть целым > 0" >&2; exit 1; }

#Проверка --command: задана ли она, можно ли ее исполнить, есть ли она в PATH
if [[ -z "$COMMAND" ]]; then
  echo "Ошибка: не задана команда обработки (command)" >&2; print_usage; exit 1;
fi
if [[ "$COMMAND" == */* ]]; then
  [[ -x "$COMMAND" ]] || { echo "Ошибка: команда '$COMMAND' не найдена/не исполнима" >&2; exit 1; }
else
  command -v "$COMMAND" >/dev/null 2>&1 || { echo "Ошибка: команда '$COMMAND' не найдена в PATH" >&2; exit 1; }
fi

#Получаем реальный путь директории
pushd "$DIRPATH" >/dev/null
DIRABS="$(pwd -P)"
popd >/dev/null

#Если по маске нет совпадений, массив пуст
shopt -s nullglob

#В FILES берём только обычные файлы (исключая каталоги/ссылки)
CAND=( "$DIRABS"/$MASK )
FILES=()
for f in "${CAND[@]}"; do
  [[ -f "$f" ]] || continue
  FILES+=( "$f" )
done

#Если файлов нет - выход
if (( ${#FILES[@]} == 0 )); then
  echo "Нет файлов по маске '$MASK' в '$DIRABS' — ничего делать не нужно."
  exit 0
fi

#Ожидание свободного слота
wait_one() {
  if help wait 2>/dev/null | grep -q -- ' -n '; then
    wait -n || true
  else
    local p
    p="$(jobs -rp | head -n1 || true)"
    [[ -n "$p" ]] && wait "$p" || true
  fi
}

#Параллельный запуск с ограничением по числу процессов
for f in "${FILES[@]}"; do
  while (( $(jobs -rp | wc -l) >= NUMBER )); do
    wait_one
  done
  "$COMMAND" "$f" &
done

wait
