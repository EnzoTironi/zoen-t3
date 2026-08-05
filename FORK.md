# Zoen T3 fork

Public product fork of [pingdotgg/t3code](https://github.com/pingdotgg/t3code).

Goal: **full upstream source sync** + **Zoen-only features**, without fighting every T3 merge.

Upstream has no first-party fork-maintenance guide. This file is ours.

## Remotes

| Remote | URL | Role |
|--------|-----|------|
| `origin` | `https://github.com/EnzoTironi/zoen-t3.git` | Our product repo |
| `upstream` | `https://github.com/pingdotgg/t3code.git` | Official T3 Code |

```bash
git remote -v
# origin    …/EnzoTironi/zoen-t3.git
# upstream  …/pingdotgg/t3code.git
```

Local clone path (this machine): `~/Code/forks/zoen-t3`

Keep `~/Code/forks/t3code` as a pure upstream-tracking clone for T3 worktrees / reading mainline. Do product work in `zoen-t3`.

## Branches

| Branch | Tracks | Purpose |
|--------|--------|---------|
| `main` | `upstream/main` (mirror) | Clean T3 tip. No Zoen commits. Fast-forward only. |
| `zoen/main` | product default | Upstream + all Zoen features. Day-to-day branch. |
| `zoen/<topic>` | off `zoen/main` | Feature work. Squash or rebase onto `zoen/main`. |
| `sync/upstream-YYYYMMDD` | temp | Optional: conflict resolution for a big import. |

Do **not** put Zoen commits on `main`. That keeps `main` a trivial mirror and makes “how far behind are we?” one command:

```bash
git fetch upstream
git rev-list --left-right --count main...upstream/main
# 0 0  → in sync
# 0 N  → N commits to fast-forward
```

### Default branch

GitHub default can stay `main` (mirror) or switch to `zoen/main` for clone-and-go. Prefer **`zoen/main`** as default once you ship product commits so casual clones get Zoen.

```bash
gh repo edit EnzoTironi/zoen-t3 --default-branch zoen/main
```

## Sync cadence

T3 moves fast. Treat sync as routine maintenance, not a quarterly event.

| Trigger | Action |
|---------|--------|
| **Weekly** (or after every interesting upstream release) | Fast-forward `main`, merge into `zoen/main` |
| **Before starting a large Zoen feature** | Sync first so you build on current contracts |
| **After a painful conflict week** | Pause features, finish sync, then resume |
| **Security / break-glass** | Sync immediately |

### Weekly sync (merge strategy)

Merge keeps history honest and avoids force-push on a shared product branch.

```bash
cd ~/Code/forks/zoen-t3
git fetch upstream
git checkout main
git merge --ff-only upstream/main
git push origin main

git checkout zoen/main
git merge main -m "chore(sync): merge upstream main $(git rev-parse --short main)"
# resolve conflicts → build/test → push
git push origin zoen/main
```

Or: `./scripts/sync-upstream.sh`

### When to rebase Zoen instead

If `zoen/main` has **few, clean, well-scoped** commits and you are the only writer, periodic rebase is fine:

```bash
git checkout zoen/main
git rebase main
# fix conflicts per commit
git push --force-with-lease origin zoen/main
```

Prefer **merge** once multiple people or agents land on `zoen/main`.

### Conflict triage order

Resolve in this order (highest churn / risk first):

1. `packages/contracts` — wire formats; fix first so the rest typechecks
2. `apps/server` orchestration (decider, projector, reactors)
3. Provider adapters under `apps/server`
4. `packages/client-runtime`
5. UI (`apps/web`, `apps/mobile`, `apps/desktop`)

If a Zoen patch repeatedly conflicts in (1)–(3), move the behavior behind a thinner seam (see below).

## Where Zoen code should live

**Principle:** new paths merge cleanly; edited upstream files cost forever.

### Prefer (low merge pain)

| Location | Use for |
|----------|---------|
| `packages/zoen-*` | Shared Zoen logic, Effect services, pure helpers |
| `apps/zoen-*` | Optional Zoen-only surfaces (if ever separate from web) |
| `docs/zoen/` | Product / fork ops docs (this guide can move there later) |
| `scripts/zoen-*.ts` | Zoen-only tooling |
| `assets/zoen/` | Brand overrides that do not replace T3 asset pipelines wholesale |
| Thin **registration** edits | One import + one registry line in upstream files |

### Acceptable (medium pain)

- Feature-flagged branches inside existing UI components
- New RPC methods / orchestration commands **namespaced** clearly (`zoen.*`) in contracts — still touches hot files, but localized
- Provider driver **additions** (new folder + registry entry) rather than rewriting Codex/Claude drivers

### Avoid (high pain)

- Rewriting orchestration core (event store, projector loop, DrainableWorker)
- Broad CSS / layout rewrites of chat shell without isolation
- Renaming `@t3tools/*` packages or the `t3` CLI globally
- Copying large upstream files into Zoen paths and diverging (“vendor forks” inside the monorepo)
- Editing `patches/` for pnpm unless you must; they collide with upstream pin bumps

### Integration pattern

```
upstream UI / server
        │
        ▼
  single registration hook  (import from @zoen/... or packages/zoen-*)
        │
        ▼
  packages/zoen-*  (all real logic lives here)
```

When upstream refactors the registration file, you re-hook one call site instead of replaying a feature onto a rewritten module.

## Branding and release

MIT license stays; keep the T3 Tools copyright notice. Add Zoen copyright for original Zoen files.

For a **distinct product binary** later:

- Desktop / mobile update feeds: point at **our** GitHub releases, not T3’s (`T3CODE_DESKTOP_UPDATE_REPOSITORY` and related env — see upstream `docs/operations/release.md`)
- Do not ship as “T3 Code” in stores; rename product strings and bundle IDs when you distribute
- Web: own origin; do not bake `app.t3.codes` into a Zoen-branded build

Until you care about distribution, run from source:

```bash
# install vp once: https://viteplus.dev
vp i
vp run dev
```

Worktree state: use this clone’s `.t3` (or `vp run dev`); never write to `~/.t3/userdata`.

## Day-to-day workflow

```bash
# feature
git checkout zoen/main && git pull
git checkout -b zoen/my-feature
# … commits …
git push -u origin zoen/my-feature
# PR into zoen/main (not into main)

# after merge
git checkout zoen/main && git pull
```

Contributing **back** to T3: branch from `main` (or `upstream/main`), cherry-pick or reimplement without Zoen paths, PR to `pingdotgg/t3code`. Expect upstream to ignore large feature PRs (`CONTRIBUTING.md`).

## Health checks after sync

Smallest useful proof (do not run full monorepo CI unless you want the wait):

```bash
vp i
# touch what you own, e.g.:
vp test run packages/zoen-*/src/**/*.test.ts   # when packages exist
vp run --filter t3 typecheck                   # if server touched
vp run --filter @t3tools/web typecheck         # if web touched
```

Smoke: `vp run dev`, pair, open a thread, one provider turn.

## Anti-patterns

1. **Committing Zoen work on `main`** — ruins the clean mirror.
2. **Giant “sync + features” commits** — split `chore(sync): …` from feature commits.
3. **Silent package renames** — breaks every upstream import hunk.
4. **Depending on T3 Connect / their Clerk / their update CDN** for Zoen production without a deliberate contract.
5. **Letting `zoen/main` drift > ~2 weeks** without a sync attempt — conflicts compound.

## Quick reference

```bash
# how far behind
git fetch upstream
git log --oneline main..upstream/main | head

# sync
./scripts/sync-upstream.sh

# product work
git checkout zoen/main
```

Repo: https://github.com/EnzoTironi/zoen-t3  
Upstream: https://github.com/pingdotgg/t3code
