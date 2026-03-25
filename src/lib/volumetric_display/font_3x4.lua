-- stylua: ignore start
---@type FontSheet
local fontSheet3x4 = {
	minAsciiCode = 32,
	maxAsciiCode = 128,
	width = 3,
	height = 4,
  gap = 1,
	sheet = {
-- Based on the following font:
-- https://web.archive.org/web/20260323192244/https://www.reddit.com/media?url=https%3A%2F%2Fi.redd.it%2Fz5ytt03tgvua1.png
-- Region 32-96 of the ascii code chart:
--SP  !   "   #   $   %   &   '   (    )  *   +   ,   -   .   /
"     X  X X X X  XX X X XXX   X   X X                          ",
"     X      XXX XX   X  X X  X   X   X  X X  X                X",
"            XXX  XX X    XX      X   X   X  XXX XX  XXX      X ",
"     X      X X XX  X X XXX       X X   X X  X   X       X  X  ",
--0   1   2   3   4   5   6   7   8   9   :   ;   <   =   >   ?
"XXX  X  XXX XXX X X XXX X   XXX XXX XXX  X   X              XXX",
"X X XX    X  XX X X XX  XXX   X XXX X X           X XXX X    XX",
"X X  X  XX    X XXX   X X X  X  X X XXX  X   X   X       X     ",
"XXX XXX XXX XXX   X XXX XXX  X  XXX   X     X     X XXX X    X ",
--@   A   B   C   D   E   F   G   H   I   J   K   L   M   N   O
"XXX  X  XX   XX XX  XXX XXX  XX X X XXX   X X X X   XXX X X XXX",
"XXX X X XX  X   X X X   X   X   X X  X    X X X X   XXX XXX X X",
"XXX XXX X X X   X X XX  XX  X X XXX  X  X X XX  X   X X XXX X X",
"XXX X X XX   XX XX  XXX X    XX X X XXX  X  X X XXX X X X X XXX",
--P   Q   R   S   T   U   V   W   X   Y   Z   [   \   ]   ^   _
"XX   X  XX   XX XXX X X X X X X X X X X XXX XXX     XXX  X     ",
"X X X X X X X    X  X X X X X X  X  X X   X X   X     X X X    ",
"XX  XXX XX    X  X  X X X X XXX  X   X  X   X    X    X        ",
"X    XX X X XX   X  XXX  X  XXX X X  X  XXX XXX   X XXX     XXX",
--`   a   b   c   d   e   f   g   h   i   j   k   l   m   n   o
"X       X         X      XX  XX X    X    X X                  ",
" X   XX XX   XX  XX XXX X   X   X           X X X   XXX XX  XXX",
"    X X X X X   X X XX  XX  X X XXX  X    X XX  X   XXX X X X X",
"     XX XX  XXX  XX XXX X   XXX X X  X  XX  X X XX  X X X X XXX",
--p   q   r   s   t   u   v   w   x   y   z   {   |   }   ~  DEL
"                 X                           XX  X  XX      XXX",
"XXX XXX  XX  XX XXX X X X X X X X X X X XX   X   X   X   XX XXX",
"XXX XXX X    X   X  X X X X XXX  X   X   X  XX   X   XX XX  XXX",
"X     X X   XX   XX XXX  X  XXX X X  X   XX  XX  X  XX      XXX",
  }
}
-- stylua: ignore end
return fontSheet3x4
