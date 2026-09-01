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

## 2026-08-19 — 已发布的 standalone Markdown 默认高亮器与本地 Jewel 文档不一致

- 环境：Windows；Jewel `0.39.1-262.9437.29`（本项目解析到的 Maven 版本）；Compose Desktop `1.11.0`；JBR `25.0.4+1-508.27-jcef`。
- 症状：仅按本地 `platform/jewel/docs/standalone-code-highlighting.md` 的说明调用已发布版本的 `ProvideMarkdownStyling` 时，Markdown 代码围栏保持纯文本，未获得 Kotlin/Python token 颜色。
- 证据：匹配已解析 Jewel sources 的 standalone `ProvideMarkdownStyling` 默认参数是 `NoOpCodeHighlighter`；而本地 IntelliJ Jewel 文档和较新的源码说明使用 `SimpleCodeHighlighter`。项目中显式传入回移植的同版本上游 `SimpleCodeHighlighter` 后，`AssistantMarkdownRenderPolicyTest` 验证 Python 的关键字和字符串有不同 token 颜色、未知语言没有 span；`:desktopApp:test` 通过。
- 已确认边界/根因：本地 IntelliJ 源码/文档描述的是尚未与 Maven `0.39.1-262.9437.29` 对齐的 API 行为；不能假定发布版的默认参数已同步。是否会在后续 Jewel 发布版中默认启用，待确认。
- 处理状态：已修复。应用明确提供高亮器，保留未知语言的纯文本回退；不直接依赖完整 IntelliJ Platform 的 Markdown 插件类。
- 来源：已解析的 `jewel-markdown-int-ui-standalone-styling-0.39.1-262.9437.29-sources.jar`；本地 `platform/jewel/docs/standalone-code-highlighting.md`；当前项目 `MulehangTheme.kt`、`AssistantCodeBlock.kt` 和 `AssistantMarkdownRenderPolicyTest.kt`。

## 2026-08-20 — 浅色标题栏若调用 `TitleBarStyle.dark` 会连带使用深色 Dropdown 与 Menu

- 环境：Windows；Jewel `0.39.1-262.9437.29`；Compose Desktop `1.11.0`；JBR `25.0.4+1-508.27-jcef`。
- 症状：应用已切换到浅色 palette 时，标题栏项目和分支下拉仍是深色表面，普通标题栏 hover 也容易继承深色/蓝色的状态语义。
- 证据：匹配源码 `platform/jewel/decorated-window/.../IntUiTitleBarStyling.kt` 中 `TitleBarStyle.light` 构造 `DropdownStyle.Undecorated.light`，而 `TitleBarStyle.dark` 构造 `DropdownStyle.Undecorated.dark`。本项目修改前无条件调用 `TitleBarStyle.dark`，修改后按 `palette.isDark` 分支调用对应工厂；`:desktopApp:test`、`:desktopApp:compileKotlin` 和 Windows 打包均通过。
- 已确认边界/根因：这是标题栏 style 工厂同时决定 Dropdown/Menu 样式的设计，而非项目/分支控件单独设置了错误背景。`TitleBarColors` 的 `iconButton` 在该版本的 `titleBarIconButtonStyle` 中把传入参数映射到 `backgroundPressed`/`backgroundHovered`，自定义中性 hover 时须按实际映射校验。
- 处理状态：已修复。浅色使用 `TitleBarStyle.light`，普通 hover 为 `#D5D9E0`，蓝色仅保留给真实选中和主操作。
- 来源：匹配 Jewel 源码 `IntUiTitleBarStyling.kt`；当前项目 `desktopApp/src/main/kotlin/com/agent/app/design/MulehangTheme.kt`、`DesktopThemeSettingsTest.kt`。

## 2026-08-25 — 带 tooltip 的 `IconActionButton` 不能直接承载 `BoxScope.align`

