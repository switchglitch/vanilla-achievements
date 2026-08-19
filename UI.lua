local VA = VanillaAchievements

local function SetButtonLabel(button, text)
    if button and button.label then button.label:SetText(text or "") end
end

local function MakeButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetBackdrop({
        bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=9,
        insets={left=2,right=2,top=2,bottom=2},
    })
    button:SetBackdropColor(0.08,0.07,0.05,0.96)
    button:SetBackdropBorderColor(0.35,0.29,0.18,1)
    button.label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    button.label:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.label:SetText(text or "")
    button:SetScript("OnEnter", function()
        this.isHovered = true
        this:SetBackdropColor(0.18,0.13,0.04,0.98)
        this:SetBackdropBorderColor(1,0.68,0.18,1)
    end)
    button:SetScript("OnLeave", function()
        this.isHovered = nil
        this:SetBackdropColor(0.08,0.07,0.05,0.96)
        this:SetBackdropBorderColor(0.35,0.29,0.18,1)
        VA:RefreshUI()
    end)
    return button
end

local function DisplayDescription(def, complete)
    if def.secret and not complete then return "The title is your clue." end
    return def.secret and (def.revealed or def.description) or def.description
end

function VA:RefreshSettingButtons()
    local buttons = self.ui and self.ui.settingButtons
    if not buttons or not VA_DB or not VA_DB.settings then return end
    local key, button, enabled
    for key, button in pairs(buttons) do
        enabled = VA_DB.settings[key] ~= false
        SetButtonLabel(button, tostring(button.settingLabel) .. ": " .. (enabled and "On" or "Off"))
        if enabled then
            button:SetBackdropBorderColor(0.35,0.85,0.42,1)
        else
            button:SetBackdropBorderColor(0.38,0.34,0.30,1)
        end
    end
end

function VA:GetDisplayList()
    local category = VA_DB.settings.category or "ALL"
    local filter = VA_DB.settings.filter or "ALL"
    local search = string.lower(tostring(VA_DB.settings.search or ""))
    local cacheKey = tostring(category) .. "|" .. tostring(filter) .. "|" .. search .. "|" .. tostring(self:GetCompletedCount())
    if self.ui and self.ui.displayCacheKey == cacheKey and self.ui.displayCache then
        return self.ui.displayCache
    end
    local list = {}
    local index, def, complete
    for index=1,table.getn(self.catalog) do
        def = self.catalog[index]
        complete = self:IsComplete(def.id)
        local nameText = string.lower(tostring(def.name or ""))
        local descriptionText = string.lower(tostring(def.description or ""))
        -- A search is global: keep the category buttons useful for browsing,
        -- but do not hide matching achievements from another category.
        if (category == "ALL" or search ~= "" or def.category == category)
            and (filter == "ALL" or (filter == "COMPLETE" and complete) or (filter == "LOCKED" and not complete))
            and (search == "" or string.find(nameText, search, 1, true) or string.find(descriptionText, search, 1, true)) then
            table.insert(list, def)
        end
    end
    table.sort(list, function(left, right)
        local lc = VA:IsComplete(left.id)
        local rc = VA:IsComplete(right.id)
        if lc ~= rc then return lc end
        if lc and rc then
            local lt = VA:GetCompletedAt(left.id) or 0
            local rt = VA:GetCompletedAt(right.id) or 0
            if lt ~= rt then return lt > rt end
        end
        return tostring(left.name) < tostring(right.name)
    end)
    if self.ui then
        self.ui.displayCacheKey = cacheKey
        self.ui.displayCache = list
    end
    return list
end

function VA:ScrollAchievements(delta)
    local ui = self.ui
    if not ui or not ui.rows then return end
    local now = GetTime and GetTime() or nil
    if now and ui.lastScrollInput and now - ui.lastScrollInput < 0.035 then return end
    if now then ui.lastScrollInput = now end
    local list, pageSize, visibleRows, pageStart, maximumScroll = self:GetAchievementScrollMetrics()
    if not list then return end
    local direction = (tonumber(delta) or 0) > 0 and -1 or 1
    local scroll = math.max(0, math.min(maximumScroll, (tonumber(ui.offset) or 0) - pageStart + direction))
    ui.offset = pageStart + scroll
    self:RefreshUI()
end

