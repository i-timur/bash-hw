# создаю массив для хранения текущего состояния поля
declare -a grid

# отрисовка текущего поля 4x4
render_grid() {
  echo "+-------------------+"
  for r in {0..3}; do
    printf "| %2s | %2s | %2s | %2s |\n" \
      "$(cell_display $((4*r+0)))" \
      "$(cell_display $((4*r+1)))" \
      "$(cell_display $((4*r+2)))" \
      "$(cell_display $((4*r+3)))"
    if (( r < 3 )); then
      echo "|-------------------|"
    fi
  done
  echo "+-------------------+"
}

# преобразую значение ячейки в выводимую строку
cell_display() {
  local val=${grid[$1]}
  [[ $val -eq 0 ]] && echo " " || echo "$val"
}

# ищу индекс заданного значения в массиве
find_pos() {
  local v=$1
  for i in "${!grid[@]}"; do
    if [[ ${grid[$i]} -eq $v ]]; then
      echo "$i"; return 0
    fi
  done
  echo -1; return 1
}

# проверка завершения (1..15 на местах, последняя 0)
is_completed() {
  for i in {0..14}; do
    [[ ${grid[$i]} -eq $((i+1)) ]] || return 1
  done
  [[ ${grid[15]} -eq 0 ]]
}

# возвращает номера плиток, которые можно передвинуть в пустую
movable_tiles() {
  local blank_idx
  blank_idx=$(find_pos 0)
  local row=$((blank_idx/4))
  local col=$((blank_idx%4))
  local res=() idx
  if (( col > 0 )); then idx=$((blank_idx-1)); res+=("${grid[$idx]}"); fi
  if (( col < 3 )); then idx=$((blank_idx+1)); res+=("${grid[$idx]}"); fi
  if (( row > 0 )); then idx=$((blank_idx-4)); res+=("${grid[$idx]}"); fi
  if (( row < 3 )); then idx=$((blank_idx+4)); res+=("${grid[$idx]}"); fi
  echo "${res[@]}"
}

# попытка передвинуть плитку: проверяю соседство и меняю местами
attempt_move() {
  local val=$1
  local blank_idx tile_idx
  blank_idx=$(find_pos 0)
  tile_idx=$(find_pos "$val")
  [[ $tile_idx -ge 0 ]] || return 1

  local br=$((blank_idx/4)) bc=$((blank_idx%4))
  local tr=$((tile_idx/4)) tc=$((tile_idx%4))
  local dr=$(( br - tr ))
  local dc=$(( bc - tc ))
  (( dr<0 )) && dr=$(( -dr ))
  (( dc<0 )) && dc=$(( -dc ))

  if (( dr + dc == 1 )); then
    grid[$blank_idx]=${grid[$tile_idx]}
    grid[$tile_idx]=0
    return 0
  fi
  return 1
}

# считаю количество инверсий для проверки разрешимости
inversion_count() {
  local inv=0 i j vi vj
  for ((i=0;i<16;i++)); do
    vi=${grid[$i]}
    (( vi==0 )) && continue
    for ((j=i+1;j<16;j++)); do
      vj=${grid[$j]}
      (( vj==0 )) && continue
      (( vi>vj )) && ((inv++))
    done
  done
  echo "$inv"
}

# на какой строке снизу находится пустая клетка (1..4)
blank_row_from_end() {
  local bi=$(find_pos 0)
  local row_top=$((bi/4))
  echo $((4 - row_top))
}

# проверяю, возможна ли комбинация (разрешимость)
check_solvable() {
  local inv=$(inversion_count)
  local rb=$(blank_row_from_end)
  local sum=$(( (inv + rb) % 2 ))
  [[ $sum -eq 1 ]]
}

# заполняю поле и тасую, пока не получу допустимое и неготовое состояние
randomize_grid() {
  grid=()
  for ((i=1;i<=15;i++)); do grid+=("$i"); done
  grid+=(0)

  while true; do
    for ((i=15;i>0;i--)); do
      j=$((RANDOM % (i+1)))
      tmp=${grid[$i]}
      grid[$i]=${grid[$j]}
      grid[$j]=$tmp
    done
    check_solvable && ! is_completed && break
  done
}

# начальная инициализация
randomize_grid

moves=0

# основной игровой цикл
while true; do
  echo "Ход № $((moves+1))"
  echo
  render_grid
  echo
  read -rp "Ваш ход (q - выход): " inp

  if [[ "$inp" == "q" || "$inp" == "Q" ]]; then
    echo "Выход из игры."
    exit 0
  fi

  if ! [[ "$inp" =~ ^([1-9]|1[0-5])$ ]]; then
    echo
    echo "Неверный ввод! Введите число 1..15, соседнее с пустой клеткой, или q для выхода."
    echo
    continue
  fi

  if attempt_move "$inp"; then
    ((moves++))
    if is_completed; then
      echo
      echo "Вы собрали головоломку за $moves ходов."
      echo
      render_grid
      exit 0
    fi
    echo
  else
    opts=( $(movable_tiles) )
    filtered=()
    for v in "${opts[@]}"; do
      (( v!=0 )) && filtered+=("$v")
    done
    echo
    echo "Неверный ход!"
    echo "Невозможно костяшку $inp передвинуть на пустую ячейку."
    if ((${#filtered[@]})); then
      IFS=', ' read -r -a dummy <<< "${filtered[*]}"
      echo -n "Можно выбрать: "
      for i in "${!filtered[@]}"; do
        if (( i>0 )); then printf ", "; fi
        printf "%s" "${filtered[$i]}"
      done
      echo
    fi
    echo
  fi
done
