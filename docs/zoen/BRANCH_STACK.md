# Zoen branch stack (upstream tracking)

## Remotes & long-lived branches

| Branch | Role |
| ------ | ---- |
| `main` | Clean mirror of `upstream/main` (FF only) |
| `zoen/main` | Product integration (default) — tip of the stack below |
| `origin` | `EnzoTironi/zoen-t3` |
| `upstream` | `pingdotgg/t3code` |

## Linear stack (one concern per layer)

```text
main
 └── zoen/fork-meta                 docs + FORK.md + sync-upstream.sh
      └── zoen/grok-acp-parser      shared ACP model/events/runtime
           └── zoen/grok-native     catalog + effort + usage + auth/models core
                └── zoen/grok-plan  plan toggle + /plan text mapping
                     └── zoen/grok-multiagent  subagent tools → task.* events
                          └── zoen/web-sticky-options
                               └── zoen/desktop-brand
                                    = zoen/main
```

| Branch | Concern | Distinct tip? | Upstream? |
| ------ | ------- | ------------- | --------- |
| `zoen/fork-meta` (`zoen/branch-stack`) | Fork layout, stack policy, parity docs, sync script | Yes | No |
| `zoen/grok-acp-parser` | Shared AcpRuntimeModel / core events | Yes | Yes |
| `zoen/grok-native` | Provider core: catalog, effort, usage, auth, set_model | Yes | Yes (may re-slice) |
| `zoen/grok-plan` | Plan mode via `/plan` text + composer toggle | Yes | Yes |
| `zoen/grok-multiagent` | Subagent tools → `task.*` | Yes | Yes |
| `zoen/web-sticky-options` | Sticky sendTurn options + badge cleanup | Yes | Yes |
| `zoen/desktop-brand` | Zoen brandbook + `ZOEN_DESKTOP_BRAND=1` | Yes | No |

### Alias tips (still on `zoen/grok-native`)

Catalog / effort / usage remain **bundled inside** the native-core commit. Aliases point there for tracking until a further re-slice:

| Alias | Bundled in |
| ----- | ---------- |
| `zoen/grok-catalog` | `zoen/grok-native` |
| `zoen/grok-effort` | `zoen/grok-native` |
| `zoen/grok-usage-meter` | `zoen/grok-native` |

## How to work

```bash
./scripts/sync-upstream.sh          # FF main from upstream, merge into zoen/main
git checkout -b zoen/grok-<topic> <parent-layer>
# one concern → merge into zoen/main → restack if needed
```

## Upstream PR policy

- One topic branch per PR onto `pingdotgg/t3code`, rebased on latest `upstream/main`.
- Never open whole `zoen/main`.
- Never open fork-only layers (`fork-meta`, `desktop-brand`).
- Prefer issue → branch → PR for each upstreamable layer.

## Inspect

```bash
git log --oneline --decorate main..zoen/main
git branch -vv | rg 'zoen/'
```
