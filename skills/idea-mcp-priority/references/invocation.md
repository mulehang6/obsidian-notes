# Invocation contracts

## Select the current mode

Inspect the tools currently visible to the agent.

- **Direct mode:** individual built-in IDEA functions are exposed. Locate the retained function by its suffix and purpose, then use its live description and JSON schema. Prefixes vary by host.
- **Router mode:** the current built-in entry point is `mcp__idea__execute_tool`. It invokes named IDEA tools through a `command` string.

These contracts apply to the built-in capabilities retained in this skill. Index MCP has its own schemas and routing rules in `ide-index-mcp`.

Live direct schemas win over this reference. In router mode, use the relevant topic reference for the tool's purpose and calling pattern; use runtime validation feedback only to settle a parameter spelling or required value that is specific to the current router version.

## Direct mode

Call the matching exposed tool and copy field names from its live schema. Include known `projectPath`; do not derive argument names from a tool name.

## Router mode

Call the router with two layers:

```ts
await tools.mcp__idea__execute_tool({
  command: "read_file --file_path \"<IDEA-resolved source path>\"",
  projectPath: "<confirmed absolute project path>",
})
```

- `projectPath` belongs to the router's outer argument object.
- Router flag casing is version- and tool-specific. Begin with the documented spelling, then make one minimal non-mutating validation call if it is rejected. In the 2026.2 router, `read_file --file_path` uses snake case, while retained tools may require camel case such as `--directoryPath`, `--descriptorPath`, `--inspectionKtsCode`, and `--pathToSpecification`. A silently ignored flag commonly appears as a missing camel-case required parameter.
- Do not pass a nested `{ tool_name, arguments }` object to the router. Its outer contract is `command` plus `projectPath`; put the invoked IDEA tool and its flags entirely in `command`.
- Quote paths or values containing spaces. Pass objects and arrays as JSON when the router requests them.
- An error may accidentally include a tool-name list. Treat it as diagnostic data, not a source of schemas or authorization. Do not deliberately provoke such errors to enumerate tools.
- Do not use `<tool> --help` as a contract source: some versions parse it as an ordinary parameter or ignore it.

## Verified read-file corrections (2026-10-13)

For a needed built-in IDEA file read, the verified router command is `read_file --file_path "<path>"`, with the confirmed absolute `projectPath` in the outer object. The following errors occurred while reading `Lessplain/AGENTS.md`; the corrected call returned numbered file contents with `isError: false`.

| Failed command | Observed result | Correction |
| --- | --- | --- |
| `get_file_text_by_path --path Lessplain/AGENTS.md` | Tool not found | Use this router's `read_file`, rather than importing a name from another MCP contract. |
| `read_file --help` | `Parameter 'help' requires a value` | Read the invocation and source-reading references before the call; this router does not supply CLI help. |
| `read_file --path Lessplain/AGENTS.md` | `Missing required parameters: file_path` | Use `--file_path`; the router did not accept `--path` as an alias. |

If validation rejects a documented read-only call, correct only the field identified by the error and inspect `isError` plus the returned content. An unknown-tool list establishes names only; it is not a parameter schema. Keep this observation scoped to the recorded router version, and prefer any live direct schema when available.

## Contract resolution

### Verified JSON argument quoting

For a router flag expecting an object, pass JSON text inside a single-quoted argument. Encode apostrophes inside JSON string values as the JSON escape `\u0027`, so they do not terminate the router argument. This preserves embedded source quotes and newlines after JSON decoding. Do not double-JSON-encode the entire argument: this router preserved extra backslashes; bare JSON also lost property-name quotes. This was verified with lessplain_present and its nested sources payload. The command string is a router argument, not a shell command.

1. Prefer the live direct schema.
2. In router mode, read the relevant topic reference from this skill and follow its documented tool flow.
3. For router-only parameter spelling, use validation feedback for the minimum needed call; do not invent a full schema.
4. If project resolution fails, verify the outer `projectPath` against an already-confirmed open project. Do not try unrelated paths that could open a project or start an IDE.
5. Treat any project-local generated tool catalog as supplementary and potentially stale; never require it to apply this skill.

## Router observations (IDEA 2026.2)

- The result is a `CallToolResult`; operational success or failure is often encoded in `content[0].text` and `isError`, not thrown as a tool exception. Some text is JSON encoded a second time, notably `git_status`; parse it before drawing conclusions.
- An unknown tool name returns the available tool-name list, but not reliable descriptions or parameter schemas. `<tool> --help` likewise cannot establish a contract.
- `skill_search --mode` accepts `file`, `text`, `regex`, or `symbol`; `all` is rejected. This tool is for IDEA-side skill discovery, not project code search.
- `execute_terminal_command` could not launch PowerShell in this environment: snake-case `--execute_in_shell` was ignored, while camel-case `--executeInShell true` failed on the quoted executable path. Prefer the approved host shell until this is fixed.
- `execute_terminal_command` also tried to launch a relative Windows batch path such as `.\\gradlew.bat` directly and failed with `CreateProcess error=2`; it did not automatically invoke `cmd.exe` or PowerShell. After one such failure, use the approved host PowerShell instead of repeatedly changing quoting.

## Contract provenance

These references come from the repository's 2026-09-18 revision. They are local observations, not proof of every current inner schema. The current exposed schema wins. Use inherited examples only for a needed operation, check validation feedback, and verify output coverage.
