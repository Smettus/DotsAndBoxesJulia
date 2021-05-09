#######################<---Dots And Boxes--->#######################
"""
  1  7777777 555555
 111     777 55
  11    777  555555
  11   777      5555
 111  777    555555
	Created by: Tim De Smet, Tomas Oostvogels
	Last edit: 09/05/2021 @1035
--------------------------------------------------------------------
	IDEAS
		- Startup menu: choose between which mode, REPL or GameZero
		- Normal mode, level of difficulty
		- (Then cooler modes: square, triangle, hexagon, ..., easy/mediocre/hard..., choice mode (check if possible))
		- Timer
		- Output of score/game overview to text file
		- Cool visuals, interface design
"""
#######################<---Startup in REPL--->#######################
using BenchmarkTools
using CPUTime
using GameZero
using Colors

# --- REPL (Graphics) stuff ---
# Colors - printstyled is also possible
struct ANSIColor
    red::Function
    bright_red::Function
    green::Function
    blue::Function
    bright_blue::Function
    yellow::Function
    magenta::Function
    cyan::Function
    white::Function
    black::Function
    rgb::Function
    ANSIColor() = new(
        c -> "\e[31m$c\e[0m", # Red
        c -> "\e[31;1m$c\e[0m", # Bright red
        c -> "\e[32m$c\e[0m", # Green
        c -> "\e[34m$c\e[0m", # Blue
        c -> "\e[34;1m$c\e[0m", # Bright blue
        c -> "\e[33m$c\e[0m", # Yellow
        c -> "\e[35m$c\e[0m", # Magenta
        c -> "\e[36m$c\e[0m", # Cyan
        c -> "\e[37m$c\e[0m", # White
        c -> "\e[40m$c\e[0m", # Black
        c -> "\x1b[38;2;55;223;206m" #test RGB
    )
end
global const ANSI = ANSIColor()

# Keyboard Input
global const esc_codes = Dict([
    "[A" => "Up",
    "[B" => "Down",
    "[C" => "Right",
    "[D" => "Left",
    "[F" => "End",
    "[H" => "Pos1",
    "[2~" => "Ins",
    "[3~" => "Del",
    "[5~" => "PgUp",
    "[6~" => "PdDown",
    "OP" => "F1",
    "[[A" => "F1",
    "OQ" => "F2",
    "[[B" => "F2",
    "OR" => "F3",
    "[[C" => "F3",
    "OS" => "F4",
    "[[D" => "F4",
    "[15~" => "F5",
    "[[E" => "F5",
    "[17~" => "F6",
    "[[F" => "F6",
    "[18~" => "F7",
    "[[G" => "F7",
    "[19~" => "F8",
    "[[H" => "F8",
    "[20~" => "F9",
    "[[I" => "F9",
    "[21~" => "F10",
    "[[J" => "F10",
    "[23~" => "F11",
    "[[K" => "F11",
    "[24~" => "F12",
    "[[L" => "F12",
    "\e" => "ESC"
])
global const ctrl_codes = Dict([
    0 => "Ctrl-2",
    1 => "Ctrl-A",
    2 => "Ctrl-B",
    3 => "Ctrl-C",
    4 => "Ctrl-D",
    5 => "Ctrl-E",
    6 => "Ctrl-F",
    7 => "Ctrl-G",
    8 => "Backspace",
    9 => "Tab",
    10 => "Ctrl-J",
    11 => "Ctrl-K",
    12 => "Ctrl-L",
    13 => "Enter",
    14 => "Ctrl-N",
    15 => "Ctrl-O",
    16 => "Ctrl-P",
    17 => "Ctrl-Q",
    18 => "Ctrl-R",
    19 => "Ctrl-S",
    20 => "Ctrl-T",
    21 => "Ctrl-U",
    22 => "Ctrl-V",
    23 => "Ctrl-W",
    24 => "Ctrl-X",
    25 => "Ctrl-Y",
    26 => "Ctrl-Z",
    27 => "Ctrl-3",
    29 => "Ctrl-5",
    30 => "Ctrl-6",
    31 => "Ctrl-7"
])
global BUFFER
function Initiate_Keyboard_Input()
	# https://discourse.julialang.org/t/wait-for-a-keypress/20218/4
	# https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/#Calling-C-and-Fortran-Code
	# https://stackoverflow.com/questions/56888266/how-to-read-keyboard-inputs-at-every-keystroke-in-julia
    global BUFFER
    ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
    BUFFER = Channel{Char}(100)
    @async while true
        put!(BUFFER, read(stdin, Char))
    end
