# Economy & Resources v0.3

**Status:** Fixed baseline  
**Last updated:** 2026-03-08

---

## 1. Purpose

This document fixes the economy/resource baseline after the stand/guidance integration pass.

It covers:
- economic layers;
- resource families;
- crafting directions;
- consumables and equipment roles;
- chest/resource storage split;
- timed consumable logic.

This document does **not** finalize:
- exact drop rates by region;
- final soft-currency pricing;
- exact recipe costs;
- final region-specific loot tables;
- final live balancing of buff values.

---

## 2. Core Economy Philosophy

The economy is intentionally designed to avoid:
- too many currencies;
- too many one-off resources;
- overly complex crafting chains;
- heavy profession grinding.

The intended structure remains:
- a small number of resource families;
- each family existing in the same five grades used elsewhere in the game;
- crafting as a support layer;
- clear links between activity type and reward type.

### Updated direction
Because the game loop is now:
- denser;
- faster;
- more repeated;
- more public/social;

the economy must also feel:
- faster to collect;
- faster to convert into useful value;
- more obviously connected to combat performance.

---

## 3. Main Economic Layers

| Layer | What it is | Main role |
|---|---|---|
| **Base Currency** | universal soft currency | shop, services, part of crafting |
| **Resource Families** | meat, herb, ore, core, boss material | food, potions, equipment, advanced recipes |
| **Fighter Cards** | separate progression economy | fighters, Fusion, Synergy, Ascension |
| **Equipment** | item layer with 3 slots | build support and specialization |
| **Consumables** | food, elixirs, potions | preparation and run support |
| **Chest** | consumable storage | stock for auto-use systems |

### Important clarification
Resources are **not** baseline chest-slot items.
They use a separate stack-based **Resource Inventory**.

---

## 4. Resource Naming Rule

**Resource Name = Grade + Resource Type**

Examples:
- Common Herb
- Rare Meat
- Epic Ore
- Legendary Core

---

## 5. Resource Grades

| Grade | Color |
|---|---|
| **Common** | White |
| **Uncommon** | Green |
| **Rare** | Blue |
| **Epic** | Purple |
| **Legendary** | Gold |

---

## 6. Resource Families

## 6.1 Meat
Main use:
- food crafting;
- sustain-focused preparation;
- long-duration buffs.

## 6.2 Herb
Main use:
- potion crafting;
- cleansing items;
- offensive/defensive alchemical effects.

## 6.3 Ore
Main use:
- equipment crafting;
- equipment upgrades;
- crafting components.

## 6.4 Core
Main use:
- advanced crafting;
- magical recipes;
- stronger equipment and consumables.

## 6.5 Boss Material
Main use:
- unique/high-end recipes;
- raid-value crafting;
- stronger progression hooks.

---

## 7. Resource Sources by Extraction Type

| Extraction Type | Main economic role |
|---|---|
| **Hunting Grounds** | stable source of Meat, Herb, Ore, base currency, easy XP |
| **Dungeons** | stronger resource density, Core access, better value than Hunting Grounds |
| **Raids** | Boss Materials, high-grade resources, unique progression drops |

### Design Rule
A single session should often advance:
- XP;
- resources;
- base currency;
- card/fighter progress;
- regional progress;
- possible node progress;
- possible rare encounter value.

The player should rarely feel:
- “I fought and nothing meaningful happened.”

---

## 8. Crafting Philosophy

Crafting exists to transform Extraction rewards into useful progression tools.

### Intended functions
- turn farmed materials into preparation items;
- support Dungeons and Raids;
- create value for repeated farming;
- enable gear progression and build support.

### Not intended
- full profession leveling;
- large multi-step production chains;
- mandatory micromanagement.

### Fixed Rule
If the player has the recipe and the resources, the item can be crafted.

---

## 9. Crafting Directions

### Meat → Food
Food provides long-duration buffs.

### Herb → Potions / Elixirs
Herb supports alchemical preparation.

### Ore → Equipment
Ore remains the primary base family for equipment crafting.

### Core → Advanced Crafting
Core enables:
- magical item recipes;
- stronger consumables;
- advanced equipment.

### Boss Material → High-End Crafting
Boss Material exists for:
- unique equipment;
- top-tier items;
- raid-value recipes.

---

## 10. Consumables

Consumables use a unified auto-use philosophy.
They do not require per-fighter manual micromanagement.

### Fixed consumable loadout baseline
- **1 Food slot**
- **1 Elixir slot**
- **2 Potion slots**

Consumables are used directly from the **Chest / Stash**.
If the chest has no remaining stock, no auto-use happens.

---

## 11. Consumable Categories

## 11.1 Food
Food is a long-duration party-wide buff.

### Auto-use rule
If the party no longer has the food buff and stocked food exists, the equipped food is auto-used again.

### Important rule
Food duration refreshes to its full duration.
It does not stack above the cap.

### Baseline food durations
| Grade | Duration |
|---|---:|
| **Common** | 10 min |
| **Uncommon** | 12 min |
| **Rare** | 15 min |
| **Epic** | 18 min |
| **Legendary** | 22 min |

