-- Additional single-character achievements from the OctoAchievements blueprint.
local VA = VanillaAchievements
local ICON_ROOT = "Interface\\AddOns\\VanillaAchievements\\Assets\\Icons\\"
local function Add(def)
    def.icon = def.icon or (ICON_ROOT .. tostring(def.id))
    VA:AddAchievement(def)
end

-- Questing.
Add({id="QUEST_001",category="GENERAL",name="A Small Favor",description="Complete one quest.",progress="quests",required=1})
Add({id="QUEST_010",category="GENERAL",name="Errand Runner",description="Complete 10 quests.",progress="quests",required=10})
Add({id="QUEST_025",category="GENERAL",name="Questional Authority",description="Complete 25 quests.",progress="quests",required=25})
Add({id="QUEST_050",category="GENERAL",name="Local Hero",description="Complete 50 quests.",progress="quests",required=50})
Add({id="QUEST_100",category="GENERAL",name="No Exclamation Marks Left",description="Complete 100 quests.",progress="quests",required=100})
Add({id="QUEST_250",category="GENERAL",name="Professional Problem Solver",description="Complete 250 quests.",progress="quests",required=250})
Add({id="QUEST_TRIPLE",category="SECRETS",name="One Trip, Three Rewards",description="Complete three quests within 60 seconds.",progress="questTriples",required=1,secret=true})

-- General combat.
Add({id="KILL_001",category="GENERAL",name="First Blood",description="Defeat one qualifying hostile enemy.",progress="kills",required=1})
Add({id="KILL_010",category="GENERAL",name="Ten Down",description="Defeat 10 qualifying enemies.",progress="kills",required=10})
Add({id="KILL_100",category="GENERAL",name="Population Control",description="Defeat 100 qualifying enemies.",progress="kills",required=100})
Add({id="KILL_500",category="GENERAL",name="Occupational Hazard",description="Defeat 500 qualifying enemies.",progress="kills",required=500})
Add({id="KILL_1000",category="GENERAL",name="A Thousand Problems",description="Defeat 1,000 qualifying enemies.",progress="kills",required=1000})
Add({id="CRIT_001",category="GENERAL",name="Critical Thinking",description="Land your first critical hit.",progress="crits",required=1})
Add({id="DAMAGE_500",category="GENERAL",name="That Had to Hurt",description="Deal at least 500 damage with one direct hit.",progress="bestDamage",required=500})
Add({id="DAMAGE_1000",category="GENERAL",name="Four Digits",description="Deal at least 1,000 damage with one direct hit.",progress="bestDamage",required=1000})
Add({id="KILL_HIGH",category="SECRETS",name="Punching Up",description="Defeat an enemy at least three levels above you.",progress="highLevelKills",required=1,secret=true})
Add({id="SURVIVE_LOW",category="SECRETS",name="Saved by the Bell",description="Leave combat alive at 5% health or less.",progress="lowHealthEscapes",required=1,secret=true})
Add({id="KILL_STREAK_25",category="GENERAL",name="On a Roll",description="Defeat 25 qualifying enemies without dying.",progress="killStreak",required=25})

