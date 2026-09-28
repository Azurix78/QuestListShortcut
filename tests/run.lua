-- Behavioral checks with WoW API doubles; no game or SavedVariables required.
local addonRoot = (TEST_ROOT or ".") .. "/QuestListShortcut"
local tocText = TEST_TOC
if not tocText then
    local tocFile = assert(io.open(addonRoot .. "/QuestListShortcut.toc", "r"))
    tocText = tocFile:read("*a")
    tocFile:close()
end
local passed = 0
local function check(name, test)
    test()
    passed = passed + 1
    print("PASS: " .. name)
end

local function setup(deferred, locale)
    local state = { frames = {}, watches = { 101, 201, 301 }, allowed = true,
        removed = {}, added = {}, messages = {}, search = "Stormwind", cleared = false }
    local entries = {
        { isHeader = true, title = "A", isCollapsed = false }, { questID = 101 },
        { isHeader = true, title = "B", isCollapsed = false }, { questID = 201 },
        { isHeader = true, title = "C", isCollapsed = false }, { questID = 301 },
    }
    state.entries = entries
    local function visibleEntries()
        if state.fullLog then return entries end
        local result, hidden = {}, false
        for _, entry in ipairs(entries) do
            if entry.isHeader then hidden = entry.isCollapsed end
            if entry.isHeader or not hidden then result[#result + 1] = entry end
        end
        return result
    end
    local frame = {}
    frame.__index = frame
    function frame:SetHeight(value) self.height = value end
    function frame:SetWidth(value) self.width = value end
    function frame:SetSize(width, height) self.width, self.height = width, height end
    function frame:SetFrameLevel(value) self.level = value end
    function frame:GetFrameLevel() return self.level or 1 end
    function frame:SetAlpha(value) self.alpha = value end
    function frame:RegisterForClicks(value) self.clicks = value end
    function frame:SetHighlightTexture() end
    function frame:SetAllPoints() end
    function frame:SetAtlas(value) self.atlas = value end
    function frame:SetColorTexture() end
    function frame:CreateTexture() return CreateFrame("Texture", nil, self) end
    function frame:ClearAllPoints() self.points = {} end
    function frame:GetWidth() return self.width or (self.parent and self.parent:GetWidth()) or 300 end
    function frame:SetText(value) self.text = value end
    function frame:SetEnabled(value) self.enabled = value end
    function frame:SetMotionScriptsWhileDisabled(value) self.motionWhileDisabled = value end
    function frame:SetVerticalScroll(value) self.verticalScroll = value end
    function frame:SetScript(event, callback) self.scripts[event] = callback end
    function frame:HookScript(event, callback)
        local old = self.scripts[event]
        self.scripts[event] = function(...)
            if old then old(...) end
            callback(...)
        end
    end
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:UnregisterEvent(event) self.events[event] = nil end
    function frame:GetNumPoints() return #self.points end
    function frame:GetPoint(index) return (unpack or table.unpack)(self.points[index]) end
    function frame:SetPoint(point, relativeTo, relativePoint, x, y)
        for index, anchor in ipairs(self.points) do
            if anchor[1] == point then
                self.points[index] = { point, relativeTo, relativePoint, x, y }
                return
            end
        end
        self.points[#self.points + 1] = { point, relativeTo, relativePoint, x, y }
    end
    function frame:IsShown() return self.shown end
    function frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function frame:SetShown(value)
        if self.shown == value then return end
        self.shown = value
        local handler = self.scripts[value and "OnShow" or "OnHide"]
        if handler then handler(self) end
    end
    function frame:Show() self:SetShown(true) end
    function frame:Hide() self:SetShown(false) end
    GetLocale = function() return locale or "frFR" end
    CreateFrame = function(kind, name, parent, template)
        local result = setmetatable({ kind = kind, parent = parent, template = template,
            shown = true, scripts = {}, points = {}, events = {} }, frame)
        state.frames[#state.frames + 1] = result
        if name then _G[name] = result end
        return result
    end
    GameTooltip = {
        SetOwner = function(self, owner) self.owner = owner end,
        SetText = function(self, text) self.title, self.lines = text, {} end,
        AddLine = function(self, text) self.lines[#self.lines + 1] = text end,
        Show = function(self) self.shown = true end,
        Hide = function(self) self.shown, self.owner = false, nil end,
        IsOwned = function(self, owner) return self.owner == owner end,
    }
    DEFAULT_CHAT_FRAME = { AddMessage = function(_, text) state.messages[#state.messages + 1] = text end }
    QuestUtil = { CanRemoveQuestWatch = function() return state.allowed end }
    C_QuestLog = {
        GetNumQuestLogEntries = function() return #visibleEntries(), 3 end,
        GetInfo = function(index) return visibleEntries()[index] end,
        GetNumQuestWatches = function() return #state.watches end,
        GetQuestIDForQuestWatchIndex = function(index) return state.watches[index] end,
        GetQuestWatchType = function(questID)
            for _, watchedID in ipairs(state.watches) do
                if questID == watchedID then return 0 end
            end
        end,
        IsQuestDisabledForSession = function(questID) return state.disabledQuest == questID end,
        AddQuestWatch = function(questID)
            if state.limit and #state.watches >= state.limit then return false end
            state.added[#state.added + 1] = questID
            state.watches[#state.watches + 1] = questID
            return true
        end,
        RemoveQuestWatch = function(questID)
            state.removed[#state.removed + 1] = questID
            if state.refused == questID then return false end
            for index, watchedID in ipairs(state.watches) do
                if questID == watchedID then table.remove(state.watches, index); break end
            end
            if state.restrictAfterFirst then state.allowed = false end
            return true
        end,
    }
    CollapseQuestHeader = function(index)
        assert(state.cleared, "Search must be cleared before collapsing")
        local entry = visibleEntries()[index]
        assert(entry and entry.isHeader, "Invalid header after indices shifted")
        entry.isCollapsed = true
    end
    SetCVar = function() error("Must not change CVars") end
    AbandonQuest = function() error("Must not abandon a quest") end
    C_QuestLog.SetAbandonQuest = AbandonQuest
    QuestListShortcutBar, QuestMapFrame = nil, nil
    QuestLogQuests_Update = function() end
    hooksecurefunc = function(name, hook)
        local original = _G[name]
        _G[name] = function(...) original(...); hook(...) end
    end
    function state.makePanel()
        local panel = CreateFrame("Frame")
        local list = CreateFrame("ScrollFrame", nil, panel)
        list:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -29)
        list:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -2, 3)
        list.SearchBox = { Clear = function()
            state.search, state.cleared = "", true
            -- Simulate Blizzard restoring header state at the end of a search.
            entries[1].isCollapsed, entries[3].isCollapsed, entries[5].isCollapsed = false, true, false
        end }
        panel.ScrollFrame = list
        state.headers = {}
        list.headerFramePool = { EnumerateActive = function()
            local index = 0
            return function() index = index + 1; return state.headers[index] end
        end }
        QuestMapFrame = { QuestsFrame = panel }
        state.panel, state.list = panel, list
    end
    if not deferred then state.makePanel() end
    state.addon = {}
    -- Exercise the real TOC order and WoW's shared private addon namespace.
    for line in tocText:gmatch("[^\r\n]+") do
        local file = line:match("^%s*([^#%s].-)%s*$")
        if file then assert(loadfile(addonRoot .. "/" .. file))("QuestListShortcut", state.addon) end
    end
    function state.emit(event)
        for _, object in ipairs(state.frames) do
            if object.events[event] and object.scripts.OnEvent then object.scripts.OnEvent(object, event) end
        end
    end
    function state.click(index)
        local button = QuestListShortcutBar.buttons[index]
        button.scripts.OnClick(button)
    end
    function state.makeHeader(index)
        state.fullLog = true
        local header = CreateFrame("Button", nil, state.list)
        header.questLogIndex = index
        header.sortKey = entries[index].headerSortKey
        header.CollapseButton = CreateFrame("Button", nil, header)
        header.Text = CreateFrame("FontString", nil, header)
        state.headers[#state.headers + 1] = header
        QuestLogQuests_Update()
        for _, object in ipairs(state.frames) do
            if object.header == header then return header, object end
        end
        error("Zone button missing")
    end
    return state
end

check("search restoration precedes collapse; shrinking indices and repeated clicks", function()
    local state = setup()
    state.click(1)
    assert(state.search == "" and state.list.verticalScroll == 0)
    for _, entry in ipairs(state.entries) do
        if entry.isHeader then assert(entry.isCollapsed) end
    end
    state.click(1)
    state.entries[1].isCollapsed = false
    state.emit("QUEST_LOG_UPDATE")
    assert(not state.entries[1].isCollapsed, "Must not collapse automatically")
end)

check("snapshot removes every watch despite index shifts and a search filter", function()
    local state = setup()
    state.click(2)
    assert(#state.watches == 0 and #state.removed == 3 and #state.entries == 6)
    assert(state.search == "Stormwind" and not state.cleared)
    assert(not QuestListShortcutBar.buttons[2].enabled)
    state.click(2)
    assert(#state.removed == 3)
end)

check("zero and one watched quest", function()
    local state = setup()
    state.watches = { 101 }
    state.click(2)
    assert(#state.removed == 1 and #state.watches == 0)
    state.emit("QUEST_WATCH_LIST_CHANGED")
    assert(not QuestListShortcutBar.buttons[2].enabled)
end)

check("empty quest log and watch list", function()
    local state = setup()
    C_QuestLog.GetNumQuestLogEntries = function() return 0, 0 end
    state.watches = {}
    state.emit("QUEST_LOG_UPDATE")
    for _, button in ipairs(QuestListShortcutBar.buttons) do assert(not button.enabled) end
    state.click(1)
    state.click(2)
    assert(not state.cleared and #state.removed == 0)
end)

check("native restriction rechecked at click and explained on disabled hover", function()
    local state = setup()
    state.allowed = false
    state.click(2)
    assert(#state.removed == 0)
    local button = QuestListShortcutBar.buttons[2]
    assert(not button.enabled and button.motionWhileDisabled)
    button.scripts.OnEnter(button)
    assert(#GameTooltip.lines == 2)
    state.allowed = true
    state.emit("PLAYER_REGEN_ENABLED")
    assert(button.enabled and #GameTooltip.lines == 1)
end)

check("restriction changing during batch stops safely", function()
    local state = setup()
    state.restrictAfterFirst = true
    state.click(2)
    assert(#state.removed == 1 and #state.watches == 2 and #state.messages == 1)
end)

check("failed removal reported without blocking other quests", function()
    local state = setup()
    state.refused = 201
    state.click(2)
    assert(#state.removed == 3 and #state.watches == 1 and state.watches[1] == 201)
    assert(#state.messages == 1 and QuestListShortcutBar.buttons[2].enabled)
end)

check("missing watch API disables action without error", function()
    local state = setup()
    C_QuestLog.RemoveQuestWatch = nil
    state.emit("QUEST_WATCH_LIST_CHANGED")
    state.click(2)
    assert(not QuestListShortcutBar.buttons[2].enabled and #state.removed == 0)
end)

check("deferred panel load initializes once", function()
    local state = setup(true)
    state.emit("PLAYER_LOGIN")
    assert(not QuestListShortcutBar)
    state.makePanel()
    state.emit("ADDON_LOADED")
    local count, bar = #state.frames, QuestListShortcutBar
    assert(bar and #bar.buttons == 2)
    state.emit("ADDON_LOADED")
    state.emit("PLAYER_ENTERING_WORLD")
    assert(#state.frames == count and QuestListShortcutBar == bar)
end)

check("layout reserves 32px once and preserves top and relative anchors", function()
    local state = setup()
    for index = 1, 10 do
        state.emit("UI_SCALE_CHANGED")
        state.panel.scripts.OnSizeChanged(state.panel)
        state.list:Hide()
        state.list:Show()
    end
    local point, relativeTo, relativePoint, x, y = state.list:GetPoint(2)
    assert(point == "BOTTOMRIGHT" and relativeTo == state.panel and relativePoint == "BOTTOMRIGHT")
    assert(x == -2 and y == 35)
    local _, _, _, _, topY = state.list:GetPoint(1)
    assert(topY == -29 and state.list:GetNumPoints() == 2)
    QuestListShortcutBar.width = 400
    QuestListShortcutBar.scripts.OnSizeChanged()
    assert(QuestListShortcutBar.buttons[1].width == 197)
end)

check("hidden list hides toolbar; return restores it", function()
    local state = setup()
    assert(QuestListShortcutBar:IsVisible())
    state.list:Hide()
    assert(not QuestListShortcutBar:IsShown())
    state.list:Show()
    assert(QuestListShortcutBar:IsVisible())
    state.panel:Hide()
    assert(not QuestListShortcutBar:IsVisible())
    state.panel:Show()
    assert(QuestListShortcutBar:IsVisible())
end)

check("English fallback and French labels", function()
    setup(false, "unknown")
    assert(QuestListShortcutBar.buttons[1].text == "Collapse all")
    setup(false, "frFR")
    assert(QuestListShortcutBar.buttons[1].text == "Tout replier")
end)

check("zone toggle affects only its quests and preserves search/collapse", function()
    local state = setup()
    table.insert(state.entries, 3, { questID = 102 })
    state.watches = { 201 }
    state.entries[1].isCollapsed = true
    local header, button = state.makeHeader(1)
    assert(not button.check:IsShown() and not button.partial:IsShown())
    button.scripts.OnClick(button)
    assert(#state.added == 2 and C_QuestLog.GetQuestWatchType(201) ~= nil)
    assert(button.check:IsShown() and not button.partial:IsShown())
    assert(state.search == "Stormwind" and state.entries[1].isCollapsed and not state.cleared)
    button.scripts.OnClick(button)
    assert(#state.watches == 1 and state.watches[1] == 201 and #state.removed == 2)
    assert(not button.check:IsShown() and not button.partial:IsShown())
end)

check("mixed zone completes tracking before clearing it", function()
    local state = setup()
    table.insert(state.entries, 3, { questID = 102 })
    local _, button = state.makeHeader(1)
    assert(button.partial:IsShown() and not button.check:IsShown())
    button.scripts.OnClick(button)
    assert(#state.added == 1 and state.added[1] == 102 and #state.removed == 0)
    assert(button.check:IsShown())
    button.scripts.OnClick(button)
    assert(C_QuestLog.GetQuestWatchType(101) == nil and C_QuestLog.GetQuestWatchType(102) == nil)
    assert(C_QuestLog.GetQuestWatchType(201) ~= nil and C_QuestLog.GetQuestWatchType(301) ~= nil)
end)

check("pooled header uses current zone with no duplicate controls or shifting", function()
    local state = setup()
    state.watches = {}
    local header, button = state.makeHeader(1)
    local count = #state.frames
    header.questLogIndex = 3
    for index = 1, 8 do QuestLogQuests_Update() end
    assert(#state.frames == count)
    local _, relative, _, offset = header.CollapseButton:GetPoint(1)
    assert(relative == header and offset == -27 and header.CollapseButton:GetNumPoints() == 1)
    button.scripts.OnClick(button)
    assert(#state.added == 1 and state.added[1] == 201)
    state.headers = {}
    QuestLogQuests_Update()
    assert(not button:IsShown())
end)

check("stale header identity and missing API cannot target wrong quests", function()
    local state = setup()
    state.entries[1].headerSortKey = 11
    local header, button = state.makeHeader(1)
    header.questLogIndex = 3
    button.scripts.OnClick(button)
    assert(#state.removed == 0 and not button.enabled)
    header.questLogIndex = 1
    C_QuestLog.AddQuestWatch = nil
    button.scripts.OnClick(button)
    assert(#state.removed == 0 and not button.enabled)
end)

check("watch changes outside addon update zone state and tooltip", function()
    local state = setup()
    local _, button = state.makeHeader(1)
    button.scripts.OnEnter(button)
    assert(GameTooltip.title == "Effacer le suivi")
    state.watches = {}
    state.emit("QUEST_WATCH_LIST_CHANGED")
    assert(not button.check:IsShown() and GameTooltip.title == "Suivre tout")
    state.watches = { 101 }
    state.allowed = false
    state.emit("PLAYER_REGEN_DISABLED")
    assert(not button.enabled)
    button.scripts.OnClick(button)
    assert(#state.removed == 0)
end)

check("watch limit leaves partial state and reports failure", function()
    local state = setup()
    table.insert(state.entries, 3, { questID = 102 })
    state.watches, state.limit = {}, 1
    local _, button = state.makeHeader(1)
    button.scripts.OnClick(button)
    assert(#state.watches == 1 and button.partial:IsShown() and not button.check:IsShown())
    assert(#state.messages == 1)
end)

check("zone removal failure leaves accurate partial state", function()
    local state = setup()
    table.insert(state.entries, 3, { questID = 102 })
    state.watches, state.refused = { 101, 102, 201 }, 102
    local _, button = state.makeHeader(1)
    button.scripts.OnClick(button)
    assert(button.partial:IsShown() and not button.check:IsShown() and #state.messages == 1)
    assert(C_QuestLog.GetQuestWatchType(201) ~= nil)
end)

check("empty zone and internal quests do not become tracking targets", function()
    local state = setup()
    state.entries[2].isHidden = true
    local _, button = state.makeHeader(1)
    assert(not button.enabled)
    button.scripts.OnClick(button)
    assert(#state.added == 0 and #state.removed == 0)
end)

check("session-disabled quests are not added; eligible ones still are", function()
    local state = setup()
    table.insert(state.entries, 3, { questID = 102 })
    state.watches, state.disabledQuest = {}, 102
    local _, button = state.makeHeader(1)
    button.scripts.OnClick(button)
    assert(#state.added == 1 and state.added[1] == 101 and button.partial:IsShown())
    assert(#state.messages == 1)
end)

local expectedLabels = {
    enUS = "Collapse all", enGB = "Collapse all", frFR = "Tout replier",
    deDE = "Alle einklappen", esES = "Contraer todo", esMX = "Contraer todo",
    itIT = "Comprimi tutto", ptBR = "Recolher tudo", ruRU = "Свернуть всё",
    koKR = "모두 접기", zhCN = "全部折叠", zhTW = "全部收合",
}
for locale, expected in pairs(expectedLabels) do
    check("complete localization, UI and placeholders: " .. locale, function()
        local state = setup(false, locale)
        local L = state.addon.L
        local english = getmetatable(L).__index
        for key, value in pairs(english) do
            assert(type(L[key]) == "string" and #L[key] > 0, "Missing string: " .. key)
            if locale ~= "enUS" and locale ~= "enGB" then
                assert(rawget(L, key), "Untranslated string: " .. locale .. "/" .. key)
            end
            local function placeholders(text)
                local result = {}
                for item in text:gmatch("%%[a-zA-Z%%]") do result[#result + 1] = item end
                return table.concat(result, ",")
            end
            assert(placeholders(value) == placeholders(L[key]), "Bad placeholders: " .. key)
        end
        for key in pairs(L) do assert(english[key], "Unknown localization key: " .. key) end
        assert(QuestListShortcutBar.buttons[1].text == expected)
        assert(QuestListShortcutBar.buttons[2].text == L.untrack)
        QuestListShortcutBar.buttons[1].scripts.OnEnter(QuestListShortcutBar.buttons[1])
        assert(GameTooltip.lines[1] == L.collapseTip)
        local _, button = state.makeHeader(1)
        button.scripts.OnEnter(button)
        assert(GameTooltip.title == L.untrackZone)
        assert(GameTooltip.lines[2] == L.count:format(1, 1))
        state.allowed = false
        button.scripts.OnEnter(button)
        assert(GameTooltip.lines[4] == L.restricted)
        state.watches = {}
        button.scripts.OnEnter(button)
        assert(GameTooltip.title == L.track)
    end)
end

check("missing translation falls back per key", function()
    local state = setup(false, "frFR")
    state.addon.L.count = nil
    assert(state.addon.L.count:format(2, 3) == "2 / 3 quests tracked")
    assert(state.addon.L.collapse == "Tout replier")
end)

print(tostring(passed) .. " tests passed. In-game validation remains required.")
