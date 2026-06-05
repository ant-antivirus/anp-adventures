# ANP Adventures Development Rules

## Code

- Use Luau
- Use ModuleScripts
- Prefer reusable systems
- No hardcoded NPC names
- No hardcoded Quest IDs

## Architecture

- Client / Server separation
- Services pattern
- Modular design

## Gameplay

Every quest must support:

- Solo Play
- Multiplayer Co-op

If a multiplayer mechanic exists:

Proton Companion must be able to assist solo players.

## Characters

Atom = Leader

Neutron = Scientist

Proton = AI Guide

Character personalities must remain consistent with Character Bible.

## UI

- Mobile Friendly
- Gamepad Friendly
- PC Friendly

## Save Data

Use Roblox DataStoreService.

All progression must be persistent.