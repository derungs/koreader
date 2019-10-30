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
local TextWidget = require("ui/widget/textwidget")
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

local Number = InputContainer:new{
    size = nil,
    number = nil,
    popup = nil,
}

function Number:init()
    self.dimen = Geom:new{ w = self.size, h = self.size }
    self[1] = CenterContainer:new{
        dimen = self.dimen,
        TextWidget:new{
            text = self.number,
            face = self.popup._face
        }
    }
    if Device:isTouchDevice() then
        self.ges_events = {
            TapSelect = {
                GestureRange:new{
                    ges = "tap",
                    range = self.dimen,
                },
                doc = "Select number",
            }
        }
    end
end

function Number:onTapSelect()
    logger.warn("select", self.number)
    self.popup:select(self.number)
end

local SudokuPopup = InputContainer:new{
    size = nil,
    cell = nil
}

function SudokuPopup:init()
    self._face = Font:getFace("cfont", self.size / 2)
    local numbers = {}
    local box = VerticalGroup:new()
    for i = 0,2 do
        local line = HorizontalGroup:new()
        for j = 1,3 do
            local number = Number:new{
                size = self.size,
                number = i*3 + j,
                popup = self,
            }
            line[j] = _framed(number, Size.border.thin)
        end
        box[i+1] = _framed(line)
    end
    self[1] = FrameContainer:new{
        background = BlitBuffer.COLOR_WHITE,
        box,
    }
    self.dimen = self[1]:getSize()

    --[
    if Device:isTouchDevice() then
        self.ges_events = {
            TapClose = {
                GestureRange:new{
                    ges = "tap",
                    range = Geom:new{
                        x = 0, y = 0,
                        w = Screen:getWidth(),
                        h = Screen:getHeight(),
                    },
                    doc = "Close sudoku popup",
                },
            }
        }
    end
    --]]
end

function SudokuPopup:onTapClose()
    UIManager:close(self)
end

function SudokuPopup:onCloseWidget()
    UIManager:nextTick(function() self.cell.board:validate() end)
end

function SudokuPopup:select(number)
    UIManager:close(self)
    self.cell:set(number)
end

return SudokuPopup