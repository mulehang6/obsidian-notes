# 已验证的 Jewel 坑

只记录由匹配版本源码、自动化测试或真实运行时调试证实的事实。每次更新都应保留适用边界；未知根因必须明确标为未知。

## 记录格式

```markdown
## YYYY-MM-DD — 简短现象

- 环境：Jewel、Compose、JBR、操作系统及必要的显示缩放/宿主信息。
- 症状：用户可观察到的行为。
- 证据：源码位置，以及最小测试或运行时观测值。
- 已确认边界/根因：仅写已证实部分；未知则写“待确认”。
- 处理状态：已修复、可行绕过、待最小复现，或不适用。
- 来源：源码、测试、issue 或变更链接。
```

## 2026-08-18 — Windows 标题栏 AWT 目标在 ComposeWindowPanel 与 SkiaLayer 之间分流

- 环境：Windows；Jewel `0.39.1-262.9437.29`；Compose Desktop `1.11.0`；JBR `25.0.4+1-508.27`；显示缩放 `1.5`。
- 症状：`DecoratedWindow` 的应用菜单、侧栏、项目和分支控件没有 hover 或点击响应，空白标题栏也不能拖动；系统窗口按钮正常。
- 证据：四个客户端区域已写入，物理矩形分别为 `application-menu (12,11)-(102,71)`、`sidebar-toggle (108,11)-(168,71)`、`project-selector (174,11)-(419,71)`、`branch-menu (425,11)-(765,71)`。当前调试会话中，内容区点 `(699,299)` 的 AWT 事件目标和 source 都是 `org.jetbrains.skiko.SkiaLayer$1`，并进入 `WindowMouseEventEffect`，得到 `isClientRegion=false`；标题栏侧栏点 `(91,27)` 的 AWT 事件目标和 source 都是 `androidx.compose.ui.awt.ComposeWindowPanel`，未进入该 Jewel 监听器。匹配 Compose Desktop `1.11.0` 源码显示 `ComposeWindow.addMouseListener` 委托给 `ComposeWindowPanel`，后者再委托给内部 content component（`SkiaLayer`）；匹配 Jewel 源码的 `WindowMouseEventEffect` 正是经由 `window.addMouseListener`/移动监听器注册。
- 已确认边界/根因：JBR 的标题栏 AWT 事件确实到达 Java 侧，但投递到 `ComposeWindowPanel`；Jewel 通过 ComposeWindow 注册的监听器实际挂在 `SkiaLayer`。因此标题栏事件不会自然抵达 Jewel 的 `WindowMouseEventEffect`。这一结论只适用于上述精确版本组合，不能泛化为 Jewel 或 JBR 的通用行为。
- 处理状态：项目已新增一个 Windows 生命周期受控的事件桥接：仅将以 `ComposeWindowPanel` 为 source 的鼠标事件重分发给既有 `SkiaLayer`，以复用 Jewel 原有的 `clientRegion` 和 `forceHitTest` 链路；不创建 Swing 标题栏、覆盖层或新命中区域。由于真实窗口自动化被用户停止，尚未完成四个控件、空白拖动和 `forceHitTest` 参数的运行时验收。
- 来源：匹配 `jewel-decorated-window` sources 中的 `ClientRegionHelper.kt`、`TitleBar.Windows.kt`、`DecoratedWindow.kt`；Compose Desktop `1.11.0` sources 中的 `ComposeWindow.desktop.kt`、`ComposeWindowPanel.desktop.kt`；当前 Windows 调试会话非暂停日志点。

## 2026-08-18 — 深色 Islands 标题栏会暴露 Jewel 固定 1dp 分隔区

- 环境：Windows；Jewel `0.39.1-262.9437.29`；Compose Desktop `1.11.0`；JBR `25.0.4+1-508.27`；显示缩放 `1.5`。
- 症状：标题栏使用透明 Islands 环境光、而 `TitleBarColors.border` 使用固定 `frameBackground` 时，标题栏下方出现横向固定色分隔线。
- 证据：匹配 Jewel 源码 `jewel-decorated-window/.../TitleBar.kt` 的 `TitleBarImpl` 在标题栏 `Box` 后无条件创建 `height(1.dp).background(style.colors.border)` 的 sibling `Spacer`；标题栏传入的 `modifier` 不会覆盖该 sibling。匹配 Compose `1.11.0` 源码中 `Density.roundToPx()` 会将 `Dp.toPx()` 取整，`SizeNode` 用它测量 `Modifier.height`，而 `DecoratedWindowMeasurePolicy` 以整像素 `Placeable.height` 偏移内容。在 1.5 倍缩放的真实调试会话中，非暂停日志点分别记录到分隔区绘制延展高度 `2.0` 与内容原点 `83.0`；首轮使用浮点 `toPx()` 的 `1.5` 和 `82.5` 时，用户截图仍显示残余横线，且在环境光最强处更明显。`FrameAmbientTest` 与 `:desktopApp:test :desktopApp:compileKotlin` 均通过。
- 已确认边界/根因：这是 Jewel `TitleBar` 的固定布局行为；在非整数缩放下，若环境光仍使用 `1.dp.toPx()` 的浮点高度/原点采样，就会与该固定 Spacer 的整数布局边界错开。它不是 DWM 右/下边框修复或内容区 Surface 的边线。该结论仅适用于此 Jewel/Compose 版本组合。
- 处理状态：已将标题栏越界绘制和内容区虚拟原点统一为 `roundToPx()` 得到的实际布局像素；调试会话已确认新值生效，最终真实窗口视觉验收待完成。
- 来源：匹配 `jewel-decorated-window-0.39.1-262.9437.29-sources.jar` 中的 `org/jetbrains/jewel/window/TitleBar.kt` 与 `DecoratedWindow.kt`；Compose `1.11.0` 的 `Density.kt` 与 `foundation-layout/Size.kt`；当前项目的 `FrameAmbient.kt`、`ChatTitleBar.kt`、`MulehangDesktopApp.kt` 与 `FrameAmbientTest.kt`；当前 Windows 非暂停日志点。
