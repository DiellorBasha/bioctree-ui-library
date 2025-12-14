# FlowbiteCard Component

Display rich, styled content in a flexible card component with headers, footers, and status badges.

## Features

- **Flexible Content** - Support for HTML content in the card body
- **Status Badges** - Optional colored status indicators (primary, success, danger, warning)
- **Interactive Mode** - Make cards clickable with callbacks
- **Tailwind CSS** - Full Tailwind CSS styling framework
- **MATLAB Integration** - Full bidirectional communication with MATLAB

## Dependencies

- **Tailwind CSS:** 3.4.17
- **Flowbite:** 2.5.0
- **MATLAB:** R2020b+

## Usage

### Basic Card

```matlab
fig = uifigure('Position', [100 100 600 400]);
card = FlowbiteCard(fig, 'Position', [50 50 500 300]);

card.Title = 'Welcome';
card.Subtitle = 'This is a card component';
card.Content = '<p>Your HTML content here</p>';
card.Status = 'Active';
card.StatusVariant = 'success';
```

### Interactive Card with Click Handler

```matlab
card.Interactive = true;
card.CardClickedFcn = @(src, event) disp(['Card clicked: ' src.Title]);
```

### Card with Custom HTML

```matlab
card.Content = '<h3>Section 1</h3><p>Content here</p><h3>Section 2</h3><p>More content</p>';
card.FooterText = '<button class="text-blue-600 hover:underline">Click here</button>';
```

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Title` | string | "Card Title" | Main heading |
| `Subtitle` | string | "" | Optional subtitle |
| `Content` | string | HTML content | Body content (supports HTML) |
| `FooterText` | string | "" | Footer content (supports HTML) |
| `Status` | string | "" | Status badge text (empty = no badge) |
| `StatusVariant` | string | "primary" | Badge color: primary, success, danger, warning |
| `Interactive` | logical | false | If true, card is clickable |

## Events

- `CardClicked` - Fired when interactive card is clicked

## Event Callbacks

- `CardClickedFcn` - Callback function executed on card click

## Architecture

```
@FlowbiteCard/
├── FlowbiteCard.m          # MATLAB class
├── README.md               # This file
└── web/
    ├── index.html          # HTML entry point
    ├── main.js             # Bootstrap and lifecycle
    ├── render.js           # Card rendering logic
    ├── styles.css          # Component-specific styles
    └── flowbite-ui.css     # Compiled Tailwind + Flowbite
```

## Examples

### Gallery of Cards

```matlab
fig = uifigure('Position', [100 100 900 600]);

% Card 1: Info
card1 = FlowbiteCard(fig, 'Position', [20 320 250 250]);
card1.Title = 'Feature';
card1.Status = 'New';
card1.StatusVariant = 'success';
card1.Content = '<p>Fast and reliable component library.</p>';

% Card 2: Warning
card2 = FlowbiteCard(fig, 'Position', [320 320 250 250]);
card2.Title = 'Alert';
card2.Status = 'Important';
card2.StatusVariant = 'warning';
card2.Content = '<p>Please review this information.</p>';

% Card 3: Error
card3 = FlowbiteCard(fig, 'Position', [620 320 250 250]);
card3.Title = 'Status';
card3.Status = 'Error';
card3.StatusVariant = 'danger';
card3.Content = '<p>Something needs attention.</p>';
```

### Interactive Dashboard

```matlab
fig = uifigure('Position', [100 100 600 500]);

card = FlowbiteCard(fig, 'Position', [50 100 500 350]);
card.Title = 'Data Summary';
card.Subtitle = 'Click for details';
card.Interactive = true;

content = sprintf('<p>Total: 1,234</p><p>Active: 567</p><p>Pending: 89</p>');
card.Content = content;
card.Status = 'Live';
card.StatusVariant = 'success';

card.CardClickedFcn = @(src, event) showDetails(src);

function showDetails(card)
    fprintf('Card "%s" was clicked\n', card.Title);
    % Update card content
    card.Content = '<p>Updated content!</p>';
    card.Status = 'Clicked';
end
```

## Testing

### MATLAB Test

```matlab
run tests/matlab/test_FlowbiteCard.m
```

### Browser Test

```
Open tests/html/test_FlowbiteCard.html in your browser
```

## MATLAB-JavaScript Communication

**MATLAB → JavaScript:** Via `HTMLComponent.Data`
```matlab
cardData = struct();
cardData.title = 'New Title';
cardData.content = '<p>New content</p>';
comp.HTMLComponent.Data = cardData;
```

**JavaScript → MATLAB:** Via CustomEvent dispatching
```javascript
htmlComponent.dispatchEvent(new CustomEvent('CardClicked', {
    detail: JSON.stringify({
        title: card.title,
        timestamp: new Date().toISOString(),
        clickCount: 1
    })
}));
```

## Styling

Cards are styled with Tailwind CSS and can be customized by:
1. Modifying `web/styles.css` for custom styles
2. Rebuilding CSS in `ui-build/` if you modify Tailwind config
3. Adding inline CSS via HTML content

## Troubleshooting

**Issue:** Content not displaying
- **Solution:** Ensure HTML is properly formatted in `Content` property

**Issue:** Status badge not visible
- **Solution:** Set `Status` property (empty string = no badge)

**Issue:** Clicks not working
- **Solution:** Set `Interactive = true` and verify `CardClickedFcn` is defined
