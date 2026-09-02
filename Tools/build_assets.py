"""Build original 64x64 achievement badges and small PCM sound effects."""

from __future__ import annotations

import math
import random
import re
import struct
import wave
import hashlib
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
CATALOG_FILES = [ROOT / "Catalog.lua", ROOT / "ExpansionCatalog.lua", ROOT / "FunCatalog.lua"]
FRAME = ROOT / "Assets" / "Source" / "achievement-medallion.png"
ICON_DIR = ROOT / "Assets" / "Icons"
SOUND_DIR = ROOT / "Assets" / "Sounds"
FONT = Path(r"C:\Windows\Fonts\framd.ttf")
FALLBACK_FONT = Path(r"C:\Windows\Fonts\georgiab.ttf")

CATEGORY_COLORS = {
    "LEVELING": (45, 76, 145),
    "DUNGEONS": (92, 64, 35),
    "RAIDS": (126, 32, 25),
    "EXPLORATION": (35, 105, 61),
    "PROFESSIONS": (115, 72, 24),
    "COLLECTION": (89, 43, 118),
    "GENERAL": (35, 75, 105),
    "SECRETS": (63, 25, 78),
}

CLASS_LABELS = {
    "WARRIOR": "WAR",
    "PALADIN": "PAL",
    "HUNTER": "HNT",
    "ROGUE": "ROG",
    "PRIEST": "PRI",
    "SHAMAN": "SHM",
    "MAGE": "MAG",
    "WARLOCK": "WLK",
    "DRUID": "DRU",
}

SPECIAL_LABELS = {
    "VA_BADGE": "VA",
    "DUN_META_05": "D5",
    "DUN_META_10": "D10",
    "DUN_META_ALL": "ALL",
    "RAID_META_03": "R3",
    "RAID_META_ALL": "ALL",
    "WORLD_META_ALL": "WB",
    "SKILL_TWO_300": "2X",
    "SECONDARY_ALL_300": "3X",
    "REP_HONORED": "HON",
    "REP_REVERED": "REV",
    "REP_EXALTED": "EX",
    "REP_EXALTED_05": "EX5",
    "REP_EXALTED_10": "E10",
    "REP_EXALTED_20": "E20",
    "LOOT_UNCOMMON": "U",
    "LOOT_RARE": "R",
    "LOOT_EPIC": "E",
    "LOOT_LEGENDARY": "L",
    "GEAR_EPIC": "GE",
    "GEAR_RARE_10": "R10",
    "GEAR_EPIC_05": "E5",
    "GEAR_EPIC_10": "E10",
    "BAGS_FULL": "BAG",
    "SOCIAL_GUILD": "",
    "BAGS_FULL": "",
    "KILL_001": "",
    "DEATH_FALL": "FALL",
    "META_PVE_ALL": "PVE",
    "META_SWORD_1000": "SWORD",
}


def achievement_ids() -> list[str]:
    text = "\n".join(path.read_text(encoding="utf-8") for path in CATALOG_FILES if path.is_file())
    pattern = re.compile(r'id="([A-Z0-9_]+)"|\{"((?:CLASS60|DUN_|RAID_|WORLD_)[A-Z0-9_]+)"\s*,')
    seen: set[str] = set()
    values: list[str] = []
    for match in pattern.finditer(text):
        value = match.group(1) or match.group(2)
        if value not in seen:
            seen.add(value)
            values.append(value)
    if len(values) != 224:
        raise RuntimeError(f"Expected 224 achievement IDs, found {len(values)}")
    return values


def category_for(achievement_id: str) -> str:
    if achievement_id.startswith(("LEVEL_", "CLASS60_")):
        return "LEVELING"
    if achievement_id.startswith("DUN_"):
        return "DUNGEONS"
    if achievement_id.startswith(("RAID_", "WORLD_")):
        return "RAIDS"
    if achievement_id.startswith("EXPLORE_"):
        return "EXPLORATION"
    if achievement_id.startswith(
        ("SKILL_", "WEAPON_", "COOKING_", "FIRSTAID_", "FISHING_", "SECONDARY_")
    ):
        return "PROFESSIONS"
    if achievement_id.startswith(("LOOT_", "GEAR_", "BAGS_")):
        return "COLLECTION" if achievement_id != "BAGS_FULL" else "SECRETS"
    if achievement_id == "DEATH_FALL":
        return "SECRETS"
    return "GENERAL"


