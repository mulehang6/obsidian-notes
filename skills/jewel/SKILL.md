---
name: jewel
description: Build, debug, or migrate JetBrains Jewel Compose UI, including themes, components, DecoratedWindow, and desktop title bars. Resolve APIs from the exact resolved Jewel source before coding; use jewel-markdown for Markdown-specific work.
---

# Jewel

Jewel is actively developed and its APIs can change between releases. Treat the source matching the project's resolved Jewel coordinates as authoritative.

## Source-first workflow

1. Read the project's resolved Jewel, Compose, Kotlin, and JBR versions before proposing an API or workaround.
2. Open the matching `*-sources.jar` through the IDE first. Use its implementation, KDoc, and tests as the API contract.
3. Use a local `intellij-community/platform/jewel` checkout only when it matches the resolved version; use its samples to understand intended composition.
4. Treat official docs, blog posts, and old samples as discovery leads only. If they conflict with matching source, source wins. If matching source is unavailable, state that the evidence is insufficient rather than inventing a likely API.

## Route the task

| Work | Start with |
| --- | --- |
| Components, themes, metrics, icons | Matching Jewel UI/foundation sources and the consuming module's resolved dependency graph. |
| `DecoratedWindow`, title bars, native controls | Matching decorated-window sources, JBR API sources, and the standalone title-bar sample. Validate in a running Windows/macOS session. |
| Standalone vs IntelliJ Platform integration | Identify the host first; do not transplant standalone setup into an IDE plugin or vice versa. |
| API migration or compile failure | Compare the exact old and resolved-source signatures; do not extrapolate from Jewel `main`. |
| Runtime input, hover, drag, or native hit testing | Use debugger evidence before changing UI. Verify client-region registration, delivered AWT events, and `forceHitTest` inputs separately. |
| Jewel Markdown | Hand off to `jewel-markdown`; this skill does not replace it. |

## Working rules

- Preserve the host application's chosen Jewel architecture unless the request authorizes a redesign.
- For native title bars, place `clientRegion` on each interactive composable, not on broad containers. Keep the blank title-bar area available for native window actions.
- A successful build does not prove native-window behavior. For runtime issues, test the actual window and record observed event flow before editing production UI.
- Do not compensate for missing evidence with Swing overlays, transparent hit targets, or version upgrades unless the user explicitly authorizes those approaches.

## Mandatory verified-pitfall writeback

This is a required closure step, not optional documentation. Before the final response of every Jewel task that confirms a pitfall, update [references/verified-pitfalls.md](references/verified-pitfalls.md).

- Record only facts verified by matching source, a test, or live runtime debugging.
- Include the exact Jewel/Compose/JBR/OS context, symptom, reproduction/evidence, confirmed boundary or cause, safe resolution/status, and source or issue reference.
- Mark an unresolved cause as unresolved; do not convert a hypothesis into a rule.
- Correct or replace stale entries when later evidence changes them.
- If no pitfall was verified, say so internally and do not add a speculative entry.

Read the reference before working on a related issue and after a failed or surprising Jewel integration.
