local BlitBuffer = require("ffi/blitbuffer")
local BottomContainer = require("ui/widget/container/bottomcontainer")
local Button = require("ui/widget/button")
local CenterContainer = require("ui/widget/container/centercontainer")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local Screen = require("device").screen
local Size = require("ui/size")
local SudokuCell = require("sudokucell")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local Widget = require("ui/widget/widget")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")
local _ = require("gettext")

local function _framed(widget, width)
    width = width or Size.border.default
    return FrameContainer:new{
        padding = 0,
        bordersize = width,
        widget
    }
end

local SudokuContainer = WidgetContainer:new{
    dimen = Geom:new{
        w = Screen:getWidth(),
        h = Screen:getHeight()
    },
    board = nil,
}

function SudokuContainer:init()
    -- playing field - most of the space
    -- grouped:
    --   row of 1..9 buttons; more?
    --   bottom - close, restart?
    local remaining_height = self.dimen.h

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
            w = self.dimen.w
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
                    local preset = self.board[9*(i*3+m-1) + (j*3+n)]
                    cell = SudokuCell:new{
                        size = self.dimen.w / 11,
                        x = i*3+m,
                        y = j*3+n,
                        fixed = preset ~= 0,
                        number = preset ~= 0 and preset,
                        board = self,
                    }
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
            w = self.dimen.w,
            h = remaining_height
        },
        _framed(sudoku_widget, Size.border.window)
    }
    table.insert(self, VerticalGroup:new{
        play_field,
        button_row
    })
end

function SudokuContainer:isComplete()
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

function SudokuContainer:validate()
    if self:isComplete() then
        local widget = CenterContainer:new{
            dimen = Geom:new{
                w = self.dimen.w,
                h = self.dimen.h,
            },
            TextWidget:new{
                text = "Yay!",
                font = Font:getFace("tfont", 33)
            }
        }
        UIManager.show(widget)
    end
end

function SudokuContainer:paintTo(bb, x, y)
    bb:paintRect(0, 0, self.dimen.w, self.dimen.h, BlitBuffer.COLOR_WHITE)
    WidgetContainer.paintTo(self, bb, x, y)
end

return SudokuContainer