function VA:GetAchievementScrollMetrics()
    local ui = self.ui
    if not ui or not ui.rows then return nil end
    local list = self:GetDisplayList()
    local pageSize = tonumber(ui.pageSize) or 14
    local visibleRows = table.getn(ui.rows)
    local pageStart = math.floor((tonumber(ui.offset) or 0) / pageSize) * pageSize
    local maximumPageStart = math.max(0, math.floor(math.max(0, table.getn(list) - 1) / pageSize) * pageSize)
    pageStart = math.max(0, math.min(maximumPageStart, pageStart))
    local maximumScroll = math.min(pageSize - visibleRows,
        math.max(0, table.getn(list) - pageStart - visibleRows))
    local scroll = math.max(0, math.min(maximumScroll, (tonumber(ui.offset) or 0) - pageStart))
    return list, pageSize, visibleRows, pageStart, maximumScroll, scroll
end

function VA:ScrollAchievementsFromClick(track, cursorY)
    local ui = self.ui
    if not ui or not track then return end
    local list, pageSize, visibleRows, pageStart, maximumScroll = self:GetAchievementScrollMetrics()
    if not list then return end
    if maximumScroll <= 0 or not cursorY or not track.GetTop then return end
    local scale = track.GetEffectiveScale and track:GetEffectiveScale() or 1
    local top = track:GetTop()
    local height = track:GetHeight()
    if not top or not height or height <= 0 then return end
    local position = ((cursorY / scale) - top) / height
    position = math.max(0, math.min(1, position))
    ui.offset = pageStart + math.floor(position * maximumScroll + 0.5)
    self:RefreshUI()
end

function VA:BeginAchievementScrollDrag(track, cursorY)
    local ui = self.ui
    if not ui or not track or not cursorY then return end
    local list, pageSize, visibleRows, pageStart, maximumScroll, scroll = self:GetAchievementScrollMetrics()
    if not list or maximumScroll <= 0 then return end
    track.dragging = true
    track.dragStartY = cursorY
    track.dragStartScroll = scroll
    track.dragPageStart = pageStart
    track.dragMaximumScroll = maximumScroll
end

function VA:ScrollAchievementsFromDrag(track, cursorY)
    local ui = self.ui
    if not ui or not track or not cursorY or not track.dragStartY then return end
    local list, pageSize, visibleRows, pageStart, maximumScroll = self:GetAchievementScrollMetrics()
    if not list then return end
    if maximumScroll <= 0 then return end
    local scale = track.GetEffectiveScale and track:GetEffectiveScale() or 1
    local thumbHeight = (ui.scrollThumb and ui.scrollThumb.GetHeight and ui.scrollThumb:GetHeight()) or 48
    local travel = (track:GetHeight() or 371) - thumbHeight
    if travel <= 0 then return end
    local delta = (cursorY - track.dragStartY) / scale
    local scroll = (track.dragStartScroll or 0) - (delta / travel) * maximumScroll
    scroll = math.max(0, math.min(maximumScroll, math.floor(scroll + 0.5)))
    ui.offset = pageStart + scroll
    self:RefreshUI()
end

