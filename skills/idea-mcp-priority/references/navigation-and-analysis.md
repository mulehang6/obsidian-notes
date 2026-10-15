# Source reading and IDE project information

Use these retained tools for source access and IDE-specific project context. Pass known `projectPath`. Code navigation, search, symbol/call analysis and editor navigation follow `ide-index-mcp`; they are not documented here.

| Tool | Use it when | Key usage rule |
| --- | --- | --- |
| `read_file` | You need project source/documents, dependency source, decompiled code, or a virtual/archive entry | Use the confirmed project path; preserve IDEA-resolved dependency paths. In router mode use `--file_path`; never use Index `ide_read_file`. |
| `list_directory_tree` | The IDE project model is needed | Ordinary directory listing and path-glob enumeration use own filesystem tools. |
| `get_project_modules` | Module names/types in the loaded IDE model are needed | Do not infer this from Gradle/Maven files unless raw build text is the goal. |
| `get_project_dependencies` | Declared project/module dependencies matter | Use it before inspecting dependency declarations manually. |
| `get_repositories` | IDE VCS roots or remotes matter | Use it before guessing repository layout. |
| `git_status` | You need working-tree, staged, or branch state | Read-only status first; do not discard or overwrite user changes. |
| `skill_search` | IDEA-side skill discovery is specifically requested | Do not substitute it for project text or symbol search. |

## Reading workflow

Use built-in IDEA `read_file` through `mcp__idea__execute_tool` for ordinary project files as well as dependency, decompiled and virtual sources. Keep `projectPath` on the outer router call. Out-of-root non-source documents and unavailable source reading follow the fallback policy in SKILL.md; do not silently switch to Python or shell source reads.

Use the exact source path resolved by IDEA, verify numbered output ranges, and crop in memory if needed. Selection byte offsets are not line offsets. Do not unpack JARs with shell while IDEA can read the resolved source.

## External-source pitfalls observed in IDEA 2026.2

- Preserve IDEA-returned archive paths verbatim, including the `*.jar!\\...` or `src.zip!\\...` separator. Do not normalize them to filesystem paths or remove `!`. Do not assume an Index-returned `jar://` URL has the same contract as a built-in IDEA source path.
- Check the actual module/dependency version. Multiple modules can resolve the same FQN to different versions. A guessed filename or mismatched source is not evidence that an API is missing.
- Router `read_file --offset` is a 1-based line start, not a byte offset. In IDEA 2026.2, `--limit` may be silently ignored even when `--offset` takes effect; treat it as a best-effort hint, inspect the returned boundary lines, and crop any excess content in memory. Omit both to read a normal-sized source file completely.
- Chat attachments may describe a selection with UTF-8 byte offsets. Those offsets are not `read_file --offset` values. Read project, attached or virtual sources through IDEA and map the selection in memory.
- `read_file --line_start/--line_end` and made-up byte-range flags are not supported router parameters. They can be silently ignored and return more source than requested. Use `--offset` as the verified start-line control; treat `--limit` as optional/best-effort and verify the returned boundary lines before treating the result as a slice.

## Parameter fields

`!` is schema-required and `?` is optional. Include known `projectPath` even though schemas mark it optional. In direct mode use the live field names exactly. In the recorded 2026.2 router, `read_file` uses `--file_path`; `list_directory_tree` instead requires `--directoryPath`. Keep `projectPath` on the outer router call.

| Tool | Fields |
| --- | --- |
| `get_project_dependencies` | `projectPath?` |
| `get_project_modules` | `projectPath?` |
| `get_repositories` | `projectPath?` |
| `git_status` | `includeIgnored?`, `includeUntracked?`, `limit?`, `repositoryPathRelativeToProject?`, `projectPath?` |
| `list_directory_tree` | `directoryPath!`, `maxDepth?`, `timeout?`, `projectPath?` |
| `read_file` | `file_path!`, `offset?` (1-based line), `limit?` (max 5000 lines), `projectPath?` |
| `skill_search` | `q!`, `mode!`, `paths?`, `includeExcluded?`, `include_external?`, `limit?`, `projectPath?` |

Public documentation may describe `read_file` with `mode/start_line/max_lines` while the recorded local router uses `offset/limit`. Unknown flags can be silently ignored. Returned ranges establish what was read; a small output budget may include both head and tail rather than a continuous requested block.
