# Installation

Get started with the bioctree UI Library in just a few steps.

## Prerequisites

- **MATLAB R2020b or later** - Required for `ComponentContainer` support
- **Modern web browser** - For component rendering (Chrome, Firefox, Safari, or Edge)
- **Git** (optional) - For cloning the repository

## Installation Methods

### Method 1: Clone from GitHub (Recommended)

```bash
git clone https://github.com/DiellorBasha/bioctree-ui-library.git
cd bioctree-ui-library
```

Then in MATLAB:

```matlab
% Add components to path
addpath(genpath('components'));

% Verify installation
which d3Brush
```

### Method 2: Download ZIP

1. Download the [latest release](https://github.com/DiellorBasha/bioctree-ui-library/releases)
2. Extract the ZIP file to your desired location
3. Add to MATLAB path:

```matlab
addpath(genpath('path/to/bioctree-ui-library/components'));
savepath;  % Optional: Save path permanently
```

### Method 3: MATLAB Toolbox (Coming Soon)

A packaged MATLAB toolbox will be available for easy installation via MATLAB's Add-On Manager.

## Verify Installation

Test that everything is working:

```matlab
% Create a test figure
fig = uifigure('Position', [100 100 600 300]);

% Create a d3Brush component
brush = d3Brush(fig, 'Position', [50 50 500 200]);

% If the brush appears, installation was successful!
```

## Project Structure

After installation, you'll have:

```
bioctree-ui-library/
├── components/           # Component implementations
│   └── @d3Brush/        # d3Brush component
├── lib/                 # Shared libraries
│   ├── d3/             # D3.js versions
│   └── assets/         # Shared resources
├── tests/              # Test suites
│   ├── html/           # Browser tests
│   └── matlab/         # MATLAB tests
├── docs/               # Documentation source
├── manifest.json       # Dependency manifest
└── README.md           # Project overview
```

## Path Configuration

### Temporary Path (Session Only)

Add components for the current MATLAB session:

```matlab
addpath(genpath('path/to/bioctree-ui-library/components'));
```

### Permanent Path

Save the path permanently:

```matlab
addpath(genpath('path/to/bioctree-ui-library/components'));
savepath;
```

### Startup Script

Add to your `startup.m` file:

```matlab
% startup.m
addpath(genpath('path/to/bioctree-ui-library/components'));
```

## Updating

### Git Users

```bash
cd bioctree-ui-library
git pull origin main
```

### ZIP Users

1. Download the latest release
2. Replace your existing files
3. Clear MATLAB's class cache: `clear classes`
4. Restart MATLAB if you experience issues

## Troubleshooting

### Component Not Found

**Error:** `Undefined function or variable 'd3Brush'`

**Solution:**
```matlab
% Check if path is set
which d3Brush

% If empty, add to path
addpath(genpath('path/to/bioctree-ui-library/components'));
```

### HTML File Not Found

**Error:** `Unable to load HTML file`

**Solution:**
- Ensure the entire component folder structure is intact
- Verify `d3Brush.html` exists in `controllers/@d3Brush/`
- Check file permissions

### Class Definition Issues

**Error:** `Unable to reload class definition`

**Solution:**
```matlab
% Clear class cache
clear classes

% If that doesn't work, restart MATLAB
```

### Version Conflicts

**Error:** Issues with existing D3.js or conflicting libraries

**Solution:**
- Each component bundles its own D3.js version in `vendor/`
- Check `manifest.json` for version information
- Avoid adding global D3.js to the MATLAB path

## Next Steps

Now that you're set up, continue with:

- [Quick Start Guide](quick-start.md) - Build your first component
- [Architecture Overview](architecture.md) - Understand the design
- [d3Brush Documentation](../components/d3brush.md) - Explore the first component

## Getting Help

- **Documentation:** This site
- **Examples:** `tests/matlab/manual_test_d3Brush.m`
- **Issues:** [GitHub Issues](https://github.com/DiellorBasha/bioctree-ui-library/issues)
