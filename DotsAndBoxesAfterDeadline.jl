#######################<---Dots And Boxes--->#######################
"""
  1  7777777 555555
 111     777 55
  11    777  555555
  11   777      5555
 111  777    555555
	Created by: Tim De Smet, Tomas Oostvogels
	Last edit: 09/05/2021 @2215
--------------------------------------------------------------------
	IDEAS
		- Startup menu: choose between which mode, REPL or GameZero
		- Normal mode, level of difficulty
		- (Then cooler modes: square, triangle, hexagon, ..., easy/mediocre/hard..., choice mode (check if possible))
		- Timer
		- Output of score/game overview to text file
		- Cool visuals, interface design
"""
#using BenchmarkTools
#using CPUTime
#using GameZero
#using Colors
using CSV 
using DataFrames

global SETTINGS = Dict() # Settings to import from csv file
global BUFFER	# Keyboard input handling
global const GRID = Array{Int}

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
global const KEY_ESC = "ESC"
global const KEY_ENTER = "Enter"
global const KEY_Q = "q"
global const KEY_Z = "z"
global const KEY_S = "s"
global const KEY_D = "d"
global const KEY_R = "r"
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

# Settings handling
function ImportSettings()
    d = Dict()
	filename = joinpath(@__DIR__, "DotsAndBoxesSettings.csv")
	if isfile(filename)
        df = CSV.read(filename, DataFrame)
        for i in 1:size(df, 1)
            if !(df[i, 1] in keys(d))
                d[df[i,1]] = df[i, 2]
            end
        end
        return d
	else
    	CreateSettings(filename)
        df = CSV.read(filename, DataFrame)
        for i in 1:size(df, 1)
            if !(df[i, 1] in keys(d))
                d[df[i,1]] = df[i, 2]
            end
        end
        return d
	end
end
function CreateSettings(filename::String)
    BaseSettings = Dict([
    "GRID_WIDTH" => 4,
    "GRID_HEIGHT" => 4,
    "PLAYERSIGN1" => "Player1",
    "PLAYERSIGN2" => "Player2",
    "STARTCO" => [1, 2],
    "SPACINGX" => 16,
    "GRIDPOINT" => "+",
    "HORZLINE" => "-",
    "VERTLINE" => "|",
    "CURSORCHAR" => '0'
    ])
    basesett = DataFrame( Setting = ["GRID_WIDTH", "GRID_HEIGHT", "PLAYERSIGN1", "PLAYERSIGN2", "STARTCO", "SPACINGX", "GRIDPOINT", "HORZLINE", "VERTLINE", "CURSORCHAR"],
                        Value = [BaseSettings["GRID_WIDTH"], BaseSettings["GRID_HEIGHT"], BaseSettings["PLAYERSIGN1"], BaseSettings["PLAYERSIGN2"], BaseSettings["STARTCO"], BaseSettings["SPACINGX"], BaseSettings["GRIDPOINT"], BaseSettings["HORZLINE"], BaseSettings["VERTLINE"], BaseSettings["CURSORCHAR"]])
    CSV.write(filename, basesett)
end
function fixsettings()
	global SETTINGS
	SETTINGS["SPACINGX"] = parse(Int, SETTINGS["SPACINGX"])
	#SETTINGS["CURSORCHAR"] = parse(Char, SETTINGS["CURSORCHAR"])
	#SETTINGS["STARTCO"] = parse(Array, SETTINGS["STARTCO"])
	SETTINGS["CURSORCHAR"] = '0'
	SETTINGS["STARTCO"] = [1, 2]
end
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
       	 	if haskey(esc_codes, esc_s)
       	 		return esc_codes[esc_s]
       	 	end
    	elseif Int(s) in 0:31
        	return ctrl_codes[Int(s)]
    	else
       		return string(s)
    	end
    end
end
# REPL Graphics Stuff
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
	#println("\x1b[42m")
	println("\33[H")
	println("\33[J")
	println("\33[H")
	hidecursor()
end