end
function readinput()
	# TODO: problem when esc is hit -> SOLVED, but needs to be pressed twice
	global BUFFER
	global ctrl_codes
	global esc_codes
    if isready(BUFFER)
        s = take!(BUFFER)
        if s == '\e' # Escape
        	esc_s = ""
       		while isempty(esc_s) || !(esc_s[end] in ['A','B','C','D','F','H','P','Q','R','S','~', '\e'])
            	esc_s *= take!(BUFFER)
        	end
       	 	if haskey(esc_codes, esc_s) # Check whether key is in dictionary or not
       	 		return esc_codes[esc_s]
       	 	end
    	elseif Int(s) in 0:31
        	return ctrl_codes[Int(s)]
    	else
       		return string(s)
    	end
    end
end
# Keys
global const KEY_ESC = "ESC"
global const KEY_ENTER = "Enter"
global const KEY_Q = "q"
global const KEY_Z = "z"
global const KEY_S = "s"
global const KEY_D = "d"
global const KEY_R = "r"

# Cursor
mutable struct CursorStruct
	x::Int 
	y::Int
	CursorStruct(x, y) = new(x, y)
end
hidecursor() = print("\e[?25l") # Or \x1b[?25l
showcursor() = println("\e[?25h")

function clearscreen()
	# Move cursor to beginning, then clear to end then again begin
	println("\33[H")
	println("\33[J")
	println("\33[H")
	hidecursor()
end


#######################<---After choice--->#######################
# Functions available to all, both GameZero and REPL
global const GRID_WIDTH = 4
global const GRID_HEIGHT = 4
global const GRID = Array{Int}

mutable struct GameState
	gw::Int # Grid width
	gh::Int # Grid height
	grid::GRID # Grid itself
	gameover::Bool
	player::Int # Player turn
	score::Array
	GameState(	gw = GRID_WIDTH,
				gh = GRID_HEIGHT,
				grid = resetGrid(gw, gh),
				gameover = false,
				player = 1,
				score = [0, 0]
			) = new(gw, gh, grid, gameover, player, score)
end
function resetGrid(gw::Int, gh::Int)
	return zeros(Int, 2*gh-1, 2*gw-1)
end
function InitiateGrid(state::GameState)
	for y in 1:size(state.grid, 1)
		if y%2 != 0
			for x in 1:size(state.grid, 2)
				if x%2 != 0
					state.grid[y, x] = -1 # Dots
				end
			end
		else
			for x in 1:size(state.grid, 2)
				if x%2 == 0
					state.grid[y, x] = -2 # Midpoints (to be used by algorithm/bot)
				end
			end
		end
	end
end

function checkAround(state::GameState)
	boxcounter = 0
	around = 0
	for y in 1:size(state.grid, 1)
		for x in 1:size(state.grid, 2)
		around = 0
			if state.grid[y, x] == -2
				# Up-Down Left-Right
				for dy in -1:2:1
					if !(state.grid[y+dy, x] == 0 || state.grid[y+dy, x] == 8)# player one or two doestn care
						around+=1
					end
				end
				for dx in -1:2:1
					if !(state.grid[y, x+dx] == 0 || state.grid[y, x+dx] == 8)
						around+=1
					end
				end
				if around == 3
					for dy in -1:2:1
						if state.grid[y+dy, x] == 0
							state.grid[y+dy, x] = 8 # Randomly chosen, >=5
						end
					end
					for dx in -1:2:1
						if state.grid[y, x+dx] == 0
							state.grid[y, x+dx] = 8
						end
					end
				elseif around == 4
					for dy in -1:2:1
						if state.grid[y+dy, x] == 6
							state.grid[y, x] = 20
							boxcounter += 1
							# state.grid[y+dy, x] = 2 do not change yet! See next for loop
						elseif state.grid[y+dy, x] == 7
							state.grid[y, x] = 10
							boxcounter += 1
							# state.grid[y+dy, x] = 1 do not change yet!
						end
					end
					for dx in -1:2:1
						if state.grid[y, x+dx] == 6
							state.grid[y, x] = 20
							boxcounter += 1
							# state.grid[y, x+dx] = 2 do not change yet!
						elseif state.grid[y, x+dx] == 7
							state.grid[y, x] = 10
							boxcounter += 1
							# state.grid[y, x+dx] = 1 do not change yet!
						end
					end
				end
			end
		end
	end

	# Fix the lines taken, give them to the player who took them
	for y in 1:size(state.grid, 1)
		for x in 1:size(state.grid, 2)
			if state.grid[y, x] == 10
				for dy in -1:2:1
					if state.grid[y+dy, x] == 7
						state.grid[y+dy, x] = 1
					end
				end
				for dx in -1:2:1
					if state.grid[y, x+dx] == 7
						state.grid[y, x+dx] = 1
					end
				end
			elseif state.grid[y, x] == 20
				for dy in -1:2:1
					if state.grid[y+dy, x] == 6
						state.grid[y+dy, x] = 2
					end
				end
				for dx in -1:2:1
					if state.grid[y, x+dx] == 6
						state.grid[y, x+dx] = 2
					end
				end
			end
		end
	end
	return boxcounter
