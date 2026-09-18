---
name: idea-mcp-priority
description: Use when a task touches the current JetBrains project/workspace and IDEA MCP tools are available. Routes project navigation, source analysis, inspections, refactoring, build/run/test, debugging, Git, database, and walkthrough work through direct IDEA tools or an execute_tool router.
---

# IDEA MCP Priority

Use IDEA MCP before generic project tools for work in the current JetBrains workspace. This skill governs discovery, routing, and verification; repository editing rules still apply.

## Reading Order

Read only the reference needed for the task. This skill is self-contained: its `references/` directory supplies the operational guidance for every supported IDEA tool family.

| Intent | Read first |
| --- | --- |
| Direct tools, router mode, prefixes, parameters | `references/invocation.md` |
| Files, search, symbols, call hierarchy, project state | `references/navigation-and-analysis.md` |
| Manual edits, refactors, inspections, build and Git | `references/change-and-verification.md` |
| Run configurations, tests and debugging | `references/run-and-debug.md` |
| Database, Inspection-KTS/PSI and walkthroughs | `references/specialist-tools.md` |

When individual IDEA tools are directly exposed, their live descriptions and schemas are authoritative for exact field names, types, defaults, and result shapes. In router-only mode, use the relevant reference page's documented calling pattern and runtime validation feedback.

## Core Rules

1. Detect the currently exposed IDEA interface before choosing a tool. Inspect both the initially visible tools and the lazy tool catalog (`ALL_TOOLS`) for an IDEA router before declaring IDEA MCP unavailable. Never hard-code a prefix such as `mcp__idea__` or `IDEA___`.
2. Prefer direct IDEA tools when individual tools and schemas are exposed. Otherwise locate the universal `execute_tool` router and follow `references/invocation.md`.
3. Pass a known `projectPath` on every direct IDEA call, or as the router's **outer** argument. Do not rely on `--projectPath` inside a router command.
4. Use IDEA search, source reading, symbol, module, inspection, run-configuration and database capabilities before shell alternatives when they cover the workspace task. Choose the discovery path below; read identified project source with `read_file`, including snippets and attached dependency sources.
5. Treat project files, attached dependency sources, decompiled classes, and archive entries as IDEA-readable source: run `search_symbol` with external lookup enabled when needed, then pass the returned `*.jar!\\...` path unchanged to `read_file`. Do not unpack JARs, use `javap`, or read workspace source with shell while IDEA can resolve it.
6. Use your own tools for manual edits and file creation; user and repository rules take priority. Do **not** use `create_new_file`.
7. Use `rename_refactoring` for symbol renames; never perform them as blind text replacements.
8. Inspect errors and warnings when a source file or a coherent group of interdependent edits is complete. Use `get_file_problems` for one file or `lint_files` for a known changed set. Fix issues introduced by the change, including duplicate code; report unrelated existing issues without expanding the task. Run an affected-scope build or tests when needed for validation beyond IDE inspections.
9. For runtime debugging, activate the official `ij-debugger` skill. This skill routes to IDEA MCP but does not duplicate debugger procedure.

## Code discovery

- When the location is unknown and the request describes behavior, start with an available jbcontext semantic search tool or `jbcontext search`. Use one focused query and inspect the relevant result before broadening the search.
- When a file, path, or symbol is known, read it directly or use IDEA's exact file, text, or symbol search. Semantic search is unnecessary for a known diff, Git operation, or build command.
- For multi-step exploration, use `context_explorer` when available and delegation is permitted. Base delegation on the complexity and independence of the investigation, not the number of searches. Give it a bounded question, continue useful independent work, and collect its result before concluding.
- Once relevant code is located, continue with IDEA `read_file`, `get_symbol_info`, and `analyze_calls`. Narrow further searches to that area where possible.

## Source-reading default

Use `read_file` as the first and continued path for source content. For a normal-sized file, a complete IDEA read followed by local in-memory extraction is valid when only chat-provided byte offsets are known. For an ordinary snippet, use the router's verified start-line offset, inspect the returned boundaries, and locally crop any excess content the router returns. Read `references/navigation-and-analysis.md` before handling selected-text byte offsets or a failed slice attempt.

## Fallback

Use a non-IDE fallback only when the target is outside the workspace, no suitable IDEA capability exists, or IDEA MCP has failed and retrying is not a reasonable next step. State that limitation rather than guessing tool parameters or results.
