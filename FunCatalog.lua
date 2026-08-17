local VA = VanillaAchievements
local ICON_ROOT = "Interface\\AddOns\\VanillaAchievements\\Assets\\Icons\\"
local function Add(def)
    def.icon = def.icon or (ICON_ROOT .. tostring(def.id))
    VA:AddAchievement(def)
end

-- Small, repeatable milestones with a little personality.
Add({id="LEVEL_03",category="LEVELING",name="Tutorial Optional",description="Reach level 3.",progressType="LEVEL",required=3})
Add({id="EXPLORE_05",category="EXPLORATION",name="A Change of Scenery",description="Visit five different zones.",progress="zonesVisited",progressType="SET",required=5})
Add({id="EXPLORE_RUN_FOREST",category="EXPLORATION",name="Run, Forrest, Run!!",description="Change zones five times within 20 minutes.",progress="forestRun",required=1})
Add({id="QUEST_005",category="GENERAL",name="Quest in Show",description="Complete five quests.",progress="quests",required=5})
Add({id="QUEST_075",category="GENERAL",name="Quest for the Best",description="Complete 75 quests.",progress="quests",required=75})
Add({id="KILL_050",category="GENERAL",name="Kill Bill",description="Defeat 50 qualifying enemies.",progress="kills",required=50})
Add({id="KILL_250",category="GENERAL",name="No Small Feat",description="Defeat 250 qualifying enemies.",progress="kills",required=250})
Add({id="CRIT_010",category="GENERAL",name="Critical Mass",description="Land 10 critical hits.",progress="crits",required=10})
Add({id="LOOT_010",category="COLLECTION",name="Lootenant",description="Loot 10 items.",progress="lootCount",required=10})
Add({id="LOOT_025",category="COLLECTION",name="Loot There, It Is",description="Loot 25 items.",progress="lootCount",required=25})
Add({id="LOOT_GRAY_005",category="COLLECTION",name="Fifty Shades of Gray",description="Loot five poor-quality items.",progress="grayLoot",required=5})
Add({id="MONEY_005",category="GENERAL",name="Five-Finger Discount",description="Carry 5 gold.",progressType="MONEY",required=50000})
Add({id="MONEY_050",category="GENERAL",name="Fifty Shades of Gold",description="Carry 50 gold.",progressType="MONEY",required=500000})
Add({id="PLAYED_15M",category="GENERAL",name="Just Five More Minutes",description="Accumulate 15 minutes of play time.",progress="playedSeconds",required=900,unit="hours"})
Add({id="PLAYED_1H",category="GENERAL",name="Where Did the Hour Go?",description="Accumulate one hour of play time.",progress="playedSeconds",required=3600,unit="hours"})
Add({id="DEATH_03",category="GENERAL",name="Third Time's the Charm",description="Die three times.",progress="deaths",required=3})
Add({id="GEAR_RARE",category="COLLECTION",name="Dress Code Suggested",description="Equip a rare item.",progress="bestEquippedQuality",required=3})
Add({id="DUN_FIRST",category="DUNGEONS",name="Dungeon Dabbler",description="Complete your first tracked dungeon.",progress="dungeonClears",required=1})
Add({id="RAID_FIRST",category="RAIDS",name="Raid and Desist",description="Complete your first tracked raid.",progress="raidClears",required=1})
Add({id="SOCIAL_FIVE",category="GENERAL",name="Plus Four",description="Be in a full five-player party.",progress="fullParty",required=1})
Add({id="MONEY_SPEND_1G",category="GENERAL",name="Money Talks",description="Spend at least 1 gold during one merchant visit.",progress="merchantSpend",required=1})
