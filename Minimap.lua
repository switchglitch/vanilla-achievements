local VA = VanillaAchievements

local FREE_POSITION_VERSION = 1

local function Clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

function VA:EnsureLauncherPosition()
    self:EnsureDB()
    local settings = VA_DB.settings
    if tonumber(settings.launcherPositionVersion) == FREE_POSITION_VERSION
        and tonumber(settings.launcherX) and tonumber(settings.launcherY) then
        return
    end

    local uiX, uiY, mapX, mapY
    if UIParent then uiX, uiY = UIParent:GetCenter() end
    if Minimap then mapX, mapY = Minimap:GetCenter() end
    if uiX and uiY and mapX and mapY then
        settings.launcherX = (mapX - uiX) + (tonumber(settings.minimapX) or -78)
        settings.launcherY = (mapY - uiY) + (tonumber(settings.minimapY) or -78)
    else
        local width = UIParent and tonumber(UIParent:GetWidth()) or 1024
        local height = UIParent and tonumber(UIParent:GetHeight()) or 768
        settings.launcherX = (width / 2) - 105
        settings.launcherY = (height / 2) - 105
    end
    settings.launcherPositionVersion = FREE_POSITION_VERSION
end

function VA:PositionMinimapButton()
    if not self.ui or not self.ui.minimapButton or not UIParent then return end
    self:EnsureLauncherPosition()

    local width = tonumber(UIParent:GetWidth()) or 1024
    local height = tonumber(UIParent:GetHeight()) or 768
    -- Keep the launcher inside the visible screen, but do not add an extra inset.
    local edge = 0
    local x = Clamp(tonumber(VA_DB.settings.launcherX) or 0, (-width/2)+edge, (width/2)-edge)
    local y = Clamp(tonumber(VA_DB.settings.launcherY) or 0, (-height/2)+edge, (height/2)-edge)
    VA_DB.settings.launcherX = x
    VA_DB.settings.launcherY = y

    self.ui.minimapButton:ClearAllPoints()
    self.ui.minimapButton:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

function VA:UpdateMinimapDragPosition()
    if not self.ui or not self.ui.minimapButton or not UIParent or not GetCursorPosition then return false end
    local cursorX, cursorY = GetCursorPosition()
    local uiX, uiY = UIParent:GetCenter()
    if not cursorX or not cursorY or not uiX or not uiY then return false end

    local scale = 1
    if UIParent.GetEffectiveScale then scale = tonumber(UIParent:GetEffectiveScale()) or 1 end
    if scale <= 0 then scale = 1 end
    VA_DB.settings.launcherX = (cursorX / scale) - uiX
    VA_DB.settings.launcherY = (cursorY / scale) - uiY
    VA_DB.settings.launcherPositionVersion = FREE_POSITION_VERSION
    self:PositionMinimapButton()
    return true
end

function VA:ApplyMinimapVisibility()
    if not self.ui or not self.ui.minimapButton then return end
    self:EnsureDB()
    if VA_DB.settings.showMinimap then self.ui.minimapButton:Show()
    else self.ui.minimapButton:Hide() end
end

function VA:InstallMinimapButton()
    if not UIParent then return end
    self.ui = self.ui or {}
    if self.ui.minimapButton then return end
    self:EnsureDB()

    local button = CreateFrame("Button", "VanillaAchievementsMinimapButton", UIParent)
    button:SetWidth(30)
    button:SetHeight(30)
    button:SetFrameStrata("HIGH")
    button:SetFrameLevel(10)
    button:SetMovable(true)
    button:SetClampedToScreen(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\VanillaAchievements\\Assets\\Icons\\VA_BADGE")
    icon:SetAllPoints(button)
    button.icon = icon

    button:SetScript("OnClick", function()
        if arg1 == "RightButton" then
            VA:CheckAllCurrentState(false)
            if RequestTimePlayed then pcall(RequestTimePlayed) end
            VA:Print("Current character state rescanned.")
        else
            VA:ToggleUI()
        end
    end)

    button:SetScript("OnDragStart", function()
        if not IsShiftKeyDown or IsShiftKeyDown() then
            this.dragging = true
            VA:UpdateMinimapDragPosition()
        end
    end)

    button:SetScript("OnUpdate", function()
        if this.dragging then VA:UpdateMinimapDragPosition() end
    end)

    button:SetScript("OnDragStop", function()
        if not this.dragging then return end
        VA:UpdateMinimapDragPosition()
        this.dragging = nil
        VA:PositionMinimapButton()
    end)

    button:SetScript("OnEnter", function()
        this.icon:SetVertexColor(1,0.82,0.35)
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:AddLine("Vanilla Achievements", 1,0.82,0.35)
        GameTooltip:AddLine(tostring(VA:GetCompletedCount()) .. " / " .. tostring(table.getn(VA.catalog)) .. " complete", 0.35,1,0.42)
        GameTooltip:AddLine("Left-click: open achievements", 1,1,1)
        GameTooltip:AddLine("Right-click: rescan character", 1,1,1)
        GameTooltip:AddLine("Shift-drag: move anywhere", 0.65,0.65,0.65)
        GameTooltip:AddLine("/va also opens the browser", 0.52,0.72,1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        this.icon:SetVertexColor(1,1,1)
        GameTooltip:Hide()
    end)

    self.ui.minimapButton = button
    self:PositionMinimapButton()
    self:ApplyMinimapVisibility()
    self:UpdateMinimapBadge()
end

function VA:UpdateMinimapBadge()
    local button = self.ui and self.ui.minimapButton
    if button then button.completedCount = self:GetCompletedCount() end
end

local BaseCompleteMinimap = VA.Complete
function VA:Complete(id, silent)
    local changed = BaseCompleteMinimap(self, id, silent)
    if changed and self.UpdateMinimapBadge then self:UpdateMinimapBadge() end
    return changed
end
