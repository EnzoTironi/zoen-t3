# Mobile Grok validation (no fork branding required)

## Question

Do we need mobile app changes for Grok parity when branding on mobile is not a goal?

## Method

Code search of `apps/mobile` and `packages/client-runtime` for Grok-specific UI/logic (2026-08-05, `zoen/main` + plan/multi-agent batch).

Commands used:

```bash
rg -n 'showInteractionModeToggle|provider === "grok"|case "grok"' apps/mobile
rg -n 'task\.started|interactionMode' apps/mobile packages/client-runtime
```

## Findings

| Area                 | Result                                                                                                                      |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Provider icon        | `apps/mobile/src/components/ProviderIcon.tsx` already maps `provider === "grok"` (X/Grok mark)                              |
| Chat / turns / tools | Shared contracts + server adapters; no Grok-only mobile fork                                                                |
| Context meter        | Uses shared activity kinds (`context-window.updated`) from server                                                           |
| Skills / slash       | Driven by `ServerProvider` snapshot over the wire                                                                           |
| Plan toggle          | Uses `showInteractionModeToggle` from provider snapshot (server now `true` for Grok; `/plan` prefix is server-side on send) |
| Multi-agent          | Mobile already renders `task.*` activity rows; Grok now emits them from subagent tools on the server                        |
| Branding             | Not required for this fork phase; stock T3 mobile is intentional                                                            |

## Conclusion

**No mobile code changes are required** for Grok server/adapter features to work, as long as:

1. The phone pairs to a **server built from zoen-t3** (desktop host, `npx t3` from fork, or CI artifact).
2. The official App Store / Play **T3 Code** client is fine — it speaks the same contracts; Grok improvements are on the **server**.

Optional later: fork mobile only for Zoen branding or store listing, not for Grok protocol support.

## How to verify

1. Run zoen-t3 server (desktop or CLI) on the LAN/tailnet.
2. Pair stock T3 mobile to that environment.
3. Select Grok, send a turn, confirm stream + tools + slash.

## Device attempt (2026-08-05)

| Check | Result |
|-------|--------|
| iPhone 17 Pro simulator boot | OK |
| `com.t3tools.t3code.dev` installed | **Missing** (no dev client on this machine) |
| `com.t3tools.t3code` (store) installed | **Missing** |
| Android `adb` | Not installed |
| Server contracts for plan/tasks/meter | Shared over wire; no mobile code delta |

**Conclusion stands:** no mobile app changes. Full device E2E needs a stock/dev T3 Code client install + pair to zoen-t3 server.
