# MultiLine View

## Description
A multiple line chart visualization using Observable Plot. Displays tidy data grouped into multiple line series using the `z` channel (grouping variable). Ideal for showing trends across different categories or divisions.

Based on the Observable Plot Gallery example: [Multiple line chart](https://observablehq.com/@observablehq/plot-gallery?collection=@observablehq/plot-gallery#Multiple%20line%20chart)

## Dependencies
- **Observable Plot** v0.6.17 (UMD build)
- **D3.js** (UMD build, bundled in web/vendor/)

## Critical Dependency Information
- **Observable Plot Version:** 0.6.17
- **D3.js Version:** Latest from lib/observable-plot/d3.min.js
- **Event Model:** Read-only (no events or callbacks)

## Data Structure
The `Data` property should be a table or struct array with the following columns:

| Column | Type | Description |
|--------|------|-------------|
| `date` | numeric/datetime | X-axis values |
| `unemployment` | numeric | Y-axis values (the metric being visualized) |
| `division` | string/categorical | Grouping variable for different line series |

### Example Usage
```matlab
% Load data from CSV file
dataPath = 'tests/data/bls-metro-unemployment.csv';
T = readtable(dataPath);

% Create the visualization
fig = uifigure('Position', [100 100 1000 600]);
view = MultiLine(fig, 'Position', [50 50 900 500]);
view.Data = T;
```

## Properties
- `Data` - Table or struct array with tidy data (date, unemployment, division columns)

## Features
- Automatic grouping of data by the `division` column
- Grid lines on y-axis for easier reading
- Y-axis label: "↑ Unemployment (%)"
- Automatic line color assignment for each division
- Responsive sizing based on container dimensions

## Implementation Notes
- Visualization uses `Plot.lineY()` with z-channel for grouping
- Includes a reference rule at Y=0 for context
- Observable Plot automatically handles color assignment and legend (if enabled)
- No manual axis configuration needed - Plot provides sensible defaults
