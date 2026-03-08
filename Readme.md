# Roblox Game: Anime Summon Wars

## Business Logic

- **Game name:** Anime Summon Wars *(working title)*
- **Genre:** Social anime-style squad battler / auto-battle progression RPG
- **Description:** Roblox-игра про сбор и усиление отряда из 3 бойцов, где игрок фармит врагов на своем battle stand, открывает карты, улучшает состав, проходит Dungeons и позже Raids, постепенно раскрывая новые системы прогрессии через guided progression.
- **Core loop:** Открыть/усилить бойцов → собрать трио → выбрать цель на споте → смотреть auto-battle и получать награды → конвертировать награды в силу через leveling / Fusion / craft / prep → пройти более сложный контент → открыть следующий слой прогрессии.
- **Audience:** Игроки Roblox, которым нравятся anime-inspired игры, collection/progression loops, быстрый дофаминовый рост силы, idle/auto-battle формат и социальное сравнение с другими игроками.
- **Key features:**
    - battle stand / combat spot как основной игровой shell
    - отряд из **3 бойцов**
    - **target-click auto-combat**
    - карты бойцов и сбор ростера
    - сильная прогрессия через **levels, milestones, Fusion**
    - **Regional Progression** как главный meta-layer
    - **Hunting Grounds, Dungeon, Raid**
    - **guided reveal**: Recommended / Tasks / reactive prompts
    - social/stat board на споте
    - быстрые power spikes, большие цифры, акцент на attack speed и feel growth
---

## Technical Overview

This template already includes:

- Rojo
- Wally
- Matter
- Selene
- StyLua
- mise
- PowerShell scripts in `tools/`
- multi-place support
- `AGENTS.md` for agent workflow

## Project Structure

```text
mise.toml
wally.toml
wally.lock
selene.toml
.stylua.toml

common/
  src/
    shared/        # pure logic/data/protocols/utils
    server/        # shared server code
    client/        # shared client code

places/
  hub/
    default.project.json
    src/
      server/
      client/

  raid/
    default.project.json
    src/
      server/
      client/
```

## After Cloning the Template

### 1. Change git origin

```bash
git remote remove origin
git remote add origin <NEW_REPO_URL>
git branch -M main
git push -u origin main
```

### 2. Change place name in Hub config

File:

```text
places/hub/default.project.json
```

Replace the `name` field with the new project/place name.

### 3. Change package name in `wally.toml`

Update:

```toml
name = "yourname/your-game"
```

### 4. Create an IDEA Run Configuration

Script:

```text
tools/Dev.ps1
```

Arguments example:

```powershell
-Command start -Place hub -Port 34872
```

## Quick Start

Install tools:

```bash
mise install
```

Install dependencies:

```bash
wally install
```

Start dev session:

```powershell
./tools/Dev.ps1 start -Place hub -Port 34872
```

Then open Roblox Studio and connect through Rojo.

## Multi-place

To add a new place:

1. Create a new folder in `places/`
2. Add `default.project.json`
3. Add `src/server` and `src/client`
4. Run `tools/Dev.ps1` with the new place name

Example:

```text
places/
  arena/
    default.project.json
    src/
      server/
      client/
```

## Main Scripts

### `tools/Dev.ps1`
Controls local dev session:
- starts `rojo serve`
- starts sourcemap watcher
- writes logs to `.dev/`
- supports `start / stop / restart / status`

### `tools/Deps.ps1`
Runs:

```powershell
mise install
wally install
```

### `tools/Fmt.ps1`
Runs StyLua formatting.

### `tools/Lint.ps1`
Runs Selene linting.

### `tools/Check.ps1`
Runs format + lint + validation/build.

### `tools/TailLogs.ps1`
Shows dev logs from `.dev/logs/`.

## Recommended Workflow

### Start session

```powershell
./tools/Deps.ps1
./tools/Dev.ps1 start -Place hub -Port 34872
```

### Before commit

```powershell
./tools/Check.ps1
```

### End session

```powershell
./tools/Dev.ps1 stop -Place hub
```

## Checklist

- [ ] Change `git origin`
- [ ] Update `places/hub/default.project.json`
- [ ] Update `wally.toml`
- [ ] Create IDEA Run Configuration for `tools/Dev.ps1`
- [ ] Run `mise install`
- [ ] Run `wally install`
- [ ] Start `tools/Dev.ps1`
- [ ] Connect Rojo in Roblox Studio
