# Визуальная система мутаций питомцев (Roblox) — документация (черновик)

> **Статус:** рабочий план и примерная архитектура.  
> Это **не финальный “фундамент”**, а **пример реализации**, который нужно адаптировать под твой пайплайн, стиль моделей и ограничения платформы.

---

## 1) Цель и ограничения

### Цель
Сделать систему, где:
- у питомца есть **одна базовая модель**;
- список активных мутаций хранится как **данные**;
- визуал мутаций **накладывается процедурно** (prefab/материалы/FX) и работает на **разных моделях**, если они соответствуют стандарту.

### Главные ограничения (иначе ты утонешь)
1) **Визуальные каналы ограничены** (slot/channel system). Много мутаций в геймплее ≠ много геометрии на модели.
2) Визуал строится по принципу: **Resolver → VisualPlan → Diff/Apply**.
3) Reconcile **не должен ререндерить каждый кадр**. Он запускается **по dirty-событиям**.

---

## 2) Термины

- **Gameplay Mutation** — мутация как механика (статы/эффекты/синергии).
- **Visual Mutation / Visual Modifier** — как мутация отображается (каналы, шаги, FX).
- **Socket** — стандартная точка крепления на питомце (Attachment в Roblox).
- **Channel / Slot** — ограниченная категория визуала (например `BackSilhouette`, `Aura`).
- **Resolver** — детерминированно выбирает, что занять в каждом канале.
- **VisualPlan** — план: “что должно быть на модели”.
- **Applier** — применяет VisualPlan, удаляя/добавляя только разницу.

---

# Часть A — Работа 3D‑моделера (Blender / DCC)

## A1) Минимальные требования к базовой модели питомца

### 1) Единый масштаб и ориентация
- Все питомцы должны быть в **сопоставимом масштабе** (иначе префабы “рога/шипы” будут разъезжаться).
- Желательно, чтобы “вперёд” и “вверх” были консистентны между моделями (дальше это проверяется в Studio).

### 2) Риг (если используется)
- Если питомец анимируется скелетом: **единый базовый подход** к структуре костей (root/hips/spine/neck/head и т.д.).
- Но: визуальная система мутаций **не обязана** опираться на кости. Базовый вариант — sockets на MeshPart.

### 3) Разбиение на части (для гибкой покраски/материалов)
Чтобы визуальные мутации могли менять “кожу/глаза/акценты”, модельеру нужно обеспечить **предсказуемые группы**.
Варианты (выбери один и соблюдай везде):
- **Вариант 1 (лучше для контроля):** несколько MeshPart/мешей: `Body`, `Eyes`, `Accents`.
- **Вариант 2:** один меш + отдельные material slots/UV islands (но в Roblox часто проще управлять через части/группы).

**Важно:** цель не в “идеальной художественности”, а в **управляемости**.

---

## A2) Сокеты мутаций (Mutation Sockets) — что нужно подготовить

### Зачем
Ты хочешь “модули, работающие на всех моделях”. Это невозможно без стандарта сокетов.

### Что нужно
Список “обязательных” сокетов (MVP):
- `Socket_HeadTop`
- `Socket_Face`
- `Socket_Back`
- `Socket_TailBase`
- `Socket_BodyCenter`
- `Socket_LShoulder`
- `Socket_RShoulder`

Опционально:
- `Socket_FootL`, `Socket_FootR`
- `Socket_Spine1`, `Socket_Spine2`
- `Socket_Eyes`

### Как моделлеру это передать (2 практичных подхода)

**Подход 1 — моделлер даёт только гайд:**
- моделлер в Blender отмечает места сокетов (например empties/markers),
- а технически ты создаёшь Attachments в Roblox Studio вручную по референсу.

**Подход 2 — моделлер экспортирует “маркер‑объекты”:**
- создаются отдельные маленькие объекты/пустышки, которые экспортируются (как отдельные parts/meshes),
- в Studio ты конвертируешь их в Attachments и удаляешь маркеры.

> Выбор зависит от твоего импорта. Для MVP обычно быстрее **создавать Attachments прямо в Studio**.

### Требование по именованию
Имена сокетов должны быть **строго одинаковыми** у всех питомцев.  
Если сокета нет — визуальная мутация, требующая его, должна корректно “no-op” (не ломать модель).

---

