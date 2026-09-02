-- Vanilla Achievements
-- Standalone achievement foundation for the 1.12.1 client.

VanillaAchievements = VanillaAchievements or {}
local VA = VanillaAchievements

VA.version = "0.8.9"
VA.schema = 1
VA.catalog = {}
VA.byId = {}
VA.categories = {
    { key="ALL", label="Overview" },
    { key="LEVELING", label="Leveling" },
    { key="DUNGEONS", label="Dungeons" },
    { key="RAIDS", label="Raids" },
    { key="EXPLORATION", label="Exploration" },
    { key="PROFESSIONS", label="Professions" },
    { key="COLLECTION", label="Collection" },
    { key="GENERAL", label="General" },
    { key="SECRETS", label="Secrets" },
}

local function Trim(text)
    text = tostring(text or "")
    return string.gsub(text, "^%s*(.-)%s*$", "%1")
end

function VA:Normalize(text)
    text = string.lower(Trim(text))
    text = string.gsub(text, "[%s%p%c]", "")
    return text
end

function VA:ShortName(name)
    return string.gsub(Trim(name), "%-.*$", "")
end

function VA:Now()
    if time then return time() end
    return 0
end

function VA:Count(tbl)
    local count = 0
    local key
    for key in pairs(tbl or {}) do count = count + 1 end
    return count
end

function VA:GetCharacterKey()
    local player = self:ShortName(UnitName and UnitName("player") or "Unknown")
    local realm = GetCVar and GetCVar("realmName") or "UnknownRealm"
    return string.lower(player) .. "@" .. string.lower(tostring(realm or "UnknownRealm"))
end

function VA:EnsureDB()
    if type(VA_DB) ~= "table" then VA_DB = {} end
    local previousVersion = tostring(VA_DB.version or "")
    VA_DB.schema = tonumber(VA_DB.schema) or self.schema
    VA_DB.version = self.version
    if type(VA_DB.characters) ~= "table" then VA_DB.characters = {} end
    if type(VA_DB.settings) ~= "table" then VA_DB.settings = {} end

    if VA_DB.settings.popups == nil then VA_DB.settings.popups = true end
    if VA_DB.settings.chatMessages == nil then VA_DB.settings.chatMessages = true end
    if VA_DB.settings.sounds == nil then VA_DB.settings.sounds = true end
    if VA_DB.settings.announceEmote == nil then VA_DB.settings.announceEmote = true end
    -- Party and guild announcements are separate controls.  Existing saves
    -- used announceGroup for both; preserve its party preference while making
    -- guild chat opt-in so a fresh install never broadcasts by surprise.
    if VA_DB.settings.announceParty == nil then
        VA_DB.settings.announceParty = VA_DB.settings.announceGroup ~= false
    end
    if VA_DB.settings.announceGuild == nil then VA_DB.settings.announceGuild = false end
    if VA_DB.settings.cheerOnUnlock == nil then VA_DB.settings.cheerOnUnlock = false end
    if VA_DB.settings.showMinimap == nil then VA_DB.settings.showMinimap = true end
    if tonumber(VA_DB.settings.minimapX) == nil then VA_DB.settings.minimapX = -78 end
    if tonumber(VA_DB.settings.minimapY) == nil then VA_DB.settings.minimapY = -78 end
    if not VA_DB.settings.category then VA_DB.settings.category = "ALL" end
    if not VA_DB.settings.filter then VA_DB.settings.filter = "ALL" end
    if VA_DB.settings.search == nil then VA_DB.settings.search = "" end

    local key = self:GetCharacterKey()
    if type(VA_DB.characters[key]) ~= "table" then VA_DB.characters[key] = {} end
    local db = VA_DB.characters[key]
    if type(db.completed) ~= "table" then db.completed = {} end
    if type(db.counters) ~= "table" then db.counters = {} end
    if type(db.sets) ~= "table" then db.sets = {} end
    if type(db.dates) ~= "table" then db.dates = {} end
    if type(db.stats) ~= "table" then db.stats = {} end
    -- QUEST_TRIPLE was driven by overly broad or repeated quest events in
    -- builds before 0.7.7 and in 0.8.8, so prior completions are not
    -- trustworthy. Clear that one record once when upgrading off those builds.
    if previousVersion ~= self.version
        and (previousVersion == "0.7.5" or previousVersion == "0.7.6" or previousVersion == "0.8.8") then
        db.completed.QUEST_TRIPLE = nil
    end
    return db
end

function VA:AddAchievement(def)
    if type(def) ~= "table" or not def.id or self.byId[def.id] then return false end
    def.required = tonumber(def.required) or 1
    table.insert(self.catalog, def)
    self.byId[def.id] = def
    return true
end

function VA:GetSet(key)
    local db = self:EnsureDB()
    if type(db.sets[key]) ~= "table" then db.sets[key] = {} end
    return db.sets[key]
end

function VA:AddSetValue(key, value, maximum)
    value = self:Normalize(value)
    if value == "" then return false end
    local set = self:GetSet(key)
    if set[value] then return false end
    if self:Count(set) >= (tonumber(maximum) or 1000) then return false end
    set[value] = true
    return true
end

function VA:SetCounter(key, value)
    local db = self:EnsureDB()
    value = tonumber(value) or 0
    if value < 0 then value = 0 end
    if value > 1000000000 then value = 1000000000 end
    db.counters[key] = value
    return value
end

function VA:AddCounter(key, amount)
    local db = self:EnsureDB()
    return self:SetCounter(key, (tonumber(db.counters[key]) or 0) + (tonumber(amount) or 0))
end

function VA:IsComplete(id)
    return self:EnsureDB().completed[id] ~= nil
