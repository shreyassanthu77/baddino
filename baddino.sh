#!/bin/env bash
source ./term.sh
source ./utils.sh

main() {
	hide_cursor
	enable_altmode
	enable_raw_mode
	local frame_time=$(echo "scale=2; 1/75" | bc)

	WIDTH=$(tput cols)
	HEIGHT=$(tput lines)
	local platform_height=4
	local ground_y=$((HEIGHT-platform_height))

	# x y speed size
	local clouds=(
    $((RANDOM % WIDTH)) $((RANDOM % 5 + 10)) 0.2 "small"
    $((RANDOM % WIDTH)) $((RANDOM % 4 + 9)) 0.15 "medium"
    $((RANDOM % WIDTH)) $((RANDOM % 3 + 4)) 0.1 "large"
	)

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

	while true; do
		read_key $frame_time

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

		for ((i=0; i<3; i++)); do
			local idx=$((i*4))
			clouds[$idx]=$(echo "${clouds[$idx]} - ${clouds[$idx+2]}" | bc)
			
			if [[ $(echo "${clouds[$idx]} < -10" | bc) -eq 1 ]]; then
					clouds[$idx]=$WIDTH
					clouds[$idx+1]=$((RANDOM % 5 + 2))
			fi
		done

		if check_collision ${dino[@]} ${cactus[@]}; then
			break
		elif (( cactus[0] + cactus[2] < dino[0] && scored == 0 )); then
			score=$((score+1))
			scored=1
		fi

		set_bg_color_rgb 4 9 22
		clear_screen
		draw_title
		reset_color
		for ((i=0; i<3; i++)); do
			local idx=$((i*4))
			draw_cloud ${clouds[$idx]%.*} ${clouds[$idx+1]} "${clouds[$idx+3]}"
		done

		move_cursor 0 1
		if [[ $scored -eq 1 ]]; then
			set_fg_color $GREEN
		fi
		printf "Score: $score"
		reset_color

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

draw_cloud() {
    local x="$1"
    local y="$2"
    local size="$3" 
    
    set_fg_color $GRAY
    
    if [ "$size" == "small" ]; then
        move_cursor $x $y
        echo -n "░░"
    elif [ "$size" == "medium" ]; then
        move_cursor $x $y
        echo -n "░░░"
        move_cursor $x $((y+1))
        echo -n " ░░"
    else  # large
        move_cursor $x $y
        echo -n " ░░░░"
        move_cursor $x $((y+1))
        echo -n "░░░░░"
    fi
    
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
