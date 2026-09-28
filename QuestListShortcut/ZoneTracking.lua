local _, addon = ...
local L = addon.L

local events = CreateFrame("Frame")
local buttons = {}
local hooked = false
local Refresh

local function GetState(header)
    local api = C_QuestLog
    if not api or type(api.GetInfo) ~= "function" or type(api.GetNumQuestLogEntries) ~= "function"
        or type(api.GetQuestWatchType) ~= "function" or type(api.AddQuestWatch) ~= "function"
        or type(api.RemoveQuestWatch) ~= "function" then
        return nil, L.unavailable
    end
    local index = header.questLogIndex
    local info = index and api.GetInfo(index)
    if not info or not info.isHeader or (header.sortKey and info.headerSortKey ~= header.sortKey) then
        return nil, L.unavailable
    end
    local state = { questIDs = {}, watched = 0, title = info.title }
    -- Forever exposes quests beneath collapsed headers in the log API; the UI
    -- applies collapse/search filtering separately. Never enumerate visible rows.
    for questIndex = index + 1, api.GetNumQuestLogEntries() do
        local quest = api.GetInfo(questIndex)
        if quest then
            if quest.isHeader then break end
            if quest.questID and quest.questID > 0 and not quest.isHidden and not quest.isTask then
                state.questIDs[#state.questIDs + 1] = quest.questID
                if api.GetQuestWatchType(quest.questID) ~= nil then
                    state.watched = state.watched + 1
                end
            end
        end
    end
    state.allWatched = #state.questIDs > 0 and state.watched == #state.questIDs
    if #state.questIDs == 0 then return state, L.empty end
    if state.allWatched then
        if not QuestUtil or type(QuestUtil.CanRemoveQuestWatch) ~= "function" then
            return state, L.unavailable
        end
        if not QuestUtil.CanRemoveQuestWatch() then return state, L.restricted end
    end
    return state
end

local function ShowTooltip(button)
    local state, reason = GetState(button.header)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText(state and state.allWatched and L.untrackZone or L.track)
    if state then
        GameTooltip:AddLine(state.title or "", 1, 0.82, 0, true)
        GameTooltip:AddLine(L.count:format(state.watched, #state.questIDs), 1, 1, 1, true)
    end
    GameTooltip:AddLine(L.scope, 1, 1, 1, true)
    if reason then GameTooltip:AddLine(reason, 1, 0.65, 0.2, true) end
    GameTooltip:Show()
end

local function ToggleZone(button)
    -- Frames are pooled: resolve the CURRENT header and snapshot IDs at click time.
    local state, reason = GetState(button.header)
    if not state or reason then Refresh(); return end
    local remove = state.allWatched
    for _, questID in ipairs(state.questIDs) do
        local watched = C_QuestLog.GetQuestWatchType(questID) ~= nil
        if remove and watched then
            if not QuestUtil.CanRemoveQuestWatch() then break end
            C_QuestLog.RemoveQuestWatch(questID)
        elseif not remove and not watched then
            if not C_QuestLog.IsQuestDisabledForSession or not C_QuestLog.IsQuestDisabledForSession(questID) then
                C_QuestLog.AddQuestWatch(questID)
            end
        end
    end
    -- Show the real result, including partial success at the game's watch limit.
    for _, questID in ipairs(state.questIDs) do
        local watched = C_QuestLog.GetQuestWatchType(questID) ~= nil
        if watched == remove then
            DEFAULT_CHAT_FRAME:AddMessage("QuestListShortcut: " .. L.incomplete, 1, 0.65, 0.2)
            break
        end
    end
    Refresh()
end

local function HideTooltip(button)
    if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
end

local function CreateZoneButton(header)
    local button = CreateFrame("Button", nil, header)
    button.header = header
    button:SetSize(18, 18)
    button:SetPoint("RIGHT", header, "RIGHT", -3, 0)
    button:SetFrameLevel(header:GetFrameLevel() + 2)
    button:SetMotionScriptsWhileDisabled(true)
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnClick", ToggleZone)
    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", HideTooltip)
    button:SetScript("OnHide", HideTooltip)

    local box = button:CreateTexture(nil, "BACKGROUND")
    box:SetAllPoints()
    box:SetAtlas("questlog-icon-ticksquare")
    button.check = button:CreateTexture(nil, "ARTWORK")
    button.check:SetAllPoints()
    button.check:SetAtlas("questlog-icon-checkmark-yellow")
    button.partial = button:CreateTexture(nil, "ARTWORK")
    button.partial:SetSize(8, 2)
    button.partial:SetPoint("CENTER")
    button.partial:SetColorTexture(1, 0.82, 0, 1)
    button:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    buttons[header] = button
    return button
end

Refresh = function()
    local panel = QuestMapFrame and QuestMapFrame.QuestsFrame
    local list = panel and panel.ScrollFrame
    local pool = list and list.headerFramePool
    if not pool then return end
    local active = {}
    for header in pool:EnumerateActive() do
        if header.CollapseButton then
            local button = buttons[header] or CreateZoneButton(header)
            active[header] = true
            -- Keep both controls inside the scroll viewport, clear of its scrollbar.
            -- Reapply after Blizzard lays out/reuses the header; offsets never add up.
            header.CollapseButton:ClearAllPoints()
            header.CollapseButton:SetPoint("RIGHT", header, "RIGHT", -27, 0)
            local label = header.Text or (header.GetFontString and header:GetFontString())
            if label then label:SetPoint("RIGHT", header.CollapseButton, "LEFT", -4, 0) end
            local state, reason = GetState(header)
            button.check:SetShown(state ~= nil and state.allWatched)
            button.partial:SetShown(state ~= nil and state.watched > 0 and not state.allWatched)
            button:SetEnabled(reason == nil)
            button:SetAlpha(reason and 0.5 or 1)
            button:Show()
            if GameTooltip:IsOwned(button) then ShowTooltip(button) end
        end
    end
    for header, button in pairs(buttons) do
        if not active[header] then button:Hide() end
    end
end

local function Initialize()
    if not hooked and type(QuestLogQuests_Update) == "function" then
        -- A post-hook runs after pooled headers have their new indices and sort keys.
        hooksecurefunc("QuestLogQuests_Update", Refresh)
        hooked = true
        events:UnregisterEvent("ADDON_LOADED")
    end
    Refresh()
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
events:RegisterEvent("QUEST_LOG_UPDATE")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", Initialize)
Initialize()
