#######################<---Dots And Boxes V1--->#######################
"""
  1  7777777 555555
 111     777 55
  11    777  555555
  11   777      5555
 111  777    555555

	Created by: Tim De Smet, Tomas Oostvogels
	Last edit: 30/04/2021
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
		

		//Maken in NativeSVG / Pluto (why not)
		
		Game Logic:

		Bot:
		Lezen Paper


		Opmaak, coole interface
		Check lpad()
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
        c -> "\e[40m$c\e[0m" # Black
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
    "OQ" => "F2",
    "OR" => "F3",
    "OS" => "F4",
    "[15~" => "F5",
    "[17~" => "F6",
    "[18~" => "F7",
    "[19~" => "F8",
    "[20~" => "F9",
    "[21~" => "F10",
    "[23~" => "F11",
    "[24~" => "F12",
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
       	 	return esc_codes[esc_s]
    	elseif Int(s) in 0:31
        	return ctrl_codes[Int(s)]
    	else
       		return string(s)
    	end
    end
end

# Keys
global const KEY_ESC = "ESC"
global const KEY_Q = "q"
global const KEY_Z = "z"
global const KEY_S = "s"
global const KEY_D = "d"
global const KEY_R = "r"

# Cursor
mutable struct cursor
	x::Int
	y::Int
end

hidecursor() = print("\e[?25l") # test \x1b[?25l
showcursor() = println("\e[?25h")
function clearscreen()
	# move cursor to beginning, then to end then again begin
	println("\33[H")
	println("\33[J")
	println("\33[H")
	hidecursor()
end


#######################<---After choice--->#######################
# TO DO: functions available to all, both GameZero and REPL
global const GRID_WIDTH = 5
global const GRID_HEIGHT = 5
global const GRID = Array{Int}

mutable struct GameState
	gw::Int # Grid width
	gh::Int # Grid height
	grid::GRID # Grid itself
	gameover::Bool
	GameState(	gw = GRID_WIDTH,
				gh = GRID_HEIGHT,
				grid = resetGrid(gw, gh),
				gameover = false
			) = new(gw, gh, grid, gameover)
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
	# TODO
	co = [x, y]

	around = 0
	for y in 2:2:state.gh-1
		for x in 2:2:state.gw-1
			if state.grid[y, x] == -2
				# onder boven links rechts
				for dy in -1:2:1
					if state.grid[y+dy, x] != 0
						around+=1
					end
				end
				for dx in -1:2:1
					if state.grid[y, x+dx] != 0
						around+=1
					end
				end
			end
		end
	end

end

#######################<---REPL GAME MODE--->#######################
function REPLMODE()
	# Makes String array of grid, to easy change and later print
	function GridToPrint(state::GameState)
		GRIDPOINT = ["+", "██"]
		LINE = ["-", "="]
		VERTLINE = ["|"]
		spacingx = 8
		# startcoordinaat doorgeven TODO: tuple
		cox = 1
		coy = 1

		gridprint = ""

        for y in 1:2*state.gh-1
        	if y%2 != 0
	            for x in 1:2*state.gw-1
	                if state.grid[y, x] == -1
	                    gridprint *= "\x1b[$(coy);$(cox)H"
	                    gridprint *= GRIDPOINT[1]
	                    cox += length(GRIDPOINT[1])
	                elseif state.grid[y, x] == -2
	                    gridprint *= "\x1b[$(coy);$(cox)H"
	                    gridprint *= " "
	                    cox += length(" ")
	                elseif state.grid[y,x] == 1
	                    gridprint *= "\x1b[$(coy);$(cox)H"
	                    gridprint *= ANSI.red(LINE[1])^spacingx
	                    cox += length(ANSI.red(LINE[1])^spacingx)
	                elseif state.grid[y,x] == 2
	                    gridprint *= "\x1b[$(coy);$(cox)H"
	                    gridprint *= ANSI.blue(LINE[1])^spacingx
	                    cox += length(ANSI.red(LINE[1])^spacingx)
	                elseif state.grid[y,x] == 0
                    	gridprint *= "\x1b[$(coy);$(cox)H"
                    	gridprint *= LINE[1]^spacingx
                    	cox += length(LINE[1]^spacingx)
	                end
	            end
        	else
        		# -1 erbij
        		for i in 1:spacingx/2-1
        			coy+=1
	        		for x in 1:2*state.gw-1
		                if state.grid[y, x] == -1
		                    gridprint *= "\x1b[$(coy);$(cox)H"
		                    gridprint *= GRIDPOINT[1]
		                    cox += length(GRIDPOINT[1])
		                elseif state.grid[y, x] == -2
		                    gridprint *= "\x1b[$(coy);$(cox)H"
		                    gridprint *= " "
		                    cox += length(" ")
		                elseif state.grid[y,x] == 1
		                    gridprint *= "\x1b[$(coy);$(cox)H"
		                    gridprint *= ANSI.red(VERTLINE[1])
		                    cox += length(ANSI.red(VERTLINE[1]))
		                elseif state.grid[y,x] == 2
		                    gridprint *= "\x1b[$(coy);$(cox)H"
		                    gridprint *= ANSI.blue(VERTLINE[1])
		                    cox += length(ANSI.red(VERTLINE[1]))
		                elseif state.grid[y,x] == 0 
	                    	gridprint *= "\x1b[$(coy);$(cox)H"
	                    	gridprint *= VERTLINE[1]
	                    	cox += spacingx
		                end
		            end
		            cox = 1
	        	end
	        	coy+=1
	        end
            cox = 1
        end
        gridprint
	end

	function cursorthing()

	end

	# Draws Grid (old)
	function DrawGridREPL(state::GameState, grid::GRID)
		GRIDPOINT = ["+", "██"]
		spacingx = 4 # Number of chars in between, put even number (square) (actually half of spacing)
		# spacingy = 1 # TODO, for now 1-1 link with spacingx -> draws square
		for y in 1:2*state.gh-1
			for x in 1:2*state.gw-1
				if grid[y, x] == -1
					print(GRIDPOINT[1])
				elseif grid[y, x] == 1
					print(ANSI.red("-")^spacingx)
				elseif grid[y, x] == 2
					print(ANSI.blue("-")^spacingx)
				else
					print(" ")
				end
				print(" "^spacingx)
			end
			for i in 1:round(spacingx/2)
				println()
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

		InitiateGrid(state)
		Initiate_Keyboard_Input()

		 # Clear entire console screen
    	clearscreen()

    	#p = GridToPrint(state, state.grid)

    	# Game loop
		while !state.gameover
			sleep(0.05)

			if UPDATE
				hidecursor()
				clearscreen()
			
				str = GridToPrint(state)
				println(str)
				printarray(state.grid)
				#printarray(p)
				UPDATE = false
			end

			# Key input
			key = readinput()
			if key == KEY_R
				state.gameover = true
				println("Restart")
			elseif key == KEY_Z || key == "Up"
			
			elseif key == KEY_S || key == "Down"

			elseif key == KEY_D || key == "Right"
				
			elseif key == KEY_ESC || key == "Left"
				
			end

			# Game Logic

		end

		println("exit")
		exit()
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