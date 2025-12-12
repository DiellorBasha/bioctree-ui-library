# bioctree UI Library

Welcome to the **bioctree UI Library** documentation! This library provides custom UI components built with D3.js for seamless integration with MATLAB.

## Overview

The bioctree UI Library is a collection of interactive, data-driven UI components that bridge the gap between MATLAB's powerful computational capabilities and D3.js's sophisticated visualization framework. Each component is designed as a MATLAB class that embeds HTML, CSS, and JavaScript to create rich, interactive user interfaces.

## Key Features

- 🎨 **Rich Visualizations** - Leverage D3.js for sophisticated data visualizations
- 🔄 **Bidirectional Communication** - Seamless data flow between MATLAB and JavaScript
- 📦 **Component-Based Architecture** - Modular, reusable components
- 🧪 **Comprehensive Testing** - Both MATLAB and browser-based test suites
- 📚 **Well-Documented** - Extensive documentation and examples
- 🔒 **Version Management** - Explicit dependency versioning to prevent conflicts

## Components

### d3Brush

An interactive brush component for selecting ranges on a continuous scale with snapping support.

[View Documentation →](components/d3brush.md){ .md-button .md-button--primary }

## Quick Start

```matlab
% Create a figure
fig = uifigure('Position', [100 100 600 300]);

% Create a d3Brush component
brush = d3Brush(fig, 'Position', [50 50 500 200]);

% Configure properties
brush.Min = 0;
brush.Max = 100;
brush.SnapInterval = 5;
brush.Value = [20, 60];

% Set up callback
brush.ValueChangedFcn = @(src, event) disp(event.Value);
```

## Architecture

Each component follows a standardized structure:

- **MATLAB Class** - Extends `ComponentContainer` for MATLAB integration
- **HTML Template** - Shadow DOM-like encapsulation
- **CSS Styles** - Component-specific styling
- **Controller (JS)** - Lifecycle management and MATLAB communication
- **Renderer (JS)** - Pure D3.js visualization logic
- **Vendor Dependencies** - Component-specific bundled libraries

## Project Structure

```
bioctree-ui-library/
├── components/           # Component implementations
│   └── @d3Brush/        # d3Brush component
│       ├── d3Brush.m    # MATLAB class
│       ├── d3Brush.html # HTML template
│       ├── d3Brush.css  # Styles
│       ├── d3Brush.js   # Controller
│       ├── d3Brush.render.js  # Renderer
│       └── vendor/      # Bundled dependencies
├── lib/                 # Shared libraries
├── tests/              # Test suites
│   ├── html/           # Browser-based tests
│   └── matlab/         # MATLAB unit tests
├── docs/               # Documentation
└── manifest.json       # Dependency tracking
```

## Getting Started

Ready to dive in? Check out our guides:

- [Installation Guide](getting-started/installation.md) - Set up the library
- [Quick Start Tutorial](getting-started/quick-start.md) - Build your first component
- [Architecture Overview](getting-started/architecture.md) - Understand the design

## Contributing

We welcome contributions! See our [Contributing Guide](development/contributing.md) for details on:

- Adding new components
- Testing requirements
- Documentation standards
- Code style guidelines

## Support

- **Issues**: [GitHub Issues](https://github.com/DiellorBasha/bioctree-ui-library/issues)
- **Documentation**: This site
- **Examples**: [Examples Section](examples/basic-usage.md)

## License

[Your License Here]
