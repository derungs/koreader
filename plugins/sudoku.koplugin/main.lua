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

local RadioBtn = InputContainer:new{
    id = nil,
    text = "",
    face = Font:getFace("cfont"),
    width = nil,
    checked = false,

    checked_mark = "◉ ",
    unchecked_mark = "◯ ",
    group = nil,
}
function RadioBtn:init()
    self._text_widget = TextWidget:new{
        text = self:makeText(),
        face = self.face,
        max_width = self.width
    }
    self[1] = self._text_widget
    self.dimen = self[1]:getSize()
    logger.warn("RadioButton size", self.dimen.w, self.dimen.h)
    if Device:isTouchDevice() then
        self.ges_events = {
            TapSelect = {
                GestureRange:new{
                    ges = "tap",
                    range = self.dimen,
                },
                doc = "Select radio button",
            },
        }
    end
end
function RadioBtn:makeText()
    local new_text = ((self.checked and self.checked_mark) or (self.unchecked_mark .. " ")) .. self.text
    logger.warn(self.id, self.checked, new_text)
    return new_text
end
function RadioBtn:onTapSelect()
    logger.warn("toggle radio button", self.id)
    if not self.checked then
        if self.group.selected then
            self.group.selected:uncheck()
        end
        self:check()
--        UIManager:setDirty(self.group)
        UIManager:widgetRepaint(self.group, self.group.dimen.x, self.group.dimen.y)
    end
    return true
end
function RadioBtn:check()
    logger.warn("check", self.id)
    self.group.selected = self
    self.checked = true
    self._text_widget.text = self:makeText()
--    UIManager:setDirty(self._text_widget)
end
function RadioBtn:uncheck()
    logger.warn("uncheck", self.id)
    self.checked = false
    self._text_widget.text = self:makeText()
--    UIManager:setDirty(self._text_widget)
end

local RadioButtonGroup = InputContainer:new{
    face = Font:getFace("cfont"),
    width = nil,
    buttons = { { id = "first", text = "First"}, },
    selected = nil,
}
function RadioButtonGroup:init()
    self[1] = VerticalGroup:new()
    for _, button in ipairs(self.buttons) do
        local rb = RadioBtn:new{
            id = button.id,
            text = button.text,
            face = self.face,
            width = self.width,
            group = self,
        }
        table.insert(self[1], LeftContainer:new{
            dimen = Geom:new{
                w = self.width,
                h = rb:getSize().h,
            },
            rb
        })
    end
    self.dimen = Geom:new{ w = self.width, h = self[1]:getSize().h }
end

function Sudoku:selectBoard()
    local difficulty_selection = RadioButtonGroup:new{
        width = Screen:getWidth() / 2,
        buttons = {
            { id = "test", text = _("Test") },
            { id = "medium", text = _("Medium") },
        }
    }
    local buttons = HorizontalGroup:new{
        Button:new{
            text = _("Start"),
            callback = function()
                UIManager:close(self._window)
                difficulty_selection.selected = difficulty_selection.selected or difficulty_selection[1][1]
                local diff = difficulty_selection.selected.id
                logger.warn("difficulty selected", diff)
                self.board = self[diff or "test"][1]
                self.difficulty = difficulty_selection.selected.text
                self:play()
            end
        },
        HorizontalSpan:new{
            width = 2 * Size.span.horizontal_default
        },
        Button:new{
            text = _("Cancel"),
            callback = function()
                UIManager:close(self._window)
            end
        }
    }
    local difficulty_text = TextWidget:new{
        text = _("Difficulty"),
        face = Font:getFace("cfont"),
    }
    self._window = FrameContainer:new{
        bordersize = 0,
        padding = 0,
        background = BlitBuffer.COLOR_WHITE,
    }
    table.insert(self._window, CenterContainer:new{
        dimen = Geom:new{
            w = Screen:getWidth(),
            h = Screen:getHeight(),
        },
        FrameContainer:new{
            bordersize = Size.border.window,
            radius = Size.radius.window,
            VerticalGroup:new{
                TextWidget:new{
                    text = _("New game"),
                    face = Font:getFace("tfont"),
                },
                LineWidget:new{
                    dimen = Geom:new{
                        w = Screen:getWidth() / 2,
                        h = Size.line.medium
                    }
                },
                VerticalGroup:new{
                    LeftContainer:new{
                        dimen = Geom:new{
                            w = Screen:getWidth() / 2,
                            h = difficulty_text:getSize().h
                        },
                        difficulty_text,
                    },
                    difficulty_selection,
                },
                LineWidget:new{
                    dimen = Geom:new{
                        w = Screen:getWidth() / 2,
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
            }
        }
    })
    UIManager:show(self._window)
    return true
--    self.board = self.test[1]
--    self:play()
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