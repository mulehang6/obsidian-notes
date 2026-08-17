---
name: jetbrains-jewel
description: 使用 JetBrains Jewel 构建、修改、审查或迁移 Kotlin Compose Desktop / IntelliJ Platform 插件 UI 时使用。适用于 Jewel 依赖、主题、组件、Swing/Compose 互操作、版本升级和编译错误修复；尤其在 Jewel 的预发布 API、坐标、包名或兼容性可能发生破坏性变化时，先核验当前版本与官方 Release Notes，再编写代码。
---

# JetBrains Jewel

将 Jewel 视为快速演进的预发布依赖：项目中**已解析的版本和其对应的官方发布说明**高于记忆、旧示例和网络片段。主文件只负责路由；按任务读取一个或多个 `references/` 文件，不要把它们全部加载。

## 每次任务的最低要求

1. 先确定是独立 Compose Desktop 应用还是 IntelliJ Platform 插件，并读取 `references/version-safety.md`。
2. 记录项目实际解析的 Jewel、Kotlin、Compose、IntelliJ Platform 与 JDK 版本；若需要，可运行 `scripts/inspect-jewel-dependencies.ps1`。
3. 使用与**目标已发布版本**匹配的 JetBrains Release Notes、Maven 元数据和源码验证 API 与兼容性。不要将 `master`、归档仓库或旧文章当作已锁定版本的事实。
4. 再读取下表中与任务对应的参考文件并实施；除非任务明确要求，否则不升级依赖。

## 按意图路由

| 请求意图 | 先读取 |
| --- | --- |
| 安装、依赖、Gradle、构件、缺类、Standalone、插件 | `references/dependency-model.md` |
| 新 UI、主题、组件、窗口、弹窗、输入、Swing/Compose 互操作 | `references/ui-patterns.md` |
| 升级、迁移、API 找不到、二进制不兼容、弃用移除 | `references/migration.md` |
| 版本、兼容表、Release Notes、Kotlin/Compose/JDK 组合 | `references/version-safety.md` |

对于具体组件，先从当前已解析的 Jewel 源码/JAR 和目标版本官方示例确认组件所属模块、导入、参数和稳定性；不要根据本技能或历史代码推断签名。

## 交付标准

- 运行仓库定义的最小相关编译和测试；不要启动长期运行开发服务器。
- 报告实际版本矩阵、查阅的 Release Notes 范围、改动与验证结果。
- 没有精确的官方兼容性证据时，将其列为风险或阻塞项；不要宣称兼容。
