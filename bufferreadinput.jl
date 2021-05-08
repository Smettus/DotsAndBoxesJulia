# test for buffer readinput
"""
global BUFFER
function Initiate_Keyboard_Input()
	# https://discourse.julialang.org/t/wait-for-a-keypress/20218/4
    global BUFFER
    c = ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
    BUFFER = Channel{Char}(100)
    @async while true
        put!(BUFFER, read(stdin, Char))
    end
end
function readinput()
	global BUFFER
    if isready(BUFFER)
        take!(BUFFER)
    end
end

global const KEY_Q = 'q'
global const ESC = '\e'

function test()
	Initiate_Keyboard_Input()
	while true
		sleep(0.05)
		key = readinput()
		@show key
		if key == KEY_Q
			break
		elseif false
			println("ye")
		elseif isa(key, Char)
			#println("---"^15, "NEW", "---"^15)
			#println(@show key)
			#println(BUFFER)
			#println(key)
		end
	end
end
test()

"""



"""
function getc1()
    ret = ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid},Int32), stdin.handle, true)
    ret == 0 || error("unable to switch to raw mode")
    c = read(stdin, Char)  # string was "char", any doesnt work, way to control stringlength??, hmm hard
    ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid},Int32), stdin.handle, false)
    c
end
function getc2()
    t = REPL.TerminalMenus.terminal
    REPL.TerminalMenus.enableRawMode(t) || error("unable to switch to raw mode")
    c = Char(REPL.TerminalMenus.readKey(t.in_stream))
    REPL.TerminalMenus.disableRawMode(t)
    c
end


function teststackoverflow()
	println(getc1())
	#println(getc2())
end
teststackoverflow()
"""