end

# Give box to the player who took it
function Difference(state::GameState, oldgrid::GRID)
	change = oldgrid - state.grid # Pointwise
	boxes::Int = 0
	for y in 1:size(state.grid, 1)
		for x in 1:size(state.grid, 2)
			if change[y, x] > 5
				state.grid[y, x] = change[y, x]
				if checkAround(state) == 2
					boxes += 2
				else
					boxes += 1
				end
			end
		end
	end
	return boxes
end

#######################<---REPL GAME MODE--->#######################
function REPLMODE()
	# TODO: Make Layout struct
	spacingx = 8
	spacingy = 3
	startco = [20, 20]
	GRIDPOINT = ["+", "██"]
	HORZLINE = ["-", "="]
	VERTLINE = ["|"]
	CURSORCHAR = '0'
	PLAYERSIGN = ["x", "y"]

	# Move cursor to discrete places, then return string with cursor to print
	function CursorInGameMove(state::GameState, cursor::CursorStruct, strgrid::Array)
		if cursor.x <= 1 && cursor.y%2 != 0
			cursor.x = 2 # Start here
		elseif cursor.x < 1 && cursor.y%2 == 0
			cursor.x = 1
		elseif cursor.x >= size(state.grid, 2) && cursor.y%2 != 0
			cursor.x = size(state.grid, 2)-1
		elseif cursor.x > size(state.grid, 2) && cursor.y%2 == 0
			cursor.x = size(state.grid, 2)
		elseif cursor.y > size(state.grid, 1)
			cursor.y = size(state.grid, 1)
			cursor.x += 1
		elseif cursor.y < 1
			cursor.y = 1
			cursor.x -= 1
		end
		# Get element out of stringgrid, change lines with cursor
		element = strgrid[cursor.y, cursor.x]
		element = collect(element)
		if cursor.y%2 != 0 # Uneven lines
			for i in 1:length(element)
				if string(element[i]) == HORZLINE[1]
					element[i] = CURSORCHAR
				end
			end
		else
			for i in 1:length(element)
				if string(element[i]) == VERTLINE[1]
					element[i] = CURSORCHAR
				end
			end
		end
		element = join(element)
		return element
	end

	# Grid with strings that will be printed
	function GridToPrint(state::GameState, co::Array)
		cox = co[1]
		coy = co[2]

		gridprint = fill("", (size(state.grid, 1), size(state.grid, 2)))
        for y in 1:size(state.grid, 1)
        	if y%2 != 0 # Uneven lines (with dots)
	            for x in 1:size(state.grid, 2)
	                if state.grid[y, x] == -1
	                    gridprint[y, x] = "\x1b[$(coy);$(cox)H"*GRIDPOINT[1]
	                    cox += length(GRIDPOINT[1])
	                elseif state.grid[y, x] == -2 
	                    gridprint[y, x] = "\x1b[$(coy);$(cox)H"*" "
	                    cox += length(" ")
	                elseif state.grid[y, x] == 10
	                	gridprint[y, x] = "\x1b[$(coy);$(cox)H"*ANSI.red(PLAYERSIGN[1])
	                	cox += length(PLAYERSIGN[1])
	                elseif state.grid[y, x] == 20
	                	gridprint[y, x] = "\x1b[$(coy);$(cox)H"*ANSI.cyan(PLAYERSIGN[2])
	                	cox += length(PLAYERSIGN[2])
	                elseif state.grid[y,x] == 1 # Player 1 -> Red
	                    gridprint[y, x] = "\x1b[$(coy);$(cox)H"*ANSI.red(HORZLINE[1])^spacingx
	                    cox += length((HORZLINE[1])^spacingx)
	                elseif state.grid[y,x] == 2 # Player 2 -> Blue
	                    gridprint[y, x] = "\x1b[$(coy);$(cox)H"*ANSI.cyan(HORZLINE[1])^spacingx
	                    cox += length((HORZLINE[1])^spacingx)
	                elseif state.grid[y,x] == 0 || state.grid[y,x] == 8 # No one -> Colorless
                    	gridprint[y, x] = "\x1b[$(coy);$(cox)H"*HORZLINE[1]^spacingx
                    	cox += length(HORZLINE[1]^spacingx)
	                end
	            end
        	else # Even lines
        		for i in 1:spacingx/2-1 # TODO: make spacingy // here, starts at 0
        			y = Int(y) # Otherwise errors
        			coy+=1
	        		for x in 1:size(state.grid, 2)
		                if state.grid[y, x] == -1
		                    gridprint[y, x] *= "\x1b[$(coy);$(cox)H"*GRIDPOINT[1]
		                    cox += length(GRIDPOINT[1])
		                elseif state.grid[y, x] == -2
		                   	gridprint[y, x] *= "\x1b[$(coy);$(cox)H"*" "
		                    cox += length(" ")
		                elseif state.grid[y, x] == 10
		                	gridprint[y, x] = "\x1b[$(coy);$(cox)H"*ANSI.red(PLAYERSIGN[1])
		                	cox += length(PLAYERSIGN[1])
	                	elseif state.grid[y, x] == 20
	                		gridprint[y, x] = "\x1b[$(coy);$(cox)H"*ANSI.cyan(PLAYERSIGN[2])
		                	cox += length(PLAYERSIGN[2])
		                elseif state.grid[y,x] == 1
		                    gridprint[y, x] *= "\x1b[$(coy);$(cox)H"*ANSI.red(VERTLINE[1])
		                    cox += spacingx
		                elseif state.grid[y,x] == 2
		                    gridprint[y, x] *= "\x1b[$(coy);$(cox)H"*ANSI.cyan(VERTLINE[1])
		                    cox += spacingx
		                elseif state.grid[y,x] == 0 || state.grid[y,x] == 8
	                    	gridprint[y, x] *= "\x1b[$(coy);$(cox)H"*VERTLINE[1]
	                    	cox += spacingx
		                end
		            end
		            cox = co[1]
	        	end
	        	coy+=1
	        end
            cox = co[1]
        end
        return gridprint
	end

	function Printscore(state::GameState)
		for i in 1:2
			println("Score Player $i: ", "$(state.score[i])")
		end
	end

	function HelpMenu()
		clearscreen()
		print::Bool = true
		while true
			sleep(0.05)
			key = readinput()

			if print == true
				println(ANSI.yellow("HELP MENU"))
				println()
				println("Movement")
				println("	Press Z or Up to move the cursor up")
				println("	Press S or Down to move the cursor down")
				println("	Press Q or Left to move the cursor to the left")
				println("	Press D or Right to move the cursor to the right")
				println("Other")
				println("	Press F2 for settings menu")
				println("	Press Ctrl-C to exit game")
				println("	Press ? or F1 to return to the game")
				print = false
			end
			if key == "?" || key == "F1"
				break
			end
		end
	end

	function Settings()
		clearscreen()
		print::Bool = true
		while true
			sleep(0.05)
			key = readinput()

			if print == true
				println(ANSI.yellow("SETTINGS"))
				println()
				println("1:", "Board length =") #TODO, but then state has to be reloaded.
				println()
				print = false
			end
			if key == "1"

			elseif key == "F2"
				break
			end
		end
	end

	# Debugging
	function printarray(a::Array)
		println()
		show(stdout, "text/plain", a)
		println()
	end

	# Game loop function
	function DotsAndBoxesREPL()
		state::GameState = GameState()

		UPDATE::Bool = true 	# Only update screen if something has happened (ie key press)
		RESTART::Bool = false	# To play directly again

		InitiateGrid(state)
		Initiate_Keyboard_Input()
		cursor = CursorStruct(2, 1)

		prevgrid = state.grid[:,:] # To check for changes
		printstrgrid = GridToPrint(state, startco)
		printstrcursor = CursorInGameMove(state, cursor, printstrgrid)

		 # Clear entire console screen
    	clearscreen()
    	
    	# Game loop
		while !state.gameover
			sleep(0.05)
			printstrgrid = GridToPrint(state, startco)

			# Key input
			key = readinput()
			if key == "Ctrl-R"
				state.gameover = true
				RESTART = true
			elseif key == "Ctrl-C"
				state.gameover = true
			elseif key == "Ctrl-L"
				UPDATE = true
			elseif key == "?" || key == "F1"
				HelpMenu()
				UPDATE = true
			elseif key == "F2"
				Settings()
				UPDATE = true
			elseif key == KEY_Z || key == "Up"
				UPDATE = true
				cursor.y -= 1
				cursor.x += 1
				printstrcursor = CursorInGameMove(state, cursor, printstrgrid)
			elseif key == KEY_S || key == "Down"
				UPDATE = true
				cursor.y += 1
				cursor.x -= 1
				printstrcursor = CursorInGameMove(state, cursor, printstrgrid)
			elseif key == KEY_D || key == "Right"
				UPDATE = true
				cursor.x += 2
				printstrcursor = CursorInGameMove(state, cursor, printstrgrid)
			elseif key == KEY_Q || key == "Left"
				UPDATE = true
				cursor.x -= 2
				printstrcursor = CursorInGameMove(state, cursor, printstrgrid)
			elseif key == KEY_ENTER
				UPDATE = true
				if state.grid[cursor.y,cursor.x] == 0 || state.grid[cursor.y,cursor.x] == 8
					state.grid[cursor.y,cursor.x] = state.player

					boxes = Difference(state, prevgrid)	# Give box to the player who took it

					# Update the score
					state.score[state.player] += boxes

					# Move cursor to beginning
					cursor.x = 2
					cursor.y = 1

					printstrgrid = GridToPrint(state, startco)	# Update the grid to later print here, so that the function on next line can take the right information		
					printstrcursor = CursorInGameMove(state, cursor, printstrgrid)

					# Change turns, if no box is completed
					if boxes == 0
						if state.player == 1
							state.player = 2
						elseif state.player == 2
							state.player = 1
						end
					end
				end				
			end
		
			if UPDATE
				clearscreen()

				if state.player == 1
					println(ANSI.red("Player 1's turn"))
				elseif state.player == 2
					println(ANSI.cyan("Player 2's turn"))
				end
				println()
				Printscore(state)

				# Print Grid
				printarray(state.grid)
				gridstr = ""
				for y in 1:size(state.grid, 1)
					for x in 1:size(state.grid, 2)
						gridstr*=printstrgrid[y, x]
					end
				end
				println(gridstr)

				# Print Cursor
				println(printstrcursor)

				checkAround(state)
				prevgrid = state.grid[:,:]
				UPDATE = false
			end
		end

		if RESTART
			clearscreen()
			println("Restart")
			
			DotsAndBoxesREPL()
		else
			# TODO move cursor to end
			clearscreen()
			println("Exit")
			exit()
		end
	end

	DotsAndBoxesREPL()
end

#######################<---GAMEZERO GAME MODE--->#######################
function GAMEZEROMODE()


end


#######################<---STARTUP--->#######################
# Startup function move brackets along the different choices
# for now: 
REPLMODE()
"""
function StartUp()
	Initiate_Keyboard_Input()
	clearscreen()
	println(ANSI.blue("Mode 1: REPL Game Mode"))
	println(ANSI.red("Mode 2: GameZero Mode"))
	println("Exit")
	while true
		sleep(0.05)
		key = readinput()
		if key  == "1"
			REPLMODE()
		elseif key == "2"
			println("pressed 2")
			GAMEZEROMODE()
		elseif key == "3"
			println("Goodbye")
			exit()
		end
	end
end
StartUp()
"""