def label_for(achievement_id: str) -> str:
    if achievement_id in SPECIAL_LABELS:
        return SPECIAL_LABELS[achievement_id]
    if achievement_id.startswith("LEVEL_"):
        return str(int(achievement_id.rsplit("_", 1)[1]))
    if achievement_id.startswith("CLASS60_"):
        return CLASS_LABELS.get(achievement_id[8:], "60")
    if achievement_id.startswith("DUN_"):
        label = achievement_id[4:]
        replacements = {
            "STOCKADE": "STK",
            "GNOMER": "GNO",
            "STRAT_LIVE": "SL",
            "STRAT_DEAD": "SD",
            "SCHOLO": "SCH",
        }
        return replacements.get(label, label.replace("_", "")[:4])
    if achievement_id.startswith("RAID_"):
        return achievement_id[5:].replace("_", "")[:4]
    if achievement_id.startswith("WORLD_"):
        return achievement_id[6:8]
    if achievement_id.startswith("EXPLORE_"):
        return achievement_id.rsplit("_", 1)[1]
    if achievement_id.startswith("QUEST_"):
        suffix = achievement_id.rsplit("_", 1)[1]
        return "3X" if suffix == "TRIPLE" else "Q" + suffix[-3:]
    if achievement_id.startswith("EMOTE_"):
        return {
            "EMOTE_CHICKEN": "CHK", "EMOTE_KNEEL": "KNE", "EMOTE_LOVE_CRITTER": "LOVE",
            "EMOTE_WAVE_KILL": "WAV", "EMOTE_CHEER_DEATH": "CD", "EMOTE_CHEER_BOSS": "CB",
            "EMOTE_MAILBOX": "MAIL", "EMOTE_AUCTION": "AUC",
        }.get(achievement_id, "EM")
    if achievement_id.startswith("SKILL_"):
        return str(int(achievement_id.rsplit("_", 1)[1]))
    if achievement_id.startswith("WEAPON_"):
        return "W" + achievement_id.rsplit("_", 1)[1].lstrip("0")
    if achievement_id == "COOKING_300":
        return "CK"
    if achievement_id == "FIRSTAID_300":
        return "FA"
    if achievement_id == "FISHING_300":
        return "FSH"
    if achievement_id.startswith("MONEY_"):
        suffix = achievement_id.rsplit("_", 1)[1]
        return (str(int(suffix)) + "G") if suffix.isdigit() else "$$"
    if achievement_id.startswith("PLAYED_"):
        return achievement_id[7:]
    if achievement_id.startswith("DEATH_"):
        suffix = achievement_id.rsplit("_", 1)[1]
        return "X" + (str(int(suffix)) if suffix.isdigit() else "!")
    if achievement_id.startswith("META_"):
        return achievement_id.rsplit("_", 1)[1].lstrip("0")
    return achievement_id.replace("_", "")[:4]


def fit_font(draw: ImageDraw.ImageDraw, label: str, max_width: int) -> ImageFont.FreeTypeFont:
    font_path = FONT if FONT.exists() else FALLBACK_FONT
    for size in range(30, 10, -1):
        font = ImageFont.truetype(str(font_path), size=size)
        box = draw.textbbox((0, 0), label, font=font, stroke_width=1)
        if box[2] - box[0] <= max_width and box[3] - box[1] <= 27:
            return font
    return ImageFont.truetype(str(font_path), size=11)


def icon_only(achievement_id: str) -> bool:
    prefixes = (
        "QUEST_", "KILL_", "CRIT_", "DAMAGE_", "MURLOC_", "TYPE_", "CRITTER_", "BOSS_",
        "EMOTE_", "ROLL_", "DUN_", "RAID_", "LOOT_", "GEAR_", "BAG_", "SOCIAL_", "META_",
    )
    return achievement_id in ("BAGS_FULL", "KILL_001", "MONEY_ZERO", "DEATH_HOGGER", "DEATH_FIRE", "DEATH_DROWN", "DEATH_DOUBLE", "DEATH_DURABILITY", "DEATH_GHOST_5M", "EXPLORE_RUN_FOREST") or achievement_id.startswith(prefixes)


