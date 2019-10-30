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
        inner_bordersize = 1,
        widget
    }
end

local SudokuContainer = VerticalGroup:new{
    cell_size = nil,
    board = nil,
    difficulty = _("Test"),
    completed = function() end,
}

function SudokuContainer:init()
    self._complete = nil

    self.rows = {}
    for i = 0,2 do
        local group = HorizontalGroup:new()
        for j = 0,2 do
            local block = VerticalGroup:new()
            for m = 1,3 do
                logger.warn("row", i*3+m)
                self.rows[i*3+m] = self.rows[i*3+m] or {}
                local short_line = HorizontalGroup:new()
                for n = 1,3 do
                    local cell
                    local preset = self.board[9*(i*3+m-1) + (j*3+n)]
                    cell = SudokuCell:new{
                        size = self.cell_size,
                        x = i*3+m,
                        y = j*3+n,
                        fixed = preset ~= 0,
                        number = preset ~= 0 and preset,
                        board = self,
                    }
                    table.insert(short_line, cell)
                    logger.warn("column", j*3+n)
                    self.rows[i*3+m][j*3+n] = cell
                end
                table.insert(block, short_line)
            end
            table.insert(group, _framed(block, Size.border.button))
        end
        table.insert(self, group)
    end
end

function SudokuContainer:isComplete()
    for i = 1, 9 do
        for j = 1, 9 do
            if not self.rows[i][j].number then
                logger.warn("empty", i, j)
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
            logger.warn("row", i, k)
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
            logger.warn("column", j, k)
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
                logger.warn("block", bi, bj, k)
                return false
            end
        end
    end
    -- all checks successful
    logger.warn("all good")
    return true
end

function SudokuContainer:validate()
    logger.warn("validating")
    if self:isComplete() then
        logger.warn("complete")
        if not self._complete then
            self.completed(true)
        end
        self._complete = true
    elseif self._complete then
        logger.warn("uncomplete")
        self.completed(false)
        self._complete = nil
    end
end

return SudokuContainer