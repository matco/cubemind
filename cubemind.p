/* Cubemind: a Mastermind-like game for the Futurocube */

#include <futurocube>

//max attempts matches the number of side of the cube (can be eventually decreased, but never increased)
const MAX_ATTEMPTS = 6
//secret size is fixed to 4 to use the corner of each side (do not touch this value, it can not be changed)
const SECRET_SIZE = 4
//configure colors that will be used for the game
new colors[]=[cORANGE, cMAGENTA, cPURPLE]

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

generate_secret() {
	for(new i = 0; i < SECRET_SIZE; i++) {
		secret[i] = colors[GetRnd(sizeof(colors))]
		//to debug, set secret to the second color
		//secret[i] = colors[1]
	}
	printf("secret generated [%x, %x, %x, %x]\n", secret[0], secret[1], secret[2], secret[3])
}

//cube position helpers
is_corner(square) {
	return square % 2 == 0 && square != 4
}

square_to_corner_index(side, orientation[3], square) {
	new i, w
	for(i = 0; i < 4; i++) {
		w = _w(side, 4)
		WalkerSetDir(w, orientation)
		WalkerMove(w, corner_index_to_step(i))
		if(_square(w) == square) {
			return i
		}
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

check_attempt(attempt[]) {
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
				if(i != j && attempt[i] == secret[j]) {
					result[result_index] = 1
					result_index++
					break
				}
			}
		}
	}
	return result
}

has_won(result[]) {
	for(new i = 0; i < SECRET_SIZE; i++) {
		if(result[i] != 2) {
			return 0
		}
	}
	return 1
}

//attempt UI related functions
draw_attempts() {
	new i, status, side, orientation[3]
	for(i = 0; i <= attempt_index; i++) {
		status = attempts_states[i]
		if(status > 0) {
			//retrieve side and orientation associated to attempt
			side = attempts_sides[i]
			orientation = attempts_orientations[i]
			//draw attempt
			draw_attempt(attempts[i], side, orientation)
			//draw attempts result if it has been validated
			if(status == 2) {
				draw_attempt_result(attempts_results[i], side, orientation)
			}
		}
	}
}

draw_attempt(attempt[], side, orientation[3]) {
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
		SetColor(attempt[i])
		DrawPoint(w)
	}
}

draw_attempt_result(result[], side, orientation[3]) {
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

main() {
	//initialize variables
	cellset(attempts_sides, -1)

	generate_secret()

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
		new square = _square(cursor)
		new walker = _w(side, 4)
		//printf("cursor is [%d], side is [%d], square is [%d]\n", cursor, side, square)

		new attempt_state = attempts_states[attempt_index]
		new attempt_orientation[3]
		attempt_orientation = attempts_orientations[attempt_index]

		//determine if a new side is being chosen
		//it can be the beginning of the game, in which case attempt index has not been initialized yet
		if(attempt_state == 0 && !is_side_used(side)) {
			SetColor(BLUE)
			//draw the gravity point at the bottom
			WalkerDirUp(walker)
			WalkerMove(walker, STEP_BACKWARDS)
			DrawFlicker(walker)
		}

		//highlight current cursor if the current attempt is running and the cursor side is the same as the attempt side
		if(attempt_state == 1 && attempts_sides[attempt_index] == side && is_corner(square)) {
			SetColor(attempts[attempt_index][square_to_corner_index(side, attempt_orientation, square)])
			DrawFlicker(cursor)
		}

		//detect motion
		new motion = Motion()
		if(motion) {
			//retrieve tap side
			//new tapside
			//GetTapSide(tapside)
			new taptype = GetTapType(cursor)
			switch(taptype) {
				//side
				case 1: {
					if(attempt_state == 1 && is_corner(square)) {
						//retrieve matching corner index
						new corner_index = square_to_corner_index(side, attempt_orientation, square)
						//retrieve index of current color
						new color_index
						for(color_index = 0; color_index < sizeof(colors); color_index++) {
							if(attempts[attempt_index][corner_index] == colors[color_index]) {
								break
							}
						}
						printf("retrieved color [%x] at index [%d]\n", colors[color_index], corner_index)
						//find next color
						color_index = (color_index + 1) % sizeof(colors)
						//switch color
						attempts[attempt_index][corner_index] = colors[color_index]
						printf("store color [%x] at index [%d]\n", colors[color_index], corner_index)
					}
				}
				//top
				case 2: {
					//validate attempt
					if(_is(motion, TAP_DOUBLE)) {
						//check that attempt can be validated
						//it must not have already been validated
						if(attempt_state == 1) {
							Vibrate(150)
							//lock the attempt
							printf("lock attempt [%d]\n", attempt_index)
							attempts_states[attempt_index] = 2
							//checking attempt and store result
							printf("check attempt [%d]\n", attempt_index)
							new result[SECRET_SIZE]
							result = check_attempt(attempts[attempt_index])
							printf("store result [%d, %d, %d, %d]\n", result[0], result[1], result[2], result[3])
							attempts_results[attempt_index] = result
							//stop game if it is won
							if(has_won(result)) {
								Melody("name:d=4,o=5,b=125:p,8p,16b,16a,b")
								printf("game won\n")
							}
							else {
								printf("attempt [%d] failed\n", attempt_index)
								if(attempt_index < MAX_ATTEMPTS - 1) {
									//prepare new attempt
									attempt_index++
								}
								else {
									Melody("name:d=4,o=5,b=125:p,16p,8b,16a,b")
									printf("game over\n")
								}
							}
						}
					}
					else {
						//check that attempt side has not been chosen yet
						if(attempt_state == 0 && !is_side_used(side)) {
							//choose this side for the attempt
							printf("store side [%d] for attempt [%d]\n", side, attempt_index)
							attempts_sides[attempt_index] = side
							//store attempt orientation
							WalkerGetDir(walker, attempt_orientation)
							attempts_orientations[attempt_index] = attempt_orientation
							printf("store orientation [%d, %d, %d] (gravity point at index [%d]) for attempt [%d]\n", attempt_orientation[0], attempt_orientation[1], attempt_orientation[2], _square(walker), attempt_index)
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
				}
			}
			AckMotion()
		}
		PrintCanvas()
		Sleep()
	}
}