-- Murlocs.
Add({id="MURLOC_010",category="GENERAL",name="Wet Work",description="Defeat 10 murlocs.",progress="murlocKills",required=10})
Add({id="MURLOC_025",category="GENERAL",name="Mrrgl Management",description="Defeat 25 murlocs.",progress="murlocKills",required=25})
Add({id="MURLOC_050",category="GENERAL",name="Murloc Menace",description="Defeat 50 murlocs.",progress="murlocKills",required=50})
Add({id="MURLOC_100",category="GENERAL",name="The Sound of Silence",description="Defeat 100 murlocs.",progress="murlocKills",required=100})
Add({id="MURLOC_RUSH",category="SECRETS",name="School's Out",description="Defeat five murlocs within 30 seconds.",progress="murlocRush",required=1,secret=true})
Add({id="MURLOC_ZONES",category="GENERAL",name="Beach Cleanup",description="Defeat murlocs in five different zones.",progress="murlocZones",progressType="SET",required=5})
Add({id="MURLOC_NAMES",category="GENERAL",name="Murloc Holmes",description="Defeat five differently named murlocs.",progress="murlocNames",progressType="SET",required=5})
Add({id="MURLOC_DANCE",category="SECRETS",name="Fish Are Friends",description="Use /dance while targeting a living murloc.",progress="murlocDance",required=1,secret=true})
Add({id="MURLOC_KISS",category="SECRETS",name="Mixed Signals",description="Kiss a murloc, then defeat one with that name within 30 seconds.",progress="murlocKiss",required=1,secret=true})
Add({id="MURLOC_DEATH",category="SECRETS",name="Mrrglglgl!",description="Die while a murloc is your target or recent attacker.",progress="murlocDeath",required=1,secret=true})
Add({id="MURLOC_META",category="SECRETS",name="Fluent in Mrrgl",description="Earn every other murloc achievement.",progress="murlocMeta",required=1,secret=true})

-- Creature types and named enemies.
Add({id="TYPE_BEAST_100",category="GENERAL",name="Beast Mode",description="Defeat 100 Beasts.",progress="beastKills",required=100})
Add({id="TYPE_UNDEAD_050",category="GENERAL",name="Grave Business",description="Defeat 50 Undead enemies.",progress="undeadKills",required=50})
Add({id="TYPE_DEMON_025",category="GENERAL",name="Occupational Exorcist",description="Defeat 25 Demons.",progress="demonKills",required=25})
Add({id="TYPE_ELEMENTAL_025",category="GENERAL",name="Elementarily Speaking",description="Defeat 25 Elementals.",progress="elementalKills",required=25})
Add({id="TYPE_DRAGONKIN_025",category="GENERAL",name="Dragon Your Feet",description="Defeat 25 Dragonkin.",progress="dragonkinKills",required=25})
Add({id="CRITTER_001",category="SECRETS",name="You Monster",description="Defeat one Critter.",progress="critterKills",required=1,secret=true})
Add({id="CRITTER_025",category="GENERAL",name="Critterical Mass",description="Defeat 25 Critters.",progress="critterKills",required=25})
Add({id="CRITTER_LOVE_08",category="EXPLORATION",name="To All The Squirrels I've Loved Before",description="Use /love on eight different classic critters.",progress="lovedCritters",progressType="SET",required=8})
Add({id="PEST_CONTROL_08",category="GENERAL",name="Pest Control",description="Slay eight different classic pests.",progress="pestKills",progressType="SET",required=8})
Add({id="BOSS_HOGGER",category="GENERAL",name="Hogger? I Barely Know Her",description="Defeat Hogger.",progress="namedKills",required=1})
Add({id="BOSS_MORLADIM",category="GENERAL",name="Grave Mistake",description="Defeat Mor'Ladim.",progress="namedKills",required=1})
Add({id="BOSS_BANGALASH",category="GENERAL",name="Cat Scratch Fever",description="Defeat King Bangalash.",progress="namedKills",required=1})
Add({id="BOSS_BELLYGRUB",category="GENERAL",name="Belly Up",description="Defeat Bellygrub.",progress="namedKills",required=1})

