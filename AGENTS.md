# GHOST SHIFT working rules

- Use the existing checkout. Cloud tasks are isolated; do not create a Git worktree unless the user requests it.
- Explain setup and testing in Moroccan Arabic for a complete Roblox/Luau beginner.
- The user chose a fresh rebuild. Seven Luau files now implement the new game; do not describe it as an empty scaffold or require the old place before development can continue.
- Keep the original Studio game separate. Open generated `build/GHOST-SHIFT.rbxlx` as a new place. Never sync this rebuilt project into the original game or replace its scripts without separately reviewed migration.
- MapService generates the station, props and lighting at runtime. An empty edit-mode Workspace is expected; the map appears on Play.
- Rojo 7.7.1 maps GhostShift under ReplicatedStorage, ServerScriptService and StarterPlayer/StarterPlayerScripts. Preserve unknown instances at mapped boundaries, but matched instances can still be overwritten. Inspect sync proposals on a separate development place.
- Studio and Rojo CLI must run on the same Windows/macOS computer for local sync at 127.0.0.1:34872. Cloud loopback cannot be reached directly from the user's Studio.
- For local Windows Codex, prefer Studio's built-in MCP and its Quick connect option. Follow docs/CONNECT_STUDIO.ar-MA.md; verify list_roblox_studios and the target studio_id before changing the open place. Reconcile MCP edits back into Rojo source before syncing so they are preserved.
- The server owns rounds, roles, captures, cooldowns, ammo, reload and rewards. Clients request actions and render presentation. Never accept client-declared hits, winners or coin amounts.
- Validate remote types, finite vectors/numbers, range, line of sight, phase, player eligibility and request rates. Validate ProximityPrompt requests server-side too. These checks are not complete movement/physics anti-cheat.
- Current weapon is single-shot Capture Pulse: magazine six, unlimited reserve and server-owned reload. It is not an automatic rifle. Sprint is the current ghost ability. Coins/Wins/Captures are session-only; no DataStore, purchases or train event exist yet.
- Preserve working systems through small, reviewable changes. Audit dependencies and duplicate event handlers before replacing a system.
- Optional imports/studio material is private archival review only. Never automatically sync, execute, publish or force-add it to Git. Preserve original paths/classes, Disabled/Enabled and RunContext if reviewing old source.
- Keep raw place/model backups, imported source, secrets and generated builds private/ignored until reviewed. Never print credentials or request the user's Roblox password/account access.
- From the root run `bash tools/setup_cloud.sh` for pinned local Rojo/Luau tools, then `python3 tools/check_project.py` for compilation, pure round decisions and built hierarchy/source checks. Run `python3 -m unittest discover -s tests -v` for importer checks.
- Compilation, pure logic tests and Rojo builds do not execute Roblox APIs or prove gameplay. Report actual checks separately. Required Studio testing uses Test / Server & Clients with at least two clients and docs/PLAYTEST.ar-MA.md.
- Keep Moroccan Arabic docs aligned with actual code. Mark Studio/multiplayer unrun until someone actually executes them.
