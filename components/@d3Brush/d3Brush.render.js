/* d3Brush Rendering Logic
 * Pure D3.js rendering - no lifecycle management
 * Based on https://observablehq.com/@d3/brush-snapping
 * 
 * D3.js Version: 5.9.2
 * Event Model: D3 v5 (uses d3.event global)
 */

function renderBrush(data, htmlComponent, retryCount) {
    // Track retry attempts (default to 0)
    retryCount = retryCount || 0;
    var maxRetries = 20;  // Maximum 20 retries = 1 second total wait
    
    // Validate data object
    if (!data || typeof data !== 'object') {
        console.error('[renderBrush] Invalid data object:', data);
        return;
    }
    
    // Clear any previous brush
    d3.select("svg").remove();
    
    // Get the container
    var container = d3.select('.brush-container');
    
    if (container.empty()) {
        console.error('[renderBrush] Container not found');
        return;
    }
    
    // Get dimensions
    var containerWidth = container.node().getBoundingClientRect().width;
    var containerHeight = container.node().getBoundingClientRect().height;
    
    // Validate container has valid dimensions
    // If dimensions are invalid, retry after a short delay
    if (containerWidth <= 0 || containerHeight <= 0) {
        if (retryCount < maxRetries) {
            console.warn('[renderBrush] Container has invalid dimensions:', containerWidth, 'x', containerHeight, '- retry', (retryCount + 1), 'of', maxRetries);
            setTimeout(function() {
                renderBrush(data, htmlComponent, retryCount + 1);
            }, 50);
        } else {
            console.error('[renderBrush] Failed to get valid container dimensions after', maxRetries, 'retries');
        }
        return;
    }
    
    console.log('[renderBrush] Rendering with dimensions:', containerWidth, 'x', containerHeight);
    
    // Set margins
    var margin = {top: 10, right: 20, bottom: 30, left: 20};
    var width = containerWidth - margin.left - margin.right;
    var height = containerHeight - margin.top - margin.bottom;
    
    // Create SVG
    var svg = container.append('svg')
        .attr('width', containerWidth)
        .attr('height', containerHeight);
    
    var g = svg.append('g')
        .attr('transform', 'translate(' + margin.left + ',' + margin.top + ')');
    
    // Extract parameters from data
    var min = data.min || 0;
    var max = data.max || 100;
    var snapInterval = data.snapInterval || 1;
    var initialSelection = data.initialSelection || [min, max];
    
    // Validate min < max
    if (min >= max) {
        console.error('[renderBrush] Invalid range: min must be less than max', min, max);
        return;
    }
    
    // Validate snapInterval
    if (snapInterval <= 0 || snapInterval > (max - min)) {
        console.warn('[renderBrush] Invalid snapInterval, using 1:', snapInterval);
        snapInterval = 1;
    }
    
    // Create scale
    var xScale = d3.scaleLinear()
        .domain([min, max])
        .rangeRound([0, width]);
    
    // Create custom interval object for snapping (similar to d3.timeHour.every(12))
    var interval = {
        round: function(x) {
            return Math.round(x / snapInterval) * snapInterval;
        },
        floor: function(x) {
            return Math.floor(x / snapInterval) * snapInterval;
        },
        offset: function(x) {
            return x + snapInterval;
        }
    };
    
    // Create axis with grid lines
    var xAxis = function(g) {
        // Background grid
        var gridGroup = g.append('g')
            .attr('class', 'grid')
            .attr('transform', 'translate(0,' + (height - margin.bottom) + ')');
        
        gridGroup.call(d3.axisBottom(xScale)
            .ticks(Math.floor((max - min) / snapInterval))
            .tickSize(-(height - margin.top - margin.bottom))
            .tickFormat(function() { return null; }));
        
        gridGroup.select('.domain')
            .attr('fill', '#ddd')
            .attr('stroke', null);
        
        gridGroup.selectAll('.tick line')
            .attr('class', 'grid-line')
            .attr('stroke', '#fff')
            .attr('stroke-opacity', function(d) {
                // Make major grid lines more prominent
                return (d % (snapInterval * 2) === 0) ? 1 : 0.5;
            });
        
        // Foreground axis with labels
        var axisGroup = g.append('g')
            .attr('class', 'axis')
            .attr('transform', 'translate(0,' + (height - margin.bottom) + ')');
        
        axisGroup.call(d3.axisBottom(xScale)
            .ticks(Math.floor((max - min) / snapInterval / 2))
            .tickPadding(0));
        
        axisGroup.select('.domain').remove();
        
        axisGroup.selectAll('text')
            .attr('x', 0)
            .attr('text-anchor', 'middle');
    };
    
    // Add axis
    g.call(xAxis);
    
    // Create brush with snapping
    var brush = d3.brushX()
        .extent([[0, margin.top], [width, height - margin.bottom]])
        .on("start", brushStarted)
        .on("brush", brushed)
        .on("end", brushEnded);
    
    // Track last valid selection to restore if brush is cleared accidentally
    var lastValidSelection = initialSelection;
    
    // Add brush group
    var brushGroup = g.append('g')
        .attr('class', 'brush')
        .call(brush);
    
    // Set initial brush selection
    if (initialSelection && initialSelection.length === 2) {
        brushGroup.call(brush.move, initialSelection.map(xScale));
    }
    
    // Brush start handler
    function brushStarted() {
        var event = d3.event;  // D3 v5 uses d3.event global, not a parameter
        if (!event || !event.sourceEvent) return;
        
        // Send brushStart event to MATLAB using sendEventToMATLAB
        if (htmlComponent && htmlComponent.sendEventToMATLAB) {
            htmlComponent.sendEventToMATLAB("BrushStarted");
        }
    }
    
    // Brush event handler with snapping (following Observable pattern exactly)
    function brushed() {
        var event = d3.event;  // D3 v5 uses d3.event global, not a parameter
        if (!event || !event.sourceEvent) return; // Only transition after input
        
        var selection = event.selection;
        if (!selection) return;
        
        // Convert pixel coordinates to data coordinates
        var d0 = selection.map(xScale.invert);
        
        // Round to nearest interval
        var d1 = d0.map(interval.round);
        
        // If empty when rounded, use floor instead
        if (d1[0] >= d1[1]) {
            d1[0] = interval.floor(d0[0]);
            d1[1] = interval.offset(d1[0]);
        }
        
        // Apply snapped selection with smooth transition
        d3.select(this).transition()
            .duration(50)  // Reduced for more responsive feel
            .call(brush.move, d1.map(xScale));
        
        // Send brushMove event to MATLAB with selection data
        if (htmlComponent && htmlComponent.sendEventToMATLAB) {
            // Pass selection as JSON in event name to avoid race conditions
            var eventData = JSON.stringify({selection: [d1[0], d1[1]]});
            console.log('[d3Brush] BrushMoving - selection:', [d1[0], d1[1]]);
            htmlComponent.sendEventToMATLAB("BrushMoving:" + eventData);
            
            // Update last valid selection
            lastValidSelection = [d1[0], d1[1]];
        }
    }
    
    function brushEnded() {
        var event = d3.event;  // D3 v5 uses d3.event global, not a parameter
        if (!event) return;
        
        // Only process user-initiated events (ignore programmatic brush.move calls)
        if (!event.sourceEvent) return;
        
        // If brush was cleared (clicked outside), allow it to clear visually
        // but don't send any event to MATLAB (keep the previous value)
        if (!event.selection) {
            console.log('[d3Brush] Brush cleared visually - no event sent to MATLAB');
            // The brush will clear visually (D3's default behavior)
            // but MATLAB retains the last valid value
            return;
        }
        
        // Apply the same snapping logic as brushed() to ensure consistency
        var selection = event.selection;
        var d0 = selection.map(xScale.invert);
        var d1 = d0.map(interval.round);
        
        // If empty when rounded, use floor instead
        if (d1[0] >= d1[1]) {
            d1[0] = interval.floor(d0[0]);
            d1[1] = interval.offset(d1[0]);
        }
        
        // Update last valid selection
        lastValidSelection = [d1[0], d1[1]];
        
        // Send ValueChanged event to MATLAB with snapped selection
        console.log('[d3Brush] BrushEnded - final selection:', d1);
        if (htmlComponent && htmlComponent.sendEventToMATLAB) {
            var eventData = JSON.stringify({selection: [d1[0], d1[1]]});
            htmlComponent.sendEventToMATLAB("ValueChanged:" + eventData);
        }
    }
}
