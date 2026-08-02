# Usage Patterns

All examples assume the app already imports:

```tsx
import '@jetbrains/ring-ui-built/components/style.css';
```

## Button

```tsx
import Button from '@jetbrains/ring-ui-built/components/button/button';

export function Actions() {
  return (
    <>
      <Button primary>Save</Button>
      <Button danger>Delete</Button>
      <Button loader disabled>
        Saving
      </Button>
    </>
  );
}
```

Use `primary`, `danger`, `loader`, `icon`, `iconRight`, and `dropdown` before inventing wrapper variants.

## Input

```tsx
import {useState} from 'react';
import searchIcon from '@jetbrains/icons/search';
import Input from '@jetbrains/ring-ui-built/components/input/input';

export function SearchField() {
  const [value, setValue] = useState('');

  return (
    <Input
      label='Search'
      value={value}
      icon={searchIcon}
      onChange={event => setValue(event.currentTarget.value)}
      onClear={() => setValue('')}
      placeholder='Type to search'
    />
  );
}
```

Use `error`, `help`, `multiline`, `size`, and `borderless` instead of custom wrappers when possible.

## Select

```tsx
import {useState} from 'react';
import Select from '@jetbrains/ring-ui-built/components/select/select';

const data = [
  {key: 'open', label: 'Open'},
  {key: 'closed', label: 'Closed'},
  {key: 'draft', label: 'Draft'},
];

export function StatusSelect() {
  const [selected, setSelected] = useState(data[0]);

  return <Select data={data} selected={selected} onSelect={setSelected} label='Status' clear />;
}
```

Use `multiple`, `filter`, `tags`, and `type={Select.Type.BUTTON}` when you need richer picker behavior.

## Dropdown + PopupMenu

```tsx
import Dropdown from '@jetbrains/ring-ui-built/components/dropdown/dropdown';
import Button from '@jetbrains/ring-ui-built/components/button/button';
import PopupMenu from '@jetbrains/ring-ui-built/components/popup-menu/popup-menu';

const items = [
  {label: 'Edit'},
  {label: 'Duplicate'},
  {label: 'Archive'},
];

export function RowActions() {
  return (
    <Dropdown anchor={<Button delayed>Actions</Button>}>
      <PopupMenu closeOnSelect data={items} />
    </Dropdown>
  );
}
```

Reach for this pair before building a custom menu popover from scratch.

## Dialog

```tsx
import {useState} from 'react';
import Dialog from '@jetbrains/ring-ui-built/components/dialog/dialog';
import {Header, Content} from '@jetbrains/ring-ui-built/components/island/island';
import Panel from '@jetbrains/ring-ui-built/components/panel/panel';
import Button from '@jetbrains/ring-ui-built/components/button/button';
import Input from '@jetbrains/ring-ui-built/components/input/input';

export function RenameDialog() {
  const [show, setShow] = useState(false);
  const [value, setValue] = useState('');

  return (
    <>
      <Button onClick={() => setShow(true)}>Rename</Button>
      <Dialog label='Rename item' show={show} onCloseAttempt={() => setShow(false)} trapFocus showCloseButton>
        <Header>Rename item</Header>
        <Content>
          <Input label='Name' value={value} onChange={event => setValue(event.currentTarget.value)} />
        </Content>
        <Panel>
          <Button primary onClick={() => setShow(false)}>
            Save
          </Button>
          <Button onClick={() => setShow(false)}>Cancel</Button>
        </Panel>
      </Dialog>
    </>
  );
}
```

The common Ring UI composition is `Dialog` + `Header` + `Content` + `Panel`.

## Tabs

```tsx
import {useState} from 'react';
import {Tabs, Tab} from '@jetbrains/ring-ui-built/components/tabs/tabs';

export function SettingsTabs() {
  const [selected, setSelected] = useState('profile');

  return (
    <Tabs selected={selected} onSelect={setSelected}>
      <Tab id='profile' title='Profile'>
        Profile content
      </Tab>
      <Tab id='notifications' title='Notifications'>
        Notifications content
      </Tab>
    </Tabs>
  );
}
```

Use `SmartTabs` only when automatic selection management is a better fit than controlled state.

## Table

```tsx
import Table from '@jetbrains/ring-ui-built/components/table/table';

const columns = [
  {id: 'name', title: 'Name', sortable: true},
  {id: 'email', title: 'Email'},
];

const data = [
  {id: 1, name: 'Ada Lovelace', email: 'ada@example.com'},
  {id: 2, name: 'Grace Hopper', email: 'grace@example.com'},
];

export function UsersTable() {
  return <Table columns={columns} data={data} />;
}
```

Add `selection`, `onSort`, `sortKey`, `sortOrder`, and `Pager` only when the feature actually needs them.

## DatePicker

```tsx
import {useState} from 'react';
import DatePicker from '@jetbrains/ring-ui-built/components/date-picker/date-picker';

export function DueDateField() {
  const [date, setDate] = useState('01.01.26');

  return <DatePicker date={date} onChange={setDate} clear />;
}
```

Use `range`, `withTime`, `minDate`, and `maxDate` instead of custom date logic when Ring UI already covers the interaction.

## Tooltip

```tsx
import Tooltip from '@jetbrains/ring-ui-built/components/tooltip/tooltip';
import Button from '@jetbrains/ring-ui-built/components/button/button';

export function HelpAction() {
  return (
    <Tooltip title='This action syncs the current record to the remote service.'>
      <Button>Sync</Button>
    </Tooltip>
  );
}
```

Use `selfOverflowOnly` when the tooltip should appear only for truncated text.

## Alert Service

```tsx
import Button from '@jetbrains/ring-ui-built/components/button/button';
import alertService from '@jetbrains/ring-ui-built/components/alert-service/alert-service';

export function NotifyButton() {
  return <Button onClick={() => alertService.successMessage('Saved successfully')}>Notify</Button>;
}
```

Use the service for imperative global feedback. Use the `Alert` component when the alert is part of page layout.
