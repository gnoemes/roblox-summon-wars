# Stand Shell & Guided Reveal v0.1

**Status:** Fixed baseline for stand shell, guidance, and local stand UI  
**Last updated:** 2026-03-08

---

## 1. Purpose

This document defines the **battle stand / combat spot** as a full system object.

It fixes:
- how the stand is structured in the world;
- how the player interacts with it;
- how guidance and support are surfaced;
- how the enemy encounter is presented;
- how the stand exposes social comparison;
- how the stand should behave across platforms.

This document does **not** finalize:
- final 3D art style;
- final Roblox implementation details;
- final icon art;
- final polish/VFX levels;
- final balance of displayed metrics.

---

## 2. Core Design Goal

The stand is the player's local gameplay home inside a Region.

It must solve three questions quickly:

1. **What am I fighting?**
2. **What should I do next?**
3. **How strong / impressive am I compared to others?**

The stand should therefore combine:
- combat access;
- support guidance;
- social display.

It should not become:
- a cluttered kiosk;
- a full-screen menu replacement;
- a field substitute with scattered farming nodes.

---

## 3. Stand Role Split

The stand is divided into three product roles:

| Role | What it answers | Main interaction |
|---|---|---|
| **Combat Core** | what is the current activity / target | Battle |
| **Guide / Support** | what should the player do next | Guide |
| **Social / Identity** | who owns this stand and how strong it looks | visible board |

### Fixed mental model
- **Battle** = combat / activity selection
- **Guide** = Recommended, Tasks, Craft, Chest
- **Fighters** = Squad, Roster, Fusion, Synergy

---

## 4. Spatial Composition

The preferred stand layout is:

- **Center:** Portal Core / Reactor
- **Front:** Encounter Pad
- **Around core:** trio anchors / squad display points
- **Left:** Guide Mascot dock
- **Right:** Social / Stat Board

### Design Rule
The enemy should appear on a readable **Encounter Pad**, not as a silhouette buried inside the same central portal VFX mass.

This preserves:
- readability;
- cleaner combat focus;
- stronger rare/elite reveal contrast;
- simpler VFX layering.

---

## 5. Main Stand Parts

## 5.1 Portal Core / Reactor
The Portal Core is the main combat silhouette of the stand.

### Role
- anchor the stand visually;
- signal that combat is active or idle;
- act as the main battle interaction point.

### It should not
- become a dense button console;
- replace the encounter pad;
- contain every service interaction.

---

## 5.2 Encounter Pad
The Encounter Pad is the place where the current enemy manifests.

### Role
- current target display;
- current combat focus;
- target-click clarity;
- enemy header anchor point.

### Design Rule
The Encounter Pad is distinct from the Portal Core.

---

## 5.3 Squad Anchors
Three anchor positions visually represent the current trio around the stand.

### Role
- show active squad presence;
- increase social readability;
- support rarity / prestige visibility.

These should remain readable and not become giant pedestal systems in baseline implementation.

---

## 5.4 Guide Mascot Dock
The Guide Mascot is a built-in support object attached to the stand.

### Role
- reactive prompts;
- support menu access;
- guidance personality layer;
- service shortcut.

### Important rule
The mascot is **not** the main combat interaction.
It is a guide/support layer.

---

## 5.5 Social / Stat Board
The Social Board sits on the stand as the visible identity display.

### Role
- owner identity;
- social proof;
- visible strength;
- prestige later.

It should stay:
- readable;
- compact;
- comparison-oriented.

It should not become:
- an admin dashboard;
- a utility panel;
- a list of every progression system.

---

## 6. Stand Interaction Model

When the player is at their stand, the baseline actions are:

- **Battle**
- **Guide**
- **Fighters**

These may be available:
- by clicking 3D objects;
- by contextual HUD buttons;
- by hotkey / button shortcuts.

### Important rule
The player must not be forced into repeated NPC dialogue flows for ordinary play.

---

## 7. Battle Panel

The Battle Panel is the fast stand panel for activity selection.

### It should show
- Hunting Grounds target / mode cards
- Dungeon node cards
- Raid node card
- recommended squad power
- entry status
- reward identity

### It should not show
- full progression management;
- craft systems;
- roster management;
- long explanation text.

### Design goal
The Battle Panel should answer:
- what can I fight;
- what is unlocked;
- what reward profile this gives.

---

## 8. Guide Panel

The Guide Panel is the stand support menu.

### Fixed sections
1. **Recommended**
2. **Tasks**
3. **Craft**
4. **Chest**

---

## 8.1 Recommended
This is the first and most important Guide screen.

It should show **1–3 contextually useful next steps**.

Examples:
- craft body armor
- equip new item
- try unlocked Dungeon node
- claim regional guidance reward

### Design Rule
Recommended is not a long list of tips.
It is a prioritized next-action layer.

---

## 8.2 Tasks
Tasks represent:
- regional guidance chain;
- repeatable task board;
- current actionable structure.

Tasks should feel like:
- direction;
- guidance;
- bonus value.

Tasks should not feel like:
- the only way to progress;
- a mandatory daily job list that replaces free play.

---

## 8.3 Craft
Craft gives access to currently available recipes.

