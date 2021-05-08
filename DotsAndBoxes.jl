#######################<---Dots And Boxes V1--->#######################
"""
  1  7777777 555555
 111     777 55
  11    777  555555
  11   777      5555
 111  777    555555
	Created by: Tim De Smet, Tomas Oostvogels
	Last edit: 08/05/2021 @1600
--------------------------------------------------------------------
	IDEAS
		- Startup menu: choose between which mode, REPL or GameZero
		- Normal mode, level of difficulty
		- (Then cooler modes: square, triangle, hexagon, ..., easy/mediocre/hard..., choice mode (check if possible))
		- Timer
		- Output of score/game overview to text file
		- Cool visuals, interface design
	TO DO
		Grid Draw:
		Maken in REPL (+clock/timer rechtsboven)
		Maken in GameZero
		
		NO//Maken in NativeSVG / Pluto (why not)
		
		Game Logic:
		Bot:
		Lezen Paper
		YES!!!CHANGE EVERY 2*state.gw -1 thing to size(...)
"""
#######################<---Startup in REPL--->#######################
# TO DO: write startup screen (cool, graphics)
using BenchmarkTools
using CPUTime
using GameZero
using Colors

# --- REPL (Graphics) stuff ---
# Colors - maar blijkbaar bestaat er al een functie genaamd printstyled
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
# TO DO: functions available to all, both GameZero and REPL
global const GRID_WIDTH = 4
global const GRID_HEIGHT = 4
global const GRID = Array{Int}

mutable struct GameState
	gw::Int # Grid width
	gh::Int # Grid height
	grid::GRID # Grid itself
	gameover::Bool
	player::Int # Player turn
	score1::Int
	score2::Int
	GameState(	gw = GRID_WIDTH,
				gh = GRID_HEIGHT,
				grid = resetGrid(gw, gh),
				gameover = false,
				player = 1,
				score1 = 0,
				score2 = 0
			) = new(gw, gh, grid, gameover, player, score1, score2)
end
function resetGrid(gw::Int, gh::Int)
	return zeros(Int, 2*gh-1, 2*gw-1) # V1: use array, for points and places in between (later maybe: actually no array for points needed)
end
function InitiateGrid(state::GameState)
	# TODO: abstract this function, not with state.gh but with size(grid, 2)
	for y in 1:2*state.gh-1
		if y%2 != 0
			for x in 1:2*state.gw-1
				if x%2 != 0
					state.grid[y, x] = -1 # Dots
				end
			end
		else
			for x in 1:2*state.gw-1
				if x%2 == 0
					state.grid[y, x] = -2 # Midpoints (to be used by algorithm/bot)
				end
			end
		end
	end
end

function checkAround(state::GameState)
	around = 0
	for y in 1:2*state.gh-1
		for x in 1:2*state.gw-1
		around = 0
			if state.grid[y, x] == -2
				# Up Down Left Right
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
					for i in -1:2:1
						if state.grid[y+i, x] == 0
							state.grid[y+i, x] = 8 # Randomly chosen, >=5
						end
					end
					for j in -1:2:1
						if state.grid[y, x+j] == 0
							state.grid[y, x+j] = 8
						end
					end
				elseif around == 4
					for dy in -1:2:1
						if state.grid[y+dy, x] == 6
							state.grid[y, x] = 20
							state.grid[y+dy, x] = 2
						elseif state.grid[y+dy, x] == 7
							state.grid[y, x] = 10
							state.grid[y+dy, x] = 1
						end
					end
					for dx in -1:2:1
						if state.grid[y, x+dx] == 6
							state.grid[y, x] = 20
							state.grid[y, x+dx] = 2
						elseif state.grid[y, x+dx] == 7
							state.grid[y, x] = 10
							state.grid[y, x+dx] = 1
						end
					end
				end
			end
		end
	end
	copygrid  = state.grid[:,:]
	return copygrid
end

function Change(state::GameState, oldgrid::GRID)
	change = oldgrid - state.grid # Pointwise
	for y in 1:2*state.gh-1
		for x in 1:2*state.gw-1
			if change[y, x] > 5
				state.grid[y, x] = change[y, x]
				checkAround(state) 
			end
		end
	end
	return change
end

