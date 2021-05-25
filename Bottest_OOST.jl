using DelimitedFiles

global SETTINGS = Dict() # Settings to import from csv file on startup
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

# Settings Handling
function ImportSettings()
    d = Dict()
	filename = joinpath(@__DIR__, "Settings.dnb")
	if isfile(filename)
        df = readdlm(filename, ':')
        for i in 1:size(df, 1)
            if !(df[i, 1] in keys(d))
                d[df[i,1]] = df[i, 2]
            end
        end
        return d
	else
    	CreateSettings(filename)
        df = readdlm(filename, ':')
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
    "PLAYSFIRST" => 1, #put one or two here (1 corresponds to playersign 1)
    "STARTCO" => [1, 2],
    "SPACINGX" => 16,
    "GRIDPOINT" => "+",
    "HORZLINE" => "-",
    "VERTLINE" => "|",
    "CURSORCHAR" => '0',
    "BOT_ON" => false
    ])
    Setting = []
    Value = []
    for key in keys(BaseSettings)
        push!(Setting, key)
        push!(Value, BaseSettings[key])
    end
    # sort array?

    open(filename, "w") do io
        writedlm(io, [Setting Value], ':')
    end
end
function fixsettings()
	global SETTINGS
	function converttochar(s)
		if isa(s, Int) || isa(s, Float64)
			s = string(s)
		end
		s = collect(s)
		return s[1]
	end
	function converttoarray(sarr)
		sarr = sarr[2:end-1]
		sarr = split(sarr, ",")
		sarr = parse.(Int, sarr)
		return sarr
	end
	SETTINGS["CURSORCHAR"] = converttochar(SETTINGS["CURSORCHAR"])
	SETTINGS["STARTCO"] = converttoarray(SETTINGS["STARTCO"])
	SETTINGS["GRIDPOINT"] = string(SETTINGS["GRIDPOINT"])
end

function GridToPrint(grid::Array, co::Array)
		cox = co[1]
		coy = co[2]

		gridprint = fill("", (size(grid, 1), size(grid, 2)))
        for y in 1:size(grid, 1)
        	if y%2 != 0 # Uneven lines (with dots)
	            for x in 1:size(grid, 2)
	                if grid[y, x] == -1
	                    gridprint[y, x] = "\x1b[$(coy);$(cox)H"*SETTINGS["GRIDPOINT"]
	                    cox += length(SETTINGS["GRIDPOINT"])
	                elseif grid[y,x] == 1 # Player 1 -> Red
	                    gridprint[y, x] = "\x1b[$(coy);$(cox)H"*ANSI.red(SETTINGS["HORZLINE"])^SETTINGS["SPACINGX"]
	                    cox += length(SETTINGS["HORZLINE"]^SETTINGS["SPACINGX"])
	                elseif grid[y,x] == 2 # Player 2 -> Blue
	                    gridprint[y, x] = "\x1b[$(coy);$(cox)H"*ANSI.cyan(SETTINGS["HORZLINE"])^SETTINGS["SPACINGX"]
	                    cox += length(SETTINGS["HORZLINE"]^SETTINGS["SPACINGX"])
	                elseif grid[y,x] == 0 || grid[y,x] == 8 # No one -> Colorless
                    	gridprint[y, x] = "\x1b[$(coy);$(cox)H"*SETTINGS["HORZLINE"]^SETTINGS["SPACINGX"]
                    	cox += length(SETTINGS["HORZLINE"]^SETTINGS["SPACINGX"])
	                end
	            end
        	else # Even lines
        		for i in 1:round(SETTINGS["SPACINGX"]/2-1)
        			y = Int(y) # Otherwise errors
        			coy+=1
        			middlex = Int(round(SETTINGS["SPACINGX"]/2-1))
        			middley = round(round(SETTINGS["SPACINGX"]/2)/2)
	        		for x in 1:size(grid, 2)
		                if grid[y, x] == -2
		                   	gridprint[y, x] *= "\x1b[$(coy);$(cox)H"*" "
		                    cox += length(" ")
		                elseif grid[y, x] == 10
		                	middlesign = Int(round(length(SETTINGS["PLAYERSIGN1"])/2))
		                	if i == middley
		                		gridprint[y, x] = "\x1b[$(coy);$(cox-middlex-middlesign)H"*ANSI.red(SETTINGS["PLAYERSIGN1"])
		                	end
		                	cox += 1
	                	elseif grid[y, x] == 20
	                		middlesign = Int(round(length(SETTINGS["PLAYERSIGN2"])/2))
	                		if i == middley
	                			gridprint[y, x] = "\x1b[$(coy);$(cox-middlex-middlesign)H"*ANSI.cyan(SETTINGS["PLAYERSIGN2"])
	                		end
		                	cox += 1
		                elseif grid[y,x] == 1
		                    gridprint[y, x] *= "\x1b[$(coy);$(cox)H"*ANSI.red(SETTINGS["VERTLINE"])
		                    cox += SETTINGS["SPACINGX"]
		                elseif grid[y,x] == 2
		                    gridprint[y, x] *= "\x1b[$(coy);$(cox)H"*ANSI.cyan(SETTINGS["VERTLINE"])
		                    cox += SETTINGS["SPACINGX"]
		                elseif grid[y,x] == 0 || grid[y,x] == 8
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


