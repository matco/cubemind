/* Cubemind: a Mastermind-like game for the Futurocube */

#include <futurocube>

new icon[]=[ICON_MAGIC1, ICON_MAGIC2, 3, 1, 0x00000000, RED, 0x00000000, RED, RED, RED, 0x00000000, 0x00000000, 0x00000000, '''', '''']

//max attempts matches the number of side of the cube (can be eventually decreased, but never increased)
const MAX_ATTEMPTS = 6
//secret size is fixed to 4 to use the corner of each side (do not touch this value, it can not be changed)
const SECRET_SIZE = 4
//configure colors that will be used for the game
new colors[3]=[cORANGE, cMAGENTA, cPURPLE]

//store secret as an array of colors
new secret[SECRET_SIZE]

//store all attempts
new attempts[MAX_ATTEMPTS][SECRET_SIZE]

//store attempts results
new attempts_results[MAX_ATTEMPTS][SECRET_SIZE]

//store attempts states
//attempt state is used to know what is the current status of the attempt
//0 if attempt has not been started yet
//1 if attempt is currently being played
//2 if attempt is locked (it has been checked and can no longer been used)
new attempts_states[MAX_ATTEMPTS]

//store association between attempts and sides of the cube
//index of the array matches the attempt index and the associated value is the side on which the attempt has been made
new attempts_sides[MAX_ATTEMPTS]

//store attempts orientation (as an orientation vector)
//when a side is selected, the gravity point is but at the bottom of the side using a walker directed to the top (its square index can be 1, 3, 5 or 7)
//at the same time, the orientation of the walker is stored in this array to be able to find the corner index associated to a square and vice versa
new attempts_orientations[MAX_ATTEMPTS][3]

//store current attempt index
new attempt_index = 0

//store game status
//0 if the game is being played
//1 if the game has been won
//2 if the game has been lost
//3 if the game has been lost and the user wants to show the secret
new game_status = 0

//debug function to be able to display color
color_to_name(color) {
	//do not forget to increase the size of the array for colors with a longer name
	new label[7]
	switch(color) {
		case cORANGE: cellcopy(label, "Orange")
		case cMAGENTA: cellcopy(label, "Magenta")
		case cPURPLE: cellcopy(label, "Purple")
	}
	return label
}

generate_secret() {
	for(new i = 0; i < SECRET_SIZE; i++) {
		secret[i] = colors[GetRnd(sizeof(colors))]
		//to debug, set secret to the second color
		//secret[i] = colors[1]
	}
	//printf("secret generated [%x, %x, %x, %x]\n", secret[0], secret[1], secret[2], secret[3]))
	printf("secret generated [%s, %s, %s, %s]\n", color_to_name(secret[0]), color_to_name(secret[1]), color_to_name(secret[2]), color_to_name(secret[3]))
}

//cube position helpers
is_corner(square) {
	return square % 2 == 0 && square != 4
}

differences_to_step(dx, dy) {
	if(dx <= -1 && dy >= 1) {
		return STEP_UPLEFT
	}
	if(dx >= 1 && dy >= 1) {
		return STEP_UPRIGHT
	}
	if(dx >= 1 && dy <= -1) {
		return STEP_DOWNRIGHT
	}
	if(dx <= -1 && dy <= -1) {
		return STEP_DOWNLEFT
	}
	return STEP_NOTHING
}

step_to_corner_index(step) {
	switch(step) {
		case STEP_UPLEFT: return 0
		case STEP_UPRIGHT: return 1
		case STEP_DOWNRIGHT: return 2
		case STEP_DOWNLEFT: return 3
	}
	return -1
}

corner_index_to_step(index) {
	switch(index) {
		case 0: return STEP_UPLEFT
		case 1: return STEP_UPRIGHT
		case 2: return STEP_DOWNRIGHT
		case 3: return STEP_DOWNLEFT
	}
	return STEP_NOTHING
}

result_index_to_step(index) {
	switch(index) {
		case 0: return STEP_FORWARD
		case 1: return STEP_LEFT
		case 2: return STEP_NOTHING
		case 3: return STEP_RIGHT
	}
	return STEP_NOTHING
}

//attempts related helpers
is_side_used(side) {
	for(new i = 0; i < MAX_ATTEMPTS; i++) {
		if(attempts_sides[i] == side) {
			return 1
		}
	}
	return 0
}

check_attempt(attempt[SECRET_SIZE]) {
	new i, j
	//prepare array that will contain attempt result
	new result[SECRET_SIZE]
	new result_index = 0
	cellset(result, 0)
	//save dots that have already been handled
	//this is because of the game rules: a dot can only have one result associated to it
	//if a dot is a perfect match (color and position) and its colors is also used at another place, result must only indicate that the dot is at the right place
	//0 means that the dot has not been managed yet
	//1 means that the dot has already been managed
	new managed_dots[SECRET_SIZE]
	cellset(managed_dots, 0)
	//find perfect matches first (color and position match)
	for(i = 0; i < SECRET_SIZE; i++) {
		if(attempt[i] == secret[i]) {
			//save the match in result
			result[result_index] = 2
			result_index++
			//register index in managed dots lists
			managed_dots[i] = 1
		}
	}
	//then find approximate matches (only color matches), only with dots that have not been managed yet
	for(i = 0; i < SECRET_SIZE; i++) {
		if(managed_dots[i] == 0) {
			//find if color exists elsewhere in secret
			for(j = 0; j < SECRET_SIZE; j++) {
				//do not compare against secret that have already been managed
				if(managed_dots[j] == 0 && attempt[i] == secret[j]) {
					result[result_index] = 1
					result_index++
					break
				}
			}
		}
	}
	return result
}

has_won(result[SECRET_SIZE]) {
	for(new i = 0; i < SECRET_SIZE; i++) {
		if(result[i] != 2) {
			return 0
		}
	}
	return 1
}

//attempt UI related functions
draw_attempts() {
	new i, status, side, orientation[3], won
	for(i = 0; i <= attempt_index; i++) {
		status = attempts_states[i]
		if(status > 0) {
			//retrieve side and orientation associated to attempt
			side = attempts_sides[i]
			orientation = attempts_orientations[i]
			if(game_status == 3) {
				draw_secret(side, orientation);
			}
			else {
				//draw attempt
				//specify if the attempt is the current attempt and if the game has been won
				draw_attempt(attempts[i], side, orientation, i == attempt_index, game_status == 1)
				//draw attempts result if it has been validated
				if(status == 2) {
					draw_attempt_result(attempts_results[i], side, orientation)
				}
			}
		}
	}
}

draw_attempt(attempt[SECRET_SIZE], side, orientation[3], current, won) {
	new i, w
	w = _w(side, 4)
	WalkerSetDir(w, orientation)
	WalkerMove(w, STEP_BACKWARDS)
	//draw gravity point
	//decrease intensity if this is not the attempt currently being played
	DrawPC(w, BLUE, current && !won ? 128 : 15)
	//draw attempt colors
	for(i = 0; i < SECRET_SIZE; i++) {
		//find good square using a walker
		w = _w(side, 4)
		WalkerSetDir(w, orientation)
		WalkerMove(w, corner_index_to_step(i))
		//draw point
		SetColor(attempt[i])
		//make the point flicker if this is the winning attempt
		if(won) {
			DrawFlicker(w)
		}
		else {
			DrawPoint(w)
		}
	}
}

draw_attempt_result(result[SECRET_SIZE], side, orientation[3]) {
	new i, w
	for(i = 0; i < SECRET_SIZE; i++) {
		switch(result[i]) {
			case 2 : {
				SetColor(RED)
			}
			case 1 : {
				SetColor(WHITE)
			}
		}
		if(result[i]) {
			//find good square using a walker
			w = _w(side, 4)
			WalkerSetDir(w, orientation)
			WalkerMove(w, result_index_to_step(i))
			DrawPoint(w)
		}
	}
}

draw_secret(side, orientation[3]) {
	new i, w
	w = _w(side, 4)
	WalkerSetDir(w, orientation)
	WalkerMove(w, STEP_BACKWARDS)
	//draw gravity point
	SetColor(BLUE)
	DrawPoint(w)
	//draw attempt colors
	for(i = 0; i < SECRET_SIZE; i++) {
		//find good square using a walker
		w = _w(side, 4)
		WalkerSetDir(w, orientation)
		WalkerMove(w, corner_index_to_step(i))
		//draw point
		SetColor(secret[i])
		//make the point flicker
		DrawFlicker(w)
	}
}

main() {
	//initialize variables
	cellset(attempts_sides, -1)

	generate_secret()

	ICON(icon)
	RegAllSideTaps()
	RegMotion(TAP_DOUBLE)
	SetDoubleTapLength(500)

	//main loop
	for(;;) {
		ClearCanvas()

		//draw existing attempts
		draw_attempts()

		//retrieve cursor and its coordinates
		new cursor = GetCursor()
		new side = _side(cursor)
		new walker = _w(side, 4)
		//printf("cursor is [%d], side is [%d], square is [%d]\n", cursor, side, square)

		new attempt_state = attempts_states[attempt_index]
		new attempt_orientation[3]
		attempt_orientation = attempts_orientations[attempt_index]

		//determine if a new side is being chosen
		if(attempt_state == 0 && !is_side_used(side)) {
			SetColor(BLUE)
			//draw the gravity point at the bottom
			WalkerDirUp(walker)
			WalkerMove(walker, STEP_BACKWARDS)
			DrawFlicker(walker)
		}

		new corner_walker, step

		//highlight corner if the current attempt is running and a corner is selected
		if(attempt_state == 1) {
			//the orientation of the cube is used to know which corner the user is trying to select
			//the easy way is to use a cursor, but this is very frustrating for the player because he would need to orient the cube perfectly so the cursor matches the exact position of the corner
			//as the player only has 4 possible choices (the 4 corners), the goal is to find the "closest" corner according to the cube orientation
			//the challenge is to find this corner while still considering the orientation of the attempt

			//at the moment, use a walker because it hides the complexity of the orientation of the attempt, but it helps only when the player is "over-orienting" the cube
			//TODO use raw accelerometer data and do the approriate calculation

			//initialize a walker at the center of the attempt side
			corner_walker = _w(attempts_sides[attempt_index], 4)
			//make the walker orientation match the orientation of the attempt
			WalkerSetDir(corner_walker, attempt_orientation)
			//retrieve the path to follow to reach the cursor from this walker
			//this way, even if the cursor is further than the corner, the direction would still be goo
			//unfortunately, it does not help if the player is "under-orienting" the cube
			new dx, dy
			WalkerDiff(corner_walker, cursor, dx, dy)
			//only consider diagonals steps
			step = differences_to_step(dx, dy)
			printf("%d, %d, %d\n", dx, dy, step)
			//move the walker using the direction found (remember, it's a diagonal step or nothing)
			WalkerMove(corner_walker, step)
			//check that the position of the walker now matches a corner
			if(is_corner(_square(corner_walker))) {
				SetColor(attempts[attempt_index][step_to_corner_index(step)])
				DrawFlicker(corner_walker)
			}
		}

		//detect motion
		new motion = Motion()
		if(motion) {
			new taptype = GetTapType(cursor)
			switch(taptype) {
				//side
				case 1: {
					//switch color if current attempt is being played and the cursor is at a corner
					if(attempt_state == 1 && is_corner(_square(corner_walker))) {
						//retrieve matching corner index
						new corner_index = step_to_corner_index(step)
						//retrieve index of current color
						new color_index
						for(color_index = 0; color_index < sizeof(colors); color_index++) {
							if(attempts[attempt_index][corner_index] == colors[color_index]) {
								break
							}
						}
						//printf("retrieved color [%s] at index [%d]\n", color_to_name(colors[color_index]), corner_index)
						//find next color
						color_index = (color_index + 1) % sizeof(colors)
						//switch color
						attempts[attempt_index][corner_index] = colors[color_index]
						printf("store color [%s] at index [%d] for attempt [%d]\n", color_to_name(colors[color_index]), corner_index, attempt_index)
					}
				}
				//top
				case 2: {
					//validate attempt with a double tap
					if(_is(motion, TAP_DOUBLE)) {
						//reset game if it has ended (won or lost)
						if(game_status != 0) {
							Restart()
						}
						//current attempt can be validated only if it's beeing played (it must not have already been validated)
						if(attempt_state == 1) {
							Vibrate(150)
							new attempt[SECRET_SIZE]
							attempt = attempts[attempt_index]
							printf("validate attempt [%d] with colors [%s, %s, %s, %s]\n", attempt_index, color_to_name(attempt[0]), color_to_name(attempt[1]), color_to_name(attempt[2]), color_to_name(attempt[3]))
							//lock the attempt
							attempts_states[attempt_index] = 2
							//checking attempt and store result
							new result[SECRET_SIZE]
							result = check_attempt(attempt)
							printf("store result [%d, %d, %d, %d] for attempt [%d]\n", result[0], result[1], result[2], result[3], attempt_index)
							attempts_results[attempt_index] = result
							//stop game if it is won
							if(has_won(result)) {
								printf("game won\n")
								//play RTTTL melody
								Melody("won:d=8,o=6,b=200:c,c,c,4g,c,1g")
								game_status = 1
							}
							else {
								printf("attempt [%d] failed\n", attempt_index)
								if(attempt_index < MAX_ATTEMPTS - 1) {
									//prepare new attempt
									attempt_index++
								}
								//game is over if there is no more available side (6 attempts)
								else {
									printf("game over\n")
									//play RTTTL melody
									Melody("lost:d=8,o=4,b=125:f,e,1d")
									game_status = 2
								}
							}
						}
					}
					else {
						//game is being played
						if(game_status == 0) {
							//check that attempt side has not been chosen yet
							if(attempt_state == 0 && !is_side_used(side)) {
								//choose this side for the attempt
								printf("store side [%d] for attempt [%d]\n", side, attempt_index)
								attempts_sides[attempt_index] = side
								//store attempt orientation
								WalkerGetDir(walker, attempt_orientation)
								attempts_orientations[attempt_index] = attempt_orientation
								printf("store orientation [%d, %d, %d] for attempt [%d] (gravity point at index [%d])\n", attempt_orientation[0], attempt_orientation[1], attempt_orientation[2], attempt_index, _square(walker))
								//set "in play" status for current attempt
								attempts_states[attempt_index] = 1
								//initialize attempt with arbitrary colors
								printf("initialize attempt [%d]\n", attempt_index)
								new attempt[SECRET_SIZE]
								attempts[attempt_index] = attempt
								for(new i = 0; i < SECRET_SIZE; i++) {
									attempts[attempt_index][i] = colors[0]
								}
							}
						}
						//game is lost and attempts are displayed
						else if(game_status == 2) {
							printf("switch to display secret\n")
							game_status = 3
						}
						//game is lost and secret are displayed
						else if(game_status == 3) {
							printf("switch to display attempts\n")
							game_status = 2
						}
					}
				}
			}
			AckMotion()
		}
		PrintCanvas()
		Sleep()
	}
}
