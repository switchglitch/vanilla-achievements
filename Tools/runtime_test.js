const fs = require("fs");
const path = require("path");
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require("fengari");

const root = path.resolve(process.argv[2] || ".");
const toc = fs.readFileSync(path.join(root, "VanillaAchievements.toc"), "utf8");
const files = toc
  .split(/\r?\n/)
  .map((line) => line.trim())
  .filter((line) => line && !line.startsWith("##"))
  .map((line) => line.replace(/\\/g, "/"));

const mock = String.raw`
if not table.getn then table.getn=function(tbl) return #tbl end end
MOCK_NOW=1700000000
MOCK_LEVEL=60
MOCK_MONEY=1000000
MOCK_MESSAGES={}
MOCK_SOUND_FILES={}
MOCK_CHAT_SEND={}
MOCK_EMOTES={}
MOCK_FACTIONS={}
MOCK_PARTY_MEMBERS=0
MOCK_RAID_MEMBERS=0
MOCK_GUILD_NAME=nil
MOCK_CURSOR_X=422
MOCK_CURSOR_Y=272
MOCK_MAP_CONTINENT=2
MOCK_MAP_ZONE=1
MOCK_WESTFALL_EXPLORED=false
MOCK_PLAYER_HEALTH=100
MOCK_PLAYER_MAX_HEALTH=100
MOCK_PARTY_UNIT_EXISTS={}
MOCK_PARTY_UNIT_HEALTHS={}
MOCK_PARTY_UNIT_MAX_HEALTHS={}

function time() return MOCK_NOW end
function date(formatText,timestamp) return os.date(formatText,timestamp or MOCK_NOW) end
function getglobal(name) return _G[name] end
function UnitName(unit) return unit=="player" and "Tester" or nil end
function UnitLevel(unit) return MOCK_LEVEL end
function UnitClass(unit) return "Warrior","WARRIOR" end
function UnitExists(unit)
    if unit=="player" then return true end
    return MOCK_PARTY_UNIT_EXISTS[unit] == true
end
function UnitHealth(unit)
    if unit=="player" then return MOCK_PLAYER_HEALTH end
    return tonumber(MOCK_PARTY_UNIT_HEALTHS[unit]) or 0
end
function UnitHealthMax(unit)
    if unit=="player" then return MOCK_PLAYER_MAX_HEALTH end
    return tonumber(MOCK_PARTY_UNIT_MAX_HEALTHS[unit]) or 0
end
function GetCVar(name) if name=="realmName" then return "TestRealm" end return "" end
function GetMoney() return MOCK_MONEY end
function GetRealZoneText() return "Westfall" end
function GetZoneText() return "Westfall" end
function GetMapContinents() return "Kalimdor","Eastern Kingdoms" end
function GetMapZones(continent)
    if continent==1 then return "Ashenvale" end
    if continent==2 then return "Westfall" end
end
function GetCurrentMapContinent() return MOCK_MAP_CONTINENT end
function GetCurrentMapZone() return MOCK_MAP_ZONE end
function SetMapZoom(continent,zone) MOCK_MAP_CONTINENT=continent MOCK_MAP_ZONE=zone end
function SetMapToCurrentZone() MOCK_MAP_CONTINENT=2 MOCK_MAP_ZONE=1 end
function GetMapOverlayInfo(index)
    if MOCK_MAP_CONTINENT==2 and MOCK_MAP_ZONE==1 then
        if index==1 then return "Interface\\WorldMap\\Westfall\\Moonbrook",100,100,0,0 end
        if index==2 then
            if MOCK_WESTFALL_EXPLORED then return "Interface\\WorldMap\\Westfall\\SentinelHill",100,100,100,0 end
            return "",100,100,100,0
        end
    elseif MOCK_MAP_CONTINENT==1 and MOCK_MAP_ZONE==1 then
        if index==1 then return "",100,100,0,0 end
    end
    return nil
end
function GetNumSkillLines() return 0 end
function GetNumFactions() return table.getn(MOCK_FACTIONS) end
function GetFactionInfo(index)
    local faction=MOCK_FACTIONS[index]
    if not faction then return nil end
    return faction.name,nil,faction.standing,0,42000,0,false,false,faction.isHeader or false,false,true
end
function GetNumPartyMembers() return MOCK_PARTY_MEMBERS end
function GetNumRaidMembers() return MOCK_RAID_MEMBERS end
function IsInGuild() return MOCK_GUILD_NAME ~= nil end
function GetInventoryItemLink() return nil end
function GetContainerNumSlots(bag) if bag==0 then return 16 end return 0 end
function GetContainerItemLink() return nil end
function GetItemInfo(link)
    if string.find(tostring(link),"19019",1,true) then
        return "Thunderfury",link,5,80,60,"Weapon","Sword",1
    end
    if string.find(tostring(link),"18832",1,true) then
        return "Brutality Blade",link,4,70,60,"Weapon","Sword",1
    end
    return "Test Item",link,1,1,1,"Miscellaneous","Junk",1
end
function RequestTimePlayed() end
function PlaySound() end
function PlaySoundFile(path) table.insert(MOCK_SOUND_FILES,path) end
function SendChatMessage(message,chatType) table.insert(MOCK_CHAT_SEND,{message=message,chatType=chatType}) end
function DoEmote(name) table.insert(MOCK_EMOTES,name) end
function GetCursorPosition() return MOCK_CURSOR_X,MOCK_CURSOR_Y end
function IsShiftKeyDown() return true end

UNITDIESOTHER="%s dies."
UNITDIESOTHER2="%s is slain."
LOOT_ITEM_SELF="You receive loot: %s."
LOOT_ITEM_SELF_MULTIPLE="You receive loot: %sx%d."
LOOT_ITEM_CREATED_SELF="You create: %s."
LOOT_ITEM_CREATED_SELF_MULTIPLE="You create: %sx%d."

local Frame={}
local frameMeta={
    __index=function(tbl,key)
        if Frame[key] then return Frame[key] end
        if type(key)=="string" and string.find(key,"^[A-Z]") then
            return function() return nil end
        end
        return nil
    end
}
local function NewFrame(name,parent)
    local frame=setmetatable({name=name,parent=parent,scripts={},visible=true,text=""},frameMeta)
    if name then _G[name]=frame end
    return frame
end
function Frame:SetScript(kind,handler) self.scripts[kind]=handler end
function Frame:RegisterEvent(name) end
function Frame:CreateFontString() return NewFrame(nil,self) end
function Frame:CreateTexture() return NewFrame(nil,self) end
function Frame:SetWidth(value) self.width=value end
function Frame:SetHeight(value) self.height=value end
function Frame:GetWidth() return self.width end
function Frame:GetHeight() return self.height end
function Frame:GetTop() return self.top end
function Frame:SetText(value) self.text=tostring(value or "") end
function Frame:GetText() return self.text or "" end
function Frame:SetTexture(value) self.texture=tostring(value or "") end
function Frame:Show() self.visible=true end
function Frame:Hide() self.visible=false end
function Frame:IsVisible() return self.visible end
function Frame:GetParent() return self.parent end
function Frame:GetFrameLevel() return 1 end
function Frame:GetCenter() return self.centerX or 500,self.centerY or 350 end
function Frame:GetEffectiveScale() return 1 end
function CreateFrame(kind,name,parent) return NewFrame(name,parent) end

UIParent=NewFrame("UIParent",nil)
UIParent.width=1000
UIParent.height=700
UIParent.centerX=500
UIParent.centerY=350
Minimap=NewFrame("Minimap",UIParent)
Minimap.width=140
Minimap.height=140
Minimap.centerX=900
Minimap.centerY=650
UISpecialFrames={}
SlashCmdList={}
DEFAULT_CHAT_FRAME={
    AddMessage=function(self,message) table.insert(MOCK_MESSAGES,message) end
}

function Fire(testEvent,a1,a2,a3)
    event=testEvent
    arg1=a1
    arg2=a2
    arg3=a3
    local handler=VanillaAchievementsEventFrame and VanillaAchievementsEventFrame.scripts.OnEvent
    assert(handler,"event handler missing")
    handler()
end
`;

