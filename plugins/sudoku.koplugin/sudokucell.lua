local BlitBuffer = require("ffi/blitbuffer")
local Device = require("device")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InputContainer = require("ui/widget/container/inputcontainer")
local logger = require("logger")

local SudokuCell = InputContainer:new{
    fixed = nil,
    number = nil,
    numbers = nil,
    dimen = nil,
    x = nil,
    y = nil,
    enabled = true,
    callback = function()
        logger.warn("!! callback called")
    end
}

function SudokuCell:init()
    if Device:isTouchDevice() then
        logger.warn("touch device", self.x, self.y, self.dimen)
        self.ges_events = {
            TapSelect = {
                GestureRange:new{
                    ges = "tap",
                    range = self.dimen,
                },
                doc = "Select number",
            },
            HoldSelect = {
                GestureRange:new{
                    ges = "hold",
                    range = self.dimen,
                },
                doc = "Hold Menu Item",
            },
        }
    end
end

function SudokuCell:paintTo(bb, x, y)
    self.dimen.x = x
    self.dimen.y = y

    logger.warn("new dimen", self.dimen)
    bb:paintRect(x + self.dimen.w / 4, y + self.dimen.h / 4, self.dimen.w / 2, self.dimen.h / 2, BlitBuffer.COLOR_GRAY)
end

function SudokuCell:onTapSelect(arg, ges)
    logger.warn("tapped", self.x, self.y, self.number, self.fixed, self.numbers)
    return true
end

function SudokuCell:onHoldSelect(arg, ges)
    logger.warn("held", self.x, self.y, self.number, self.fixed)
    return true
end

function SudokuCell:add(n)
    if not self.fixed then
        self.numbers = self.numbers or {}
        self.numbers[n] = n
        self.number = nil
    end
end

function SudokuCell:remove(n)
    if not self.fixed and self.numbers then
        self.numbers[n] = nil
    end
end

function SudokuCell:toggle(n)
    if not self.fixed then
        self.numbers = self.numbers or {}
        if self.numbers[n] then
            self.numbers[n] = nil
        else
            self.numbers[n] = n
        end
        self.number = nil
    end
end

function SudokuCell:set(n)
    if not self.fixed then
        self.number = n
        self.numbers = nil
    end
end

function SudokuCell:clear()
    if not self.fixed then
        self.number = nil
        self.numbers = nil
    end
end

return SudokuCell