---
name: idea-mcp-priority
description: Prefer JetBrains built-in IDEA MCP read_file for project source code, dependency source, decompiled and virtual sources. Read ordinary non-source files with the agent's own tools. Also use IDEA MCP for IDE project information, authorized execution, debugging and specialist workflows. Code intelligence follows ide-index-mcp and user or repository rules.
---

# IDEA MCP Priority

Use the built-in IDEA MCP for the capabilities retained here. Code search, navigation, symbol and call analysis, semantic refactoring, code formatting, diagnostics and builds follow `ide-index-mcp`. This skill does not provide built-in alternatives for those overlapping capabilities. Task-authorized test discovery and execution may use built-in IDEA run configurations; test debugging and its non-debug reproduction runs follow `ij-debugger`. User and repository rules take priority.

Read project source code through built-in IDEA `read_file`, including source files on disk. Dependency source, decompiled classes and virtual/archive source entries use the same tool. Do not use Index MCP `ide_read_file`, Python file-reading libraries or shell reads as an automatic substitute for source code.

Read ordinary non-source files directly with the agent's own filesystem tools: documentation, AGENTS.md, skills, logs, plain configuration and test/build reports. This applies both inside and outside project roots; Windows text reads prefer PowerShell `Get-Content`. No IDEA attempt or root-rejection explanation is needed first.

For source code, `read_file` only accepts files within the already-open project's roots, libraries and SDKs. Use the confirmed project and, when present, its real workspace alias. If source reading is unavailable, report the limitation and request a usable connection or explicit fallback; do not silently change readers or open another project.

## Reading order

Before the first `execute_tool` router call in a session, read [references/invocation.md](references/invocation.md), then the topic reference for that operation. Resolve the inner tool name and required flags from those references before calling it.

Read only the reference needed for the task.

| Intent | Reference |
| --- | --- |
| Direct tools, router mode, parameters | [invocation.md](references/invocation.md) |
| Attached sources, IDE project information and VCS state | [navigation-and-analysis.md](references/navigation-and-analysis.md) |
| Manual file handling, module-template identification and acceptance checks | [change-and-verification.md](references/change-and-verification.md) |
| Authorized test/non-test IDE runs and debugging | [run-and-debug.md](references/run-and-debug.md) |
| Database, Inspection-KTS/PSI and walkthroughs | [specialist-tools.md](references/specialist-tools.md) |

## Core rules

1. Inspect visible tools and the lazy tool catalog for the built-in IDEA interface before declaring it unavailable. Use directly exposed tools with their current schemas; in the current router mode, use `mcp__idea__execute_tool`.
2. Confirm which IDE and already-open project serve the task. Pass its absolute `projectPath` on direct calls or as the router's outer argument. Do not silently switch projects or probe a path that could open a project or start an IDE without authorization.
3. Manual edits, file creation, directory/path-glob operations and commands use the agent's own tools. Windows commands prefer pwsh 7. File reads follow the read_file rule above.
4. Read dependency sources, decompiled classes and virtual/archive entries through built-in `read_file`. Use the exact IDEA-resolved path and verify the target module, dependency version and returned line coverage. A matching FQN alone does not identify the intended dependency version.
5. Database discovery and queries use the dedicated IDEA MCP database tools in specialist-tools.md. Do not automatically replace them with Python, Node.js, JDBC or command-line database scripts; report unavailable connections and request an explicit fallback. IDE project-model, Inspection-KTS/PSI and walkthrough capabilities remain available for their specific tasks. Do not use specialist scripts to replace ordinary code navigation or diagnostics assigned to Index MCP.
6. Repository tests, packaging and compatibility checks use the required host commands. Use test or non-test IDE run configurations when the task authorizes an IDE run; do not start an IDE or app merely for validation. Runtime debugging and its test reproduction runs follow `ij-debugger` when available and applicable.

## Discovery and fallback

When only unfamiliar behavior is known, follow the repository's `jbcontext` discovery workflow. Once located, read source through built-in read_file; code search and semantic analysis follow `ide-index-mcp`, subject to user and repository rules. Multi-step exploration follows the repository's delegation and model rules; this skill does not mandate a fixed-model role.

Use current schemas where exposed. Router references record installation-specific observations; validate the needed call and its actual output rather than inventing flags or treating all examples as freshly verified. Do not deliberately provoke errors to enumerate tools, or use mutations/execution to discover parameters.

If a retained built-in capability is unavailable or still fails after a justified correction, state the limitation. Source reading follows the explicit fallback rule above; other capabilities may use an equivalent own-tool workflow where authorized. Do not substitute Index `ide_read_file` for built-in source reading. Do not repeatedly retry unchanged errors or perform unrelated discovery.
