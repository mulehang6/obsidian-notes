# Component Catalog

## Table of Contents

- Core UI
- Forms and pickers
- Overlay and feedback
- Data display and navigation
- Layout and structure
- Services and specialized APIs
- Usually skip first

## Core UI

Use these first for most application work.

| Need | Component | Import path | Notes |
| --- | --- | --- | --- |
| Primary or secondary action | `Button` | `components/button/button` | Supports `primary`, `danger`, `loader`, `icon`, `iconRight`, `dropdown`. |
| Related actions in one row | `ButtonGroup` | `components/button-group/button-group` | Visual grouping for several buttons. |
| Dense action set | `ButtonSet` | `components/button-set/button-set` | Lays out action buttons as a set. |
| Toolbar of actions | `ButtonToolbar` | `components/button-toolbar/button-toolbar` | Good for editor or table actions. |
| Inline text or navigation link | `Link` | `components/link/link` | Use instead of styling anchor tags by hand. |
| Text field or textarea | `Input` | `components/input/input` | Supports labels, help, `error`, `icon`, `onClear`, `multiline`. |
| Boolean toggle | `Checkbox` | `components/checkbox/checkbox` | Supports label, help, disabled, indeterminate. |
| Exclusive choice group | `Radio` | `components/radio/radio` | Compose with `Radio.Item`. |
| On/off switch | `Toggle` | `components/toggle/toggle` | Use for binary setting toggles. |
| Choice from list | `Select` | `components/select/select` | Supports single, multi, filter, tags, avatars, button mode. |
| Dropdown anchor + popup | `Dropdown` | `components/dropdown/dropdown` | Compose with `Popup` or `PopupMenu`. |
| Popup menu items | `PopupMenu` | `components/popup-menu/popup-menu` | Good for action menus fed by `data`. |
| Simple menu wrapper | `DropdownMenu` | `components/dropdown-menu/dropdown-menu` | Higher-level dropdown menu option. |
| Tags editor | `TagsInput` | `components/tags-input/tags-input` | Useful for editable labels or recipients. |
| Existing tags display | `TagsList` | `components/tags-list/tags-list` | Read-only tag collection display. |
| Single tag or pill | `Tag` | `components/tag/tag` | Small status or label chip. |
| Slider input | `Slider` | `components/slider/slider` | Numeric range control. |
| File upload | `Upload` | `components/upload/upload` | Use when file selection and upload state matter. |
| Calendar input | `DatePicker` | `components/date-picker/date-picker` | Supports single date, range, time, clear, min/max. |

## Forms and Pickers

These are commonly composed with the core controls above.

| Need | Component | Import path | Notes |
| --- | --- | --- | --- |
| Form field label | `ControlLabel` | `components/control-label/control-label` | Use with checkbox/radio groups or custom controls. |
| Context help for a control | `ControlHelp` | `components/control-help/control-help` | Small helper tooltip pattern. |
| Search-like structured input | `QueryAssist` | `components/query-assist/query-assist` | Async suggestions, syntax highlighting, custom item rendering. |
| Expand/collapse region | `Collapse` | `components/collapse/collapse` | Toggleable content area. |
| Multiple collapsible regions | `CollapsibleGroup` | `components/collapsible-group/collapsible-group` | Grouped accordion-like behavior. |
| Editable heading | `EditableHeading` | `components/editable-heading/editable-heading` | Inline title editing. |
| Rich editable text area | `Contenteditable` | `components/contenteditable/contenteditable` | Use only when plain `Input multiline` is not enough. |

## Overlay and Feedback

| Need | Component | Import path | Notes |
| --- | --- | --- | --- |
| Modal dialog | `Dialog` | `components/dialog/dialog` | Usually composed with `Header`, `Content`, and `Panel`. |
| Confirm flow | `Confirm` | `components/confirm/confirm` | Visual confirm component; see service API below too. |
| Hover explanation | `Tooltip` | `components/tooltip/tooltip` | Supports rich title markup and overflow-only mode. |
| Anchored popup body | `Popup` | `components/popup/popup` | Lower-level overlay primitive. |
| Anchored inline message | `Message` | `components/message/message` | Good for contextual hint or warning near an anchor. |
| Inline alert banner | `Alert` | `components/alert/alert` | Visual alert with type and close handling. |
| Error indicator bubble | `ErrorBubble` | `components/error-bubble/error-bubble` | Compact error marker. |
| Error text block | `ErrorMessage` | `components/error-message/error-message` | Dedicated error message output. |
| Long-running state | `Loader` | `components/loader/loader` | Full loader visuals. |
| Inline loading indicator | `LoaderInline` | `components/loader-inline/loader-inline` | Use inside text or compact areas. |
| Full-screen loading | `LoaderScreen` | `components/loader-screen/loader-screen` | Splash or blocking loading screen. |
| Progress indicator | `ProgressBar` | `components/progress-bar/progress-bar` | Determinate progress. |
| Notification/banner block | `Banner` | `components/banner/banner` | Prominent page-level notice. |

