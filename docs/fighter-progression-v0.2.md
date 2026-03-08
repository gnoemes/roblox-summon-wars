# Fighter Progression v0.2

**Status:** Fixed baseline  
**Last updated:** 2026-03-08

---

## 1. Purpose

This document fixes the baseline progression system for fighters after the combat and world-shell update.

It covers:

- how fighter cards are obtained;
- how a fighter is generated from a card;
- grades and colors;
- levels and milestone progression;
- traits;
- enhancement through **Fusion**;
- recycling through **Synergy**;
- Tier I Ascension;
- baseline shop pack structure;
- baseline stat generation and level growth.

This document does **not** finalize:
- exact balance values for all future skills;
- late Ascension tiers;
- economy tuning by live data;
- event packs or limited-time monetization details.

---

## 2. Core Terms

### Fighter
A generated unit that can be placed into the player's roster and active trio.

### Class
The fighter's primary combat role.

### Subclass
The fighter's specialization inside its class.  
Subclass is determined by the fighter's generated **special skill**.

### Special Skill
The fighter's unique defining combat skill.  
It is visible from level 1 and unlocks for active use at level 3.

### Trait
An optional passive modifier on the fighter.  
Traits may be:
- positive;
- compromise-based (one upside, one downside).

A fighter may have:
- **0 or 1 trait**

### Grade
The fighter's rarity tier.

### Fusion
A progression mechanic where selected fighters are merged into a chosen target fighter to grant **Ascension points**.

### Synergy
A recycling mechanic where **10 cards** are combined into **1 new card** with a randomized grade result within defined rules.

### Ascension
A long-term fighter progression layer.  
Only **Tier I** is considered baseline in this document.

---

## 3. Grades and Colors

The progression system uses the following fixed grades:

| Grade | Color |
|---|---|
| **Common** | White |
| **Uncommon** | Green |
| **Rare** | Blue |
| **Epic** | Purple |
| **Legendary** | Gold |

### Updated Design Rule
Grades are no longer meant to feel like minor statistical steps.

A higher-grade fighter should often feel:
- noticeably stronger;
- more active in combat;
- faster or more explosive;
- more immediately valuable in the trio.

The rarity ladder must support:
- stronger visible combat spikes;
- stronger emotional payoff;
- stronger social readability.

---

## 4. Card Acquisition

Fighters are obtained only through **cards**.

Cards may come from:
- shop packs;
- activity rewards;
- combat drops;
- bosses;
- events;
- online/activity systems;
- contracts (as pack/card rewards);
- Synergy results.

### Design Rule
Drops from combat and activities produce **cards**, not fully spawned fighters directly.

This preserves:
- reveal moments;
- collection rhythm;
- comparison value;
- delayed dopamine from opening.

---

## 5. Progression Sources by Game Stage

## Early Game
Main sources:
- shop;
- drops;
- activity / online / event rewards;
- occasional Synergy use.

## Mid Game
Main sources:
- drops;
- bosses;
- activity / online / event rewards;
- Synergy becomes more relevant.

## Late Game
Main sources:
- drops;
- bosses;
- activity / online / event rewards;
- Synergy becomes an important recycling loop;
- Legendary acquisition is strongly tied to high-end routes.

### Updated Direction
Early progression should feel faster and juicier than before.  
The player should get:
- new cards early;
- skill identity early;
- noticeable improvement early.

The system should not wait too long before a fighter feels “real”.

---

## 6. Card Opening and Fighter Generation

When a card is opened, the fighter is generated in this order:

1. **Class**
2. **Grade**
3. **Base stats** within class-grade ranges
4. **Special skill** from the class pool
5. **Subclass**, derived from the generated special skill
6. **0–1 trait**
7. Optional future cosmetic/visual module (not baseline)

### Design Rule
Subclass is **not** rolled separately first.  
Subclass is defined by the generated special skill.

### Updated Direction
The generation result should create stronger immediate differentiation than before.

A “good” pull should feel good not only because of rarity color, but because:
- stat ranges are more meaningful;
- skill identity is visible;
- role fit is obvious;
- tempo-oriented classes can feel immediately more exciting.

