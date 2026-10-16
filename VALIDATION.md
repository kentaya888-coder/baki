# Validation

Checks executed in the cloud workspace:

- Four Luau files compiled successfully with the official `luau-lang/luau` compiler, source commit `9d7748a4f324213a18cb8283fa2a77c330225fa0`.
- Python unittest: 2 tests passed. Checks cover XML hierarchy, unique references, exact embedding of all source files, and deterministic builds.
- All enum references checked against Roblox Client Tracker's API dump from `MaximumADHD/Roblox-Client-Tracker`, branch `roblox`.
- Generated `BAKI-Underground.rbxlx` with Python 3; no third-party Python packages required.

These are compilation and packaging checks, not Roblox gameplay tests. Roblox Studio/Engine is unavailable in this cloud machine. NPC movement, combat feel, collision, avatar animations, controller/mobile layout, multiplayer behavior and performance remain unverified in the engine. Follow the Studio checklist in README before publishing. No game was uploaded or published.

Reference access: HTTP requests to the supplied Roblox game URL and Roblox metadata APIs were rejected by the environment proxy (403). The scene is an original martial-arts prototype, not a verified recreation of Ryujin.
