local VA = VanillaAchievements

local ICON_ROOT = "Interface\\AddOns\\VanillaAchievements\\Assets\\Icons\\"
local function Add(def)
    def.icon = def.icon or (ICON_ROOT .. tostring(def.id))
    VA:AddAchievement(def)
end

-- Leveling. IDs are permanent and should never be reused for another meaning.
Add({id="LEVEL_05",category="LEVELING",name="First Steps",description="Reach level 5.",progressType="LEVEL",required=5})
Add({id="LEVEL_10",category="LEVELING",name="Double Digits",description="Reach level 10.",progressType="LEVEL",required=10})
Add({id="LEVEL_20",category="LEVELING",name="Seasoned Adventurer",description="Reach level 20.",progressType="LEVEL",required=20})
Add({id="LEVEL_30",category="LEVELING",name="Halfway There",description="Reach level 30.",progressType="LEVEL",required=30})
Add({id="LEVEL_40",category="LEVELING",name="Veteran Adventurer",description="Reach level 40.",progressType="LEVEL",required=40})
Add({id="LEVEL_50",category="LEVELING",name="The Home Stretch",description="Reach level 50.",progressType="LEVEL",required=50})
Add({id="LEVEL_59",category="LEVELING",name="One Bar Left",description="Reach level 59. Surely the last level will be quick.",progressType="LEVEL",required=59})
Add({id="LEVEL_60",category="LEVELING",name="At the Summit",description="Reach the Vanilla level cap of 60.",progressType="LEVEL",required=60})
local CLASS_60 = {
    {"CLASS60_WARRIOR","Warrior at the Summit","Reach level 60 as a Warrior.","WARRIOR"},
    {"CLASS60_PALADIN","Paladin at the Summit","Reach level 60 as a Paladin.","PALADIN"},
    {"CLASS60_HUNTER","Hunter at the Summit","Reach level 60 as a Hunter.","HUNTER"},
    {"CLASS60_ROGUE","Rogue at the Summit","Reach level 60 as a Rogue.","ROGUE"},
    {"CLASS60_PRIEST","Priest at the Summit","Reach level 60 as a Priest.","PRIEST"},
    {"CLASS60_SHAMAN","Shaman at the Summit","Reach level 60 as a Shaman.","SHAMAN"},
    {"CLASS60_MAGE","Mage at the Summit","Reach level 60 as a Mage.","MAGE"},
    {"CLASS60_WARLOCK","Warlock at the Summit","Reach level 60 as a Warlock.","WARLOCK"},
    {"CLASS60_DRUID","Druid at the Summit","Reach level 60 as a Druid.","DRUID"},
}
VA.class60AchievementIds = {}
local classIndex, classRow
local currentClassToken
if UnitClass then local _, token = UnitClass("player"); currentClassToken = token end
for classIndex=1,table.getn(CLASS_60) do
    classRow = CLASS_60[classIndex]
    if not currentClassToken or currentClassToken == classRow[4] then
        Add({id=classRow[1],category="LEVELING",name=classRow[2],description=classRow[3],progressType="LEVEL",required=60})
        VA.class60AchievementIds[classRow[4]] = classRow[1]
    end
end