---

## 7. Classes

The baseline class list is:

- Guardian
- Warrior
- Berserker
- Rogue
- Jester
- Archer
- Priest
- Mage
- Occultist

Summoner is reserved for later updates and is not part of this baseline progression document.

### Updated Role Direction
Classes are no longer read through slot logic.

They are now read through:
- role;
- behavior;
- tempo;
- trio value.

---

## 8. Traits

Traits are an early progression/identity system.

### Baseline Rules
- Fighters can generate with **0 or 1 trait**
- Traits do not level up
- Traits do not affect economy systems directly
- Traits affect only combat formulas and combat behavior

### Trait Types
Traits may be:
- purely positive;
- compromise-based

Example compromise trait concepts:
- lower Accuracy, higher Attack Speed
- lower Defense, higher Crit Chance
- lower HP, higher burst pressure

### Updated Rule
Traits should create flavor and interesting variation, but should **not** outweigh:
- grade;
- special skill;
- subclass;
- overall progression investment.

Traits are meaningful, but they are not the main source of fighter value.

### Not Baseline
The following are not baseline:
- trait removal;
- trait rerolling;
- healing/sanctuary/church systems for traits.

Those may exist later.

---

## 9. Levels and Experience

## 9.1 Level Cap
Fighters start at **level 1** and can reach **level 20**.

All newly generated fighters start at **level 1**.

## 9.2 Experience Source
Experience comes from **combat only**.

All **surviving fighters** who participated in the battle receive experience.

There is no requirement that the fighter must have taken a turn.

A soft experience cap per battle may exist later if needed for balance.

## 9.3 Experience at Max Level
When a fighter is already at max level:
- excess experience is not fully wasted;
- **10%** of excess experience is converted into Ascension progress/resource.

### Updated Rule
Leveling must feel more impactful than in the older conservative version.

The player should feel:
- faster kills;
- stronger role contribution;
- more obvious power spikes;
- more visible tempo changes for tempo classes.

---

## 10. Level Milestones

The baseline milestone structure is:

| Level | Milestone |
|---|---|
| **1** | Fighter exists in base form, special skill is visible in UI but not yet usable |
| **3** | Special skill unlocks for active use |
| **10** | Class spike / role spike |
| **15** | Special skill modifier choice |
| **20** | Subclass capstone |

## 10.1 Level 3
Unlocks the generated special skill.

This is intentionally early to:
- reveal the fighter's real identity quickly;
- improve retention;
- help players decide whether to invest or replace.

### Updated Rule
Level 3 is the first real “this unit is online” point.  
This milestone should feel noticeable in combat, not ceremonial.

## 10.2 Level 10
Grants a **class-specific role spike**.

Exact numerical tuning is intentionally left open, but the design intent is fixed:
- the class spike strengthens the class fantasy and core combat role;
- the spike should be visible in actual combat pace and usefulness.

Examples of class-spike directions:
- Guardian: stronger defensive value / better aggro holding
- Warrior: stronger stable frontline pressure
- Berserker: stronger aggressive payoff
- Rogue: stronger crit / poison / tempo pressure
- Jester: stronger buff tempo utility
- Archer: stronger precision / crit pressure
- Priest: stronger sustain impact
- Mage: stronger effect reliability
- Occultist: stronger ritual reliability

## 10.3 Level 15
The player chooses a modifier for the fighter's special skill.

### Baseline Rules
- choice is **one-time and irreversible** in early versions;
- not every skill is required to have exactly the same number of options;
- the modifier must alter the **use-case inside the role**, not break the fighter's identity.

The choice should help the player:
- cover a missing need in the team;
- reinforce a preferred use-case;
- keep the skill inside the class/subclass role.

### Updated Rule
This choice should create real differentiation, not fake micro-optimization.

It should feel like:
- “I shaped this fighter for my trio”
not:
- “I picked the least bad +5%”

## 10.4 Level 20
Grants a **subclass capstone**.

This should strengthen:
- the current subclass identity;
- the fighter's existing role and play pattern.

It should not be a generic flat bonus only.

