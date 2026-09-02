-- Lightweight detectors for the expanded, single-character achievement set.
local VA = VanillaAchievements
VA.expSession = VA.expSession or { recentQuests={}, recentMurlocs={}, recentDeaths={}, dungeonSession={}, recentRoll=nil }
VA.expSession.recentDeaths = VA.expSession.recentDeaths or {}

local function db() return VA:EnsureDB() end
local function counter(key) return tonumber(db().counters[key]) or 0 end
local function add(key, amount) return VA:AddCounter(key, amount or 1) end
local function finish(id) if VA.byId[id] and not VA:IsComplete(id) then VA:Complete(id, false) end end
local function threshold(key, value, rows)
    for i=1,table.getn(rows) do if value >= rows[i][1] then finish(rows[i][2]) end end
end
local function setValue(key, value, maximum)
    return VA:AddSetValue(key, value, maximum)
end

local function damageAmount(text)
    local _, _, amount = string.find(tostring(text or ""), "(%d+)%s*damage")
    return tonumber(amount)
end

local QUEST_ROWS={{1,"QUEST_001"},{5,"QUEST_005"},{10,"QUEST_010"},{25,"QUEST_025"},{50,"QUEST_050"},{75,"QUEST_075"},{100,"QUEST_100"},{250,"QUEST_250"}}
local KILL_ROWS={{1,"KILL_001"},{10,"KILL_010"},{50,"KILL_050"},{100,"KILL_100"},{250,"KILL_250"},{500,"KILL_500"},{1000,"KILL_1000"}}
local MURLOC_ROWS={{10,"MURLOC_010"},{25,"MURLOC_025"},{50,"MURLOC_050"},{100,"MURLOC_100"}}
local LOVED_CRITTERS={"chicken","cat","cow","deer","fawn","rabbit","squirrel","sheep"}
local PESTS={"adder","larva","maggot","mouse","rat","roach","scorpion","spider","water snake"}

local function ExactName(name, names)
    local normalized=VA:Normalize(name)
    for i=1,table.getn(names) do
        if normalized==VA:Normalize(names[i]) then return names[i] end
    end
end

local function PrefixName(name, names)
    local normalized=VA:Normalize(name)
    local match
    for i=1,table.getn(names) do
        local candidate=VA:Normalize(names[i])
        if string.find(normalized,candidate,1,true)==1 and (not match or string.len(candidate)>string.len(VA:Normalize(match))) then
            match=names[i]
        end
    end
    return match
end

local function EvaluateMetaExtras()
    local secretCount, deathCount, ordinary = 0, 0, {}
    local categories={"LEVELING","DUNGEONS","RAIDS","EXPLORATION","PROFESSIONS","COLLECTION"}
    for i=1,table.getn(VA.catalog) do
        local def=VA.catalog[i]
        if def.secret and VA:IsComplete(def.id) then secretCount=secretCount+1 end
        if string.find(def.id,"^DEATH") or string.find(def.id,"^MURLOC_DEATH") or string.find(def.id,"^NAKED_DEATH") then
            if VA:IsComplete(def.id) then deathCount=deathCount+1 end
        end
    end
    VA:SetCounter("secretAchievements", secretCount)
    VA:SetCounter("deathAchievements", deathCount)
    for i=1,table.getn(categories) do
        for j=1,table.getn(VA.catalog) do
            if VA.catalog[j].category==categories[i] and VA:IsComplete(VA.catalog[j].id) then ordinary[categories[i]]=true end
        end
    end
    local all=true
    for i=1,table.getn(categories) do if not ordinary[categories[i]] then all=false end end
    if all then finish("META_EVERY_CATEGORY") end
    if secretCount>=5 then finish("META_SECRET_05") end
    if secretCount>=15 then finish("META_SECRET_15") end
    if deathCount>=5 then finish("META_DEATH_05") end
end

