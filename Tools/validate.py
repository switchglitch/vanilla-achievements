from __future__ import annotations

import re
import sys
import hashlib
from pathlib import Path


ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
EXPECTED_CATALOG = 224


def check(name: str, condition: bool, detail: str = "") -> bool:
    status = "PASS" if condition else "FAIL"
    suffix = f" ({detail})" if detail else ""
    print(f"[{status}] {name}{suffix}")
    return condition


def main() -> int:
    results: list[bool] = []
    toc = ROOT / "VanillaAchievements.toc"
    results.append(check("TOC exists", toc.is_file()))
    if not toc.is_file():
        return 1

    toc_text = toc.read_text(encoding="utf-8")
    results.append(check("Vanilla interface", "## Interface: 11200" in toc_text))
    results.append(check("SavedVariables declared", "## SavedVariables: VA_DB" in toc_text))

    lua_entries = [
        line.strip().replace("\\", "/")
        for line in toc_text.splitlines()
        if line.strip() and not line.startswith("##")
    ]
    expected_order = ["Core.lua", "Catalog.lua", "ExpansionCatalog.lua", "FunCatalog.lua", "Tracking.lua", "ExpansionTracking.lua", "UI.lua", "Minimap.lua"]
    results.append(check("load order", lua_entries == expected_order, ", ".join(lua_entries)))
    results.append(check("all TOC files exist", all((ROOT / item).is_file() for item in lua_entries)))

    lua_files = [ROOT / item for item in lua_entries]
    sources: list[str] = []
    ascii_safe = True
    for path in lua_files:
        data = path.read_bytes()
        if any(byte > 127 for byte in data):
            ascii_safe = False
        sources.append(data.decode("ascii"))
    combined = "\n".join(sources)
    results.append(check("ASCII and Vanilla-font safe", ascii_safe))

    forbidden = [
        "GuildRoster",
        "SendAddonMessage",
        "BackdropTemplate",
        "SetDesaturated",
    ]
    found = [token for token in forbidden if token in combined]
    results.append(check("no guild or modern API dependencies", not found, ", ".join(found)))

    catalog = (ROOT / "Catalog.lua").read_text(encoding="ascii") + (ROOT / "ExpansionCatalog.lua").read_text(encoding="ascii") + (ROOT / "FunCatalog.lua").read_text(encoding="ascii")
    explicit_ids = re.findall(r'id="([A-Z0-9_]+)"', catalog)
    dynamic_ids = re.findall(
        r'^\s*\{"((?:CLASS60|DUN_|RAID_|WORLD_)[A-Z0-9_]+)"\s*,',
        catalog,
        flags=re.MULTILINE,
    )
    all_ids = explicit_ids + dynamic_ids
    duplicates = sorted({item for item in all_ids if all_ids.count(item) > 1})
    results.append(check("achievement IDs unique", not duplicates, ", ".join(duplicates)))
    results.append(
        check(
            "catalog count",
            len(all_ids) == EXPECTED_CATALOG,
            f"{len(all_ids)} expected {EXPECTED_CATALOG}",
        )
    )

    results.append(check("level 59 joke included", "LEVEL_59" in all_ids))
    results.append(check("level cap is 60", 'id="LEVEL_60"' in catalog and "required=60" in catalog))
    results.append(check("VanCleef trigger included", "Edwin VanCleef" in catalog))
    results.append(check("all-clear metas included", "DUN_META_ALL" in all_ids and "RAID_META_ALL" in all_ids))
    results.append(check("/va command alias included", 'SLASH_VANILLAACHIEVEMENTS3 = "/va"' in combined))
    results.append(check("minimap launcher included", "VanillaAchievementsMinimapButton" in combined))
    results.append(check("launcher is discoverable by minimap button panels", 'VanillaAchievementsMinimapButton", Minimap or UIParent' in combined))
    results.append(check("launcher uses free screen position", 'SetPoint("CENTER", UIParent, "BOTTOMLEFT"' in combined and "launcherX" in combined))
    results.append(check("launcher has no square backdrop", 'button:SetBackdrop({' not in (ROOT / "Minimap.lua").read_text(encoding="ascii")))
    results.append(check("paged achievement list included", "ScrollAchievements" in combined and "scrollBar" in combined and "14 per page" not in combined))
    results.append(check("scrollbar click support included", "scrollUp" in combined and "scrollDown" in combined and "OnMouseDown" in combined))
    results.append(check("scrollbar hold scrolling included", "scrollElapsed" in combined and "OnMouseUp" in combined and "OnUpdate" in combined))
    missing_icons = [
        achievement_id
        for achievement_id in all_ids
        if not (ROOT / "Assets" / "Icons" / f"{achievement_id}.tga").is_file()
    ]
    results.append(check("every achievement has a badge", not missing_icons, ", ".join(missing_icons)))
    badge_hashes = {}
    duplicate_badges = []
    for achievement_id in all_ids:
        icon_path = ROOT / "Assets" / "Icons" / f"{achievement_id}.tga"
        if not icon_path.is_file():
            continue
        digest = hashlib.sha256(icon_path.read_bytes()).hexdigest()
        if digest in badge_hashes:
            duplicate_badges.append(f"{achievement_id}={badge_hashes[digest]}")
        else:
            badge_hashes[digest] = achievement_id
    results.append(check("achievement badges are unique", not duplicate_badges, ", ".join(duplicate_badges)))
    icon_files = list((ROOT / "Assets" / "Icons").glob("*.tga"))
    bad_icon_sizes: list[str] = []
    for icon_path in icon_files:
        data = icon_path.read_bytes()
        if len(data) < 18:
            bad_icon_sizes.append(icon_path.name)
            continue
        width = int.from_bytes(data[12:14], "little")
        height = int.from_bytes(data[14:16], "little")
        depth = data[16]
        if width != 64 or height != 64 or depth != 32:
            bad_icon_sizes.append(icon_path.name)
    results.append(check("badges are Vanilla-safe 64x64 RGBA TGA", not bad_icon_sizes, ", ".join(bad_icon_sizes)))
    expected_sounds = {"standard.wav", "level.wav", "dungeon.wav", "raid.wav", "secret.wav", "meta.wav"}
    found_sounds = {path.name for path in (ROOT / "Assets" / "Sounds").glob("*.wav")}
    results.append(check("six achievement sound cues included", found_sounds == expected_sounds))
    custom_sound = ROOT / "Assets" / "Sounds" / "anime-wow.mp3"
    results.append(check("custom achievement MP3 included", custom_sound.is_file() and custom_sound.stat().st_size > 0))
    results.append(check("/vach sound toggle included", 'message == "sound"' in combined))
    results.append(check("/vach sound test included", 'message == "soundtest"' in combined))
    results.append(check("/vach replay command included", 'message == "replay"' in combined))
    results.append(check("/vach announcement toggle included", 'message == "announce"' in combined))
    results.append(check("/vach social toggle included", 'message == "social"' in combined))
    results.append(check(
        "party and guild announcements are separate",
        "announceParty" in combined and "announceGuild" in combined and "announceGuild = false" in combined,
    ))
    results.append(check("settings tab included", 'button = MakeButton(frame, "Settings"' in combined and "settingsPanel" in combined))
    results.append(check("/vach cheer toggle included", 'message == "cheer"' in combined))
    results.append(check("real-time fallback scanner included", "UpdateRealtimeTracking" in combined))
    results.append(check(
        "quest trip uses completion event",
        'event=="QUEST_COMPLETE"' in combined and 'event=="QUEST_FINISHED"' not in combined,
    ))
    results.append(check("Vanilla equipment event included", '"UNIT_INVENTORY_CHANGED"' in combined))
    results.append(check("front-end cheer setting included", '"cheerOnUnlock","Cheer"' in combined))
    results.append(check(
        "full-zone map discovery removed",
        "ScanAllZoneExploration" not in combined
        and "ScanCurrentZoneExploration" not in combined
        and "GetMapOverlayInfo" not in combined,
    ))

    passed = sum(results)
    print(f"RESULT passed={passed} failed={len(results) - passed} total={len(results)}")
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main())
