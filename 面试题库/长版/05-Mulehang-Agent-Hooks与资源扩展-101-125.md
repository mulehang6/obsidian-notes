---
tags: [面试, AI-Agent, Hooks, Skills, MCP]
question_range: 101-125
status: 已完成
---

# Mulehang Agent：Hooks 与资源扩展（101-125）

## 101. Hooks 解决了什么问题？

### 面试时可以这样答

> Hooks 让用户或受信任扩展在主流程的固定位置执行规则，而不用修改 Agent 核心代码。例如提交 prompt 前补上下文、工具执行前阻断、权限请求时强制人工确认、模型准备结束时检查是否真的完成。它适合组织规范和本地自动化。
>
> Hook 也会执行命令，因此本身是高权限扩展点。项目只从用户设置和受信任包加载规则，并限制超时、输出和生命周期。不能把任意项目文件中的 Hook 自动当成可信代码。

## 102. 当前支持哪些 Hook 事件？

### 面试时可以这样答

> 当前事件包括 `SessionStart`、`UserPromptSubmit`、`PreToolUse`、`Stop`、`StopFailure`、`PermissionRequest` 和 `SessionEnd`。它们分别覆盖会话开始、用户提交、工具前置、正常完成检查、失败通知、权限判断和会话关闭。
>
> 事件名兼容 Junie 风格，但运行语义由本项目实现。回答时不能只背名称，要能指出每个事件在网关或工具拦截器中的触发位置。

## 103. 同一事件配置多个 Hook 时按什么顺序执行？

### 面试时可以这样答

> `AgentHookSettings` 保留列表顺序，dispatcher 按顺序执行匹配命令。合并不同来源时，基础设置先执行，追加来源在后。每条命令可以更新决定、附加上下文或输入，后续命令能看到同一事件输入，但最终以最后一个明确决定为准，遇到 `BLOCK` 立即停止。
>
> 顺序属于行为契约。若用无序 Map 或并行执行同步 Hook，同一配置可能产生不同结果，难以排查。

## 104. Hook 的 matcher 怎么工作？

### 面试时可以这样答

> 每个事件下可以配置多个 matcher。省略 matcher 表示匹配该事件的全部值；工具相关事件会用工具名作为 `matcherValue`。dispatcher 先筛选匹配项，再按配置顺序展开其中的命令。
>
> matcher 让规则只约束指定工具，例如所有 Shell 调用都要求确认，而读取工具继续默认策略。匹配失败时应当无副作用，配置错误则进入诊断，不能悄悄扩大匹配范围。

## 105. Hook 命令如何接收上下文？

### 面试时可以这样答

> dispatcher 把事件、sessionId、workspacePath、matcherValue、traceId 和事件 payload 编码成 JSON，通过 stdin 交给 Hook 命令。命令不用解析不稳定的环境变量或命令行转义，也能读取结构化参数。
>
> stdin 内容可能含 prompt、路径或工具参数，不能默认写入公开日志。Hook 的工作目录固定为 workspace，调用方仍需防止脚本自行访问更大范围。

## 106. 四种 Hook 决策分别是什么？

### 面试时可以这样答

> `CONTINUE` 表示 Hook 不改变默认流程，`ALLOW` 表示明确放行，`ASK` 表示强制人工确认，`BLOCK` 表示阻止。四态比一个布尔值更适合插入现有权限系统，因为“不表态”和“明确允许”不是一回事。
>
> `BLOCK` 优先级最高并立即停止后续同步 Hook。`ASK` 不能被后面的自动审批静默覆盖，否则组织策略要求的人在环会失效。

## 107. `PreToolUse` Hook 在哪里执行？

### 面试时可以这样答

> 本地工具通过 `AgentHookToolInterceptor` 在具体逻辑前触发 `PRE_TOOL_USE`，传入工具名和结构化参数。Hook 可以阻断、要求确认，也可以返回 `updatedInput` 修改参数。MCP 包装器也在调用远程 delegate 前触发同一事件。
>
> 拦截必须发生在任何副作用之前。若先启动进程或写文件再等待 Hook，阻断就只剩事后通知。

## 108. `PermissionRequest` 与 `PreToolUse` 有什么区别？

### 面试时可以这样答

> `PreToolUse` 面向每一次工具调用，可以检查或改写输入。`PermissionRequest` 只在动作需要权限决策时触发，payload 更偏向工具名、摘要、目标路径和预览。前者决定“这个调用能否进入工具逻辑”，后者参与“这个有风险的动作由谁批准”。
>
> 两者分开后，内容校验规则不必等到审批阶段才运行，权限策略也不用理解每个工具的全部参数。

