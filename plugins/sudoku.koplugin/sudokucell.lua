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
local SudokuPopup = require("sudokupopup")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local logger = require("logger")

local SudokuCell = InputContainer:new{
    fixed = nil,
    number = nil,
    numbers = nil,
    size = nil,
    x = nil,
    y = nil,
    board = nil,
}

function SudokuCell:init()
    local font = self.fixed and "tfont" or "infont"
    local fontsize = self.fixed and self.size / 2 or self.size * 2 / 3
    self._text = TextWidget:new{
        text = self.number or "",
        face = Font:getFace(font, fontsize)
    }
    local content = CenterContainer:new{
        dimen = Geom:new{
            w = self.size,
            h = self.size,
        },
        self._text
    }
    self.dimen = content.dimen
    self[1] = FrameContainer:new{
        background = self.fixed and BlitBuffer.COLOR_GRAY_E,
        bordersize = Size.border.thin,
        padding = 0,
        content
    }
    if not self.fixed and Device:isTouchDevice() then
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

function SudokuCell:onTapSelect(arg, ges)
    local temp = SudokuPopup:new{
        cell = self,
        size = self.size,
    }
    local region = temp:getSize()
    region.x = self.dimen.x - (region.w - self.dimen.w) / 2
    region.y = self.dimen.y - (region.h - self.dimen.h) / 2
    UIManager:show(temp, nil, nil, region.x, region.y)
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
    self._text.text = self.number or ""
--    self.board:validate()
end

function SudokuCell:clear()
    if not self.fixed then
        self.number = nil
        self.numbers = nil
    end
end

return SudokuCell