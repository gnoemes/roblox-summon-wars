# Overview v0.3

**Status:** Baseline overview  
**Last updated:** 2026-03-08

---

## 1. Project Shape

This project is best described as a **social stand-based regional trio battler** built around:

- collectible fighters;
- **target-click auto-battle** with a 3-fighter trio;
- repeated combat outings called **Extractions**;
- compact regional battle spaces;
- public battle stands / combat spots;
- guided reveal of deeper systems;
- long-term fighter growth;
- account-level meta progression;
- crafting and preparation systems;
- monetization through packs, storage, boosters, convenience, and later prestige/cosmetics.

The product should prioritize:
- fast re-entry into the core loop;
- visible power spikes;
- readable progression;
- strong retention hooks;
- realistic implementation scope for a first commercial Roblox release.

---

## 2. Core Player Loop

The intended high-level loop is:

1. enter a Region;
2. go to your battle stand / combat spot;
3. choose a target or activity node;
4. fight and collect rewards;
5. gain fighter experience and account progress;
6. gather resources and cards;
7. use guidance / Recommended to discover the next useful upgrade;
8. craft consumables or equipment when needed;
9. improve fighters through leveling, Fusion, and Ascension;
10. unlock more content through regional and meta progression;
11. repeat in harder or more rewarding content.

This creates four linked loops:

- **Combat Loop** — target-click battles, trio roles, skills, statuses, tempo
- **Progression Loop** — cards, fighters, levels, Fusion, Ascension
- **Guidance Loop** — reactive prompts, regional chain, tasks, Recommended
- **Account Loop** — regions, Dungeon/Raid tracks, economy, crafting, long-term mastery

---

## 3. Core System Documents

The current baseline system set is:

| Document | Role |
|---|---|
| **combat-core-v0.3.md** | battle rules, timer/interval shell, statuses, enemy readability, persistence rules |
| **fighter-progression-v0.2.md** | fighter generation, leveling, grades, Fusion, Synergy, Tier I Ascension |
| **extractions-v0.3.md** | activity structure: Hunting Grounds, Dungeons, Raids, region/stand shell |
| **economy-resources-v0.3.md** | resource families, crafting directions, consumables, equipment economy, chest/resource split |
| **monetization-v0.3.md** | monetization layers, pricing baseline, safety rules, storage clarification |
| **meta-progression-v0.2.md** | region progression, Dungeon/Raid tracks, Bestiary |
| **stand-shell-guidance-v0.1.md** | stand layout, Guide/Fighters menus, guided reveal, social board, enemy header |

Hooks & Retention are maintained separately in **hooks-retention-v0.2.md**.

---

## 4. Combat Summary

Combat is a **target-click automatic trio battle system**.

### Core characteristics
- player squad uses **3 active fighters**;
- the player chooses the active target directly;
- the trio fights **one selected target at a time** as baseline;
- combat runs through a **timer / interval model**, not visible round sequencing;
- class identity is expressed through role and behavior, not slot position.

### Main design goal
Combat should be:
- easier to read in a 3D social shell;
- faster to re-enter;
- stronger in visible power spikes;
- readable without turning into manual action combat.

---

## 5. Stand / Shell Summary

The stand is now a formal system object.

It combines:
- **Combat access**
- **Guide / Support**
- **Social display**

### Fixed stand interaction model
- **Battle** → what to fight
- **Guide** → what to do next / how to convert progress
- **Fighters** → squad and roster management

### Fixed support menu
- Recommended
- Tasks
- Craft
- Chest

### Fixed fighters menu
- Squad
- Roster
- Fusion
- Synergy

### Product role
The stand should feel like:
- a local combat machine;
- a progression hub;
- a visible social identity object.

---

## 6. Fighter Progression Summary

Fighters are obtained through cards and developed over time.

### Fighter generation
A fighter is generated through:
1. class
2. grade
3. stat roll
4. special skill
5. subclass
6. 0–1 trait

### Fighter growth
Fighters level from 1 to 20.

Important milestones:
- **3** — special skill unlock
- **10** — class spike
- **15** — special skill modifier choice
- **20** — subclass capstone

