# Class VFX Identity Table

> Документ задает визуальный язык классов для бойцов.
> Цель — сделать класс, редкость и момент силы читаемыми в auto-battle без перегруза экрана.

---

## Общие правила

### 1. Роль слоев
- **Archetype / model** — продает fantasy персонажа
- **Class VFX language** — продает стиль боя
- **Rarity VFX layer** — продает статус и редкость
- **Skill signature** — продает special moment

### 2. Базовое правило
VFX должны:
- усиливать читаемость;
- делать редкость и силу заметными;
- не ломать силуэт;
- не превращать бой в визуальный шум.

### 3. P0-слои
В P0 допустимы:
- idle aura (легкая / средняя)
- weapon glow / hand glow
- attack trail
- hit flash
- skill icon popup
- skill burst

Не брать в P0:
- тяжелые постоянные частицы
- орбиты / плавающие объекты
- сложные ground decals на каждом ударе
- отдельный уникальный набор VFX на каждого бойца

---

## Rarity VFX Baseline

| Rarity | Idle | Weapon / Hands | Attack | Skill | Goal |
|---|---|---|---|---|---|
| **Common** | почти чисто | нет или минимально | базовый | базовый | нормальный, не унылый |
| **Rare** | легкий контур / дымка | слабый glow | минимальный trail | чуть ярче | первая заметная редкость |
| **Epic** | заметная aura | устойчивый glow | читаемый trail | жирный burst | редкость читается издалека |
| **Legendary** | сильная signature aura | яркий energy glow | насыщенный trail / afterimage | выраженный каст / вспышка | юнит “онлайннулся” |
| **Mythic / Secret later** | уникальная aura формы | особый тип свечения | уникальное поведение trail | уникальный signature moment | статус + уникальность |

---

# Class VFX Identity

## 1. Rogue

| Layer | Direction |
|---|---|
| **Fantasy** | быстрый dual-blade / assassin / shadow striker |
| **Idle** | напряженный темный контур, тонкая нестабильная aura |
| **Weapon** | glow клинков, не слишком толстый |
| **Basic Attack** | короткие резкие slash trails, быстрый hit flash |
| **Motion Feel** | скорость, резкость, рваный темп |
| **Skill Signature** | cross-slash / shadow burst / afterimage strike |
| **Rarity Growth** | от легкого glow клинков → к shadow trail + afterimage на Legendary |
| **Do Not Do** | не делать жирный дымный эффект, который прячет руки и мечи |
| **Player Feeling** | “режет быстро, резко, опасно” |

### P0 package
- light blade glow
- short slash trail
- compact shadow skill burst
- small afterimage only on stronger skill or Epic+

---

## 2. Guardian

| Layer | Direction |
|---|---|
| **Fantasy** | тяжелый защитник / щит / frontliner |
| **Idle** | плотная стабильная aura, ощущение массы |
| **Weapon** | тяжелое свечение щита/оружия, не искрящееся, а “плотное” |
| **Basic Attack** | короткий heavy impact, не длинный trail |
| **Motion Feel** | тяжесть, устойчивость, давление |
| **Skill Signature** | shield pulse / guard wave / slam burst |
| **Rarity Growth** | от легкого shield edge glow → к мощному defensive pulse и aura shell |
| **Do Not Do** | не делать Guardian быстрым “аниме-лазером”, он должен ощущаться тяжелым |
| **Player Feeling** | “массивный, крепкий, удерживает” |

### P0 package
- stable body aura
- shield/weapon edge glow
- heavy hit flash
- block/defense pulse on skill

---

## 3. Mage

| Layer | Direction |
|---|---|
| **Fantasy** | spell caster / ranged magic pressure |
| **Idle** | glow рук / магический контур / мягкие частицы вокруг кистей |
| **Weapon / Hands** | главное свечение в руках или на фокусе/посохе |
| **Basic Attack** | чистый energy projectile / magical pulse |
| **Motion Feel** | кастует, а не просто стреляет |
| **Skill Signature** | rune circle / magic seal / beam burst / elemental wave |
| **Rarity Growth** | от hand glow → к cast circle, richer projectile core, stronger burst |
| **Do Not Do** | не превращать каждую атаку в огромный spell explosion |
| **Player Feeling** | “реально кастует силу, а не просто кидает шарик” |

### P0 package
- hand glow
- readable projectile
- simple rune flash on skill
- stronger burst on Epic+

---

## 4. Archer

| Layer | Direction |
|---|---|
| **Fantasy** | precision / ranged pressure / volley |
| **Idle** | легкий energy line around bow/weapon |
| **Weapon** | bow glow / arrow tip glow |
| **Basic Attack** | тонкий fast shot trail / bright hit line |
| **Motion Feel** | точность, скорость, чистота |
| **Skill Signature** | volley burst / piercing line shot / split shot flare |
| **Rarity Growth** | от light arrow glow → к multi-shot flash и richer shot trails |
| **Do Not Do** | не делать стрелка магом с рунами, он должен ощущаться как ranged weapon user |
| **Player Feeling** | “точный, быстрый, чистый дальник” |

### P0 package
- arrow tip glow
- clean line trail
- brighter crit flash
- volley burst on skill

---

## 5. Berserker

