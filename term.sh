
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
  read -n 1 -s -t $timeout key
	if [[ "$key" == $'q' ]]; then 
		quit
	fi
}

clear_screen() {
  printf '\e[2J' # clear screen
}

move_cursor() {
	local x=$1
	local y=$2
	printf '\e[%d;%dH' $y $x
}