Exact capstone content remains open, but the design direction is fixed.

### Updated Rule
Level 20 should feel like a real end-state version of the fighter.

A level 20 unit should not feel like:
- “same unit, slightly bigger numbers”

It should feel like:
- fully online;
- role-defined;
- clearly worth long-term investment.

---

## 11. Stat Generation

## 11.1 Generated Stats
At fighter creation, the rolled stats are:

- **HP**
- **Damage**
- **one secondary class stat**

Secondary class stats by class:

| Class | Secondary Stat |
|---|---|
| Guardian | Defense |
| Warrior | Defense |
| Berserker | Attack Speed |
| Rogue | Evasion |
| Jester | Attack Speed |
| Archer | Accuracy |
| Priest | Defense |
| Mage | Accuracy |
| Occultist | Attack Speed |

### Design Rule
Not all combat stats are rolled at creation.  
The system intentionally avoids over-randomization.

### Updated Rule
**Attack Speed** replaces Initiative as the main player-facing tempo stat in progression.

This is fixed because:
- it creates more visible combat difference;
- it helps higher-rarity fighters feel exciting;
- it better supports the new combat shell and retention goals.

---

## 11.2 Stat Tier Labels
For stat generation, class-grade ranges use three category levels:

- **Low**
- **Medium**
- **High**

A class receives one of these ratings for each relevant stat.

---

## 11.3 Class Stat Profile Matrix

| Class | HP | Damage | Defense | Evasion | Accuracy | Attack Speed |
|---|---|---|---|---|---|---|
| **Guardian** | High | Low | High | Low | Medium | Low |
| **Warrior** | Medium | Medium | Medium | Low | Medium | Medium |
| **Berserker** | Medium | High | Low | Low | Medium | High |
| **Rogue** | Low | High | Low | High | Medium | High |
| **Jester** | Medium | Low | Low | Medium | Low | High |
| **Archer** | Low | High | Low | Low | High | Medium |
| **Priest** | Medium | Low | Medium | Low | Medium | Low |
| **Mage** | Low | High | Low | Low | High | Medium |
| **Occultist** | Low | High | Low | Low | Medium | Low |

### Matrix Interpretation
- HP and Damage define the role skeleton;
- the secondary stat defines how the class expresses that role;
- tempo classes should now feel more active, not merely more “initiative efficient”.

---

## 11.4 Base Stat Ranges by Grade

### HP

| HP Level | Common | Uncommon | Rare | Epic | Legendary |
|---|---:|---:|---:|---:|---:|
| **Low** | 120–170 | 155–220 | 200–285 | 255–360 | 320–450 |
| **Medium** | 180–260 | 235–335 | 300–430 | 385–550 | 480–690 |
| **High** | 280–420 | 360–540 | 460–690 | 590–890 | 750–1130 |

### Damage

| Damage Level | Common | Uncommon | Rare | Epic | Legendary |
|---|---:|---:|---:|---:|---:|
| **Low** | 10–15 | 13–19 | 17–25 | 22–32 | 28–40 |
| **Medium** | 16–24 | 21–31 | 27–40 | 35–52 | 45–66 |
| **High** | 26–38 | 34–50 | 44–65 | 57–84 | 73–108 |

### Defense

| Defense Level | Common | Uncommon | Rare | Epic | Legendary |
|---|---:|---:|---:|---:|---:|
| **Low** | 2–4 | 3–5 | 4–7 | 5–9 | 7–11 |
| **Medium** | 5–8 | 7–11 | 9–14 | 12–18 | 15–23 |
| **High** | 9–14 | 12–18 | 16–24 | 21–31 | 27–40 |

### Evasion

| Evasion Level | Common | Uncommon | Rare | Epic | Legendary |
|---|---:|---:|---:|---:|---:|
| **Low** | 5–8 | 7–10 | 9–13 | 11–16 | 14–20 |
| **Medium** | 9–14 | 12–18 | 16–23 | 20–29 | 25–36 |
| **High** | 15–22 | 19–28 | 24–35 | 31–45 | 39–57 |

### Accuracy