def draw_symbol(draw: ImageDraw.ImageDraw, achievement_id: str) -> None:
    dark = (35, 17, 8, 255)
    gold = (244, 190, 70, 255)
    light = (255, 225, 135, 255)
    if achievement_id == "EXPLORE_RUN_FOREST":
        draw.line([(19, 41), (28, 38), (37, 40), (46, 35)], fill=(70, 170, 85, 255), width=3)
        draw.ellipse((29, 17, 36, 24), fill=(241, 185, 87, 255), outline=dark)
        draw.line([(32, 24), (28, 33), (36, 32)], fill=light, width=3)
        draw.line([(29, 29), (22, 36)], fill=gold, width=2)
        draw.line([(35, 31), (43, 37)], fill=gold, width=2)
        return
    if achievement_id in ("BAGS_FULL", "BAG_MATCHING"):
        draw.rounded_rectangle((17, 25, 30, 41), radius=4, fill=(123, 68, 30, 255), outline=dark, width=2)
        draw.rounded_rectangle((34, 25, 47, 41), radius=4, fill=(149, 82, 33, 255), outline=dark, width=2)
        draw.arc((20, 18, 28, 29), 180, 360, fill=gold, width=2)
        draw.arc((37, 18, 45, 29), 180, 360, fill=gold, width=2)
        draw.line([(20, 30), (27, 30)], fill=light, width=2)
        draw.line([(37, 30), (44, 30)], fill=light, width=2)
        return
    if achievement_id in ("SOCIAL_GUILD", "SOCIAL_PARTY", "SOCIAL_FULL_PARTY", "SOCIAL_FIVE"):
        draw.polygon([(17, 33), (24, 25), (31, 30), (27, 37), (21, 40)], fill=(67, 112, 177, 255), outline=dark)
        draw.polygon([(47, 33), (40, 25), (33, 30), (37, 37), (43, 40)], fill=(159, 59, 45, 255), outline=dark)
        draw.polygon([(25, 28), (32, 27), (39, 32), (35, 36), (29, 33)], fill=(238, 178, 99, 255), outline=dark)
        draw.line([(29, 32), (36, 32)], fill=light, width=2)
        return
    if achievement_id in ("KILL_001",) or achievement_id.startswith(("CRIT_", "DAMAGE_")):
        draw.ellipse((19, 19, 45, 45), outline=(224, 65, 45, 255), width=2)
        draw.line([(32, 16), (32, 48)], fill=gold, width=2); draw.line([(16, 32), (48, 32)], fill=gold, width=2)
        draw.ellipse((29, 29, 35, 35), fill=(216, 45, 35, 255), outline=light); return
    if achievement_id.startswith("QUEST_"):
        draw.polygon([(21, 19), (42, 19), (42, 42), (21, 42)], fill=(224, 190, 117, 255), outline=dark)
        draw.line([(25, 25), (38, 25)], fill=(112, 73, 35, 255), width=2); draw.line([(25, 31), (36, 31)], fill=(112, 73, 35, 255), width=2)
        draw.line([(27, 37), (31, 40), (38, 34)], fill=(54, 133, 66, 255), width=2); return
    if achievement_id.startswith("MURLOC_"):
        draw.ellipse((20, 25, 44, 39), fill=(77, 151, 177, 255), outline=dark)
        draw.polygon([(20, 31), (14, 25), (14, 38)], fill=(52, 120, 150, 255), outline=dark)
        draw.ellipse((35, 28, 38, 31), fill=light); draw.ellipse((36, 29, 37, 30), fill=dark); return
    if achievement_id.startswith("TYPE_") or achievement_id.startswith("CRITTER_"):
        draw.ellipse((24, 22, 40, 38), fill=(145, 91, 45, 255), outline=dark)
        draw.ellipse((21, 18, 27, 25), fill=(145, 91, 45, 255), outline=dark); draw.ellipse((37, 18, 43, 25), fill=(145, 91, 45, 255), outline=dark)
        draw.ellipse((28, 28, 31, 31), fill=dark); draw.ellipse((33, 28, 36, 31), fill=dark); return
    if achievement_id.startswith(("ROLL_", "MONEY_")) or achievement_id == "MONEY_ZERO":
        draw.ellipse((20, 20, 44, 44), fill=(220, 164, 49, 255), outline=dark, width=2)
        draw.ellipse((25, 25, 39, 39), outline=light, width=2); draw.line([(32, 24), (32, 40)], fill=light, width=1); return
    if achievement_id.startswith(("DEATH_", "NAKED_DEATH")):
        draw.ellipse((21, 19, 43, 40), fill=(212, 211, 190, 255), outline=dark)
        draw.rectangle((25, 35, 39, 44), fill=(212, 211, 190, 255), outline=dark)
        draw.ellipse((26, 26, 30, 31), fill=dark); draw.ellipse((34, 26, 38, 31), fill=dark); draw.line([(28, 36), (36, 36)], fill=(150, 38, 35, 255), width=2); return
    if achievement_id.startswith("DUN_"):
        # Dungeon door: an arched entrance with a small gold lintel.
        draw.rectangle((19, 27, 45, 45), fill=(77, 48, 29, 255), outline=dark, width=2)
        draw.arc((19, 15, 45, 39), 180, 360, fill=gold, width=4)
        draw.line([(23, 28), (23, 44)], fill=(204, 151, 62, 255), width=2)
        draw.line([(41, 28), (41, 44)], fill=(204, 151, 62, 255), width=2)
        draw.polygon([(32, 25), (37, 31), (32, 37), (27, 31)], fill=(184, 48, 35, 255), outline=light)
        return
    if achievement_id.startswith("RAID_"):
        # Raid crest: shield and a stylized dragon wing.
        draw.polygon([(32, 15), (47, 22), (43, 42), (32, 49), (21, 42), (17, 22)], fill=(129, 39, 31, 255), outline=dark)
        draw.arc((18, 18, 34, 38), 270, 90, fill=gold, width=3)
        draw.arc((30, 18, 46, 38), 90, 270, fill=gold, width=3)
        draw.polygon([(32, 23), (36, 32), (32, 40), (28, 32)], fill=(239, 196, 73, 255), outline=dark)
        return
    if achievement_id.startswith("BOSS_"):
        # Boss trophy: horned skull with a warm red eye glow.
        draw.ellipse((20, 21, 44, 43), fill=(190, 183, 157, 255), outline=dark, width=2)
        draw.polygon([(23, 24), (16, 17), (19, 30)], fill=(181, 166, 123, 255), outline=dark)
        draw.polygon([(41, 24), (48, 17), (45, 30)], fill=(181, 166, 123, 255), outline=dark)
        draw.ellipse((25, 28, 30, 33), fill=(214, 56, 39, 255), outline=dark)
        draw.ellipse((34, 28, 39, 33), fill=(214, 56, 39, 255), outline=dark)
        draw.line([(28, 38), (32, 35), (36, 38)], fill=dark, width=2)
        return
    if achievement_id.startswith("EMOTE_"):
        # Speech bubble with a tiny expressive face.
        draw.rounded_rectangle((17, 18, 47, 39), radius=6, fill=(225, 193, 112, 255), outline=dark, width=2)
        draw.polygon([(24, 38), (22, 47), (31, 39)], fill=(225, 193, 112, 255), outline=dark)
        draw.ellipse((25, 26, 29, 30), fill=dark); draw.ellipse((35, 26, 39, 30), fill=dark)
        draw.arc((28, 27, 37, 36), 10, 170, fill=(152, 39, 35, 255), width=2)
        return
    if achievement_id.startswith(("LOOT_", "GEAR_")):
        # Treasure chest / gear reward rather than an unexplained glyph.
        draw.rounded_rectangle((18, 27, 46, 44), radius=3, fill=(126, 74, 31, 255), outline=dark, width=2)
        draw.arc((18, 17, 46, 38), 180, 360, fill=(229, 170, 56, 255), width=3)
        draw.rectangle((29, 32, 35, 39), fill=(239, 195, 76, 255), outline=dark)
        draw.ellipse((30, 24, 34, 28), fill=(89, 170, 191, 255), outline=dark)
        return
    if achievement_id.startswith("META_"):
        # Meta goals use a bright eight-point star, distinct from the empty
        # pentagon placeholder used by older builds.
        draw.regular_polygon((32, 31, 15), n_sides=8, rotation=22.5, fill=gold, outline=dark)
        draw.regular_polygon((32, 31, 8), n_sides=8, rotation=22.5, fill=(215, 54, 37, 255), outline=light)
        return
    draw.regular_polygon((32, 31, 14), n_sides=8, rotation=22.5, fill=gold, outline=dark)


