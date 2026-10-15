# Runs, tests and debugging

## Test and non-test runs

| Tool | Use it when | Key usage rule |
| --- | --- | --- |
| `get_run_configurations` | Before running an authorized test or non-test process | This is the source of truth for exact configuration names, runnable file/line locations, and whether temporary launch overrides are supported. |
| `execute_run_configuration` | Run a known test/non-test configuration or discovered runnable file/line | Pass an exact returned configuration name, or the returned file-and-line pair. Do not invent configuration names. Only pass argument/environment/working-directory overrides when the configuration says it supports them. |

Task-authorized test discovery and execution may use these built-in run tools. Follow `ij-debugger` for test debugging, including an ordinary `execute_run_configuration` run to reproduce a failure before starting debugging. Repository-required acceptance commands remain host-command work.

For `waitForExit=true`, treat a timeout as an execution that may still be running; use returned output or full-output location rather than claiming a final result. Use a discovered test or non-test run configuration for task-authorized IDE execution. Repository acceptance commands remain own-tool work. No IDE or app launch is authorized merely by this reference.

## Debugging

Activate and follow the official `ij-debugger` skill whenever runtime evidence, breakpoints, stepping, frames, thread state, or expression evaluation is required. The following IDEA tool names are routed by that skill:

- Session lifecycle: `xdebug_get_debugger_status`, `xdebug_start_debugger_session`, `xdebug_control_session`
- Breakpoints: `xdebug_list_breakpoints`, `xdebug_set_breakpoint`, `xdebug_remove_breakpoint`, `xdebug_run_to_line`
- Runtime state: `xdebug_get_threads`, `xdebug_get_stack`, `xdebug_get_frame_values`, `xdebug_get_value_by_path`, `xdebug_evaluate_expression`, `xdebug_set_variable`

Do not reproduce an ad hoc debugger flow here. In particular, use status-derived session IDs, set logpoints before adding print statements, and let `ij-debugger` own breakpoint cleanup and pause/resume sequencing.

## Run parameter fields

`!` is schema-required and `?` is optional. Pass known `projectPath`; router flags preserve each tool's recorded casing; do not mechanically convert camelCase to snake_case. Pass JSON text for `envs`.

| Tool | Fields |
| --- | --- |
| `get_run_configurations` | `filePath?`, `projectPath?` |
| `execute_run_configuration` | `configurationName?`, `filePath?`, `line?`, `envs?`, `programArguments?`, `workingDirectory?`, `waitForExit?`, `timeout?`, `projectPath?` |

`execute_run_configuration` uses exactly one target mode: `configurationName`, or `filePath` + `line`. The exact `xdebug_*` parameter contracts, target modes, logpoint setup, session IDs, and cleanup procedure belong exclusively to the official `ij-debugger` skill.
