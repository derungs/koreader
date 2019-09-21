local DocumentRegistry = require("document/documentregistry")
local InputContainer = require("ui/widget/container/inputcontainer")
local Menu = require("ui/widget/menu")
local Screen = require("device").screen
local UIManager = require("ui/uimanager")
local logger = require("logger")
local util = require("ffi/util")
local lfs = require("libs/libkoreader-lfs")
local getFriendlySize = require("util").getFriendlySize
local _ = require("gettext")

local CollectionTest = InputContainer:extend {
    collectiontest_menu_title = "Show Collection",
}

function CollectionTest:init()
    logger.warn("CollectionTest:init")
    self.ui.menu:registerToMainMenu(self)
end

function CollectionTest:addToMainMenu(menu_items)
    logger.warn("CollectionTest:addToMainMenu")
    -- insert table to main tab of filemanager menu
    menu_items.show_collection = {
        text = "Show Collection",
        callback = function()
            self:onShowCollection()
        end,
    }
end

function CollectionTest:onSetDimensions(dimen)
    self.dimen = dimen
end

local function buildEntry(input_time, input_file)
    local file_exists = lfs.attributes(input_file, "mode") == "file"
    local real_file_path = util.realpath(input_file) or input_file
    return {
        time = input_time,
        text = input_file:gsub(".*/", ""),
        file = real_file_path, -- keep orig file path of deleted files
        dim = not file_exists, -- "dim", as expected by Menu
        mandatory = file_exists and getFriendlySize(lfs.attributes(input_file, "size") or 0),
        callback = function()
            logger.info("open "..real_file_path)
            -- local ReaderUI = require("apps/reader/readerui")
            -- ReaderUI:showReader(input_file)
        end
    }
end

function CollectionTest:updateItemTable()
    -- try to stay on current page
    local select_number = nil
--    if self.hist_menu.page and self.hist_menu.perpage then
--        select_number = (self.hist_menu.page - 1) * self.hist_menu.perpage + 1
--    end
    self.collections_menu:switchItemTable(self.collectiontest_menu_title,
                                  self:fillCollectionsMenu(), select_number)
end

function CollectionTest:fillCollectionsMenu()
    local menu = { }
    local homedir = G_reader_settings:readSetting("home_dir")
    local i = 1
    for f in lfs.dir(homedir) do
        local filepath = util.joinPath(homedir, f)
        local isBook = lfs.attributes(filepath, "mode") == "file" and DocumentRegistry:getProviders(filepath) ~= nil
            -- and #(DocumentRegistry:getProviders(filepath)) > 1
        if isBook then
            local attr = lfs.attributes(filepath, "mode") or "nil"
            local fn = filepath
            local nr = i
            table.insert(menu, buildEntry(os.time(), fn))
            i = i+1
        else logger.info("not a book: "..filepath)
        end
    end
    return menu
end

function CollectionTest:onShowCollection()
    logger.warn("CollectionTest:onShowCollection", "triggered")
    local collections_menu = Menu:new{
        ui = self.ui,
        width = Screen:getWidth(),
        height = Screen:getHeight(),
        covers_fullscreen = true, -- hint for UIManager:_repaint()
        is_borderless = true,
        is_popout = false,
--        onMenuHold = self.onMenuHold,
        _manager = self,
    }

    -- overwrite menu behaviour
    collections_menu._coverbrowser_overridden = true
    local CoverMenu = require("covermenu")
    collections_menu.updateItems = CoverMenu.updateItems
    collections_menu.onCloseWidget = CoverMenu.onCloseWidget
    -- Also replace original onMenuHold (it will use original method, so remember it)
--    collections_menu.onMenuHold_orig = collections_menu.onMenuHold
--    collections_menu.onMenuHold = CoverMenu.onHistoryMenuHold

    local ListMenu = require("listmenu")
    collections_menu._recalculateDimen = ListMenu._recalculateDimen
    collections_menu._updateItemsBuildUI = ListMenu._updateItemsBuildUI
    -- Set ListMenu behaviour:
    collections_menu._do_cover_images = true
    collections_menu._do_filename_only = nil

    self.collections_menu = collections_menu
    self:updateItemTable()
    self.collections_menu.close_callback = function()
        -- Close it at next tick so it stays displayed
        -- while a book is opening (avoids a transient
        -- display of the underlying File Browser)
        UIManager:nextTick(function()
            --UIManager:close(self.collections_menu)
        end)
    end
    UIManager:show(self.collections_menu)
    return true
end

return CollectionTest