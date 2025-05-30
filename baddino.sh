#!/bin/env bash
source ./term.sh
source ./utils.sh


main() {
	hide_cursor
	enable_altmode
	enable_raw_mode
	local frame_time=$(echo "scale=2; 1/60" | bc)

	WIDTH=$(tput cols)
	HEIGHT=$(tput lines)
	local platform_height=4
	local ground_y=$((HEIGHT-platform_height))

	# x y width height color vy on_ground
	local dino=(
		$((WIDTH/2-2))
		$((ground_y-2+1)) 
		4 2 $BLUE
		0 1
	)

	# x y width height color 
	local cactus=(
		$((WIDTH-2))
		$((ground_y-4+1)) 
		2 4 $GREEN
	)
	local cactus_speed=0.5

	local jump_speed=$(echo "($cactus_speed * 4)/1" | bc)
	local gravity=$(echo "scale=2; ($cactus_speed / 2)" | bc)

	local score=0
	local scored=0

	local old_dino=""
	local old_cactus=""

	while true; do
		read_key $frame_time
		old_dino="${dino[@]}"
		old_cactus="${cactus[@]}"

		if [[ "$key" == "w" && ${dino[6]} -eq 1 ]]; then
			# dino.vy = -jump_speed
			dino[5]=$(echo "(-$jump_speed)/1" | bc)
			# dino.on_ground = false
			dino[6]=0
		fi

		# if not dino.on_ground:
		if [[ ${dino[6]} -eq 0 ]]; then
			# dino.vy += gravity
			dino[5]=$(echo "${dino[5]} + $gravity" | bc)
		fi

		# dino.y += dino.vy
		dino[1]=$(echo "scale=0; (${dino[1]} + ${dino[5]})/1" | bc)
		# if int(dino.y) >= ground_y-dino.height:
		if [[ ${dino[1]%.*} -ge $((ground_y+1-dino[3])) ]]; then
			# dino.y = ground_y-dino.height
			dino[1]=$((ground_y+1-dino[3]))
			# dino.vy = 0
			dino[5]=0
			# dino.on_ground = true
			dino[6]=1
		fi


		# cactus.x -= cactus_speed
		cactus[0]=$(echo "(${cactus[0]} - $cactus_speed)/1" | bc)
		if [[ ${cactus[0]} -le 0 ]]; then
			# cactus.width = random
			cactus[2]=$((RANDOM%4+1)) # 1 <= width <= 4
			# cactus.x = WIDTH - cactus.width
			cactus[0]=$((WIDTH-cactus[2]))
			# cactus.height = random
			cactus[3]=$((RANDOM%3+1)) # 1 <= height <= 3
			# cactus.y = ground_y - cactus.height + 1
			cactus[1]=$((ground_y - cactus[3] + 1))

			scored=0
			cactus_speed=$(echo "scale=2; ($cactus_speed + 0.1)/1" | bc)
			jump_speed=$(echo "scale=2; ($jump_speed + 0.1)/1" | bc)
			if [[ $(echo "$cactus_speed > 2" | bc) -eq 1 ]]; then
				cactus_speed=2
			fi
			if [[ $(echo "$jump_speed > 2.5" | bc) -eq 1 ]]; then
				jump_speed=2.5
			fi
		fi

		if check_collision ${dino[@]} ${cactus[@]}; then
			draw_game_over
			read_key 0
			# reset state
			dino=(
				$((WIDTH/2-2))
				$((ground_y-2+1)) 
				4 2 $BLUE
				0 1
			)
			cactus=(
				$((WIDTH-2))
				$((ground_y-4+1)) 
				2 4 $GREEN
			)
			cactus_speed=0.5
			jump_speed=$(echo "($cactus_speed * 4)/1" | bc)
			gravity=$(echo "scale=2; ($cactus_speed / 2)" | bc)
			score=0
			scored=0
			clear_screen
			continue
		elif (( cactus[0] + cactus[2] < dino[0] && scored == 0 )); then
			score=$((score+1))
			scored=1
		fi

		set_bg_color_rgb 4 9 22
		# clear_screen_alt 10 $((HEIGHT-platform_height))
		clear_rect $old_dino
		clear_rect $old_cactus
		draw_title
		reset_color

		move_cursor 0 1
		if [[ $scored -eq 1 ]]; then
			set_fg_color $GREEN
		fi
		printf "Score: $score"
		reset_color

		move_cursor 0 2
		printf "Cactus speed: %0.2f" $cactus_speed

		draw_platform $platform_height
		draw_dino ${dino[0]} ${dino[1]} ${dino[4]}
		draw_cactus ${cactus[0]} ${cactus[1]} ${cactus[3]} ${cactus[4]}
	done

	quit
}