## A3) Что НЕ нужно делать моделлеру (чтобы не усложнять)
- Не нужно заранее “вшивать” все варианты мутаций в модель.
- Не нужно готовить 100 отдельных мешей “на всякий случай”.
- Не нужно пытаться “закрыть всё геометрией”. Большая часть мутаций будет:
  - материал/паттерн,
  - цвет/эмиссия,
  - FX (аура/трейлы),
  - 1–2 силуэтных элемента.

---

# Часть B — Реализация в Roblox Studio / код

## B1) Структура ассетов в проекте (рекомендуемая)

```
ReplicatedStorage
  Assets
    Pets
      <SpeciesId>
        BaseModel (Model)
    Mutations
      Prefabs
        Horns_A (Model)
        Spikes_Back_A (Model)
      FXPresets
        Aura_Poison (Folder / ModuleScript preset)
        Trail_Energy (Folder / ModuleScript preset)
      Surface
        CrystalSkin (SurfaceAppearance)
        SlimeSkin   (SurfaceAppearance)

ServerStorage (опционально)
  HeavyAssets (если хочешь грузить на сервере только нужное)

StarterPlayer
  StarterPlayerScripts
    ClientWorld (Matter client) / или VisualController без ECS
```

---

## B2) Требования к модели питомца в Studio

В Studio у каждого питомца должна быть одинаковая структура (минимум):

```
PetModel (Model)
  PrimaryPart (например Root)
  Meshes (Folder) [опционально]
    Body (MeshPart)
    Eyes (MeshPart)
    Accents (MeshPart)
  MutationSockets (Folder)
    Socket_HeadTop (Attachment)
    Socket_Face (Attachment)
    Socket_Back (Attachment)
    ...
```

### Дополнительно (очень желательно)
- На MeshPart выставить атрибуты групп:
  - `MatGroup = "Body" | "Eyes" | "Accents"`
  - (или теги CollectionService — на твой вкус)

---

## B3) Каналы (slots) — “жёсткая рамка”, которая спасает проект

Пример набора каналов (MVP, не догма):

### Силуэт
- `HeadSilhouette` (0..1)
- `BackSilhouette` (0..1)
- `TailSilhouette` (0..1)

### Материал/паттерн
- `SkinMaterial` (0..1)
- `SkinPattern` (0..1)

### FX
- `Aura` (0..1)
- `Trail` (0..1)
- `MinorFX` (0..2, только High VFX)

> Каналы — это контракт. Мутаций может быть 30, но визуально активны будут, например, 6–8 вещей.

---

## B4) Data‑Driven описание визуала мутации

### Формат `MutationVisualDef` (пример)
Это **данные**, а не код бизнес‑логики.

```lua
-- ReplicatedStorage/Assets/Mutations/Defs/bio_spikes.lua
return {
  id = "bio_spikes",
  priority = 50,
  channels = { "BackSilhouette" },

  requiresSockets = { "Socket_Back" },

  steps = {
    { kind = "AttachPrefab", prefab = "Spikes_Back_A", socket = "Socket_Back" },
    { kind = "Tint", target = "Prefab", colorKey = "AccentColor" },
  },
}
```

### Поддерживаемые `steps` (MVP)
- `AttachPrefab(prefab, socket)`
- `Tint(target, colorKey)`
- `SetSurfaceAppearance(group, assetKey)`
- `AddParticles(socket, presetKey)`
- `AddTrail(socket0, socket1, presetKey)`

---

## B5) Resolver → VisualPlan → Diff/Apply (ядро)

### 1) Resolver
Вход:
- активные мутации (ids),
- контекст (speciesId, palette, vfxQuality, lodTier),
- таблица defs.

Выход:
- `VisualPlan`: что занято в каждом канале.

Пример:
```lua
VisualPlan = {
  BackSilhouette = { defId="bio_spikes", prefab="Spikes_Back_A", socket="Socket_Back" },
  Aura = { defId="poison_aura", preset="Aura_Poison", socket="Socket_BodyCenter" },
  SkinMaterial = { defId="crystal_skin", surface="CrystalSkin", group="Body" },
}
```

### 2) Diff
Сравнивает:
- `appliedPlan` (что было),
- `newPlan` (что надо).

Меняет **только разницу**:
- удаляет старое из канала,
- ставит новое.

### 3) Apply
Апплаер исполняет шаги и помечает созданные инстансы.

---

## B6) ECS Matter: рекомендуемая схема

