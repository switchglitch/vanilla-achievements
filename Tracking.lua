local VA = VanillaAchievements

local LEVEL_IDS = {
    {3,"LEVEL_03"},{5,"LEVEL_05"},{10,"LEVEL_10"},{20,"LEVEL_20"},{30,"LEVEL_30"},
    {40,"LEVEL_40"},{50,"LEVEL_50"},{59,"LEVEL_59"},{60,"LEVEL_60"},
}
local MONEY_IDS = {
    {50000,"MONEY_005"},{10000,"MONEY_001"},{100000,"MONEY_010"},{1000000,"MONEY_100"},
    {500000,"MONEY_050"},
    {5000000,"MONEY_500"},{10000000,"MONEY_1000"},
}
local SKILL_IDS = {
    {75,"SKILL_075"},{150,"SKILL_150"},{225,"SKILL_225"},{300,"SKILL_300"},
}
local META_IDS = {
    {10,"META_010"},{25,"META_025"},{50,"META_050"},{75,"META_075"},{100,"META_100"},
}
local PRIMARY_PROFESSIONS = {
    alchemy=true, blacksmithing=true, enchanting=true, engineering=true,
    herbalism=true, leatherworking=true, mining=true, skinning=true, tailoring=true,
}

local function CompleteThresholds(value, rows, silent)
    local index
    for index=1,table.getn(rows) do
        if value >= rows[index][1] then VA:Complete(rows[index][2], silent) end
    end
end

function VA:CheckLevel(level, silent)
    level = tonumber(level) or (UnitLevel and tonumber(UnitLevel("player"))) or 0
    self:SetCounter("level", level)
    CompleteThresholds(level, LEVEL_IDS, silent)
    if level >= 60 and UnitClass then
        local className, classToken = UnitClass("player")
        local id = self.class60AchievementIds and self.class60AchievementIds[string.upper(tostring(classToken or ""))]
        if id then self:Complete(id, silent) end
    end
end

function VA:CheckMoney(silent)
    local money = GetMoney and tonumber(GetMoney()) or 0
    self:SetCounter("money", money)
    CompleteThresholds(money, MONEY_IDS, silent)
end

function VA:VisitCurrentZone(silent)
    local zone = GetRealZoneText and GetRealZoneText() or (GetZoneText and GetZoneText()) or ""
    if zone == "" then return end
    if self:AddSetValue("zonesVisited", zone, 200) then
        local count = self:Count(self:GetSet("zonesVisited"))
        if count >= 5 then self:Complete("EXPLORE_05", silent) end
        if count >= 10 then self:Complete("EXPLORE_10", silent) end
        if count >= 25 then self:Complete("EXPLORE_25", silent) end
        if count >= 40 then self:Complete("EXPLORE_40", silent) end
        if count >= 50 then self:Complete("EXPLORE_50", silent) end
    end
end

function VA:RemoveRetiredZoneExploration()
    local db = self:EnsureDB()
    if db.dates.zoneExplorationRemoved then return end

    local id
    for id in pairs(db.completed) do
        if string.find(id, "^EXPLORE_ZONE_") or id == "EXPLORE_META_KALIMDOR"
            or id == "EXPLORE_META_EK" or id == "EXPLORE_META_AZEROTH" then
            db.completed[id] = nil
        end
    end
    for id in pairs(db.counters) do
        if string.find(id, "^explored_EXPLORE_ZONE_") or id == "exploredKalimdor"
            or id == "exploredEasternKingdoms" or id == "exploredAzeroth" then
            db.counters[id] = nil
        end
    end
    db.sets.fullyExploredZones = nil
    db.dates.zoneExplorationRemoved = true
    db.stats.completions = self:GetCompletedCount()
end