end

function VA:GetCompletedAt(id)
    local record = self:EnsureDB().completed[id]
    if type(record) == "table" then return tonumber(record.at) end
    return tonumber(record)
end

function VA:GetCompletedCount()
    local count = 0
    local id
    for id in pairs(self:EnsureDB().completed) do
        if self.byId[id] then count = count + 1 end
    end
    return count
end

function VA:GetProgress(def)
    if not def then return 0, 1 end
    if self:IsComplete(def.id) then return def.required, def.required end
    local db = self:EnsureDB()
    local current = 0
    if def.progressType == "SET" then
        current = self:Count(self:GetSet(def.progress))
    elseif def.progressType == "LEVEL" then
        current = UnitLevel and tonumber(UnitLevel("player")) or 0
    elseif def.progressType == "MONEY" then
        current = GetMoney and tonumber(GetMoney()) or 0
    elseif def.progressType == "COMPLETED" then
        current = self:GetCompletedCount()
    else
        current = tonumber(db.counters[def.progress or ""]) or 0
    end
    if current > def.required then current = def.required end
    return current, def.required
end

function VA:Print(message)
    local text = "|cffffcc66Vanilla Achievements:|r " .. tostring(message or "")
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(text)
    end
end

function VA:PlayAchievementSound(def)
    if VA_DB.settings.sounds == false then return end
    local path = "Interface\\AddOns\\VanillaAchievements\\Assets\\Sounds\\anime-wow.mp3"
    if PlaySoundFile then
        local ok, played = pcall(PlaySoundFile, path)
        if (not ok or played == false) and PlaySound then pcall(PlaySound, "LevelUp") end
    elseif PlaySound then
        pcall(PlaySound, "LevelUp")
    end
end

function VA:ProcessAchievementAnnouncements()
    self.runtime = self.runtime or {}
    self.runtime.announcementQueue = self.runtime.announcementQueue or {}
    if table.getn(self.runtime.announcementQueue) == 0 then return end
    if self.runtime.announcementReadyAt and self:Now() < self.runtime.announcementReadyAt then return end

    local def = table.remove(self.runtime.announcementQueue, 1)
    if VA_DB.settings.cheerOnUnlock and DoEmote then pcall(DoEmote, "CHEER") end
    if VA_DB.settings.announceEmote and SendChatMessage then
        local name = tostring(def and def.name or "Achievement")
        name = string.gsub(name, "[\r\n]", " ")
        name = string.sub(name, 1, 100)
        pcall(SendChatMessage, " has unlocked achievement \"" .. name .. "\"", "EMOTE")
    end
    if (VA_DB.settings.announceParty or VA_DB.settings.announceGuild) and SendChatMessage then
        local name = tostring(def and def.name or "Achievement")
        name = string.gsub(name, "[\r\n]", " ")
        name = string.sub(name, 1, 100)
        local message = " has unlocked achievement \"" .. name .. "\""
        if VA_DB.settings.announceParty and GetNumPartyMembers and (tonumber(GetNumPartyMembers()) or 0) > 0 then
            pcall(SendChatMessage, message, "PARTY")
        end
        if VA_DB.settings.announceParty and GetNumRaidMembers and (tonumber(GetNumRaidMembers()) or 0) > 0 then
            pcall(SendChatMessage, message, "RAID")
        end
        if VA_DB.settings.announceGuild and IsInGuild and IsInGuild() then
            pcall(SendChatMessage, message, "GUILD")
        end
    end
    self.runtime.announcementReadyAt = self:Now() + 2
end

function VA:QueueAchievementAnnouncement(def)
    if not def then return end
    if VA_DB.settings.announceEmote == false and VA_DB.settings.announceParty == false
        and VA_DB.settings.announceGuild == false
        and VA_DB.settings.cheerOnUnlock == false then return end
    self.runtime = self.runtime or {}
    self.runtime.announcementQueue = self.runtime.announcementQueue or {}
    table.insert(self.runtime.announcementQueue, def)
    self:ProcessAchievementAnnouncements()
end

function VA:Complete(id, silent)
    local def = self.byId[id]
    local db = self:EnsureDB()
    if not def or db.completed[id] then return false end
    db.completed[id] = { at=self:Now() }
    db.stats.completions = (tonumber(db.stats.completions) or 0) + 1

    if not silent then
        if VA_DB.settings.chatMessages ~= false then
            self:Print("Achievement earned: |cffffffff[" .. tostring(def.name) .. "]|r")
        end
        if VA_DB.settings.popups ~= false and self.ShowToast then
            self:ShowToast(def)
        else
            self:PlayAchievementSound(def)
        end
        if not self.runtime.suppressAchievementAnnouncement then
            self:QueueAchievementAnnouncement(def)
        end
    end

    if not self.metaGuard then
        self.metaGuard = true
        if self.EvaluateMetaAchievements then self:EvaluateMetaAchievements(silent) end
        self.metaGuard = nil
    end
    if self.RefreshUI then self:RefreshUI() end
    return true
end

function VA:FormatProgress(def, current, required)
    if def.progressType == "MONEY" then
        return tostring(math.floor((tonumber(current) or 0) / 10000)) .. " / " ..
            tostring(math.floor((tonumber(required) or 0) / 10000)) .. "g"
    elseif def.unit == "hours" then
        return tostring(math.floor((tonumber(current) or 0) / 3600)) .. " / " ..
            tostring(math.floor((tonumber(required) or 0) / 3600)) .. "h"
    end
    return tostring(math.floor(tonumber(current) or 0)) .. " / " ..
        tostring(math.floor(tonumber(required) or 1))
end
