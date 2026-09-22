---
tags: [面试, AI-Agent, LLM, Provider]
question_range: 126-150
status: 已完成
---

# Mulehang Agent：模型配置与提供商适配（126-150）

## 126. `ConfigProfile` 为什么不是简单的模型名加 API Key？

### 面试时可以这样答

> 一次模型调用还依赖协议类型、base URL、模型限制、推理档位、视觉能力、扩展请求头、请求体覆盖和迭代上限。`ConfigProfile` 保存的是用户级、项目级和环境覆盖合并后的最终配置，Agent 运行只读取这个结果，不在调用现场重新猜优先级。
>
> 把配置先解析成稳定对象，也方便在启动前校验。API Key 属于敏感值，不能出现在普通日志、事件或快照展示中。

## 127. `providerId`、`providerType` 和 `model` 有什么区别？

### 面试时可以这样答

> `providerId` 标识一组用户配置，例如某个官方服务或兼容中转站；`providerType` 决定使用哪套请求协议；`model` 是真正发给服务端的模型 ID。同一种 OpenAI-compatible 协议可以对应多个服务商和模型，所以三者不能合成一个枚举。
>
> UI 标签也与请求 ID 分开。改显示名称不应改变网络协议或模型字符串。

## 128. 当前项目真正支持哪些模型协议？

### 面试时可以这样答

> `ProviderType` 枚举列出 OpenAI Responses、OpenAI Chat Completions、Anthropic 和 Google。但当前 `buildLlmModel`、`buildPromptParams` 与 `buildPromptExecutor` 只实现前三种，Google 会抛出“暂不支持”。
>
> 面试时应说“配置模型预留了 Google 类型，当前桌面执行链尚未接入”，不能看到枚举值就宣称已经支持。判断功能是否落地，要沿创建客户端和请求参数的路径核实。

## 129. Responses API 与 Chat Completions 为什么要分开？

### 面试时可以这样答

> 两者虽然都可能来自 OpenAI-compatible 服务，但端点、请求体和工具历史格式不同。项目给 LLModel 添加不同 endpoint capability，Prompt 参数也分别使用 `OpenAIResponsesParams` 与 `OpenAIChatParams`。
>
> 推理档位的字段同样不同。Responses 使用 `reasoning.effort`，Chat Completions 使用 `reasoning_effort`。若只换 URL 不换协议类型，服务端可能接受连接却拒绝请求体。

## 130. 为什么 `baseUrl` 不自动追加 `/v1`？

### 面试时可以这样答

> 兼容服务对 base URL 的约定不一致，有的配置已经包含 `/v1`，有的使用自定义根路径。客户端若擅自追加，容易得到重复路径或破坏中转站路由。
>
> 当前代码只移除末尾斜杠，再使用相对的 `chat/completions`、`responses` 等路径。版本前缀由配置负责。这种规则简单，但设置页必须给出示例并在测试连接时显示最终请求地址。

## 131. `LLModel.capabilities` 有什么用？

### 面试时可以这样答

> Koog 根据 capability 判断模型能否完成工具调用、结构化 JSON、思考或图片输入。项目始终声明 Completion、Tools、ToolChoice 和两级 JSON Schema；配置存在推理档位时增加 Thinking；确认支持图片时增加 Vision。
>
> capability 不是服务端能力探测结果，它来自配置和内建规则。声明过多会让框架发送服务端不支持的内容，声明过少则让已有能力无法使用，因此需要按模型验证。

## 132. 图片能力为什么使用 nullable Boolean？

### 面试时可以这样答

> `true` 表示用户或配置明确声明支持，`false` 表示明确不支持，`null` 表示没有声明，由运行时内建模型规则保守判断。若只用 Boolean，就无法区分“明确关闭”和“旧配置尚未填写”。
>
> 保守判断能避免向纯文本模型发送图片。长期看，最好通过模型元数据或实际能力测试减少硬编码名单。

## 133. 模型输入输出上限如何进入请求？

### 面试时可以这样答

> `ConfigProfile.limit` 保存模型限制，输出上限映射到不同 Provider 参数的 `maxTokens`。输入限制更多用于上层历史管理和附件校验，因为服务端请求字段通常只控制输出。
>
> 配置上限不能保证请求一定成功。系统 prompt、历史、工具 schema 和本轮输入都会占上下文，需要在发送前估算并为输出预留空间。

## 134. 推理档位为什么不能直接使用 Koog 的标准枚举？

