Dabble v1.3
September 6, 2001
J.P. Grossman
jpg@ai.mit.edu
http://dabble.ai.mit.edu


Two different executables are provided: dabble.exe and dabble_nohash.exe.
dabble.exe uses a highly optimized transposition table that only works
for small boards (up to 6x6 dots).  dabble_nohash.exe does not use
a transposition table so it is slower but it works for larger boards
(up to 20x20 dots).  Also, dabble.exe uses a lot of memory for its
transposition table.  If you don't have 128 Megs of RAM, don't run
dabble.exe.


The sample games included were played against Saul Schleimer, 
Katherine Scott, and Elwyn Berlekamp.  Dabble won one of these games
(saul2_vs_dodie.dbl) when Saul tried to use a symmetry strategy.


Quick Reference Guide
---------------------

Ctrl+N  -   Start a new game
Alt+S   -   Settings (can change them during a game)

  Max Depth            - Maximum number of moves the computer will look ahead
  Per-Move Time Limit  - Time limit per move in seconds (0 for no time limit)
  Per-Game Time Limit  - Time limit per game in minutes
  First Player Name    - Default is Dodie
  Second Player Name   - Default is Evie

Enter   -   Let the computer move

Backspace\Left Arrow    -   Undo last move
Right Arrow             -   Redo last move

Ctrl+S  -   Save game
Ctrl+O  -   Load game

  After loading a game, use right arrow (Redo) to step through the game

Autoplay   -    When this is not checked, the computer will not move
                automatically

View Internals  -   Shows graphically some of the internal data structures
