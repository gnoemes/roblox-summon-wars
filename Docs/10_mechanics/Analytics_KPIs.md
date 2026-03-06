# Analytics & KPIs

### 12.1 События (Events)
Onboarding:
- first_join
- claimed_starter_pet
- started_first_raid
- completed_first_raid

Progression:
- mutation_unlocked (id)
- pet_level_up
- breeding_started / breeding_completed
- stance_changed

Engagement:
- daily_reward_claimed
- quest_completed
- raid_modifier_seen

Monetization:
- shop_opened
- purchase_attempted
- purchase_succeeded (productId)

### 12.2 KPI цели (минимальные ориентиры)
- D1: 15–20%+
- Средняя сессия: 8–12 минут
- 2–4 рейда за сессию
- Прохождение первого рейда: 60%+

---

## Дополнения (обновлено 2026-02-26)

### События рейдов (milestone)
- `raid_start` (mode, difficulty, modifiers[], partySize, arenaId)
- `raid_wave_milestone` (milestone=25|50|75|100, wavesCleared, totalWaves, timeFromStart, partySize)
- `raid_fail` (wavesCleared, milestoneReached, reason)
- `raid_complete` (wavesCleared=totalWaves, duration, partySize)
- `boss_kill` (bossId, duration, difficulty, partySize)

### Награды
- `reward_milestone_paid` (milestone, resources{}, totalValue, partySize)
- `reward_disconnect_forfeit` (milestone, bankValue)

### Хаб/социалка
- `party_lobby_created` (mode, difficulty, openSlots)
- `party_lobby_joined` (lobbyId, viaGlobalLFG=true|false)
- `party_lobby_start` (partySize)
- `inspect_player` (targetUserId, petRarity, hasAura)

### KPI
- Milestone reach rate: % игроков, достигших 25/50/75/100 в Wave Arena
- Party formation rate: % забегов, стартовавших в пати
- Conversion to co-op: доля игроков, которые хотя бы 1 раз прошли рейд в пати за D1/D7

---

## Combat & Commanding events (обновлено 2026-02-26)

### Режимы и ввод
- `combat_waypoint_set` (source=tap|click)
- `combat_mode_focus_enter` (cpCost)
- `combat_focus_target_set` (enemyType, distance)
- `combat_mode_hold_enter` (cpCost, holdRadius)
- `combat_hold_point_set` (holdRadius)
- `combat_mode_exit` (fromMode=focus|hold, reason=newCommand|targetDead|cancel)

### Dash
- `combat_dash_used` (manual=true, cpCost, dashCd)
- `combat_dash_used` (manual=false, stance=defense, trigger=damageSpike|dangerZone|hpDrop)

### Stances
- `combat_stance_changed` (from, to, cpCost, stanceCd)

### Расходники / revive (если есть)
- `combat_consumable_used` (slot, itemId)
- `combat_revive_used` (source=freeDaily|paid|token)

---

## Mutations / Genetics events (обновлено 2026-02-27)

### Genome Capacity
- `genome_capacity_inherited` (parentA, parentB, childCap)
- `genome_capacity_cap_reached` (cap)

### Mutations (equip/active set)
- `combat_mutation_set_changed` (usedCapacity, maxCapacity)
- `visual_mutation_changed` (channel, mutationId)

### Marionette
- `marionette_tactical_assigned` (skillId, eligibleCount, atMilestone=25)
- `marionette_tactical_longpress_auto` (skillId)

### Fusion
- `mutation_fusion_performed` (recipeId, type=visual|combat|cross, deltaCapacity)
