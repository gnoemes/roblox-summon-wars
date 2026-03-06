# Raid Content Structure

## 0) Статус
- Status: Draft (обновлено 2026-03-06)
- Назначение: структура контента рейдов и data-model поверх уже описанного raid flow
- Связанные документы:
  - Рейды и инстансы: Raids_Instance_Flow.md
  - Places & Servers: ../30_tech/Places_and_Servers.md
  - Modifiers System: Modifiers_System.md
  - Economy & Progression: Economy_Progression.md

## 1) Базовая модель выбора рейда
Рекомендуемая формула:

**Biome → Tier → Difficulty → Active Modifiers → Encounter Triggers**

Где:
- **Biome** — контентная тема
- **Tier** — ступень PvE-прогрессии
- **Difficulty** — risk/reward scalar
- **Active Modifiers** — глобальные правила запуска
- **Encounter Triggers** — spike-события по ходу рейда

## 2) Архитектурная рекомендация
На текущем этапе:
- **1 Hub place**
- **1 Raid place**

Биомы, врагов, модификаторы, сценарии и награды нужно подгружать внутри **одного Raid place** через конфиги и пресеты.

## 3) Роли Biome / Tier / Difficulty

### 3.1 Biome
Biome определяет:
- визуальную тему
- семейства врагов
- тип угроз
- тематику наград
- доступные модификаторы
- пул минибоссов / боссов

### 3.2 Tier
Tier определяет:
- длину рейда
- число волн
- composition budget
- шанс и плотность элит
- наличие минибоссов
- число trigger-событий
- базовое качество наград

**Рекомендуемый диапазон для MVP:** Tier 1–5.

### 3.3 Difficulty
Difficulty определяет:
- scalar статов врагов
- множитель награды
- число активных модификаторов
- усиление trigger-событий
- шанс дополнительных pressure-моментов

**Для MVP:** Normal / Hard.  
**Позже:** Nightmare.

## 4) Биомы для MVP

### Луга
- стартовый и самый читаемый биом
- простые мили / базовые ранжовые / первые “толстые” враги
- акцент: понятные телеграфы и базовое позиционирование

### Лес
- средний биом с контролем пространства
- засады, яды, призыватели, кастеры
- акцент: фокус приоритетных целей и дебаффы

### Пещеры
- поздний MVP / предэндгейм
- плотные пачки, бронированные враги, сильные элиты, минибоссы
- акцент: pressure, выживаемость, area denial

## 5) Рекомендуемая структура Tier'ов

### Tier 1
- 2–3 волны
- без минибосса
- без сложных сценарных событий или с 1 простым trigger

### Tier 2
- 3–4 волны
- плотнее составы
- 1 простой trigger / pressure-событие

### Tier 3
- 4 волны
- гарантированное или вероятное элитное событие
- 1–2 trigger'а
- первое серьёзное минибосс-подобное давление

### Tier 4
- 4–5 волн
- несколько pressure-моментов
- 1–2 элитных события
- минибосс или тяжёлая финальная волна

### Tier 5
- кульминационный рейд блока прогрессии
- несколько опасных trigger'ов
- 1–2 активных модификатора
- сильный финал через минибосса / тяжёлую элитную волну / босса

## 6) Active Modifiers как отдельная сущность
Категории:
- Enemy Stat
- Enemy Behavior
- Arena Pressure
- Player Constraint
- Event-based

Рекомендуемое число:
- **Normal:** 0–1
- **Hard:** 1–2
- **Nightmare:** 2–3

## 7) Encounter Triggers как отдельная сущность
Trigger = **Condition → Action**

Conditions могут проверять:
- `% зачистки`
- время
- индекс волны
- модификаторы
- tier / difficulty / biome
- число живых врагов
- фазу encounter-а

Actions могут:
- спавнить элитную волну
- спавнить минибосса
- активировать hazard
- усиливать врагов
- переводить encounter в фазу
- запускать bonus-награду
- запускать audio/visual событие

## 8) % зачистки считать по budget-based системе
Формула:

**ClearPercent = DefeatedEncounterBudget / TotalEncounterBudget**

Пример budget-стоимости:
- обычный моб = 1
- усиленный моб = 2
- элита = 5
- минибосс = 12

## 9) Base Waves + Triggers
Encounter не должен быть просто кучей случайных trigger-событий.

- **Base Waves** задают ритм, составы, pacing, длительность
- **Triggers** усиливают ритм, добавляют spike-моменты и вариативность

## 10) Ориентировочные data-сущности
- RaidDefinition
- EncounterDefinition
- WaveDefinition
- EncounterTriggerDefinition
- ModifierDefinition
- RewardProfileDefinition
- BiomeDefinition
- DifficultyDefinition
- TierDefinition
- PacingProfile
- SpawnDirectorHints

## 11) Что не рекомендуется делать на старте
- много place под биомы
- 20 уровней внутри биома
- procedural generation окружения с нуля
- слишком много модификаторов одновременно
- строить фундамент вокруг node-map режима

## 12) MVP-объём
### P0
- 1 Raid place
- 3 биома: луга / лес / пещеры
- 3–5 tier'ов
- 2 сложности: Normal / Hard
- базовые волны
- базовые trigger-события
- модификаторы как отдельные сущности
- 1–2 mini-boss / elite сценария на поздних tier'ах

### P1
- больше trigger-типов
- более тонкий pacing
- больше arena themes
- больше биом-специфичных modifiers
- больше reward profile вариантов
- расширение mini-boss pool

### P2
- expedition mode
- node-map режим
- nightmare сложность
- seasonal / weekly модификаторы
- advanced director logic
