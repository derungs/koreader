
--return { disabled = true }

loadfile("medium.lua")

loadfile("test.lua")

local Board = require("board")

local b = Board:new()
b:init(test)

repeat
    b:draw()
    io.write("i j n: ")
    io.flush()
    local i = io.read("*n")
    local j = io.read("*n")
    local n = io.read("*n")
    if n == 0 then n = nil end
    b.rows[i][j]:set(n)
until b:complete()