| Accuracy Level | Common | Uncommon | Rare | Epic | Legendary |
|---|---:|---:|---:|---:|---:|
| **Low** | 90–100 | 102–114 | 116–130 | 132–149 | 150–170 |
| **Medium** | 101–112 | 115–128 | 131–146 | 150–168 | 171–192 |
| **High** | 113–126 | 129–144 | 147–165 | 169–190 | 193–218 |

### Attack Speed

| Speed Level | Common | Uncommon | Rare | Epic | Legendary |
|---|---:|---:|---:|---:|---:|
| **Low** | 0.82–0.92 | 0.90–1.00 | 0.98–1.09 | 1.06–1.18 | 1.14–1.27 |
| **Medium** | 0.93–1.05 | 1.01–1.14 | 1.10–1.24 | 1.19–1.34 | 1.28–1.45 |
| **High** | 1.06–1.20 | 1.15–1.31 | 1.25–1.43 | 1.35–1.56 | 1.46–1.70 |

### Updated Philosophy
The old small linear numbers are no longer valid for this project.

These ranges now support:
- stronger rarity feel;
- stronger level payoff;
- stronger TTK changes;
- more visible class identity.

### Speed Rule
For tempo classes, higher rarity should often feel different not just because of more damage, but because:
- attacks happen more often;
- effects trigger more often;
- screen activity is denser.

Readability is secondary to excitement here.

---

## 12. Stat Growth on Level Up

## 12.1 What Grows
Each level increases:
- **HP**
- **Damage**
- **the fighter's secondary class stat**

Other combat stats are expected to be influenced mostly by:
- combat systems;
- equipment;
- future content systems.

## 12.2 Grade Influence on Growth
Grade affects:
- starting stat ranges strongly;
- level growth meaningfully, not just slightly.

This preserves:
- strong value of higher grades;
- visible reward for leveling;
- stronger long-term payoff from investment.

## 12.3 Growth Philosophy
The old flat “safe RPG” progression is no longer valid.

Leveling must create:
- noticeable TTK improvement;
- stronger sustain;
- stronger support output;
- more visible tempo growth for tempo classes;
- real feeling of “this fighter is online now”.

A level 20 fighter should not feel like a level 1 fighter with slightly cleaner numbers.

## 12.4 Growth Targets at Level 20

### HP growth multiplier by level 20
- Common → **x2.20**
- Uncommon → **x2.40**
- Rare → **x2.65**
- Epic → **x2.95**
- Legendary → **x3.30**

### Damage growth multiplier by level 20
- Common → **x1.95**
- Uncommon → **x2.15**
- Rare → **x2.40**
- Epic → **x2.70**
- Legendary → **x3.05**

### Secondary stat growth multiplier by level 20
- Common → **x1.45**
- Uncommon → **x1.55**
- Rare → **x1.68**
- Epic → **x1.82**
- Legendary → **x2.00**

### Attack Speed Growth Note
Attack Speed should not simply scale linearly from raw levels across all classes.

For speed-oriented classes, a meaningful part of tempo growth should come from:
- rarity;
- level 10 class spike;
- level 15 modifier choice;
- gear;
- traits;
- future systems.

This avoids every class converging into the same combat feel.

## 12.5 Growth Targets at Level 10

| Grade | HP | Damage | Secondary |
|---|---:|---:|---:|
| **Common** | x1.52 | x1.36 | x1.18 |
| **Uncommon** | x1.61 | x1.44 | x1.23 |
| **Rare** | x1.72 | x1.54 | x1.29 |
| **Epic** | x1.84 | x1.66 | x1.36 |
| **Legendary** | x1.98 | x1.80 | x1.45 |

### Updated Rule
Level 10 should already feel like a strong transformation point.  
Level 20 should feel like a fully developed unit, not a polished starter version.

---

## 13. Shop Packs

The shop uses pack tiers rather than one universal product.

### Pack Tabs
- **Low Tier**
- **Mid Tier**
- **High Tier**

Within each tier:
- the first slot may be a fully random pack;
- the remaining slots may be class-targeted packs.

## 13.1 Random vs Class Packs

