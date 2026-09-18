---
tags: [面试, Kotlin, Coroutines, Compose]
question_range: 226-250
status: 已完成
---

# Kotlin 协程与 Compose Desktop（226-250）

## 226. 协程与线程是什么关系？

### 面试时可以这样答

> 协程是可挂起的任务，线程是操作系统调度的执行资源。多个协程可以复用少量线程，挂起时不占住线程；但协程中的阻塞调用仍会阻塞当前线程。Dispatcher 决定协程在哪些线程上执行。
>
> JDBC 和传统进程等待属于阻塞工作，应切到 IO 或用 `runInterruptible`。把函数标成 suspend 不会自动变成非阻塞。

## 227. 什么是结构化并发？

### 面试时可以这样答

> 子协程属于明确的 CoroutineScope，父任务会等待子任务，取消和异常沿 Job 层级传播。函数不会在返回后留下无主后台工作。这样资源生命周期能跟业务操作对齐。
>
> 项目用 channelFlow 管理一次 Agent 运行，用 session lifetime 管理异步 Hook。需要比一次调用活得更久的任务，也要交给更高层拥有，而不是 `GlobalScope.launch`。

## 228. `launch` 与 `async` 有什么区别？

### 面试时可以这样答

> `launch` 返回 Job，适合只关心完成与取消的任务；`async` 返回 Deferred，调用 `await` 取得结果并传播异常。async 若从不 await，异常和资源所有权容易变得含糊。
>
> 并发请求只有相互独立且总耗时值得优化时才用 async。顺序有依赖的步骤强行并发会制造竞态。

## 229. `coroutineScope` 与 `supervisorScope` 有什么区别？

### 面试时可以这样答

> coroutineScope 中一个子任务失败会取消其他子任务并把异常抛给父级。supervisorScope 隔离兄弟失败，一个失败不自动取消其他任务，但调用方仍要逐个处理错误。
>
> Agent 主执行链通常需要共同成败；独立的通知或多个互不依赖的诊断连接可以考虑 supervisor。隔离失败不等于忽略失败。

## 230. `SupervisorJob` 为什么适合应用级后台任务？

### 面试时可以这样答

> 应用级 scope 可能同时管理多个会话收尾。某个 SessionEnd Hook 失败，不应取消其他会话的清理，因此网关生命周期使用 SupervisorJob。应用退出时仍统一 cancel。
>
> SupervisorJob 只改变子任务失败传播，未处理异常仍需日志或 handler。它不是“永不失败”的 Job。

## 231. suspend 函数为什么不代表后台线程？

### 面试时可以这样答

> suspend 只表示函数可以挂起并稍后恢复，代码仍在当前 coroutine context 运行。若在 UI Dispatcher 里调用阻塞 JDBC，即使函数签名是 suspend，界面还是会卡。
>
> 需要用 `withContext(Dispatchers.IO)` 显式隔离阻塞 I/O。CPU 密集渲染可用 Default，UI 状态更新回到 UI context。

## 232. 协程取消为什么是协作式的？

### 面试时可以这样答

> 取消会把 Job 标记为 cancelling，挂起函数通常检查并抛 CancellationException。持续 CPU 循环或阻塞 API 若不检查，就不会立即停止。代码可调用 `ensureActive`、`yield`，或把取消函数传入底层循环。
>
> 项目的进程运行器每 50ms 查询取消状态，Hook 执行后也调用 `ensureActive`，让取消穿过阻塞边界。

## 233. `CancellationException` 为什么通常不记录成错误？

### 面试时可以这样答

> 它表达调用方不再需要结果，常见于用户停止、Compose effect key 变化或 debounce 替换旧任务。把它当故障弹窗会制造噪音，吞掉它又会让任务继续。
>
> 正确做法是在 finally 清理资源，然后重新抛出。只有业务明确把取消转换成状态时，才在边界处理。

## 234. Flow 是冷流是什么意思？

### 面试时可以这样答

