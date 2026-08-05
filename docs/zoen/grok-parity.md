# Grok Build parity (T3 / zoen-t3)

Status: **`APPROVE COMPLETE PARITY`** (GPT owner-proxy; macOS product gate).  
Transport decision: **ACP only** (`grok agent stdio`). Not headless, not Rust embed.

### GPT hold conditions (must resolve before APPROVE)

1. **Per-event semantics + acceptance tests** for every standard ACP `sessionUpdate` (not only “emit a tag”): ordering, dedupe, authority, persistence, UI consumer for `user_message_chunk`, `session_info_update`, `usage_update`, `config_option_update`.
2. **Split Phase A**: generic ACP parser correctness mergeable **without** Grok auth/BigInt/skills-reload/settle so Cursor is not blocked by Grok bugs.
3. **Prompt-settlement correlation**: prove promptId shared between ACP prompt result and `_x.ai/session/prompt_complete`; define mismatch/absent-id behavior; exactly-once.
4. **Auth source of truth**: process-observed transitions, not “token file exists”; browser flow, concurrent windows, restart, rejected token.
5. **Usage semantics** before meter: delta vs snapshot, prompt vs session, subagents, no silent estimate of context limits.
6. **Transactional config** for effort/modes: request id, optimistic vs confirmed, reject, unsolicited server change, reconnect.
7. **Bounded unknown-event telemetry**: redaction, size, retention, production defaults.
8. **Gates**: real-wire fixtures, version skew, **macOS + Linux**, Cursor regression.