-- Dungeon clears use the final boss death as the completion trigger.
local DUNGEONS = {
    {"DUN_RFC","Ragefire Chasm","Defeat Bazzalan in Ragefire Chasm.",{"Bazzalan"}},
    {"DUN_WC","Wailing Caverns","Defeat Mutanus the Devourer in Wailing Caverns.",{"Mutanus the Devourer","Mutanus"}},
    {"DUN_DM","The Deadmines","Defeat Edwin VanCleef in The Deadmines.",{"Edwin VanCleef","VanCleef"}},
    {"DUN_SFK","Shadowfang Keep","Defeat Archmage Arugal in Shadowfang Keep.",{"Archmage Arugal"}},
    {"DUN_STOCKADE","The Stockade","Defeat Bazil Thredd in The Stockade.",{"Bazil Thredd"}},
    {"DUN_BFD","Blackfathom Deeps","Defeat Aku'mai in Blackfathom Deeps.",{"Aku'mai","Aku mai"}},
    {"DUN_GNOMER","Gnomeregan","Defeat Mekgineer Thermaplugg in Gnomeregan.",{"Mekgineer Thermaplugg"}},
    {"DUN_RFK","Razorfen Kraul","Defeat Charlga Razorflank in Razorfen Kraul.",{"Charlga Razorflank"}},
    {"DUN_SM_GY","Scarlet Monastery: Graveyard","Defeat Bloodmage Thalnos in the Graveyard.",{"Bloodmage Thalnos"}},
    {"DUN_SM_LIB","Scarlet Monastery: Library","Defeat Arcanist Doan in the Library.",{"Arcanist Doan"}},
    {"DUN_SM_ARM","Scarlet Monastery: Armory","Defeat Herod in the Armory.",{"Herod"}},
    {"DUN_SM_CATH","Scarlet Monastery: Cathedral","Defeat High Inquisitor Whitemane in the Cathedral.",{"High Inquisitor Whitemane"}},
    {"DUN_RFD","Razorfen Downs","Defeat Amnennar the Coldbringer in Razorfen Downs.",{"Amnennar the Coldbringer"}},
    {"DUN_ULDA","Uldaman","Defeat Archaedas in Uldaman.",{"Archaedas"}},
    {"DUN_ZF","Zul'Farrak","Defeat Chief Ukorz Sandscalp in Zul'Farrak.",{"Chief Ukorz Sandscalp"}},
    {"DUN_MARA","Maraudon","Defeat Princess Theradras in Maraudon.",{"Princess Theradras"}},
    {"DUN_ST","The Temple of Atal'Hakkar","Defeat the Shade of Eranikus in the Sunken Temple.",{"Shade of Eranikus"}},
    {"DUN_BRD","Blackrock Depths","Defeat Emperor Dagran Thaurissan in Blackrock Depths.",{"Emperor Dagran Thaurissan","Emperor Thaurissan"}},
    {"DUN_LBRS","Lower Blackrock Spire","Defeat Overlord Wyrmthalak in Lower Blackrock Spire.",{"Overlord Wyrmthalak"}},
    {"DUN_UBRS","Upper Blackrock Spire","Defeat General Drakkisath in Upper Blackrock Spire.",{"General Drakkisath"}},
    {"DUN_DM_E","Dire Maul East","Defeat Alzzin the Wildshaper in Dire Maul East.",{"Alzzin the Wildshaper"}},
    {"DUN_DM_W","Dire Maul West","Defeat Prince Tortheldrin in Dire Maul West.",{"Prince Tortheldrin"}},
    {"DUN_DM_N","Dire Maul North","Defeat King Gordok in Dire Maul North.",{"King Gordok"}},
    {"DUN_STRAT_LIVE","Stratholme: Living","Defeat Balnazzar in Stratholme.",{"Balnazzar"}},
    {"DUN_STRAT_DEAD","Stratholme: Undead","Defeat Baron Rivendare in Stratholme.",{"Baron Rivendare"}},
    {"DUN_SCHOLO","Scholomance","Defeat Darkmaster Gandling in Scholomance.",{"Darkmaster Gandling"}},
}

VA.bossAchievements = {}
VA.dungeonAchievementIds = {}
local index, row, bossIndex, key
for index=1,table.getn(DUNGEONS) do
    row = DUNGEONS[index]
    Add({id=row[1],category="DUNGEONS",name=row[2],description=row[3],progress="dungeonClears",required=1,tag="DUNGEON"})
    table.insert(VA.dungeonAchievementIds, row[1])
    for bossIndex=1,table.getn(row[4]) do
        key = VA:Normalize(row[4][bossIndex])
        VA.bossAchievements[key] = row[1]
    end
end
Add({id="DUN_META_05",category="DUNGEONS",name="Dungeon Tourist",description="Clear five different Vanilla dungeons.",progress="dungeonClears",progressType="SET",required=5})
Add({id="DUN_META_10",category="DUNGEONS",name="Dungeon Delver",description="Clear ten different Vanilla dungeons.",progress="dungeonClears",progressType="SET",required=10})
Add({id="DUN_META_ALL",category="DUNGEONS",name="Master of the Depths",description="Clear every tracked Vanilla dungeon and wing.",progress="dungeonClears",progressType="SET",required=table.getn(DUNGEONS)})