local function MurlocName(name)
    local n=string.lower(tostring(name or ""))
    local prefixes={"bluegill","greymist","grimscale","mirefin","murkshallow","saltspittle","vile fin"}
    if string.find(n,"murloc",1,true) then return true end
    for i=1,table.getn(prefixes) do if string.find(n,prefixes[i],1,true)==1 then return true end end
    return false
end

local function CurrentTargetName()
    if UnitName then return UnitName("target") end
end

local function HandleKill(message)
    message=string.lower(tostring(message or ""))
    if not string.find(message,"you have slain",1,true) then return end
    local name=string.gsub(message,"^.*you have slain%s+","" )
    name=string.gsub(name,"[%.!]$","")
    if name=="" then name=string.lower(tostring(CurrentTargetName() or "")) end
    local kills=add("kills")
    threshold("kills",kills,KILL_ROWS)
    add("killStreak")
    if counter("killStreak")>=25 then finish("KILL_STREAK_25") end
    if MurlocName(name) then
        local mk=add("murlocKills")
        threshold("murlocKills",mk,MURLOC_ROWS)
        setValue("murlocNames",name,100)
        if counter("murlocKills")>=5 then finish("MURLOC_NAMES") end
        local zone=GetRealZoneText and GetRealZoneText() or "unknown"
        setValue("murlocZones",zone,100)
        if VA:Count(VA:GetSet("murlocZones"))>=5 then finish("MURLOC_ZONES") end
        local now=VA:Now(); local times=VA.expSession.recentMurlocs
        table.insert(times,now)
        while table.getn(times)>0 and now-times[1]>30 do table.remove(times,1) end
        if table.getn(times)>=5 then finish("MURLOC_RUSH") end
        if VA.expSession.murlocKissName and VA.expSession.murlocKissName==name and now-VA.expSession.murlocKissAt<=30 then finish("MURLOC_KISS") end
        local murlocIds={"MURLOC_010","MURLOC_025","MURLOC_050","MURLOC_100","MURLOC_RUSH","MURLOC_ZONES","MURLOC_NAMES","MURLOC_DANCE","MURLOC_KISS","MURLOC_DEATH"}
        local allMurloc=true
        for mi=1,table.getn(murlocIds) do if not VA:IsComplete(murlocIds[mi]) then allMurloc=false end end
        if allMurloc then finish("MURLOC_META") end
    end
    if string.find(name,"hogger",1,true) then finish("BOSS_HOGGER") if VA:IsComplete("DEATH_HOGGER") then finish("HOGGER_REMATCH") end end
    if string.find(name,"mor'l\adim",1,true) or string.find(name,"morladim",1,true) then finish("BOSS_MORLADIM") end
    if string.find(name,"king bangalash",1,true) then finish("BOSS_BANGALASH") end
    if string.find(name,"bellygrub",1,true) then finish("BOSS_BELLYGRUB") end
    if string.find(name,"critter",1,true) then
        local ck=add("critterKills"); finish("CRITTER_001"); if ck>=25 then finish("CRITTER_025") end
    end
    local pest=PrefixName(name,PESTS)
    if pest then
        local pc=setValue("pestKills",pest,table.getn(PESTS))
        if pc and VA:Count(VA:GetSet("pestKills"))>=8 then finish("PEST_CONTROL_08") end
    end
    local damage=damageAmount(message)
    if damage and damage>counter("bestDamage") then VA:SetCounter("bestDamage",damage); if damage>=500 then finish("DAMAGE_500") end; if damage>=1000 then finish("DAMAGE_1000") end end
end

local function HandleCombatMessage(message)
    local text=string.lower(tostring(message or ""))
    if string.find(text,"critical",1,true) then local c=add("crits"); if c>=1 then finish("CRIT_001") end end
    local damage=damageAmount(text)
    if damage and damage>counter("bestDamage") then VA:SetCounter("bestDamage",damage); if damage>=500 then finish("DAMAGE_500") end; if damage>=1000 then finish("DAMAGE_1000") end end
end