## 109. `SessionStart` 为什么每个会话只执行一次？

### 面试时可以这样答

> 一个会话可能包含多轮用户消息。启动 Hook 通常用于初始化上下文或环境，若每轮重复执行会产生重复副作用。网关用 sessionId 集合记录已启动会话，只有首次运行触发。
>
> 如果启动 Hook 阻断，会移除启动标记，使用户修正配置后仍能重试。空 sessionId 的临时运行不共享会话生命周期。

## 110. `UserPromptSubmit` 能修改用户输入吗？

### 面试时可以这样答

> 可以。Hook 输出的 `updatedInput.prompt` 会替换本轮文本，`additionalContext` 会以明确的 Hook context 片段附加。代码还会同步更新 `inputParts` 中第一个文本部分，同时保持附件顺序。
>
> 修改必须对用户可解释。若 Hook 悄悄改变需求，最终结果很难追责。更合适的用途是补充项目规范、工单信息或固定上下文，不是擅自改写用户意图。

## 111. `Stop` Hook 为什么能让 Agent 继续？

### 面试时可以这样答

> 主 Agent 给出结果后，网关先运行 Stop Hook。若 Hook 返回 `BLOCK`，当前结果不会立刻作为最终完成，而是被写入历史，再添加“检查并补充未完成部分”的新 prompt，启动下一轮 Agent。
>
> 这适合运行测试、检查格式或验证交付物。Hook 不是直接篡改答案，而是把检查意见作为下一轮上下文，让模型看到自己已经给过什么。

## 112. Stop Hook 为什么限制最多重试 8 次？

### 面试时可以这样答

> 验证脚本若一直判定未完成，Agent 会在“生成结果、Hook 阻断、继续处理”之间循环。项目把补充处理上限设为 8，超过后抛出专门异常并安全停止。
>
> 8 是当前产品参数，不是通用最优值。日志应记录每次阻断原因；若频繁触顶，应修复 Hook 条件或任务定义，而不是简单提高上限。

## 113. `StopFailure` 什么时候触发？

### 面试时可以这样答

> Agent 主流程抛出非取消异常后，网关先把异常转换为用户可理解的 reason，再派发 `STOP_FAILURE`，最后发送运行级 Failed 事件。它适合失败通知、诊断采集或清理提示。
>
> StopFailure 不应掩盖原异常，也不应把失败改成成功。Hook 自身异常由安全分发逻辑吞住并记录，避免错误处理再次让会话卡死。

## 114. `SessionEnd` 与一次 run 结束有什么区别？

### 面试时可以这样答

> 一次 run 对应一条用户消息，一次 session 可以包含多轮 run。`SessionEnd` 只在窗口关闭或会话移除时触发，用于会话级收尾。普通 Completed 不会结束 Hook 生命周期。
>
> 网关给 SessionEnd 设 10 秒总预算，等待受限后台任务后关闭 lifetime。这样既给清理机会，也避免应用退出无限等待。

## 115. 异步 Hook 为什么不能参与本轮决策？

### 面试时可以这样答

> 异步 Hook 启动后主流程立即继续，它的结果到达时动作可能已经执行，因此不能可靠地产生 ALLOW、ASK 或 BLOCK。项目把异步命令用于通知、统计等旁路工作，不合并它们的决策结果。
>
> 若一个规则必须阻断，就必须配置成同步 Hook，并给出合理超时。把安全检查设为异步等于没有检查。

## 116. Hook 超时后如何降级？

### 面试时可以这样答

> 降级取决于事件。`PermissionRequest` 超时返回 ASK，交给人工，不会自动允许。Stop 超时只有在 `blockOnError` 为 true 时阻断，否则继续。其他事件默认继续并记录诊断。
>
> 这种按事件处理比统一失败开放或失败关闭更实际。权限事件优先安全，通知类事件不能因为脚本故障拖死主会话。

## 117. `blockOnError` 有什么作用？

### 面试时可以这样答

> 它主要影响 Stop Hook。命令非零退出、超时或执行失败时，开启后把结果视为 BLOCK，要求 Agent 继续或最终因重试上限停止；关闭时只记录诊断，允许完成。
>
> 这个选项适合区分强制质量门禁和尽力检查。格式检查可以强制，非关键统计脚本不应阻止用户得到结果。

## 118. Hook 如何解析命令输出？

### 面试时可以这样答

> stdout 若是 JSON 对象，dispatcher 读取 `decision`、兼容的 `continue`、附加上下文和更新输入。若不是合法 JSON，非空文本作为附加上下文并限制长度。退出码还会按事件转换成默认决策。
>
> 决策优先级中 BLOCK 最高。解析失败不能把任意文本当 ALLOW，未知值应回到 CONTINUE 或安全降级。

