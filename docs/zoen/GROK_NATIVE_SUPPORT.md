# Grok native support in T3 Code (zoen-t3)

**Scope:** L1 ACP client + L2 T3 first-class provider UX on **macOS**.  
**Not in scope:** Cloning the full Grok Build TUI (L3).

**Status (2026-08-05):** Native Grok is first-class for all T3 product features the ACP wire exposes. Verified with unit tests, live `grok agent stdio` probes, and an isolated **test-t3-app** web pass (home: `.t3-parity-test`).

## Feature matrix (T3 product × Grok)

| Feature                            | Status          | Notes                                                                 |
| ---------------------------------- | --------------- | --------------------------------------------------------------------- |
| Provider enabled + Settings health | **Yes**         | v0.2.118; auth email + SuperGrok Heavy tier observed                  |
| Model list from live ACP           | **Yes**         | `grok-4.5` (wire may add more later)                                  |
| Reasoning effort picker            | **Yes**         | Process-scoped `--reasoning-effort`; restart + session resume         |
| Sticky effort across sends         | **Yes**         | Sticky options preferred over stale thread selection                  |
| Full-access → `--always-approve`   | **Yes**         | Spawn flag from runtime mode                                          |
| Streaming assistant text           | **Yes**         |                                                                       |
| Reasoning / thought stream         | **Yes**         | `agent_thought_chunk` → reasoning                                     |
| Tool calls + approvals             | **Yes**         | ACP permission path                                                   |
| Ask-user questions                 | **Yes**         | `_x.ai/ask_user_question`                                             |
| Plan updates + plan exit           | **Yes**         | `_x.ai/exit_plan_mode` approve/reject                                 |
| Slash commands catalog             | **Yes**         | Live `/compact`, `/context`, `/workflow`, hooks, skills, …            |
| Skills picker ($ / slash)          | **Yes**         | Mapped from ACP commands with descriptions                            |
| Context / token usage              | **Yes**         | Usage even when xAI settles first; → `context-window.updated` → meter |
| Session title updates              | **Yes**         | `session_info_update` → `thread.metadata.updated`                     |
| In-session `session/set_model`     | **Yes**         | No-op + prompt continuity proven; no forced new thread                |
| Stop / interrupt turn              | **Yes**         |                                                                       |
| Resume via `session/load`          | **Yes**         | Effort restart and app resume use resume cursor                       |
| Checkpoints / diffs                | **Yes**         | Generic T3 orchestration (observed in UI)                             |
| MCP (T3 session MCP)               | **Yes**         | Injected when MCP session present                                     |
| Provider-side rollback             | **N/A**         | Grok ACP has no `thread/rollback`; T3 reports clear error             |
| Plan / Build toggle + `/plan`      | **Hidden**      | User choice; Grok does not honor T3 `interactionMode`                 |
| Multi-model switch UI              | **Conditional** | Wire currently single model; same set_model path when more appear     |
| Subagents as nested T3 threads     | **No**          | Run inside Grok process; show as tools/tasks in same thread           |
| Workflows / goals UI               | **Slash only**  | Grok owns; `/workflow`, `/goal` in catalog — no T3-native manager     |

## How to run isolated UI verification (test-t3-app)

```bash
cd /path/to/zoen-t3
mkdir -p .t3-parity-test
node scripts/dev-runner.ts --home-dir "$(pwd)/.t3-parity-test" dev
# Pair with printed pairing URL (do not use ~/.t3)
# Select Grok, send a turn, open / for slash catalog, Settings → Providers for auth
```

## Reference sources

- Live CLI: `grok` 0.2.118
- Upstream source: `Code/forks/grok-build` (ACP shell, exit_plan_mode, effort meta)
- Matrix history: `docs/zoen/grok-parity.md`, trail: `docs/zoen/AUTONOMOUS_TRAIL.md`