########<---- Game Logic and stuff ---->#############
mutable struct GameState
	gw::Int # Grid width
	gh::Int # Grid height
	grid::GRID # Grid itself
	gameover::Bool
	player::Int # Player turn, 1 or 2
	score::Array # Score[playerone, playertwo]
	GameState(	gw = parse(Int, SETTINGS["GRID_WIDTH"]),
				gh = parse(Int, SETTINGS["GRID_HEIGHT"]),
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

function Bot()

end
#######################<---REPL GAME MODE--->#######################
function REPLMODE()
	global SETTINGS
	# TODO: Make Layout struct
	startco = [1, 2]
	spacingx = 16
	#spacingy = 3
	GRIDPOINT = "+" # "██"
	HORZLINE = "-" # "="
	VERTLINE = "|"
	CURSORCHAR = '0'
	PLAYERSIGN = ["Player1", "Player2"]

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
				if string(element[i]) == SETTINGS["HORZLINE"]
					element[i] = SETTINGS["CURSORCHAR"]
				end
			end
		else
			for i in 1:length(element)
				if string(element[i]) == SETTINGS["VERTLINE"]
					element[i] = SETTINGS["CURSORCHAR"]
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
	                    gridprint[y, x] = "\x1b[$(coy);$(cox)H"*SETTINGS["GRIDPOINT"]
	                    cox += length(SETTINGS["GRIDPOINT"])
	                elseif state.grid[y,x] == 1 # Player 1 -> Red
	                    gridprint[y, x] = "\x1b[$(coy);$(cox)H"*ANSI.red(SETTINGS["HORZLINE"])^SETTINGS["SPACINGX"]
	                    cox += length(SETTINGS["HORZLINE"]^SETTINGS["SPACINGX"])
	                elseif state.grid[y,x] == 2 # Player 2 -> Blue
	                    gridprint[y, x] = "\x1b[$(coy);$(cox)H"*ANSI.cyan(SETTINGS["HORZLINE"])^SETTINGS["SPACINGX"]
	                    cox += length(SETTINGS["HORZLINE"]^SETTINGS["SPACINGX"])
	                elseif state.grid[y,x] == 0 || state.grid[y,x] == 8 # No one -> Colorless
                    	gridprint[y, x] = "\x1b[$(coy);$(cox)H"*HORZLINE^SETTINGS["SPACINGX"]
                    	cox += length(SETTINGS["HORZLINE"]^SETTINGS["SPACINGX"])
	                end
	            end
        	else # Even lines
        		for i in 1:round(SETTINGS["SPACINGX"]/2-1)
        			y = Int(y) # Otherwise errors
        			coy+=1
        			middlex = Int(round(SETTINGS["SPACINGX"]/2-1))
        			middley = round(round(SETTINGS["SPACINGX"]/2-1)/2)
	        		for x in 1:size(state.grid, 2)
		                if state.grid[y, x] == -2
		                   	gridprint[y, x] *= "\x1b[$(coy);$(cox)H"*" "
		                    cox += length(" ")
		                elseif state.grid[y, x] == 10
		                	middlesign = Int(round(length(SETTINGS["PLAYERSIGN1"])/2))
		                	if i == middley
		                		gridprint[y, x] = "\x1b[$(coy);$(cox-middlex-middlesign)H"*ANSI.red(SETTINGS["PLAYERSIGN1"])
		                	end
		                	cox += 1
	                	elseif state.grid[y, x] == 20
	                		middlesign = Int(round(length(SETTINGS["PLAYERSIGN2"])/2))
	                		if i == middley
	                			gridprint[y, x] = "\x1b[$(coy);$(cox-middlex-middlesign)H"*ANSI.cyan(SETTINGS["PLAYERSIGN2"])
	                		end
		                	cox += 1
		                elseif state.grid[y,x] == 1
		                    gridprint[y, x] *= "\x1b[$(coy);$(cox)H"*ANSI.red(SETTINGS["VERTLINE"])
		                    cox += SETTINGS["SPACINGX"]
		                elseif state.grid[y,x] == 2
		                    gridprint[y, x] *= "\x1b[$(coy);$(cox)H"*ANSI.cyan(SETTINGS["VERTLINE"])
		                    cox += SETTINGS["SPACINGX"]
		                elseif state.grid[y,x] == 0 || state.grid[y,x] == 8
	                    	gridprint[y, x] *= "\x1b[$(coy);$(cox)H"*SETTINGS["VERTLINE"]
	                    	cox += SETTINGS["SPACINGX"]
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

	function PrintInformation(state::GameState, printgrid::Array)
		a = printgrid[1, end] # Take out the cross element on top row to get coordinate
		a *= "\x1b[10C" # Move cursor forward by 10 spaces
		if state.player == 1
				println(a*ANSI.red("Player 1's turn"))
		elseif state.player == 2
				println(a*ANSI.cyan("Player 2's turn"))
		end
		a *=  "\x1b[1B" # Move cursor down
		for i in 1:2
			a *= "\x1b[1B"
			print(a*"Score Player $i: ", "$(state.score[i])")
		end
	end

	function HelpMenu()
		clearscreen()
		printer::Bool = true
		while true
			sleep(0.05)
			key = readinput()

			if printer == true
				println(ANSI.yellow("HELP MENU"))
				println()
				println("Movement")
				println("	Press Z or Up to move the cursor up")
				println("	Press S or Down to move the cursor down")
				println("	Press Q or Left to move the cursor to the left")
				println("	Press D or Right to move the cursor to the right")
				println("	Press ENTER to cross a line")
				println("Other")
				println("	Press F2 to access the settings menu")
				println("	Press Ctrl-L to refresh the screen")
				println("	Press Ctrl-R to restart the game")
				println("	Press Ctrl-C to exit game")
				println()
				println(ANSI.yellow("Press ? or F1 to return to the game"))
				printer = false
			end
			if key == "?" || key == "F1"
				break
			end
		end
	end

	function SettingsREPL(state::GameState)
		# More beautiful and intuitive -> more code
		while true
			sleep(0.05)
			key = readinput()

			SETTINGS = ImportSettings()
			if key == "F2"
				fixsettings()
				break
			end
		end
	end

	function EndGame(state::GameState)
		a = "\x1b[10;20C"
		if state.score[1] > state.score[2]
			println(a*"╔────────────────────────╗")
        	println("║    "*ANSI.red("Player 1 wins!")*"      ║")
        	println("╚────────────────────────╝")
		elseif state.score[1] < state.score[2]
			println(a*"╔────────────────────────╗")
        	println("║    "*ANSI.cyan("Player 2 wins!")*"      ║")
        	println("╚────────────────────────╝")
		else
			println(a*ANSI.green("DRAW"))
		end
		println()
		println("Press CTRL-R to restart or CTRL-C to exit")
	end

	# Debugging
	function printarray(a::Array, state::GameState)
		for i in 1:(round(SETTINGS["SPACINGX"]/2-1)*(state.gh-1)+state.gh+1-4)
			println()
		end
		show(stdout, "text/plain", a)
	end

	# Game loop function
	function DotsAndBoxesREPL()
		global SETTINGS
		SETTINGS = ImportSettings()
		fixsettings()
		state::GameState = GameState()

		UPDATE::Bool = true 	# Only update screen if something has happened (ie key press)
		RESTART::Bool = false	# To play directly again

		InitiateGrid(state)
		Initiate_Keyboard_Input()
		cursor = CursorStruct(2, 1)

		prevgrid = state.grid[:,:] # To check for changes
		printstrgrid = GridToPrint(state, SETTINGS["STARTCO"])
		printstrcursor = CursorInGameMove(state, cursor, printstrgrid)

		 # Clear entire console screen (top line has to be cleared by user in beginning)
    	clearscreen()
    	
    	# Game loop
		while !state.gameover
			sleep(0.05)
			printstrgrid = GridToPrint(state, SETTINGS["STARTCO"])

			# Key input
			key = readinput()
			if key == "Ctrl-R"
				state.gameover = true
				RESTART = true
			elseif key == "Ctrl-C"
				state.gameover = true
			elseif key == "Ctrl-L" # Refresh
				UPDATE = true
			elseif key == "?" || key == "F1"
				HelpMenu()
				UPDATE = true
			elseif key == "F2"
				SettingsREPL(state)
				state = GameState()
				InitiateGrid(state)
				printstrgrid = GridToPrint(state, SETTINGS["STARTCO"])
				printstrcursor = CursorInGameMove(state, cursor, printstrgrid)
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
					checkAround(state)

					# Update the score
					state.score[state.player] += boxes

					# Move cursor to beginning
					cursor.x = 2
					cursor.y = 1

					printstrgrid = GridToPrint(state, SETTINGS["STARTCO"])	# Update the grid (to later print) here, so that the function on next line can take the right information		
					printstrcursor = CursorInGameMove(state, cursor, printstrgrid)

					# Change turns, if no box is completed
					if !state.gameover
						if boxes == 0
							if state.player == 1
								state.player = 2
							elseif state.player == 2
								state.player = 1
							end
						end
					end
				end		
			end
		
			if UPDATE
				if state.score[1]+state.score[2] == (state.gh-1)*(state.gw-1)	
					clearscreen()
					EndGame(state)
					UPDATE = false
					continue # makes us stay in while loop (state.gameover is still false), in order to use key input
				end
				if !state.gameover
					clearscreen()
					printstrgrid = GridToPrint(state, SETTINGS["STARTCO"])
					PrintInformation(state, printstrgrid)

					# Print Grid
					#printarray(printstrgrid, state)
					#printarray(state.grid, state)
					gridstr = ""
					for y in 1:size(state.grid, 1)
						for x in 1:size(state.grid, 2)
							gridstr*=printstrgrid[y, x]
						end
					end
					println(gridstr)

					# Print Cursor
					println(printstrcursor)

					prevgrid = state.grid[:,:]
					UPDATE = false
				end
			end
		end

		if RESTART
			clearscreen()
			println("Restart")
			
			DotsAndBoxesREPL()
		else
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