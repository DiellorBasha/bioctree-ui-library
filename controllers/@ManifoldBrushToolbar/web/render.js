/**
 * Renders the toolbar with brush tools
 * @param {Object} data - Toolbar data from MATLAB
 * @param {Object} data.tools - Array of tool definitions [{id, icon, label, active}]
 * @param {HTMLElement} htmlComponent - MATLAB HTML component
 */
function renderToolbar(data, htmlComponent) {
    // console.log('[ManifoldBrushToolbar] renderToolbar called');
    // console.log('[ManifoldBrushToolbar] Toolbar data:', data);
    // console.log('[ManifoldBrushToolbar] htmlComponent:', htmlComponent);
    
    if (!data || !data.tools || !Array.isArray(data.tools)) {
        // console.warn('[ManifoldBrushToolbar] Invalid data structure');
        return;
    }
    
    var container = document.getElementById('toolbar-container');
    if (!container) {
        // console.error('[ManifoldBrushToolbar] Container not found');
        return;
    }
    
    var toolSize = 40;     // Reduced from 48
    var toolSpacing = 6;   // Reduced from 8
    var iconSize = 24;     // Reduced from 32
    var iconOffset = (toolSize - iconSize) / 2;
    
    // Calculate SVG dimensions
    var width = toolSize + 2 * toolSpacing;
    var height = data.tools.length * (toolSize + toolSpacing) + toolSpacing;
    
    // Clear previous SVG
    d3.select('#toolbar').remove();
    
    // Create SVG
    var svg = d3.select(container)
        .append('svg')
        .attr('id', 'toolbar')
        .attr('width', width)
        .attr('height', height);
    
    // Create tool groups
    var tools = svg.selectAll('.tool')
        .data(data.tools)
        .enter()
        .append('g')
        .attr('class', function(d) { 
            return 'tool' + (d.active ? ' active' : '');
        })
        .attr('transform', function(d, i) {
            var x = toolSpacing;
            var y = toolSpacing + i * (toolSize + toolSpacing);
            return 'translate(' + x + ',' + y + ')';
        })
        .on('click', handleToolClick);
    
    // Add rectangles
    tools.append('rect')
        .attr('width', toolSize)
        .attr('height', toolSize)
        .attr('rx', 6);
    
    // Add icons (SVG embedded as images)
    tools.append('image')
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