Sources: T3 `apps/server/src/provider/**` (Grok/Cursor/Claude/Codex), `packages/effect-acp`, [xai-org/grok-build](https://github.com/xai-org/grok-build) user guides (agent / headless / subagents), open T3 issues/PRs.

---

## 1. What “full parity” means (testable)

Three different claims get mixed. We **do not** claim parity with the full Grok TUI product.

| Layer                               | Definition                                                                                                                                                                                                | In scope?                                         |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| **L1 — ACP faithful client**        | Every **standard ACP** session/update and control method Grok actually emits over stdio is parsed, never silently lost, and mapped into T3 runtime events or an explicit “unsupported” path with logging. | **Required**                                      |
| **L2 — T3 first-class provider UX** | Same _composer / thread / approval_ product quality users get from the best T3 providers on each surface (see §2 reference map).                                                                          | **Required**                                      |
| **L3 — Grok Build product clone**   | Every TUI pane, persona editor, plugin marketplace UI, workflows overlay, etc.                                                                                                                            | **Out of scope** (delegated to Grok CLI / config) |

**Complete for zoen-t3** means **L1 + L2**. L3 features that only exist as in-process tools stay inside Grok; T3 must not break them and should surface them when ACP exposes them (e.g. subagent tool envelopes).

### Classification legend

| Class                      | Meaning                                                                        |
| -------------------------- | ------------------------------------------------------------------------------ |
| **Required**               | Ship before calling Grok “first class” / remove Early Access                   |
| **Conditionally required** | Required if Grok advertises the capability on the wire for this binary version |
| **Delegated**              | Grok owns it; T3 only must not corrupt the session                             |
| **Impossible over ACP**    | No wire path; not a T3 defect                                                  |

---

## 2. Reference provider per surface (not “copy Codex”)

GPT challenged Codex as default baseline. Correct rule: **reference the provider whose transport and product semantics match**.

| Surface                                 | Reference                                                                     | Why                                                                                                   |
| --------------------------------------- | ----------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| ACP parse + config options + modes      | **Cursor**                                                                    | Same `AcpSessionRuntime` / `session/set_config_option` / thought_level mapping in `CursorProvider.ts` |
| Skills / slash picker population        | **Codex** product shape + **Cursor/Grok ACP** discovery                       | Codex fills `skills` from live list; Grok should fill from `available_commands_update` / session meta |
| Reasoning effort UI                     | **Cursor** (ACP config) first; **Codex** labels if model list exposes efforts | Cursor already maps select config → `optionDescriptors`                                               |
| Context / usage meter                   | **Codex** (`thread.token-usage` + window)                                     | Product UX users compare against; wire for Grok is ACP `usage_update` + `_meta`                       |
| Plan panel                              | shared plan events                                                            | Already partial via `plan` update                                                                     |
| Plan **approve/exit**                   | **Grok-specific x.ai**                                                        | Not Claude/Codex; reverse request `_x.ai/exit_plan_mode` (see issue #4514 / closed PR #4233)          |
| Approvals / ask-user                    | existing ACP + **XAiAskUserQuestion**                                         | Already in `XAiAcpExtension.ts`                                                                       |
| Subagent nested threads / observability | **Orchestration model** (#538 / #5219) + Claude attribution patterns          | Not “copy Claude SDK”; map **if** Grok emits child session / tool lineage on ACP                      |
| Auth probe / multi-account polish       | **Codex** (rich labels) only as UX, not protocol                              | Grok auth is OAuth/API key via ACP methods                                                            |

**Do not** use Claude Agent SDK shapes as the Grok transport template.

---

## 3. Capability matrix

### 3.1 Control plane (composer / provider snapshot)

| Capability                        | Grok CLI / ACP                                     | T3 today                                                 | Class                  | Target                                        |
| --------------------------------- | -------------------------------------------------- | -------------------------------------------------------- | ---------------------- | --------------------------------------------- |
| Model list                        | session models / ACP model state                   | Partial discovery; often fallback `grok-build`           | Required               | Live list on probe + session                  |
| Model capabilities (options)      | per-model `_meta.reasoningEfforts`, config options | **`EMPTY_CAPABILITIES` always**                          | Required               | Advertise only what wire sends                |
| Reasoning effort control          | advertised efforts + set path                      | Missing (PRs #5403, #5160)                               | Conditionally required | Cursor-style config or model meta             |
| Context window size               | model meta / usage                                 | Missing (PR #5405)                                       | Conditionally required | Meter + max tokens                            |
| Token / context meter during turn | `usage_update`, `_meta.totalTokens`                | **Dropped in parser**                                    | Required               | `thread.token-usage.updated`                  |
| Interaction / permission modes    | ACP modes + yolo/auto meta                         | `showInteractionModeToggle: false`                       | Conditionally required | Only if `current_mode` / modes advertised     |
| Model switch in session           | `session/set_model` (T3 already calls)             | Works; **`requiresNewThreadForModelChange: true`** still | Conditionally required | Flip flag only with evidence no context reset |
| Slash commands                    | `available_commands_update`                        | Empty snapshot (#4109)                                   | Required               | Fill `ServerProvider.slashCommands`           |
| Skills                            | same channel / skill names                         | Empty (#4109); PR #5131                                  | Required               | Fill `ServerProvider.skills` if distinct      |
| Provider auth state               | OAuth / API key                                    | Flaky login loop (#4983)                                 | Required               | Explicit state machine                        |
| Version / update advisory         | —                                                  | Manual only                                              | Delegated              | Optional later                                |

### 3.2 Session stream (transcript truth)

| `sessionUpdate` (ACP schema)     | Parsed in `AcpRuntimeModel`? | GrokAdapter maps?  | Class                                                                                      |
| -------------------------------- | ---------------------------- | ------------------ | ------------------------------------------------------------------------------------------ |
| `agent_message_chunk`            | Yes                          | Yes (ContentDelta) | Required done                                                                              |
| `tool_call` / `tool_call_update` | Yes                          | Yes                | Required done                                                                              |
| `plan`                           | Yes                          | Yes (PlanUpdated)  | Required partial (no exit)                                                                 |
| `current_mode_update`            | Yes                          | mode id only       | Conditionally required                                                                     |
| `agent_thought_chunk`            | **No (default drop)**        | No                 | Required for truthful transcript _or_ explicit “reasoning hidden” if we choose not to show |
| `available_commands_update`      | **No**                       | No                 | Required (catalog)                                                                         |
| `usage_update`                   | **No**                       | No                 | Required (meter)                                                                           |
| `config_option_update`           | **No**                       | No                 | Required (control plane, not “P3 cosmetics”)                                               |
| `session_info_update`            | **No**                       | No                 | Conditionally required                                                                     |
| `user_message_chunk`             | **No**                       | No                 | Policy TBD (echo vs ignore)                                                                |

Code: `parseSessionUpdateEvent` switch in `apps/server/src/provider/acp/AcpRuntimeModel.ts` ends in `default: break`.

### 3.3 Approvals and plan lifecycle

| Capability                      | T3 today            | Class             | Notes                                                  |
| ------------------------------- | ------------------- | ----------------- | ------------------------------------------------------ |
| Tool permission requests        | ACP permission path | Required done     |                                                        |
| `x.ai/ask_user_question`        | Handled             | Required done     |                                                        |
| `_x.ai/session/prompt_complete` | Settlement helper   | Required (harden) | Must settle exactly once                               |
| Plan render                     | Partial             | Required done-ish |                                                        |
| **Plan exit approve/reject**    | **Missing** (#4514) | **Required**      | Can **deadlock** session if Grok waits for reverse RPC |
| Plan ≠ blanket tool yolo        | —                   | Required          | Approve plan must not mean allow-all tools             |

### 3.4 Subagents / multi-agent

| Capability                                          | Grok Build                        | T3 Grok                            | Class                                                                |
| --------------------------------------------------- | --------------------------------- | ---------------------------------- | -------------------------------------------------------------------- |
| `spawn_subagent` inside Grok                        | Yes (docs)                        | Runs as tools inside child process | Delegated execution                                                  |
| Nested threads / Agents panel                       | TUI has tasks pane                | No Grok-specific mapping           | Conditionally required if wire shows child ids / parent_tool linkage |
| Worktree isolation                                  | Grok tool + `x.ai/git/worktree/*` | Not mapped                         | Delegated unless T3 needs apply UX                                   |
| Personas / agent types                              | Grok config                       | Delegated                          |                                                                      |
| Background child still running after parent settles | Grok                              | Same generic gap as #5043/#4962    | Orchestration (#5219), not Grok-only                                 |

### 3.5 x.ai extension surface (docs vs T3)

Grok docs list many `x.ai/*` methods. **T3 only implements a thin set today** (`XAiAcpExtension.ts`: prompt_complete, ask_user_question).

| Policy           | Rule                                                                                       |
| ---------------- | ------------------------------------------------------------------------------------------ |
| Integrate        | Only after **stdio wire capture** or schema in open source shows the method on agent stdio |
| Do not integrate | Internal TUI-only or headless-only surfaces                                                |
| Unknown methods  | Log + preserve raw (no silent forever drop without telemetry)                              |

---

## 4. Layer ownership (before more code)

| Layer                 | Owns                                                                                          | Must not own             |
| --------------------- | --------------------------------------------------------------------------------------------- | ------------------------ |
| `packages/effect-acp` | Wire codec, request ids (incl. large ints), JSON-RPC                                          | Product UX               |
| `AcpRuntimeModel`     | **Normalize all known ACP update kinds** into tagged events; unknown → `UnknownSessionUpdate` | Provider-specific labels |
| `AcpSessionRuntime`   | Process lifecycle, session methods                                                            | Composer                 |
| `XAiAcpExtension`     | xAI reverse notifications / requests only                                                     | Generic tool_call        |
| `GrokAdapter`         | Map tagged events → `ProviderRuntimeEvent`                                                    | Re-parse raw JSON        |
| `GrokProvider`        | Snapshot: models, capabilities, skills, slash, auth, presentation flags                       | Stream deltas            |
| Orchestration / UI    | Nested threads, meters, plan approval chrome                                                  | ACP method names         |

**Parse hole is a generic ACP correctness defect**, not Grok-only. Fix with tests that Cursor still behaves (golden fixtures per provider).

---

## 5. Reliability items (split; do not one-ball “P0”)

| Issue                   | Symptom                                  | Likely owner                                  | Notes                              |
| ----------------------- | ---------------------------------------- | --------------------------------------------- | ---------------------------------- |
| #4109 BigInt RequestId  | Crash on skills-reload                   | effect-acp / JSON id type                     | Preserve as string; no Number()    |
| #3666 Linux ACP timeout | Probe fails on unsolicited skills-reload | T3 handler + Grok emit order                  | Not fixed by longer timeout alone  |
| #4983 login loop        | Browser opens repeatedly                 | T3 auth orchestration                         | Need state machine + idempotency   |
| Prompt hang / settle    | Working forever                          | XAi prompt_complete + ACP prompt RPC mismatch | Already partial; race cases remain |
| #4514 plan stuck        | No exit UI                               | T3 missing reverse method                     | Product deadlock, not polish       |

---

## 6. Revised delivery phases (after GPT critique)

Order is **correctness → control plane → safety deadlock → transcript fidelity → multi-agent observability**.

### Phase A — ACP correctness (blocks everything)

1. Parse **all** schema `sessionUpdate` kinds in `AcpRuntimeModel` (at least emit typed tags + tests).
2. JSON-RPC **id / BigInt** safe path (#4109).
3. Unsolicited skills-reload / notify handling so probe does not wedge (#3666).
4. Unknown update policy: structured log + counter; never pure silent drop in prod without metrics.
5. Prompt settlement invariant: exactly-once complete despite early/late/missing `prompt_complete`.

### Phase B — Control plane parity (Cursor-shaped)

1. Map session/model **config options** and model meta → `ModelCapabilities` (kill empty defaults when live data exists).
2. Reasoning effort round-trip (discover → select → set → confirm → persist).
3. `usage_update` → context meter.
4. `available_commands_update` → slash + skills snapshots; define refresh invalidation.
5. Modes: wire `current_mode_update` to T3 only if semantics match; **do not** rename Grok plan mode as “interaction mode” without proof.
6. Revisit `requiresNewThreadForModelChange` with measured set_model behavior.

### Phase C — Plan exit (safety)

1. Handle `_x.ai/exit_plan_mode` (or current method name from wire).
2. UI approve / reject / cancel; state machine for stale session, reconnect, double-submit.
3. Security: plan approval ≠ tool yolo.

### Phase D — Transcript fidelity

1. `agent_thought_chunk` → reasoning UI **after** sample payloads (may be noise; may need collapsible).
2. `user_message_chunk` policy (usually ignore echo).
3. `config_option_update` as control-plane push (belongs with B if easy).

### Phase E — Subagent observability

1. Capture real stdio traces of `spawn_subagent` / child activity.
2. If lineage exists: map into orchestration nested threads / #5219.
3. If not: document as **Delegated**; only show tool_call titled as subagent.

### Phase F — Optional x.ai/\*

Worktree apply, session fork, etc. only with product need + wire proof.

---

## 7. Upstream leverage (do not reimplement blindly)

| Work                    | Repo            | Use                 |
| ----------------------- | --------------- | ------------------- |
| #5403 / #5160           | T3 PRs          | Reasoning effort    |
| #5405                   | T3 PR           | Context meter       |
| #5131                   | T3 PR           | Skills/slash        |
| #4233                   | closed unmerged | Plan exit body      |
| #5219 / #4664           | T3 PRs          | Generic subagent UI |
| #4109 #3666 #4514 #4983 | issues          | Reliability         |

Cherry-pick candidates into **zoen-t3 `zoen/main`** after review; upstream merge is optional.

---

## 8. Explicit non-goals

- Headless `grok -p` as primary thread transport
- Embedding `xai-grok-*` crates
- Pixel parity with Grok TUI tasks pane
- Full `x.ai/fs|git|search` reimplementation when tools already work inside the agent
- “Infer” capabilities when the binary does not advertise them

---

## 9. GPT owner-proxy questions (round 1)

ChatGPT was instructed: questions only, no code execution. Generation truncated mid-answer; **~40 questions captured**. Themes:

1. Define parity (L1/L2/L3) — answered §1
2. Codex vs Cursor baseline — answered §2
3. ACP vs x.ai compensation boundary — §1 + §3.5
4. Parse hole as generic defect — §4 + Phase A
5. Why usage/commands not P0 — revised into Phase A/B
6. Layer ownership — §4
7. Unknown event policy — Phase A.4
8. Wire proof for x.ai/\* — §3.5
9. Split P0 root causes — §5
10. Prompt-complete exactly-once — Phase A.5
11. Timeouts vs deadlocks — §5  
    12–13. Auth state machine + login loop — §5 / Phase A  
    14–18. Capabilities / effort round-trip / model switch — Phase B
12. Interaction mode ≠ plan mode — Phase B.5  
    20–22. Skills/slash cache + BigInt — Phase A/B  
    23–26. Plan exit state machine + security — Phase C  
    27–29. Thought stream privacy — Phase D  
    30+. Subagents, worktrees, PR cherry-picks, acceptance tests — Phase E/F

**Next agent step:** answer residual GPT questions with file-level evidence in the same ChatGPT thread, then request `APPROVE PARITY PLAN` / `HOLD` / `REJECT`.

---

## 10. Acceptance tests (minimum for “parity complete”)

1. Probe Grok on Linux+macOS: status ready, models non-empty, no hang.
2. Skills present under `~/.grok/skills` appear in `$` / `/` pickers; skills-reload does not crash.
3. Composer shows effort when model advertises it; changing effort changes next turn (assert wire).
4. Context meter moves during a long turn.
5. Plan mode: enter plan → approve → continue; reject path works.
6. Stop mid-turn settles; no zombie Working.
7. Login: single browser flow; no loop.
8. Cursor ACP regression suite still green after parser changes.
9. Optional: subagent spawn shows child progress if Phase E lands.

---

## 11. Key code pointers

| Area                  | Path                                                                                          |
| --------------------- | --------------------------------------------------------------------------------------------- |
| Spawn                 | `apps/server/src/provider/acp/GrokAcpSupport.ts` (`agent stdio`)                              |
| Parse hole            | `apps/server/src/provider/acp/AcpRuntimeModel.ts` `parseSessionUpdateEvent`                   |
| Adapter               | `apps/server/src/provider/Layers/GrokAdapter.ts`                                              |
| Snapshot / EMPTY caps | `apps/server/src/provider/Layers/GrokProvider.ts`                                             |
| xAI ext               | `apps/server/src/provider/acp/XAiAcpExtension.ts`                                             |
| Cursor reference      | `apps/server/src/provider/Layers/CursorProvider.ts`                                           |
| ACP schema updates    | `packages/effect-acp/src/_generated/schema.gen.ts` (`agent_thought_chunk`, `usage_update`, …) |

---

_Document owner: zoen-t3. Update after GPT APPROVE/HOLD and after each phase lands._