-- Dungeon challenges.
Add({id="DUN_FULL_PARTY",category="DUNGEONS",name="Five Alive",description="Defeat a dungeon final boss with a full party alive.",progress="fiveAlive",required=1})
Add({id="DUN_NO_DEATH",category="DUNGEONS",name="No Repairs Needed",description="Defeat a dungeon final boss without dying during the run.",progress="noRepairRuns",required=1})
Add({id="DUN_LOW_HEALTH",category="DUNGEONS",name="By a Thread",description="Defeat a dungeon final boss at 10% health or less.",progress="threadRuns",required=1})
Add({id="DUN_LAST_STANDING",category="SECRETS",name="Last One Standing",description="Be the only living connected party member when a dungeon boss dies.",progress="lastStanding",required=1,secret=true})
Add({id="DUN_REPEAT_SESSION",category="DUNGEONS",name="Run It Back",description="Complete the same dungeon twice in one login session.",progress="repeatDungeon",required=1})
Add({id="DUN_DOUBLEHEADER",category="DUNGEONS",name="Dungeon Doubleheader",description="Complete two different dungeons in one login session.",progress="doubleheader",required=1})
Add({id="DUN_SCARLET_ALL",category="DUNGEONS",name="Scarlet Letter",description="Complete all four Scarlet Monastery wings.",progress="scarletWings",progressType="SET",required=4})
Add({id="DUN_DM_TRIATHLON",category="DUNGEONS",name="Dire Maul Triathlon",description="Complete Dire Maul East, West, and North.",progress="direMaulWings",progressType="SET",required=3})
Add({id="DUN_BLACKROCK_SET",category="DUNGEONS",name="Blackrock Tourist",description="Complete Blackrock Depths, Lower Blackrock Spire, and Upper Blackrock Spire.",progress="blackrockDungeons",progressType="SET",required=3})
Add({id="DUN_STRAT_SIDES",category="DUNGEONS",name="Two Sides of the Same Coin",description="Complete both tracked sides of Stratholme.",progress="stratholmeSides",progressType="SET",required=2})

-- Inventory and equipment.
Add({id="LOOT_GRAY_025",category="COLLECTION",name="One Man's Trash",description="Loot 25 poor-quality items.",progress="grayLoot",required=25})
Add({id="LOOT_GRAY_100",category="COLLECTION",name="Garbage Collector",description="Loot 100 poor-quality items.",progress="grayLoot",required=100})
Add({id="BAG_08",category="COLLECTION",name="Bag Upgrade",description="Equip an additional bag with at least eight slots.",progress="bagSlots8",required=1})
Add({id="BAG_10X4",category="COLLECTION",name="Deep Pockets",description="Equip four bags with at least 10 slots each.",progress="bags10",required=1})
Add({id="BAG_14X4",category="COLLECTION",name="Pack Mule",description="Equip four bags with at least 14 slots each.",progress="bags14",required=1})
Add({id="BAG_MATCHING",category="COLLECTION",name="Matching Luggage",description="Equip four bags with the same number of slots.",progress="matchingBags",required=1})
Add({id="NO_CHEST",category="SECRETS",name="Going Commando",description="Defeat a qualifying enemy with no chest armor equipped.",progress="noChestKill",required=1,secret=true})
Add({id="NAKED_DEATH",category="SECRETS",name="Naked and Afraid",description="Die with all normal armor slots empty.",progress="nakedDeath",required=1,secret=true})

-- Social and travel.
Add({id="SOCIAL_PARTY",category="GENERAL",name="Strength in Numbers",description="Join a party.",progress="partyJoined",required=1})
Add({id="SOCIAL_FULL_PARTY",category="GENERAL",name="Full House",description="Be in a full five-player party.",progress="fullParty",required=1})
Add({id="SOCIAL_RAID",category="RAIDS",name="We're Gonna Need a Bigger Boat",description="Join a raid group.",progress="raidJoined",required=1})
Add({id="SOCIAL_GUILD",category="GENERAL",name="Guilded",description="Become a member of a guild.",progress="guilded",required=1})
Add({id="TRAVEL_COASTS",category="EXPLORATION",name="Both Coasts",description="Visit both the Eastern Kingdoms and Kalimdor.",progress="visitedContinents",progressType="SET",required=2})
Add({id="FOLLOW_10M",category="SECRETS",name="Follow the Leader",description="Follow the same player continuously for 10 minutes.",progress="followLeader",required=1,secret=true})

