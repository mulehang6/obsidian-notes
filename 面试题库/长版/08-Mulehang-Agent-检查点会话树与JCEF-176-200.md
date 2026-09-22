---
tags: [面试, Checkpoint, Session-Tree, JCEF]
question_range: 176-200
status: 已完成
---

# Mulehang Agent：检查点、会话树与 JCEF（176-200）

> [!warning] 当前实现边界
> 当前源码已核实：Session Tree 已经落地，但它是“外层会话父子树 + 会话内条目树”的内容与路径管理，不是 Koog 图级 Agent Checkpoint。SQLite 可以恢复任务快照、活动 leaf/head 和完整条目图；应用重启仍不能从 Koog 图节点、在途请求、工具进程或审批 continuation 处安全续跑。176–190 要把已实现部分、仍未实现的 Checkpoint 边界和工作区副作用边界分开说，不能把三者混成一个功能。

## 176. 当前任务持久化等于 Agent Checkpoint 吗？

### 面试时可以这样答

> 不等于。当前 SQLite 保存的不只是 UI 时间线、模型历史和会话偏好，还包括外层任务父子关系、fork 来源、归档状态、活动条目、持久 head、树格式版本和 `task_entry` 完整条目图；Mapper 会按活动 leaf 重建时间线、模型 history 和路径配置，应用重启后可以恢复会话内容与分支位置。但它没有保存 Koog 当前图节点、节点执行上下文、在途工具请求、审批 continuation 或可重建的外部副作用记录，运行中状态重启后会被降级成“执行已中断”。
>
> 真正 Checkpoint 要支持从确定节点恢复，并保证已经发生的副作用不会重复。当前实现更准确的名称是“任务快照 + Session Tree 持久化”：它解决内容和分支路径恢复，不等于 Agent 执行续跑。

## 177. 真正的 Agent Checkpoint 应保存什么？

### 面试时可以这样答

> 若要做真正的 Agent Checkpoint，至少保存 graph 与 schema 版本、当前节点、共享状态、完整消息历史、迭代计数、资源快照版本、待处理工具调用、审批状态和幂等标识。还要记录模型与 Profile，因为换模型后继续可能改变状态解释。当前项目已经保存 Profile、权限、推理档位、任务状态、timeline/history 和条目图，但还没有把 Koog 图节点与 continuation 变成可恢复数据。
>
> 不需要盲目序列化整个运行时对象。网络连接、协程和进程句柄无法可靠恢复，应保存能够重建它们的业务数据；当前实现选择在重启后把运行中任务标记为中断，而不是伪装成可继续运行。

## 178. Checkpoint 应该在什么时候创建？

### 面试时可以这样答

> 对真正 Checkpoint，最稳妥的边界是节点完成且状态一致之后。模型节点结束、工具结果写回、人工审批完成都可以形成检查点。当前项目没有按 Koog 节点创建这种检查点，而是由 `TaskPersistenceCoordinator` 以 300ms debounce 保存任务快照；切换分支时若选择摘要，还会把摘要作为 `BranchSummary` 条目追加到目标路径。
>
> 每个 token 都保存成本太高；只在任务结束保存又没有恢复价值。未来若加入图级续跑，应围绕副作用边界和可重放节点选择时机，并保留关闭前 `flush` 这类立即落盘路径。

## 179. 为什么工具副作用让恢复变难？

### 面试时可以这样答

> 崩溃可能发生在文件已经写入、但工具结果还没写入检查点的瞬间。恢复后若重新执行，补丁可能应用两次；若直接跳过，又不知道第一次是否成功。这是典型的“副作用已发生，记录未提交”问题。
>
> 可用幂等键、执行日志、结果校验和人工确认处理。数据库事务无法覆盖外部文件和远程系统，不能声称一次本地事务解决全部一致性。

## 180. 如何给工具调用设计幂等性？

### 面试时可以这样答

> 每次工具调用生成稳定 callId，执行前记录意图和输入摘要，完成后记录结果。当前条目模型会保存工具调用的 `toolCallId`、参数预览、结果和结构化 diff，并可随任务快照恢复；但这主要保证历史配对和展示，仓库没有独立的“已执行 callId”幂等账本。真正恢复时仍要先查询 callId 是否有完成记录，并验证目标状态。文件补丁还可以记录修改前后摘要，只有当前文件仍匹配预期时才重放。
>
> 命令执行通常无法天然幂等。对未知副作用命令，恢复时应请求用户决定，而不是因为 Session Tree 中存在同一条历史就自动重跑。