function VA:ScanSkills(silent)
    if not GetNumSkillLines or not GetSkillLineInfo then return end
    local total = tonumber(GetNumSkillLines()) or 0
    local best = 0
    local bestWeapon = 0
    local primaryAt300 = 0
    local cooking = 0
    local firstAid = 0
    local fishing = 0
    local index, name, isHeader, rank, key
    for index=1,total do
        name, isHeader, _, rank = GetSkillLineInfo(index)
        if name and not isHeader then
            rank = tonumber(rank) or 0
            key = string.lower(tostring(name))
            if string.find(key, "alchemy", 1, true) or string.find(key, "blacksmith", 1, true)
                or string.find(key, "enchant", 1, true) or string.find(key, "engineering", 1, true)
                or string.find(key, "herbalism", 1, true) or string.find(key, "leatherworking", 1, true)
                or string.find(key, "mining", 1, true) or string.find(key, "skinning", 1, true)
                or string.find(key, "tailoring", 1, true) or string.find(key, "cooking", 1, true)
                or string.find(key, "first aid", 1, true) or string.find(key, "fishing", 1, true) then
                if rank > best then best = rank end
                if string.find(key, "cooking", 1, true) then cooking = math.max(cooking, rank) end
                if string.find(key, "first aid", 1, true) then firstAid = math.max(firstAid, rank) end
                if string.find(key, "fishing", 1, true) then fishing = math.max(fishing, rank) end
                local primaryKey
                for primaryKey in pairs(PRIMARY_PROFESSIONS) do
                    if string.find(key, primaryKey, 1, true) and rank >= 300 then
                        primaryAt300 = primaryAt300 + 1
                        break
                    end
                end
            elseif string.find(key, "swords", 1, true) or string.find(key, "axes", 1, true)
                or string.find(key, "maces", 1, true) or string.find(key, "daggers", 1, true)
                or string.find(key, "staves", 1, true) or string.find(key, "bows", 1, true)
                or string.find(key, "guns", 1, true) or string.find(key, "crossbows", 1, true)
                or string.find(key, "polearms", 1, true) or string.find(key, "unarmed", 1, true)
                or string.find(key, "two-handed", 1, true) then
                if rank > bestWeapon then bestWeapon = rank end
            end
        end
    end
    self:SetCounter("bestProfession", best)
    self:SetCounter("bestWeaponSkill", bestWeapon)
    self:SetCounter("primaryProfessionsAt300", primaryAt300)
    self:SetCounter("cookingSkill", cooking)
    self:SetCounter("firstAidSkill", firstAid)
    self:SetCounter("fishingSkill", fishing)
    local secondaryAt300 = 0
    if cooking >= 300 then secondaryAt300 = secondaryAt300 + 1 end
    if firstAid >= 300 then secondaryAt300 = secondaryAt300 + 1 end
    if fishing >= 300 then secondaryAt300 = secondaryAt300 + 1 end
    self:SetCounter("secondaryAt300", secondaryAt300)
    CompleteThresholds(best, SKILL_IDS, silent)
    if primaryAt300 >= 2 then self:Complete("SKILL_TWO_300", silent) end
    if bestWeapon >= 100 then self:Complete("WEAPON_100", silent) end
    if bestWeapon >= 200 then self:Complete("WEAPON_200", silent) end
    if bestWeapon >= 300 then self:Complete("WEAPON_300", silent) end
    if cooking >= 300 then self:Complete("COOKING_300", silent) end
    if firstAid >= 300 then self:Complete("FIRSTAID_300", silent) end
    if fishing >= 300 then self:Complete("FISHING_300", silent) end
    if secondaryAt300 >= 3 then self:Complete("SECONDARY_ALL_300", silent) end
end

