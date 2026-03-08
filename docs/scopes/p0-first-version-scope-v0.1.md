# P0 — First Version Scope v0.1

> **Статус:** production scope, не full vision.
> 
> Цель документа — зафиксировать, что именно должно войти в первую рабочую версию, чтобы валидировать ядро продукта, не раздувая проект.

---

# 1. Цель P0

Первая версия должна доказать 4 вещи:

1. **Спот реально работает как core shell**
2. **Бить моба приятно и хочется еще**
3. **Игрок чувствует резкий буст от новой системы**
4. **Карточки / ростер / Fusion создают retention, а не просто объем контента**

Если версия не доказывает это — остальные системы преждевременны.

---

# 2. Что входит в P0

## 2.1 Контент

### Один регион
- 1 social region space
- несколько спотов одного типа
- 1 рабочий stand prefab
- понятный visual language

### Hunting Grounds
- 3–4 обычных типа врагов
- 1 stronger target tier
- 1–2 special replacements:
  - elite
  - chest **или** rare enemy

### Один Dungeon
- 1 node-based Dungeon
- 3–4 encounter/stage
- более высокое давление, чем в Hunting Grounds
- ощутимо лучшая награда

---

## 2.2 Stand / Shell

### Один полноценный спот
Сразу в финальной логике shell, а не как временная болванка.

Должно быть:
- **Combat Core / портал**
- **Encounter Pad**
- **Guide / Mascot**
- **Social / Stat Board**
- HUD-кнопки:
  - **Battle**
  - **Guide**
  - **Fighters**

### Battle shell
- target / mode selection
- Dungeon card
- recommended squad power
- reward identity
- access status

### Guide shell
- **Recommended**
- **Tasks**
- **Craft**
- **Chest**

### Fighters shell
- **Squad**
- **Roster**
- **Fusion**
- Synergy **не обязателен в P0**

---

## 2.3 Combat core

- 3 активных бойца
- target-click combat
- interval / timer model
- 1 active target baseline
- enemy combat header
- basic damage / crit / attack speed feel

### Enemy Combat Header
Обязательный минимум:
- Enemy Name
- HP Bar
- Tier Badge
- optional short Threat Tag

---

## 2.4 Fighter loop

### Обязательный минимум
- cards
- card opening
- fighter generation
- active trio
- roster
- leveling
- grade contrast
- milestone 3
- Fusion

### Что важно доказать
- редкость ощущается
- сильный боец реально убивает быстрее
- milestone дает заметный spike
- Fusion решает судьбу лишних бойцов

---

## 2.5 Guided Reveal v1

Это часть продукта, а не полировка.

### Должно быть
- **Recommended** экран
- **Tasks**
- 1 короткая региональная цепочка
- 4–6 реактивных подсказок

### Что должна доказывать система
Игрок не просто бьет target бесконечно, а:
- упирается в friction
- получает подсказку
- применяет новый рычаг
- чувствует буст

---

## 2.6 Мини-экономика

### Достаточно для P0
- 2–3 resource types
- отдельный stack-based resource inventory
- chest только для consumables
- 1–2 craft paths
- 1–2 useful consumables
- 1 понятный equipment path

### Рекомендуемый baseline
- 1 equipment slot **или** очень ограниченный gear set
- 1 speed consumable **или** 1 survival consumable
- 1 понятный first craft payoff

---

## 2.7 Social / Stat Board

### Обязательный минимум
- Owner Name
- optional Title / Prestige marker
- 1 main stat
- 1–2 secondary stats

### Рекомендуемый baseline
- **Main:** Peak DPS **или** Highest Crit
- **Secondary:** Kill Streak
- **Secondary:** Region Kills

---

## 2.8 Минимальная монетизация

На старте не нужна широкая monetization architecture.

### Достаточно для P0
- Packs
- Fighter Storage
- Chest Slots

### Чего не делать в P0
- boosters
- subscription
- broad shop architecture
- prestige monetization layer

---

# 3. Что не входит в P0

## Системы, которые стоит убрать из первой версии
- Raid
- Synergy как обязательный слой
- Bestiary
- Contracts
- subscription
- широкая monetization depth
- широкий крафт
- все equipment slots сразу
- полный class roster
- prestige/cosmetics как отдельная система
- глубокая Ascension emphasis

---

# 4. Launch-safe class scope

Даже если в full vision остается 9 классов, в первой версии не стоит полировать весь roster одинаково.

### Рекомендуемый safe scope
- 4–5 реально читаемых и контрастных классов максимум

Цель — не ширина, а:
- читаемый feel
- понятные роли
- manageable balancing cost

---

# 5. Что именно валидирует P0

## Product validation
- Hunting Grounds loop не утомляет слишком быстро
- стенд считывается и ощущается как core object
- guided reveal реально приводит игрока к следующей полезной системе
- карта → боец → ростер → Fusion работают как retention loop
- спайки силы реально заметны

## UX validation
- Battle / Guide / Fighters shell не путает игрока
- enemy header помогает, а не захламляет бой
- social/stat board усиливает envy, а не превращается в мусор

---

# 6. Порядок реализации внутри P0

## Этап 1
- stand playable slice
- спот
- бой
- враг
- target select
- rewards

## Этап 2
- fighter loop
- cards
- roster
- level
- Fusion

## Этап 3
- guided reveal
- Recommended
- Tasks
- first chain
- first craft payoff

## Этап 4
- Dungeon
- hp persistence
- prep value
- better reward

## Этап 5
- минимальная monetization layer

---

# 7. Критерий готовности P0

P0 можно считать успешным, если:
- core stand loop играется без ощущения сырого прототипа
- игрок видит первый заметный power spike
- Dungeon ощущается как следующий meaningful step
- базовый retention строится без опоры на поздние системы
- игра уже не требует немедленного добавления Raid / Bestiary / Contracts, чтобы вообще работать
