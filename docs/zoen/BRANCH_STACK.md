# Zoen branch stack (upstream tracking)

## Remotes & long-lived branches

| Branch      | Role                                      |
| ----------- | ----------------------------------------- |
| `main`      | Clean mirror of `upstream/main` (FF only) |
| `zoen/main` | Product integration (default)             |
| `origin`    | `EnzoTironi/zoen-t3`                      |
| `upstream`  | `pingdotgg/t3code`                        |

## Topic branches (open from latest `main`, merge into `zoen/main`)

Use one concern per branch. Names match intended upstream PR slices:

| Branch                    | Concern                                              | Status                              |
| ------------------------- | ---------------------------------------------------- | ----------------------------------- |
| `zoen/grok-acp-parser`    | Shared `AcpRuntimeModel` sessionUpdate kinds         | Merged on `zoen/main`               |
| `zoen/grok-usage-meter`   | Prompt meta usage → context meter                    | Merged on `zoen/main`               |
| `zoen/grok-effort`        | Process-scoped `--reasoning-effort` restart          | Merged on `zoen/main`               |
| `zoen/grok-catalog`       | Slash/skills catalog publish                         | Merged on `zoen/main`               |
| `zoen/grok-plan`          | Plan mode via `/plan` text mapping + composer toggle | Merged on `zoen/main` (`270fd9465`) |
| `zoen/grok-multiagent`    | Subagent tools → `task.*` events                     | Merged on `zoen/main` (`270fd9465`) |
| `zoen/desktop-brand`      | Zoen logo + product name (`ZOEN_DESKTOP_BRAND=1`)    | Merged on `zoen/main` (`270fd9465`) |
| `zoen/web-sticky-options` | Sticky option fallback for sendTurn                  | Merged on `zoen/main`               |
| `zoen/branch-stack`       | Docs: stack policy + mobile validation               | Merged on `zoen/main` (`270fd9465`) |

Historical commits already landed on `zoen/main`. Going forward:

```bash
git fetch upstream
git checkout main && git merge --ff-only upstream/main && git push origin main
git checkout -b zoen/grok-<topic> main
# implement one concern → test → merge into zoen/main
git checkout zoen/main && git merge main && git merge zoen/grok-<topic>
```

Or use `./scripts/sync-upstream.sh` for the weekly `main` + `zoen/main` merge.

## Upstream PR policy

Only open **one topic branch per PR** onto `pingdotgg/t3code`, after an issue, rebased on latest `upstream/main`. Never a monolith of `zoen/main`.