### Design Rule
Craft should be tightly tied to guidance and progression pain.

It is strongest when it answers:
- “these enemies got too tanky”
- “you now have enough materials”
- “this craft will help in this region”

---

## 8.4 Chest
Chest stores consumables.

### Important rule
The Chest is not the same thing as fighter roster storage.

It should be treated as:
- consumable stock;
- auto-use support layer;
- support-system utility panel.

---

## 9. Fighters Panel

The Fighters Panel is separate from the Guide Panel.

### Fixed sections
1. **Squad**
2. **Roster**
3. **Fusion**
4. **Synergy**

### Design Rule
This panel is about:
- who the player owns;
- who is active;
- who should be invested in;
- how unwanted fighters are converted.

It should not become a mixed menu for craft/chest/tasks.

---

## 9.1 Squad
Shows the active trio.

Strong candidate contents:
- current active fighters
- high-level squad summary
- useful recommendation
- maybe role/tempo/survival hint

### Important rule
`Squad Power` is a stronger baseline guidance metric than trying to make raw DPS the only truth metric.

---

## 9.2 Roster
Shows owned fighters.

### It should help answer
- who is strong
- who is expendable
- who fits the trio better
- who should be fused later

---

## 9.3 Fusion
Main controlled conversion of unwanted fighters into target progression.

---

## 9.4 Synergy
Secondary recycling loop.
Lower priority and lower strategic weight than Fusion.

---

## 10. Guided Reveal Architecture

The game uses a three-layer reveal model.

## 10.1 Layer A — Reactive Prompts
Short contextual nudges such as:
- enough resources to craft first armor
- first meaningful slowdown in TTK
- first failure
- new Dungeon unlocked
- reward ready

### Goal
Solve immediate friction with one obvious next action.

---

## 10.2 Layer B — Regional Guidance Chain
Each region may have a short guided chain:
- engage with local enemies
- gather local resources
- craft a useful item
- apply it
- clear local node content

### Design Rule
The chain should be:
- short;
- contextual;
- tied to region progression;
- not a giant narrative questline.

---

## 10.3 Layer C — Repeatable Tasks / Boards
Repeatable objectives provide medium-length structure.

Examples:
- kill enemy type
- collect resource type
- craft item
- finish number of fights
- clear node

---

## 11. Enemy Combat Header

The current enemy uses an **Enemy Combat Header**.

### Required elements
- enemy name
- HP bar
- threat tier badge

### Optional elements
- one short threat tag
- stage line for Dungeon / Raid
- chest/rare icon if applicable

### Hunting Grounds baseline
- compact
- name
- HP bar
- badge only if special

### Dungeon / Raid baseline
- name
- HP bar
- badge
- optional threat tag
- optional stage line below

### Design Rule
The enemy header communicates current combat state, not full enemy analysis.

---

## 12. Social / Stat Board

The stand uses a visible social/stat panel.

### Required elements
- owner name
- optional title / prestige marker
- 1 main stat
- 1–2 secondary stats

### Strong candidate metrics
- Peak DPS
- Highest Crit
- Kill Streak
- Region Kills
- Boss Damage later

### Recommended baseline
- Main: Peak DPS or Highest Crit
- Secondary: Kill Streak
- Secondary: Region Kills

### Important rule
The board is not an Excel board.

---

## 13. Platform Rule

The project now uses a **mobile-first baseline layout** for stand UI.

This means:
- identical information architecture for mobile and desktop;
- desktop may have more space, but not a different logic;
- the same baseline menu sections remain valid everywhere.

### Design Rule
Do not create a second desktop-specific mental model.

---

## 14. Stand States

The stand should support at least these high-level states:

1. **Unclaimed / Empty**
2. **Claimed / Idle**
3. **Hunting Grounds Active**
4. **Rare / Elite Active**
5. **Guide Prompt Ready**
6. **Dungeon Available / Selected**
7. **Reward Ready**

This should behave like a simple stand state machine, not a pile of unrelated VFX flags.

---

## 15. Fixed vs Open

### Fixed in this document
- stand has 3 roles: combat, guide/support, social display
- preferred 3D layout uses portal core + encounter pad + mascot + board
- enemy appears on encounter pad, not merged into portal effect mass
- stand uses Battle / Guide / Fighters mental model
- Guide menu = Recommended / Tasks / Craft / Chest
- Fighters menu = Squad / Roster / Fusion / Synergy
- guided reveal uses prompts + regional chain + repeatable tasks
- enemy combat header is compact and state-oriented
- social board uses 1 main stat + 1–2 secondary stats
- mobile-first baseline applies to all platforms

### Open for later iteration
- exact stand art style
- exact VFX budget
- exact prompt priority algorithm
- exact first-region guidance steps/rewards
- exact HUD layout
- final stat choice for the social board
- later prestige layers and stand cosmetics

---

## 16. Design Intent Summary

The stand should feel like:
- the player's local combat machine;
- the place where progress is made visible;
- the place where the next useful step is easy to discover;
- the place where nearby players can compare power.

The stand should not feel like:
- a marketplace booth;
- a giant menu terminal;
- a cluttered quest giver.