### Компоненты (пример)
- `PetModelRef { model: Model }`
- `PetMutations { ids: {string}, seed: number }`
- `PetVisualContext { speciesId: string, palette: table, vfxQuality: "Low"|"High", lodTier: number }`
- `PetVisualState { appliedHash: string, byChannel: table }`
- `DirtyVisual { reason: string }` (tag)

### Системы (идея)
1) `MarkDirtyOnMutationChangeSystem`
2) `MarkDirtyOnModelReadySystem`
3) `MarkDirtyOnVfxQualityChangeSystem`
4) `VisualReconcileSystem` (только по `DirtyVisual`)

> Ключ: reconcile не “каждый tick”. Он event-driven.

---

## B7) Примерный код (псевдо / пример, не финальная реализация)

> Это демонстрация структуры. Придётся подогнать под твой стиль Matter/утилит, хранение assets и т.д.

### `VisualReconcileSystem` (псевдокод)
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local MutationDefs = require(Assets.Mutations.DefsIndex) -- { [id] = def }
local Prefabs = Assets.Mutations.Prefabs
local Surfaces = Assets.Mutations.Surface
local FXPresets = Assets.Mutations.FXPresets

local function getSockets(model)
  local socketsFolder = model:FindFirstChild("MutationSockets")
  if not socketsFolder then return nil end
  local sockets = {}
  for _, child in ipairs(socketsFolder:GetChildren()) do
    if child:IsA("Attachment") then
      sockets[child.Name] = child
    end
  end
  return sockets
end

local function resolvePlan(mutationIds, ctx, sockets)
  -- 1) собираем кандидатов по каналам
  -- 2) сортируем по priority
  -- 3) применяем правила конфликтов
  -- 4) строим VisualPlan
  return {
    -- пример результата
    -- BackSilhouette = {...}
  }
end

local function clearChannel(model, channelName)
  -- удаляем все инстансы с атрибутом MutChannel == channelName
  for _, inst in ipairs(model:GetDescendants()) do
    if inst:GetAttribute("MutVis") and inst:GetAttribute("MutChannel") == channelName then
      inst:Destroy()
    end
  end
end

local function applyStep(model, sockets, ctx, channelName, defId, step, runtimeState)
  if step.kind == "AttachPrefab" then
    local socket = sockets[step.socket]
    if not socket then return end

    local prefab = Prefabs:FindFirstChild(step.prefab)
    if not prefab then return end

    local clone = prefab:Clone()
    clone.Parent = model

    -- Тут ты сам решаешь, как “прикреплять”:
    -- - AlignPosition/AlignOrientation
    -- - WeldConstraint
    -- - или просто выставить CFrame относительно Attachment
    -- Для MVP часто достаточно: clone:PivotTo(socket.WorldCFrame)

    clone:PivotTo(socket.WorldCFrame)

    clone:SetAttribute("MutVis", true)
    clone:SetAttribute("MutChannel", channelName)
    clone:SetAttribute("MutDefId", defId)

  elseif step.kind == "SetSurfaceAppearance" then
    -- пройтись по MeshPart в нужной группе и назначить SurfaceAppearance
    local surface = Surfaces:FindFirstChild(step.assetKey)
    if not surface then return end

    for _, inst in ipairs(model:GetDescendants()) do
      if inst:IsA("MeshPart") and inst:GetAttribute("MatGroup") == step.group then
        local sa = surface:Clone()
        sa.Parent = inst
        sa:SetAttribute("MutVis", true)
        sa:SetAttribute("MutChannel", channelName)
        sa:SetAttribute("MutDefId", defId)
      end
    end

  elseif step.kind == "AddParticles" then
    local socket = sockets[step.socket]
    if not socket then return end
    local preset = FXPresets:FindFirstChild(step.presetKey)
    if not preset then return end

    if ctx.vfxQuality == "Low" then return end -- LQ режем сразу

    local fx = preset:Clone()
    fx.Parent = socket
    fx:SetAttribute("MutVis", true)
    fx:SetAttribute("MutChannel", channelName)
    fx:SetAttribute("MutDefId", defId)
  end
end

