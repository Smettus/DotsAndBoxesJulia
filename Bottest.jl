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



function Bot(testarray::Array)
	global SETTINGS # bot needs to knnow who starts
	# 4x4 dots -> second player wins, assuming perfect play

	# http://www.gcrhoads.byethost4.com/DotsBoxes/dots_strategy.html?i=1
	global ketens = 0

	#pseudocode to begin:
	# boven rechts onder links
	function chainsInGame()
		teller = 0 #lengte van 1 keten
		History = []
		function IsPartOfChain(co)
			amount = 0
			x = co[1]
			y = co[2]
			CellsAround = [
				(x, y - 1),
				(x + 1, y),
				(x, y + 1),
		        (x - 1, y)
		        ]
	        for j in CellsAround
	        	if ingrid(j)
	        		if testarray(j[2],j[1]) == 1 || testarray(j[2],j[1]) == 2
	        			amount += 1
	        		end
	        	end
	        end
	        if amount > 1
	        	return true
	        else
	        	return false
	        end
	    end 
		
		function Around(co)
			x = co[1]
			y = co[2]
			CellsAround = [
				(x,y),
				(x, y - 1),
				(x + 1, y),
				(x, y + 1),
		        (x - 1, y)
		        ]
		    for i in CellsAround
		    	if ingrid(i) #ook plaatsen waar al gechecked is TODO
		    		push!(History,i)
		    		if testarraygrid[i[2],i[1]] == 0 || testarraygrid[i[2],i[1]] == 8 || testarraygrid[i[2],i[1]] == -2
		    			if i == CellsAround[2]
		    				i[2] -= 1 
		    				if ! ingrid(i)
		    					continue
		    				else
		    					if IsPartOfChain(i)
		    						teller +=1
		    					else
		    						continue
		    					end
		    					Around(i)
		    					if teller >= 3 
		    						ketens += 1
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
				if !((x,y) in History)
					Around((x,y))
				end
			end
		end
		

	end
	"""
	n_chains = chainsInGame()

	LongChainRule = state.gh*state.gw + n_chains
	if LongChainRule%2 == 0
		# first player has control
	else
		#second player has control
	end
	"""
	return ketens
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

	@show Bot(arr)
end
test()