def draw_badge(frame: Image.Image, achievement_id: str) -> Image.Image:
    image = frame.copy()
    draw = ImageDraw.Draw(image, "RGBA")
    category = category_for(achievement_id)
    base_color = CATEGORY_COLORS[category]
    # Keep the same medallion style while giving every achievement its own
    # subtle tint variant, even when two short labels happen to collide.
    digest = hashlib.md5(achievement_id.encode("ascii")).hexdigest()
    variant_rgb = (int(digest[0:2], 16), int(digest[2:4], 16), int(digest[4:6], 16))
    color = tuple(int(channel * 0.58 + variant * 0.18) for channel, variant in zip(base_color, variant_rgb))

    # Tint the opaque center without covering the hand-painted texture.
    center_overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    center_draw = ImageDraw.Draw(center_overlay, "RGBA")
    center_draw.ellipse((17, 15, 47, 45), fill=(*color, 132))
    image = Image.alpha_composite(image, center_overlay)
    draw = ImageDraw.Draw(image, "RGBA")

    label = "" if icon_only(achievement_id) else label_for(achievement_id)
    if label:
        font = fit_font(draw, label, 31)
        box = draw.textbbox((0, 0), label, font=font, stroke_width=1)
        width = box[2] - box[0]
        height = box[3] - box[1]
        x = 32 - width / 2 - box[0]
        y = 30 - height / 2 - box[1]
        fill = (255, 235, 168, 255)
        if achievement_id == "LEVEL_59":
            fill = (255, 190, 80, 255)
            y += 1
        elif achievement_id in ("LEVEL_60", "META_100", "META_PVE_ALL"):
            fill = (255, 255, 220, 255)
        draw.text((x, y), label, font=font, fill=fill, stroke_width=2, stroke_fill=(24, 10, 4, 255))

    if icon_only(achievement_id):
        draw_symbol(draw, achievement_id)

    if achievement_id == "META_SWORD_1000":
        # Small sword emblem rendered into the medallion itself.
        draw.polygon([(32, 17), (36, 35), (32, 42), (28, 35)], fill=(190, 198, 205, 255), outline=(35, 20, 8, 255))
        draw.line([(32, 19), (32, 39)], fill=(255, 235, 150, 255), width=1)
        draw.rectangle((24, 34, 40, 37), fill=(235, 174, 52, 255), outline=(35, 20, 8, 255))
        draw.rectangle((30, 12, 34, 34), fill=(177, 112, 34, 255), outline=(35, 20, 8, 255))
        draw.ellipse((29, 9, 35, 15), fill=(255, 220, 96, 255), outline=(35, 20, 8, 255))
    elif achievement_id == "SOCIAL_GUILD":
        # Two clasped hands for Guilded.
        draw.polygon([(18, 32), (24, 25), (30, 29), (27, 35), (22, 38)], fill=(63, 105, 170, 255), outline=(28, 15, 8, 255))
        draw.polygon([(46, 32), (40, 25), (34, 29), (37, 35), (42, 38)], fill=(145, 52, 42, 255), outline=(28, 15, 8, 255))
        draw.polygon([(25, 28), (31, 27), (36, 31), (34, 35), (29, 33)], fill=(232, 169, 91, 255), outline=(45, 22, 8, 255))
        draw.polygon([(39, 28), (33, 27), (28, 31), (30, 35), (35, 33)], fill=(246, 185, 105, 255), outline=(45, 22, 8, 255))
        draw.line([(29, 31), (35, 31)], fill=(255, 225, 130, 255), width=2)
    elif achievement_id == "BAGS_FULL":
        # Two little packed pouches.
        draw.rounded_rectangle((18, 25, 31, 40), radius=3, fill=(119, 66, 30, 255), outline=(35, 17, 7, 255), width=2)
        draw.rounded_rectangle((33, 25, 46, 40), radius=3, fill=(143, 78, 32, 255), outline=(35, 17, 7, 255), width=2)
        draw.rectangle((20, 24, 29, 29), fill=(229, 167, 51, 255), outline=(55, 28, 8, 255))
        draw.rectangle((35, 24, 44, 29), fill=(242, 184, 61, 255), outline=(55, 28, 8, 255))
        draw.line([(24, 30), (24, 37)], fill=(255, 218, 110, 255), width=1)
        draw.line([(39, 30), (39, 37)], fill=(255, 218, 110, 255), width=1)
    elif achievement_id == "KILL_001":
        # Crosshair for First Blood.
        draw.ellipse((19, 19, 45, 45), outline=(224, 65, 45, 255), width=2)
        draw.line([(32, 16), (32, 48)], fill=(255, 202, 80, 255), width=2)
        draw.line([(16, 32), (48, 32)], fill=(255, 202, 80, 255), width=2)
        draw.ellipse((29, 29, 35, 35), fill=(216, 45, 35, 255), outline=(255, 224, 120, 255))

    # Level 59 gets a crooked crack through the center as the running joke.
    if achievement_id == "LEVEL_59":
        draw.line([(35, 18), (31, 25), (35, 30), (30, 39)], fill=(38, 16, 7, 235), width=2)
        draw.line([(36, 18), (32, 25), (36, 30), (31, 39)], fill=(255, 210, 92, 130), width=1)
    return image