> 普通 Flow 的代码在每个 collector 开始收集时执行，每次收集都是独立运行。若 Agent 的 `run()` Flow 被两个地方收集，可能启动两次模型请求和工具执行。
>
> 因此 UI 应有唯一收集者，再把状态投影共享。若确实需要多订阅，使用 shareIn 或 StateFlow，并明确启动策略和 replay。

## 235. StateFlow 与普通 Flow 有什么区别？

### 面试时可以这样答

> StateFlow 始终有当前值，新订阅者立即收到最新状态，相同值会合并，适合 UI 状态。普通 Flow 更适合按顺序发生的事件。工具开始、日志增量这类一次性事件若只放 StateFlow，快速连续更新可能被覆盖。
>
> 项目可以用事件 Flow 驱动 reducer，再把归约后的 Chat 状态放 StateFlow。

## 236. Channel 与 Flow 如何分工？

### 面试时可以这样答

> Channel 是多生产者与消费者之间的队列，发送就发生；Flow 是声明式异步序列，强调收集。网关内部用 Channel 汇聚工具线程与 Agent 协程事件，对外暴露 Flow，隐藏队列细节。
>
> Channel 关闭和消费所有权要明确。多个消费者会分摊消息，而不是每人都收到一份。

## 237. 什么是背压？

### 面试时可以这样答

> 当生产事件速度高于消费速度，系统必须决定让生产者等待、缓存、合并还是丢弃。无限缓存最终会占满内存；完全阻塞又可能拖慢模型或子进程读取。
>
> 项目使用容量 64 的事件队列。正文可按帧合并，stdout 可批量刷新，但终态、审批和 diff 不能丢。容量和合并周期应通过峰值事件速率与 UI 消费耗时验证，并记录丢弃或等待指标。

## 238. Mutex 与 `synchronized` 怎么选？

### 面试时可以这样答

> Mutex 的 `withLock` 可以挂起等待，不阻塞线程，适合协程间保护状态；synchronized 阻塞线程，适合很短的 JVM 临界区。Mutex 不是可重入锁，同一协程重复获取会挂住。
>
> 持锁期间不要做长时间网络调用。持久化协调器串行完整保存是有意选择，若写入变慢应调整保存粒度，而不是扩大临界区。

## 239. Compose 的重组是什么？

### 面试时可以这样答

> Composable 读取的 State 变化后，Compose 重新执行受影响的组合代码，计算新的 UI。重组不是重绘整棵窗口，也不保证只执行一次，因此 Composable 主体必须尽量无副作用。
>
> 网络请求、数据库写和启动浏览器不能直接放在组合主体，应使用 effect 或状态持有层。

## 240. `remember` 保存的状态能跨应用重启吗？

### 面试时可以这样答

> 不能。remember 只在当前 composition 中保留对象，key 变化或组件离开组合后可能丢失。桌面应用进程结束后也不会保存。
>
> 图表组件用 remember 保存显示模式和缩放，任务历史则由 SQLite 保存。UI 临时状态与业务持久化状态要分开。

## 241. `remember` 的 key 为什么重要？

### 面试时可以这样答

> key 决定旧值是否可以复用。图表预览以 kind、source 和主题作为 key，源码或明暗主题变化时清空旧 SVG 和缩放状态。如果漏掉 source，组件可能显示上一段图表；key 过多则会无意义重建。
>
> key 应包含初始化值真正依赖的输入，而不是把所有参数都塞进去。

## 242. `LaunchedEffect` 的生命周期是什么？

### 面试时可以这样答

> 组件进入组合时启动协程，任一 key 变化时取消旧协程并启动新协程，离开组合时取消。适合与当前 UI 实例绑定的异步工作。
>
> 项目用它渲染图表。捕获 CancellationException 后重新抛出，避免旧源码渲染完成后覆盖新源码结果。若回调对象可能变化但不希望重启 effect，可用 `rememberUpdatedState` 保持最新引用。