function VA:ScanReputation(silent)
    if not GetNumFactions or not GetFactionInfo then return end
    local total = tonumber(GetNumFactions()) or 0
    if total <= 0 then return end
    local best = 0
    local exalted = 0
    local db = self:EnsureDB()
    local index, name, standing, isHeader
    for index=1,total do
        name, _, standing, _, _, _, _, _, isHeader = GetFactionInfo(index)
        if name and not isHeader then
            if (tonumber(standing) or 0) > best then best = tonumber(standing) or 0 end
            if tonumber(standing) == 8 then exalted = exalted + 1 end
        end
    end
    self:SetCounter("bestReputationStanding", best)
    self:SetCounter("exaltedFactions", exalted)
    -- Vanilla standing IDs are Friendly=5, Honored=6, Revered=7, Exalted=8.
    -- Older releases used 5 for Honored, which could award this achievement at Friendly.
    -- Revoke that stale false positive when the current scan is still below Honored.
    if best < 6 and db.completed.REP_HONORED then
        db.completed.REP_HONORED = nil
        db.stats.completions = self:GetCompletedCount()
    end
    if best >= 6 then self:Complete("REP_HONORED", silent) end
    if best >= 7 then self:Complete("REP_REVERED", silent) end
    if best >= 8 then self:Complete("REP_EXALTED", silent) end
    if exalted >= 5 then self:Complete("REP_EXALTED_05", silent) end
    if exalted >= 10 then self:Complete("REP_EXALTED_10", silent) end
    if exalted >= 20 then self:Complete("REP_EXALTED_20", silent) end
end

function VA:ScanEquipment(silent)
    if not GetInventoryItemLink or not GetItemInfo then return end
    local best = 0
    local rareCount = 0
    local epicCount = 0
    local slot, link, quality
    for slot=1,18 do
        link = GetInventoryItemLink("player", slot)
        if link then
            local itemName, itemLink, itemQuality = GetItemInfo(link)
            quality = tonumber(itemQuality) or 0
            if quality > best then best = quality end
            if quality >= 3 then rareCount = rareCount + 1 end
            if quality >= 4 then epicCount = epicCount + 1 end
        end
    end
    self:SetCounter("bestEquippedQuality", best)
    self:SetCounter("rareEquippedCount", rareCount)
    self:SetCounter("epicEquippedCount", epicCount)
    if best >= 4 then self:Complete("GEAR_EPIC", silent) end
    if rareCount >= 10 then self:Complete("GEAR_RARE_10", silent) end
    if epicCount >= 5 then self:Complete("GEAR_EPIC_05", silent) end
    if epicCount >= 10 then self:Complete("GEAR_EPIC_10", silent) end
end

function VA:ScanBags(silent)
    if not GetContainerNumSlots or not GetContainerItemLink then return end
    local total = 0
    local free = 0
    local bag, slot, slots
    for bag=0,4 do
        slots = tonumber(GetContainerNumSlots(bag)) or 0
        total = total + slots
        for slot=1,slots do if not GetContainerItemLink(bag, slot) then free = free + 1 end end
    end
    self:SetCounter("freeBagSlots", free)
    if total > 0 and free == 0 then
        self:SetCounter("bagsFull", 1)
        self:Complete("BAGS_FULL", silent)
    end
end

