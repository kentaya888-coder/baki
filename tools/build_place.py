#!/usr/bin/env python3
"""Build a self-contained Roblox XML place from the checked-in Luau sources."""
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def build(destination=None):
    doc = ET.Element("roblox", {"version": "4"})
    counter = 0

    def item(parent, kind, name, source=None, properties=None):
        nonlocal counter
        counter += 1
        node = ET.SubElement(parent, "Item", {"class": kind, "referent": f"RBX{counter}"})
        props = ET.SubElement(node, "Properties")
        ET.SubElement(props, "string", {"name": "Name"}).text = name
        if source:
            ET.SubElement(props, "ProtectedString", {"name": "Source"}).text = (ROOT / source).read_text()
        for tag, key, value in properties or []:
            ET.SubElement(props, tag, {"name": key}).text = value
        return node

    item(doc, "Workspace", "Workspace", properties=[("bool", "StreamingEnabled", "false")])
    item(doc, "Lighting", "Lighting")
    rs = item(doc, "ReplicatedStorage", "ReplicatedStorage")
    shared = item(rs, "Folder", "Baki")
    item(shared, "ModuleScript", "Config", "src/shared/Config.luau")
    ss = item(doc, "ServerScriptService", "ServerScriptService")
    server = item(ss, "Folder", "BakiServer")
    item(server, "ModuleScript", "World", "src/server/World.luau")
    item(server, "Script", "Main", "src/server/Main.server.luau")
    starter = item(doc, "StarterPlayer", "StarterPlayer")
    scripts = item(starter, "StarterPlayerScripts", "StarterPlayerScripts")
    item(scripts, "LocalScript", "BakiClient", "src/client/Controller.client.luau")
    item(doc, "StarterGui", "StarterGui")
    destination = Path(destination or ROOT / "BAKI-Underground.rbxlx")
    ET.indent(doc)
    ET.ElementTree(doc).write(destination, encoding="utf-8", xml_declaration=True)
    return destination


if __name__ == "__main__":
    print(build())
