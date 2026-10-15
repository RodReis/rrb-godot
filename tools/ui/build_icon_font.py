"""Recorta o Material Symbols Outlined (Apache-2.0) nos icones usados pelo Theme (F24).

Gera shared/ui/theme/fonts/font_icons.ttf (estatica: FILL 0, GRAD 0, opsz 24, wght 400 — os
padroes do CSS dos prototipos) e shared/ui/theme/icons.gd (class_name UiIcons: nome -> glifo).
O icone e um caractere de uso privado; as fontes do Launcher tem font_icons.ttf como fallback,
entao "%s VOLTAR" % UiIcons.ARROW_BACK desenha icone e texto no mesmo Label/Button.

Uso (fonte variavel nao versionada, ~10 MB, de github.com/google/material-design-icons,
pasta variablefont/):
  python tools/ui/build_icon_font.py <MaterialSymbolsOutlined[...].ttf> <....codepoints>
Icone novo: acrescente o nome em ICONS e rode de novo.
"""

import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ICONS = [
    "account_circle",
    "alt_route",
    "arrow_back",
    "arrow_forward",
    "bolt",
    "calculate",
    "check",
    "check_circle",
    "chevron_right",
    "close",
    "crisis_alert",
    "display_settings",
    "done_all",
    "emoji_events",
    "error",
    "favorite",
    "fort",
    "gamepad",
    "grass",
    "heart_broken",
    "history",
    "how_to_reg",
    "inbox",
    "info",
    "inventory_2",
    "key",
    "keyboard",
    "landscape",
    "license",
    "lock",
    "lock_open",
    "logout",
    "menu_book",
    "military_tech",
    "mouse",
    "person",
    "play_arrow",
    "power_settings_new",
    "progress_activity",
    "psychology",
    "radar",
    "restart_alt",
    "save",
    "schedule",
    "search",
    "settings",
    "shield",
    "shield_with_heart",
    "skull",
    "smart_toy",
    "speed",
    "sports_esports",
    "stars",
    "steps",
    "swap_horiz",
    "swords",
    "timer",
    "tune",
    "verified",
    "visibility",
    "visibility_off",
    "volume_up",
    "warning",
    "water_drop",
    "workspace_premium",
]
AXES = {"FILL": 0, "GRAD": 0, "opsz": 24, "wght": 400}
REPO = Path(__file__).resolve().parents[2]
FONT_OUT = REPO / "shared/ui/theme/fonts/font_icons.ttf"
GD_OUT = REPO / "shared/ui/theme/icons.gd"


def read_codepoints(path: Path) -> dict[str, int]:
    table: dict[str, int] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        name, code = line.split()
        table.setdefault(name, int(code, 16))
    return table


def build_font(source: Path, codes: list[int]) -> None:
    font = instancer.instantiateVariableFont(TTFont(source), AXES)
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.notdef_outline = True
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=codes)
    subsetter.subset(font)
    font.save(FONT_OUT)


def write_gd(table: dict[str, int]) -> None:
    lines = [
        "class_name UiIcons",
        "extends RefCounted",
        "## Glifos do Material Symbols Outlined em shared/ui/theme/fonts/font_icons.ttf (F24).",
        "## GERADO por tools/ui/build_icon_font.py: nao edite a mao. As fontes do Launcher tem a",
        "## de icones como fallback: use o glifo dentro do texto de qualquer Label ou Button.",
        "",
    ]
    for name in ICONS:
        lines.append(f'const {name.upper()}: String = "\\u{table[name]:04x}"')
    GD_OUT.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    table = read_codepoints(Path(sys.argv[2]))
    missing = [name for name in ICONS if name not in table]
    if missing:
        sys.exit(f"icones sem codepoint: {missing}")
    build_font(Path(sys.argv[1]), [table[name] for name in ICONS])
    write_gd(table)
    print(f"{FONT_OUT.name}: {FONT_OUT.stat().st_size} bytes, {len(ICONS)} icones")


if __name__ == "__main__":
    main()
