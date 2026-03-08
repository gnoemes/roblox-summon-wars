# Extractions v0.3

**Status:** Fixed baseline  
**Last updated:** 2026-03-08

---

## 1. Purpose

This document fixes the baseline structure for **Extractions** after the stand-shell clarification pass.

It defines:
- what an Extraction is now;
- how Extractions fit the regional stand shell;
- which Extraction types remain baseline;
- how state carries between encounters;
- what each Extraction type is for;
- how entry, failure, and exit behave.

This document does **not** finalize:
- final region art/layout;
- exact regional reward tables;
- final economy values;
- final first-region guidance chain steps;
- final UI art treatment.

---

## 2. Core Term

### Extraction
An Extraction is a selected combat activity run.

Baseline Extraction types:
- **Hunting Grounds**
- **Dungeon**
- **Raid**

Contracts remain a future layer, not baseline.

---

## 3. Updated World Shell

The updated shell is:

- **Main Hub**
- **Regions**
- **Battle Stand / Combat Spot**
- **Node-based activities**

### Region
A Region is a compact social battle space.

It is:
- a themed combat environment;
- a regional mini-hub;
- a public comparison space;
- the place where players run their stands and compare visible progress.

### Battle Stand / Combat Spot
Each player uses one main regional combat stand.

From this stand, the player can:
- run Hunting Grounds;
- choose a farming target or farming mode;
- activate Dungeon content;
- activate Raid content;
- display social statistics;
- access Guide / Fighters shell.

### Important Direction
The preferred structure is:
- **one main farming stand**
- **UI-driven target/mode selection**
- **node-based escalation into Dungeon and Raid content**
- **support/guidance layered onto the same stand shell**

---

## 4. Baseline Extraction Types

## 4.1 Hunting Grounds

### Core Role
Targeted, repeatable, low-friction farming.

### Purpose
Hunting Grounds let the player repeatedly farm:
- specific enemies;
- specific drops;
- basic resources;
- easy experience.

### Updated Structure
The player uses their battle stand and selects:
- a specific target;
- or a farming mode mapped to a target pool.

After each victory:
- experience and drops are granted;
- the next encounter starts immediately;
- the loop continues until the player changes target/mode or exits.

### State Between Encounters
Each Hunting Grounds encounter starts fresh.

#### Fixed rule
- **HP fully restores**
- **cooldowns reset**
- **encounter-only temporary buffs reset**
- **encounter-only temporary debuffs reset**
- **the next fight starts clean**

### Important clarification
Long-duration timed prep buffs such as Food and Elixir are **not** forcibly wiped between Hunting Grounds encounters.
They continue until their duration expires.

### Identity
Hunting Grounds are:
- the comfortable farming loop;
- the default grind shell;
- the content most suitable for repeated fast sessions.

They are **not** meant to feel like a dangerous run.

### Rare Replacements
Rare encounter logic may exist in Hunting Grounds, such as:
- treasure chest;
- elite enemy;
- rare regional enemy;
- mini-boss.

### Baseline Priority
**P0**

---

## 4.2 Dungeon

### Core Role
A finite chained run with increasing pressure and better rewards.

### Purpose
Dungeons:
- escalate difficulty;
- provide more value than Hunting Grounds;
- test trio building and preparation;
- bridge the player toward harder content.

### Updated Structure
A Dungeon is a **node-based chained activity**.

This means:
- the player activates a Dungeon node;
- the run happens as a sequence of encounters or waves;
- corridor-heavy traversal is not required for baseline implementation;
- the run has a beginning and an end.

### State Between Encounters
#### Fixed rule
- **current HP is preserved**
- **dead fighters stay dead**
- **cooldowns reset between encounters**
- **encounter-only temporary buffs reset**
- **encounter-only temporary debuffs reset**
- **encounter state resets**
- long-duration timed prep buffs may remain

### Identity
A Dungeon is:
- a pressure run;
- a chained combat sequence;
- a preparation-sensitive activity.

### Entry Conditions
Dungeons may require:
- item/key;
- progression unlock;
- previous completion requirement;
- recommended or minimum squad power.

### Baseline Priority
**P0**

---

## 4.3 Raid

### Core Role
High-end, gated combat objective with unique value.

### Purpose
Raids are difficult prepared encounters intended to provide:
- high-end progression goals;
- unique drops;
- stronger reward ceilings;
- raid-focused materials;
- prestige value.

### Updated Structure
A Raid is a **node-based boss activity**.

This means:
- the player activates a Raid node;
- the content may be a hard boss, a phased boss, or a boss-chain format;
- the content is focused, not corridor-dependent;
- the player is expected to enter prepared.

### State Between Encounters / Stages
#### Fixed rule
- **current HP is preserved**
- **dead fighters remain unavailable**
- **cooldowns reset between stages/encounters**
- **encounter-only temporary buffs reset**
- **encounter-only temporary debuffs reset**
- **encounter state resets between major segments**
- long-duration timed prep buffs may remain if still active

### Identity
A Raid is:
- a preparation-heavy challenge;
- a high-end reward target;
- a prestige activity;
- the hardest baseline Extraction type.

### Entry Conditions
Raids always require a meaningful gate.

Valid examples:
- completion of a specific Dungeon;
- possession of a specific item or crafted entry resource;
- progression milestone;
- recommended/minimum squad power requirement.

### Baseline Priority
**Late P0 / P0.5**

Early versions are still expected to have at most:
- **one raid**.

---

## 4.4 Contracts

### Status
Contracts are still **not baseline** for the first Extraction layer.

