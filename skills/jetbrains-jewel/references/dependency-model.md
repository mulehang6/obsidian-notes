# Jewel 依赖模型

## 先选择运行场景

| 场景 | 依赖策略 | 禁止事项 |
| --- | --- | --- |
| 独立 Compose Desktop 应用 | 仅使用目标 Jewel 版本官方标记为 standalone 的构件及其规定的传递依赖。 | 引入 IntelliJ Platform 实现或 bridge 依赖来“补齐”缺类。 |
| IntelliJ Platform 插件 | 优先使用目标 IDE / Platform 已打包的 Jewel 依赖；仅在目标平台官方文档明确要求时使用兼容构件。 | 将 standalone 构件混入插件 classpath，或假设任意 IDE 版本都兼容。 |

确认运行场景后再选模块。不要根据构件名称、旧示例或自动补全推断它适用于两种场景。

## Gradle 核验

阅读 `settings.gradle.kts`、相关 `build.gradle.kts`、版本目录、锁定文件与 IntelliJ Platform 插件配置。随后查看已解析依赖，而非只查看声明：

```powershell
& 'C:\Users\帅小伙\.codex\skills\jetbrains-jewel\scripts\inspect-jewel-dependencies.ps1' `
    -DependencyInsightTask ':<module>:dependencyInsight' `
    -Configuration '<runtime-or-compile-classpath>'
```

替换模块和配置名为当前项目的真实值。该脚本只运行 `dependencyInsight`，不会写入项目或启动应用。

确认以下条件：

- 所有 `org.jetbrains.jewel` 构件位于同一发布线。
- 未同时解析 standalone 与 IntelliJ Platform / bridge 的冲突构件。
- 传递的 Compose、Skiko、图标和 IntelliJ 依赖符合目标版本 Release Notes 与 POM。
- 没有为了临时消除 `ClassNotFoundException` 而手工加入 Jewel 内部或 `com.intellij` 实现模块。

## 依赖修改规则

1. 仅在任务要求升级或官方矩阵要求时改版本、Maven 仓库、强制版本或排除规则。
2. 原子更新同发布线的全部 Jewel 模块；不要留下旧版 Markdown、窗口或 bridge 模块。
3. 先保留经验证的显式传递依赖，待完整依赖树和 smoke test 通过后，再以单独变更清理冗余项。
4. 发现不同版本被 Gradle 选中时，追踪引入路径和约束来源；不要先添加 `force` 或 `resolutionStrategy` 掩盖问题。