-- Raid clears use the final encounter of each raid.
local RAIDS = {
    {"RAID_ONY","Onyxia's Lair","Defeat Onyxia.",{"Onyxia"}},
    {"RAID_MC","Molten Core","Defeat Ragnaros.",{"Ragnaros"}},
    {"RAID_BWL","Blackwing Lair","Defeat Nefarian.",{"Nefarian"}},
    {"RAID_ZG","Zul'Gurub","Defeat Hakkar the Soulflayer.",{"Hakkar","Hakkar the Soulflayer"}},
    {"RAID_AQ20","Ruins of Ahn'Qiraj","Defeat Ossirian the Unscarred.",{"Ossirian the Unscarred"}},
    {"RAID_AQ40","Temple of Ahn'Qiraj","Defeat C'Thun.",{"C'Thun","C Thun"}},
    {"RAID_NAXX","Naxxramas","Defeat Kel'Thuzad.",{"Kel'Thuzad","Kel Thuzad"}},
}

VA.raidAchievementIds = {}
for index=1,table.getn(RAIDS) do
    row = RAIDS[index]
    Add({id=row[1],category="RAIDS",name=row[2],description=row[3],progress="raidClears",required=1,tag="RAID"})
    table.insert(VA.raidAchievementIds, row[1])
    for bossIndex=1,table.getn(row[4]) do
        key = VA:Normalize(row[4][bossIndex])
        VA.bossAchievements[key] = row[1]
    end
end
Add({id="RAID_META_03",category="RAIDS",name="Raid Regular",description="Complete three different Vanilla raids.",progress="raidClears",progressType="SET",required=3})
Add({id="RAID_META_ALL",category="RAIDS",name="Conqueror of Vanilla",description="Complete every tracked Vanilla raid.",progress="raidClears",progressType="SET",required=table.getn(RAIDS)})

-- Outdoor raid bosses.
local WORLD_BOSSES = {
    {"WORLD_AZUREGOS","The Blue Dragon","Defeat Azuregos.",{"Azuregos"}},
    {"WORLD_KAZZAK","The Lord of the Blasted Lands","Defeat Lord Kazzak.",{"Lord Kazzak"}},
    {"WORLD_YSONDRE","Ysondre","Defeat Ysondre.",{"Ysondre"}},
    {"WORLD_EMERISS","Emeriss","Defeat Emeriss.",{"Emeriss"}},
    {"WORLD_LETHON","Lethon","Defeat Lethon.",{"Lethon"}},
    {"WORLD_TAERAR","Taerar","Defeat Taerar.",{"Taerar"}},
}
for index=1,table.getn(WORLD_BOSSES) do
    row = WORLD_BOSSES[index]
    Add({id=row[1],category="RAIDS",name=row[2],description=row[3],progress="worldBosses",required=1,tag="WORLD"})
    for bossIndex=1,table.getn(row[4]) do VA.bossAchievements[VA:Normalize(row[4][bossIndex])] = row[1] end
end
Add({id="WORLD_META_ALL",category="RAIDS",name="Dragons, Demons, and You",description="Defeat every tracked outdoor world boss.",progress="worldBosses",progressType="SET",required=table.getn(WORLD_BOSSES)})

-- Exploration is based on unique zone names visited after installation.
Add({id="EXPLORE_10",category="EXPLORATION",name="Getting Around",description="Visit ten different zones.",progress="zonesVisited",progressType="SET",required=10})
Add({id="EXPLORE_25",category="EXPLORATION",name="Well Traveled",description="Visit twenty-five different zones.",progress="zonesVisited",progressType="SET",required=25})
Add({id="EXPLORE_40",category="EXPLORATION",name="Continental Wanderer",description="Visit forty different zones.",progress="zonesVisited",progressType="SET",required=40})
Add({id="EXPLORE_50",category="EXPLORATION",name="Azeroth Has No Corners Left",description="Visit fifty different zones.",progress="zonesVisited",progressType="SET",required=50})