#######################<---REPL GAME MODE--->#######################
function REPLMODE()
	spacingx = 8
	spacingy = 3 # 3 newlines
	startco = [20, 20]
	GRIDPOINT = ["+", "██"]
	HORZLINE = ["-", "="]
	VERTLINE = ["|"]
	CURSORCHAR = '0'
	PLAYERSIGN = ["x", "y"]
	function CursorInGameMove(state::GameState, cursor::CursorStruct, strgrid::Array)
		if cursor.x <= 1 && cursor.y%2 != 0
			cursor.x = 2 # Start here
		elseif cursor.x < 1 && cursor.y%2 == 0
			cursor.x = 1
		elseif cursor.x >= 2*state.gw-1 && cursor.y%2 != 0
			cursor.x = 2*state.gw-2
		elseif cursor.x > 2*state.gw-1 && cursor.y%2 == 0
			cursor.x = 2*state.gw-1
		elseif cursor.y > 2*state.gh-1
			cursor.y = 2*state.gh-1
			cursor.x += 1
		elseif cursor.y < 1
			cursor.y = 1
			cursor.x -= 1
		end
		element = strgrid[cursor.y, cursor.x]
		element = collect(element)
		if cursor.y%2 != 0 # Uneven lines
			for i in 1:length(element)
				if string(element[i]) == HORZLINE[1]
					element[i] = CURSORCHAR
				end
			end
		elseif cursor.y%2 == 0
			for i in 1:length(element)
				if string(element[i]) == VERTLINE[1]
					element[i] = CURSORCHAR
				end
			end
		end
		element = join(element)
		return element
	end

	# Makes String array of grid, to easy change and later print
	# V2: makes entire grid itself, same dimensions as state.grid
	function GridToPrint(state::GameState, co::Array)
		cox = co[1]
		coy = co[2]

		#TODO: vertline fix... -> solution import new row each time spacingy

		gridprint = fill("", (2*state.gh-1, 2*state.gw-1))
        for y in 1:2*state.gh-1
        	if y%2 != 0 # Uneven lines
	            for x in 1:2*state.gw-1
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
        	else # Even lines (in terms of dots)
        		for i in 1:spacingx/2-1 # TODO: make spacingy // here, starts at 0
        			y = Int(y) # Gives otherwise errors
        			i = Int(i)
        			coy+=1
        			# Insert new row, length stays same as prev: doesnt work....
        			#newrow = fill("", 1, 2*state.gw-1)
        			#gridprint = [gridprint[1:y+i+1, :]; newrow; gridprint[y+1+i:end, :]]
        			#works now
	        		for x in 1:2*state.gw-1
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
        gridprint
	end

	function HelpMenu()
		clearscreen()
		UPDATE::Bool = true
		while true
			sleep(0.05)
			key = readinput()

			if UPDATE == true
				println(ANSI.cyan("HELP MENU"))
				println()
				println("Press Z/Up to move cursor up")
				println("...")
				println("Press Ctrl-C to exit game")
				println("Press ? or F1 to return to the game")
				UPDATE = false
			end
			if key == "?" || key == "F1"
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

		UPDATE::Bool = true # Only update screen if something has happened (ie key press)
		restart::Bool = false

		InitiateGrid(state)
		Initiate_Keyboard_Input()
		cursor = CursorStruct(2, 1) # 1, 1 ook goed
		oost = ""

		 # Clear entire console screen
    	clearscreen()
    	prevgrid = state.grid[:,:]
    	# Game loop
		while !state.gameover
			sleep(0.05)
			t = GridToPrint(state, startco)

			# Key input
			key = readinput()
			if key == KEY_R
				state.gameover = true
				restart = true
			elseif key == "Ctrl-C"
				state.gameover = true
			elseif key == "Ctrl-L"
				UPDATE = true
			elseif key == "?" || key == "F1"
				HelpMenu()
				UPDATE = true
			elseif key == KEY_Z || key == "Up"
				UPDATE = true
				cursor.y-=1
				cursor.x+=1
				oost = CursorInGameMove(state, cursor, t)
			elseif key == KEY_S || key == "Down"
				UPDATE = true
				cursor.y+=1
				cursor.x-=1
				oost = CursorInGameMove(state, cursor, t)
			elseif key == KEY_D || key == "Right"
				UPDATE = true
				cursor.x+=2
				oost = CursorInGameMove(state, cursor, t)
			elseif key == KEY_Q || key == "Left"
				UPDATE = true
				cursor.x-=2
				oost = CursorInGameMove(state, cursor, t)
			elseif key == "Enter"
				UPDATE = true
				if state.grid[cursor.y,cursor.x] == 0 || state.grid[cursor.y,cursor.x] == 8
					state.grid[cursor.y,cursor.x] = state.player
					cursor.x = 2
					cursor.y = 1
					t = GridToPrint(state, startco)				
					oost = CursorInGameMove(state, cursor, t)
					if state.player == 1
						state.player = 2
					elseif state.player == 2
						state.player = 1
					end
				end
				
				# call function Move with state, cursorx, cursor y
				# determine where on the board cursorx/y is // Same as the cursor output
				# place in state.grid value of state.player
				
			end
			# Game Logic
			



			# Print Output
			if UPDATE
				clearscreen()
				Change(state, prevgrid)
				@show state.player
				# Grid
				printarray(state.grid)
				gridstr = ""
				for y in 1:2*state.gh-1
					for x in 1:2*state.gw-1
						gridstr*=t[y, x]
					end
				end
				println(gridstr)

				# Cursor
				println(oost)
				#@show oost
				#@show cursor

				# Cursor
				#println(CursorInGameMove(cursor, startco)) 
				prevgrid = checkAround(state)
				UPDATE = false
			end
		end

		if restart
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