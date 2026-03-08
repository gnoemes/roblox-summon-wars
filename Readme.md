# Roblox Game Template

## Business Logic

> Fill this section after cloning the template for a specific game.

- **Game name:** TBD
- **Genre:** TBD
- **Description:** TBD
- **Core loop:** TBD
- **Audience:** TBD
- **Key features:** TBD

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
