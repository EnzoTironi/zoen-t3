# Upstream Grok PR learnings (2026-08-05)

Validated against `pingdotgg/t3code` open + merged Grok work, CONTRIBUTING, PR/issue templates, and agent review comments on our stack **#5422–#5426**.

## Contributing rules (how they constrain us)

Source: `CONTRIBUTING.md`, `.github/pull_request_template.md`, size/vouch workflows.

| Rule | Implication for Grok work |
| ---- | ------------------------- |
| Not actively accepting contributions | High chance of close/defer. Issues first for non-trivial work. |
| Prefer small bug fixes / reliability | Split lakes; avoid mega-features. |
| Reject 1,000+ line feature dumps | **size:XXL** (#5423–#5425) is a red flag vs Ahmed's **size:L** single-concern PRs. |
| One concern per PR; no mixed fixes | Stack tips must be true single-concern diffs, not cumulative product dumps. |
| UI → before/after images; motion → video | Web sticky / plan toggle need screenshots if reopened for UI. |
| `vouch:unvouched` until listed | All external authors (us + Ahmed) are unvouched. Not a quality signal. |
| `size:XS`…`XXL` | Effective lines exclude pure test files in mixed PRs; still flag XXL hard. |

**Template structure (PRs must use):**

```md
## What Changed
## Why
## UI Changes   (or delete)
## Checklist
- [ ] small and focused
- [ ] explained what/why
- [ ] UI screenshots if needed
- [ ] video if motion
```

**Issue forms:** bug_report.yml / feature_request.yml (area, repro or problem, smallest scope, impact). Freeform issues we filed are weaker than form-shaped ones.

---

## Merged Grok PRs — what shipped and stuck

| PR | Author | Size | Lesson |
| -- | ------ | ---- | ------ |
| **#2809** | Jaaneek | XXL | Initial Grok ACP provider (`grok agent stdio`). Product entry accepted once. Large provider PRs can land from maintainers/friends; externals should not copy this size. |
| **#3156** | mwolson | XXL | Harden resume, `prompt_complete` race, replay-idle load, root-session filter. Child sessions deliberately ignored (V1). Multi-agent is a later layer. |
| **#4218** | mwolson | L | No spurious wake after in-turn monitors. Grok multiturn + monitors need careful wake evidence. |
| **#3578** | mwolson | huge | V2 settlement, background tasks, steer, images — maintainer orchestration work. |
| **#4586** | Wraient | M | Mobile provider icons for Grok/Cursor/OpenCode. **Canonical small PR shape**: one file, before/after screenshots, checklist. |
| **#4094** | BunnyGamezsc | S | Cursor binary `cursor-agent` avoids path clash with Grok `agent`. |
| **#3484** | Aditya | S | Marketing provider list only. |

### Patterns that get merged

1. **Narrow, user-visible bug** with screenshots (#4586).
2. **Reliability on the live ACP wire** (prompt settle, resume, wake) with focused tests (#3156, #4218).
3. **Maintainer-owned large provider work** (#2809, orchestration v2) — not the external default.

### Closed without merge (still useful)

| PR | Why closed | Keep the idea? |
| -- | ---------- | -------------- |
| **#4233** plan cards | Julius: V1 base removed by #2829; reimplement on V2 | Yes — same lake as #5409 / our plan path |
| **#3784** auth preflight | Same V1 close | Yes — fail-fast unauthenticated CLI |
| **#3839** prompt_complete | Superseded / partial land in hardens | Partially in tree via XAi completion |
| **#3904** Grok 4.5 OAuth | Closed (stale) | Check if still needed on live CLI |

---

## Open community Grok PRs vs zoen

### Ahmed Besic (best external hygiene)

| PR | Concern | Size | vs zoen |
| -- | ------- | ---- | ------- |
| **#5403** effort | Map `_meta.reasoningEfforts` → `optionDescriptors`; apply via **`session/set_model` `_meta`** in place (no process restart). Explicitly rejects #5160 spawn-only approach. | +285 / 7 files | **Different approach.** We use **CLI `--reasoning-effort` + process restart**. Live probe earlier found set_config_option fails; Ahmed claims set_model `_meta` works mid-thread. **Must re-probe** before abandoning process-scoped path. If set_model works, it is strictly better (no session.exited, no lock gap). |
| **#5405** usage | `usage_update` + stream `_meta.totalTokens` + prompt `_meta` → context meter; Cursor no-op for exhaustive union; small web `contextWindow` polish | +657 / 9 files | Overlaps our usage path. Ahmed is tighter; bot notes zero-token fields dropped and ambiguous window fallback — absorb those polish bits. |
| **#5409** plan approval | Handle `x.ai/exit_plan_mode`, emit proposed-plan card, abandon (not auto-implement), stream **plan.md** mid-plan | +551 / 5 files | **They are more complete on plan *surface*** (card + exit gate). We are more complete on plan *entry* (`/plan` text + composer toggle). Product needs both. Bot: stale markdown, any `**/plan.md` path, shared stamp — real risks if we cherry-pick. |
| **#5412** compact | Advertise `/compact`; handle `session_notification` `auto_compact_completed` → compacted work-log | +245 / 7 files | **We do not have this.** Small high-value absorb for zoen. |

### Others

| PR | Note |
| -- | ---- |
| **#5160** mwolson effort | **Ignore for merge shape**: +159k/−75k, 828 files — whole branch dump. Idea (spawn `--reasoning-effort`) matches ours; packaging is unreviewable. |
| **#5131** fm1randa skills | Empty `/` `$` pickers (#4109). Real product gap; bot found catalog race bugs; some resolved. Overlaps our catalog work — prefer their focused catalog PR if upstream wants skills alone. |
| **#4542** marketing Grok mark | UI-only layout. Irrelevant to provider parity. |

### Completeness scoreboard (product lake, not mergeability)

| Lake | Winner | Gap to close |
| ---- | ------ | ------------ |
| ACP parser / sessionUpdate | Ours #5422 + Ahmed #5405 overlap | Keep shared parser; slim upstream tip |
| Effort UI + apply | Contested | Re-verify `set_model` `_meta` vs process restart |
| Usage meter | Tie; Ahmed polish edges | Zero tokens, window fallback, no double emit |
| Plan entry (composer → /plan) | **Ours** | — |
| Plan surface (exit_plan_mode card + plan.md) | **Ahmed #5409** | Absorb carefully |
| Multi-agent task.* | **Ours only** | Fix shared stamp + dedupe |
| Compact feedback | **Ahmed #5412** | Absorb |
| Sticky options | **Ours #5426** | Fix model override bug |
| Catalog/skills picker | Overlap #5131 | Prefer small focused PR |
| Auth preflight | Closed #3784 idea | Optional absorb |

**Overall:** zoen product lake still leads (plan entry + multi-agent + sticky + desktop brand). Ahmed wins **upstream review shape** and several **completion edges** (plan card, compact, usage polish). #5160 is noise.

---

## Agent comments on our PRs — validation

Agents present: CodeRabbit (reviews **disabled**, noise only), Macroscope (approvability + inline), Cursor Bugbot (high/medium severity).

### Real — fix on zoen/main and restack before any re-push

| Finding | PR | Verdict | Why |
| ------- | -- | ------- | --- |
| **Shared stamp for tool + task.\*** | #5425 | **Real HIGH** | `task.started`/`completed` reuse tool-call `stamp` → same `eventId` → activity PK collision drops multi-agent row. Code: `GrokAdapter` ToolCallUpdated ~1273 spreads `...stamp`. Needs fresh `makeEventStamp()`. |
| **Repeated task.started on every pending/inProgress update** | #5425 | **Real MED** | No per-taskId guard; ACP sends tool_call + updates. Need emit-once map. |
| **Sticky overrides thread model** | #5426 | **Real HIGH** | `activeSelection = … ?? stickySelection` then `selectedModel` from sticky. Intent was options-only. Confirmed in `composerDraftStore.ts` ~1018–1037. Bugbot + Macroscope agree. |
| **Sticky options key under wrong instanceId** | #5426 | **Real MED** | Fallback map keyed by sticky's own instance, not `stickyInstanceKey`. |
| **Duplicate token usage (RPC + ensuring)** | #5423–25 | **Real MED** | Happy path calls `offerGrokPromptTokenUsage` then ensuring does again when `promptRpcSucceeded`. |
| **Empty live catalog keeps stale slash/skills** | #5423–25 | **Real MED** | `mergeCommandCatalog` uses `length > 0` as "has live". Empty clear never wins. |
| **preferredModelMeta wrong fallback** | #5423–25 | **Real MED** | `preferredMatch?._meta ?? models[0]._meta` when match has no meta steals another model's window/effort. |
| **isGrokSubagentToolCall substring `subagent`** | #5425 | **Real MED (policy)** | Live title is `spawn_subagent` (verified). Broad `subagent` match can false-positive. Prefer `data.name` / exact tool names; keep spawn_subagent first. |
| **Empty attachment-only plan → no /plan** | #5424 | **Real MED** | `applyGrokPlanModeToPromptText` early-returns on blank text. Should emit `/plan` alone. |
| **Effort restart → session.exited** | #5423 | **Real if process restart kept** | Bugbot high. If we keep CLI restart, need silent restart without orchestration stop; if set_model works, delete path. |
| **Lock gap during effort restart** | #5423 | **Real if restart kept** | Unlock between delete and startSession. |

### Real but lower urgency / defensive

| Finding | Verdict |
| ------- | ------- |
| Untyped `initializeMeta.availableCommands` / `modelState` throws | **Real defensive.** Live Grok is well-formed; still guard for health-probe hardness. Our `parseGrokAvailableCommandsFromMeta` already guards commands; modelState path still weaker. |
| Usage dropped when `activeTurnId` cleared | **Plausible** for late usage_update after xAI settle. Prompt `_meta` path is the intentional backup. |

### Noise / ignore

| Source | Note |
| ------ | ---- |
| CodeRabbit skip-review spam | Auto reviews off; no signal. |
| Macroscope “Needs human review” approvability | Policy label, not a defect list. |
| Duplicate findings across stacked PRs | Same base commit; fix once at tip. |

### Ahmed PR agent notes worth stealing

- #5405: preserve **zero** token breakdowns; don’t fall back to arbitrary model window when multi-model.
- #5409: reset plan markdown per turn; don’t treat every `**/plan.md` as Grok session plan; unique stamps for proposed vs tool events.

---

## Upstream strategy (introspected)

1. **Do not expect #5423–#5425 to merge as-is.** size:XXL + multi-feature stack + unvouched + open competing L-size PRs.
2. **Prefer coordination over competition** with Ahmed: effort (#5403 vs process restart), usage (#5405), plan surface (#5409), compact (#5412). Our unique lakes: multi-agent, plan entry, sticky options (fixed), desktop brand (fork-only).
3. **Re-slice for upstream** only after high bugs fixed, as true single-concern diffs that do **not** include full stack product:
   - parser only (#5422 shape is closest to acceptable size:L)
   - effort only (either adopt set_model or document restart)
   - usage only
   - plan entry only
   - multi-agent only (after stamp fix)
   - sticky only (after model override fix)
4. **Fork product (`zoen/main`)** absorbs Ahmed completeness (plan card, compact, usage polish) regardless of upstream fate.
5. **Issues first** for anything new; use feature_request form fields (problem, smallest scope, tradeoffs).

---

## Action checklist

### Must fix on zoen (correctness)

- [x] Fresh stamp for `task.*` events; dedupe by toolCallId/taskId
- [x] Sticky: options-only fallback; never override thread `selectedModel`
- [x] Sticky: re-key options map to selected instance
- [x] Deduplicate prompt token-usage offer
- [x] `mergeCommandCatalog` empty-live propagation
- [x] `preferredModelMeta` no cross-model meta steal
- [x] Plan blank text → `/plan`
- [x] Tighten `isGrokSubagentToolCall`
- [ ] Effort restart without `session.exited` / lock gap (or adopt #5403 set_model)

### Absorb from community

- [ ] #5409 plan.md + exit_plan_mode proposed card (with path/stamp fixes)
- [ ] #5412 `/compact` + auto_compact_completed
- [ ] #5405 zero-token + window resolution polish
- [ ] Re-probe #5403 set_model effort mid-thread vs CLI restart

### Process / templates

- [x] Document learnings (this file)
- [ ] Rewrite open PR bodies to What/Why/UI/Checklist
- [ ] Align issues #5417–#5421 with feature form structure
- [ ] Shrink upstream tips before re-requesting review
- [ ] Close or supercede XXL tips if Ahmed lands the overlapping lake
