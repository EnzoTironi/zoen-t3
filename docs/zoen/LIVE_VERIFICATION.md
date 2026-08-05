# Live verification log (Grok parity residuals)

## Multi-agent (2026-08-05)

Probe: `grok agent --always-approve stdio` with prompt forcing `spawn_subagent`.

| Check | Result |
|-------|--------|
| Session new + prompt | OK |
| `tool_call` title `spawn_subagent` | OK (call-9d839974-…) |
| Status completed + subagent_id | OK |
| `isGrokSubagentToolCall` matches live shape | OK (`true`) |

Stack layer: `zoen/grok-multiagent` maps that tool call to `task.started` / `task.completed`.

## Plan entry

| Check | Result |
|-------|--------|
| Unit: `applyGrokPlanModeToPromptText` | OK |
| test-t3-app: Plan toggle + `/plan` slash for Grok | OK (earlier session) |

## Mobile

See `MOBILE_GROK_VALIDATION.md`. No app code changes; device client not installed on this host.

## Upstream

Opened on `pingdotgg/t3code` (heads from `EnzoTironi/t3code`):

| Slice | Issue | PR | Size | Status |
|-------|-------|-----|------|--------|
| ACP parser (shared) | #5417 | [#5422](https://github.com/pingdotgg/t3code/pull/5422) | ~+379 / 6 files | Open — merge first |
| Grok native parity (adapter) | #5418–#5420 | [#5423](https://github.com/pingdotgg/t3code/pull/5423) | ~+2.3k Grok delta | Open — includes plan + multi-agent + compact + effort set_model |
| Web sticky options | #5421 | [#5426](https://github.com/pingdotgg/t3code/pull/5426) | ~+237 / 4 files | Open — independent of server |
| Plan-only tip | #5419 | #5424 | — | **Closed** (folded into #5423) |
| Multi-agent-only tip | #5420 | #5425 | — | **Closed** (folded into #5423) |

Heads rebuilt from `upstream/main` with tip product code (not cumulative XXL dumps). Bodies follow CONTRIBUTING What/Why/UI/Checklist.

Fork-only: `zoen/fork-meta`, `zoen/desktop-brand`.

Learnings + agent review: [UPSTREAM_GROK_PR_LEARNINGS.md](./UPSTREAM_GROK_PR_LEARNINGS.md).