| Layer | Direction |
|---|---|
| **Fantasy** | ярость / brute force / savage melee |
| **Idle** | рваная агрессивная aura, будто “кипит” |
| **Weapon** | тяжелый горячий / violent glow |
| **Basic Attack** | широкий trail, резкий ударный flash |
| **Motion Feel** | мясо, сила, агрессия |
| **Skill Signature** | rage burst / ground smash / blood-red shockwave style |
| **Rarity Growth** | от rough aura → к violent aura burst, stronger slam effect, impact wave |
| **Do Not Do** | не делать слишком аккуратные и чистые эффекты |
| **Player Feeling** | “просто ломает лицо” |

### P0 package
- rough aura
- broad slash trail
- heavy impact flash
- simple rage burst on skill

---

## 6. Priest / Support

| Layer | Direction |
|---|---|
| **Fantasy** | heal / cleanse / empower / light support |
| **Idle** | мягкое спокойное свечение, light pulse |
| **Weapon / Hands** | glow hands / staff tip / support sigil |
| **Basic Attack** | не перегружать, базовая атака вторична |
| **Motion Feel** | поддерживает, а не доминирует basic-ударом |
| **Skill Signature** | heal wave / blessing ring / cleanse flash / buff crest |
| **Rarity Growth** | от gentle light pulse → к richer aura and cleaner support burst |
| **Do Not Do** | не делать support слишком “взрывным дд-шником” визуально |
| **Player Feeling** | “поддерживает, усиливает, спасает” |

### P0 package
- soft aura
- hand/staff glow
- compact blessing flash
- short ring pulse on skill

---

## 7. Occultist

| Layer | Direction |
|---|---|
| **Fantasy** | dark caster / curse / forbidden power |
| **Idle** | нестабильная темная aura, ощущение “плохой энергии” |
| **Weapon / Hands** | void glow / corrupted sigil / dark hand effect |
| **Basic Attack** | curse pulse / dark projectile / black-violet streak |
| **Motion Feel** | неприятный, опасный, мистический |
| **Skill Signature** | curse seal / void burst / corrupted wave |
| **Rarity Growth** | от weak corruption glow → к stronger void flare, seal patterns, richer burst |
| **Do Not Do** | не делать Occultist просто “еще одного Mage другого цвета” |
| **Player Feeling** | “грязная магия, неприятный контроль, проклятия” |

### P0 package
- corruption aura
- dark projectile
- curse seal flash
- stronger void burst on higher rarity

---

## 8. Jester / Trickster

| Layer | Direction |
|---|---|
| **Fantasy** | chaos / proc-based / weird utility |
| **Idle** | нестабильные искры / playful but dangerous vibe |
| **Weapon / Hands** | odd glow accents, нестандартная подача |
| **Basic Attack** | непредсказуемый flash pattern, но не визуальный мусор |
| **Motion Feel** | странный, хаотичный, “что-то сейчас случится” |
| **Skill Signature** | card burst / roulette flash / confetti-like strike but dangerous |
| **Rarity Growth** | от odd spark → к richer proc flash and more signature weirdness |
| **Do Not Do** | не превращать в клоунский цирк с радугой и шумом |
| **Player Feeling** | “хаос, проки, странная полезность” |

### P0 package
- subtle weird spark
- irregular but controlled hit flash
- card/sigil burst on skill

---

## 9. Monk / Fighter

| Layer | Direction |
|---|---|
| **Fantasy** | martial artist / focused body combat / combo striker |
| **Idle** | aura around fists / body focus / internal energy |
| **Weapon / Hands** | glow fists / gauntlets |
| **Basic Attack** | быстрые hand trails / combo flashes |
| **Motion Feel** | серия ударов, физический темп |
| **Skill Signature** | palm burst / aura strike / combo finisher wave |
| **Rarity Growth** | от hand glow → к aura fists, combo trails, stronger finisher flash |
| **Do Not Do** | не делать monk как rogue с ножами или mage с кастами |
| **Player Feeling** | “чистая техника, скорость, серия ударов” |

### P0 package
- fist glow
- short hand trails
- combo finisher flash
- aura burst on skill

---

# Readability Rules

## Combat readability
- **Basic attacks**: короткие, быстрые, не должны перекрывать enemy header
- **Skill effects**: заметнее, но краткие
- **Legendary+**: сильнее в idle и cast, но без постоянной wall-of-particles
- **All classes**: silhouette first, VFX second

## Screen noise rules
- не больше **1 активного заметного skill burst** на бойца одновременно
- не больше **1 idle aura family** на класс
- не давать всем одинаковый rarity halo
- attack speed усиливать через trail/hit rhythm, а не только через частицы

---

# P0 Implementation Priority

| Priority | Include |
|---|---|
| **Must Have** | idle aura baseline, weapon/hand glow, basic attack trail, skill burst, skill icon popup |
| **Good to Have** | better crit flash, Epic/Legendary amplification, short afterimage on fast classes |
| **Later** | orbitals, persistent class-specific particles, unique ground glyphs, summon entry effects |

---

# Final Design Rule

**Class VFX should answer three questions instantly:**
1. Кто это по роли?
2. Насколько он редкий?
3. Произошло ли сейчас что-то важное?