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



function Bot(testarraygrid::Array)

	global SETTINGS # bot needs to knnow who starts
	# 4x4 dots -> second player wins, assuming perfect play

	# http://www.gcrhoads.byethost4.com/DotsBoxes/dots_strategy.html?i=1

	# boven rechts onder links
	function chainsInGame(testarraygrid::Array)
		Chains = Dict([])
		History = [] # To keep track of boxes part of chains


		function InGrid(co) # TODO: if error is given (out of bounds access error -> return false)
			if co[1] > 0 && co[2] > 0 && co[1] <= size(testarraygrid, 2) && co[2] <= size(testarraygrid, 1)
				return true
			else
				return false
			end
		end
		function IsPartOfChain(co,startco)
			n_around = 0
			x = co[1] # for demonstrative purposes
			y = co[2]
			CellsAround = [
				(x, y-1),
				(x+1, y),
				(x, y+1),
		        (x-1, y)]

	        for j in CellsAround
	        	if InGrid(j)
	        		if testarraygrid[j[2],j[1]] == 1 || testarraygrid[j[2],j[1]] == 2
	        			n_around += 1
	        		end
	        	end
	        end
	        if n_around == 2 || n_around == 3
	        	push!(Chains["$(startco)"],co) 
	        	return true
	        else
	        	return false
	        end
	    end 
		# nu andere methode of rond te kijken
		function Around(co, startco)
			x = co[1] # for demonstrative purposes
			y = co[2]
			# array of array, tuples are immutable
			CellsAround = [
				[x,y],
				[x, y-1],
				[x+1, y],
				[x, y+1],
		        [x-1, y]]

		    for i in CellsAround
		    	if InGrid(i)
		    		@show i
		    		push!(History,i)
		    		#@show History
		    		if testarraygrid[i[2],i[1]] == 0 || testarraygrid[i[2],i[1]] == 8
		    			if i == CellsAround[1]
		    				if !IsPartOfChain(i,startco)
		    					continue
		    				end
		    			elseif i == CellsAround[2]
		    				i[2] -= 1 # Up
		    				if !(InGrid(i))
		    					continue # next iteration
		    				else
		    					if !IsPartOfChain(i, startco)
		    						continue
		    					end
		    					if !(i in History)
		    						Around(i, startco)
		    					end
		    				end
		    			elseif i == CellsAround[3]

		    			elseif i == CellsAround[4]

		    			elseif i == CellsAround[5]

		    			end
		    		end
		    	end
		    end
		end

		for y in 1:size(testarraygrid, 1)
			for x in 1:size(testarraygrid, 2)
				if testarraygrid[y,x] == -2
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

	Chains = chainsInGame(testarraygrid)
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
			1 -2  0 -2  1 -2 1;
		   -1  0 -1  1 -1  0 -1;
		1 -2 1 -2 0 -2 1;
		-1 0 -1 1 -1 1 -1;
		0 -2 0 -2 0 -2 0;
		-1 0 -1 0 -1 0 -1]

	printarray(arr)

	println(Bot(arr))
end
test()