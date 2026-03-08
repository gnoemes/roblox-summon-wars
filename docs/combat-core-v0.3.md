# Combat Core v0.3

**Status:** Fixed mechanic baseline  
**Last updated:** 2026-03-08

---

## 1. Purpose

This document fixes the updated core combat mechanic for the project.

It answers:
- what combat is now;
- how combat starts inside the regional shell;
- how a battle flows without slot-based formation;
- how stats, statuses, and skills work;
- how combat state persists across Extraction types;
- what combat presentation assumptions are fixed for stand-based play.

This document focuses on **core battle logic**, not final tuning tables.

---

## 2. Combat Overview

Combat is a **target-click auto-battle encounter** built around a **3-fighter player trio** and usually **1 active enemy target**.

Core pillars:
- the player chooses the target directly;
- trio composition matters;
- class behavior matters;
- actions are automated but visible;
- battles are resolved through **timers / intervals**, not visible turn rounds;
- status effects, role synergies, and progression define tactical depth.

The standard encounter format is:
- **Player:** 3 active fighters
- **Enemy side:** usually 1 active enemy target

More complex enemy behavior can exist later through:
- phases;
- extra attacks;
- summons;
- special node rules;
- boss scripting.

---

## 3. Stand Combat Context

Combat happens inside the **regional stand shell**.

### Battle Stand / Combat Spot
The player's main local combat station inside a region.

From the stand, the player may:
- farm a selected target;
- switch target / farming mode;
- activate Dungeon content;
- activate Raid content.

### Local Combat Mode
The in-region combat state entered after the player starts fighting a selected target.

### Encounter Pad
The local manifestation point where the current target appears during stand combat.

### Design Rule
The enemy should be presented on a readable **Encounter Pad**, not buried inside the same central visual effect mass as the stand core.

---

## 4. Core Battle Structure

### 4.1 Standard Encounter
The default battle format is:
- **3 player fighters**
- **1 main enemy**

This is intentionally simpler than a squad-vs-squad format in order to preserve:
- readability;
- clear targeting;
- lower balancing complexity;
- stronger social readability in public regions;
- clearer understanding of why a battle was won or lost.

### 4.2 Battle End Conditions
A battle proceeds continuously until one of these conditions is met:
- the active enemy dies → player wins the encounter;
- all player fighters die → player loses the encounter.

### 4.3 Death Rules
When a unit reaches **0 HP or less**, it dies immediately.

Implications:
- death resolves instantly;
- a dead unit cannot act again in that encounter;
- dead units are no longer valid targets;
- enemies do not target corpses.

Death persistence depends on activity type:
- Hunting Grounds → death lasts only until encounter end
- Dungeon / Raid → death persists for the current run

---

## 5. Combat Start and Targeting

### 5.1 How Combat Starts
Combat begins when the player:
- clicks a valid target;
- or later unlocks auto-engage within range.

Combat does **not** load a separate arena.

Instead:
- the target is selected on the current scene;
- the camera shifts into local combat mode;
- the trio engages the selected target at the same stand.

### 5.2 Player Targeting Rule
The player directly selects the target.
The trio attacks that selected target.

There is no baseline:
- weakest-target logic;
- lowest-HP smart targeting;
- auto-priority by role;
- background smart switching.

### 5.3 Enemy Targeting Rule
Enemies use simplified readable targeting.

Baseline direction:
- units have an **aggro weight**;
- tank-like classes are hit more often;
- fragile classes are hit less often.

This preserves role identity without overcomplicating the system.

---

## 6. Timing Model

The combat system uses a **timer / interval model**.

Each combatant acts based on:
- attack interval;
- skill cooldown;
- current restrictions;
- current buff/debuff state.

### Basic timing terms
- **Attack Interval** — time between basic attacks
- **Skill Cooldown** — time before a special skill may be used again
- **Buff Duration** — remaining active time on a beneficial effect
- **Debuff Duration** — remaining active time on a harmful effect
- **DoT Tick** — periodic damage event from poison, bleed, or future types

### Design Rule
Player-facing time language should now use:
- time;
- remaining duration;
- cooldown time;
not visible turn rounds.

---

## 7. Action Sequence

Even though combat is not visibly round-based, each action still follows a readable internal order.

1. start-of-action effects
2. death check
3. restriction check
4. action selection
5. hit resolution
6. damage / effect application
7. immediate death resolution

This remains the internal order baseline.

---

## 8. Stats

| Stat | Role |
|---|---|
| **HP** | survivability |
| **Damage** | base offensive power |
| **Defense** | linear incoming damage reduction |
| **Accuracy** | hit reliability |
| **Evasion** | avoidance |
| **Crit Chance** | critical hit frequency |
| **Crit Damage** | critical damage multiplier |
| **Attack Speed / Attack Interval** | combat tempo |
| **Status Resist** | resistance against control/utility effects |