## 243. `rememberCoroutineScope` 适合什么场景？

### 面试时可以这样答

> 它返回与当前 composition 生命周期绑定的 scope，常在点击事件中启动动画、保存或弹窗工作。与 LaunchedEffect 不同，它由用户事件触发，不会因 key 自动重启。
>
> 长期 Agent run 若要跨页面存在，应由 ViewModel 或窗口状态层持有，不应绑在一个按钮 Composable 上。

## 244. Compose 中如何避免过度重组？

### 面试时可以这样答

> 缩小状态读取范围，使用稳定不可变参数，对可推导值使用 `derivedStateOf`，列表提供稳定 key。不要每次重组都创建大型解析器或把整个应用状态传给所有子组件。
>
> 先用 profiler 或重组计数定位问题。为了“稳定”到处包 remember，可能缓存过期值并增加复杂度。

## 245. 为什么 UI 状态适合不可变 copy 更新？

### 面试时可以这样答

> 新对象能让 StateFlow 和 Compose 明确感知变化，也便于 reducer 测试和历史快照。data class 的 copy 让更新局部字段简单。
>
> 内部若仍共享 MutableList，表面 copy 并没有真正隔离状态。列表也应创建新实例，或使用持久化不可变集合。

## 246. Compose Desktop 与 Swing 如何互操作？

### 面试时可以这样答

> Compose Desktop 运行在 JVM 桌面环境，可以通过 SwingPanel 嵌入 Swing/AWT 组件，也能在窗口层访问原生能力。互操作时要处理 EDT 与 Compose 线程、焦点、缩放和组件销毁。
>
> JCEF 属于重量级浏览器组件。Mulehang 没把它直接作为聊天内容长期嵌入，而是后台生成 SVG，降低层级和焦点问题。

## 247. 为什么桌面应用要关心 UI 线程？

### 面试时可以这样答

> 状态更新和窗口组件操作通常要求在 UI 线程，阻塞数据库、模型网络和图表生成会造成卡顿。项目把 JDBC 放 IO，把 PlantUML 渲染放 Default，结果返回后更新 Compose State。
>
> 线程切换不是越多越好。纯状态转换保持在当前协程即可，只有明确阻塞或 CPU 密集任务才切 dispatcher。

## 248. 为什么渲染失败要回退源码而不是只显示错误？

### 面试时可以这样答

> Mermaid 语法错误、JCEF 缺失或 SVG 处理失败都不应让消息内容消失。源码是用户原始信息，回退后仍可复制和修复。错误提示说明失败类型，避免空白框让用户误以为没有内容。
>
> 这是渐进增强。渲染成功提供图形，失败时核心文本仍可用。回退内容还应保留复制入口和简短错误原因，同时把详细堆栈留在诊断日志而非展示给普通用户。

## 249. Compose Desktop 应如何测试？

### 面试时可以这样答

> 业务状态和 reducer 用普通单元测试。Composable 用 `createComposeRule` 设置真实内容，通过 semantics tag 查找节点、点击并断言状态。窗口、JCEF 和打包资源再用少量集成测试覆盖。
>
> 不要把所有验证都变成截图像素比较。语义测试更稳定，视觉回归只覆盖确实关心布局的页面。

## 250. 如何排查桌面应用“界面卡住”？

### 面试时可以这样答

> 先抓线程栈，看 UI 线程是在 JDBC、Process.waitFor、锁还是渲染中阻塞；再看协程调度和事件队列是否积压。若只有图表卡，检查 JCEF helper、页面握手和超时。
>
> 修复要移走阻塞工作或缩短临界区，而不是简单加 loading。loading 只能解释等待，不能解除 UI 线程阻塞。

## 参考资料

- [Kotlin 协程概览](https://github.com/JetBrains/kotlin-web-site/blob/master/docs/topics/coroutines-overview.md)
- [Compose Multiplatform](https://github.com/JetBrains/compose-multiplatform)
