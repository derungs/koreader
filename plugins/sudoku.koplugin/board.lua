local SudokuCell = require("sudokucell")
local Board = {}

function Board:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--[[
 -------------------------
 | 3 6 5 | 4 9 2 | 1 8 7 |
 | 9 8 1 | 5 7 6 | 3 2 4 |
 | 7 2 4 | 8 1 3 | 5 6 9 |
 -------------------------
 | 4 1 9 | 6 3 8 | 2 7 5 |
 | 6 7 3 | 2 5 9 | 4 1 8 |
 | 2 5 8 | 1 4 7 | 9 3 6 |
 -------------------------
 | 5 3 2 | 7 8 4 | 6 9 1 |
 | 1 9 7 | 3 6 5 | 8 4 2 |
 | 8 4 6 | 9 2 1 | 7 5 3 |
 -------------------------

    -------------------------
    |       | 4 9 2 | 1 8 7 |
    |   8   | 5 7 6 | 3 2 4 |
    | 7 2 4 | 8 1 3 | 5 6 9 |
    -------------------------
    | 4 1 9 | 6 3 8 | 2 7 5 |
    |   7   | 2 4 9 | 4 1 8 |
    | 2 5 8 | 1 4 7 | 9 3 6 |
    -------------------------
    |       | 7 8 4 | 6     |
    |   9 7 | 3 6 5 | 8 4   |
    | 8 4 6 | 9 2 1 | 7 5 3 |
    -------------------------
   
]]

--[[--
  Initialize a Sudoku board
  @param start array with initial values; 0: empty
]]
function Board:init(start)
    assert(#start == 81, "too few entries")
    self.rows = {}
    local k = 1
    for i = 1, 9 do
        local row = {}
        for j = 1, 9 do
            if start[k] == 0 then
                row[j] = SudokuCell:new {}
            else
                row[j] = SudokuCell:new {
                    fixed = true,
                    number = start[k],
                }
            end
            k = k + 1
        end
        self.rows[i] = row
    end
end

function Board:complete()
    for i = 1, 9 do
        for j = 1, 9 do
            if not self.rows[i][j].number then
                print("empty", i, j)
                return false
            end
        end
    end
    -- check rows
    for i = 1, 9 do
        local v = {}
        for j = 1, 9 do
            local n = self.rows[i][j]
            v[n.number] = n.number
        end
        local k = 0
        for _ in pairs(v) do k = k + 1 end
        if k < 9 then
            print("row", i, k)
            return false
        end
    end
    -- check columns
    for j = 1, 9 do
        local v = {}
        for i = 1, 9 do
            local n = self.rows[i][j]
            v[n.number] = n.number
        end
        local k = 0
        for _ in pairs(v) do k = k + 1 end
        if k < 9 then
            print("column", j, k)
            return false
        end
    end
    -- check blocks
    for bi = 0, 6, 3 do
        for bj = 0, 6, 3 do
            local v = {}
            for i = 1, 3 do
                for j = 1, 3 do
                    local n = self.rows[bi + i][bj + j]
                    v[n.number] = n.number
                end
            end
            local k = 0
            for _ in pairs(v) do k = k + 1 end
            if k < 9 then
                print("block", bi, bj, k)
                return false
            end
        end
    end
    -- all checks successful
    return true
end

function Board:draw()
    for i = 1, 9 do
        if i % 3 == 1 then
            print(" -------------------------")
        end
        for j = 1, 9 do
            if j % 3 == 1 then
                io.write(" |")
            end
            local n = self.rows[i][j].number or " "
            io.write(" " .. n)
        end
        io.write(" |\n")
        io.flush()
    end
    print(" -------------------------")
end

return Board