- 环境：Windows；Jewel `0.39.1-262.9437.29`；Compose Desktop `1.11.0`；JBR `25.0.4+1-508.27-jcef`。
- 症状：将 `.align(Alignment.BottomEnd)` 直接传给带 `tooltip` 的 `IconActionButton` 后，回到底部按钮落在时间线左上角，而不是预期右下角。
- 证据：匹配 `IconActionButton.kt` 源码的 tooltip 重载在第 86 行创建 `Tooltip`，再在其 content lambda 内部把调用方 `modifier` 传给 `BaseIconActionButton`。因此外层 `Box` 的直接子节点是 `Tooltip`，不是携带 `BoxScope.align` 的按钮。项目中旧的 `WorkspacePanel.kt` 正是将该 parent-data modifier 直接传给 tooltip 重载。
- 已确认边界/根因：`BoxScope` 的定位 modifier 必须附着在 `Box` 的直接子节点；Jewel tooltip 重载的内部包装层不会替外层 parent-data modifier 传递布局归属。该结论仅适用于上述 Jewel API 重载结构。
- 处理状态：已在项目中使用直接子 `Box` 承载右下定位和 36dp 尺寸，内部 `IconActionButton` 仅使用 `fillMaxSize()`；`:desktopApp:test` 与 `:desktopApp:compileKotlin` 已通过，真实窗口视觉验收待用户运行应用确认。
- 来源：匹配 `jewel-ui-0.39.1-262.9437.29-sources.jar!/org/jetbrains/jewel/ui/component/IconActionButton.kt`；当前项目 `desktopApp/src/main/kotlin/com/agent/app/chat/component/WorkspacePanel.kt`。

## 2026-08-25 — 可聚焦的 `PopupMenu` 会阻断 Composer 触发器 hover

- 环境：Windows；Jewel `0.39.1-262.9437.29`；Compose Desktop `1.11.0`；JBR `25.0.4+1-508.27-jcef`。
- 症状：打开任一 Composer 下拉菜单后，当前触发器立即失去 hover，鼠标移到其他服务商、模型、推理等级或权限触发器也没有 hover 填充。
- 证据：匹配 Jewel `PopupMenu` 源码默认传入 `PopupProperties(focusable = true)`；匹配 Compose `Popup.skiko.kt` 将该值传入 `ComposeSceneLayer`。`ComposeSceneLayer` 明确规定可聚焦层外部的指针事件不会传到下层，Desktop 实现的 `FocusableLayerEventFilter` 也会在上层存在可聚焦层时阻止下层鼠标事件。用户的复现与这条事件路径一致。
- 已确认边界/根因：触发器本身的 `hoverable` 和 `ActionButton` 状态可以正常工作；问题发生在打开的可聚焦弹层拦截 Composer 下层鼠标事件之后。非可聚焦弹层仍会在自身范围内接收菜单点击，并保留默认的点击外部关闭；它不接收菜单键盘事件。
- 处理状态：已按触发方式分流。指针按下后保持 `PopupProperties(focusable = false)`，键盘 Enter/Space 激活时设为 `true`；触发器和主操作恢复 `ActionButton(focusable = true)`，焦点使用中性背景。匹配源码与当前项目的 IDEA 局部重建通过；此主机缺少 JDK 25 工具链，Gradle 测试尚未重跑，真实窗口验收待完成。
- 来源：匹配 `jewel-ui-0.39.1-262.9437.29-sources.jar!/org/jetbrains/jewel/ui/component/Menu.kt`；Compose Desktop `1.11.0` 的 `Popup.skiko.kt`、`ComposeSceneLayer.skiko.kt`、`DesktopComposeSceneLayer.desktop.kt`；当前项目 `desktopApp/src/main/kotlin/com/agent/app/chat/component/ComposerControls.kt`。

## 2026-08-25 — `DefaultButton` 的焦点描边不能通过 `ButtonColors` 隐藏

