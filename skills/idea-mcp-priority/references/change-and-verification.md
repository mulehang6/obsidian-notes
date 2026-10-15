# File handling and acceptance checks

Manual source edits, file creation and commands use your own tools, following user and repository rules. Project source and document reads use built-in IDEA read_file, with only the explicit fallback in SKILL.md. Semantic refactoring, code formatting, diagnostics and IDE builds follow `ide-index-mcp`; this reference does not offer overlapping built-in tools.

| Tool | Use it when | Key usage rule |
| --- | --- | --- |
| `recognize_ij_module_kind` | You need to identify an IntelliJ-module template kind | Specialist identification tool for IntelliJ plugin/module work; module creation follows `ide-index-mcp`. |
| `execute_terminal_command` | The task specifically requires the IDE terminal | Ordinary project and acceptance commands use own shell tools. Follow repository shell restrictions. |

## Verification

- Run repository-required tests, packaging and compatibility commands with own command tools in the correct product directory. IDE results do not replace these checks.
- Use the affected host build or tests when compilation or runtime behavior needs validation. Broaden or repeat checks only when failures or unresolved concerns justify it.
- Fix issues introduced by the change. Report unrelated existing issues without broadening the task.
- For tests, verify current-run completion, test counts, failures/errors and skipped tests; a stale report or zero tests is insufficient.
- A client timeout may leave an operation running. Check its state before starting another.
- Report the checks performed and any remaining limitations.

## Parameter fields

`!` is schema-required and `?` is optional. Pass known `projectPath`. Use live schemas; router references record installation-specific field names. Do not execute commands or create modules solely to discover flags.

| Tool | Fields |
| --- | --- |
| `execute_terminal_command` | `command!`, `executeInShell?`, `maxLinesCount?`, `reuseExistingTerminalWindow?`, `timeout?`, `truncateMode?`, `projectPath?` |
| `recognize_ij_module_kind` | `descriptorPath!`, `projectPath?` |

Inspection-KTS script validation belongs to [specialist-tools.md](specialist-tools.md); it does not replace routine Index diagnostics.
