local _, addon = ...
local L = addon.L

local FOOTER_HEIGHT = 32
local events = CreateFrame("Frame")
local bar, scrollFrame, questsFrame, bottomAnchor

local function CollapseUnavailable()
    if not C_QuestLog or type(C_QuestLog.GetNumQuestLogEntries) ~= "function"
        or type(C_QuestLog.GetInfo) ~= "function" or type(CollapseQuestHeader) ~= "function"
        or not scrollFrame.SearchBox or type(scrollFrame.SearchBox.Clear) ~= "function" then
        return L.unavailable
    end
    if C_QuestLog.GetNumQuestLogEntries() == 0 then
        return L.emptyLog
    end
end

local function UntrackUnavailable()
    if not C_QuestLog or type(C_QuestLog.GetNumQuestWatches) ~= "function"
        or type(C_QuestLog.GetQuestIDForQuestWatchIndex) ~= "function"
        or type(C_QuestLog.RemoveQuestWatch) ~= "function"
        or not QuestUtil or type(QuestUtil.CanRemoveQuestWatch) ~= "function" then
        return L.unavailable
    end
    if not QuestUtil.CanRemoveQuestWatch() then
        return L.restricted
    end
    if C_QuestLog.GetNumQuestWatches() == 0 then
        return L.emptyWatch
    end
end

local function ShowTooltip(button)
    GameTooltip:SetOwner(button, "ANCHOR_TOP")
    GameTooltip:SetText(button.label)
    GameTooltip:AddLine(button.description, 1, 1, 1, true)
    local reason = button.unavailable()
    if reason then
        GameTooltip:AddLine(reason, 1, 0.65, 0.2, true)
    end
    GameTooltip:Show()
end

local function RefreshButtons()
    if not bar then return end
    for _, button in ipairs(bar.buttons) do
        button:SetEnabled(button.unavailable() == nil)
        if GameTooltip:IsOwned(button) then
            ShowTooltip(button)
        end
    end
end

local function CollapseAll()
    if CollapseUnavailable() then
        RefreshButtons()
        return
    end
    -- Clear through Blizzard's method FIRST: ending a search restores saved headers.
    scrollFrame.SearchBox:Clear()
    for index = C_QuestLog.GetNumQuestLogEntries(), 1, -1 do
        local info = C_QuestLog.GetInfo(index)
        if info and info.isHeader and not info.isCollapsed then
            CollapseQuestHeader(index)
        end
    end
    -- Blizzard refreshes the contents in response to QUEST_LOG_UPDATE.
    scrollFrame:SetVerticalScroll(0)
    RefreshButtons()
end

local function UntrackAll()
    if UntrackUnavailable() then
        RefreshButtons()
        return
    end
    -- Watch indices change during removals. Take a snapshot independent of the UI.
    local questIDs = {}
    for index = 1, C_QuestLog.GetNumQuestWatches() do
        local questID = C_QuestLog.GetQuestIDForQuestWatchIndex(index)
        if questID then
            questIDs[#questIDs + 1] = questID
        end
    end
    for _, questID in ipairs(questIDs) do
        if not QuestUtil.CanRemoveQuestWatch() then break end
        C_QuestLog.RemoveQuestWatch(questID)
    end
    if C_QuestLog.GetNumQuestWatches() > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("QuestListShortcut: " .. L.remaining, 1, 0.65, 0.2)
    end
    RefreshButtons()
end

local function CreateButton(label, description, unavailable, onClick)
    local button = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
    button:SetHeight(24)
    button:SetText(label)
    button.label = label
    button.description = description
    button.unavailable = unavailable
    button:SetMotionScriptsWhileDisabled(true)
    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", function(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    button:SetScript("OnHide", function(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    return button
end

local function UpdateLayout()
    -- Use the original bottom anchor every time so the 32px inset never accumulates.
    scrollFrame:SetPoint(bottomAnchor[1], bottomAnchor[2], bottomAnchor[3],
        bottomAnchor[4], bottomAnchor[5] + FOOTER_HEIGHT)
    local width = math.max(1, (bar:GetWidth() - 6) / 2)
    for _, button in ipairs(bar.buttons) do
        button:SetWidth(width)
    end
end

local function UpdateVisibility()
    bar:SetShown(scrollFrame:IsVisible())
    if bar:IsShown() then
        UpdateLayout()
        RefreshButtons()
    end
end

local function Initialize()
    if bar then return true end
    local panel = QuestMapFrame and QuestMapFrame.QuestsFrame
    local list = panel and panel.ScrollFrame
    if not list then return false end

    -- Preserve the top anchor and the original relative frame and offsets.
    for index = 1, list:GetNumPoints() do
        local point, relativeTo, relativePoint, x, y = list:GetPoint(index)
        if point == "BOTTOMRIGHT" then
            bottomAnchor = { point, relativeTo, relativePoint, x, y }
            break
        end
    end
    if not bottomAnchor then return false end
    questsFrame, scrollFrame = panel, list
    bar = CreateFrame("Frame", "QuestListShortcutBar", questsFrame)
    bar:SetHeight(FOOTER_HEIGHT)
    bar:SetPoint("BOTTOMLEFT", questsFrame, "BOTTOMLEFT", 0, bottomAnchor[5])
    bar:SetPoint("BOTTOMRIGHT", bottomAnchor[2], bottomAnchor[3], bottomAnchor[4], bottomAnchor[5])

    local collapse = CreateButton(L.collapse, L.collapseTip, CollapseUnavailable, CollapseAll)
    local untrack = CreateButton(L.untrack, L.untrackTip, UntrackUnavailable, UntrackAll)
    collapse:SetPoint("LEFT", bar, "LEFT", 0, 0)
    untrack:SetPoint("RIGHT", bar, "RIGHT", 0, 0)
    bar.buttons = { collapse, untrack }

    bar:HookScript("OnSizeChanged", UpdateLayout)
    scrollFrame:HookScript("OnShow", UpdateVisibility)
    scrollFrame:HookScript("OnHide", UpdateVisibility)
    questsFrame:HookScript("OnShow", UpdateVisibility)
    questsFrame:HookScript("OnSizeChanged", UpdateLayout)
    events:UnregisterEvent("ADDON_LOADED")
    UpdateVisibility()
    return true
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("QUEST_LOG_UPDATE")
events:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("UI_SCALE_CHANGED")
events:SetScript("OnEvent", function(_, event)
    if not Initialize() then return end
    if event == "UI_SCALE_CHANGED" then UpdateLayout() end
    RefreshButtons()
end)
Initialize()