## 181. Checkpoint 与事件溯源有什么区别？

### 面试时可以这样答

> Checkpoint 保存某一时刻的完整状态，恢复快，但不一定解释状态如何形成。事件溯源保存连续事件，通过重放构建状态，审计强但迁移和重放复杂。实际系统常用事件记录过程，定期 checkpoint 缩短恢复时间。
>
> 当前实现的 `task_timeline_item`、`task_history_item` 和 `task_entry` 是三种用途不同的持久化负载：条目图是 Session Tree 的稳定事实，timeline/history 是活动路径投影和模型上下文。它们不是严格事件溯源，也没有承诺能仅靠事件重建 Koog 执行状态。

## 182. Checkpoint 的 schema 如何升级？

### 面试时可以这样答

> 检查点必须带 schemaVersion 和执行引擎版本。当前 SQLite 已有 v1 到 v6 迁移：v5 增加外层会话树字段和 `task_entry`，v6 增加 `head_entry_id` 并从 active leaf 回填；迁移前会做 WAL checkpoint 和备份，测试覆盖 v1、v4、v5 旧库。这个 schema 兼容解决的是任务与会话内容，不是执行引擎节点迁移。
>
> 若继续实现图级 Checkpoint，仍需为 graph/schema/引擎版本建立独立迁移；无法迁移的旧 checkpoint 应保留为可查看历史，而不是强行续跑。恢复逻辑应使用旧样本做兼容测试，只测试新版本自己写自己读无法证明升级安全。

## 183. 为什么恢复时要校验资源快照？

### 面试时可以这样答

> 原运行可能使用旧 prompt、Skill 和 MCP 工具。若恢复时直接换成新资源，同一个 graph state 会在另一套规则下继续。当前项目在一次运行中冻结资源快照，并在任务上保存 Profile、权限和推理档位，但没有保存一份足以重建 Koog continuation 的完整资源版本校验；因此重启选择恢复内容而不是继续原图。真正续跑时至少要比较资源版本，并让用户选择使用可重建的旧配置还是从当前节点之前重新开始。
>
> 密钥不能原样写进 checkpoint。保存服务引用，恢复时从安全配置重新解析。

## 184. 什么是 Session Tree？

### 面试时可以这样答

> 当前项目已经实现了 Session Tree，而且分成两层。外层 `ChatConversationUiState.parentConversationId` 把 fork/clone 产生的任务组织成会话父子树；内层 `ConversationEntry` 为每条用户/助手消息、推理块、工具调用与结果、问答、摘要、标签和模型设置保存 `id`、`parentId`、`createdAt`。活动 leaf 的祖先路径投影成 UI 时间线和 Agent history，兄弟分支仍保留在完整条目图中。
>
> 控制器已支持从用户消息 fork、克隆当前 leaf 路径、从用户消息编辑并在重新发送后形成兄弟分支、切换任意 leaf、回到持久 head，以及离开路径时选择自动/自定义摘要。`ChatScreen` 已接入右侧 `ConversationTreePanel`：可在“会话内分支”和“全部条目”之间切换，支持搜索、筛选、折叠、标签、键盘导航和分支切换。外层森林也有 `buildConversationForest` 与树节点渲染器；但当前默认 `TaskSidebar` 仍走平铺任务列表，因此更准确的说法是“右侧条目树 UI 和树数据模型已实现”，不能夸大为左侧默认侧栏已经完整展开父子树。这里的“恢复”是内容和活动路径恢复，不是从 Koog 图节点继续执行。

## 185. 为什么 Agent 比普通聊天更需要分支？

### 面试时可以这样答

> Agent 会修改环境。用户可能想回到“第一次补丁应用前”，尝试另一种方案，同时保留原路线供比较。当前控制器可以把活动 leaf 切到历史分支、保留旧条目并在需要时把离开路径摘要注入新路径；线性撤销会丢掉后续记录，树结构能保存多个尝试。
>
> 但分支对话不等于工作区也自动分支。当前 fork/clone 仍绑定同一个 `workspacePath`，没有自动创建 Git worktree、文件快照或独立沙箱；若文件已经变化，仍需要外部工作区隔离和副作用治理。

## 186. Session Tree 的数据模型怎么设计？

### 面试时可以这样答

