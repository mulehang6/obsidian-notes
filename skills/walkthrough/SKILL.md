---
name: walkthrough
description: Authors inline code walkthroughs in IntelliJ IDEA via the walkthrough-plugin MCP tools (show_walkthrough_items, await_walkthrough_question, insert_walkthrough_tangents). Use when the user asks for a guided tour, walkthrough, explainer, or step-by-step code tour anchored to specific files and lines, and the `idea` MCP server is available.
---

# Authoring walkthroughs

The [walkthrough-plugin](https://github.com/forketyfork/walkthrough-plugin) renders styled popups inside IntelliJ next to specific lines of code, lets the user step through items with Previous/Next, and lets them type follow-up questions that you answer by inserting child steps.

The three MCP tools form one stateful protocol. Skipping the question-loop leaves the popup waiting for input that never arrives.

## Tools

All tools live on the `idea` MCP server. Fully qualified names:

- `mcp__idea__show_walkthrough_items` — create the walkthrough, returns a `walkthroughId`
- `mcp__idea__await_walkthrough_question` — blocks until the user asks a question or dismisses
- `mcp__idea__insert_walkthrough_tangents` — splices answer steps as children of a step

If these tools are not available, do not pretend to create an inline walkthrough. Tell the user that the IntelliJ walkthrough plugin and its `idea` MCP server are required, then offer a normal text walkthrough only if they want one.

## Required protocol

```
show_walkthrough_items(description, items)        → walkthroughId
loop:
  await_walkthrough_question(walkthroughId)        → "dismissed" | (parentLabel, question)
  if dismissed: stop
  answer = build items addressing the question
  insert_walkthrough_tangents(walkthroughId, parentLabel, answer)
```

**You must enter the await loop immediately after `show_walkthrough_items` returns.** Do not summarize, do not stop, do not call other tools first. The popup's question UI depends on you waiting. Keep looping until `await_walkthrough_question` returns the literal string `dismissed`.

If a walkthrough tool returns an error such as `No active project`, `No active editor`, or `Unknown walkthroughId`, tell the user what failed and stop the loop. Do not retry blindly.

## Item format

The plugin parses `items` with Gson as a JSON array string. Each object has this runtime shape:

```json
{ "text": "...markdown...", "file": "src/Foo.kt", "line": 42 }
```

- `text` (required) — GitHub-flavored markdown. Supported: headings, fenced code with syntax highlighting, lists, tables, strikethrough, GitHub alerts (`> [!NOTE]`), autolinks, inline HTML.
- `file` (optional) — project-relative path, forward slashes
- `line` (optional) — 1-based line number; navigates the editor and anchors the connector to that line

Items without `file`/`line` render the popup without navigating.

The `items` parameter is a JSON **string** containing an array. Build a JSON array, then stringify it exactly once for the tool argument:

```json
{
  "description": "Auth middleware request flow",
  "items": "[{\"text\":\"This middleware validates the bearer token before routing continues.\",\"file\":\"src/AuthMiddleware.kt\",\"line\":42},{\"text\":\"This step is conceptual and does not navigate.\"}]"
}
```

Do not include `label` or `parentLabel` in item objects. The plugin ignores input labels for top-level items and assigns child labels from the `parentLabel` tool argument.

## Verifying line numbers (mandatory)

Line numbers must be correct — the connector visibly points at that line. **Read the file before calling `show_walkthrough_items` or `insert_walkthrough_tangents`.** Never estimate from a diff, commit, memory, or LSP output. Files drift; verify in the current working tree.

For each item with a `line`:
1. Read the file
2. Confirm the line number matches the symbol/expression the step describes
3. Use `rg -n` to find candidate anchors when available; if `rg` is unavailable, use `grep -n`
4. Treat search output as a candidate only; re-read the current file before using the line number

Anchor the popup to the **actual code line the reader should inspect first**, not a nearby comment, method signature, or general area.

- If the step names a concrete call, field, branch, assignment, or return, point to that exact line.
- If the step is about a whole method only at a conceptual level, a method-signature anchor is acceptable.
- If comments already explain the local code, keep the step short and use the anchor to bring the reader to the real execution point.

## Labels

Top-level items are auto-labeled `1`, `2`, `3`, … in order. Do not set labels yourself.

Child steps inserted via `insert_walkthrough_tangents` are auto-labeled by appending `.N` to the parent: tangents under `3` become `3.1`, `3.2`. Nested tangents under `3.1` become `3.1.1`, etc. Pass the exact `parentLabel` returned by `await_walkthrough_question`.

## Description field

A short human-readable phrase, shown in the project's walkthrough history (`.idea/walkthroughs/`). Treat it as the title a user will scan a week later. Examples:

- `"Auth middleware request flow"`
- `"How WalkthroughPopupSurface paints the connector"`
- `"Adding a new MCP tool to ShowWalkthroughItemsToolset"`

Avoid generic phrases like `"Code walkthrough"` or `"Tour"`.

## Choosing walkthrough scope

Default to the smallest scope that cleanly answers the user's question.

- If the user asks about a concrete behavior or flow, build the walkthrough around that **scenario/call chain**, not around the whole file.
- If the user only points at a file and gives no behavior, explain the file by **method-level structure** first. Start with the most important public entry points and main helpers rather than trying to summarize the whole file at once.
- Show **one walkthrough at a time**. Do not open multiple parallel walkthroughs for related topics. If more topics are worth covering, finish the current walkthrough first and then suggest the next one.
- Inside a single walkthrough, order items by the reading path that best matches the question: usually entry point first, then direct downstream calls, then supporting or cross-cutting logic.

## Writing step content

Each step is one focused idea anchored to one location. The popup is ~560×300px — readable, but not a doc page.

Good step text:
- Opens with the **what** in one sentence, then the **why** if non-obvious
- Uses inline code for identifiers: `` `WalkthroughSession` ``, not WalkthroughSession
- Uses fenced code blocks for snippets longer than a line or two
- Quotes the actual surrounding code only when the reader needs more than what's visible at the anchored line

A walkthrough item should map to a **logic region**, not to an arbitrary chunk of a method. Good boundaries for logic regions are:

- a nearby comment that introduces a responsibility
- a blank-line-separated block
- a branch entry such as `if`, `switch`, or `catch`
- an obvious responsibility change such as "load", then "mutate", then "persist", then "sanitize"

Do not merge adjacent regions just because they live in the same method. If a reader would naturally pause and say "this is the next thing this code does," that is usually a new item.

Walkthrough text is there to orient the reader, not to replace reading the code.

- If the code or comments already say what the block does, write a brief note about the block's role in the broader flow and stop there.
- Save detailed explanation for follow-up questions via tangents.
- Prefer a short, precise sentence over a paragraph that paraphrases the code line by line.

Suggested step count for a single walkthrough: no minimum, and **13 top-level items or fewer by default**. For a single strongly connected chain, you may go beyond that only when splitting would make the explanation harder to follow; in that case, keep the extra steps terse and tightly related. If a walkthrough wants to cover multiple loosely related chains, split it into separate walkthroughs instead.

## Q&A loop: answering tangents

`await_walkthrough_question` returns either:
- `dismissed` (literal string) — stop the loop
- a body like `parentLabel=3\nquestion=Why is this dispatched on the EDT?`

To answer:
1. Investigate as you normally would (read files, search, run commands)
2. Build a small `items` array — usually 1–3 child steps — addressing the question
3. Call `insert_walkthrough_tangents` with the **exact** `parentLabel` from the question
4. Loop back to `await_walkthrough_question` with the same `walkthroughId`

Tangent items use the same format as top-level items. Give them `file`/`line` when the answer is anchored somewhere specific; omit when the answer is purely conceptual.

If the question is unanswerable (out of scope, hallucinated premise), still respond with at least one tangent item that says so plainly — silence leaves the user staring at a spinner.

## Authoring workflow

```
[ ] 1. Clarify the goal — what should the user understand after stepping through this?
[ ] 2. Choose the scope — scenario/call chain first; method-level file overview only when no behavior is given
[ ] 3. Pick anchor points — the specific files/actual code lines the reader should inspect first
[ ] 4. Read each anchor file to confirm line numbers and surrounding context
[ ] 5. Draft the items array, one focused logic region per anchor
[ ] 6. Check item count — default to 13 or fewer unless one strong chain truly needs more
[ ] 7. Call show_walkthrough_items, capture walkthroughId
[ ] 8. Enter the await_walkthrough_question loop; respond to each question; stop on dismissed
```

## Common mistakes

- **Skipping the await loop.** The user can't ask questions if you don't wait. Don't call `show_walkthrough_items` and then end your turn.
- **Stale line numbers.** Copying line numbers from a previous session, a diff, or a tool output that wasn't a real file read. Always re-read.
- **Anchoring near the code instead of on the code.** If the step says `countService.incrArticleReadCount(...)`, point to that call, not to the method header or a nearby comment.
- **Passing items as a list.** The `items` parameter is a JSON string. Stringify.
- **Manually setting `label` or `parentLabel` on items.** The plugin assigns labels. Authors only pass `parentLabel` to `insert_walkthrough_tangents`, never inside an item.
- **Generic descriptions.** `"Walkthrough"` is useless in history; the description is searchable metadata.
- **Walls of text per step.** The popup is small; break content across steps anchored to the relevant lines instead.
- **Using one oversized step for multiple regions.** Adjacent blocks with different responsibilities should usually be separate items, even inside one method.
- **Paraphrasing comments back to the user.** If the code already says what it does, use the popup to orient the reader to the flow, not to restate the comment.

## Example

User: "Walk me through how the MCP toolset shows a walkthrough."

After reading the current files and verifying the line numbers. The numeric lines below show the JSON shape; replace them with the lines you just verified in the target checkout.

```json
{
  "description": "How show_walkthrough_items wires an MCP call to the editor popup",
  "items": "[{\"text\":\"This `@McpTool` method is the public entry point for the walkthrough request.\",\"file\":\"src/main/kotlin/com/forketyfork/walkthrough/ShowWalkthroughItemsToolset.kt\",\"line\":22},{\"text\":\"This line switches onto the EDT before touching editor UI state.\",\"file\":\"src/main/kotlin/com/forketyfork/walkthrough/ShowWalkthroughItemsToolset.kt\",\"line\":56},{\"text\":\"This line resolves the active project from the coroutine context rather than from a tool parameter.\",\"file\":\"src/main/kotlin/com/forketyfork/walkthrough/ShowWalkthroughItemsToolset.kt\",\"line\":139},{\"text\":\"This call hands the verified anchor items to the orchestrator that builds and shows the popup session.\",\"file\":\"src/main/kotlin/com/forketyfork/walkthrough/WalkthroughOrchestrator.kt\",\"line\":30}]"
}
```

Then immediately:

```json
{ "walkthroughId": "abc123" }
```

If it returns:

```
parentLabel=3
question=What happens if there's no active editor?
```

Build the tangent answer after re-reading the relevant code, then call `insert_walkthrough_tangents` with:

```json
{
  "walkthroughId": "abc123",
  "parentLabel": "3",
  "items": "[{\"text\":\"If no active editor is available, `showWalkthroughSession` returns null and the tool reports `No active editor` to the MCP client.\",\"file\":\"src/main/kotlin/com/forketyfork/walkthrough/ShowWalkthroughItemsToolset.kt\",\"line\":58}]"
}
```

Loop back to `await_walkthrough_question`. Continue until it returns `dismissed`.