### Random Packs
- may contain higher high-roll value;
- are the primary shop-based route for Legendary chance.

### Class Packs
- allow controlled targeting of a chosen class;
- are intentionally more expensive;
- **do not contain Legendary fighters**.

### Class Pack Price Rule
Class-targeted packs should cost roughly **15%–30% more** than equivalent random packs.

## 13.2 Low Tier Pack (baseline)

| Grade | Chance |
|---|---:|
| Common | 65.0% |
| Uncommon | 29.5% |
| Rare | 3.5% |
| Epic | 1.8% |
| Legendary | 0.2% |

## 13.3 Mid Tier Pack (baseline random version)

| Grade | Chance |
|---|---:|
| Uncommon | 72.0% |
| Rare | 20.0% |
| Epic | 7.5% |
| Legendary | 0.5% |

## 13.4 High Tier Pack (baseline random version)

| Grade | Chance |
|---|---:|
| Rare | 70.0% |
| Epic | 25.0% |
| Legendary | 5.0% |

### Design Rule
Class packs remove Legendary outcomes.  
Random packs preserve the higher-ceiling gamble.

### Updated Rule
Random packs should retain higher emotional upside.  
Class packs should retain higher control.  
They must not feel identical except for price.

---

## 14. Fusion

Fusion is the main targeted sink for unwanted fighters.

### Rule
Selected fighters are merged into a chosen target fighter to grant **Ascension points**.

Fusion is intended to be:
- controlled;
- targeted;
- the main way to improve a chosen fighter's Ascension progress.

## 14.1 Fusion Value Philosophy
Raw combat stats are **not** used directly in Fusion value.

Instead, Fusion value uses:
- grade;
- roll quality inside class-grade ranges;
- class match;
- subclass match;
- level progression.

This avoids distortions such as tanks being worth too much just because raw HP numbers are larger.

## 14.2 Fusion Value Formula

**FusionValue = 100 × GradeModifier × RollQualityModifier × ClassModifier × SubclassModifier × LevelProgressModifier**

### GradeModifier
- Common → 1.00
- Uncommon → 1.25
- Rare → 1.50
- Epic → 1.75
- Legendary → 2.00

### RollQualityModifier
**RollQualityModifier = 0.80 + 0.25 × PrimaryPercentile + 0.15 × SecondaryPercentile**

Where:
- `PrimaryPercentile` = roll quality of the class's primary stat inside its class-grade range
- `SecondaryPercentile` = roll quality of the class's secondary stat inside its class-grade range

This creates:
- low roll ≈ 0.80
- average roll ≈ 1.00
- high roll ≈ 1.20

### ClassModifier
- same class → 1.25
- otherwise → 1.00

### SubclassModifier
- same subclass → 1.10
- otherwise → 1.00

**SubclassModifier only applies if class also matches.**

### LevelProgressModifier
- level 1–14 → 1.00
- level 15–19 → 1.15
- level 20 → 1.20

### Explicitly Not Counted
- traits
- equipment
- external progression layers

### Updated Rule
Fusion should feel like:
- feeding a main project;
- investing in a favorite unit;
- not just deleting leftovers.

---

## 15. Synergy

Synergy is a secondary recycle loop.

### Rule
**10 cards** are combined into **1 new card** with a randomized grade result according to the Synergy rules.

### Design Role
Synergy is:
- an alternative to Fusion;
- more random;
- more gamble-like;
- less controlled.

It is **not** intended to replace Fusion as the main progression sink.

### Important Rule
Legendary fighters are **not** obtained through Synergy.

## 15.1 Baseline Synergy Rules
- a recipe always uses **10 cards**
- clean recipes of a tier give a baseline chance at the next tier
- higher-quality cards in the recipe improve outcome chances
- Synergy is a recycle loop, not a primary deterministic progression path

Detailed Synergy tuning may be adjusted later.

### Updated Rule
Synergy must feel like:
- a recycling gamble with hope;
not:
- the main serious investment system.

Fusion remains the primary controlled route.

---

## 16. Ascension

Ascension is a long-term progression layer for fighters.

