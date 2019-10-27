local BlitBuffer = require("ffi/blitbuffer")
local BottomContainer = require("ui/widget/container/bottomcontainer")
local Button = require("ui/widget/button")
local CenterContainer = require("ui/widget/container/centercontainer")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local Screen = require("device").screen
local Size = require("ui/size")
local SudokuCell = require("sudokucell")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local Widget = require("ui/widget/widget")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")
local _ = require("gettext")

local SudokuContainer = WidgetContainer:new{
    dimen = Geom:new{
        w = Screen:getWidth(),
        h = Screen:getHeight()
    },
    board = nil,
}

local function _framed(widget, width)
    width = width or Size.border.default
    return FrameContainer:new{
        padding = 0,
        bordersize = width,
        widget
    }
end

function SudokuContainer:run()
    -- playing field - most of the space
    -- grouped:
    --   row of 1..9 buttons; more?
    --   bottom - close, restart?
    local remaining_height = Screen:getHeight()

    -- Close and restart buttons
    local temp = VerticalGroup:new{
        VerticalSpan:new{width = Size.padding.fullscreen},
        Button:new{
            text = _("Close"),
            radius = Size.radius.window,
            callback = function()
                logger.warn("close window")
                UIManager:close(self)
            end,
        },
        VerticalSpan:new{width = Size.padding.fullscreen}
    }
    local button_row = CenterContainer:new{
        dimen = Geom:new{
            h = temp:getSize().h,
            w = Screen:getWidth()
        },
        temp
    }
    remaining_height = remaining_height - button_row:getSize().h
    logger.warn("remaining height", remaining_height)

    local sudoku_widget = VerticalGroup:new()
    for i = 0,2 do
        local group = HorizontalGroup:new()
        for j = 0,2 do
            local block = VerticalGroup:new()
            for m = 1,3 do
                local short_line = HorizontalGroup:new()
                for n = 1,3 do
                    local cell
                    if m == 2 and n == 3 then
                        cell = Button:new{
                            callback = function()
                                logger.warn("button", i*3+m, j*3+n)
                            end,
                            text = "aaa"
                        }
                    else
                        cell = SudokuCell:new{
                            dimen = Geom:new{
                                w = Screen:getWidth() / 11,
                                h = Screen:getWidth() / 11,
                            },
                            x = i*3+m,
                            y = j*3+n,
    --                        fixed = self.board[i*3+m][j*3+n] ~= 0
                        }
                    end
                    table.insert(short_line, _framed(cell, Size.border.thin))
                end
                table.insert(block, short_line)
            end
            table.insert(group, _framed(block, Size.border.default))
        end
        table.insert(sudoku_widget, group)
    end
    local play_field = CenterContainer:new{
        dimen = Geom:new{
            w = Screen:getWidth(),
            h = remaining_height
        },
        _framed(sudoku_widget, Size.border.window)
    }
    table.insert(self, VerticalGroup:new{
        play_field,
        button_row
    })
    UIManager:show(self)
end

function SudokuContainer:paintTo(bb, x, y)
    bb:paintRect(0, 0, self.dimen.w, self.dimen.h, BlitBuffer.COLOR_WHITE)
    WidgetContainer.paintTo(self, bb, x, y)
end

return SudokuContainer