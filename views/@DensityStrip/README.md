# DensityStrip View

One-dimensional density visualization view component for displaying data distributions using kernel density estimation (KDE).

## Overview

DensityStrip is a **VIEW component** (read-only, one-way data flow) that visualizes the density distribution of 1D numeric data. It shows:
- Individual data points as dots
- Smooth density curve using kernel density estimation
- Density contours at multiple threshold levels
- Customizable bandwidth, colors, and display options

Based on: [Observable Plot One-Dimensional Density](https://observablehq.com/@observablehq/plot-one-dimensional-density)

## View Component Architecture

**DensityStrip is a VIEW, not an interactive component:**
- ❌ No events
- ❌ No callbacks
- ❌ No bidirectional communication
- ✅ One-way data flow (MATLAB → JavaScript only)
- ✅ Pure data visualization

## Installation

Ensure the views directory is on your MATLAB path:

```matlab
addpath(genpath('path/to/bioctree-ui-library/views'));
```

## Basic Usage

### Simple Example

```matlab
% Create a figure
fig = uifigure('Position', [100 100 800 300]);

% Create density view with sample data
data = randn(100, 1) * 20 + 50;  % Normal distribution
densityView = DensityStrip(fig, 'Position', [50 50 700 200]);
densityView.Data = data;
```

### With Custom Styling

```matlab
% Create figure
fig = uifigure('Position', [100 100 800 300]);

% Create view
densityView = DensityStrip(fig, 'Position', [50 50 700 200]);

% Set properties
densityView.Data = randn(200, 1) * 15 + 75;
densityView.Title = "Temperature Distribution (°F)";
densityView.Bandwidth = 5;
densityView.Color = "coral";
densityView.Thresholds = 6;
```

## Properties

### Data
- **Type:** `double` column vector
- **Default:** `[]`
- **Description:** 1D numeric data to visualize

```matlab
densityView.Data = [45, 50, 52, 48, 55, 60, 58, 62, 65, 70];
```

### Title
- **Type:** `string`
- **Default:** `"Density Distribution"`
- **Description:** Title displayed above the visualization

```matlab
densityView.Title = "Waiting Time Distribution";
```

### Bandwidth
- **Type:** `double` (positive scalar)
- **Default:** `10`
- **Description:** Kernel density estimation bandwidth (controls smoothness)

Larger bandwidth = smoother curve, smaller bandwidth = more detail

```matlab
densityView.Bandwidth = 5;  % More detail
densityView.Bandwidth = 20; % Smoother
```

### Color
- **Type:** `string`
- **Default:** `"steelblue"`
- **Description:** Color for density visualization (CSS color name or hex)

```matlab
densityView.Color = "coral";
densityView.Color = "#ff6b6b";
```

### ShowDots
- **Type:** `logical`
- **Default:** `true`
- **Description:** Show individual data points at the bottom

```matlab
densityView.ShowDots = false;  % Hide dots
```

### ShowDensityLine
- **Type:** `logical`
- **Default:** `true`
- **Description:** Show the density curve line

```matlab
densityView.ShowDensityLine = false;  % Hide density line
```

### ShowContours
- **Type:** `logical`
- **Default:** `true`
- **Description:** Show density contour levels

```matlab
densityView.ShowContours = false;  % Hide contours
```

### Thresholds
- **Type:** `double` (positive integer)
- **Default:** `4`
- **Description:** Number of density contour levels to display

```matlab
densityView.Thresholds = 6;  % More contour levels
```

## Examples

### Multiple Distributions Comparison

```matlab
fig = uifigure('Position', [100 100 900 600]);

% Dataset 1
data1 = randn(150, 1) * 10 + 50;
view1 = DensityStrip(fig, 'Position', [50 400 800 150]);
view1.Data = data1;
view1.Title = "Distribution A";
view1.Color = "steelblue";

% Dataset 2
data2 = randn(150, 1) * 15 + 70;
view2 = DensityStrip(fig, 'Position', [50 200 800 150]);
view2.Data = data2;
view2.Title = "Distribution B";
view2.Color = "coral";
```

### Dynamic Data Update

```matlab
fig = uifigure('Position', [100 100 800 300]);
view = DensityStrip(fig, 'Position', [50 50 700 200]);

% Start with initial data
view.Data = randn(100, 1) * 20 + 50;

% Update data (view automatically refreshes)
view.Data = randn(200, 1) * 15 + 60;
view.Bandwidth = 8;
view.Color = "purple";
```

### High Detail vs Smooth

```matlab
fig = uifigure('Position', [100 100 900 600]);

data = randn(300, 1) * 20 + 50;

% High detail (small bandwidth)
view1 = DensityStrip(fig, 'Position', [50 400 800 150]);
view1.Data = data;
view1.Title = "High Detail (Bandwidth = 3)";
view1.Bandwidth = 3;

% Smooth (large bandwidth)
view2 = DensityStrip(fig, 'Position', [50 200 800 150]);
view2.Data = data;
view2.Title = "Smooth (Bandwidth = 20)";
view2.Bandwidth = 20;
```

## Technical Details

### Dependencies

- **D3.js Version:** 7.9.0 (only for data loading with d3.tsv, not required by Plot)
- **Observable Plot Version:** 0.6.17+ (loaded via CDN ES module using +esm endpoint)
- **Visualization Library:** Observable Plot's native Plot.densityX() for 1D density
- **Visualization Library:** Observable Plot for density marks

### Component Files

```
@DensityStrip/
├── DensityStrip.m         # MATLAB class
├── README.md              # This file
└── web/
    ├── index.html         # HTML entry point (loads Plot via ES module)
    ├── main.js            # Simplified controller (DataChanged only)
    ├── render.js          # Observable Plot visualization
    ├── styles.css         # View styles
    └── vendor/
        └── d3.v7.9.0.min.js           # D3.js v7 (for data loading only)
        
**Note:** Observable Plot is loaded via CDN using ES module (+esm) endpoint:
```html
<script type="module">
  import * as Plot from "https://cdn.jsdelivr.net/npm/@observablehq/plot@0.6.17/+esm";
  window.Plot = Plot;  // Expose globally
</script>
```

This ensures `Plot.densityX()` is available (not included in UMD builds).
```

### View Constraints

As a VIEW component, DensityStrip:
- Has NO `events` block in MATLAB class
- Has NO callback properties (e.g., no `ValueChangedFcn`)
- Does NOT dispatch events back to MATLAB
- Does NOT set `HTMLEventReceivedFcn`
- Only implements `setup()` and `update()` methods
- Only communicates via `HTMLComponent.Data` (one-way)

## Algorithm

The view uses **Observable Plot's `Plot.densityX()` mark** for native 1D density visualization:

```javascript
Plot.densityX(data, {
    bandwidth: bandwidth,
    thresholds: thresholds || 4,
    fill: color,
    fillOpacity: 0.25
})
```

**How it works:**
1. `Plot.densityX()` computes native 1D kernel density estimation (KDE) along x-axis
2. Creates stacked density contour bands at different threshold levels
3. Each band represents a density quantile (e.g., 25%, 50%, 75%, 100%)
4. Displays density as filled contour bands with transparency
5. Optionally overlays individual data points as dots

The `Bandwidth` parameter controls the KDE smoothing, and `Thresholds` controls the number of density bands.

**Key Implementation Details:**
- Uses Observable Plot v0.6.17's native `Plot.densityX()` (introduced in v0.6.17+)
- True 1D KDE - no degenerate 2D math or y=0 jitter hacks
- Produces proper density contours without manual computation
- "Contours" are visual density bands representing quantile levels

## Limitations

- Data must be finite numeric values
- Empty data displays "No data to display" message
- Very large datasets (>10,000 points) may have performance impact
- No interactive features (this is a view, not a component)

## See Also

- [Views Documentation](../README.md)
- [Observable Plot Density](https://observablehq.com/@observablehq/plot-one-dimensional-density)
- Component: [d3Brush](../../controllers/@d3Brush/README.md) - Interactive selection component