### Baseline food types
- HP Food
- Speed Food
- EXP Food

### Player-facing direction
Prefer:
- **Speed / Attack Speed / Tempo**
over Initiative language.

---

## 11.2 Elixirs
Elixirs are long-duration party-wide magical buffs.

### Auto-use rule
If the party no longer has the elixir buff and stocked elixir exists, the equipped elixir is auto-used again.

### Important rule
Elixir duration refreshes to its full duration.
It does not stack above the cap.

### Baseline elixir durations
| Grade | Duration |
|---|---:|
| **Common** | 10 min |
| **Uncommon** | 12 min |
| **Rare** | 15 min |
| **Epic** | 18 min |
| **Legendary** | 22 min |

---

## 11.3 Potions
Potions are situational auto-trigger items.

### Examples
- healing
- cleansing
- anti-status
- emergency survival tools

Potions remain condition-based auto-use consumables rather than long timed buffs.

---

## 12. Chest / Stash

### Fixed Rule
The Chest / Stash stores **consumables only**.

### Baseline storage
- **10 slots** by default
- expandable later

### Important rule
The player is responsible for keeping stock available.
If a consumable is out of stock, it is simply not used.

### Clarification
Resources do **not** consume chest slots in baseline design.

---

## 13. Resource Inventory

Resources use a separate stack-based **Resource Inventory**.

### Purpose
- avoid toxic baseline storage pressure on raw materials;
- keep chest pressure focused on consumables;
- preserve readable crafting flow.

### Design Rule
Baseline monetization should not depend on raw resource slot pain.

---

## 14. Equipment

Equipment supports builds without drowning the game in loot clutter.

### Baseline equipment slots
- **Weapon**
- **Body**
- **Amulet**

### Future optional slots
- Helmet
- Ring

These remain non-baseline.

---

## 15. Equipment Slot Roles

| Slot | Main role | Typical bonuses |
|---|---|---|
| **Weapon** | offensive identity | Damage, Accuracy, Crit Chance, Crit Damage, offensive passive |
| **Body** | survivability | HP, Defense, Evasion, Resist, defensive passive |
| **Amulet** | utility / build support | Speed, hybrid support, utility passive, situational bonuses |

### Updated Direction
Because the new combat shell values tempo and visible spikes more, the equipment system should comfortably support:
- Attack Speed
- crit pressure
- visible burst identity
- role compensation

---

## 16. Equipment Grades

| Grade | Typical role |
|---|---|
| **Common** | basic stats |
| **Uncommon** | slightly better stats |
| **Rare** | strong stats, focused specialization |
| **Epic** | strong stats, possible passive |
| **Legendary** | strong stats, guaranteed passive |

---

## 17. Equipment Passives

High-end equipment may grant passives.

### Design Rule
Passives should:
- strengthen a build;
- support a role;
- close a weakness;
- create tactical variety.

Passives should not:
- replace class identity;
- turn the fighter into another class;
- dominate the whole combat system.

---

## 18. Main Economic Sinks

| Sink | Spent on | Spends |
|---|---|---|
| **Shop** | packs, services | base currency |
| **Food crafting** | party preparation | Meat + base currency |
| **Potion/Elixir crafting** | run support | Herb + base currency |
| **Equipment crafting** | build progression | Ore/Core/Boss Material + base currency |
| **Preparation for harder content** | better runs | crafted items + resources |

---

## 19. What Baseline Economy Intentionally Avoids

The baseline economy avoids:
- too many unique resource names;
- too many separate currencies;
- profession leveling;
- excessive recipe chains;
- too many equipment slots;
- large-scale loot clutter;
- raw-resource slot pain as a primary monetization lever.

---

## 20. Fixed vs Open

### Fixed in this document
- economy uses a small set of resource families
- resource naming follows grade + type
- crafting has no baseline profession leveling
- Chest / Stash stores consumables only
- Resources use separate stack-based resource inventory
- baseline equipment slots are Weapon, Body, and Amulet
- consumables use chest stock and auto-use logic
- baseline consumable loadout is 1 Food, 1 Elixir, 2 Potions
- food and elixirs are party-wide long timed buffs
- potions are situational built-in auto-use items
- Speed / Attack Speed is preferred over Initiative in player-facing language

### Open for later iteration
- exact recipe costs
- exact drop rates by region
- final region-specific resource mapping
- event resources
- expanded equipment system
- advanced unique passives
- final soft-currency pricing
- exact timed-duration values after testing

---

## 21. Design Intent Summary

The economy is meant to support the rest of the game, not replace it.

The intended flow is:
- farm in Hunting Grounds for reliable basics;
- enter Dungeons for stronger run-based value;
- challenge Raids for unique and high-end materials;
- convert gathered resources into consumables and equipment;
- use those tools to progress into harder content.

The updated requirement is:
- this loop must feel faster, more layered per fight, and more obviously useful inside the stand/node shell.
