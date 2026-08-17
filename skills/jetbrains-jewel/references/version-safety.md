# Jewel 版本安全

## 权威来源顺序

按以下顺序建立事实，不要跳过已解析依赖：

1. 项目的 Gradle 已解析依赖、锁定文件和运行目标。
2. Maven Central 或 JetBrains 已发布 Maven 元数据，确认构件版本确实可下载。
3. [Jewel Release Notes](https://github.com/JetBrains/intellij-community/blob/master/platform/jewel/RELEASE%20NOTES.md) 中覆盖该发布版的条目。
4. 与目标 IntelliJ Platform 标签一致的 [Jewel 源码](https://github.com/JetBrains/intellij-community/tree/master/platform/jewel) 和已解析 source JAR。

Release Notes 的 `master` 可能包含尚未发布到 Maven 的下一个版本。始终分开记录“最新发布说明条目”和“最新可解析构件”，不要以其中之一推断另一个。

旧 [JetBrains/jewel](https://github.com/JetBrains/jewel) 仓库已经归档；只将其用于历史背景，绝不用于当前 API、构件坐标或版本矩阵。

## 兼容性闸门

在改动前填写并核验以下矩阵：

| 项目 | 当前解析值 | 目标值 | 官方依据 |
| --- | --- | --- | --- |
| Jewel 与所有 Jewel 模块 |  |  |  |
| Compose Multiplatform |  |  |  |
| Kotlin 与 Compose Compiler |  |  |  |
| JDK / toolchain |  |  |  |
| IntelliJ Platform（若为插件） |  |  |  |
| 运行场景（standalone / plugin） |  |  |  |

只有所有行都有匹配版本的证据后，才开始写或迁移 API。若 `Jewel`、Compose、Kotlin、JDK 或 IntelliJ Platform 有任何一项不匹配，先解决版本冲突。

## 变更前的证据收集

- 阅读旧版到目标版之间**每一个**发布条目，尤其是 `Important Changes`、弃用移除、模块拆分、Kotlin/Compose/JDK 提升与运行时行为改变。
- 对升级跨度内的每个 breaking change，记录受影响文件、替换 API、验证方式和未决风险。
- 在既有发布系列中选择最新版，而不是未经确认地指向 `master`。不确定某个后缀版本对应哪一 IntelliJ 平台发布线时，从 Maven POM、构件名称和正式发布说明交叉确认。

## 禁止事项

- 不要从记忆、旧博客或 Stack Overflow 猜测坐标、仓库、包名或版本兼容性。
- 不要只升级 `org.jetbrains.jewel` 而忽略与其二进制耦合的 Compose、Kotlin、JDK 或 IntelliJ Platform。
- 不要用编译通过代替运行时与视觉兼容性证据。
