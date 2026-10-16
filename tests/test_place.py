import importlib.util
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("builder", ROOT / "tools/build_place.py")
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class PlaceTests(unittest.TestCase):
    def test_generated_place_embeds_current_sources_and_valid_hierarchy(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = builder.build(Path(tmp) / "test.rbxlx")
            doc = ET.parse(target).getroot()
            self.assertEqual(doc.attrib["version"], "4")
            nodes = list(doc.iter("Item"))
            refs = [n.attrib["referent"] for n in nodes]
            self.assertEqual(len(refs), len(set(refs)))
            embedded = [n.find("Properties/ProtectedString").text for n in nodes if n.find("Properties/ProtectedString") is not None]
            expected = [p.read_text() for p in (ROOT / "src").rglob("*.luau")]
            self.assertCountEqual(embedded, expected)
            self.assertEqual(len(embedded), 4)
            ss = doc.find("Item[@class='ServerScriptService']/Item[@class='Folder']")
            self.assertIsNotNone(ss.find("Item[@class='Script']"))
            self.assertIsNotNone(ss.find("Item[@class='ModuleScript']"))
            self.assertIsNotNone(doc.find("Item[@class='StarterPlayer']/Item[@class='StarterPlayerScripts']/Item[@class='LocalScript']"))

    def test_build_is_deterministic(self):
        with tempfile.TemporaryDirectory() as tmp:
            first = builder.build(Path(tmp) / "one.rbxlx").read_bytes()
            second = builder.build(Path(tmp) / "two.rbxlx").read_bytes()
            self.assertEqual(first, second)


if __name__ == "__main__":
    unittest.main()
