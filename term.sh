
hide_cursor() {
	printf '\e[?25l'
}

show_cursor() {
	printf '\e[?25h'
}

enable_altmode() {
  printf '\e[?1049h' # alt screen
}


disable_altmode() {
  printf '\e[?1049l' # exit alt screen
}

enable_raw_mode() {
	term_settings=$(stty -g)
  stty raw -echo
}

disable_raw_mode() {
  stty $term_settings
}

quit() {
	disable_raw_mode
	disable_altmode
	show_cursor
  exit
}

read_key() {
	local timeout="$1"

	if [[ $(echo "$timeout > 0" | bc) -eq 1 ]]; then
		read -t $timeout -s -n 1   key
	else
		read -n 1 -s key
	fi

	if [[ "$key" == $'q' ]]; then 
		quit
	fi
}

clear_screen() {
  printf '\e[2J' # clear screen
}

clear_rect() {
	local x=$(($1 - 2))
	if [[ $x -lt 0 ]]; then
		x=0
	fi
	local y=$2
	local width=$(($3 + 4))
	local height=$4
	local clear_text=$(printf "%${width}s")
	for ((i=0; i<height; i++)); do
		move_cursor $x $((y+i))
		printf "$clear_text"
	done
}

move_cursor() {
	local x=$1
	local y=$2
	printf '\e[%d;%dH' $y $x
}
