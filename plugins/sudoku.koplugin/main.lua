local BlitBuffer = require("ffi/blitbuffer")
local BottomContainer = require("ui/widget/container/bottomcontainer")
local Button = require("ui/widget/button")
local CenterContainer = require("ui/widget/container/centercontainer")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local LeftContainer = require("ui/widget/container/leftcontainer")
local Screen = require("device").screen
local Size = require("ui/size")
local SudokuCell = require("sudokucell")
local SudokuContainer = require("sudokucontainer")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local Widget = require("ui/widget/widget")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")
local _ = require("gettext")

--return { disabled = true }

local medium_boards = dofile("plugins/sudoku.koplugin/medium.lua")

local test_boards = dofile("plugins/sudoku.koplugin/test.lua")

local Sudoku = WidgetContainer:new{
    name = "sudoku",

    -- internal state
    _sudoku_widget = nil,
    _title = nil,
    _complete = nil,
    _cell_size = nil,
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

function Sudoku:newBoard(board)
    return SudokuContainer:new{
        cell_size = self._cell_size,
        board = board or test_boards[1],
        completed = function(complete)
            if complete then
                self._title.text = self.difficulty .. ": Complete"
            else
                self._title.text = self.difficulty
            end
            UIManager:setDirty(self._title)
        end
    }
end

function Sudoku:play()
    self.board = test_boards[1]
    self.difficulty = _("Test"),
    logger.warn("Yay! Sudoku!")
    local board = FrameContainer:new{
        bordersize = 0,
        padding = 0,
        inner_bordersize = 1,
        background = BlitBuffer.COLOR_WHITE,
    }

    local remaining_height = Screen:getHeight()

    -- Close and restart buttons
    local buttons = HorizontalGroup:new{
        Button:new{
            text = _("New game"),
            radius = Size.radius.window,
            callback = function()
                logger.warn("new sudoku game")
            end,
        },
        HorizontalSpan:new{
            width = 2 * Size.span.horizontal_default
        },
        Button:new{
            text = _("Restart"),
            radius = Size.radius.window,
            callback = function()
                logger.warn("restart sudoku")
                UIManager:close(self._sudoku_widget)
                self._sudoku_widget = self:newBoard(test_boards[1])
                self._play_field[1][1] = self._sudoku_widget
                UIManager:show(self._sudoku_widget)
--                UIManager:setDirty(self._play_field)
            end,
        },
        HorizontalSpan:new{
            width = 2 * Size.span.horizontal_default
        },
        Button:new{
            text = _("Close"),
            radius = Size.radius.window,
            callback = function()
                logger.warn("close window")
                UIManager:close(board)
            end,
        }
    }
    local temp = VerticalGroup:new{
        VerticalSpan:new{width = Size.padding.fullscreen},
        buttons,
        VerticalSpan:new{width = Size.padding.fullscreen}
    }
    local button_row = CenterContainer:new{
        dimen = Geom:new{
            h = temp:getSize().h,
            w = Screen:getWidth(),
        },
        temp
    }
    remaining_height = remaining_height - button_row:getSize().h
    logger.warn("remaining height", remaining_height)

    -- title row
    self._title = TextWidget:new{
        text = self.difficulty,
        face = Font:getFace("tfont")
    }
    local title_row = FrameContainer:new{
        bordersize = 0,
        padding = Size.padding.fullscreen,
        inner_bordersize = 1,
        LeftContainer:new{
            dimen = Geom:new{ w = Screen:getWidth() - 2 * Size.padding.fullscreen },
            self._title,
        }
    }
    remaining_height = remaining_height - title_row:getSize().h

    self._cell_size = math.ceil(math.min(Screen:getWidth(), remaining_height) / 12)
    if not self._sudoku_widget then
        self._sudoku_widget = self:newBoard()
    end
    self._play_field = CenterContainer:new{
        dimen = Geom:new{
            w = Screen:getWidth(),
            h = remaining_height
        },
        FrameContainer:new{
            bordersize = Size.border.window,
            padding = 0,
            self._sudoku_widget,
        }
    }
    table.insert(board, VerticalGroup:new{
        title_row,
        self._play_field,
        button_row,
    })

    UIManager:show(board)
    return true
end

return Sudoku