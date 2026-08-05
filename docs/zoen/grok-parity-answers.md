# Answers to GPT parity questions (57)

Context: GPT owner-proxy deep review of Grok Build parity for zoen-t3 / T3 Code.  
Evidence base: T3 tree (`AcpRuntimeModel`, `Grok*`, `Cursor*`, `Codex*`, `XAiAcpExtension`, `effect-acp` schema), [xai-org/grok-build](https://github.com/xai-org/grok-build) docs, open issues #4109 #3666 #4514 #4983.

Notation: **R** = Required for L1+L2 parity · **C** = Conditionally required if wire advertises · **D** = Delegated to Grok · **X** = Impossible / out of scope over ACP.

---

## Q1 — Exact testable definition of “full Grok Build parity”

Three claims mixed. We pick:

| Layer | Definition | Scope |
|-------|------------|-------|
| **L1 ACP faithful client** | Every standard ACP `sessionUpdate` kind in `effect-acp` schema is either mapped to a typed event + consumer, or handled as `Unknown` with bounded telemetry. No silent `default: break`. | **R** |
| **L2 T3 first-class UX** | Composer/thread/approval quality matching the *correct reference provider per surface* (§Q2), when Grok exposes the capability. | **R** |
| **L3 Grok TUI product clone** | Personas UI, plugin marketplace chrome, workflows overlay pixel parity. | **X / D** |

**Complete for zoen-t3 = L1 + L2.** Not L3.

### User-visible capability classification

| Capability | Class | Notes |
|------------|-------|-------|
| Chat stream (assistant text) | R | Already mapped |
| Tool calls + updates | R | Already mapped |
| Tool permission approvals | R | ACP permission path |
| Ask-user (x.ai) | R | `XAiAcpExtension` |
| Turn settle / stop | R | prompt + `prompt_complete` |
| Auth ready / login once | R | state machine |
| Model list | R | live ACP model state |
| Model options (effort etc.) | C | only if advertised |
| Context meter (used/size) | C | `usage_update` |
| Provider-reported cost | C | `usage_update.cost` if present; never invent |
| Slash commands picker | R | `available_commands_update` |
| Skills picker | R | if distinct from commands; else same feed |
| Plan board | R | `plan` update |
| Plan exit approve/reject | R | x.ai reverse; deadlock risk |
| Reasoning / thought UI | C | parse always; display after sample policy |
| Interaction/permission modes | C | only if modes wire matches T3 toggle |
| In-session model switch | C | `session/set_model` exists; flag today forces new thread |
| Subagent nested addressable threads | C | only if child session identity on wire |
| Subagent activity visibility | C | same |
| Worktree isolation UX | D | Grok tools + isolation param |
| Personas / agent types config | D | `~/.grok` / files |
| MCP server management UI | D | Grok owns; tools may appear as tool_call |
| Plugins marketplace UI | D | |
| Workflows TUI overlay | D | |
| Headless CI scripting | X | not T3 product path |
| Embed Rust crates | X | |

---

## Q2 — Why Codex P1 vs Cursor ACP?

**Codex is wrong as default control-plane baseline.** Revised:

| Surface | Reference | Why not transport debt |
|---------|-----------|------------------------|
| Parse/config/modes/effort discovery | **Cursor** | Same `AcpSessionRuntime`; `CursorProvider` already maps `thought_level` / config options → `optionDescriptors` |
| Usage meter product shape | **Codex** `thread.token-usage` | UI already knows this shape; wire source for Grok is ACP `usage_update` |
| Skills/slash list shape | **Codex fields** + **ACP discovery** | `ServerProvider.skills` / `slashCommands` |
| Plan panel | shared plan events | |
| Plan exit | **Grok x.ai only** | not Claude/Codex |
| Subagent UI | **#5219 generic** if lineage exists | not Claude SDK copy |
| Auth labels polish | Codex-like UX optional | not protocol |

Copying Codex app-server paths for Grok would invent a second transport.

---

## Q3 — ACP faithful vs x.ai compensation?

**Primary: consume all standard ACP semantics.**  
**Secondary: x.ai only for Grok-specific reverse RPC** already required (`prompt_complete`, `ask_user_question`, `exit_plan_mode`).

Boundary:

| Situation | Classification |
|-----------|----------------|
| Schema has `usage_update`, T3 drops it | **T3 defect** |
| Grok never emits thought chunks on stdio | **Upstream / C not required** after wire proof |
| Feature only in TUI / headless, not agent stdio | **X / D**, not T3 parity defect |
| x.ai method not on stdio | do not implement |

---

## Q4 — Parse hole as generic AcpRuntimeModel defect?

**Yes.** Fix before Grok-only features.

| `sessionUpdate` | Today | Policy |
|-----------------|-------|--------|
| `agent_message_chunk` | ContentDelta | keep |
| `tool_call` / `tool_call_update` | ToolCallUpdated | keep |
| `plan` | PlanUpdated | keep |
| `current_mode_update` | ModeChanged | keep |
| `agent_thought_chunk` | **drop** | global preserve → ThoughtDelta (or tagged) |
| `available_commands_update` | **drop** | CommandsUpdated |
| `usage_update` | **drop** | UsageUpdated |
| `config_option_update` | **drop** | ConfigOptionUpdated |
| `session_info_update` | **drop** | SessionInfoUpdated |
| `user_message_chunk` | **drop** | UserMessageChunk (policy: usually no UI echo) |
| unknown future | **drop silent** | UnknownSessionUpdate + metrics |

**Cursor regression:** golden fixtures for Cursor mock agent must stay green; no change to Cursor mapping without explicit tests.

---

## Q5 — Why were usage/commands not P0?

They **should be** in Phase A (parse) + Phase B (consume). Dropping them **does** cause:

- empty skills/slash (stale/empty catalog)  
- missing meter (misleading “no usage”)  
- ignored config_option (wrong model options)  
- missed session title/meta  

Cannot prove “safe to drop.” Revised plan puts parser completeness first.

---

## Q6 — Canonical ownership of ACP events

| Layer | Owns | Must not |
|-------|------|----------|
| `packages/effect-acp` | JSON-RPC codec, request id types | product |
| `AcpRuntimeModel` | normalize **all** known updates to tags | Grok labels |
| `AcpSessionRuntime` | process, session methods | UI |
| `XAiAcpExtension` | x.ai reverse notify/request only | generic tool_call |
| `GrokAdapter` | tag → `ProviderRuntimeEvent` | re-parse raw |
| `GrokProvider` | snapshot models/caps/skills/auth | stream |
| Orchestration / web | meters, plan chrome, nested activity | ACP method strings |

---

## Q7 — Unknown ACP / x.ai events?

**Silent drop is not acceptable without counters.**

Policy:

1. Known schema kinds → typed events.  
2. Unknown `sessionUpdate` string → `UnknownSessionUpdate { kind, size }` + structured log.  
3. Unknown x.ai method → log method name; respond error if request; ignore notify after log.  
4. Raw preserve: **dev/debug only**, max N bytes/event, redact secrets, off in production default.  
5. Metric: `acp.unknown_session_update{kind}`.

---

## Q8 — Evidence x.ai surface is on stdio?

**Today proven in T3 codepaths:**

- `_x.ai/session/prompt_complete` — `XAiAcpExtension.ts`  
- `x.ai/ask_user_question` / `_x.ai/ask_user_question` — same  

**Documented in Grok agent-mode guide** (not yet all wired in T3): `x.ai/fs/*`, `git/*`, `worktree/*`, `search/*`, `terminal/*`, `session/*`, `auth/*`, etc.

**Gate:** no new x.ai integration without (a) open-source handler path in grok-build **or** (b) captured stdio transcript from `grok agent stdio`. Docs alone ≠ wire proof.

---

## Q9 — Split “P0” root causes

| Issue | Symptom | Owner | Layer |
|-------|---------|-------|-------|
| #4109 BigInt | `Cannot convert skills-reload to a BigInt` in RpcMessage RequestId | **T3 / effect-acp / Effect RPC** | codec |
| #4109 empty skills | snapshot skills/slash empty | **T3 GrokProvider** never fills from updates | adapter snapshot |
| #3666 Linux timeout | probe hangs on unsolicited skills-reload | **T3** missing notify handling + possible Grok emit order | session probe |
| #4983 login loop | browser opens repeatedly | **T3** auth orchestration | provider auth |
| Prompt hang | Working forever | **T3** settle race (partial XAi helper) | turn lifecycle |
| #4514 plan stuck | no exit UI | **T3** missing reverse method | plan exit |
| Grok CLI bugs | wrong wire | **upstream Grok** | external |

Not one P0 ball.

---

## Q10 — Prompt completion invariant

**Settle exactly once** when first of:

1. ACP `session/prompt` RPC result returns, or  
2. `_x.ai/session/prompt_complete` resolves pending prompt, or  
3. cancel / interrupt, or  
4. child process death / transport error.

Rules:

- Track `promptId` (from response `_meta.promptId|requestId`, or T3-allocated fallback used in outgoing prompt meta — see `XAiAcpExtension` fallback registration).  
- After settle, ignore late updates for that promptId (already partially: `completedPromptIdsRef`).  
- If complete arrives **before** final chunks: still accept chunks only until settle decision is “prompt RPC still open”; after settle, drop late deltas (test both orders).  
- Never start next user turn’s prompt until previous settled.  
- If `prompt_complete` missing forever: settle on RPC result or timeout **after** cancel path is exhausted — timeout is last resort, not first.

**Gap today:** correlation when Grok omits promptId on one side is incomplete (GPT HOLD #3). Must define: if no id, settle on session-scoped single in-flight prompt only (at most one open prompt per session).

---

## Q11 — Timeout policy

| Path | Policy |
|------|--------|
| Model discovery probe | Keep bounded (~15s); **fix notify handling** so skills-reload does not block; do not “fix” #3666 by only raising timeout |
| Interactive turn | No short global kill; user Stop; provider cancel |
| Approval wait | Unlimited until user or disconnect |
| Plan exit wait | Unlimited until user or disconnect; surface waiting UI |
| Skills reload | Handle async; never block initialize |
| Subagents | Parent settle ≠ children done (orchestration); child timeouts owned by Grok |

---

## Q12 — Auth state machine

States: `unknown` → `unauthenticated` | `login_pending` | `authenticated` | `expired` | `error`.

Transitions (process-observed, not “file exists”):

| From | Event | To |
|------|-------|-----|
| * | spawn + `authenticate` success | authenticated |
| * | authenticate fail / unauthorized | unauthenticated |
| unauthenticated | user starts login (browser/device) | login_pending |
| login_pending | auth success notify / re-probe ok | authenticated |
| login_pending | cancel / timeout | unauthenticated |
| authenticated | later request unauthorized | expired → reauth |
| any | process crash | unknown (re-probe on next use) |
| login_pending | second login request | **ignore / join** same pending (idempotent) |

Methods today: `xai.api_key` if `XAI_API_KEY`, else `cached_token` (`GrokAcpSupport.ts`).

---

## Q13 — Login-loop prevention

- **SoT:** last successful `authenticate` / session start for this process instance + probe result, not mere `auth.json` presence.  
- **Idempotency:** one `login_pending` per instanceId; UI “Log in” disabled while pending.  
- **Do not** spawn browser on every status poll.  
- Concurrent windows: serialize login on provider instance lock.  
- After success: probe once; cache authenticated until failure.

---

## Q14 — Authoritative capabilities source

| Fact | Source of truth |
|------|-----------------|
| Model id list | Live session model state / probe ACP (`buildGrokDiscoveredModelsFromSessionModelState`) |
| Context size | `usage_update.size` or model meta if present |
| Reasoning levels | Session config options (Cursor pattern) and/or model `_meta.reasoningEfforts` if Grok sends |
| Modes | ACP session modes + `current_mode_update` |
| Model switch | `session/set_model` result |

**Conflict rule:** live session config **wins** over static `GrokProvider` catalog. Static catalog is fallback when probe fails only. Never invent options.

---

## Q15 — Infer vs advertise only?

**Only advertise what the running binary declares.**  
`EMPTY_CAPABILITIES` today is wrong when live data exists; replacing with **inferences** (guessing efforts) is also wrong.

Degradation:

- Old binary, no options → empty descriptors, UI hides controls.  
- Partial schema → skip unknown fields.  
- Unknown enum value → show raw id or hide, never map to wrong tier.  
- Version skew → probe each session; no global “Grok always has High”.

---

## Q16 — Reasoning effort: labels or protocol ids?

**Protocol-stable option values** (Cursor: config option select values via `session/set_config_option`). UI labels are derived.

Round-trip:

1. **Discovery:** config options / model meta at session start + updates.  
2. **Current:** `currentValue` on option.  
3. **Mutation:** `session/set_config_option` (or documented Grok path).  
4. **Ack:** RPC success; optional `config_option_update`.  
5. **Persist:** T3 `modelSelection.options` only after ack.  
6. **Restore:** re-apply on session resume if Grok does not restore.  
7. **Rollback:** on RPC error, UI reverts to last acked.

---

## Q17 — Effort applies when? Optimistic UI?

Typically **next prompt / rest of session** (session config), not mid-token rewrite.  
UI: show “pending” until ack; never green check before success.

---

## Q18 — `requiresNewThreadForModelChange: true`

Today forced in `GrokProvider` presentation.  
`GrokAcpSupport.applyGrokAcpModelSelection` already calls `setSessionModel` when model differs.

**Evidence needed before flipping false:** wire test that after `session/set_model`, prior transcript context and tools remain (or Grok documents reset). If reset: keep true **or** allow switch but show “new context” banner when session id / meta indicates discontinuity.

Detect discontinuity: new session id, explicit agent notification, or empty history after switch.

---

## Q19 — `showInteractionModeToggle` vs plan mode

**Not the same.**  
T3 interaction mode = permission/automation posture (supervised / auto / …).  
Grok plan mode = enter/exit plan workflow + plan entries + exit approval.

Do not wire plan mode into the interaction toggle without ACP mode ids proving equivalence.

Grok modes (product docs): ask / auto / always-approve (yolo) via flags and `_meta.yoloMode` / `autoMode` on `session/new`. Wire mode ids must be captured from `initialize` / modes list before UI.

---

## Q20 — Slash/skills “just snapshot fill”?

**No.** Lifecycle:

- **Scope:** session (+ workspace cwd at session create); may refresh when plugins/skills change.  
- **Feed:** `available_commands_update` (and any skill-specific meta).  
- **Invalidate on:** that update, new session, cwd change, reconnect.  
- Probe-time snapshot alone is insufficient if Grok only emits after session start.

---

## Q21 — BigInt crash fix

**Offending path (issue #4109):** Grok emits JSON-RPC related to `skills-reload` with a request id that Effect `RequestId` / RpcMessage tries to coerce via `BigInt(...)`, failing with `Cannot convert skills-reload to a BigInt` (id may be a **string method name** or non-numeric id).

**Fix requirements:**

- Accept string **or** numeric request ids end-to-end (preserve as string key).  
- Never `Number(id)` for ids.  
- Never assume all ids are bigint-encodable.  
- No global `JSON.parse` monkey-patch.  
- Unsolicited responses/notifies with odd ids must not crash the connection.

Owner: `effect-acp` / Effect RPC integration used by ACP client.

---

## Q22 — Skills vs slash commands

**Different product concepts in Grok** (skills under `~/.grok/skills`, slash commands include skills + builtins).  

T3 model already has **two arrays**: `ServerProvider.slashCommands` and `ServerProvider.skills`.

| | Slash | Skills |
|---|-------|--------|
| Discover | commands update | skills subset or dedicated |
| Invoke | `/name` in prompt | `$name` or skill runner |
| Args | optional input hint | often free text |
| Refresh | commands update | same or skills-reload notify |
| Permissions | as tool/command | as tool |

**UI:** may share a combined palette with sections; **data model stays separate.** Do not force one abstraction if wire distinguishes.

---

## Q23 — Plan approval phase?

**Safety, not polish.** Incomplete UI **can deadlock** if Grok waits on `_x.ai/exit_plan_mode` (PR #4233 description).  
Phase order: after parser reliability, **before** thought cosmetics. Treat as **R**.

---

## Q24 — `exit_plan_mode` state machine

| State | Events |
|-------|--------|
| idle | — |
| plan_visible | `plan` updates while in plan mode |
| exit_requested | reverse RPC arrive: `{sessionId, toolCallId, planContent}` |
| rendering_approval | UI shows plan + Approve / Request changes / Cancel |
| approving | send allow response |
| rejecting | send reject + optional feedback |
| cancelled | user cancel or Stop |
| acked | agent continues |
| stale | session switch / process death → drop UI, fail RPC if still open |
| reconnect | if request not acked, re-show or mark failed |

Duplicate approve: idempotent on toolCallId.  
After process death: no silent success.

---

## Q25 — Generic ACP or x.ai?

**x.ai-specific reverse request** (not generic ACP plan entry).  
UI: reuse **approval request framework** with kind `plan_exit` (or similar), not a second parallel modal system.  
Plan **rendering** stays on generic `plan` sessionUpdate.

---

## Q26 — Plan approve ≠ tool yolo

Approving plan:

- Acknowledges plan content / allows agent to **leave plan mode**.  
- Does **not** set session to always-approve tools.  
- Subsequent file/shell/git/MCP still use normal permission mode and tool permission prompts.

Document in UI copy: “Approve plan” ≠ “Allow all tools.”

---

## Q27 — Thought as P3 vs truthful transcript?

**Parser must not drop** (truth / latency attribution).  
**Display** can be phased after payload sampling.  
If dropped: user cannot tell “no reasoning” vs “hidden” — bad.  
Minimum: parse + store optional collapsed “Reasoning” with indicator when chunks existed.

---

## Q28 — What to show from thought chunks?

| Rule | Choice |
|------|--------|
| Default UI | Collapsed “Thinking” region, stream optional |
| Persist | Session transcript optional flag; default on for debugging parity, revisit privacy |
| Export | Include only if user exported “full trace” |
| Redaction | Strip secrets patterns if any |
| Compatibility | Older clients ignore unknown activity types |

Do not assume every thought token is user-facing prose.

---

## Q29 — Empirical thought payload?

**Required before final UI mapping.** Capture stdio samples: pure reasoning vs status vs tool narration.  
Until then: generic collapsible text, not forced into Claude “thinking” product semantics.

---

## Q30 — `config_option_update` not stream cosmetics

**Control plane.** Same phase as effort/modes. Transactional session state (§Q16). Unknown option ids: store raw, do not crash, do not invent UI.

---

## Q31 — `user_message_chunk`?

Likely **echo / agent-side user materialization** (multimodal, tool-originated user, remote).  

Policy:

- **Default:** do not render as a second user bubble if T3 already inserted the user message.  
- **Render** only if content differs (attachments, tool-synthesized user).  
- Dedupe by text hash + turn id when possible.  
- Always parse (L1).

---

## Q32 — `session_info_update`?

Schema (effect-acp): optional `title`, `updatedAt`, partial meta.  

**Role:** session title / activity timestamp for sidebar.  
**Safe to defer UI** if T3 already titles threads; **not safe to drop parse** (L1).  
Child-session identity: only if `_meta` carries it (unproven) — do not assume.

---

## Q33 — Usage parity definition

ACP `usage_update` (schema):

- `used`: tokens currently in context  
- `size`: total context window  
- `cost?`: cumulative session cost (optional, unstable)  
- `_meta?`: extension  

| Dimension | Source | Est. allowed? |
|-----------|--------|---------------|
| Context occupancy | `used` / `size` | no invent size |
| Cumulative cost | `cost` if present | no local pricing table |
| Input/output/cache split | only if `_meta` or other events | no |
| Per-turn | derive from successive updates if monotonic | careful |
| Subagent usage | only if attributed in meta | no invent |
| Budget limits | not in schema | X unless Grok adds |

Prefer **provider-reported** values only.

---

## Q34 — Spend ownership

If Grok sends `cost`, **display as reported** (currency/units per payload).  
T3 does **not** own pricing tables, subscription allowances, or cache discounts unless Grok documents formulas.  
Absence of cost ≠ $0.

---

## Q35 — Out-of-order / reset usage

Assumptions:

- Treat `(sessionId, update)` as snapshot of **current** used/size unless meta says delta.  
- Allow used to **drop** after compact (not strictly monotonic).  
- On reconnect: last update wins; no sum of history.  
- Child attribution only with explicit ids.  
- Never extrapolate missing updates.

---

## Q36 — MCP / plugins / workflows parity criterion

**Delegated operation sufficient for L2** if:

- tools appear as ACP tool_calls,  
- permissions work,  
- user can complete work.

**First-class management UI** (enable MCP servers, plugin market) = L3 / D unless product prioritizes.

Do not claim parity only because Grok can use MCP invisibly without T3 surfacing tool activity (tool_call visibility is R).

---

## Q37 — Per feature: control / observe / config / persist / recover

| Feature | Control | Observe | Config | Persist | Recover |
|---------|---------|---------|--------|---------|---------|
| Subagents | D (Grok spawns) | C if wire | D personas | C if child session | C |
| Worktrees | D | tool_call | D | D | D |
| Personas | D | D | D files | D | D |
| Plan mode | R exit | R plan | C modes | plan in transcript | reconnect stale |
| Effort | R if advertised | current value | session option | modelSelection | reapply |
| Skills/slash | invoke R | list R | D install | cache session | refresh |
| Usage | — | R meter | — | last snapshot | reconnect |
| MCP | D | tool_call R | D | D | D |
| Plugins | D | D | D | D | D |
| Workflows | D | C if events | D | D | D |

---

## Q38 — Subagent observability required or optional?

**Decision: Conditionally required for L2.**

Acceptance:

- **IF** stdio shows child session id / parent linkage / lifecycle → must show activity (generic #5219 model).  
- **ELSE** after documented capture attempts → **D** with tool_call titles only; L2 still complete without nested threads.

No “implement if possible” without the IF/ELSE gate written in tests.

---

## Q39 — Wire evidence for child session

Accept lineage only with at least one of:

- distinct child `sessionId` in updates,  
- spawn tool result with subagent id + later updates tagged,  
- explicit x.ai session notification with parent/child fields,  
- lifecycle start/complete events with stable id.

**Reject:** inferring only from tool name `spawn_subagent` string matching.

---

## Q40 — Map to nested threads?

**Only if** Grok child is a durable, user-addressable session (resume, open, message).  
If transient background work: **activity group / read-only panel**, not full T3 thread (would fake composer, pin, title, independent history).

Default bias: **activity**, not thread, until proven.

---

## Q41 — #5219 vs Grok-specific?

**Prefer #5219 / generic observability.**  
GrokAdapter only maps wire → generic child activity events.  
Avoid binding unfinished upstream abstraction: feature-detect; if #5219 not merged, implement minimal generic events in zoen-t3 contracts compatible with that direction.

---

## Q42 — Minimum safe representation if incomplete lineage

1. tool_call rows with subagent-like titles (no fake ids)  
2. optional “background work” group without click-through  
3. explicit UI: “Details unavailable from provider”  
**Never** invent child transcripts.

---

## Q43 — Child failure / cancel / usage / parent completion

- Parent turn settle ≠ all children done (same class of bug as #5043).  
- Need orchestration “waiting on children” when lineage exists.  
- Child approvals: route to UI with parent context.  
- Child usage: only if attributed; else omit.  
- Final parent message must not clear child terminal events.

Without lineage: cannot enforce; document limitation.

---

## Q44 — Why T3 own worktree x.ai/*?

**Default: do not.** Grok tools + isolation already solve isolation.  
T3 owns worktrees only if product needs **cross-provider** worktree apply UX independent of Grok — separate initiative, not Grok parity L2.

---

## Q45 — x.ai classification bar

| Kind | Examples | Bar |
|------|----------|-----|
| Presentation | show plan text | low |
| Control | exit_plan_mode response, ask_user | medium; needed for session liveness |
| Orchestration | T3 drives git worktree apply parallel to Grok | **high** — split-brain risk |

---

## Q46 — SoT for fs/git/terminal/search/worktree

**Grok agent process is SoT for agent-initiated tool effects.**  
T3 SoT for T3-initiated git/checkpoints (orchestration checkpointing).  

Prevent dual drive: T3 must not call x.ai/fs write while also expecting Grok tools for same path without locking. Prefer **observe tool_calls** over dual control.

---

## Q47 — Implement x.ai/fs|git|terminal|search?

**No**, unless a capability **cannot** appear as ACP tool_call (none proven for L2).  
Display ordinary tool_calls.

---

## Q48 — Security review before x.ai controls

- Workspace root = session cwd; path allowlist  
- No silent path escape  
- Mutating ops approval-gated (Grok mode or T3)  
- Redact tokens in logs  
- Auth methods only for auth, not general RPC  
- Trust: local stdio agent = same trust as Cursor ACP today  

---

## Q49 — Can x.ai bypass approvals?

Must be **one** of:

1. Grok gates (permission mode), or  
2. T3 gates (approval UI), or  
3. Documented always-allow (user yolo).  

Never both ambiguous nor neither for mutating ops.  
Plan exit and tool permission stay distinct (§Q26).

---

## Q50 — Extension versioning

Methods namespaced `x.ai/*` but **unversioned** in practice.  

Policy:

- Feature-detect via initialize / try-call.  
- Soft-fail unknown methods.  
- Additive `_meta` fields ignored if unknown.  
- Breaking payload: adapter version pin + probe; degrade feature off.

---

## Q51 — Prevent second 4k Claude adapter

Hard module caps:

| Module | Max responsibility |
|--------|--------------------|
| GrokAcpSupport | spawn + auth method id + model id normalize |
| XAiAcpExtension | x.ai reverse only |
| GrokAdapter | map tags → runtime events + session ops |
| GrokProvider | snapshot only |
| Shared AcpRuntimeModel | all providers |

No Grok stream parsing outside these.  
New behavior = new small module + test, not grow Claude-style monolith.

---

## Q52 — Inadequate vs false-general abstractions

**Must generalize:**

- `parseSessionUpdateEvent` completeness  
- request id typing (string|bigint-safe)  
- provider snapshot skills/commands refresh  
- optional usage events → token meter  

**False generality (Grok-only for now):**

- `exit_plan_mode`  
- `prompt_complete`  
- `ask_user_question` x.ai shapes  

Keep those in `XAiAcpExtension`, not “generic ACP plan approval” until second provider needs them.

---

## Q53 — Anti-slop `provider === "grok"`

**Allowed only in:** `Grok*.ts`, `XAi*.ts`, tests, driver registry entry.  

**Forbidden in:** web components, decider, projector (use capabilities / event kinds / driverKind only when unavoidable at registry).  

Dead branches: remove when capability flag replaces them; CI grep optional later.

---

## Q54 — Avoid surface-only parity

Every control must document:

| Field | Example effort |
|-------|----------------|
| Command | `session/set_config_option` |
| Ack | RPC ok + optional config_option_update |
| Failure UI | toast + revert |
| Persist | modelSelection after ack |
| Fallback | hide control if not advertised |

Acceptance tests must fail if control is visible but no-op.

---

## Q55 — OS / version acceptance matrix

| | macOS arm64 | Linux x64 | Windows |
|---|-------------|-----------|---------|
| Phase A probe | R | R (#3666) | best-effort |
| Skills/slash | R | R | best-effort |
| Login | R | R (#4983 class) | best-effort |
| Grok version N / N-1 | R skew | R | — |

Windows: track but not gate L2 initially if T3 desktop Windows Grok is secondary.

---

## Q56 — Process lifecycle tests

Required automated or integration cases:

startup fail, missing binary, bad version, stdout garbage, stderr flood, graceful exit, crash mid-stream, restart session, cancel, orphan kill on stop, two concurrent threads/sessions.

Many already sketched in `GrokAdapter.test.ts` with mock agent; extend mock for skills-reload + BigInt ids.

---

## Q57 — Protocol fixtures / recorded transcripts

(GPT truncated; full intent:)

**Required:**

1. Checked-in **recorded stdio transcripts** (sanitized) from real `grok agent stdio` for: happy path, skills-reload, plan exit, usage_update, thought chunks, multi-tool.  
2. Mock agent scripts reproducing those shapes (`apps/server/scripts/acp-mock-agent.ts` pattern).  
3. Unit tests parse → tags → adapter events.  
4. **No** production code that only works against guessed payloads.

Until real captures exist for a feature, that feature stays C/D, not R.

---

## Mapping to HOLD conditions

| GPT HOLD | Answered in |
|----------|-------------|
| Per-event semantics | Q4, Q27–32, Q33–35 |
| Split Phase A | Q4, Q9, Q51–52 |
| Prompt correlation | Q10 |
| Auth process-observed | Q12–13 |
| Usage semantics | Q33–35 |
| Config transactional | Q16–17, Q30 |
| Bounded unknown telemetry | Q7 |
| OS + Cursor gates | Q55–57 |

---

## Status

These answers supersede the earlier draft phases where they conflict.  
Next: paste this set into the GPT thread and request `APPROVE PARITY PLAN` or a short residual HOLD list.