- 环境：Windows；Jewel `0.39.1-262.9437.29`；Compose Desktop `1.11.0`；JBR `25.0.3+9-508.16-nomod`。
- 症状：Composer 的发送和停止图标按钮没有可见 hover 填充，点击后出现主题蓝色圆角描边；将 `ButtonColors.borderFocused` 设为透明也不生效。
- 证据：匹配 Jewel `Button.kt` 的 `DefaultButton` 没有 `focusable` 参数，并在 `ButtonImpl` 中无条件对聚焦状态应用 `focusOutline`。匹配 `Outline.kt` 显示该 outline 直接使用 `JewelTheme.globalColors.outlines.focused`，不读取 `ButtonColors`。匹配 `ActionButton.kt` 与 `IconButton.kt` 显示 `ActionButton(focusable = false)` 会为内部图标按钮添加 `focusProperties { canFocus = false }`，且图标按钮实现没有 `focusOutline`。用户在真实 Composer 中复现了缺失 hover 和点击蓝边。
- 已确认边界/根因：`ButtonColors` 只能控制按钮背景、内容和边框，不能控制 `DefaultButton` 的全局焦点描边；当前版本的 `DefaultButton` 没有关闭该描边的公开参数。`DefaultButton` 收集到 `HoverInteraction` 才会进入 hover 状态，但本 Composer 原先没有显式 `hoverable` 修饰符。为何该场景下 `clickable` 未产生可见 hover，待单独调试确认。
- 处理状态：原先使用 `ActionButton(focusable = false)` 以避免不符合视觉的焦点效果；无障碍评审后改为 `ActionButton(focusable = true)`，并将 `backgroundFocused` 设为中性 hover 背景。发送与停止仍共用 36dp、8dp 容器，停止图标保留危险色。
- 来源：匹配 `jewel-ui-0.39.1-262.9437.29-sources.jar!/org/jetbrains/jewel/ui/component/Button.kt`、`ActionButton.kt`、`IconButton.kt`、`Outline.kt` 与 `component/styling/ButtonStyling.kt`；当前项目 `ComposerPanel.kt`、`ComposerControls.kt`；用户提供的 Windows 运行时截图。

## 2026-08-30 — `LocalDensity` 不会额外放大使用像素约束计算的 SVG Canvas

- 环境：Windows；Jewel `0.39.1-262.9437.29`；Compose Desktop `1.11.0`；JBR 25。
- 症状：审查意见认为全局 `LocalDensity` 已使 SVG Canvas 内容缩放，要求删除 SVG 的额外全局绘制倍率。
- 证据：匹配 Compose `ui-desktop-1.11.0-sources.jar` 的 `CompositionLocals.kt` 定义 `LocalDensity` 为 dp/sp 与像素之间的转换；匹配 `foundation-layout-desktop-1.11.0-sources.jar` 的 `BoxWithConstraints.kt` 明确保留父级像素约束，并仅在 `maxWidth` 等 dp 属性上通过 `constraints.maxWidth.toDp()` 转换。项目 `DiagramSvgSurface` 随后把 `maxWidth` 转回像素后计算 `fitScale`，Canvas 也以像素坐标绘制。
- 已确认边界/根因：当 SVG 适配倍率来自像素约束并用于 Canvas 绘制时，单独提供更高的 `LocalDensity` 不会让该倍率变大。若要求图表内容随全局外观缩放额外放大，必须在绘制倍率中保留独立的全局倍率；这会有意扩大同级平移边界。
- 处理状态：保留 `fitScale * diagramScale * globalScale`。现有 `DiagramSvgPreviewTest` 验证局部图表缩放值不被全局倍率改写。
- 来源：Compose Desktop `1.11.0` 匹配源码；项目 `DesktopAppearance.kt`、`DiagramSvgPreview.kt`、`DiagramSvgPreviewTest.kt`；PR #7 审查线程。

## 2026-08-31 — 全局 `LocalDensity` 不能直接包住 Windows 原生 `TitleBar`

