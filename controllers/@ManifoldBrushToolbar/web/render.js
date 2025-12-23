/**
 * Renders the toolbar with brush tools
 * @param {Object} data - Toolbar data from MATLAB
 * @param {Object} data.tools - Array of tool definitions [{id, icon, label, active}]
 * @param {string} data.orientation - 'vertical' or 'horizontal'
 * @param {HTMLElement} htmlComponent - MATLAB HTML component
 */
function renderToolbar(data, htmlComponent) {
    console.log('[ManifoldBrushToolbar] renderToolbar called');
    console.log('[ManifoldBrushToolbar] Toolbar data:', data);
    console.log('[ManifoldBrushToolbar] Number of tools:', data ? data.tools ? data.tools.length : 0 : 0);
    console.log('[ManifoldBrushToolbar] Orientation:', data ? data.orientation : 'undefined');
    
    if (!data || !data.tools || !Array.isArray(data.tools)) {
        console.warn('[ManifoldBrushToolbar] Invalid data structure');
        return;
    }
    
    var container = document.getElementById('toolbar-container');
    if (!container) {
        console.error('[ManifoldBrushToolbar] Container not found');
        return;
    }
var toolSize = 28;
var iconSize = 16;
var toolSpacing = 4;

    var dividerSize = 2;   // Divider line thickness
    var dividerSpacing = 4; // Extra spacing around dividers
    var iconOffset = (toolSize - iconSize) / 2;
    var orientation = data.orientation || 'vertical';
    
    console.log('[ManifoldBrushToolbar] Orientation:', orientation);
    console.log('[ManifoldBrushToolbar] Tool count:', data.tools.length);
    
    // Calculate SVG dimensions based on orientation, accounting for dividers
    var width, height;
    var totalSize = 0;
    for (var i = 0; i < data.tools.length; i++) {
        if (data.tools[i].isDivider) {
            totalSize += dividerSize + 2 * dividerSpacing;
        } else {
            totalSize += toolSize + toolSpacing;
        }
    }
    
    if (orientation === 'horizontal') {
        width = totalSize + toolSpacing;
        height = toolSize + 2 * toolSpacing;
    } else {
        width = toolSize + 2 * toolSpacing;
        height = totalSize + toolSpacing;
    }
    
    console.log('[ManifoldBrushToolbar] SVG dimensions:', width, 'x', height);
    
    // Clear previous SVG within this container only
    d3.select(container).select('#toolbar').remove();
    
    // Create SVG with viewBox and explicit pixel dimensions
    // This prevents MATLAB uihtml from rescaling the toolbar
    var svg = d3.select(container)
        .append('svg')
        .attr('id', 'toolbar')
        .attr('viewBox', '0 0 ' + width + ' ' + height)
        .attr('preserveAspectRatio', 'xMinYMin meet')
        .style('width', width + 'px')
        .style('height', height + 'px');
    
    // Create tool groups with position tracking for dividers
    var currentPos = toolSpacing;
    var tools = svg.selectAll('.tool')
        .data(data.tools)
        .enter()
        .append('g')
        .attr('class', function(d) { 
            if (d.isDivider) {
                return 'divider';
            }
            return 'tool' + (d.active ? ' active' : '');
        })
        .attr('transform', function(d, i) {
            var x, y;
            if (orientation === 'horizontal') {
                x = currentPos;
                y = toolSpacing;
                if (d.isDivider) {
                    currentPos += dividerSize + 2 * dividerSpacing;
                } else {
                    currentPos += toolSize + toolSpacing;
                }
            } else {
                x = toolSpacing;
                y = currentPos;
                if (d.isDivider) {
                    currentPos += dividerSize + 2 * dividerSpacing;
                } else {
                    currentPos += toolSize + toolSpacing;
                }
            }
            return 'translate(' + x + ',' + y + ')';
        })
        .on('click', function(d) {
            if (!d.isDivider) {
                handleToolClick(d);
            }
        });
    
    // Add rectangles for tools (not dividers)
    tools.filter(function(d) { return !d.isDivider; })
        .append('rect')
        .attr('width', toolSize)
        .attr('height', toolSize)
        .attr('rx', 4);
    
    // Add divider lines
    tools.filter(function(d) { return d.isDivider; })
        .append('rect')
        .attr('class', 'divider-line')
        .attr('x', function() {
            return orientation === 'horizontal' ? dividerSpacing : (toolSize - dividerSize) / 2;
        })
        .attr('y', function() {
            return orientation === 'horizontal' ? (toolSize - dividerSize) / 2 : dividerSpacing;
        })
        .attr('width', function() {
            return orientation === 'horizontal' ? dividerSize : toolSize;
        })
        .attr('height', function() {
            return orientation === 'horizontal' ? toolSize : dividerSize;
        })
        .attr('rx', 1);
    
    // Add icons (SVG embedded as images) for tools only
    tools.filter(function(d) { return !d.isDivider; })
        .append('image')
        .attr('x', iconOffset)
        .attr('y', iconOffset)
        .attr('width', iconSize)
        .attr('height', iconSize)
        .attr('href', function(d) {
            // If icon already has a path, use it as-is (for tests)
            // Otherwise, prepend vendor/icons/ (for production)
            if (d.icon.includes('/')) {
                return d.icon;
            }
            return 'vendor/icons/' + d.icon;
        })
        .attr('title', function(d) { return d.label; });
    
    // Click handler (separate function like d3Brush pattern)
    function handleToolClick(d) {
        // Send event to MATLAB using sendEventToMATLAB with two parameters
        if (htmlComponent && htmlComponent.sendEventToMATLAB) {
            htmlComponent.sendEventToMATLAB('ToolClicked', { id: d.id, label: d.label });
        }
    }
    
    // console.log('[ManifoldBrushToolbar] Render complete');
}