> 当前实现用 `task` 保存任务元数据、外层 `parent_conversation_id`/`forked_from_entry_id`、`active_entry_id`/`head_entry_id` 和归档状态，用 `task_entry` 保存 `id`、`parent_id`、`created_at`、`type` 与 `payload_json`。工具调用与结果是可编码的条目类型；加载时从 active leaf 沿 parent 链读取祖先，再投影出 timeline、history、profile 和 reasoning effort。
>
> 条目表用 taskId + entryId 保证任务内标识唯一，并建立 parent 索引；路径读取与森林/扁平树展示对缺失父节点、孤儿和环路做保护。外层删除不会级联删除后代，而是把直接子会话提升为根；归档则级联整个会话子树，恢复只作用于所选节点。数据库层仍未把 entry parent 做成跨行外键，损坏数据的安全降级依赖读取代码。

## 187. 分支创建时哪些数据可以共享？

### 面试时可以这样答

> 同一会话内的分支共享逻辑祖先：每个条目只存 `parentId`，兄弟节点共存，活动路径按需投影，避免把兄弟混入上下文。fork/clone 生成独立会话时，当前实现会复制目标祖先路径并为条目生成新 ID，同时重写摘要和标签的内部引用；用户输入片段与附件快照随路径复制。模型 Profile、权限和推理档位也在会话快照中保留。
>
> 文件系统副作用不能因为消息祖先共享就视为共享。当前派生会话沿用源 `workspacePath`，没有按分支绑定工作区状态，因此同一目录上的修改仍需用户或未来的 worktree/沙箱策略负责隔离。

## 188. 如何让 Session Tree 与 Git 配合？

### 面试时可以这样答

> 代码任务可以让重要分支绑定 Git commit 或 worktree。创建对话分支时，从记录的基线提交创建独立工作区，工具只操作该目录。合并时通过正常 Git diff 和冲突处理回主线；这是当前 Session Tree 需要配合的设计，不是 Mulehang Agent 已完成的分支工作区集成。
>
> 这比复制整个目录节省空间，但未提交文件、外部生成物和数据库状态仍要单独处理。不能把 Git 当成所有工具副作用的事务系统。

## 189. 会话树如何避免上下文无限增长？

### 面试时可以这样答

> 当前投影函数只取活动 leaf 到根的祖先链，不把兄弟分支送进模型。会话树导航离开旧路径时可以生成自动或自定义摘要，摘要以 `BranchSummary` 条目写回目标路径；原始条目图仍保留，摘要记录来源 leaf、覆盖条数、指令和 token 统计。摘要输入按单条 8,000 字符、总计 60,000 字符截断。
>
> 摘要不是无损压缩。当前摘要生成失败、返回空文本或被取消时不会提交 leaf 变化；但它仍不替代完整 Checkpoint，也不隔离文件副作用。关键工具结果、约束和未完成事项应结构化保留，恢复时还要校验摘要对应的节点范围，避免分支切换后误用其他路径的上下文。

## 190. 如何测试 Session Tree？

### 面试时可以这样答

> 当前测试已经覆盖条目路径投影只包含祖先、工具调用/结果配对、标签不进入模型上下文、单路径复制与引用重写；`ConversationTreeControllerTest` 覆盖 fork、clone、用户编辑后形成兄弟、精确 leaf 切换、回到 head、自动/自定义摘要、摘要失败/取消/并发互斥、归档/恢复/删除；Mapper 和 SQLite 测试覆盖完整条目图往返、迁移与 head 回填；森林和 UI 测试覆盖孤儿提升、子树排序、分支压缩、筛选、折叠、搜索和缩进上限。
>
> 仍未覆盖的是 Koog 图级断点续跑、在途工具/审批 continuation、真实外部副作用幂等，以及分支绑定 worktree 后的文件隔离和清理失败；这些属于下一阶段，而不是现有测试已经证明的能力。

## 191. 项目中的 JCEF 用来做什么？

### 面试时可以这样答

> 当前 JCEF 用作不可见的 Mermaid 后台工作器。它加载本地 HTML 和打包的 Mermaid JavaScript，把 Markdown 中的 Mermaid 源码渲染为 SVG。最终展示仍由 Compose 的 SVG 画布完成，不是把整个聊天界面放进浏览器。
>
> PlantUML 走本地 JVM 渲染路径，因此两种图表最后统一成 SVG，但生成方式不同。

## 192. 为什么不用远程 Mermaid 服务？

### 面试时可以这样答