### 面试时可以这样答

> 不同兼容服务支持的档位和字段可能超出 Koog 当前枚举。项目把 `ReasoningEffort.wireValue` 作为原始值写入 additional properties，并按 endpoint 生成对应 JSON，从而保留服务商扩展。
>
> 代价是失去一部分编译期约束，所以配置层必须限制可选档位，并用捕获请求体的测试确认字段位置。不能把任意用户字符串直接拼入请求。

## 135. 三种协议的推理字段分别是什么？

### 面试时可以这样答

> Responses 写成 `reasoning: { effort: value }`；Chat Completions 写顶层 `reasoning_effort`；Anthropic 直连写 `output_config: { effort: value }`。代码只在用户选择了推理档位时加入这些字段。
>
> 这说明“推理强度”是产品层统一概念，传输层必须按协议翻译。统一 UI 不代表请求 JSON 也统一。

## 136. 请求体覆盖的优先级是什么？

### 面试时可以这样答

> 代码先生成协议默认字段，再 deep merge Profile 的静态 `requestBody`，最后 merge 当前推理档位对应的 `reasoningBodyByEffort`。后合并的值优先，因此档位专属覆盖最高。
>
> 深合并比顶层覆盖更适合嵌套 JSON，但也可能让用户覆盖协议关键字段。设置页需要标出高级配置风险，日志只记录脱敏后的有效结构。

## 137. 为什么允许扩展请求头？

### 面试时可以这样答

> 兼容网关可能要求租户 ID、路由标签或自定义鉴权头。Profile 将合并后的 `requestHeaders` 交给 HTTP client factory，创建客户端时与框架头部组合。
>
> Header 很可能包含秘密。冲突优先级要明确，禁止把完整值写入诊断。若允许项目级配置提供 Header，还要防止陌生仓库诱导用户向外部地址发送凭据。

## 138. 为什么桌面端统一使用 JDK HttpClient 引擎？

### 面试时可以这样答

> 源码注释记录了 DeepSeek SSE 与 Apache5 HTTP/2 协商出现随机协议错误。项目显式用 Ktor 的 Java 引擎，避免 ServiceLoader 在不同机器解析到不同实现，并让 OpenAI-compatible 与 Anthropic 共享可控网络底座。
>
> 这是基于真实兼容问题的工程选择，不代表 JDK 引擎在所有场景都更快。替换引擎前应重跑流式、超时和代理环境测试。

## 139. 为什么需要过滤 SSE 的 `[DONE]`？

### 面试时可以这样答

> `[DONE]` 是部分 OpenAI-compatible 服务使用的流结束标记，不是 JSON。若直接交给 Koog 的 JSON 解码器，会产生解析异常。装饰器保留原 dataFilter，并额外排除这个标记。
>
> 过滤放在协议传输层，而不是业务事件层，因为它处理的是 wire format。上层只应看到合法 StreamFrame 和正常结束。

## 140. 为什么还过滤部分 Responses 生命周期事件？

### 面试时可以这样答

> Koog 1.1.1 不消费 `response.content_part.added` 和 `done`，却会先尝试反序列化其中的 part。某些合法类型尚未注册时会失败。项目在解码前跳过这两类元数据事件，但保留真正的文本和推理增量。
>
> 这属于明确版本下的兼容层。升级 Koog 后要重新验证，不能永久过滤未来可能需要的事件。

## 141. Anthropic 的 `signature_delta` 为什么被过滤？

### 面试时可以这样答

> 该事件承载 extended thinking 的签名元数据。当前 Koog 版本不会把它写入 reasoning frame，只产生无效警告。项目因此在传输层过滤，行为与框架实际能表达的内容保持一致。
>
> 如果未来要回放签名或 Koog 增加支持，这个过滤必须移除。兼容补丁应带版本理由和回归测试，否则很容易变成隐蔽的数据丢失。

## 142. 为什么 Anthropic 兼容端点需要自定义模型映射？

### 面试时可以这样答

> Koog 的 Anthropic client 默认只认识内建 Claude 模型，序列化前会从 `modelVersionsMap` 查找请求模型。兼容端点若使用自定义模型名，会在发网络请求前报 Unsupported model。
>
> 项目用当前 Profile 构建 LLModel，再映射回原始 model 字符串。这样仍使用 Anthropic 协议，同时允许服务端自己的模型 ID。

## 143. 为什么要有 Provider 传输适配器？

### 面试时可以这样答