-- Professions and reputation.
Add({id="SKILL_075",category="PROFESSIONS",name="Apprentice No More",description="Reach 75 skill in any profession.",progress="bestProfession",required=75})
Add({id="SKILL_150",category="PROFESSIONS",name="Journeyman",description="Reach 150 skill in any profession.",progress="bestProfession",required=150})
Add({id="SKILL_225",category="PROFESSIONS",name="Expert Hand",description="Reach 225 skill in any profession.",progress="bestProfession",required=225})
Add({id="SKILL_300",category="PROFESSIONS",name="Artisan",description="Reach 300 skill in any profession.",progress="bestProfession",required=300})
Add({id="SKILL_TWO_300",category="PROFESSIONS",name="Master of Two Trades",description="Reach 300 in two primary professions.",progress="primaryProfessionsAt300",required=2})
Add({id="WEAPON_100",category="PROFESSIONS",name="Practiced Hand",description="Reach 100 skill with a weapon type.",progress="bestWeaponSkill",required=100})
Add({id="WEAPON_200",category="PROFESSIONS",name="Weapon Veteran",description="Reach 200 skill with a weapon type.",progress="bestWeaponSkill",required=200})
Add({id="WEAPON_300",category="PROFESSIONS",name="Weapon Master",description="Reach 300 skill with a weapon type.",progress="bestWeaponSkill",required=300})
Add({id="COOKING_300",category="PROFESSIONS",name="Azeroth's Chef",description="Reach 300 Cooking.",progress="cookingSkill",required=300})
Add({id="FIRSTAID_300",category="PROFESSIONS",name="Field Surgeon",description="Reach 300 First Aid.",progress="firstAidSkill",required=300})
Add({id="FISHING_300",category="PROFESSIONS",name="Master Angler",description="Reach 300 Fishing.",progress="fishingSkill",required=300})
Add({id="SECONDARY_ALL_300",category="PROFESSIONS",name="Self-Sufficient",description="Reach 300 Cooking, First Aid, and Fishing.",progress="secondaryAt300",required=3})
Add({id="REP_HONORED",category="GENERAL",name="A Friendly Face",description="Become Honored with a faction.",progress="bestReputationStanding",required=6})
Add({id="REP_REVERED",category="GENERAL",name="Highly Regarded",description="Become Revered with a faction.",progress="bestReputationStanding",required=7})
Add({id="REP_EXALTED",category="GENERAL",name="They Really Like You",description="Become Exalted with a faction.",progress="bestReputationStanding",required=8})
Add({id="REP_EXALTED_05",category="GENERAL",name="Known Across Azeroth",description="Become Exalted with five factions.",progress="exaltedFactions",required=5})
Add({id="REP_EXALTED_10",category="GENERAL",name="Beloved by Many",description="Become Exalted with ten factions.",progress="exaltedFactions",required=10})
Add({id="REP_EXALTED_20",category="GENERAL",name="Diplomatic Legend",description="Become Exalted with twenty factions.",progress="exaltedFactions",required=20})

