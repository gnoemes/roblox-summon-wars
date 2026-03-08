# Integration Update v0.1

**Status:** Documentation integration patch  
**Last updated:** 2026-03-08

---

## 1. Purpose

This document records the design decisions and inconsistency fixes agreed after the v0.2 pass.

It exists to:
- lock the newly discussed shell/UI/guidance decisions;
- resolve cross-document contradictions;
- provide a clean handoff into the next documentation set and implementation planning.

This is an integration document, not a replacement for all system docs.

---

## 2. Main Newly Fixed Decisions

### 2.1 Guided Reveal Architecture
The game now explicitly uses a **guided reveal** structure.

This means:
- the player is not expected to self-discover every progression system;
- systems should appear as solutions to a visible problem;
- a new system should quickly create a visible payoff after discovery.

The baseline guidance stack is:
1. **reactive prompts**
2. **short regional guidance chain**
3. **repeatable tasks / boards**

---

### 2.2 Battle Stand / Combat Spot Shell
The stand is now treated as a formal system object, not just a thematic location.

The stand has three clear product roles:
1. **Combat Core**
2. **Guide / Support Layer**
3. **Social / Identity Display**

The stand should no longer be treated as:
- a random decorative anchor;
- a field replacement with many scattered combat points;
- a full service kiosk where every core action requires NPC dialogue.

---

### 2.3 Stand Spatial Composition
The preferred stand layout is now:

- **Center:** Portal Core / Reactor
- **Front of core:** Encounter Pad / enemy manifestation point
- **Around core:** trio visual anchors
- **Left side:** Guide Mascot / support dock
- **Right side:** Social / Stat Board

Important rule:
- the enemy should not be visually merged into the same central effect mass as the portal core;
- the encounter should manifest on a distinct readable combat pad.

---

### 2.4 Interaction Model
The stand interaction model is now:

- **Battle** → battle/activity selection
- **Guide** → support/guidance/services
- **Fighters** → squad/roster/progression management

This is the intended mental model:
- **Battle = what am I fighting**
- **Guide = what should I do next**
- **Fighters = who am I investing in**

---

### 2.5 Guide / Support Menu
The support menu is now fixed as:

1. **Recommended**
2. **Tasks**
3. **Craft**
4. **Chest**

Important rule:
- `Recommended` is the first and most important screen;
- it should not become a long checklist;
- it should show 1–3 contextually useful next actions.

---

### 2.6 Fighters Menu
The fighters menu is now fixed as:

1. **Squad**
2. **Roster**
3. **Fusion**
4. **Synergy**

Important rule:
- this menu is for fighter management, not for support systems;
- `Roster` should not be called `Storage` in player-facing UI because it conflicts with consumable chest/storage language.

---

### 2.7 Mobile-First Baseline UI
The project now uses a **mobile-first baseline UI layout** for both mobile and desktop.

This means:
- the same core information architecture should be preserved across platforms;
- desktop should not become a second design language with different menu logic;
- adaptations may improve spacing, but the baseline interaction structure stays the same.

---

### 2.8 Enemy Combat Header
The current enemy should use a compact **Enemy Combat Header**.

Baseline contents:
- enemy name
- HP bar
- threat tier badge
- optional short threat tag
- stage line below for Dungeon / Raid if needed

Important rule:
- this header communicates current combat state;
- it should not become a full enemy analysis panel.

---

### 2.9 Social / Stat Board
The stand now formally uses a **Social / Stat Board**.

Its job is:
- identity;
- comparison;
- envy / aspiration;
- prestige display later.

It should show:
- owner name
- optional title / prestige marker
- 1 main stat
- 1–2 secondary stats

It should not become:
- a service panel;
- a progression dashboard;
- an admin screen.

---

### 2.10 Social Shell Reframing
The region social shell is now understood more honestly.

The baseline role is:
- **ambient comparison**
- **public visible progress**
- **light social curiosity**
- **possible conversation context**

It is **not** treated as a guaranteed deep social mechanic by itself.

---

## 3. Resolved Inconsistencies

### 3.1 Chest / Stash vs Resource Storage
The old wording caused a major contradiction.

Resolved baseline:
- **Chest / Stash = consumable storage only**
- **Resources use a separate stack-based resource inventory**
- resource stacks do **not** consume chest slots in baseline design

This fixes the contradiction where:
- chest was described as shared storage for consumables and resources;
- default chest size was too small if all resources also occupied slot space;
- monetization language around storage became misleading.

---

### 3.2 “Turns” After Moving to Interval Combat
The old economy document still described long buffs with `turn` durations.

Resolved baseline:
- long-duration consumables now use **real-time duration**
- player-facing duration language should use **minutes / remaining time**
- turn-based duration wording is no longer valid in this shell

---

### 3.3 Prep Buff Persistence Between Encounters
The old rules partially conflicted across Hunting Grounds, Dungeon, and Raid descriptions.

Resolved baseline:
- **encounter-only combat state** resets between encounters;
- **long-duration prep buffs** persist until their real-time duration ends;
- Hunting Grounds still resets combat pressure, but does not forcibly wipe active timed prep buffs;
- Dungeons and Raids still preserve HP attrition and therefore remain much more preparation-sensitive.

---

### 3.4 “Storage” as a UI Label
The term `Storage` was used too broadly.

Resolved baseline:
- fighter list UI should use **Roster**
- consumable storage UI should use **Chest**
- monetization may still use storage language, but internal design docs should stay precise

---

## 4. Product Direction Reinforced

The project is now more clearly treated as:

**a social stand-based auto-battle progression game with guided reveal, visible power spikes, and strong comparison hooks**

The game should not drift back toward:
- slot-based combat;
- line logic;
- field-first multi-spot farming;
- too much hidden complexity without guided discovery.

---

## 5. What Still Needs Follow-Up

The following are still worth resolving in a later pass:

- exact recommended stand metrics for launch
- final Recommended screen priority algorithm
- exact timed consumable durations and stock pressure tuning
- whether equipment ships in P0 or only a subset does
- exact rarity/elite/chest replacement tables
- exact first-region guidance chain steps and rewards
- whether early crafting opens in Region 1 or Region 2
- which classes are truly in launch scope versus document scope

---

## 6. Implementation Consequence

The project now has a cleaner implementation target.

A practical early implementation can be built around:
- one stand prefab/state machine
- one battle panel
- one guide panel
- one fighters panel
- one enemy combat header widget
- one social/stat board widget
- one reactive prompt system
- one first-region guidance chain

This is a much cleaner production target than the older partially merged shell.