### Reason
Contracts add:
- condition systems;
- separate UI;
- reward tables;
- task generation logic.

They should be introduced only after the core Extraction loop is proven.

### Baseline Priority
**P1**

---

## 5. Reward Roles by Extraction Type

| Extraction Type | Main reward role |
|---|---|
| **Hunting Grounds** | stable targeted farming |
| **Dungeon** | stronger run value and mid-tier progression |
| **Raid** | unique/high-end progression and prestige value |

### Design Rule
The activity types must feel mechanically and economically different, not like cosmetic variants of the same fight.

---

## 6. Entry Rules

### Hunting Grounds
- always available;
- no key required;
- no hard gate required;
- may still show recommended squad power.

### Dungeons
- may require entry conditions;
- may use recommended or minimum squad power;
- may require a key or progression unlock.

### Raids
- always require a meaningful gate;
- are not freely always available by default;
- should feel earned and prepared for.

---

## 7. Squad Power

### Purpose
Squad Power is a coarse indicator used to:
- communicate difficulty;
- guide players toward suitable content;
- support soft or hard entry gating.

### Usage
Activity selection may show:
- **Recommended Squad Power**
- optionally **Minimum Squad Power**

### Design Rule
Squad Power is a guidance/gating tool, not a guarantee of victory.

---

## 8. Combat Flow Inside Extractions

The shared core combat loop across Extractions is:

1. encounter begins;
2. trio fights the current enemy encounter;
3. on victory:
   - drops are granted,
   - experience is granted,
   - the next encounter or repeated target appears;
4. state resets according to Extraction rules;
5. the loop continues until exit, completion, or defeat.

### Important Distinction
This shared loop does **not** make all Extraction types equivalent.

The distinction still comes from:
- what resets and what persists;
- how rewards are structured;
- whether the activity is open-ended or finite;
- whether entry is free or gated;
- how much preparation matters.

---

## 9. Exit and Failure Rules

### Escape / Manual Exit
The player may exit combat without added fail penalties.

#### Result by Extraction Type
- **Hunting Grounds:** leaves the current farming loop
- **Dungeon:** ends the run
- **Raid:** ends the run

### Defeat
When all three fighters are dead:
- the current Extraction attempt ends;
- the result is treated as a failed run / forced exit.

### Baseline Rule
There are **no defeat penalties** such as:
- injury systems;
- corruption;
- long fail-state punishment.

---

## 10. Extraction State Persistence Summary

| Extraction Type | HP Between Encounters | Cooldowns | Encounter-only Buffs/Debuffs | Long-duration Prep Buffs | Encounter State |
|---|---|---|---|---|---|
| **Hunting Grounds** | Fully restored | Reset | Reset | Persist by time | Reset |
| **Dungeon** | Preserved | Reset | Reset | Persist by time | Reset |
| **Raid** | Preserved | Reset | Reset | Persist by time | Reset |

This is one of the most important identity rules in the Extraction system.

---

## 11. Preparation and Consumables

Because Dungeons and Raids preserve HP across the full run, preparation matters more there than in Hunting Grounds.

This creates natural value for:
- healing consumables;
- anti-status consumables;
- pre-run food buffs;
- temporary battle enhancers;
- crafted support items.

### Baseline Rule
Preparation should feel:
- optional and helpful in Hunting Grounds;
- valuable in Dungeons;
- strongly relevant in Raids.

---

## 12. Extraction Selection UX

The player should access Extraction choice through the stand shell.

For every Extraction / target choice, the player must be able to see:
- type of Extraction;
- recommended squad power;
- any minimum squad power;
- entry condition;
- expected reward identity;
- access status.

### Updated UX direction
A practical early implementation should favor:
- stand interaction;
- target/mode cards;
- node cards for Dungeon / Raid;
- social visibility without requiring full-screen isolated menus every time.

---

## 13. Regions

A Region may contain:
- one player stand per player;
- Hunting Grounds target selection on that stand;
- one or more Dungeon nodes;
- one Raid node;
- region-linked drops and economy loops.

### Important Note
Detailed region economy, art treatment, and exact encounter variety are still fixed elsewhere.

---

## 14. Fixed vs Open

### Fixed in this document
- Extraction remains the umbrella term for combat activity runs
- baseline Extraction types remain Hunting Grounds, Dungeon, and Raid
- Contracts are postponed
- stands are the main local launch point for Extractions
- Hunting Grounds are always available and reset fully between fights
- Dungeons preserve HP but reset encounter-only combat state
- Raids preserve HP but reset encounter-only combat state between major stages
- long-duration prep buffs use timed persistence across Extractions
- Dungeons may require entry conditions
- Raids always require meaningful gates
- no baseline defeat penalties
- manual exit is allowed
- leaving a Dungeon or Raid ends the run
- Squad Power is used as a recommendation/gating indicator
- Regions use battle stands and node-based activity structure

### Open for later iteration
- exact rare encounter tables in Hunting Grounds
- event rotations
- contract system details
- exact reward economy values
- final UI art treatment
- precise raid structure beyond baseline direction
- exact region-node counts

---

## 15. Design Intent Summary

The Extraction system is designed to create three clearly different activity loops:

### Hunting Grounds
Comfortable, repeatable, targeted farming.

### Dungeons
Finite progression runs with increasing pressure and preserved attrition.

### Raids
Prepared high-end challenges with unique value and strong gating.

The updated shell exists to make:
- combat faster to enter;
- activities easier to read;
- regions more social;
- stand ownership clearer;
- content production more realistic.