local function applyPlan(model, sockets, ctx, plan, prevState)
  prevState = prevState or { byChannel = {} }

  for channelName, entry in pairs(plan) do
    local prev = prevState.byChannel[channelName]
    local changed = (not prev) or (prev.defId ~= entry.defId)

    if changed then
      clearChannel(model, channelName)

      local def = MutationDefs[entry.defId]
      if def then
        for _, step in ipairs(def.steps) do
          applyStep(model, sockets, ctx, channelName, def.id, step, prevState)
        end
      end

      prevState.byChannel[channelName] = { defId = entry.defId }
    end
  end

  -- каналы, которые были, но исчезли
  for channelName, prev in pairs(prevState.byChannel) do
    if not plan[channelName] then
      clearChannel(model, channelName)
      prevState.byChannel[channelName] = nil
    end
  end

  return prevState
end

-- Matter system body (примерно)
return function(world)
  for id, modelRef, muts, ctx, state, dirty in world:query(PetModelRef, PetMutations, PetVisualContext, PetVisualState, DirtyVisual) do
    local model = modelRef.model
    if not model or not model.Parent then
      world:remove(id, DirtyVisual)
      continue
    end

    local sockets = getSockets(model)
    if not sockets then
      -- нет сокетов — просто снимаем dirty, но можно и логировать
      world:remove(id, DirtyVisual)
      continue
    end

    local plan = resolvePlan(muts.ids, ctx, sockets)
    local newState = applyPlan(model, sockets, ctx, plan, state)

    world:replace(id, PetVisualState, newState)
    world:remove(id, DirtyVisual)
  end
end
```

---

## B8) Где хранить “истину” и как реплицировать (практично)

### Рекомендуемо
- **Сервер** хранит активные мутации и выдаёт их клиенту.
- **Клиент** строит визуал локально.

Практичный “MVP способ”:
- сервер ставит на модель атрибуты:
  - `MutationsPacked` (строка/JSON/битпак)
  - `MutationSeed` (число)
  - `PalettePacked` (строка)
- клиент слушает изменения атрибутов → добавляет `DirtyVisual`.

Плюсы:
- меньше сетевого мусора,
- можно легко делать LOD/LowVFX только на клиенте.

---

## B9) Производительность (обязательно заложить сразу)

### Лимиты (MVP рекомендации)
- Силуэт‑частей (prefab models) на пета: **0–3**
- ParticleEmitter одновременно: **0–1** (Low) / **0–3** (High)
- Trails: **0–1**
- Вдалеке: **0** частиц, **0** трейлов

### LOD политика
- `lodTier 0` (близко): всё разрешено
- `lodTier 1`: без MinorFX
- `lodTier 2` (далеко): только силуэт + материал, без FX

### Важное правило
FX и мелкая геометрия должны уметь **выключаться без пересборки** (по контексту).

---

## B10) Контентная дисциплина (иначе всё развалится)

### Нейминг и контракты
- Сокеты **одинаковые**.
- Каналы **ограничены**.
- Префабы **не завязаны** на конкретного питомца.

### Совместимость
В `MutationVisualDef` всегда указывай `requiresSockets`.  
Если сокета нет — деф просто не применяется.

---

## B11) Чек‑лист тестов (минимум)

1) 20 случайных наборов мутаций на одном питомце:
   - нет ошибок,
   - нет “накопления мусора” в модели.
2) Те же наборы на другом виде питомца:
   - сокеты работают,
   - префабы не улетают.
3) Переключение `Low/High VFX`:
   - FX корректно пропадают/возвращаются.
4) LOD (далеко/близко):
   - FX отключается,
   - силует/материал остаются.
5) Перезагрузка персонажа / respawn:
   - визуал восстанавливается детерминированно.

---

## B12) Типичные ошибки (предупреждение)

- Делать reconcile каждый кадр → GC и лаги.
- Не иметь сокетов → “модульность” превращается в ручные костыли.
- Не иметь каналов → комбинаторный ад.
- Реплицировать визуальные инстансы с сервера → трафик и боль.
- Не помечать созданные объекты → невозможность чистки.

---

# Приложение: рекомендуемые “следующие шаги” (MVP)

1) Один питомец + 7 сокетов + 3 группы материалов.
2) 3 мутации:
   - `Horns` (HeadSilhouette)
   - `BackSpikes` (BackSilhouette)
   - `PoisonAura` (Aura, High only)
3) Resolver по priority и 6 каналам.
4) VisualPlan + Diff/Apply + cleanup по атрибутам.
5) Включить Low/High VFX и простой distance LOD.

---

**Конец документа.**
