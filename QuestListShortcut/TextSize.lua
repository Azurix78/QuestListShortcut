local addonName, addon = ...
local L = addon.L
local COMPACT_SCALE = 0.8
local events = CreateFrame("Frame")
local ready, menuHooked, updateHooked, refreshing = false, false, false, false
local fonts = setmetatable({}, { __mode = "k" })
local hookedPools = setmetatable({}, { __mode = "k" })
local poolNames = { "headerFramePool", "titleFramePool", "objectiveFramePool" }

local function GetMode()
    return QuestListShortcutDB.textMode
end

local function ApplyFont(text)
    if not text or type(text.GetFont) ~= "function" then return false end
    local original = fonts[text]
    if not original then
        local file, size, flags = text:GetFont()
        if not file or not size or size <= 0 then return false end
        original = { file = file, size = size, flags = flags, mode = "normal" }
        fonts[text] = original
    end
    local mode = GetMode()
    if original.mode == mode then return false end
    -- Change only this FontString, never the shared FontObject or its locale font.
    local size = original.size * (mode == "compact" and COMPACT_SCALE or 1)
    text:SetFont(original.file, size, original.flags)
    original.mode = mode
    return true
end

local function ApplyPool(pool)
    local changed = false
    for frame in pool:EnumerateActive() do
        local label = frame.Text or (frame.GetFontString and frame:GetFontString())
        if ApplyFont(label) then changed = true end
        if ApplyFont(frame.Dash) then changed = true end
        if ApplyFont(frame.TagText) then changed = true end
    end
    return changed
end

local function GetList()
    local panel = QuestMapFrame and QuestMapFrame.QuestsFrame
    return panel and panel.ScrollFrame
end

local function ApplyPools()
    local list = GetList()
    local changed = false
    if list then
        for _, name in ipairs(poolNames) do
            local pool = list[name]
            if pool and type(pool.EnumerateActive) == "function" then
                if not hookedPools[pool] and type(pool.Acquire) == "function" then
                    -- Run before the caller measures text and lays out this row.
                    -- Reused frames retain their original sizes; shrinking never compounds.
                    hooksecurefunc(pool, "Acquire", ApplyPool)
                    hookedPools[pool] = true
                end
                if ApplyPool(pool) then changed = true end
            end
        end
    end
    return changed
end

local function RebuildList()
    local list = GetList()
    if not refreshing and list and list:IsVisible() and type(QuestLogQuests_Update) == "function" then
        refreshing = true
        QuestLogQuests_Update()
        refreshing = false
    end
end

local function SetMode(mode)
    QuestListShortcutDB.textMode = mode
    ApplyPools()
    RebuildList()
end

local function Initialize()
    if not ready then return end
    if not menuHooked and Menu and type(Menu.ModifyMenu) == "function" then
        Menu.ModifyMenu("MENU_QUEST_MAP_FRAME_SETTINGS", function(_, root)
            root:CreateDivider()
            local submenu = root:CreateButton("QuestListShortcut: " .. L.textSize)
            local function IsSelected(mode) return GetMode() == mode end
            submenu:CreateRadio(L.normal, IsSelected, SetMode, "normal")
            submenu:CreateRadio(L.compact, IsSelected, SetMode, "compact")
        end)
        menuHooked = true
    end
    if not updateHooked and type(QuestLogQuests_Update) == "function" then
        hooksecurefunc("QuestLogQuests_Update", Initialize)
        updateHooked = true
    end
    -- Also handles a panel/pool loaded after the addon, or already visible at login.
    if ApplyPools() then RebuildList() end
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, name)
    if event == "PLAYER_LOGIN" or (event == "ADDON_LOADED" and name == addonName) then
        -- SavedVariables are restored after the Lua files load, before ADDON_LOADED.
        if type(QuestListShortcutDB) ~= "table" then QuestListShortcutDB = {} end
        if QuestListShortcutDB.textMode ~= "compact" then QuestListShortcutDB.textMode = "normal" end
        ready = true
    end
    Initialize()
end)
