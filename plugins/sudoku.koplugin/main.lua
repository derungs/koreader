local BlitBuffer = require("ffi/blitbuffer")
local BottomContainer = require("ui/widget/container/bottomcontainer")
local Button = require("ui/widget/button")
local CenterContainer = require("ui/widget/container/centercontainer")
local CheckButton = require("ui/widget/checkbutton")
local Device = require("device")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local InputContainer = require("ui/widget/container/inputcontainer")
local LeftContainer = require("ui/widget/container/leftcontainer")
local LineWidget = require("ui/widget/linewidget")
local RadioButton = require("ui/widget/radiobutton")
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

local Sudoku = WidgetContainer:new{
    name = "sudoku",
    difficulty = "Test",
    board = nil,

    -- internal state
    _title = nil,
    _container = nil,

    medium = dofile("plugins/sudoku.koplugin/medium.lua"),
    test = dofile("plugins/sudoku.koplugin/test.lua")
}

function Sudoku:init()
    self.ui.menu:registerToMainMenu(self)
end

function Sudoku:addToMainMenu(menu_items)
    menu_items.sudoku = {
        text = _("Sudoku"),
        callback = function()
            if self._container then
                UIManager:show(self._container)
            elseif self.board then
                self:play()
            else
                self:selectBoard()
            end
            return true
        end,
    }
end

function Sudoku:selectBoard()
    local width = Screen:getWidth() / 2
    local window = FrameContainer:new{
        radius = Size.radius.window,
        background = BlitBuffer.COLOR_WHITE,

        selected = nil,
        face = Font:getFace("cfont"),
    }
    local function radioButton(id, text)
        local button = RadioButton:new{
            id = id,
            text = text,
            face = window.face,
            width = width,
            parent = window,
        }
        button.checked = function()
            return window.selected == button
        end
        button.callback = function()
            if window.selected ~= button then
                if window.selected then
                    window.selected:unCheck()
                end
                window.selected = button
                button:check()
            end
        end
        return button
    end
    local buttons = HorizontalGroup:new{
        Button:new{
            text = _("Start"),
            enabled = window.selected,
            callback = function()
                UIManager:close(window)
                local diff = window.selected
                logger.warn("difficulty selected", diff)
                self.board = self[diff.id][1]
                self.difficulty = diff.text
                self:play()
            end
        },
        HorizontalSpan:new{
            width = 2 * Size.span.horizontal_default
        },
        Button:new{
            text = _("Cancel"),
            callback = function()
                UIManager:close(window)
            end
        }
    }
    table.insert(window, VerticalGroup:new{
        TextWidget:new{
            text = _("New game"),
            face = Font:getFace("tfont"),
        },
        LineWidget:new{
            dimen = Geom:new{
                w = width,
                h = Size.line.medium
            }
        },
        VerticalGroup:new{
            align = "left",
            TextWidget:new{
                text = _("Difficulty"),
                face = Font:getFace("cfont"),
            },
            radioButton("test", "Test"),
            radioButton("easy", "Easy"),
            radioButton("medium", "Medium"),
        },
        LineWidget:new{
            dimen = Geom:new{
                w = width,
                h = Size.line.medium
            }
        },
        VerticalSpan:new{
            width = 2 * Size.span.vertical_large
        },
        buttons,
        VerticalSpan:new{
            width = 2 * Size.span.vertical_large
        },
    })
    local dimen = window:getSize()
    dimen.x = math.ceil((Screen:getWidth() - dimen.w) / 2)
    dimen.y = math.ceil((Screen:getHeight() - dimen.h) / 2)
    logger.warn("window size", dimen)
    UIManager:show(window, nil, nil, dimen.x, dimen.y)
    return true
end

function Sudoku:play()
    logger.warn("Yay! Sudoku!")
    local board = FrameContainer:new{
        bordersize = 0,
        padding = 0,
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
                UIManager:close(self._container)
                self:selectBoard()
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
                UIManager:close(self._container)
                self:play()
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
                UIManager:close(self._container)
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
        LeftContainer:new{
            dimen = Geom:new{ w = Screen:getWidth() - 2 * Size.padding.fullscreen },
            self._title,
        }
    }
    remaining_height = remaining_height - title_row:getSize().h

    local cell_size = math.ceil(math.min(Screen:getWidth(), remaining_height) / 12)
    local play_field = CenterContainer:new{
        dimen = Geom:new{
            w = Screen:getWidth(),
            h = remaining_height
        },
        FrameContainer:new{
            bordersize = Size.border.window,
            padding = 0,
            SudokuContainer:new{
                cell_size = cell_size,
                board = self.board,
                completed = function(complete)
                    if complete then
                        self._title.text = self.difficulty .. ": Complete"
                    else
                        self._title.text = self.difficulty
                    end
                    UIManager:setDirty(self._title)
                end
            }
        }
    }
    table.insert(board, VerticalGroup:new{
        title_row,
        play_field,
        button_row,
    })
    self._container = board
    UIManager:show(board)
    return true
end

return Sudoku