- 环境：Windows；Jewel `0.39.1-262.9437.29`；Compose Desktop `1.11.0`；JBR 25；应用全局缩放 60%、100%、130%。
- 症状：全局缩放后标题栏视觉内容会变大，但标题栏与正文工作区之间出现额外空隙或坐标错位，深色环境光的标题栏/分隔线/正文起点也不能连续。
- 证据：匹配 Jewel `TitleBar.kt` 显示标题栏先按 `style.metrics.height` 测量，再在 `onSizeChanged` 中用当前 `LocalDensity` 将像素高度转为 dp；`TitleBar.Windows.kt` 将该 dp 值写给 JBR `CustomTitleBar`，而 `DecoratedWindow.kt` 以标题栏实际 `Placeable.height` 偏移正文。若全局缩放提供者包住整个 `TitleBar`，两条链路会使用不同坐标系。项目 `DesktopThemeSettingsTest` 断言 60%、100%、130% 标题栏度量分别为 32.4dp、54dp、70.2dp；`FrameAmbientTest` 在 1.5 系统密度下断言正文原点分别为 51px、83px、107px，且标题栏与正文共享的环境光密度分别为 0.9、1.5、1.95；`:desktopApp:test` 与 `:desktopApp:compileKotlin` 均通过。
- 已确认边界/根因：在此 Jewel/Compose 组合下，原生 `TitleBar` 必须保持未缩放 `LocalDensity`，但其 `TitleBarMetrics.height` 需要按应用缩放明确增大；仅标题栏内部 Compose 内容和正文应接收全局缩放密度。由于 `drawWithCache` 也会从各自组合读取 `density`，标题栏与正文环境光还必须显式使用同一个实际画布密度。固定 1dp 分隔线仍需在未缩放密度中取整。真实窗口的三档视觉验收待用户运行应用确认。
- 处理状态：已修复。项目将缩放后的标题栏高度传入 `MulehangTheme`，将 `ChatTitleBar` 外层留在原生密度，并只在标题栏内容行和正文分别提供全局外观；正文环境光起点和标题栏/正文画布密度均复用同一实际布局计算。
- 来源：匹配 `jewel-decorated-window-0.39.1-262.9437.29-sources.jar` 中的 `TitleBar.kt`、`TitleBar.Windows.kt`、`DecoratedWindow.kt`；当前项目 `MulehangTheme.kt`、`ChatTitleBar.kt`、`MulehangDesktopApp.kt`、`DesktopThemeSettingsTest.kt`、`FrameAmbientTest.kt`。

## 2026-08-31 — `SwingPanel.factory` 不能用于切换持久终端组件

- 环境：Windows；Jewel `0.39.1-262.9437.29`；Compose Desktop `1.11.0`；JBR 25；内嵌 JediTerm 终端。
- 症状：两个终端标签切换后展示同一份终端历史。为每个 tab ID 强制重建 `SwingPanel` 后，用户运行时截图显示标签正常创建但终端画布为空。
- 证据：匹配 Compose Desktop `ui-desktop-1.11.0-sources.jar` 中的 `SwingPanel.desktop.kt` 将带有调用方 `factory` 的 `SwingInteropViewHolder` 放在 `remember` 内创建，因此同一个组合位置的 `factory` 只用于首次创建互操作组件。项目原先向 `factory` 闭包传入活动 JediTerm 组件，自动化测试确认各 tab 的 Swing 组件本身不同。新建的 `TerminalSwingHostTest` 验证稳定 `JPanel` 宿主会移除旧组件，并只保留当前 tab 对应组件。
- 已确认边界/根因：不能依靠 `SwingPanel(factory = { activeComponent })` 在重组时更换已嵌入的 Swing 子组件。标签切换需要保持一个稳定的 `SwingPanel`，并在其 `update` 回调中由宿主容器显式替换子组件。强制重建 `SwingPanel` 后空白画布的底层框架原因尚未单独调试确认。
- 处理状态：已改为稳定 `TerminalSwingHost`，按 tab ID 先 `removeAll()` 后挂载对应 JediTerm，并重新布局和重绘。`:desktopApp:test` 与 `:desktopApp:compileKotlin` 已通过；真实窗口验收待用户在更新后的进程中确认。
- 来源：Compose Desktop `1.11.0` 匹配源码 `androidx/compose/ui/awt/SwingPanel.desktop.kt`；用户提供的 Windows 终端截图；当前项目 `EmbeddedTerminalPanel.kt` 与 `TerminalSwingHostTest.kt`。