local function DeathName(message)
    message = tostring(message or "")
    local formats = {
        getglobal and getglobal("UNITDIESOTHER") or nil,
        getglobal and getglobal("UNITDIESOTHER2") or nil,
    }
    local index, formatText, pattern
    for index=1,table.getn(formats) do
        formatText = formats[index]
        if type(formatText) == "string" and string.find(formatText, "%s", 1, true) then
            pattern = string.gsub(formatText, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
            pattern = string.gsub(pattern, "%%%%s", "(.+)")
            local _, _, name = string.find(message, "^" .. pattern .. "$")
            if name and name ~= "" then return name end
        end
    end
    -- Combat text may append an experience/reward clause after "dies".
    local _, _, fallback = string.find(message, "^(.+) dies")
    if not fallback then _, _, fallback = string.find(message, "^You have slain (.+)") end
    if not fallback then _, _, fallback = string.find(message, "^You have killed (.+)") end
    if not fallback then _, _, fallback = string.find(message, "^(.+) is slain") end
    if not fallback then _, _, fallback = string.find(message, "^(.+) has been slain") end
    if not fallback then _, _, fallback = string.find(message, "^(.+) has died") end
    if not fallback then _, _, fallback = string.find(message, "^(.+) was slain") end
    if not fallback then _, _, fallback = string.find(message, "^(.+) was defeated") end
    if not fallback then _, _, fallback = string.find(message, "^(.+) has been defeated") end
    if not fallback then _, _, fallback = string.find(message, "^(.+) is defeated") end
    if not fallback then _, _, fallback = string.find(message, "^(.+) has been destroyed") end
    if not fallback then _, _, fallback = string.find(message, "^(.+) is destroyed") end
    if not fallback then _, _, fallback = string.find(message, "^(.+) falls") end
    if not fallback then _, _, fallback = string.find(message, "^(.+) has fallen") end
    if not fallback then _, _, fallback = string.find(message, "^(.+) collapses") end
    return fallback
end

local function IsBossDeathText(message)
    local lower = string.lower(tostring(message or ""))
    local cues = {
        " dies",
        "you have slain ",
        "you have killed ",
        " is slain",
        " has been slain",
        " has died",
        " was slain",
        " was defeated",
        " has been defeated",
        " is defeated",
        " has been destroyed",
        " is destroyed",
        " falls",
        " has fallen",
        " collapses",
    }
    local index
    for index=1,table.getn(cues) do
        if string.find(lower, cues[index], 1, true) then return true end
    end
    return false
end

local function UnitIsAlive(unit)
    if not unit then return false end
    if UnitExists and not UnitExists(unit) then return false end
    local health = tonumber(UnitHealth and UnitHealth(unit) or 0) or 0
    local maxHealth = tonumber(UnitHealthMax and UnitHealthMax(unit) or 0) or 0
    return health > 0 and maxHealth > 0
end

local function HasLivingFullParty()
    local partyMembers = tonumber(GetNumPartyMembers and GetNumPartyMembers() or 0) or 0
    if partyMembers < 4 then return false end
    return UnitIsAlive("player")
        and UnitIsAlive("party1")
        and UnitIsAlive("party2")
        and UnitIsAlive("party3")
        and UnitIsAlive("party4")
end

local function ResolveBossAchievement(self, message)
    local name = DeathName(message)
    local id = name and self.bossAchievements[self:Normalize(name)] or nil
    if id then return name, id end
    if name then
        local normalizedName = self:Normalize(name)
        local alias, bossId
        -- Some realms report only the boss surname (for example, "Arugal").
        -- Match that meaningful name against the full catalog alias too.
        if string.len(normalizedName) >= 4 then
            for alias, bossId in pairs(self.bossAchievements) do
                if type(alias) == "string"
                    and string.find(alias, normalizedName, 1, true) then
                    return name, bossId
                end
            end
        end
    end
    if not name and not IsBossDeathText(message) then return nil, nil end

    local normalizedMessage = self:Normalize(message)
    local bestAlias, bestId
    local alias, bossId
    for alias, bossId in pairs(self.bossAchievements) do
        if type(alias) == "string" and alias ~= "" and string.find(normalizedMessage, alias, 1, true) then
            if not bestAlias or string.len(alias) > string.len(bestAlias) then
                bestAlias = alias
                bestId = bossId
            end
        end
    end
    if bestId then return bestAlias, bestId end
    return nil, nil
end

local function MaybeCompleteDungeonPartyBonus(self, def, silent)
    if not def or def.tag ~= "DUNGEON" then return end
    if HasLivingFullParty() then self:Complete("DUN_FULL_PARTY", silent) end
end

function VA:HandleBossDeath(message)
    local name, id = ResolveBossAchievement(self, message)
    if not name then return false end
    if VA_DB and VA_DB.settings and VA_DB.settings.debug then
        self:Print("Combat death detected: " .. tostring(name))
    end
    if not id then return false end

    self.runtime = self.runtime or {}
    self.runtime.recentBosses = self.runtime.recentBosses or {}
    local now = self:Now()
    local last = tonumber(self.runtime.recentBosses[id]) or 0
    if now - last < 120 then return false end
    self.runtime.recentBosses[id] = now

    local def = self.byId[id]
    if def and def.tag == "DUNGEON" then self:AddSetValue("dungeonClears", id, 100)
    elseif def and def.tag == "RAID" then self:AddSetValue("raidClears", id, 50)
    elseif def and def.tag == "WORLD" then self:AddSetValue("worldBosses", id, 50) end
    self:Complete(id, false)
    MaybeCompleteDungeonPartyBonus(self, def, false)
    self:EvaluateInstanceMetas(false)
    return true
end

function VA:EvaluateInstanceMetas(silent)
    local dungeons = self:Count(self:GetSet("dungeonClears"))
    local raids = self:Count(self:GetSet("raidClears"))
    local world = self:Count(self:GetSet("worldBosses"))
    if dungeons >= 5 then self:Complete("DUN_META_05", silent) end
    if dungeons >= 10 then self:Complete("DUN_META_10", silent) end
    if dungeons >= (tonumber(self.totalDungeonAchievements) or 999) then self:Complete("DUN_META_ALL", silent) end
    if raids >= 3 then self:Complete("RAID_META_03", silent) end
    if raids >= (tonumber(self.totalRaidAchievements) or 999) then self:Complete("RAID_META_ALL", silent) end
    if world >= (tonumber(self.totalWorldBossAchievements) or 999) then self:Complete("WORLD_META_ALL", silent) end
    if dungeons >= (tonumber(self.totalDungeonAchievements) or 999)
        and raids >= (tonumber(self.totalRaidAchievements) or 999) then
        self:SetCounter("pveChronicle", 1)
        self:Complete("META_PVE_ALL", silent)
    end
end

function VA:EvaluateMetaAchievements(silent)
    local count = self:GetCompletedCount()
    CompleteThresholds(count, META_IDS, silent)
    -- This meta excludes itself: it completes once every other catalog entry is complete.
    if count >= (table.getn(self.catalog) - 1) then
        self:Complete("META_SWORD_1000", silent)
    end
end

local function ExtractItemLink(message)
    message = tostring(message or "")
    local startAt = string.find(message, "|Hitem:", 1, true)
    if not startAt then return nil end
    local firstEnd = string.find(message, "|h", startAt, true)
    if not firstEnd then return nil end
    local secondEnd = string.find(message, "|h", firstEnd + 2, true)
    if not secondEnd then return nil end
    return string.sub(message, startAt, secondEnd + 1)
end

function VA:HandleLoot(message)
    if not self:IsSelfLootMessage(message) then return end
    local link = ExtractItemLink(message)
    if not link or not GetItemInfo then return end
    local name, fullLink, quality = GetItemInfo(link)
    quality = tonumber(quality) or 0
    local previous = tonumber(self:EnsureDB().counters.bestLootQuality) or 0
    if quality > previous then self:SetCounter("bestLootQuality", quality) end
    if quality >= 2 then self:Complete("LOOT_UNCOMMON", false) end
    if quality >= 3 then self:Complete("LOOT_RARE", false) end
    if quality >= 4 then self:Complete("LOOT_EPIC", false) end
    if quality >= 5 then self:Complete("LOOT_LEGENDARY", false) end
end

function VA:IsSelfLootMessage(message)
    message = tostring(message or "")
    local formats = {
        getglobal and getglobal("LOOT_ITEM_SELF") or nil,
        getglobal and getglobal("LOOT_ITEM_SELF_MULTIPLE") or nil,
        getglobal and getglobal("LOOT_ITEM_CREATED_SELF") or nil,
        getglobal and getglobal("LOOT_ITEM_CREATED_SELF_MULTIPLE") or nil,
    }
    local index, formatText, pattern
    for index=1,table.getn(formats) do
        formatText = formats[index]
        if type(formatText) == "string" and formatText ~= "" then
            pattern = string.gsub(formatText, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
            pattern = string.gsub(pattern, "%%%%s", ".-")
            pattern = string.gsub(pattern, "%%%%d", "%%d+")
            if string.find(message, "^" .. pattern .. "$") then return true end
        end
    end
    local lower = string.lower(message)
    return string.find(lower, "you receive loot:", 1, true) == 1
        or string.find(lower, "you receive item:", 1, true) == 1
        or string.find(lower, "you receive:", 1, true) == 1
        or string.find(lower, "you loot ", 1, true) == 1
end

function VA:CheckPlayed(totalSeconds, silent)
    totalSeconds = tonumber(totalSeconds) or 0
    self:SetCounter("playedSeconds", totalSeconds)
    if totalSeconds >= 900 then self:Complete("PLAYED_15M", silent) end
    if totalSeconds >= 3600 then self:Complete("PLAYED_1H", silent) end
    if totalSeconds >= 86400 then self:Complete("PLAYED_24H", silent) end
    if totalSeconds >= 604800 then self:Complete("PLAYED_7D", silent) end
    if totalSeconds >= 2592000 then self:Complete("PLAYED_30D", silent) end
    if totalSeconds >= 5184000 then self:Complete("PLAYED_60D", silent) end
end

function VA:CheckAllCurrentState(silent)
    self:CheckLevel(nil, silent)
    self:CheckMoney(silent)
    self:VisitCurrentZone(silent)
    self:ScanSkills(silent)
    self:ScanReputation(silent)
    self:ScanEquipment(silent)
    self:ScanBags(silent)
    self:EvaluateInstanceMetas(silent)
    self:EvaluateMetaAchievements(silent)
end

function VA:UpdateRealtimeTracking(elapsed)
    elapsed = tonumber(elapsed) or 0
    if elapsed <= 0 then return end
    if elapsed > 10 then elapsed = 10 end
    self.runtime = self.runtime or {}
    self.runtime.lightScanElapsed = (tonumber(self.runtime.lightScanElapsed) or 0) + elapsed
    self.runtime.heavyScanElapsed = (tonumber(self.runtime.heavyScanElapsed) or 0) + elapsed
    self.runtime.playedElapsed = (tonumber(self.runtime.playedElapsed) or 0) + elapsed

    if self.runtime.lightScanElapsed >= 1 then
        self.runtime.lightScanElapsed = 0
        self:CheckLevel(nil, false)
        self:CheckMoney(false)
        self:VisitCurrentZone(false)

        if self.runtime.playedTrackingReady then
            local wholeSeconds = math.floor(self.runtime.playedElapsed)
            if wholeSeconds > 0 then
                self.runtime.playedElapsed = self.runtime.playedElapsed - wholeSeconds
                local played = (tonumber(self:EnsureDB().counters.playedSeconds) or 0) + wholeSeconds
                self:CheckPlayed(played, false)
            end
        end
    end

    if self.runtime.heavyScanElapsed >= 3 then
        self.runtime.heavyScanElapsed = 0
        self:ScanSkills(false)
        self:ScanReputation(false)
        self:ScanEquipment(false)
        self:ScanBags(false)
        self:EvaluateInstanceMetas(false)
        self:EvaluateMetaAchievements(false)
    end

end

VA.runtime = VA.runtime or {}
local eventFrame = CreateFrame("Frame", "VanillaAchievementsEventFrame")
local events = {
    "PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_LEVEL_UP","PLAYER_MONEY",
    "ZONE_CHANGED_NEW_AREA","MINIMAP_ZONE_CHANGED","SKILL_LINES_CHANGED","UPDATE_FACTION",
    "PLAYER_EQUIPMENT_CHANGED","UNIT_INVENTORY_CHANGED","BAG_UPDATE","CHAT_MSG_COMBAT_HOSTILE_DEATH",
    "CHAT_MSG_MONSTER_SAY","CHAT_MSG_MONSTER_YELL","CHAT_MSG_MONSTER_EMOTE",
    "CHAT_MSG_LOOT","PLAYER_DEAD","CHAT_MSG_SYSTEM","CHAT_MSG_COMBAT_SELF_HITS",
    "CHAT_MSG_SPELL_SELF_DAMAGE","TIME_PLAYED_MSG","PLAYER_XP_UPDATE","UNIT_LEVEL",
    "PLAYER_ALIVE","PLAYER_UNGHOST","CHARACTER_POINTS_CHANGED",
}
local eventIndex
for eventIndex=1,table.getn(events) do pcall(eventFrame.RegisterEvent, eventFrame, events[eventIndex]) end

eventFrame:SetScript("OnEvent", function()
    if event == "PLAYER_LOGIN" then
        local db = VA:EnsureDB()
        local firstLogin = not db.dates.baselineComplete
        if VA.InstallUI then VA:InstallUI() end
        VA:RemoveRetiredZoneExploration()
        -- Catch up a brand-new character once. Later versions only refresh
        -- state silently and never replay the completed-achievement history.
        VA:CheckAllCurrentState(true)
        db.dates.baselineComplete = true
        if firstLogin and VA.QueueCompletedAchievementToasts then
            VA:QueueCompletedAchievementToasts()
        end
        VA.runtime.suppressNextTimePlayedAnnouncement = nil
        VA.runtime.playedTrackingReady = true
        VA.runtime.playedElapsed = 0
        if RequestTimePlayed then pcall(RequestTimePlayed) end
    elseif event == "PLAYER_ENTERING_WORLD" then
        VA:CheckAllCurrentState(false)
    elseif event == "PLAYER_LEVEL_UP" then
        VA:CheckLevel(arg1, false)
    elseif event == "PLAYER_XP_UPDATE" or (event == "UNIT_LEVEL" and (not arg1 or arg1 == "player")) then
        VA:CheckLevel(nil, false)
    elseif event == "PLAYER_MONEY" then
        VA:CheckMoney(false)
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "MINIMAP_ZONE_CHANGED" then
        VA:VisitCurrentZone(false)
    elseif event == "SKILL_LINES_CHANGED" or event == "CHARACTER_POINTS_CHANGED" then
        VA:ScanSkills(false)
    elseif event == "UPDATE_FACTION" then
        VA:ScanReputation(false)
    elseif event == "PLAYER_EQUIPMENT_CHANGED"
        or (event == "UNIT_INVENTORY_CHANGED" and (not arg1 or arg1 == "player")) then
        VA:ScanEquipment(false)
    elseif event == "BAG_UPDATE" then
        VA:ScanBags(false)
    elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" or event == "CHAT_MSG_MONSTER_SAY"
        or event == "CHAT_MSG_MONSTER_YELL" or event == "CHAT_MSG_MONSTER_EMOTE" then
        VA:HandleBossDeath(arg1)
    elseif event == "CHAT_MSG_LOOT" then
        VA:HandleLoot(arg1)
    elseif event == "PLAYER_DEAD" then
        local deaths = VA:AddCounter("deaths", 1)
        VA:Complete("DEATH_01", false)
        if deaths >= 3 then VA:Complete("DEATH_03", false) end
        if deaths >= 10 then VA:Complete("DEATH_10", false) end
        if deaths >= 100 then VA:Complete("DEATH_100", false) end
        if VA.runtime.fallDamageAt and VA:Now() - VA.runtime.fallDamageAt <= 4 then
            VA:SetCounter("fallDeath", 1)
            VA:Complete("DEATH_FALL", false)
        end
        VA.runtime.fallDamageAt = nil
    elseif event == "CHAT_MSG_SYSTEM" or event == "CHAT_MSG_COMBAT_SELF_HITS" or event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        local text = string.lower(tostring(arg1 or ""))
        if string.find(text, "fall", 1, true) then VA.runtime.fallDamageAt = VA:Now() end
    elseif event == "TIME_PLAYED_MSG" then
        VA.runtime.suppressAchievementAnnouncement = VA.runtime.suppressNextTimePlayedAnnouncement
        VA.runtime.suppressNextTimePlayedAnnouncement = nil
        VA:CheckPlayed(arg1, false)
        VA.runtime.playedTrackingReady = true
        VA.runtime.playedElapsed = 0
        VA.runtime.suppressAchievementAnnouncement = nil
    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        VA:CheckAllCurrentState(false)
    end
end)