## 119. `updatedInput` 为什么需要类型安全回退？

### 面试时可以这样答

> Hook 可以改工具参数，但外部脚本可能返回错误类型。`HookedToolInput` 按 String、Int、Long、Boolean 和字符串数组分别读取，类型不匹配就使用模型原始参数，不做危险的强制转换。
>
> 这能防止一个坏 Hook 把 `limit` 改成对象导致工具崩溃。工具自身仍要做范围校验，因为类型正确不代表值合理。

## 120. `additionalContext` 会流向哪里？

### 面试时可以这样答

> Prompt Hook 的附加上下文进入本轮用户输入；工具前置 Hook 的上下文会附加到工具返回文本，让模型在观察结果时看到规则说明；Stop Hook 的上下文进入下一轮继续 prompt。
>
> 上下文来源要有明确标记，避免模型把 Hook 文本误认为用户原话。还要限制长度，否则脚本输出可能迅速挤占上下文窗口。

## 121. 为什么 Hook 规则按轮冻结，后台任务按会话持有？

### 面试时可以这样答

> 每轮开始时读取最新规则，运行中不热替换，保证同一轮决策一致。异步 Hook 却可能在本轮结束后继续，因此由 session 级 `AgentHookLifetime` 持有。下一轮可以使用新 dispatcher，但仍绑定同一个 lifetime。
>
> 会话关闭时 lifetime 统一取消后台任务。这样配置更新不会丢掉旧任务的所有权，也不会让它们永久游离。

## 122. 资源来源为什么需要明确优先级？

### 面试时可以这样答

> 项目资源可能来自项目配置、项目自动发现、用户配置、用户自动发现、扩展包和内建项。枚举顺序定义同名资源的首项胜出顺序，冲突项生成诊断而不是依赖文件系统遍历顺序。
>
> 明确优先级让用户能预测哪个 prompt、Skill 或命令生效。没有确定规则，同一项目在不同机器上可能加载不同资源。

## 123. 为什么项目 Skills 和 prompts 受 `projectTrusted` 控制？

### 面试时可以这样答

> 打开陌生仓库不应自动启用其中的可执行扩展或引导模型采取动作。加载请求只有在 `projectTrusted=true` 时才让项目 Skills、prompts 和扩展包参与发现。用户级资源则由用户自己安装，可以始终加载。
>
> AGENTS 或 CLAUDE 上下文仍按目录规则读取，因此它们应被视为指令文本，不等同于获得执行权限。真正的命令和 MCP 能力还要经过各自的信任与审批层。

## 124. Skill 如何进入模型上下文？

### 面试时可以这样答

> 资源加载器解析 Skill 的名称、描述、位置、正文、来源和 `disableModelInvocation`。构建运行时资源时，只把允许模型调用的 Skill 以名称、描述和位置列表加入 system prompt 附录，不把所有正文一次塞进上下文。
>
> 这是一种渐进加载。模型先知道有哪些 Skill，需要时再读取对应内容。禁用模型调用的 Skill 仍可供用户通过界面或命令显式使用。

## 125. `/` 命令如何发现并处理冲突？

### 面试时可以这样答

> 命令列表先注册内建 `/reload`，再按资源根优先级和稳定字典序读取 prompts 目录的直接子级 Markdown，最后为 Skills 生成 `/skill:<name>`。名称必须匹配限定格式，空模板会被跳过。
>
> 注册使用首项胜出。同名 prompt、Skill 或内建命令不会被后加载项覆盖，而是产生带路径的 warning。`/reload` 用于手动生成新资源快照，已经开始的运行仍使用旧版本。

## 源码索引

- `shared/src/commonMain/kotlin/com/agent/shared/settings/model/AgentHookSettings.kt`
- `shared/src/jvmMain/kotlin/com/agent/shared/agent/hook/WindowsAgentHookDispatcher.kt`
- `shared/src/jvmMain/kotlin/com/agent/shared/tool/runtime/AgentHookToolInterceptor.kt`
- `shared/src/jvmMain/kotlin/com/agent/shared/agent/koog/KoogAgentGateway.kt`
- `shared/src/jvmMain/kotlin/com/agent/shared/agent/koog/KoogHookRequestPolicy.kt`
- `shared/src/jvmMain/kotlin/com/agent/shared/agent/resource/AgentResourceModels.kt`
- `shared/src/jvmMain/kotlin/com/agent/shared/agent/resource/PromptCommandDiscovery.kt`

