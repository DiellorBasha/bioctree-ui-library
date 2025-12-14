# FlowbiteSidebar Component

A Flowbite-styled sidebar navigation component for MATLAB ComponentContainers.

## Features

- **Navigation Items** - Customizable menu items
- **Collapse/Expand** - Toggle sidebar visibility with smooth transitions
- **Themes** - Support for light and dark themes
- **Event Handling** - ItemClicked event when users select menu items
- **Callbacks** - ItemClickedFcn for MATLAB-side event handling
- **Responsive** - Adapts to container size

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Items` | string array | `["Dashboard"; "Users"; "Settings"; "Help"]` | Menu item labels |
| `Collapsed` | logical | `false` | Sidebar collapse state (true = collapsed) |
| `SelectedItem` | string | `"Dashboard"` | Currently selected menu item |
| `Theme` | string | `"light"` | Visual theme: `"light"` or `"dark"` |
| `ItemClickedFcn` | function_handle | `[]` | Callback function for item clicks |

## Events

- **ItemClicked** - Fired when user clicks a menu item
  - Event data: `Item` (selected item), `ClickCount` (click counter)

## Usage Example

```matlab
% Create a sidebar with default items
fig = uifigure('Position', [100 100 800 500]);
sidebar = FlowbiteSidebar(fig);

% Customize items
sidebar.Items = ["Home"; "Dashboard"; "Analytics"; "Reports"; "Settings"];
sidebar.Theme = "dark";

% Set up callback for item clicks
sidebar.ItemClickedFcn = @(src, event) handleItemClick(src, event);

function handleItemClick(src, event)
    fprintf('User selected: %s\n', event.Item);
end
```

## Dependencies

- Tailwind CSS v3.4.17 (compiled in `ui-build/`)
- Flowbite v2.5.0
- MATLAB R2020b+ with ComponentContainer support

## Architecture

The component follows the standard MATLAB ComponentContainer pattern:

- **FlowbiteSidebar.m** - MATLAB class with properties, events, and lifecycle methods
- **web/index.html** - HTML entry point
- **web/main.js** - Bootstrap and lifecycle controller
- **web/render.js** - Pure rendering logic using Tailwind CSS
- **web/styles.css** - Component-specific styling

## Communication Flow

**MATLAB → JavaScript:**
- Properties sent via `HTMLComponent.Data` struct
- Triggers DataChanged event in JavaScript

**JavaScript → MATLAB:**
- Item clicks dispatched as CustomEvent
- MATLAB event handler parses and triggers ItemClicked event
- Callback function executed with event details

## Styling

The component uses Tailwind CSS utility classes with Flowbite design patterns:
- Light theme: White background with gray borders and text
- Dark theme: Dark gray background with light text and borders
- Hover effects and transitions for interactive feedback
- Icons rendered as SVG elements
- Responsive scrollbar styling

## Testing

Run the test file to verify functionality:

```matlab
run('tests/matlab/test_FlowbiteSidebar.m')
```

Or manually test in MATLAB:

```matlab
fig = uifigure('Name', 'Sidebar Test', 'Position', [100 100 800 500]);
sidebar = FlowbiteSidebar(fig, 'Items', ["One"; "Two"; "Three"]);
sidebar.ItemClickedFcn = @(s, e) disp(['Selected: ' e.Item]);
```
