measure_text() {
	local text="$@"
	local length=${#text}
	echo $length
}

BLACK=0
GREEN=2
RED=1
BLUE=4
YELLOW=3
GRAY=8

set_fg_color() {
	local color="$1"
	printf "\e[38;5;${color}m"
}

set_bg_color() {
	local color="$1"
	printf "\e[48;5;${color}m"
}

set_bg_color_rgb() {
	local r="$1"
	local g="$2"
	local b="$3"
	printf "\e[48;2;${r};${g};${b}m"
}

dim_text() {
	printf "\e[2m"
}

reset_color() {
	printf "\e[0m"
}