-- Wealth, equipment, loot, play time, and deaths.
Add({id="MONEY_001",category="GENERAL",name="Pocket Change",description="Carry 1 gold.",progressType="MONEY",required=10000})
Add({id="MONEY_010",category="GENERAL",name="A Modest Purse",description="Carry 10 gold.",progressType="MONEY",required=100000})
Add({id="MONEY_100",category="GENERAL",name="Triple Digits",description="Carry 100 gold.",progressType="MONEY",required=1000000})
Add({id="MONEY_500",category="GENERAL",name="A Small Fortune",description="Carry 500 gold.",progressType="MONEY",required=5000000})
Add({id="MONEY_1000",category="GENERAL",name="Goblin Approved",description="Carry 1,000 gold.",progressType="MONEY",required=10000000})
Add({id="LOOT_UNCOMMON",category="COLLECTION",name="A Touch of Green",description="Loot an uncommon item.",progress="bestLootQuality",required=2})
Add({id="LOOT_RARE",category="COLLECTION",name="Feeling Blue",description="Loot a rare item.",progress="bestLootQuality",required=3})
Add({id="LOOT_EPIC",category="COLLECTION",name="Purple Fever",description="Loot an epic item.",progress="bestLootQuality",required=4})
Add({id="LOOT_LEGENDARY",category="COLLECTION",name="Legendary!",description="Loot a legendary item.",progress="bestLootQuality",required=5})
Add({id="GEAR_EPIC",category="COLLECTION",name="Dressed to Impress",description="Equip an epic item.",progress="bestEquippedQuality",required=4})
Add({id="GEAR_RARE_10",category="COLLECTION",name="True Blue",description="Equip at least ten rare-or-better items at once.",progress="rareEquippedCount",required=10})
Add({id="GEAR_EPIC_05",category="COLLECTION",name="Purple Ensemble",description="Equip at least five epic-or-better items at once.",progress="epicEquippedCount",required=5})
Add({id="GEAR_EPIC_10",category="COLLECTION",name="Raid Ready",description="Equip at least ten epic-or-better items at once.",progress="epicEquippedCount",required=10})
Add({id="BAGS_FULL",category="SECRETS",name="Inventory Management",description="Have no free bag slots.",revealed="Fill every slot in your backpack and equipped bags.",progress="bagsFull",required=1,secret=true})
Add({id="PLAYED_24H",category="GENERAL",name="A Day in Azeroth",description="Accumulate 24 hours of play time.",progress="playedSeconds",required=86400,unit="hours"})
Add({id="PLAYED_7D",category="GENERAL",name="A Week in Azeroth",description="Accumulate seven days of play time.",progress="playedSeconds",required=604800,unit="hours"})
Add({id="PLAYED_30D",category="GENERAL",name="A Month in Azeroth",description="Accumulate thirty days of play time.",progress="playedSeconds",required=2592000,unit="hours"})
Add({id="PLAYED_60D",category="GENERAL",name="Azerothian Resident",description="Accumulate sixty days of play time.",progress="playedSeconds",required=5184000,unit="hours"})
Add({id="DEATH_01",category="GENERAL",name="That Was Educational",description="Die once after installing Vanilla Achievements.",progress="deaths",required=1})
Add({id="DEATH_10",category="GENERAL",name="Learning the Hard Way",description="Die ten times after installing Vanilla Achievements.",progress="deaths",required=10})
Add({id="DEATH_100",category="GENERAL",name="Spirit Healer Regular",description="Die one hundred times after installing Vanilla Achievements.",progress="deaths",required=100})
Add({id="DEATH_FALL",category="SECRETS",name="Gravity Remains Undefeated",description="The title is your clue.",revealed="Die shortly after taking falling damage.",progress="fallDeath",required=1,secret=true})

-- Overall collection milestones.
Add({id="META_010",category="GENERAL",name="Achievement Hunter",description="Earn ten achievements.",progressType="COMPLETED",required=10})
Add({id="META_025",category="GENERAL",name="Making Progress",description="Earn twenty-five achievements.",progressType="COMPLETED",required=25})
Add({id="META_050",category="GENERAL",name="Half a Chronicle",description="Earn fifty achievements.",progressType="COMPLETED",required=50})
Add({id="META_075",category="GENERAL",name="Dedicated Adventurer",description="Earn seventy-five achievements.",progressType="COMPLETED",required=75})
Add({id="META_100",category="GENERAL",name="Centurion",description="Earn one hundred achievements.",progressType="COMPLETED",required=100})
Add({id="META_PVE_ALL",category="GENERAL",name="The Complete PvE Chronicle",description="Clear every tracked dungeon and raid.",progress="pveChronicle",required=1})
Add({id="META_SWORD_1000",category="SECRETS",name="Sword of 1000 Truths",description="The title is your clue.",revealed="Earn every other achievement in Vanilla Achievements.",secret=true})

VA.totalDungeonAchievements = table.getn(DUNGEONS)
VA.totalRaidAchievements = table.getn(RAIDS)
VA.totalWorldBossAchievements = table.getn(WORLD_BOSSES)

-- Public extension point for private-server dungeons, raids, and renamed bosses.
function VA:RegisterBossAchievement(def, aliases)
    if not self:AddAchievement(def) then return false end
    local aliasIndex, alias
    for aliasIndex=1,table.getn(aliases or {}) do
        alias = self:Normalize(aliases[aliasIndex])
        if alias ~= "" then self.bossAchievements[alias] = def.id end
    end
    return true
end