> 同样标称 OpenAI-compatible 的服务，工具历史和 SSE 字段仍可能有细微差异。工厂按 Profile 选择 `KoogProviderTransportAdapter`，在请求发出前规范化 body，在 SSE 解码前规范化事件。
>
> 适配器应只修协议差异，不能偷偷改变业务 prompt。每个适配都要限定 Provider 条件，否则一个服务的兼容补丁会破坏其他服务。

## 144. 为什么每个 Profile 创建自己的 HTTP client factory？

### 面试时可以这样答

> 不同 Profile 可能有不同请求头和传输适配器。`factoryFor` 在创建时捕获这些值，使同一轮请求规则稳定。若使用一个可变全局工厂，切换设置可能让运行中的请求突然使用另一家服务的规则。
>
> 底层 Java HttpClient 可以共享，但面向 Profile 的装饰器配置应当不可变。

## 145. 快速模型 Profile 用来做什么？

### 面试时可以这样答

> 标题生成、自动审批等内部任务不需要主模型的完整推理能力，可以选择同一 provider 下配置的 faster profile，降低延迟和费用。映射按 `providerId` 查找，未配置时安全回退主 Profile。
>
> 快速模型不能接管需要完整上下文的主任务。内部任务还应使用独立 prompt、工具集和输出解析，防止权限审核变成另一个自由 Agent。

## 146. 为什么快速模型按 providerId 匹配？

### 面试时可以这样答

> 同一 provider 往往共享鉴权、网络和数据边界。按 providerId 选择快速模型，可以避免用户主任务走自建服务，内部摘要却无意发送到另一家服务。
>
> 若用户明确允许跨 provider，应把它设计成显式配置，不能只按模型价格自动切换。还要分别记录主模型与快速模型的实际选择，便于审计请求去了哪里。

## 147. Profile 的配置层有什么意义？

### 面试时可以这样答

> `layer` 记录最终配置来自用户级还是项目级等层次，便于 UI 解释值为何生效，也为冲突诊断提供依据。解析器负责合并，运行时不再遍历所有配置文件。
>
> 项目级配置适合模型名和地址，不适合直接提交密钥。秘密应由环境或安全存储覆盖，并在展示时脱敏；配置诊断只报告来源与缺失项，不能把秘密写进日志。

## 148. 为什么禁用的 Profile 仍可能保留在配置中？

### 面试时可以这样答

> `enabled` 将“配置存在”和“允许选择”分开。用户可以暂时停用某个服务而不删除地址、模型和参数。解析和 UI 可以显示诊断，但 Agent 选择器不应把禁用项用于新运行。
>
> 当前运行一旦已经取得 Profile 快照，不应因用户随后禁用而中途切换；安全紧急停用则需要单独的取消机制。

## 149. 如何测试 Provider 兼容层？

### 面试时可以这样答

> 用录制型 HTTP client 捕获最终请求体，分别断言端点、模型 ID、推理字段、Header 和工具历史顺序；再用构造的 SSE 数据验证 `[DONE]`、未知生命周期事件和正常增量。测试不需要真实 API Key，也不依赖外网。
>
> 还要覆盖错误响应、半截 JSON、取消和服务端提前断流。只测一次成功文本无法证明 Agent 工具循环可用。

## 150. 如果新增 Google Provider，你会怎么做？

### 面试时可以这样答

> 不能只在 `when` 中加一个分支。先明确使用原生 Gemini 协议还是 OpenAI-compatible 接口，再实现 LLModel provider、Prompt 参数、客户端、工具 schema、流式事件和推理字段映射。随后补请求体与 SSE 回归测试，并验证图片和工具调用。
>
> UI 枚举已经存在，但在完整链路落地前仍应显示未支持。功能开关应以可执行路径为准，不以枚举是否编译通过为准。

## 源码索引

- `shared/src/commonMain/kotlin/com/agent/shared/settings/model/ConfigProfile.kt`
- `shared/src/commonMain/kotlin/com/agent/shared/settings/model/ProviderType.kt`
- `shared/src/commonMain/kotlin/com/agent/shared/agent/prompt/MulehangPromptExecutor.kt`
- `shared/src/jvmMain/kotlin/com/agent/shared/agent/koog/DesktopPromptExecutorFactory.kt`
- `shared/src/jvmMain/kotlin/com/agent/shared/agent/provider/`
- `desktopApp/src/main/kotlin/com/agent/app/chat/state/FasterModelTaskSelection.kt`