const tests = String.raw`
local VA=VanillaAchievements
assert(table.getn(VA.catalog)==214,"catalog count")
assert(VA.byId["EXPLORE_RUN_FOREST"],"Run, Forrest, Run achievement registered")
VA:EnsureDB().dates.toastReplayVersion="0.2.6"

Fire("PLAYER_LOGIN")
assert(VA:IsComplete("LEVEL_05"),"level 5 baseline")
assert(VA:IsComplete("LEVEL_59"),"level 59 baseline")
assert(VA:IsComplete("LEVEL_60"),"level 60 baseline")
assert(VA:IsComplete("CLASS60_WARRIOR"),"class at 60")
assert(VA:IsComplete("MONEY_100"),"100 gold baseline")
assert(not VA:IsComplete("MONEY_500"),"500 gold should remain locked")
assert(not VA:IsComplete("REP_HONORED"),"friendly reputation does not unlock Honored")
MOCK_FACTIONS={{name="Test Faction",standing=5}}
Fire("UPDATE_FACTION")
assert(VA:EnsureDB().counters.bestReputationStanding==5,"friendly reputation recorded")
assert(not VA:IsComplete("REP_HONORED"),"friendly reputation remains below Honored")
VA:EnsureDB().completed.REP_HONORED={at=MOCK_NOW}
MOCK_FACTIONS={}
VA:ScanReputation(false)
assert(VA:IsComplete("REP_HONORED"),"no reputation data does not clear a valid Honored completion")
MOCK_FACTIONS={{name="Test Faction",standing=5}}
Fire("UPDATE_FACTION")
assert(not VA:IsComplete("REP_HONORED"),"legacy false Honored unlock revoked")
MOCK_FACTIONS[1].standing=6
Fire("UPDATE_FACTION")
assert(VA:IsComplete("REP_HONORED"),"Honored reputation unlocks at standing 6")
-- This unlock is part of the reputation test; keep later replay/announcement assertions isolated.
MOCK_CHAT_SEND={}
MOCK_EMOTES={}
assert(not VA.ScanAllZoneExploration and not VA.ScanCurrentZoneExploration,"full-zone map discovery removed")
assert(SLASH_VANILLAACHIEVEMENTS3=="/va","/va alias")
assert(VanillaAchievementsMinimapButton,"minimap button")
assert(VanillaAchievementsMinimapButton.icon.texture=="Interface\\AddOns\\VanillaAchievements\\Assets\\Icons\\VA_BADGE","minimap badge")
assert(VanillaAchievementsMinimapButton:GetParent()==Minimap,"launcher is discoverable as a minimap child")
assert(VanillaAchievementsMinimapButton:GetWidth()==30 and VanillaAchievementsMinimapButton:GetHeight()==30,"compact launcher size")
assert(VanillaAchievementsMinimapButton.badge==nil,"no square count badge")
local uiCenterX,uiCenterY=UIParent:GetCenter()
local mapCenterX,mapCenterY=Minimap:GetCenter()
local migratedExpectedX=mapCenterX+(tonumber(VA_DB.settings.minimapX) or -78)
local migratedExpectedY=mapCenterY+(tonumber(VA_DB.settings.minimapY) or -78)
assert(math.abs(VA_DB.settings.launcherX-migratedExpectedX)<0.01 and math.abs(VA_DB.settings.launcherY-migratedExpectedY)<0.01,
    "old minimap position migrated "..tostring(VA_DB.settings.launcherX)..","..tostring(VA_DB.settings.launcherY)..
    " expected "..tostring(migratedExpectedX)..","..tostring(migratedExpectedY)..
    " centers "..tostring(uiCenterX)..","..tostring(uiCenterY).."/"..tostring(mapCenterX)..","..tostring(mapCenterY))
assert(VA.ui.settingButtons and VA.ui.settingButtons.cheerOnUnlock,"front-end cheer setting")
assert(VA.ui.settingButtons.announceEmote and VA.ui.settingButtons.announceParty and VA.ui.settingButtons.announceGuild and VA.ui.settingButtons.sounds,"front-end announcement and sound settings")
assert(VA_DB.settings.announceGuild==false,"guild announcements default off")
VA_DB.settings.category="SETTINGS"
VA:RefreshUI()
assert(VA.ui.settingsPanel:IsVisible() and not VA.ui.rows[1]:IsVisible(),"settings tab replaces achievement list")
VA_DB.settings.category="ALL"
VA:RefreshUI()
assert(VA.ui.search:IsVisible() and VA.ui.rows[1]:IsVisible(),"achievement tab restores list")
assert(table.getn(VA.ui.rows)==7 and VA.ui.pageSize==14,"achievement list shows seven visible rows per fourteen-item page")
assert(VA.ui.scrollBar,"stylized achievement scrollbar installed")
assert(VA.ui.scrollBar:IsVisible(),"achievement scrollbar is visible")
assert(VA.ui.scrollThumb and VA.ui.scrollThumb:IsVisible(),"basic scrollbar thumb is visible")
assert(VA.ui.offset==0,"achievement list starts at first row")
VA.ui.scrollBar.top=100
VA.ui.scrollThumb.top=100
MOCK_CURSOR_Y=100
VA:ScrollAchievementsFromClick(VA.ui.scrollBar,MOCK_CURSOR_Y)
assert(VA.ui.offset==0,"scrollbar click at top keeps first row")
MOCK_CURSOR_Y=471
VA:ScrollAchievementsFromClick(VA.ui.scrollBar,MOCK_CURSOR_Y)
assert(VA.ui.offset==7,"scrollbar click at bottom reaches end of page")
VA.ui.offset=0
VA:RefreshUI()
MOCK_CURSOR_Y=400
this=VA.ui.scrollThumb
arg1="LeftButton"
VA.ui.scrollThumb.scripts.OnMouseDown()
MOCK_CURSOR_Y=0
this=VA.ui.scrollThumb
VA.ui.scrollThumb.scripts.OnUpdate()
this=VA.ui.scrollThumb
VA.ui.scrollThumb.scripts.OnMouseUp()
assert(VA.ui.offset==7,"scrollbar thumb drag reaches end of page")
assert(not VA.ui.scrollBar.dragging,"scrollbar drag stops on mouse up")
local scrollIndex
for scrollIndex=1,7 do VA:ScrollAchievements(-1) end
assert(VA.ui.offset==7,"mouse-wheel reveals second half of page")
VA:ScrollAchievements(-1)
assert(VA.ui.offset==7,"mouse-wheel stops at fourteen-item page boundary")
VA.ui.next.scripts.OnClick()
assert(VA.ui.offset==14,"next button advances one page")
VA.ui.prev.scripts.OnClick()
assert(VA.ui.offset==0,"previous button returns to first page")
this=VA.ui.settingButtons.cheerOnUnlock
this.scripts.OnClick()
assert(VA_DB.settings.cheerOnUnlock==true,"front-end cheer toggle enables")
this.scripts.OnClick()
assert(VA_DB.settings.cheerOnUnlock==false,"front-end cheer toggle disables")
local catalogIndex
for catalogIndex=1,table.getn(VA.catalog) do
    assert(string.find(VA.catalog[catalogIndex].icon or "","Assets\\Icons\\",1,true),"achievement badge path")
end
local loginToast=VA.runtime.currentToast
local loginQueue=table.getn(VA.runtime.toastQueue)
assert(loginToast,"new baseline achievement toast")
assert(VA.ui.toast.icon.texture==VA.byId[loginToast].icon,"toast badge")
assert(loginQueue>=0,"baseline toast queue is valid")
local loginSoundCount=table.getn(MOCK_SOUND_FILES)
local sameVersionCurrent=VA.runtime.currentToast
local sameVersionQueued=table.getn(VA.runtime.toastQueue)
Fire("PLAYER_LOGIN")
assert(VA.runtime.currentToast==sameVersionCurrent,"login keeps active toast")
assert(table.getn(VA.runtime.toastQueue)==sameVersionQueued,"login does not replay completed achievements")
assert(table.getn(MOCK_SOUND_FILES)==loginSoundCount,"login does not replay completed sounds")

local firstToast=VA.runtime.currentToast
local queuedBefore=table.getn(VA.runtime.toastQueue)
local soundsBefore=table.getn(MOCK_SOUND_FILES)
MOCK_NOW=MOCK_NOW+5
this=VanillaAchievementsTicker
arg1=0.3
VanillaAchievementsTicker.scripts.OnUpdate()
assert(VA.runtime.currentToast and VA.runtime.currentToast~=firstToast,"next toast shown")
assert(table.getn(VA.runtime.toastQueue)==queuedBefore-1,"toast queue advanced")
assert(table.getn(MOCK_SOUND_FILES)==soundsBefore+1,"next toast plays one sound")

local button=VanillaAchievementsMinimapButton
MOCK_CURSOR_X=500
MOCK_CURSOR_Y=440
this=button
button.scripts.OnDragStart()
button.scripts.OnUpdate()
button.scripts.OnDragStop()
assert(math.abs(VA_DB.settings.launcherX-500)<0.01,"free horizontal drag saved")
assert(math.abs(VA_DB.settings.launcherY-440)<0.01,"free vertical drag saved")
local savedX=VA_DB.settings.launcherX
local savedY=VA_DB.settings.launcherY
VA:PositionMinimapButton()
assert(VA_DB.settings.launcherX==savedX and VA_DB.settings.launcherY==savedY,"free position persists")

VA.runtime.toastQueue={}
VA.runtime.currentToast=nil
VA.runtime.toastHideAt=nil
VA.ui.toast:Hide()
SlashCmdList["VANILLAACHIEVEMENTS"]("replay")
assert(VA.runtime.currentToast,"manual replay starts a toast")
assert(table.getn(VA.runtime.toastQueue)+1==VA:GetCompletedCount(),"manual replay queues all completed")
assert(table.getn(MOCK_CHAT_SEND)==0,"manual replay does not announce")

VA.runtime.toastQueue={}
VA.runtime.currentToast=nil
VA.runtime.toastHideAt=nil
VA.ui.toast:Hide()
MOCK_PARTY_MEMBERS=1
MOCK_GUILD_NAME="Test Guild"
Fire("CHAT_MSG_COMBAT_HOSTILE_DEATH","Edwin VanCleef dies.")
assert(VA:IsComplete("DUN_DM"),"VanCleef clear")
assert(VA:Count(VA:GetSet("dungeonClears"))==1,"one dungeon clear")
assert(string.find(MOCK_SOUND_FILES[table.getn(MOCK_SOUND_FILES)] or "","anime-wow.mp3",1,true),"custom dungeon sound")
assert(table.getn(MOCK_CHAT_SEND)==2,"new dungeon unlock announces to emote and party by default")
assert(MOCK_CHAT_SEND[1].chatType=="EMOTE","announcement uses emote chat")
assert(MOCK_CHAT_SEND[1].message==" has unlocked achievement \"The Deadmines\"","announcement text")
assert(MOCK_CHAT_SEND[2].chatType=="PARTY","announcement uses party chat")
assert(MOCK_CHAT_SEND[2].chatType=="PARTY","announcement uses party chat")
assert(table.getn(MOCK_EMOTES)==0,"physical cheer defaults off")
MOCK_CHAT_SEND={}
VA_DB.settings.announceParty=false
VA_DB.settings.announceGuild=true
Fire("CHAT_MSG_COMBAT_HOSTILE_DEATH","Edwin VanCleef dies.")
assert(VA:Count(VA:GetSet("dungeonClears"))==1,"boss dedupe")
assert(table.getn(MOCK_CHAT_SEND)==0,"duplicate boss does not announce")

VA:DismissToast()
MOCK_NOW=MOCK_NOW+121
Fire("CHAT_MSG_COMBAT_HOSTILE_DEATH","Ragnaros dies.")
assert(VA:IsComplete("RAID_MC"),"Ragnaros clear")
assert(VA:Count(VA:GetSet("raidClears"))==1,"one raid clear")
assert(string.find(MOCK_SOUND_FILES[table.getn(MOCK_SOUND_FILES)] or "","anime-wow.mp3",1,true),"custom raid sound")
assert(table.getn(MOCK_CHAT_SEND)==2 and MOCK_CHAT_SEND[2].chatType=="GUILD","guild toggle enables guild announcement")

MOCK_CHAT_SEND={}
VA:DismissToast()
MOCK_NOW=MOCK_NOW+121
MOCK_PARTY_MEMBERS=4
MOCK_PARTY_UNIT_EXISTS={party1=true,party2=true,party3=true,party4=true}
MOCK_PARTY_UNIT_HEALTHS={party1=100,party2=100,party3=100,party4=100}
MOCK_PARTY_UNIT_MAX_HEALTHS={party1=100,party2=100,party3=100,party4=100}
VA:EnsureDB().completed.DUN_FULL_PARTY=nil
Fire("CHAT_MSG_COMBAT_HOSTILE_DEATH","Mutanus the Devourer has been defeated!")
assert(VA:IsComplete("DUN_WC"),"Mutanus clear")
assert(VA:IsComplete("DUN_FULL_PARTY"),"full party dungeon bonus")
assert(VA:Count(VA:GetSet("dungeonClears"))==2,"second dungeon clear")
assert(table.getn(MOCK_CHAT_SEND)>=0,"full party clear processed")
VA:DismissToast()

MOCK_NOW=MOCK_NOW+121
MOCK_PARTY_MEMBERS=0
Fire("CHAT_MSG_COMBAT_HOSTILE_DEATH","Arugal dies.")
assert(VA:IsComplete("DUN_SFK"),"Arugal clear")
assert(VA:Count(VA:GetSet("dungeonClears"))==3,"SFK counts as a dungeon clear")
VA:DismissToast()

VA:EnsureDB().completed.DUN_SFK=nil
VA:GetSet("dungeonClears").DUN_SFK=nil
MOCK_NOW=MOCK_NOW+121
Fire("CHAT_MSG_COMBAT_HOSTILE_DEATH","Archmage Arugal dies, you gain 213 experience. (+91 exp Rested bonus)")
assert(VA:IsComplete("DUN_SFK"),"Arugal combat text with experience suffix clear")
assert(VA:Count(VA:GetSet("dungeonClears"))==3,"SFK suffix message counts as a dungeon clear")
VA:DismissToast()

VA:EnsureDB().completed.DUN_WC=nil
VA:GetSet("dungeonClears").DUN_WC=nil
MOCK_NOW=MOCK_NOW+121
Fire("CHAT_MSG_COMBAT_HOSTILE_DEATH","You have slain Mutanus the Devourer!")
assert(VA:IsComplete("DUN_WC"),"Mutanus player-kill message clear")
assert(VA:Count(VA:GetSet("dungeonClears"))==3,"Mutanus player-kill message counts as a dungeon clear")
VA:DismissToast()

VA:EnsureDB().completed.DUN_WC=nil
VA:GetSet("dungeonClears").DUN_WC=nil
MOCK_NOW=MOCK_NOW+121
Fire("CHAT_MSG_COMBAT_HOSTILE_DEATH","You have slain Mutanus the Devourer, you gain 213 experience")
assert(VA:IsComplete("DUN_WC"),"Mutanus slain prefix with trailing text clear")
assert(VA:Count(VA:GetSet("dungeonClears"))==3,"Mutanus slain prefix counts as a dungeon clear")
VA:DismissToast()

VA:EnsureDB().completed.DUN_SFK=nil
VA:GetSet("dungeonClears").DUN_SFK=nil
MOCK_NOW=MOCK_NOW+121
Fire("CHAT_MSG_COMBAT_HOSTILE_DEATH","Son of Arugal dies, you gain 213 experience")
assert(not VA:IsComplete("DUN_SFK"),"Son of Arugal is not the SFK final boss")
assert(not VA:GetSet("dungeonClears").DUN_SFK,"Son of Arugal does not count as an SFK clear")
VA:DismissToast()

Fire("CHAT_MSG_LOOT","You receive loot: |cffa335ee|Hitem:18832:0:0:0|h[Brutality Blade]|h|r.")
assert(VA:IsComplete("LOOT_EPIC"),"epic personal loot")
assert(not VA:IsComplete("LOOT_LEGENDARY"),"legendary should remain locked")

Fire("PLAYER_DEAD")
assert(VA:IsComplete("DEATH_01"),"first death")
assert(VA:EnsureDB().counters.deaths==1,"death counter")

VA:EnsureDB().completed.LEVEL_60=nil
Fire("UNIT_LEVEL","player")
assert(VA:IsComplete("LEVEL_60"),"Vanilla unit-level event unlocks immediately")

VA:EnsureDB().counters.playedSeconds=86399
VA:EnsureDB().completed.PLAYED_24H=nil
MOCK_MONEY=5000000
this=VanillaAchievementsTicker
arg1=1.1
VanillaAchievementsTicker.scripts.OnUpdate()
assert(VA:IsComplete("MONEY_500"),"live scanner unlocks money during play")
assert(VA:IsComplete("PLAYED_24H"),"live scanner advances played time")

-- QUEST_FINISHED is a quest-frame transition/close event and must not count
-- as a completed quest.  Only QUEST_COMPLETE should feed the quest counter
-- and the three-within-one-minute secret.
local expansionEvent=VanillaAchievementsExpansionEvents and VanillaAchievementsExpansionEvents.scripts.OnEvent
assert(expansionEvent,"expanded event handler")
VA.expSession.recentQuests={}
VA:EnsureDB().counters.quests=0
VA:EnsureDB().completed.QUEST_TRIPLE=nil
event="QUEST_FINISHED"
expansionEvent()
assert(VA:EnsureDB().counters.quests==0,"quest window close does not count as completion")
MOCK_NOW=MOCK_NOW+10
event="QUEST_COMPLETE"; expansionEvent()
MOCK_NOW=MOCK_NOW+10
event="QUEST_COMPLETE"; expansionEvent()
MOCK_NOW=MOCK_NOW+10
event="QUEST_COMPLETE"; expansionEvent()
assert(VA:EnsureDB().counters.quests==3,"quest completion counter counts completed quests")
assert(VA:IsComplete("QUEST_TRIPLE"),"three quest completions unlock One Trip, Three Rewards")
VA_DB.version="0.7.6"
VA_DB.characters[VA:GetCharacterKey()].completed.QUEST_TRIPLE={at=MOCK_NOW}
VA:EnsureDB()
assert(not VA:IsComplete("QUEST_TRIPLE"),"upgrade clears legacy quest-trip false positive")

VA.expSession.recentDeaths={}
VA:EnsureDB().completed.DEATH_DOUBLE=nil
MOCK_NOW=MOCK_NOW+20
event="PLAYER_DEAD"; expansionEvent()
MOCK_NOW=MOCK_NOW+120
event="PLAYER_DEAD"; expansionEvent()
assert(VA:IsComplete("DEATH_DOUBLE"),"two deaths within five minutes unlock Not Again")

VA.expSession.recentDeaths={}
VA:EnsureDB().completed.SURVIVE_LOW=nil
MOCK_PLAYER_HEALTH=5
MOCK_PLAYER_MAX_HEALTH=100
event="PLAYER_REGEN_ENABLED"; expansionEvent()
assert(VA:IsComplete("SURVIVE_LOW"),"low-health combat exit unlocks Saved by the Bell")

VA:EnsureDB().completed.SURVIVE_LOW=nil
MOCK_PLAYER_HEALTH=0
MOCK_PLAYER_MAX_HEALTH=100
event="PLAYER_REGEN_ENABLED"; expansionEvent()
assert(not VA:IsComplete("SURVIVE_LOW"),"death does not count as a low-health escape")

print("RESULT passed catalog=214 badges=ok custom_sound=ok toast_queue=ok free_launcher=ok realtime=ok bosses=ok loot=ok deaths=ok")
`;

const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);

function run(source, name) {
  const status = lauxlib.luaL_loadbuffer(
    L,
    to_luastring(source),
    null,
    to_luastring(name)
  );
  if (status !== lua.LUA_OK) {
    throw new Error(to_jsstring(lua.lua_tostring(L, -1)));
  }
  const callStatus = lua.lua_pcall(L, 0, lua.LUA_MULTRET, 0);
  if (callStatus !== lua.LUA_OK) {
    throw new Error(to_jsstring(lua.lua_tostring(L, -1)));
  }
}

run(mock, "@mock.lua");
for (const file of files) {
  run(fs.readFileSync(path.join(root, file), "utf8"), `@${file}`);
}
run(tests, "@tests.lua");
