local BlitBuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local InputContainer = require("ui/widget/container/inputcontainer")
local Screen = Device.screen
local Size = require("ui/size")
local TextBoxWidget = require("ui/widget/textboxwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local logger = require("logger")

local function _framed(widget, width)
    width = width or Size.border.default
    return FrameContainer:new{
        padding = 0,
        bordersize = width,
        widget
    }
end

local SudokuDialog = InputContainer:new{
    size = Screen:getWidth() / 11
}

function SudokuDialog:init()
    local box = VerticalGroup:new()
    for i = 0,2 do
        local line = HorizontalGroup:new()
        for j = 1,3 do
            line[j] = _framed(CenterContainer:new{
                dimen = Geom:new{ w = self.size, h = self.size },
                TextBoxWidget:new{
                    dimen = Geom:new{
                        w = self.size, h = self.size
                    },
                    text = i*3 + j,
                    face = Font:getFace("cfont", self.size / 2)
            }}, Size.border.thin)
        end
        box[i+1] = _framed(line)
    end
    self[1] = _framed(box)
    self.dimen = self[1]:getSize()
end

function SudokuDialog:paintTo(bb, x, y)
    self.dimen.x = x
    self.dimen.y = y
    InputContainer.paintTo(self, bb, x, y)
end

function SudokuDialog:onCloseWidget()
    UIManager:setDirty(nil, function()
        return "partial", self.dimen
    end)
end

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
    local temp = SudokuDialog:new()
    local region = temp:getSize()
    region.x = self.dimen.x - 50
    region.y = self.dimen.y - 50
    UIManager:show(temp, "ui", region, region.x, region.y)
--    UIManager:show(temp)
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