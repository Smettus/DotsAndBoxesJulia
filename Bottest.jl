global SETTINGS = Dict() # Settings to import from csv file on startup
global BUFFER	# Keyboard input handling
global const GRID = Array{Int}


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
	        	# push was done here, but not right
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
		    # Mistake found: didn't add -2
		    for cell in CellsAround
		    	@show cell
		    	@show Chains
		    	if InGrid(cell)
		    		@show History	
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
		    						push!(Chains["$(startco)"],cell) # Tie current coordinate to array in dictionary - make chain of coordinates which are part of chain
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
				if grid[y,x] == -2 && IsPartOfChain([x,y])
					# another mistake: if -2, and no partofchain to begin, than just dont do it 
					#-> fixed by doing ispartofchain here, but changed ispartofchain: 
					# coordinate pushing now done later
					if !([x,y] in History) 
						println()
                		Chains["$([x,y])"] = []
						@show [x,y]
						@show Chains
						Around([x,y], [x,y])
					end
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


function printarray(a::Array)
		println("\33[H")
		show(stdout, "text/plain", a)
end

function test()
	clearscreen()
	arr = [-1  1 -1  1 -1  1 -1;
			1 -2  8 -2  1 -2 1;  
		   -1  0 -1  1 -1  0 -1;
		1 -2 1 -2 0 -2 1;
		-1 1 -1 1 -1 1 -1;
		2 -2 0 -2 0 -2 2;
		-1 1 -1 1 -1 2 -1]

	printarray(arr)
	println("->", Bot(arr))
end
test()