function Bot(grid::Array)
	global SETTINGS # bot needs to knnow who starts
	# 4x4 dots -> second player wins, assuming perfect play
	# http://www.gcrhoads.byethost4.com/DotsBoxes/dots_strategy.html?i=1

	function chainsInGame(grid::Array)
		Chains = Dict([])	# To keep track of chains
		History = []	# To keep track of places checked


		function InGrid(co)
			if co[1] > 0 && co[2] > 0 && co[1] <= size(grid, 2) && co[2] <= size(grid, 1)
				return true
			else
				return false
			end
		end
		function IsPartOfChain(co)
			# Other method to look around
			x = co[1] # For demonstrative purposes
			y = co[2]
			CellsAround = [
				(x, y-1),
				(x+1, y),
				(x, y+1),
		        (x-1, y)]
		    n_around = 0

	        for cell in CellsAround
	        	if InGrid(cell)
	        		if grid[cell[2],cell[1]] == 1 || grid[cell[2],cell[1]] == 2
	        			n_around += 1
	        		end
	        	end
	        end
	        if n_around == 2 || n_around == 3
	        	return true
	        else
	        	return false
	        end
	    end 

		function Around(co, startco)
			x = co[1] # For demonstrative purposes
			y = co[2]
			# Array of arrays (tuples are immutable)
			CellsAround = [
				[x,y],
				[x, y-1],
				[x+1, y],
				[x, y+1],
		        [x-1, y]]
		    for cell in CellsAround
		    	if InGrid(cell)
		    		if grid[cell[2],cell[1]] == 0 || grid[cell[2],cell[1]] == 8 || grid[cell[2],cell[1]] == -2 
		    			if cell == CellsAround[1]
		    				if !IsPartOfChain(cell)
		    					push!(History,cell)
		    					continue
		    				elseif !(cell in History)
		    					push!(History,cell)
		    				end
		    			elseif cell == CellsAround[2]
		    				cell[2] -= 1 # Move up
		    				if !InGrid(cell)
		    					continue
		    				else
		    					if !IsPartOfChain(cell)
		    						push!(History,cell)
		    						continue
		    					elseif !(cell in History)
		    						push!(Chains["$(startco)"],cell) # Tie current coordinate to array in dictionary - make chain of coordinates
		    					end
		    					if !(cell in History)
		    						push!(History,cell)
		    						Around(cell, startco)
		    					end
		    				end
		    			elseif cell == CellsAround[3]
		    				cell[1] += 1
		    				if !InGrid(cell)
		    					continue
		    				else
		    					if !IsPartOfChain(cell)
		    						push!(History,cell)
		    						continue
		    					elseif !(cell in History)
		    						push!(Chains["$(startco)"],cell)
		    					end
		    					if !(cell in History)
		    						push!(History,cell)
		    						Around(cell, startco)
		    					end
		    				end
		    			elseif cell == CellsAround[4]
		    				cell[2] += 1
		    				if !InGrid(cell)
		    					continue
		    				else
		    					if !IsPartOfChain(cell)
		    						push!(History,cell)
		    						continue
		    					elseif !(cell in History)
		    						push!(Chains["$(startco)"],cell)
		    					end
		    					if !(cell in History)
		    						push!(History,cell)
		    						Around(cell, startco)
		    					end
		    				end
		    			elseif cell == CellsAround[5]
		    				cell[1] -= 1
		    				if !InGrid(cell)
		    					continue
		    				else
		    					if !IsPartOfChain(cell)
		    						push!(History,cell)
		    						continue
		    					elseif !(cell in History)
		    						push!(Chains["$(startco)"],cell)
		    					end
		    					if !(cell in History)
		    						push!(History,cell)
		    						Around(cell, startco)
		    					end
		    				end
		    			end
		    		end
		    	end
		    end
		end

		for y in 1:size(grid, 1)
			for x in 1:size(grid, 2)
				if grid[y,x] == -2 && IsPartOfChain([x,y]) && !([x,y] in History)
            		Chains["$([x,y])"] = []
					Around([x,y], [x,y])
				end
			end
		end
		return Chains
	end

	

	function minimax(grid::GRID, depth::Int, isMax::Bool, scores::Array, h_max::Int)
		

		if depth == h_max
			return scores;
		end

		if isMax
			# Maximizing player

		else
			# Minimizing player

		end
		
	end

	Chains = chainsInGame(grid)
	return Chains


	"""
	n_chains = chainsInGame()
	LongChainRule = state.gh*state.gw + n_chains
	if LongChainRule%2 == 0
		# first player has control
	else
		#second player has control
	end
	"""
