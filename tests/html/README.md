# Browser Testing Guide for D3 UI Components

This directory contains HTML test files for validating D3.js UI components in the browser before MATLAB integration.

## Purpose

Browser testing allows you to:
- Validate HTML, CSS, and JavaScript rendering
- Test D3.js interactions and animations
- Verify event handling and data flow
- Debug visual issues quickly
- Test edge cases and error handling

## Running Tests

### Method 1: Direct File Opening
1. Navigate to `tests/html/`
2. Open `test_d3_brush.html` in your browser
3. Open browser DevTools (F12) to see console logs
4. Interact with the test cases

### Method 2: Local Server (Recommended)
Using a local server prevents CORS issues and simulates production environment:

```powershell
# Using Python
cd tests/html
python -m http.server 8000

# Using Node.js (http-server)
cd tests/html
npx http-server -p 8000

# Using PHP
cd tests/html
php -S localhost:8000
```

Then open: `http://localhost:8000/test_d3_brush.html`

## Test Structure

Each test file contains multiple test cases:

### Test 1: Basic Rendering
- Verifies component renders with default values
- Checks SVG creation
- Validates initial selection display

### Test 2: Dynamic Property Updates
- Tests updating min, max, snapInterval values
- Validates selection range updates
- Checks component redraws correctly

### Test 3: Event Handling
- Tests BrushStarted event
- Tests BrushMoving events (during drag)
- Tests ValueChanged event (on release)
- Validates event data structure

### Test 4: Edge Cases & Validation
- Null/undefined data handling
- Invalid range (min >= max)
- Zero-size containers
- Invalid snap intervals
- Boundary conditions

### Test 5: Responsive Sizing
- Tests component resizing
- Validates responsive behavior
- Checks layout at different dimensions

## Mock HTML Component

Tests use a mock object that simulates MATLAB's `htmlComponent`:

```javascript
const mockComponent = {
    Data: null,
    addEventListener: function(eventName, callback) { },
    dispatchEvent: function(event) {
        // Logs events to test UI and console
    }
};
```

This allows testing the JavaScript layer independently from MATLAB.

## Debugging Tips

### Console Logging
All component functions use prefixed console logs:
- `[D3 Brush Rendering]` - Rendering script messages
- `[D3 Brush]` - HTML setup messages
- `[drawBrush]` - Drawing function messages
- `[Mock]` - Mock component messages
- `[Test Suite]` - Test harness messages

### Common Issues

**D3.js not loading:**
- Check browser console for 404 errors
- Verify path to `../../lib/d3/d3.min.js`
- Use a local server instead of `file://` protocol

**Component not rendering:**
- Check container dimensions (must be > 0)
- Verify data object structure
- Look for JavaScript errors in console

**Events not firing:**
- Check if htmlComponent mock is properly set up
- Verify event names match MATLAB expectations
- Check event data JSON structure

## Test Checklist

Before moving to MATLAB integration, verify:

- [ ] Component renders with default values
- [ ] SVG elements are created properly
- [ ] Brush can be dragged and resized
- [ ] Snap-to-grid works as expected
- [ ] All events fire correctly (BrushStarted, BrushMoving, ValueChanged)
- [ ] Event data structure matches MATLAB expectations
- [ ] Invalid data is handled gracefully
- [ ] Component resizes responsively
- [ ] CSS styles render correctly
- [ ] No console errors during normal operation
- [ ] Edge cases don't crash the component

## Creating New Tests

To test a new component:

1. Create `test_ComponentName.html` in this directory
2. Include D3.js library: `<script src="../../lib/d3/d3.min.js"></script>`
3. Include component files (CSS, JS, HTML)
4. Create mock htmlComponent object
5. Set up test cases with different scenarios
6. Add controls for manual interaction
7. Add event logging for validation

## Next Steps

After browser validation passes:
1. Move to MATLAB integration tests in `tests/matlab/`
2. Test component in MATLAB uifigure
3. Test in App Designer
4. Test property synchronization
5. Test event callbacks
6. Test lifecycle (creation, update, deletion)

## Browser Compatibility

Tested in:
- Chrome/Edge (Chromium)
- Firefox
- Safari

D3.js v7 requires modern browsers with ES6+ support.