### Baseline Tier Support
Only **Tier I Ascension** is fixed in this document.

Higher tiers are acknowledged but intentionally deferred.

## 16.1 Tier I Ascension Thresholds

| Grade | Tier I Ascension Requirement |
|---|---:|
| **Common** | 2500 |
| **Uncommon** | 6000 |
| **Rare** | 15000 |
| **Epic** | 40000 |
| **Legendary** | 120000 |

These values are intentionally tuned so that:
- Common fighters can reach Tier I without extreme pain;
- Uncommon requires deliberate investment;
- Rare requires time and resources;
- Epic becomes a grind project;
- Legendary requires major focus and long-term commitment.

## 16.2 Tier I Reward
Tier I Ascension unlocks:
- **one passive or trigger-based bonus**

### Baseline Rule
The player chooses **1 of 3** options.

The option pool is:
- defined inside the fighter's class;
- at least one option should usually align well with the current subclass.

### Early Version Rule
This choice is **not reversible** in early versions.

## 16.3 Higher Ascension Tiers
Tier II and Tier III are planned conceptually, but not part of the baseline implementation.

They may later unlock:
- stronger role-defining bonuses;
- additional active depth;
- capstone-level fighter identity expansion.

Not fixed in this document.

---

## 17. Roster and Storage

The player's active combat roster is intended to stay relatively narrow.

Storage baseline:
- up to **20 fighter slots**
- may be monetized/expanded later

This supports:
- meaningful roster management;
- pressure to evaluate and recycle fighters;
- long-term collection without immediate infinite storage.

---

## 18. UI Evaluation Priorities

When comparing fighters, UI should prioritize clarity.

Important visible elements:
- class
- subclass
- grade
- special skill
- trait (if any)
- key stat highlights
- level and milestone state

### Comparison UX Rule
The UI should clearly highlight:
- which key stat is primary for that class;
- which values are higher/lower compared to another fighter;
- green for better / red for worse comparisons.

This helps players:
- decide who to keep;
- decide who to level;
- decide who to fuse;
- decide who to recycle via Synergy.

### Updated Rule
The UI should not only show “bigger number”.

It should help answer:
- is this fighter faster?
- does this fighter hit harder?
- does this fighter fit my trio better?
- is this fighter worth investing in?

---

## 19. Fixed vs Open

## 19.1 Fixed in this document
The following are treated as fixed baseline decisions:

- card-based fighter acquisition;
- class → grade → stat roll → special skill → subclass → 0–1 trait generation order;
- grades and grade colors;
- level cap 20;
- level milestones at 3 / 10 / 15 / 20;
- special skill visible from level 1, usable from level 3;
- level-based stat growth structure;
- class stat profile matrix;
- **Attack Speed as the player-facing tempo stat replacing Initiative in progression**
- baseline grade pack structure;
- class packs cost more and exclude Legendary;
- Fusion as primary targeted sink;
- Synergy as secondary recycle loop;
- Tier I Ascension thresholds;
- Tier I Ascension grants a passive/trigger choice;
- excess max-level experience converts 10% into Ascension progress/resource.

## 19.2 Intentionally open for later iteration
The following are not fully finalized:
- exact class-specific level 10 bonus numbers;
- exact subclass capstone implementations at level 20;
- exact skill modifier content at level 15;
- final Attack Speed coefficient tuning;
- full Synergy formula tuning;
- late Ascension tiers;
- trait correction systems;
- final monetization tuning;
- event/limited pack rules.

---

## 20. Design Intent Summary

The fighter progression system is designed to provide:

- fast early identity reveal;
- meaningful roster evaluation;
- long-term investment in chosen fighters;
- useful sinks for unwanted fighters;
- controlled class targeting;
- randomized but readable variation;
- stronger visible progression than the earlier conservative version;
- more dopamine through tempo, spikes, and rarity fantasy.

The intended progression fantasy is:

- collect cards;
- open and evaluate fighters;
- build a focused trio;
- level the fighters you believe in;
- fuse the ones you do not need;
- recycle excess through Synergy;
- push favorite fighters into Ascension over time.