end

function CheckChains(Chains::Dict)
	n_LongChains = 0
	Lengths = []
	for i in 1:10
		push!(Lengths,i)
	end
	LengthChainDict = Dict([(key,[]) for key in Lengths])
	for i in keys(Chains)
		if length(Chains[i]) in 1:10
			push!(LengthChainDict[length(Chains[i])+1],i)
			println(LengthChainDict)
		end
	end
	for i in keys(LengthChainDict)
		if i >= 3 
			n_LongChains += length(LengthChainDict[i])
		end
	end		
	CleanDict(LengthChainDict)
	println(LengthChainDict)
	return n_LongChains
end

function CleanDict(dict)
	for i in keys(dict)
		if dict[i] == []
			delete!(dict,i)
		end
	end
end


function printarray(a::Array)
		println("\33[H")

		for i in 1:(round(SETTINGS["SPACINGX"]/2-1)*(4-1)+4+1)
			println()
		end
		println()
		println()
		show(stdout, "text/plain", a)
end

function test()
	global SETTINGS
		SETTINGS = ImportSettings()
		fixsettings()

	clearscreen()
	arr = [-1   1  -1   2  -1   1  -1;
			1  -2   1  -2   1  -2   1;  
		   -1   0  -1   0  -1   0  -1;
			2  -2   0  -2   2  -2   1;
		   -1   1  -1   1  -1   0  -1;
			0  -2   0  -2   1  -2   1;
		   -1   0  -1   0  -1   1  -1]

	printarray(arr)
	printstrgrid = GridToPrint(arr, SETTINGS["STARTCO"])
	gridstr = ""
	for y in 1:size(arr, 1)
		for x in 1:size(arr, 2)
			gridstr*=printstrgrid[y, x]
		end
	end
	println(gridstr)
	Chains = Bot(arr)
	n_longchains = CheckChains(Chains)
	println(n_longchains)
	println(Chains)
end
test()