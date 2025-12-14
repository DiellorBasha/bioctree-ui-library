# FlowbiteButton Component

Interactive button component built with Flowbite + Tailwind CSS, integrated into MATLAB as a ComponentContainer.

## Features

- **Tailwind + Flowbite Integration** - Full Tailwind CSS framework with Flowbite component library
- **Multiple Variants** - Primary, success, danger, warning, and secondary button styles
- **Click Events** - Callback support and MATLAB events
- **Bidirectional Communication** - Full MATLAB-JavaScript data synchronization

## Dependencies

- **Tailwind CSS:** 3.4.17
- **Flowbite:** 2.5.0
- **MATLAB:** R2020b+ (ComponentContainer support)

## Usage

```matlab
% Create a figure and add the button component
fig = uifigure('Position', [100 100 600 200]);
btn = FlowbiteButton(fig, 'Position', [50 50 500 100]);

% Set properties
btn.Label = 'Submit';
btn.Variant = 'success';

% Set up callback
btn.ButtonClickedFcn = @(src, event) disp(['Button clicked! Count: ' num2str(src.ClickCount)]);
```

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `Label` | string | "Click me" | Text displayed on the button |
| `Variant` | string | "primary" | Color variant: primary, success, danger, warning, secondary |

## Events

- `ButtonClicked` - Fired when button is clicked

## Events Callbacks

- `ButtonClickedFcn` - Callback function executed on button click

## Architecture

```
@FlowbiteButton/
├── FlowbiteButton.m        # MATLAB class
├── README.md               # This file
└── web/
    ├── index.html          # HTML entry point
    ├── main.js             # Bootstrap and lifecycle controller
    ├── render.js           # Pure visualization logic
    ├── styles.css          # Component-specific styles
    └── flowbite-ui.css     # Compiled Tailwind + Flowbite CSS
```

## Files

- **FlowbiteButton.m** - MATLAB class extending ComponentContainer
- **web/index.html** - HTML template loaded by uihtml()
- **web/main.js** - Bootstrap function called by MATLAB, handles setup and lifecycle
- **web/render.js** - Pure rendering logic, creates Flowbite button and handles events
- **web/styles.css** - Component-specific CSS
- **web/flowbite-ui.css** - Compiled Tailwind + Flowbite stylesheet (26KB)

## Building CSS

To rebuild the CSS after modifying Tailwind/Flowbite configuration:

```bash
cd ui-build
npm run build  # or: npx tailwindcss -i ./src/input.css -o ./src/flowbite-ui.css --minify
cp src/flowbite-ui.css ../controllers/@FlowbiteButton/web/
```

## Testing

### Browser Test
Open `tests/html/test_FlowbiteButton.html` in a browser to test without MATLAB.

### MATLAB Test
```matlab
% Create test figure
fig = uifigure('Position', [100 100 600 400]);
btn = FlowbiteButton(fig, 'Position', [10 200 580 150]);

% Test different variants
variants = ["primary", "success", "danger", "warning", "secondary"];
for i = 1:length(variants)
    btn.Variant = variants(i);
    btn.Label = variants(i);
    pause(1);
end

% Test callback
btn.Label = 'Click Me!';
btn.Variant = 'success';
btn.ButtonClickedFcn = @(src, event) fprintf('Button clicked! Total: %d\n', src.ClickCount);
```

## MATLAB-JavaScript Communication

**MATLAB → JavaScript:** Via `HTMLComponent.Data`
```matlab
buttonData = struct();
buttonData.label = 'New Label';
buttonData.variant = 'success';
comp.HTMLComponent.Data = buttonData;  % Triggers DataChanged event in JS
```

**JavaScript → MATLAB:** Via CustomEvent dispatching
```javascript
var event = new CustomEvent('ButtonClicked', {
    detail: JSON.stringify({
        clickCount: 1,
        timestamp: new Date().toISOString(),
        variant: 'primary'
    })
});
htmlComponent.dispatchEvent(event);
```

## Troubleshooting

**Issue:** CSS not loading
- **Solution:** Ensure flowbite-ui.css is in `web/` directory and properly compiled from ui-build

**Issue:** Button not responding to clicks
- **Solution:** Check browser console for JavaScript errors; verify Flowbite library is loaded

**Issue:** Variant classes not applying
- **Solution:** Rebuild CSS in ui-build directory and copy to web/
