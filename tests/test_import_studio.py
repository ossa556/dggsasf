import hashlib
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tools.import_studio import ImportError, import_place


PLACE = '''<roblox version="4">
  <Item class="ServerScriptService" referent="service">
    <Properties><string name="Name">ServerScriptService</string></Properties>
    <Item class="Script" referent="script-a">
      <Properties>
        <string name="Name">../../شبح/duplicate</string>
        <bool name="Disabled">true</bool><token name="RunContext">2</token>
        <Content name="LinkedSource"><null /></Content>
        <ProtectedString name="Source"><![CDATA[-- شبح\nprint("<ghost>")\n]]></ProtectedString>
      </Properties>
    </Item>
    <Item class="LocalScript" referent="script-b">
      <Properties><string name="Name">../../شبح/duplicate</string>
      <bool name="Enabled">false</bool><ProtectedString name="Source" /></Properties>
      <Item class="ModuleScript" referent="script-c">
        <Properties><string name="Name">Module</string>
        <ProtectedString name="Source">return { value = &quot;مرحبا&quot; }</ProtectedString></Properties>
      </Item>
    </Item>
    <Item class="RemoteEvent" referent="remote"><Properties><string name="Name">Capture</string></Properties></Item>
    <Item class="ProximityPrompt" referent="prompt"><Properties><string name="Name">Disguise</string></Properties></Item>
  </Item>
</roblox>'''


class StudioImportTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.input = self.root / "baseline.rbxlx"
        self.input.write_text(PLACE, encoding="utf-8")
        self.output = self.root / "imports" / "studio" / "baseline-001"

    def run_import(self):
        return import_place(self.input, self.output, repository_root=self.root)

    def test_preserves_sources_execution_metadata_and_full_inventory(self):
        result = self.run_import()
        self.assertEqual(result["script_count"], 3)
        self.assertEqual(result["instance_count"], 6)
        self.assertEqual({x["class"] for x in result["instances"]}, {
            "ServerScriptService", "Script", "LocalScript", "ModuleScript", "RemoteEvent", "ProximityPrompt"
        })
        first, second, third = result["scripts"]
        source = (self.output / first["source_file"]).read_text(encoding="utf-8")
        self.assertEqual(source, '-- شبح\nprint("<ghost>")\n')
        self.assertEqual(first["source_sha256"], hashlib.sha256(source.encode()).hexdigest())
        self.assertEqual(first["execution_properties"]["Disabled"]["value"], "true")
        self.assertEqual(first["execution_properties"]["RunContext"], {"xml_type": "token", "value": "2"})
        self.assertEqual(second["execution_properties"]["Enabled"]["value"], "false")
        self.assertEqual((self.output / second["source_file"]).read_bytes(), b"")
        self.assertEqual(third["parent_id"], second["id"])
        self.assertEqual(third["path"], ["ServerScriptService", "../../شبح/duplicate", "Module"])
        self.assertIn('name="RunContext"', (self.output / first["properties_file"]).read_text())
        self.assertEqual(json.loads((self.output / "inventory.json").read_text()), result)
        self.assertEqual(result["input_sha256"], hashlib.sha256(self.input.read_bytes()).hexdigest())

    def test_untrusted_duplicate_names_never_become_filenames(self):
        result = self.run_import()
        self.assertEqual([x["source_file"] for x in result["scripts"]], [
            "sources/000001.luau", "sources/000002.luau", "sources/000003.luau"
        ])
        self.assertEqual(len(list(self.output.rglob("*.luau"))), 3)
        self.assertFalse((self.root / "src").exists())
        self.assertNotEqual(result["scripts"][0]["id"], result["scripts"][1]["id"])

    def test_refuses_existing_output_even_if_empty(self):
        self.output.mkdir(parents=True)
        with self.assertRaises(ImportError):
            self.run_import()
        self.assertEqual(list(self.output.iterdir()), [])

    def test_rejects_invalid_xml_and_entity_without_partial_output(self):
        for contents in ["<roblox><Item>", '<!DOCTYPE roblox [<!ENTITY secret "hidden">]><roblox />', "<other />"]:
            with self.subTest(contents=contents):
                self.input.write_text(contents)
                with self.assertRaises(ImportError):
                    self.run_import()
                self.assertFalse(self.output.exists())
                self.assertFalse(self.output.parent.exists())

    def test_rejects_unresolved_or_unsupported_sources(self):
        for properties in [
            "", '<SharedString name="Source">abc</SharedString>',
            '<ProtectedString name="Source">valid</ProtectedString><Content name="LinkedSource"><url>https://example.invalid/code</url></Content>',
            '<ProtectedString name="Source">one</ProtectedString><ProtectedString name="Source">two</ProtectedString>',
        ]:
            with self.subTest(properties=properties):
                self.input.write_text(f'<roblox><Item class="Script"><Properties>{properties}</Properties></Item></roblox>')
                with self.assertRaises(ImportError):
                    self.run_import()
                self.assertFalse(self.output.exists())

    def test_rejects_binary_place_with_actionable_error(self):
        self.input = self.root / "baseline.rbxl"
        self.input.write_bytes(b"<roblox!binary")
        with self.assertRaisesRegex(ImportError, "XML .rbxlx"):
            self.run_import()
        self.assertFalse(self.output.exists())

    def test_refuses_src_or_symlink_escape(self):
        self.output = self.root / "src" / "client"
        with self.assertRaises(ImportError):
            self.run_import()
        (self.root / "imports" / "studio").mkdir(parents=True)
        (self.root / "outside").mkdir()
        (self.root / "imports" / "studio" / "escape").symlink_to(self.root / "outside", target_is_directory=True)
        self.output = self.root / "imports" / "studio" / "escape" / "snapshot"
        with self.assertRaises(ImportError):
            self.run_import()
        self.assertFalse((self.root / "src").exists())
        self.assertEqual(list((self.root / "outside").iterdir()), [])

    def test_rejects_invalid_encoding_and_size_limit(self):
        self.input.write_bytes(b"\xff\xfe")
        with self.assertRaisesRegex(ImportError, "UTF-8"):
            self.run_import()
        self.input.write_text(PLACE)
        with patch("tools.import_studio.MAX_FILE_BYTES", 10):
            with self.assertRaisesRegex(ImportError, "limit"):
                self.run_import()
        self.assertFalse(self.output.exists())

    def test_refuses_quarantine_root_symlink_into_src(self):
        (self.root / "src").mkdir()
        (self.root / "imports").mkdir()
        (self.root / "imports" / "studio").symlink_to(self.root / "src", target_is_directory=True)
        with self.assertRaisesRegex(ImportError, "symlinked components"):
            self.run_import()
        self.assertEqual(list((self.root / "src").iterdir()), [])

    def test_write_failure_cleans_stage_and_never_publishes_partial_snapshot(self):
        with patch("tools.import_studio.json.dump", side_effect=OSError("disk full")):
            with self.assertRaises(OSError):
                self.run_import()
        self.assertFalse(self.output.exists())
        self.assertEqual(list(self.output.parent.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