def build_icons() -> int:
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    source = Image.open(FRAME).convert("RGBA")
    source.thumbnail((60, 60), Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    frame.alpha_composite(source, ((64 - source.width) // 2, (64 - source.height) // 2))

    values = achievement_ids()
    for achievement_id in values:
        draw_badge(frame, achievement_id).save(
            ICON_DIR / f"{achievement_id}.tga", format="TGA"
        )
    draw_badge(frame, "VA_BADGE").save(ICON_DIR / "VA_BADGE.tga", format="TGA")
    return len(values)


def envelope(t: float, duration: float) -> float:
    attack = min(1.0, t / 0.035)
    release = min(1.0, (duration - t) / 0.18)
    return max(0.0, min(attack, release))


def build_sound(
    filename: str,
    notes: list[tuple[float, float, float]],
    duration: float,
    cheer: float = 0.0,
) -> None:
    sample_rate = 22050
    rng = random.Random(filename)
    frames: list[bytes] = []
    for sample_index in range(int(sample_rate * duration)):
        t = sample_index / sample_rate
        value = 0.0
        for start, frequency, length in notes:
            local_t = t - start
            if 0 <= local_t < length:
                note_env = math.sin(math.pi * local_t / length) ** 0.65
                value += note_env * (
                    math.sin(2 * math.pi * frequency * local_t)
                    + 0.32 * math.sin(2 * math.pi * frequency * 2 * local_t)
                    + 0.12 * math.sin(2 * math.pi * frequency * 3 * local_t)
                )
        if cheer and 0.28 < t < duration - 0.08:
            crowd_env = math.sin(math.pi * (t - 0.28) / (duration - 0.36))
            noise = rng.uniform(-1, 1)
            # Slowly moving crowd-like noise rather than a harsh static burst.
            noise *= 0.55 + 0.45 * math.sin(2 * math.pi * (7 + 2 * math.sin(t * 3)) * t)
            value += cheer * crowd_env * noise
        value *= envelope(t, duration)
        value = max(-1.0, min(1.0, value * 0.22))
        frames.append(struct.pack("<h", int(value * 32767)))

    SOUND_DIR.mkdir(parents=True, exist_ok=True)
    with wave.open(str(SOUND_DIR / filename), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(sample_rate)
        output.writeframes(b"".join(frames))


def build_sounds() -> int:
    sounds = {
        "standard.wav": (
            [(0.00, 523.25, 0.35), (0.16, 659.25, 0.38), (0.33, 783.99, 0.55)],
            1.05,
            0.0,
        ),
        "level.wav": (
            [(0.00, 261.63, 0.40), (0.14, 392.00, 0.45), (0.31, 523.25, 0.70), (0.52, 659.25, 0.58)],
            1.35,
            0.08,
        ),
        "dungeon.wav": (
            [(0.00, 196.00, 0.42), (0.18, 293.66, 0.48), (0.38, 392.00, 0.78), (0.56, 493.88, 0.65)],
            1.55,
            0.20,
        ),
        "raid.wav": (
            [(0.00, 146.83, 0.52), (0.16, 220.00, 0.55), (0.36, 293.66, 0.72), (0.58, 369.99, 0.82), (0.78, 440.00, 0.85)],
            2.00,
            0.28,
        ),
        "secret.wav": (
            [(0.00, 220.00, 0.55), (0.24, 261.63, 0.58), (0.50, 311.13, 0.72)],
            1.35,
            0.0,
        ),
        "meta.wav": (
            [(0.00, 261.63, 0.50), (0.13, 329.63, 0.56), (0.27, 392.00, 0.64), (0.43, 523.25, 0.82), (0.68, 659.25, 0.75)],
            1.70,
            0.15,
        ),
    }
    for filename, (notes, duration, cheer) in sounds.items():
        build_sound(filename, notes, duration, cheer)
    return len(sounds)


if __name__ == "__main__":
    icon_count = build_icons()
    sound_count = build_sounds()
    print(f"Built {icon_count} achievement icons and {sound_count} sounds.")