-- Emote secrets.
Add({id="EMOTE_CHICKEN",category="SECRETS",name="Chicken Chaser",description="Use /chicken while targeting a living Chicken.",progress="chickenEmote",required=1,secret=true})
Add({id="EMOTE_KNEEL",category="SECRETS",name="Respect the Fallen",description="Use /kneel while targeting a dead player.",progress="kneelDead",required=1,secret=true})
Add({id="EMOTE_LOVE_CRITTER",category="SECRETS",name="No Witnesses",description="Love a Critter, then defeat one with that name within 30 seconds.",progress="loveCritter",required=1,secret=true})
Add({id="EMOTE_WAVE_KILL",category="SECRETS",name="Wave Goodbye",description="Wave at a hostile target, then defeat an enemy with that name.",progress="waveKill",required=1,secret=true})
Add({id="EMOTE_CHEER_DEATH",category="SECRETS",name="Premature Celebration",description="Cheer in combat, then die before leaving combat.",progress="cheerDeath",required=1,secret=true})
Add({id="EMOTE_CHEER_BOSS",category="SECRETS",name="Job's Done",description="Cheer within 10 seconds after defeating a dungeon or raid boss.",progress="cheerBoss",required=1,secret=true})
Add({id="EMOTE_MAILBOX",category="SECRETS",name="Mailbox Dancer",description="Dance within 10 seconds after opening a mailbox.",progress="mailboxDance",required=1,secret=true})
Add({id="EMOTE_AUCTION",category="SECRETS",name="Auction House Idol",description="Dance within 10 seconds after opening the Auction House.",progress="auctionDance",required=1,secret=true})

-- Money and dice.
Add({id="MONEY_ZERO",category="SECRETS",name="Exactly Broke",description="Carry exactly zero copper.",progress="zeroMoney",required=1,secret=true})
Add({id="ROLL_ONE",category="SECRETS",name="Natural One",description="Roll exactly 1 on a normal 1-100 roll.",progress="rollOne",required=1,secret=true})
Add({id="ROLL_HUNDRED",category="GENERAL",name="Roll Model",description="Roll exactly 100 on a normal 1-100 roll.",progress="rollHundred",required=1})
Add({id="ROLL_MATCH",category="SECRETS",name="What Are the Odds?",description="Roll the same number on two consecutive normal 1-100 rolls.",progress="rollMatch",required=1,secret=true})
Add({id="MERCHANT_10G",category="GENERAL",name="Retail Therapy",description="Spend at least 10 gold during one merchant visit.",progress="merchantSpend",required=1})

-- Death and survival secrets.
Add({id="DEATH_HOGGER",category="SECRETS",name="Hogger's Lunch",description="Die while Hogger is your target or recent attacker.",progress="hoggerDeath",required=1,secret=true})
Add({id="HOGGER_REMATCH",category="GENERAL",name="Rematch Clause",description="Defeat Hogger after earning Hogger's Lunch.",progress="hoggerRematch",required=1})
Add({id="DEATH_FIRE",category="SECRETS",name="Campfire Casualty",description="Die shortly after environmental fire damage.",progress="environmentFireDeath",required=1,secret=true})
Add({id="DEATH_DROWN",category="SECRETS",name="Swimming Lessons",description="Die from drowning.",progress="drowningDeath",required=1,secret=true})
Add({id="DEATH_DOUBLE",category="SECRETS",name="Not Again",description="Die twice within five minutes.",progress="doubleDeath",required=1,secret=true})
Add({id="DEATH_DURABILITY",category="SECRETS",name="Repair Bill Incoming",description="Die while an equipped item has zero durability.",progress="brokenDeath",required=1,secret=true})
Add({id="DEATH_GHOST_5M",category="SECRETS",name="The Long Walk",description="Remain a ghost for five continuous minutes before resurrecting.",progress="ghostWalk",required=1,secret=true})

-- New metas.
Add({id="META_SECRET_05",category="GENERAL",name="Curious Adventurer",description="Discover five secret achievements.",progress="secretAchievements",required=5})
Add({id="META_SECRET_15",category="GENERAL",name="Secret Seeker",description="Discover 15 secret achievements.",progress="secretAchievements",required=15})
Add({id="META_DEATH_05",category="GENERAL",name="Mortal Coil",description="Earn five different death-related achievements.",progress="deathAchievements",required=5})
Add({id="META_EVERY_CATEGORY",category="GENERAL",name="A Little Bit of Everything",description="Earn at least one achievement from every ordinary category.",progress="ordinaryCategories",required=1})
