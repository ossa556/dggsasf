#!/usr/bin/env python3
"""Check Luau syntax, pure round decisions, and the built Rojo hierarchy."""
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
LUAU = ROOT / ".tools/luau/0.743"
ROJO = ROOT / ".tools/rojo/7.7.1/rojo"


def main():
    files = sorted((ROOT / "src").rglob("*.luau"))
    if not files:
        raise SystemExit("No game source found")
    for path in files:
        # Bytecode can be large; successful compilation is the useful result.
        subprocess.run([str(LUAU / "luau-compile"), "--binary", str(path)],
                       cwd=ROOT, stdout=subprocess.DEVNULL, check=True)
    print(f"Luau syntax: {len(files)} game scripts compiled.", flush=True)
    subprocess.run([str(LUAU / "luau"), "tests/round_rules.luau"], cwd=ROOT, check=True)
    target = ROOT / "build/GHOST-SHIFT.rbxlx"
    target.parent.mkdir(exist_ok=True)
    subprocess.run([str(ROJO), "build", "default.project.json", "--output", str(target)],
                   cwd=ROOT, check=True)
    place = ET.parse(target).getroot()
    actual = {}

    def visit(item, parent=()):
        name = item.find("Properties/string[@name='Name']")
        name = name.text if name is not None else item.get("class")
        path = (*parent, name)
        actual[path] = (item.get("class"), item)
        for child in item.findall("Item"):
            visit(child, path)

    for item in place.findall("Item"):
        visit(item)
    expected = {
        ("ServerScriptService", "GhostShift", "Main"): ("Script", "src/server/Main.server.luau"),
        ("ServerScriptService", "GhostShift", "MapService"): ("ModuleScript", "src/server/MapService.luau"),
        ("ServerScriptService", "GhostShift", "GameplayService"): ("ModuleScript", "src/server/GameplayService.luau"),
        ("ServerScriptService", "GhostShift", "RoundService"): ("ModuleScript", "src/server/RoundService.luau"),
        ("ReplicatedStorage", "GhostShift", "Config"): ("ModuleScript", "src/shared/Config.luau"),
        ("ReplicatedStorage", "GhostShift", "RoundRules"): ("ModuleScript", "src/shared/RoundRules.luau"),
        ("StarterPlayer", "StarterPlayerScripts", "GhostShift", "Main"): ("LocalScript", "src/client/Main.client.luau"),
    }
    for path, (class_name, source_file) in expected.items():
        built = actual.get(path)
        assert built is not None and built[0] == class_name, f"Incorrect Roblox script placement: {'/'.join(path)}"
        source = built[1].find("Properties/ProtectedString[@name='Source']")
        if source is None:
            source = built[1].find("Properties/string[@name='Source']")
        assert source is not None and (source.text or "") == (ROOT / source_file).read_text(encoding="utf-8"), \
            f"Built source differs from the current file: {source_file}"
    built_sources = [x for x in place.iter("Item") if x.get("class") in {"Script", "LocalScript", "ModuleScript"}]
    assert len(built_sources) == len(files), "Missing or unexpected script in the built place"
    print("Rojo hierarchy: server, client, shared modules and embedded sources verified.")
    print("Studio gameplay and multiplayer tests remain required; this check does not run Roblox.")


if __name__ == "__main__":
    main()