local function ScanBagsAndSocial()
    local bag8,bag10,bag14,matching=0,0,0,0; local firstSlots=nil
    if GetContainerNumSlots then
        for bag=1,4 do
            local slots=tonumber(GetContainerNumSlots(bag)) or 0
            if slots>=8 then bag8=bag8+1 end; if slots>=10 then bag10=bag10+1 end; if slots>=14 then bag14=bag14+1 end
            if slots>0 then if not firstSlots then firstSlots=slots elseif firstSlots==slots then matching=matching+1 end end
        end
    end
    if bag8>0 then finish("BAG_08") end; if bag10>=4 then finish("BAG_10X4") end; if bag14>=4 then finish("BAG_14X4") end; if matching>=3 then finish("BAG_MATCHING") end
    if GetNumPartyMembers then local party=tonumber(GetNumPartyMembers()) or 0; if party>0 then finish("SOCIAL_PARTY") end; if party>=4 then finish("SOCIAL_FULL_PARTY") end end
    if GetNumRaidMembers and (tonumber(GetNumRaidMembers()) or 0)>0 then finish("SOCIAL_RAID") end
    if GetGuildInfo and GetGuildInfo("player") then finish("SOCIAL_GUILD") end
end

local function HandleEvent()
    -- QUEST_FINISHED is a UI-window event in the 1.12 client: it fires when
    -- the quest frame changes or closes, including ordinary browsing.  It is
    -- not proof that a quest was turned in.  QUEST_COMPLETE is the completion
    -- event emitted immediately before the reward is accepted, so use that
    -- signal for both the quest counter and the three-in-one-minute secret.
    if event=="QUEST_COMPLETE" then
        local q=add("quests"); threshold("quests",q,QUEST_ROWS)
        local now=VA:Now(); local times=VA.expSession.recentQuests; table.insert(times,now)
        while table.getn(times)>0 and now-times[1]>60 do table.remove(times,1) end
        if table.getn(times)>=3 then finish("QUEST_TRIPLE") end
    elseif event=="CHAT_MSG_COMBAT_HOSTILE_DEATH" then HandleKill(arg1)
    elseif event=="CHAT_MSG_COMBAT_SELF_HITS" or event=="CHAT_MSG_SPELL_SELF_DAMAGE" then HandleCombatMessage(arg1)
    elseif event=="CHAT_MSG_LOOT" then
        local loot=add("lootCount")
        if loot>=10 then finish("LOOT_010") end
        if loot>=25 then finish("LOOT_025") end
        local lootText=string.lower(tostring(arg1 or ""))
        if string.find(lootText,"poor",1,true) or string.find(lootText,"gray",1,true) then
            local gray=add("grayLoot")
            if gray>=5 then finish("LOOT_GRAY_005") end
        end
    elseif event=="PLAYER_DEAD" then
        VA:SetCounter("killStreak",0)
        local now=VA:Now(); local deaths=VA.expSession.recentDeaths
        table.insert(deaths,now)
        while table.getn(deaths)>0 and now-deaths[1]>300 do table.remove(deaths,1) end
        if table.getn(deaths)>=2 then finish("DEATH_DOUBLE") end
        if VA.expSession.murlocTarget then finish("MURLOC_DEATH") end
        if VA.expSession.hoggerTarget then finish("DEATH_HOGGER") end
    elseif event=="PLAYER_REGEN_DISABLED" then VA.expSession.inCombat=true
    elseif event=="PLAYER_REGEN_ENABLED" then
        VA.expSession.inCombat=nil
        local hp=UnitHealth and tonumber(UnitHealth("player")) or 0; local max=UnitHealthMax and tonumber(UnitHealthMax("player")) or 0
        if max>0 and hp>0 and hp/max<=0.05 then finish("SURVIVE_LOW") end
    elseif event=="BAG_UPDATE" or event=="UNIT_INVENTORY_CHANGED" or event=="PARTY_MEMBERS_CHANGED" or event=="RAID_ROSTER_UPDATE" or event=="GUILD_ROSTER_UPDATE" or event=="PLAYER_LOGIN" then
        ScanBagsAndSocial()
        if counter("bestEquippedQuality")>=3 then finish("GEAR_RARE") end
    elseif event=="ZONE_CHANGED_NEW_AREA" or event=="MINIMAP_ZONE_CHANGED" then
        local now=VA:Now(); local zone=GetRealZoneText and GetRealZoneText() or ""; local s=VA.expSession
        if zone~="" then
            if not s.forestRunStarted or now-s.forestRunStarted>1200 then s.forestRunStarted=now; s.forestRunZones={} end
            if not s.forestRunZones[zone] then
                s.forestRunZones[zone]=true
                if VA:Count(s.forestRunZones)>=5 then finish("EXPLORE_RUN_FOREST") end
            end
        end
    elseif event=="PLAYER_MONEY" then
        local money=tonumber(GetMoney and GetMoney() or 0) or 0
        if money==0 then finish("MONEY_ZERO") end
        if VA.expSession.merchantMoney then
            if VA.expSession.merchantMoney-money>=100000 then finish("MERCHANT_10G") end
            VA.expSession.merchantMoney=money
        end
    elseif event=="MAIL_SHOW" then VA.expSession.mailAt=VA:Now()
    elseif event=="AUCTION_HOUSE_SHOW" then VA.expSession.auctionAt=VA:Now()
    elseif event=="CHAT_MSG_TEXT_EMOTE" then
        local text=string.lower(tostring(arg1 or "")); local target=string.lower(tostring(CurrentTargetName() or "")); local now=VA:Now()
        if string.find(text,"dances",1,true) or string.find(text,"dance",1,true) then
            if VA.expSession.mailAt and now-VA.expSession.mailAt<=10 then finish("EMOTE_MAILBOX") end
            if VA.expSession.auctionAt and now-VA.expSession.auctionAt<=10 then finish("EMOTE_AUCTION") end
            if MurlocName(target) then finish("MURLOC_DANCE") end
        elseif string.find(text,"kisses",1,true) and MurlocName(target) then VA.expSession.murlocKissName=target; VA.expSession.murlocKissAt=now end
        if string.find(text,"love",1,true) then
            local critter=ExactName(target,LOVED_CRITTERS)
            if critter then
                setValue("lovedCritters",critter,table.getn(LOVED_CRITTERS))
                if VA:Count(VA:GetSet("lovedCritters"))>=8 then finish("CRITTER_LOVE_08") end
            end
        end
    elseif event=="MERCHANT_SHOW" then VA.expSession.merchantMoney=GetMoney and GetMoney() or 0
    end
end

local frame=CreateFrame("Frame","VanillaAchievementsExpansionEvents")
local eventNames={"PLAYER_LOGIN","QUEST_COMPLETE","CHAT_MSG_COMBAT_HOSTILE_DEATH","CHAT_MSG_COMBAT_SELF_HITS","CHAT_MSG_SPELL_SELF_DAMAGE","CHAT_MSG_LOOT","PLAYER_DEAD","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","BAG_UPDATE","UNIT_INVENTORY_CHANGED","PARTY_MEMBERS_CHANGED","RAID_ROSTER_UPDATE","GUILD_ROSTER_UPDATE","PLAYER_MONEY","MAIL_SHOW","AUCTION_HOUSE_SHOW","CHAT_MSG_TEXT_EMOTE","MERCHANT_SHOW","ZONE_CHANGED_NEW_AREA","MINIMAP_ZONE_CHANGED"}
for i=1,table.getn(eventNames) do pcall(frame.RegisterEvent,frame,eventNames[i]) end
frame:SetScript("OnEvent",HandleEvent)

local oldComplete=VA.Complete
VA.Complete=function(self,id,silent)
    local result=oldComplete(self,id,silent)
    if result then EvaluateMetaExtras() end
    return result
end
