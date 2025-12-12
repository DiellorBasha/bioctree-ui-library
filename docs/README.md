# MkDocs Documentation

This directory contains the source files for the bioctree UI Library documentation website.

## Building the Documentation

### Prerequisites

Install MkDocs and dependencies:

```bash
pip install -r requirements.txt
```

Or install individually:

```bash
pip install mkdocs mkdocs-material mkdocstrings
```

### Local Development

Serve documentation locally with live reload:

```bash
# From the project root
mkdocs serve
```

Then open http://127.0.0.1:8000/ in your browser.

### Building Static Site

Build the documentation to `site/` directory:

```bash
mkdocs build
```

### Deployment

Deploy to GitHub Pages:

```bash
mkdocs gh-deploy
```

## Documentation Structure

```
docs/
├── index.md                    # Home page
├── getting-started/
│   ├── installation.md         # Installation guide
│   ├── quick-start.md          # Quick start tutorial
│   └── architecture.md         # Architecture overview
├── components/
│   ├── index.md               # Components overview
│   └── d3brush.md             # d3Brush documentation
├── development/
│   ├── contributing.md        # Contributing guide
│   ├── component-structure.md # How to build components
│   ├── testing.md             # Testing guide
│   └── versioning.md          # Versioning strategy
├── api/
│   ├── matlab.md              # MATLAB API reference
│   └── javascript.md          # JavaScript API reference
├── examples/
│   ├── basic-usage.md         # Basic examples
│   └── advanced-features.md   # Advanced examples
└── requirements.txt           # Python dependencies
```

## Writing Documentation

### Markdown Guidelines

Use standard Markdown with Material for MkDocs extensions:

#### Code Blocks

```matlab
% MATLAB code
brush = d3Brush(fig);
```

```javascript
// JavaScript code
function setup(htmlComponent) {
    // ...
}
```

#### Admonitions

```markdown
!!! note
    This is a note.

!!! warning
    This is a warning.

!!! tip
    This is a tip.
```

#### Tabs

```markdown
=== "MATLAB"
    ```matlab
    brush = d3Brush(fig);
    ```

=== "JavaScript"
    ```javascript
    renderBrush(data);
    ```
```

#### Links

```markdown
[Link text](relative/path.md)
[External link](https://example.com)
```

### Adding New Pages

1. Create Markdown file in appropriate directory
2. Add entry to `nav` section in `mkdocs.yml`
3. Link from related pages

Example `mkdocs.yml` entry:

```yaml
nav:
  - Components:
    - Overview: components/index.md
    - d3Brush: components/d3brush.md
    - NewComponent: components/new-component.md  # Add here
```

## Style Guide

### Headings

- Use sentence case for headings
- H1 (#) for page title (once per page)
- H2 (##) for major sections
- H3 (###) for subsections

### Code Examples

- Include working, tested examples
- Show both simple and advanced usage
- Add comments to explain non-obvious code
- Use realistic variable names

### Voice and Tone

- Write in second person ("you")
- Be concise and clear
- Use active voice
- Explain "why" not just "how"

## Configuration

Main configuration in `mkdocs.yml` at project root:

```yaml
site_name: bioctree UI Library
theme:
  name: material
  palette:
    - scheme: default
      primary: indigo
      toggle:
        icon: material/brightness-7
        name: Switch to dark mode
    - scheme: slate
      primary: indigo
      toggle:
        icon: material/brightness-4
        name: Switch to light mode
```

## Contributing to Documentation

When contributing:

1. Follow existing structure and style
2. Test locally with `mkdocs serve`
3. Check all links work
4. Verify code examples run correctly
5. Update table of contents if needed
6. Submit PR with documentation changes

## Resources

- [MkDocs Documentation](https://www.mkdocs.org/)
- [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)
- [Python Markdown Extensions](https://python-markdown.github.io/extensions/)