check_collision() {
	local ax="$1"
	local ay="$2"
	local aw="$3"
	local ah="$4"
	# skip color, vy, on_ground
	local bx="$8"
	local by="$9"
	local bw="${10}"
	local bh="${11}"

	if (( ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by )); then
    return 0
  else
    return 1
  fi
}

draw_dino() {
    local x="$1"
    local y="$2"
    local color="$3"
    
    set_fg_color $color
    move_cursor $x $y
    echo -n "█▀▄"
    move_cursor $x $((y+1))
    echo -n "█▀ "
    reset_color
}

draw_cactus() {
    local x="$1"
    local y="$2"
    local height="$3"
    local color="$4"
    
    set_fg_color $color
    
    for ((i=0; i<height; i++)); do
        move_cursor $x $((y+i))
        echo -n "█"
    done
    
    if [ $height -gt 2 ]; then
        move_cursor $((x+1)) $((y+1))
        echo -n "▄"
        
        if [ $height -gt 3 ]; then
            move_cursor $((x-1)) $((y+2))
            echo -n "▄"
        fi
    fi
    
    reset_color
}


game_over="   _____                         ____                 \n
  / ____|                       / __ \\                \n
 | |  __  __ _ _ __ ___   ___  | |  | |_   _____ _ __ \n
 | | |_ |/ _' | '_ ' _ \\ / _ \\ | |  | \\ \\ / / _ \\ '__|\n
 | |__| | (_| | | | | | |  __/ | |__| |\\ V /  __/ |   \n
  \\_____|\\__,_|_| |_| |_|\\___|  \\____/  \\_/ \\___|_|   \n
"
game_over_line_x=(0 0 0 0 0)
draw_game_over() {
	set_bg_color_rgb 4 9 22
	clear_screen

	set_fg_color $RED
	local l=$((HEIGHT/2-7))
	while IFS= read -r line; do
		if [[ ${game_over_line_x[$l]} -eq 0 ]]; then
			local line_width=$(measure_text "$line")
			local x=$((WIDTH/2-line_width/2))
			game_over_line_x[$l]=$x
			move_cursor 0 $((l+1))
		fi

		move_cursor ${game_over_line_x[$l]} $((l+1))
		printf "$line"
		l=$((l+1))
	done <<< "$game_over"

	local score_text="Score: $score"
	local score_width=$(measure_text "$score_text")

	set_fg_color $YELLOW
	move_cursor $((WIDTH/2-score_width/2)) $((l+1))
	printf "$score_text"

	local try_again_text="Press q to quit or any other key to restart"
	local try_again_width=$(measure_text "$try_again_text")
	move_cursor $((WIDTH/2-try_again_width/2)) $((l+2))
	printf "$try_again_text"

	reset_color
}

title="\n
    __              __       ___           \n
   / /_  ____ _____/ /  ____/ (_)___  ____ \n
   / __ \\/ __ ./ __  /  / __  / / __ \\/ __ \\ \n
 / /_/ / /_/ / /_/ /  / /_/ / / / / / /_/ /\n
/_.___/\\__,_/\\__,_/   \\__,_/_/_/ /_/\\____/ \n
Dino but badcop style
"
title_line_x=(0 0 0 0 0 0 0 0)
draw_title() {
	move_cursor 0 0
	# looop through each line
	local l=0
	set_fg_color $YELLOW
	dim_text
	while IFS= read -r line; do
		if [[ ${title_line_x[$l]} -eq 0 ]]; then
			local line_width=$(measure_text "$line")
			local x=$((WIDTH/2-line_width/2))
			title_line_x[$l]=$x
			move_cursor 0 $((l+1))
		fi

		move_cursor ${title_line_x[$l]} $((l+1))
		printf "$line"
		l=$((l+1))
	done <<< "$title"
	reset_color
}

draw_platform() {
	local platform_height="$1"
	local width_spaces=$(printf "%${WIDTH}s")


	local top=$((HEIGHT-platform_height+1))
	set_bg_color_rgb 57 109 44
	move_cursor 0 $top
	printf "$width_spaces"
	reset_color

	set_bg_color_rgb 78 45 31
	for ((i=((top+1)); i<=HEIGHT; i++)); do
		move_cursor 0 $i
		printf "$width_spaces"
	done
	reset_color
}

main