> 图表源码可能包含项目架构、类名和业务流程。发给在线服务会产生隐私和网络依赖。项目打包 Mermaid 运行时，用本地 JCEF 离线渲染，断网也能工作。
>
> 代价是安装包更大，需要指定带 JCEF 的 JBR，并处理浏览器初始化、页面握手和超时。渲染进程还应禁止任意外网导航和本地文件读取，避免图表源码变成新的攻击入口。

## 193. 如何阻止 JCEF 偷跑外部请求？

### 面试时可以这样答

> `DiagramBrowserResourcePolicy` 在导航和资源加载两个阶段拦截请求，只允许 `about:blank` 和指定图表资源目录内的 file URL。新标签打开一律阻止。目录解析失败时拒绝所有请求。
>
> Chromium 启动参数还关闭后台网络、组件更新、同步和 ping。参数是补充，真正的资源白名单仍由请求处理器执行。

## 194. file URL 白名单如何防目录穿越？

### 面试时可以这样答

> 代码解析 URI，拒绝非 file scheme，去掉 query 和 fragment，再把路径转成绝对规范化 Path，最后检查是否 `startsWith` 规范化资源根目录。这样 `..` 会在比较前被折叠。
>
> Windows 下还要关注大小写、符号链接和 URI 编码。高安全场景可以解析 real path 后再比较，防止目录内符号链接指向外部。

## 195. 为什么开发环境和安装包要用两套资源定位？

### 面试时可以这样答

> 安装包通过 Compose 的 resources directory 系统属性定位；开发运行则从 classpath 的 file URL 回退。两条路径都要检查 worker HTML 与 `mermaid.min.js` 是否完整存在。
>
> 资源缺失时返回 null，策略随后拒绝请求并让 UI 回退源码，而不是尝试从 CDN 补下载。

## 196. JCEF worker 为什么带 generation 和 requestId？

### 面试时可以这样答

> 浏览器可能因超时或崩溃重建。generation 区分旧会话和新会话，requestId 区分同一会话内的渲染请求。迟到的旧回包不能完成新请求，否则用户会看到与当前源码不对应的 SVG。
>
> `CompletableDeferred` 让调用协程等待指定请求，同时能在浏览器失败时统一结束 ready 等待和活动请求。

## 197. 哪些错误会触发 JCEF worker 重建？

### 面试时可以这样答

> 当前只把 JCEF 初始化、页面加载、浏览器会话和超时视为 worker 级故障。普通 Mermaid 语法错误属于输入问题，重建浏览器没有意义，应直接回退并展示源码。
>
> 区分基础设施错误与内容错误可以避免坏图表反复重启 Chromium，造成卡顿和资源泄漏。

## 198. 图表预览的 UI 状态有哪些？

### 面试时可以这样答

> `DiagramPreviewState` 区分 PlantUML 生成中、Mermaid 生成中、Ready 和 Failed。源码、主题或显示模式变化时，`LaunchedEffect` 重新渲染。取消必须继续抛出，其他异常转换为带类型的失败。
>
> 失败后保留原始代码块和提示，用户仍能复制、修改或判断语法问题，不会只看到空白区域。

## 199. 为什么最终用 Compose 渲染 SVG？

### 面试时可以这样答

> JCEF 只负责执行 Mermaid JavaScript。拿到 SVG 后交回 Compose，可以统一主题、缩放、工具栏和布局，也减少长期显示浏览器组件带来的焦点和层级问题。
>
> SVG 仍是不可信输入。渲染前应限制外部引用、脚本和危险元素，不能因为它来自本地 worker 就跳过内容安全检查。

## 200. 如何测试离线图表链路？

### 面试时可以这样答

> 纯单元测试覆盖 URL 白名单、路径规范化、资源目录选择、缩放范围和失败分类。集成测试用打包资源启动 worker，验证合法 Mermaid 返回 SVG、外部 HTTP 被拦截、语法错误回退源码、超时后 generation 更新。
>
> 打包测试同样重要。开发 classpath 成功不代表安装包包含 worker HTML、Mermaid JS 和正确 JCEF helper。

## 源码索引

- `desktopApp/src/main/kotlin/com/agent/app/chat/component/DiagramBrowserResourcePolicy.kt`
- `desktopApp/src/main/kotlin/com/agent/app/chat/component/MermaidSvgRenderer.kt`
- `desktopApp/src/main/kotlin/com/agent/app/chat/component/MermaidWorkerSupport.kt`
- `desktopApp/src/main/kotlin/com/agent/app/chat/component/AssistantDiagramPreview.kt`
- `shared/src/jvmMain/kotlin/com/agent/shared/chat/persistence/SqliteTaskRepository.kt`
