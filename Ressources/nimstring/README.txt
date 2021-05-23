Files
=====
nim.h    -- The header file.
nim.cpp  -- The C++ source file.
example  -- Input file containing the strings and coins position
            corresponding to the start of the 4-box game.
example2 -- Input file containing the strings and coins position
            corresponding to the start of the 9-box game.

Instructions
============
(1) Compile the program (depends on your system) to obtain an
executable called "nimstr" (or "nimstr.exe" on windows).  For best
execution time, you should use the optimization option that will inline
functions that are declared "inline."
The command line for the g++ compiler is
g++ -O3 nim.cpp -o nimstr

The -O3 optimization option will perform all optimizations that are
guaranteed to improve the execution efficiency plus it will inline
functions that are declared inline.

(2) Run the program using an input file containing the strings
and coins position.  E.g. if the strings-and-coins position is
stored in the file "example," then on UNIX, you would enter
./nimstr example at the UNIX prompt.

Input File format
=================
Coins are represented by "*"'s and strings are represented by "-" and
"|"'s. Strings attached to the ground node are represented by "^", ">", "v"
and "<" .

Important: The first coin (*) should appear in the second column
on the second line of the input file.


Running the compiled program on the two sample input files
should produce the following output.


==> ./nimstr example
 ^ ^
<*-*>
 | |
<*-*>
 v v
nimber = 0

The 1-step followers are:

 1 1
1*1*1
 1 1
1*1*1
 1 1
==> ./nimstr example2
 ^ ^ ^
<*-*-*>
 | | |
<*-*-*>
 | | |
<*-*-*>
 v v v
nimber = 2

The 1-step followers are:

 1 1 1
1*4*4*1
 4 0 4
1*0*0*1
 4 0 4
1*4*4*1
 1 1 1