function VA:RefreshUI()
    local ui = self.ui
    if not ui or not ui.frame then return end
    local category = VA_DB.settings.category or "ALL"
    local completed = self:GetCompletedCount()
    local total = table.getn(self.catalog)
    ui.count:SetText(tostring(completed) .. " / " .. tostring(total) .. " complete")

    -- Settings get their own tab so the category rail remains readable and
    -- the achievement list has the full content area available.
    if category == "SETTINGS" then
        ui.count:Hide()
        ui.search:Hide()
        if ui.settingsPanel then ui.settingsPanel:Show() end
        for _, button in pairs(ui.filterButtons or {}) do button:Hide() end
        for _, row in pairs(ui.rows or {}) do row:Hide() end
        if ui.page then ui.page:Hide() end
        if ui.prev then ui.prev:Hide() end
        if ui.next then ui.next:Hide() end
        if ui.scrollBar then ui.scrollBar:Hide() end
        if ui.scrollThumb then ui.scrollThumb:Hide() end
        if ui.scrollUp then ui.scrollUp:Hide() end
        if ui.scrollDown then ui.scrollDown:Hide() end
        for key, button in pairs(ui.categoryButtons or {}) do
            if key == "SETTINGS" then button:SetBackdropBorderColor(1,0.68,0.18,1)
            else button:SetBackdropBorderColor(0.35,0.29,0.18,1) end
        end
        self:RefreshSettingButtons()
        return
    end

    ui.count:Show()
    ui.search:Show()
    if ui.settingsPanel then ui.settingsPanel:Hide() end
    for _, button in pairs(ui.filterButtons or {}) do button:Show() end
    if ui.page then ui.page:Show() end

    local list = self:GetDisplayList()
    local pageSize = tonumber(ui.pageSize) or 14
    local visibleRows = table.getn(ui.rows)
    local pageStart = math.floor((tonumber(ui.offset) or 0) / pageSize) * pageSize
    local maximumPageStart = math.max(0, math.floor(math.max(0, table.getn(list)-1) / pageSize) * pageSize)
    pageStart = math.max(0, math.min(maximumPageStart, pageStart))
    local maximumScroll = math.min(pageSize - visibleRows,
        math.max(0, table.getn(list) - pageStart - visibleRows))
    local scroll = math.max(0, math.min(maximumScroll, (tonumber(ui.offset) or 0) - pageStart))
    ui.offset = pageStart + scroll
    if ui.scrollThumb then
        local trackHeight = (ui.scrollBar and ui.scrollBar.GetHeight and ui.scrollBar:GetHeight()) or 371
        local thumbHeight = ui.scrollThumb:GetHeight() or 48
        local travel = math.max(0, trackHeight - thumbHeight)
        local thumbOffset = 0
        if maximumScroll > 0 then thumbOffset = travel * scroll / maximumScroll end
        ui.scrollThumb:ClearAllPoints()
        ui.scrollThumb:SetPoint("TOPLEFT", ui.frame, "TOPLEFT", 684, -88 - thumbOffset)
    end
    -- Do not leave an inert scrollbar on short result sets (for example a
    -- search returning only two achievements).  The controls return as soon
    -- as the current page has more rows than fit in the viewport.
    local scrollVisible = maximumScroll > 0
    if ui.scrollBar then if scrollVisible then ui.scrollBar:Show() else ui.scrollBar:Hide() end end
    if ui.scrollThumb then if scrollVisible then ui.scrollThumb:Show() else ui.scrollThumb:Hide() end end
    if ui.scrollUp then if scrollVisible then ui.scrollUp:Show() else ui.scrollUp:Hide() end end
    if ui.scrollDown then if scrollVisible then ui.scrollDown:Show() else ui.scrollDown:Hide() end end

    local index, row, def, complete, current, required, when
    for index=1,visibleRows do
        row = ui.rows[index]
        def = list[ui.offset + index]
        if def then
            complete = self:IsComplete(def.id)
            current, required = self:GetProgress(def)
            when = self:GetCompletedAt(def.id)
            row.def = def
            row.name:SetText(def.name)
            row.description:SetText(DisplayDescription(def, complete))
            row.icon:SetTexture(def.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            if complete then
                if def.secret then
                    -- Keep secrets purple after discovery; completion brightens
                    -- the treatment without making them look like ordinary rows.
                    row:SetBackdropColor(0.10,0.025,0.14,0.98)
                    row:SetBackdropBorderColor(0.82,0.38,1,1)
                    row.name:SetTextColor(1,0.72,1)
                    row.status:SetText("COMPLETE")
                    row.status:SetTextColor(0.75,1,0.85)
                else
                    row:SetBackdropColor(0.12,0.08,0.02,0.98)
                    row:SetBackdropBorderColor(0.85,0.58,0.15,1)
                    row.name:SetTextColor(1,0.82,0.35)
                    row.status:SetText("COMPLETE")
                    row.status:SetTextColor(0.35,1,0.42)
                end
                row.date:SetText(when and date("%d %b %Y", when) or "")
                row.icon:SetVertexColor(1,1,1)
            elseif def.secret then
                row:SetBackdropColor(0.035,0.018,0.045,0.98)
                row:SetBackdropBorderColor(0.26,0.12,0.34,1)
                row.name:SetTextColor(0.55,0.36,0.68)
                row.status:SetText("SECRET")
                row.status:SetTextColor(0.55,0.36,0.68)
                row.date:SetText("")
                -- Secret progress is intentionally subdued until unlocked;
                -- it should not look like a completed gold badge.
                row.icon:SetVertexColor(0.38,0.30,0.42)
            else
                row:SetBackdropColor(0.025,0.023,0.020,0.98)
                row:SetBackdropBorderColor(0.25,0.22,0.18,1)
                row.name:SetTextColor(0.78,0.75,0.68)
                row.status:SetText(self:FormatProgress(def, current, required))
                row.status:SetTextColor(current > 0 and 1 or 0.65, current > 0 and 0.75 or 0.65, 0.20)
                row.date:SetText("")
                row.icon:SetVertexColor(0.46,0.46,0.46)
            end
            row:Show()
        else
            row.def = nil
            row:Hide()
        end
    end

    if table.getn(list) == 0 then ui.page:SetText("No achievements in this view.")
    else
        ui.page:SetText(tostring(ui.offset + 1) .. "-" ..
            tostring(math.min(ui.offset + visibleRows, table.getn(list))) .. " of " .. tostring(table.getn(list)))
    end
    local hasPrevious = pageStart > 0
    local hasNext = pageStart + pageSize < table.getn(list)
    SetButtonLabel(ui.prev, hasPrevious and "< Previous" or "")
    SetButtonLabel(ui.next, hasNext and "Next >" or "")
    if hasPrevious then ui.prev:Show() else ui.prev:Hide() end
    if hasNext then ui.next:Show() else ui.next:Hide() end

    local key, button
    for key, button in pairs(ui.categoryButtons) do
        if key == (VA_DB.settings.category or "ALL") then
            button:SetBackdropBorderColor(1,0.68,0.18,1)
        else button:SetBackdropBorderColor(0.35,0.29,0.18,1) end
    end
    for key, button in pairs(ui.filterButtons) do
        if key == (VA_DB.settings.filter or "ALL") then
            button:SetBackdropBorderColor(0.35,0.70,1,1)
        else button:SetBackdropBorderColor(0.35,0.29,0.18,1) end
    end
    self:RefreshSettingButtons()
end

function VA:ShowNextToast()
    if not self.ui or not self.ui.toast or self.runtime.currentToast then return end
    self.runtime.toastQueue = self.runtime.toastQueue or {}
    local def = table.remove(self.runtime.toastQueue, 1)
    if not def then return end

    local toast = self.ui.toast
    self.runtime.currentToast = def.id
    toast.title:SetText("ACHIEVEMENT EARNED")
    toast.name:SetText(def.name or "Achievement")
    toast.description:SetText(def.secret and (def.revealed or def.description) or def.description)
    toast.icon:SetTexture(def.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    toast:Show()
    self:PlayAchievementSound(def)
    self.runtime.toastHideAt = self:Now() + 5
end

function VA:ShowToast(def)
    if not def or not self.ui or not self.ui.toast then return end
    self.runtime.toastQueue = self.runtime.toastQueue or {}
    if self.runtime.currentToast == def.id then return end

    local index
    for index=1,table.getn(self.runtime.toastQueue) do
        if self.runtime.toastQueue[index].id == def.id then return end
    end
    table.insert(self.runtime.toastQueue, def)
    self:ShowNextToast()
end

function VA:DismissToast()
    self.runtime.toastHideAt = nil
    self.runtime.currentToast = nil
    if self.ui and self.ui.toast then self.ui.toast:Hide() end
    self:ShowNextToast()
end

function VA:QueueCompletedAchievementToasts()
    if VA_DB.settings.popups == false then return end
    local completed = {}
    local index, def
    for index=1,table.getn(self.catalog) do
        def = self.catalog[index]
        if self:IsComplete(def.id) then table.insert(completed, def) end
    end
    table.sort(completed, function(left, right)
        local leftAt = VA:GetCompletedAt(left.id) or 0
        local rightAt = VA:GetCompletedAt(right.id) or 0
        if leftAt ~= rightAt then return leftAt < rightAt end
        return tostring(left.name) < tostring(right.name)
    end)
    for index=1,table.getn(completed) do self:ShowToast(completed[index]) end
end

function VA:ToggleUI()
    if not self.ui or not self.ui.frame then self:InstallUI() end
    if self.ui.frame:IsVisible() then self.ui.frame:Hide()
    else self.ui.frame:Show() self:RefreshUI() end
end

function VA:InstallUI()
    if self.ui and self.ui.frame then return end
    self.ui = self.ui or {}
    local ui = self.ui

    local frame = CreateFrame("Frame", "VanillaAchievementsFrame", UIParent)
    frame:SetWidth(720)
    frame:SetHeight(520)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:SetBackdrop({
        bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true, tileSize=32, edgeSize=32,
        insets={left=10,right=10,top=10,bottom=10},
    })
    frame:Hide()
    ui.frame = frame
    if UISpecialFrames then table.insert(UISpecialFrames, "VanillaAchievementsFrame") end

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -22)
    title:SetText("Vanilla Achievements")
    title:SetTextColor(1,0.82,0.35)
    ui.count = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.count:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -48, -25)

    local search = CreateFrame("EditBox", "VanillaAchievementsSearchBox", frame)
    search:SetWidth(300)
    search:SetHeight(22)
    search:SetPoint("TOPLEFT", frame, "TOPLEFT", 164, -30)
    search:SetAutoFocus(false)
    search:SetFontObject("GameFontNormalSmall")
    search:SetTextInsets(8, 8, 0, 0)
    search:SetBackdrop({
        bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=9,
        insets={left=2,right=2,top=2,bottom=2},
    })
    search:SetBackdropColor(0.03,0.025,0.02,0.96)
    search:SetBackdropBorderColor(0.45,0.36,0.20,1)
    ui.search = search
    search:SetText(VA_DB.settings.search or "")
    search:SetScript("OnTextChanged", function()
        VA_DB.settings.search = tostring(this:GetText() or "")
        VA.ui.offset = 0
        VA:RefreshUI()
    end)
    search:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    search:SetScript("OnEscapePressed", function() this:SetText("") this:ClearFocus() end)

    local close = MakeButton(frame, "x", 24, 24)
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -18)
    close:SetScript("OnClick", function() VA.ui.frame:Hide() end)

    ui.categoryButtons = {}
    local index, info, button
    for index=1,table.getn(self.categories) do
        info = self.categories[index]
        button = MakeButton(frame, info.label, 130, 25)
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -58 - ((index-1)*29))
        button.category = info.key
        button:SetScript("OnClick", function()
            VA_DB.settings.category = this.category
            VA.ui.offset = 0
            VA:RefreshUI()
        end)
        ui.categoryButtons[info.key] = button
    end

    button = MakeButton(frame, "Settings", 130, 25)
    button:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -319)
    button.category = "SETTINGS"
    button:SetScript("OnClick", function()
        VA_DB.settings.category = "SETTINGS"
        VA.ui.offset = 0
        VA:RefreshUI()
    end)
    ui.categoryButtons.SETTINGS = button

    local settingsPanel = CreateFrame("Frame", nil, frame)
    settingsPanel:SetWidth(510)
    settingsPanel:SetHeight(410)
    settingsPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 164, -88)
    settingsPanel:SetBackdrop({
        bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=16, edgeSize=9,
        insets={left=2,right=2,top=2,bottom=2},
    })
    settingsPanel:SetBackdropColor(0.025,0.023,0.020,0.96)
    settingsPanel:SetBackdropBorderColor(0.35,0.29,0.18,1)
    ui.settingsPanel = settingsPanel

    local settingsTitle = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    settingsTitle:SetPoint("TOP", settingsPanel, "TOP", 0, -24)
    settingsTitle:SetText("Achievement Settings")
    settingsTitle:SetTextColor(1,0.82,0.35)

    ui.settingButtons = {}
    local settingRows = {
        {"popups","Popups"},
        {"sounds","Sounds"},
        {"announceEmote","Nearby /me"},
        {"announceParty","Party"},
        {"announceGuild","Guild"},
        {"cheerOnUnlock","Cheer"},
        {"chatMessages","Local chat"},
    }
    local settingRow
    for index=1,table.getn(settingRows) do
        settingRow = settingRows[index]
        button = MakeButton(settingsPanel, "", 210, 30)
        -- Avoid the newer modulo operator; Vanilla 1.12 uses an older Lua.
        local zeroBased = index - 1
        local column = zeroBased - math.floor(zeroBased / 2) * 2
        local row = math.floor((index-1) / 2)
        button:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 34 + (column * 240), -70 - (row * 42))
        button.settingKey = settingRow[1]
        button.settingLabel = settingRow[2]
        button:SetScript("OnClick", function()
            VA_DB.settings[this.settingKey] = not VA_DB.settings[this.settingKey]
            VA:RefreshUI()
        end)
        ui.settingButtons[settingRow[1]] = button
    end

    ui.filterButtons = {}
    local filters = {{"ALL","All"},{"COMPLETE","Completed"},{"LOCKED","Locked"}}
    for index=1,table.getn(filters) do
        button = MakeButton(frame, filters[index][2], 95, 24)
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 164 + ((index-1)*101), -58)
        button.filter = filters[index][1]
        button:SetScript("OnClick", function()
            VA_DB.settings.filter = this.filter
            VA.ui.offset = 0
            VA:RefreshUI()
        end)
        ui.filterButtons[filters[index][1]] = button
    end

    ui.rows = {}
    for index=1,7 do
        local row = CreateFrame("Button", nil, frame)
        row:SetWidth(510)
        row:SetHeight(49)
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 164, -91 - ((index-1)*53))
        row:EnableMouseWheel(true)
        row:SetScript("OnMouseWheel", function() VA:ScrollAchievements(arg1) end)
        row:SetBackdrop({
            bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
            tile=true, tileSize=16, edgeSize=9,
            insets={left=2,right=2,top=2,bottom=2},
        })
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", 52, -7)
        row.name:SetWidth(260)
        row.name:SetJustifyH("LEFT")
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetWidth(40)
        row.icon:SetHeight(40)
        row.icon:SetPoint("LEFT", row, "LEFT", 7, 0)
        row.description = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.description:SetPoint("TOPLEFT", row, "TOPLEFT", 52, -25)
        row.description:SetWidth(326)
        row.description:SetJustifyH("LEFT")
        row.description:SetTextColor(0.66,0.66,0.63)
        row.status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.status:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -8)
        row.status:SetWidth(130)
        row.status:SetJustifyH("RIGHT")
        row.date = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.date:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -8, 7)
        row.date:SetTextColor(0.62,0.62,0.60)
        row:SetScript("OnEnter", function()
            if not this.def then return end
            GameTooltip:SetOwner(this, "ANCHOR_CURSOR")
            GameTooltip:AddLine(this.def.name, 1,0.82,0.35)
            GameTooltip:AddLine(DisplayDescription(this.def, VA:IsComplete(this.def.id)), 1,1,1,true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        ui.rows[index] = row
    end

    ui.prev = MakeButton(frame, "< Previous", 90, 24)
    ui.prev:SetFrameLevel(10)
    ui.prev:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 164, 22)
    ui.prev:SetScript("OnClick", function()
        VA.ui.offset = math.max(0, math.floor((tonumber(VA.ui.offset) or 0) / 14) * 14 - 14)
        VA:RefreshUI()
    end)
    ui.page = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.page:SetPoint("BOTTOM", frame, "BOTTOM", 80, 29)
    local scrollTrack = CreateFrame("Frame", "VanillaAchievementsScrollBar", frame)
    scrollTrack:SetWidth(24)
    scrollTrack:SetHeight(371)
    scrollTrack:SetPoint("TOPLEFT", frame, "TOPLEFT", 682, -88)
    scrollTrack:SetFrameStrata("DIALOG")
    scrollTrack:SetFrameLevel(20)
    scrollTrack:EnableMouse(true)
    scrollTrack:EnableMouseWheel(true)
    scrollTrack:SetBackdrop({
        bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=8, edgeSize=7,
        insets={left=3,right=3,top=3,bottom=3},
    })
    scrollTrack:SetBackdropColor(0.14,0.09,0.025,1)
    scrollTrack:SetBackdropBorderColor(0.90,0.58,0.12,1)
    scrollTrack:SetScript("OnMouseDown", function()
        if arg1 ~= "LeftButton" then return end
        local cursorX, cursorY = GetCursorPosition()
        if cursorY then VA:ScrollAchievementsFromClick(this, cursorY) end
    end)
    scrollTrack:SetScript("OnMouseUp", function()
        this.dragging = nil
    end)
    scrollTrack:SetScript("OnHide", function()
        this.dragging = nil
    end)
    scrollTrack:SetScript("OnMouseWheel", function()
        VA:ScrollAchievements(arg1)
    end)
    scrollTrack:Show()
    ui.scrollBar = scrollTrack
    local scrollThumb = CreateFrame("Frame", "VanillaAchievementsScrollThumb", frame)
    scrollThumb:SetWidth(20)
    scrollThumb:SetHeight(48)
    scrollThumb:SetFrameStrata("DIALOG")
    scrollThumb:SetFrameLevel(21)
    scrollThumb:SetPoint("TOPLEFT", frame, "TOPLEFT", 684, -88)
    scrollThumb:EnableMouse(true)
    scrollThumb:EnableMouseWheel(true)
    scrollThumb:SetBackdrop({
        bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",
        tile=true, tileSize=8, edgeSize=7,
        insets={left=2,right=2,top=2,bottom=2},
    })
    scrollThumb:SetBackdropColor(0.78,0.46,0.08,1)
    scrollThumb:SetBackdropBorderColor(1,0.88,0.32,1)
    scrollThumb.scrollBar = scrollTrack
    scrollThumb:SetScript("OnMouseDown", function()
        if arg1 ~= "LeftButton" then return end
        local cursorX, cursorY = GetCursorPosition()
        if cursorY then VA:BeginAchievementScrollDrag(this.scrollBar, cursorY) end
    end)
    scrollThumb:SetScript("OnMouseUp", function()
        if this.scrollBar then this.scrollBar.dragging = nil end
    end)
    scrollThumb:SetScript("OnHide", function()
        if this.scrollBar then this.scrollBar.dragging = nil end
    end)
    scrollThumb:SetScript("OnMouseWheel", function()
        VA:ScrollAchievements(arg1)
    end)
    scrollThumb:SetScript("OnUpdate", function()
        if not this.scrollBar or not this.scrollBar.dragging then return end
        if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
            this.scrollBar.dragging = nil
            return
        end
        local cursorX, cursorY = GetCursorPosition()
        if cursorY then VA:ScrollAchievementsFromDrag(this.scrollBar, cursorY) end
    end)
    scrollThumb:Show()
    ui.scrollThumb = scrollThumb

    local function MakeScrollArrow(label, direction, point, y)
        local button = MakeButton(frame, label, 24, 20)
        button:SetPoint(point, frame, point, 682, y)
        button:SetFrameLevel(22)
        button:SetScript("OnMouseDown", function()
            this.scrollDirection = direction
            -- One deterministic step per click; delayed repeats prevent a quick
            -- click from accidentally becoming two or three steps.
            this.scrollElapsed = -0.22
            VA:ScrollAchievements(direction)
        end)
        button:SetScript("OnMouseUp", function() this.scrollDirection = nil end)
        button:SetScript("OnHide", function() this.scrollDirection = nil end)
        button:SetScript("OnUpdate", function()
            if not this.scrollDirection then return end
            this.scrollElapsed = (this.scrollElapsed or 0) + (arg1 or 0)
            if this.scrollElapsed >= 0.10 then
                this.scrollElapsed = -0.02
                VA:ScrollAchievements(this.scrollDirection)
            end
        end)
        return button
    end
    ui.scrollUp = MakeScrollArrow("^", 1, "TOPLEFT", -66)
    ui.scrollDown = MakeScrollArrow("v", -1, "TOPLEFT", -459)
    ui.next = MakeButton(frame, "Next >", 90, 24)
    ui.next:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -26, 22)
    ui.next:SetScript("OnClick", function()
        VA.ui.offset = math.floor((tonumber(VA.ui.offset) or 0) / 14) * 14 + 14
        VA:RefreshUI()
    end)
    ui.pageSize = 14
    ui.offset = 0

    local toast = CreateFrame("Button", "VanillaAchievementsToast", UIParent)
    toast:SetWidth(410)
    toast:SetHeight(86)
    toast:SetPoint("TOP", UIParent, "TOP", 0, -70)
    toast:SetFrameStrata("DIALOG")
    toast:SetBackdrop({
        bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true, tileSize=16, edgeSize=18,
        insets={left=6,right=6,top=6,bottom=6},
    })
    toast:SetBackdropColor(0.02,0.015,0.01,0.98)
    toast:SetBackdropBorderColor(1,0.68,0.18,1)
    toast.icon = toast:CreateTexture(nil, "ARTWORK")
    toast.icon:SetWidth(62)
    toast.icon:SetHeight(62)
    toast.icon:SetPoint("LEFT", toast, "LEFT", 12, 0)
    toast.title = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toast.title:SetPoint("TOPLEFT", toast, "TOPLEFT", 80, -10)
    toast.title:SetWidth(315)
    toast.title:SetJustifyH("LEFT")
    toast.title:SetTextColor(1,0.68,0.18)
    toast.name = toast:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    toast.name:SetPoint("TOPLEFT", toast, "TOPLEFT", 80, -29)
    toast.name:SetWidth(315)
    toast.name:SetJustifyH("LEFT")
    toast.description = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toast.description:SetPoint("TOPLEFT", toast, "TOPLEFT", 80, -50)
    toast.description:SetWidth(315)
    toast.description:SetJustifyH("LEFT")
    toast.description:SetTextColor(0.75,0.75,0.72)
    toast:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    toast:SetScript("OnClick", function() VA:DismissToast() end)
    toast:Hide()
    ui.toast = toast

    local ticker = CreateFrame("Frame", "VanillaAchievementsTicker")
    ticker.elapsed = 0
    ticker:SetScript("OnUpdate", function()
        this.elapsed = (this.elapsed or 0) + (arg1 or 0)
        if this.elapsed < 0.25 then return end
        local updateElapsed = this.elapsed
        this.elapsed = 0
        VA:UpdateRealtimeTracking(updateElapsed)
        if VA.runtime.toastHideAt and VA:Now() >= VA.runtime.toastHideAt then
            VA:DismissToast()
        end
        VA:ProcessAchievementAnnouncements()
    end)

    SLASH_VANILLAACHIEVEMENTS1 = "/vach"
    SLASH_VANILLAACHIEVEMENTS2 = "/achievements"
    SLASH_VANILLAACHIEVEMENTS3 = "/va"
    SlashCmdList["VANILLAACHIEVEMENTS"] = function(message)
        message = string.lower(tostring(message or ""))
        if message == "rescan" then
            VA:CheckAllCurrentState(false)
            if RequestTimePlayed then pcall(RequestTimePlayed) end
            VA:Print("Current character state rescanned.")
        elseif message == "replay" then
            if VA_DB.settings.popups == false then
                VA:Print("Popups are disabled. Use /vach popups first.")
            else
                VA:QueueCompletedAchievementToasts()
                VA:Print("Completed achievement popups queued.")
            end
        elseif message == "popups" then
            VA_DB.settings.popups = not VA_DB.settings.popups
            VA:Print("Popups " .. (VA_DB.settings.popups and "enabled." or "disabled."))
        elseif message == "chat" then
            VA_DB.settings.chatMessages = not VA_DB.settings.chatMessages
            VA:Print("Chat messages " .. (VA_DB.settings.chatMessages and "enabled." or "disabled."))
        elseif message == "sound" or message == "sounds" then
            VA_DB.settings.sounds = not VA_DB.settings.sounds
            VA:Print("Achievement sounds " .. (VA_DB.settings.sounds and "enabled." or "disabled."))
            if VA_DB.settings.sounds then VA:PlayAchievementSound({category="GENERAL"}) end
        elseif message == "soundtest" then
            if VA_DB.settings.sounds == false then
                VA:Print("Achievement sounds are disabled. Use /vach sound first.")
            else
                VA:PlayAchievementSound({category="GENERAL"})
                VA:Print("Achievement sound test played.")
            end
        elseif message == "announce" then
            VA_DB.settings.announceEmote = not VA_DB.settings.announceEmote
            VA:Print("Nearby achievement announcements " .. (VA_DB.settings.announceEmote and "enabled." or "disabled."))
        elseif message == "social" then
            local enabled = not (VA_DB.settings.announceParty or VA_DB.settings.announceGuild)
            VA_DB.settings.announceParty = enabled
            VA_DB.settings.announceGuild = enabled
            VA:Print("Party and guild achievement announcements " .. (enabled and "enabled." or "disabled."))
        elseif message == "party" then
            VA_DB.settings.announceParty = not VA_DB.settings.announceParty
            VA:Print("Party achievement announcements " .. (VA_DB.settings.announceParty and "enabled." or "disabled."))
        elseif message == "guild" then
            VA_DB.settings.announceGuild = not VA_DB.settings.announceGuild
            VA:Print("Guild achievement announcements " .. (VA_DB.settings.announceGuild and "enabled." or "disabled."))
        elseif message == "cheer" then
            VA_DB.settings.cheerOnUnlock = not VA_DB.settings.cheerOnUnlock
            VA:Print("Physical cheer on unlock " .. (VA_DB.settings.cheerOnUnlock and "enabled." or "disabled."))
        elseif message == "debug" then
            VA_DB.settings.debug = not VA_DB.settings.debug
            VA:Print("Boss-name debug " .. (VA_DB.settings.debug and "enabled." or "disabled."))
        elseif message == "status" then
            VA:Print(tostring(VA:GetCompletedCount()) .. " / " .. tostring(table.getn(VA.catalog)) .. " achievements complete.")
        elseif message == "minimap" then
            VA_DB.settings.showMinimap = not VA_DB.settings.showMinimap
            if VA.ApplyMinimapVisibility then VA:ApplyMinimapVisibility() end
            VA:Print("Minimap button " .. (VA_DB.settings.showMinimap and "shown." or "hidden."))
        elseif message == "help" then
            VA:Print("/va or /vach - open the achievement browser")
            VA:Print("/vach rescan - rescan level, money, skills, gear, bags, and reputation")
            VA:Print("/vach replay - replay completed achievement popups")
            VA:Print("/vach popups - toggle unlock popups")
            VA:Print("/vach chat - toggle unlock chat messages")
            VA:Print("/vach sound - toggle achievement sounds")
            VA:Print("/vach soundtest - play the configured achievement sound")
            VA:Print("/vach announce - toggle nearby /me unlock announcements")
            VA:Print("/vach social - toggle party and guild unlock announcements")
            VA:Print("/vach cheer - toggle the physical cheer animation")
            VA:Print("/vach debug - show parsed hostile-death names for boss testing")
            VA:Print("/vach status - show completion count")
            VA:Print("/vach minimap - show or hide the minimap button")
        else
            VA:ToggleUI()
        end
    end

    self:RefreshUI()
    if self.InstallMinimapButton then self:InstallMinimapButton() end
end
