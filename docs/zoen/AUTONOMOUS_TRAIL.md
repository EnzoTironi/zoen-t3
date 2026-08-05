# Autonomous Grok parity trail (poteto-mode)

## Exit predicate (checkable)

1. L1: all ACP `sessionUpdate` kinds parsed; unit tests green; Cursor adapter still green.
2. L2: usage events, reasoning stream, plan exit RPC, effort config apply, models/commands from live initialize meta.
3. Residual from GPT HOLD closed or explicitly waived by GPT.
4. GPT owner-proxy emits **`APPROVE COMPLETE PARITY`**.

Current GPT state: **`APPROVE COMPLETE PARITY`** (macOS product gate).  
Native support matrix: **`docs/zoen/GROK_NATIVE_SUPPORT.md`**.

## Human

GPT-5.6 in T3 Code browser (owner proxy). Physical human out of loop for decisions.
Builder-ethos: no mocks-as-product, no stubs, no half-done lakes. “If not perfect, not done.”
**Platform:** macOS only (user sovereignty).

## Eureka (deliberate departure)

**Live Grok 0.2.x does not implement `session/set_config_option` for effort.**
Effort is process-scoped via CLI `--reasoning-effort`. T3 restarts the ACP process on
effort change and **resumes the same session** (`session/load`).

## Lakes (builder-ethos) — all boiled on macOS

| Lake                                            | Status      | Evidence                                                                 |
| ----------------------------------------------- | ----------- | ------------------------------------------------------------------------ |
| Live probe models/efforts/commands/context      | **boiled**  | GrokAcpCliProbe live 0.2.118                                             |
| Session stream usage/thought/commands + catalog | **boiled**  | Adapter + driver PubSub                                                  |
| Plan exit                                       | **boiled**  | Unit + live `_x.ai/exit_plan_mode`                                       |
| Effort process restart + resume                 | **boiled**  | Unit + live meta + browser UI                                            |
| Sticky effort reaches sendTurn                  | **boiled**  | `457e748f7` + process argv proof                                         |
| Auth process-observed                           | **boiled**  | email/tier; unauth on failure                                            |
| set_model in-session policy                     | **boiled**  | no-op + prompt continuity live; `requiresNewThreadForModelChange: false` |
| session_info title → UI                         | **boiled**  | `thread.metadata.updated` mapping + mock test                            |
| Mid-turn effort reject                          | **boiled**  | Adapter validation; reactor surfaces activity failure                    |
| GPT APPROVE COMPLETE PARITY                     | **APPROVE** | GPT-5.6                                                                  |

## Named oceans (explicit, non-blocking)

1. Multi-model switch cannot be exercised on current wire (single `grok-4.5`); same `session/set_model` path when more models appear.
2. ACP session modes not advertised (`modes: null`) → `showInteractionModeToggle: false` correct.
3. Linux not a product gate for this fork (macOS only).

## Commits (high water)

| SHA       | What                                          |
| --------- | --------------------------------------------- |
| 40ee652db | process-scoped effort restart + catalog       |
| 9e34287df | live exit_plan_mode                           |
| 457e748f7 | sticky effort → sendTurn                      |
| (next)    | set_model policy flip + session title publish |