### Damage formula direction
`FinalDamage = max(RawDamage - Defense, 1)`

### Accuracy / Evasion
- Accuracy improves hit reliability
- Evasion reduces enemy hit reliability
- **Evasion cap: 50%**

### Crits
- fighters start at **0% crit chance** unless granted elsewhere
- **Crit Damage = 150%** baseline

### Attack Speed
Attack Speed is a major combat and feel stat.

It affects:
- action frequency;
- visible tempo;
- farming satisfaction;
- perceived rarity/power;
- “my fighter goes crazy now” moments.

---

## 9. Status Effects

Baseline effect families remain:
- Poison
- Bleed
- Stun
- Silence

### Effect chance principle
Control-style effects follow the principle:
`FinalControlChance = SkillBaseChance - TargetResist + Modifiers`

The exact coefficients remain tunable.

---

## 10. Skills and Special Skills

Each fighter has:
- a **Basic Attack**
- a **Special Skill**

Special skills may be:
- passive;
- active;
- trigger-based.

The old position-profile layer is removed.

---

## 11. Class / Archetype Matrix

The supported class list remains:
- Guardian
- Warrior
- Berserker
- Rogue
- Jester
- Archer
- Priest
- Mage
- Occultist

### Design Rule
Classes are read through:
- role;
- behavior;
- tempo;
- trio value;

not through slot geometry.

---

## 12. Enemy Readability

Enemies must be **predictably dangerous**, not chaotically unpredictable.

The player should understand:
- what kind of threat the enemy represents;
- what kind of trio counters it;
- why the trio won or lost.

### Enemy complexity by tier
- **Normal:** basic attack + 1 special
- **Elite:** basic attack + 2 specials, maybe 1 passive
- **Boss:** basic attack + 2–3 specials, passives, optional phases

---

## 13. Enemy Combat Header

The current target should use a compact **Enemy Combat Header**.

### Required elements
- enemy name
- HP bar
- threat tier badge

### Optional elements
- one short threat tag
- stage line for Dungeon / Raid
- special rare/chest icon

### Design Rule
The enemy header communicates current combat state, not full enemy analysis.

It should not become:
- a stat spreadsheet;
- a reward table;
- a resistance list;
- a large permanent world panel.

---

## 14. Activity-Specific Persistence Rules

## 14.1 Hunting Grounds
Each fight is a fresh encounter.

After the target dies:
- rewards are granted;
- HP fully restores;
- dead fighters return;
- cooldown state resets;
- encounter-only temporary combat state resets.

### Important clarification
Long-duration timed **prep buffs** such as Food and Elixir do **not** get forcibly wiped between Hunting Grounds encounters.
They persist until their real-time duration expires.

Hunting Grounds remain:
- fast;
- low-pressure;
- comfortable;
- not preparation-demanding by design.

---

## 14.2 Dungeon Nodes
Across the Dungeon:
- HP persists;
- dead fighters stay dead;
- cooldowns reset between encounters;
- encounter-only temporary buffs/debuffs reset between encounters;
- long-duration timed prep buffs may remain.

This creates real value in:
- sustain;
- preparation;
- good trio composition;
- defensive tools;
- consumables.

---

## 14.3 Raid Nodes
Across the Raid:
- HP persists;
- dead fighters remain unavailable;
- cooldowns reset between major stages/encounters;
- encounter-only temporary state resets between major stages;
- long-duration timed prep buffs may remain if their duration has not expired.

Raids therefore strongly reward:
- preparation;
- sustain;
- consumables;
- correct trio building.

---

## 15. Fixed vs Open

### Fixed in this document
- **3-fighter trio**
- **1 selected target at a time**
- target-click combat start
- no slot-based formation
- no line-based formation
- no smart targeting baseline
- timer / interval combat shell
- attack-speed-forward feel philosophy
- immediate death at 0 HP
- linear defense formula
- Evasion cap at 50%
- readable enemy behavior philosophy
- timed prep buffs instead of visible turn-duration language
- encounter-only reset vs long-duration prep persistence distinction
- compact enemy combat header

### Still open for later tuning
- exact stat coefficients
- exact hit formula coefficients
- exact status values
- exact skill content pools
- boss scripting
- future summon rules
- exact attack interval tuning
- exact threat tag list

---

## 16. Design Intent Summary

The combat system is intended to be:
- readable;
- behavior-driven;
- engaging without action-combat execution;
- fast enough for repeated regional farming;
- strong enough in visible payoff to support retention;
- compatible with public stand-based play.

The key differentiator is:
- **a visible 3-unit squad battler with target-click combat, strong class identity, and progression-driven tempo and power spikes.**
