local BlitBuffer = require("ffi/blitbuffer")
local BottomContainer = require("ui/widget/container/bottomcontainer")
local Button = require("ui/widget/button")
local CenterContainer = require("ui/widget/container/centercontainer")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local Screen = require("device").screen
local SudokuContainer = require("sudokucontainer")
local UIManager = require ("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")
local _ = require("gettext")

--return { disabled = true }

local medium_boards = dofile("plugins/sudoku.koplugin/medium.lua")

local test_boards = dofile("plugins/sudoku.koplugin/test.lua")

local Sudoku = WidgetContainer:new{
    name = "sudoku",
}

function Sudoku:init()
    self.ui.menu:registerToMainMenu(self)
end

function Sudoku:addToMainMenu(menu_items)
    menu_items.sudoku = {
        text = _("Sudoku"),
        callback = function()
            return self:play()
        end,
    }
end

function Sudoku:play()
    logger.warn("Yay! Sudoku!")
    local board = SudokuContainer:new{
        board = test_boards[1],
    }
    UIManager:show(board)
    --[[
    local full_widget
    local close_button = Button:new{
        text = _("Close"),
        callback = function()
            logger.warn("close window")
            UIManager:close(full_widget)
        end,
    }
    local bottom_widget = CenterContainer:new{
        dimen = Geom:new{
            w = Screen:getWidth(),
            h = close_button:getSize().h
        },
        close_button,
    }
    local www = BottomContainer:new{
        dimen = Geom:new{
            w = Screen:getWidth(),
            h = Screen:getHeight(),
        },
        bottom_widget
    }
    full_widget = FrameContainer:new{
        background = BlitBuffer.COLOR_WHITE,
        dimen = Geom:new{
            w = Screen:getWidth(),
            h = Screen:getHeight(),
        },
    }
    table.insert(full_widget, www)
    logger.warn(full_widget)
    UIManager:show(full_widget)
    ]]
end

return Sudoku

--[[
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
]]