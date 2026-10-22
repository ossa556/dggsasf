#!/usr/bin/env python3
"""Extract a Roblox XML place for review; never execute or synchronize its code."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
MAX_FILE_BYTES = 128 * 1024 * 1024
MAX_INSTANCES = 100_000
MAX_DEPTH = 256
SCRIPT_CLASSES = {"Script", "LocalScript", "ModuleScript"}
EXECUTION_PROPERTIES = ("Disabled", "Enabled", "RunContext", "LinkedSource")


class ImportError(ValueError):
    """A place cannot be imported without losing or misrepresenting information."""


def _properties(item: ET.Element) -> dict[str, ET.Element]:
    result: dict[str, ET.Element] = {}
    element = item.find("Properties")
    if element is not None:
        for value in element:
            name = value.get("name")
            if name is not None:
                if name in result:
                    raise ImportError("An instance has duplicate XML properties; import stopped.")
                result[name] = value
    return result


def _target(output: Path, repository_root: Path) -> Path:
    root = repository_root.resolve()
    quarantine_path = root / "imports" / "studio"
    quarantine = quarantine_path.resolve()
    destination = output.resolve()
    if quarantine != quarantine_path:
        raise ImportError("imports/studio must use a real directory path, without symlinked components.")
    if destination == quarantine or not destination.is_relative_to(quarantine):
        raise ImportError("Choose a NEW --output directory inside imports/studio, never src.")
    if destination.exists() or output.is_symlink():
        raise ImportError("Output already exists; choose a new snapshot name. Nothing was overwritten.")
    return destination


def import_place(
    input_path: Path, output_path: Path, *, repository_root: Path = REPOSITORY_ROOT
) -> dict:
    """Create a new quarantine snapshot, or leave no output snapshot on failure."""
    destination = _target(output_path, repository_root)
    if input_path.suffix.lower() != ".rbxlx":
        raise ImportError("Use an XML .rbxlx place. In Studio, Save to File and select .rbxlx; binary .rbxl is unsupported.")
    with input_path.open("rb") as source_file:
        raw = source_file.read(MAX_FILE_BYTES + 1)
    if len(raw) > MAX_FILE_BYTES:
        raise ImportError("Place exceeds the 128 MiB import limit; export a smaller review copy.")
    try:
        document = raw.decode("utf-8-sig")
    except UnicodeDecodeError as error:
        raise ImportError("Expected UTF-8 Roblox XML; re-save the place as .rbxlx in Studio.") from error
    if re.search(r"<!\s*(?:DOCTYPE|ENTITY)\b", document, re.IGNORECASE):
        raise ImportError("XML document types and entities are unsupported; import stopped.")
    try:
        root = ET.fromstring(document)
    except ET.ParseError as error:
        raise ImportError("Invalid XML; re-save the place as .rbxlx in Studio.") from error
    if root.tag != "roblox":
        raise ImportError("Expected a Roblox XML place with a <roblox> root.")

    instances: list[dict] = []
    scripts: list[dict] = []
    files: list[tuple[str, str]] = []
    pending = [(item, [], []) for item in reversed(root.findall("Item"))]
    while pending:
        item, parent_path, parent_ids = pending.pop()
        if len(instances) >= MAX_INSTANCES or len(parent_path) >= MAX_DEPTH:
            raise ImportError("Place exceeds the instance count or depth limit; export a smaller review copy.")
        class_name = item.get("class")
        if not class_name:
            raise ImportError("An instance is missing its class; import stopped.")
        properties = _properties(item)
        name_element = properties.get("Name")
        name = (name_element.text or "") if name_element is not None else class_name
        instance_id = len(instances) + 1
        path = [*parent_path, name]
        ancestry = [*parent_ids, instance_id]
        record = {
            "id": instance_id,
            "parent_id": parent_ids[-1] if parent_ids else None,
            "ancestry_ids": ancestry,
            "referent": item.get("referent"),
            "class": class_name,
            "name": name,
            "name_defaulted_to_class": name_element is None,
            "path": path,
        }
        instances.append(record)
        if class_name in SCRIPT_CLASSES:
            linked = properties.get("LinkedSource")
            if linked is not None and "".join(linked.itertext()).strip():
                raise ImportError("A script uses external LinkedSource; resolve its source in a separate Studio copy before import.")
            source = properties.get("Source")
            if source is None or source.tag not in {"ProtectedString", "string"} or len(source):
                raise ImportError("A script has missing or unsupported Source encoding; re-save editable source in Studio before import.")
            text = source.text or ""
            file_id = f"{len(scripts) + 1:06d}"
            source_path = f"sources/{file_id}.luau"
            properties_path = f"properties/{file_id}.properties.xml"
            full_properties = item.find("Properties")
            assert full_properties is not None
            files.extend([
                (source_path, text),
                (properties_path, ET.tostring(full_properties, encoding="unicode")),
            ])
            scripts.append({
                **record,
                "source_file": source_path,
                "properties_file": properties_path,
                "source_sha256": hashlib.sha256(text.encode("utf-8")).hexdigest(),
                "execution_properties": {
                    key: {"xml_type": properties[key].tag, "value": "".join(properties[key].itertext())}
                    for key in EXECUTION_PROPERTIES if key in properties
                },
            })
        pending.extend((child, path, ancestry) for child in reversed(item.findall("Item")))

    inventory = {
        "format_version": 1,
        "input_file_name": input_path.name,
        "input_sha256": hashlib.sha256(raw).hexdigest(),
        "instance_count": len(instances),
        "script_count": len(scripts),
        "source_encoding": "UTF-8; XML newline normalization applies",
        "purpose": "Review-only snapshot; not a Rojo project or complete place backup.",
        "instances": instances,
        "scripts": scripts,
    }
    # Parse and validate everything before creating any output directory.
    destination.parent.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix=".studio-import-", dir=destination.parent))
    reserved = False
    try:
        for relative_path, contents in files:
            target = stage / relative_path
            target.parent.mkdir(parents=True, exist_ok=True)
            with target.open("w", encoding="utf-8", newline="") as handle:
                handle.write(contents)
        with (stage / "inventory.json").open("w", encoding="utf-8", newline="\n") as handle:
            json.dump(inventory, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
        # Exclusive reservation prevents another importer or pre-existing empty
        # directory from being overwritten. Only our own empty directory is replaced.
        destination.mkdir()
        reserved = True
        stage.replace(destination)
        reserved = False
    finally:
        if reserved:
            destination.rmdir()
        if stage.exists():
            shutil.rmtree(stage)
    return inventory


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("place", type=Path, help="Studio XML .rbxlx file")
    parser.add_argument("--output", type=Path, required=True, help="New directory under imports/studio")
    args = parser.parse_args()
    try:
        inventory = import_place(args.place, args.output)
    except (ImportError, OSError) as error:
        # Never print XML or extracted script source, including parser excerpts.
        parser.exit(1, f"Import stopped: {error}\n")
    print(f"Imported {inventory['script_count']} scripts and inventoried {inventory['instance_count']} instances. No code was executed or synchronized.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