## Data Display and Navigation

| Need | Component | Import path | Notes |
| --- | --- | --- | --- |
| Tabbed sections | `Tabs`, `Tab`, `SmartTabs` | `components/tabs/tabs` | `Tabs` is controlled; `SmartTabs` manages selection. |
| Paginated navigation | `Pager` | `components/pager/pager` | Often paired with `Table`. |
| Data table | `Table` | `components/table/table` | Sorting, selection, drag reorder, custom cell rendering. |
| Structured list | `List` | `components/list/list` | Reused by several pickers and menus. |
| Lightweight key/value or row list | `DataList` | `components/data-list/data-list` | Simpler than `Table`. |
| Breadcrumb navigation | `Breadcrumbs` | `components/breadcrumbs/breadcrumbs` | Hierarchical navigation path. |
| Markdown renderer | `Markdown` | `components/markdown/markdown` | Use for trusted markdown display. |
| Code rendering | `Code` | `components/code/code` | Inline or block code presentation. |
| Typography wrapper | `Text` | `components/text/text` | Shared text styling primitive. |
| Heading styles | `Heading` | `components/heading/heading` | Shared heading typography. |
| Icon glyph renderer | `Icon` | `components/icon/icon` | Pairs with `@jetbrains/icons` glyph imports. |
| Clipboard helper | `Clipboard` | `components/clipboard/clipboard` | Copy-to-clipboard interactions. |
| Scrollable content region | `ScrollableSection` | `components/scrollable-section/scrollable-section` | Constrained scroll area. |

## Layout and Structure

| Need | Component | Import path | Notes |
| --- | --- | --- | --- |
| Card-like container | `Island` | `components/island/island` | Often composed with `Header` and `Content`. |
| Island header | `Header` | `components/island/island` | Shared title/header block for islands and dialogs. |
| Island content | `Content` | `components/island/island` | Shared body block for islands and dialogs. |
| Action footer row | `Panel` | `components/panel/panel` | Common dialog or form action row. |
| Horizontal or vertical grouping | `Group` | `components/group/group` | Small layout grouping helper. |
| Grid layout | `Grid`, `Row`, `Col` | `components/grid/grid` | Structured page and demo layout. |
| Page shell sections | `Header`, `Footer`, `ContentLayout`, `Sidebar` | `components/header/header`, `components/footer/footer`, `components/content-layout/content-layout`, `components/sidebar/sidebar` | Use for full-page app framing. |
| Divider line | `Line` | `components/line/line` | Visual separator. |
| Expand helper | `Expand` | `components/expand/expand` | Specialized expand/collapse affordance. |

## Services and Specialized APIs

These are useful, but they are not the first components to reach for in ordinary CRUD forms.

| Need | API or component | Import path | Notes |
| --- | --- | --- | --- |
| Global toast-like notifications | `alert-service` | `components/alert-service/alert-service` | Imperative success, warning, message flows. |
| Imperative confirm flow | `confirm-service` | `components/confirm-service/confirm-service` | Service alternative to rendering confirm UI manually. |
| Authentication dialog | `AuthDialog` | `components/auth-dialog/auth-dialog` | Auth-specific UI. |
| Imperative auth dialog API | `auth-dialog-service` | `components/auth-dialog-service/auth-dialog-service` | Service-style auth dialog control. |
| Login dialog | `LoginDialog` | `components/login-dialog/login-dialog` | Sign-in specific surface. |
| User avatar display | `Avatar`, `AvatarStack`, `UserCard` | `components/avatar/avatar`, `components/avatar-stack/avatar-stack`, `components/user-card/user-card` | Identity display primitives. |
| Permissions or agreements | `Permissions`, `UserAgreement` | `components/permissions/permissions`, `components/user-agreement/user-agreement` | Product-specific legal/access flows. |
| Analytics helper | `Analytics` | `components/analytics/analytics` | Specialized instrumentation support. |
| Browser/storage helpers | `Storage` | `components/storage/storage` | Specialized persistence helper. |

## Usually Skip First

These exist, but they are rarely the first answer for normal app work:

- `auth`, `http`, `hub-source`, `global`: support modules, not general UI starting points.
- `tab-trap`: low-level focus handling.
- `old-browsers-message`: legacy compatibility surface.
- `shortcuts`: specialized keyboard help flows.
- `welcome`: demo/story surface, not production UI.

If a user request sounds ordinary and one of these seems necessary, double-check whether a higher-level component already solves the problem.