"""
global BUFFER
function Initiate_Keyboard_Input()
	# https://discourse.julialang.org/t/wait-for-a-keypress/20218/4
    global BUFFER
    c = ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
    BUFFER = Channel{Any}(100) 
    @async while true
        put!(BUFFER, read(stdin, Char))
    end
end
function readinput()
	global BUFFER
    if isready(BUFFER)
        #take!(BUFFER)
        take!(BUFFER)
    end
end

function ownreadkey()
	Initiate_Keyboard_Input()
	k = 1
	while k==1
		sleep(0.05)
		key = readinput()
		#println(typeof(key))
		#println(BUFFER)
		if key != nothing
			println(key)
			for i in BUFFER
				if i == '\e'
					if i == '['
						if nextind(nextind(i)) == 'A'
							println("up")
						end
					end
				end
			end
		end
		if key == 'q'
			break
		end
		
		for i in BUFFER
			println(i)
			if i == 'q'
				k = 0
				break
			end
		end
	end
end
ownreadkey()

"""
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
    "[29~" => "Apps",
    "[34~" => "Win",
    "[1;2A" => "Shift-Up",
    "[1;2B" => "Shift-Down",
    "[1;2C" => "Shift-Right",
    "[1;2D" => "Shift-Left",
    "[1;2F" => "Shift-End",
    "[1;2H" => "Shift-Pos1",
    "[2;2~" => "Shift-Ins",
    "[3;2~" => "Shift-Del",
    "[5;2~" => "Shift-PgUp",
    "[6;2~" => "Shift-PdDown",
    "[1;2P" => "Shift-F1",
    "[1;2Q" => "Shift-F2",
    "[1;2R" => "Shift-F3",
    "[1;2S" => "Shift-F4",
    "[15;2~" => "Shift-F5",
    "[17;2~" => "Shift-F6",
    "[18;2~" => "Shift-F7",
    "[19;2~" => "Shift-F8",
    "[20;2~" => "Shift-F9",
    "[21;2~" => "Shift-F10",
    "[23;2~" => "Shift-F11",
    "[24;2~" => "Shift-F12",
    "[29;2~" => "Shift-Apps",
    "[34;2~" => "Shift-Win",
    "[1;3A" => "Meta-Up",
    "[1;3B" => "Meta-Down",
    "[1;3C" => "Meta-Right",
    "[1;3D" => "Meta-Left",
    "[1;3F" => "Meta-End",
    "[1;3H" => "Meta-Pos1",
    "[2;3~" => "Meta-Ins",
    "[3;3~" => "Meta-Del",
    "[5;3~" => "Meta-PgUp",
    "[6;3~" => "Meta-PdDown",
    "[1;3P" => "Meta-F1",
    "[1;3Q" => "Meta-F2",
    "[1;3R" => "Meta-F3",
    "[1;3S" => "Meta-F4",
    "[15;3~" => "Meta-F5",
    "[17;3~" => "Meta-F6",
    "[18;3~" => "Meta-F7",
    "[19;3~" => "Meta-F8",
    "[20;3~" => "Meta-F9",
    "[21;3~" => "Meta-F10",
    "[23;3~" => "Meta-F11",
    "[24;3~" => "Meta-F12",
    "[29;3~" => "Meta-Apps",
    "[34;3~" => "Meta-Win",
    "[1;5A" => "Ctrl-Up",
    "[1;5B" => "Ctrl-Down",
    "[1;5C" => "Ctrl-Right",
    "[1;5D" => "Ctrl-Left",
    "[1;5F" => "Ctrl-End",
    "[1;5H" => "Ctrl-Pos1",
    "[2;5~" => "Ctrl-Ins",
    "[3;5~" => "Ctrl-Del",
    "[5;5~" => "Ctrl-PgUp",
    "[6;5~" => "Ctrl-PdDown",
    "[1;5P" => "Ctrl-F1",
    "[1;5Q" => "Ctrl-F2",
    "[1;5R" => "Ctrl-F3",
    "[1;5S" => "Ctrl-F4",
    "[15;5~" => "Ctrl-F5",
    "[17;5~" => "Ctrl-F6",
    "[18;5~" => "Ctrl-F7",
    "[19;5~" => "Ctrl-F8",
    "[20;5~" => "Ctrl-F9",
    "[21;5~" => "Ctrl-F10",
    "[23;5~" => "Ctrl-F11",
    "[24;5~" => "Ctrl-F12",
    "[29;5~" => "Ctrl-Apps",
    "[34;5~" => "Ctrl-Win",
    "[1;6A" => "Shift-Ctrl-Up",
    "[1;6B" => "Shift-Ctrl-Down",
    "[1;6C" => "Shift-Ctrl-Right",
    "[1;6D" => "Shift-Ctrl-Left",
    "[1;6F" => "Shift-Ctrl-End",
    "[1;6H" => "Shift-Ctrl-Pos1",
    "[2;6~" => "Shift-Ctrl-Ins",
    "[3;6~" => "Shift-Ctrl-Del",
    "[5;6~" => "Shift-Ctrl-PgUp",
    "[6;6~" => "Shift-Ctrl-PdDown",
    "[1;6P" => "Shift-Ctrl-F1",
    "[1;6Q" => "Shift-Ctrl-F2",
    "[1;6R" => "Shift-Ctrl-F3",
    "[1;6S" => "Shift-Ctrl-F4",
    "[15;6~" => "Shift-Ctrl-F5",
    "[17;6~" => "Shift-Ctrl-F6",
    "[18;6~" => "Shift-Ctrl-F7",
    "[19;6~" => "Shift-Ctrl-F8",
    "[20;6~" => "Shift-Ctrl-F9",
    "[21;6~" => "Shift-Ctrl-F10",
    "[23;6~" => "Shift-Ctrl-F11",
    "[24;6~" => "Shift-Ctrl-F12",
    "[29;6~" => "Shift-Ctrl-Apps",
    "[34;6~" => "Shift-Ctrl-Win",
    "[1;7A" => "Ctrl-Meta-Up",
    "[1;7B" => "Ctrl-Meta-Down",
    "[1;7C" => "Ctrl-Meta-Right",
    "[1;7D" => "Ctrl-Meta-Left",
    "[1;7F" => "Ctrl-Meta-End",
    "[1;7H" => "Ctrl-Meta-Pos1",
    "[2;7~" => "Ctrl-Meta-Ins",
    "[3;7~" => "Ctrl-Meta-Del",
    "[5;7~" => "Ctrl-Meta-PgUp",
    "[6;7~" => "Ctrl-Meta-PdDown",
    "[1;7P" => "Ctrl-Meta-F1",
    "[1;7Q" => "Ctrl-Meta-F2",
    "[1;7R" => "Ctrl-Meta-F3",
    "[1;7S" => "Ctrl-Meta-F4",
    "[15;7~" => "Ctrl-Meta-F5",
    "[17;7~" => "Ctrl-Meta-F6",
    "[18;7~" => "Ctrl-Meta-F7",
    "[19;7~" => "Ctrl-Meta-F8",
    "[20;7~" => "Ctrl-Meta-F9",
    "[21;7~" => "Ctrl-Meta-F10",
    "[23;7~" => "Ctrl-Meta-F11",
    "[24;7~" => "Ctrl-Meta-F12",
    "[29;7~" => "Ctrl-Meta-Apps",
    "[34;7~" => "Ctrl-Meta-Win",
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
    global BUFFER
    c = ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid}, Int32), stdin.handle, true)
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
        c = take!(BUFFER)
        if c == '\e' # Escape
        	esc_s = ""
       		while isempty(esc_s) || !(esc_s[end] in ['A','B','C','D','F','H','P','Q','R','S','~', '\e'])
       			#println(take!(BUFFER))
       			#println(string(take!(BUFFER)))
            	esc_s *= take!(BUFFER)
        	end
       	 	return esc_codes[esc_s]
    	elseif Int(c) in 0:31
        	return ctrl_codes[Int(c)]
    	else
       		return string(c)
    	end
    end
end

global const KEY_Q = "q"
global const ESC = '\e'

function test()
	Initiate_Keyboard_Input()

	while true
		sleep(0.05)
		key = readinput()
		if !isa(key, Nothing)
			if key == "Ctrl-C"
				break
			else
				#println("here")
				#println("---"^15, "NEW", "---"^15)
				#println(@show key)
				#println(BUFFER)
				println(key)
			end
		end
	end
	println("end")
end
test()