### Long-term fighter systems
- **Fusion** — merge unwanted fighters into a chosen fighter for Ascension progress
- **Synergy** — convert 10 cards into 1 new randomized card
- **Ascension Tier I** — unlock passive/trigger bonus through long-term investment

---

## 7. Extraction Summary

Baseline Extraction types remain:
- **Hunting Grounds**
- **Dungeon**
- **Raid**

### Updated shell
Extractions now happen inside:
- **Regions**
- through **battle stands / combat spots**
- with **node-based Dungeon and Raid access**

### Identity split
- **Hunting Grounds** = comfortable low-friction farm loop
- **Dungeons** = finite chained pressure run
- **Raids** = gated high-end boss challenge

---

## 8. Economy Summary

The economy remains intentionally readable.

### Main resource families
- Meat
- Herb
- Ore
- Core
- Boss Material

### Main crafting directions
- Meat → Food
- Herb → Potions / Elixirs
- Ore → Equipment
- Core → Advanced Crafting
- Boss Material → High-End Crafting

### Important clarification
- **Chest / Stash = consumable storage**
- **Resources use a separate stack-based resource inventory**
- long-duration consumables now use **real-time duration**, not turn language

---

## 9. Meta Progression Summary

Meta progression remains the account-level layer.

### Main layers
- **Regional Progression** — primary meta system
- **Dungeon Progress Track** — guaranteed reward progress
- **Raid Progress Track** — long-term deterministic high-end progress
- **Bestiary** — background mastery by enemy type

### Updated note
Because Regions are now compact social battle spaces built around stands and nodes, Regional Progression maps directly onto:
- node access;
- encounter quality;
- recipe unlocks;
- target tier access;
- later stand-related value.

---

## 10. Guidance Summary

The project now explicitly uses **guided reveal**.

The player is not expected to self-discover every system through friction alone.

The baseline guidance stack is:
- **reactive prompts**
- **regional guidance chain**
- **repeatable tasks**
- **Recommended** as the main next-action screen

### Design goal
The game should reveal deeper systems exactly when they solve a visible problem.

---

## 11. Retention Summary

The project should retain through:
- anime-inspired presentation;
- big visible numbers;
- strong tempo / Attack Speed feel;
- reveal moments;
- rare encounter spikes;
- public stand statistics;
- visible progress bars;
- guided next steps;
- prestige and comparison later.

The game should not depend on:
- deep manual tactics;
- hidden complexity without guidance;
- slow “honest” early pacing.

---

## 12. Monetization Summary

The intended monetization pillars remain:
- Soft Currency
- Packs
- Storage
- Boosters
- Subscription
- later QoL and Cosmetics / Prestige

### Important clarification
Storage should now be read as:
- **fighter roster slots**
- **consumable chest slots**

Not:
- resource slot pressure in baseline design

This keeps monetization safer and cleaner.

---

## 13. Current Baseline Priorities

### P0
- combat core
- stand shell
- Guide / Fighters UI structure
- Hunting Grounds
- Dungeons
- basic economy/resources
- reactive prompts
- first regional guidance chain
- packs
- fighter roster storage
- chest storage
- boosters

### P0.5
- first Raid
- subscription
- Dungeon/Raid progress tracks
- stand social board polish

### P1
- Bestiary
- QoL monetization
- wider recipe/crafting depth
- prestige/cosmetics
- expanded infrastructure/meta layers
- contracts

---

## 14. What Is Still Intentionally Open

The following remain intentionally flexible:
- final balance numbers;
- exact regional content;
- exact progression pacing;
- exact first-region guidance chain steps/rewards;
- final shop tuning;
- final stand art style;
- full endgame scaling.

The system skeleton is fixed.
The live balance and production scope still require deliberate reduction and ordering.

---

## 15. Design Intent Summary

The project is designed as a layered progression game where:

- combat is readable and behavior-driven;
- deeper systems are revealed through guided friction-solving;
- stands act as combat, support, and identity objects;
- Extractions provide distinct activity loops;
- economy and crafting reinforce progression;
- meta progression adds long-term goals;
- monetization accelerates and supports rather than replacing gameplay;
- public regional play creates comparison, envy, and prestige hooks.

The intended result is:
- a commercially realistic first Roblox product;
- with strong retention hooks;
- meaningful progression;
- and a cleaner implementation target than the old over-ambitious shell.
