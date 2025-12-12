/* HorizonChart Rendering Logic
 * Horizon chart visualization using Observable Plot v0.6.17
 * 
 * Implements horizon chart pattern:
 * - Multiple area layers (bands) stacked vertically
 * - Each band represents a value range (step)
 * - Uses Plot.areaY with faceting (fy) for multiple series
 * - d3.range() generates band indices
 * - Plot.axisFy for series labels
 * 
 * Observable Plot Version: 0.6.17 (UMD build)
 * D3.js: Required dependency (UMD build)
 */

function renderHorizonChart(viewData, retryCount) {
    // Track retry attempts (default to 0)
    retryCount = retryCount || 0;
    var maxRetries = 20;
    
    // Validate data object
    if (!viewData || typeof viewData !== 'object') {
        console.error('[renderHorizonChart] Invalid data object:', viewData);
        return;
    }
    
    // Get the container
    var container = document.querySelector('.horizon-container');
    
    if (!container) {
        console.error('[renderHorizonChart] Container not found');
        return;
    }
    
    // Clear previous visualization
    container.innerHTML = '';
    
    // Get dimensions
    var containerWidth = container.getBoundingClientRect().width;
    var containerHeight = container.getBoundingClientRect().height;
    
    // Validate container has valid dimensions
    if (containerWidth <= 0 || containerHeight <= 0) {
        if (retryCount < maxRetries) {
            console.warn('[renderHorizonChart] Container has invalid dimensions:', containerWidth, 'x', containerHeight, '- retry', (retryCount + 1));
            setTimeout(function() {
                renderHorizonChart(viewData, retryCount + 1);
            }, 50);
        } else {
            console.error('[renderHorizonChart] Failed to get valid container dimensions after', maxRetries, 'retries');
        }
        return;
    }
    
    console.log('[renderHorizonChart] Rendering with dimensions:', containerWidth, 'x', containerHeight);
    
    // Extract data and parameters
    var data = viewData.data || [];
    var bands = viewData.bands || 3;
    var step = viewData.step || 0;
    var colorScheme = viewData.colorScheme || "Greens";
    var showLegend = viewData.showLegend !== false;
    
    // Handle empty data
    if (!data || data.length === 0) {
        console.warn('[renderHorizonChart] No data to display');
        var svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        svg.setAttribute('width', containerWidth);
        svg.setAttribute('height', containerHeight);
        
        var text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
        text.setAttribute('x', containerWidth / 2);
        text.setAttribute('y', containerHeight / 2);
        text.setAttribute('text-anchor', 'middle');
        text.setAttribute('fill', '#999');
        text.textContent = 'No data to display';
        
        svg.appendChild(text);
        container.appendChild(svg);
        return;
    }
    
    // Parse dates (convert ISO strings to Date objects)
    data.forEach(function(d) {
        d.date = new Date(d.date);
    });
    
    // Auto-calculate step if not provided
    if (step === 0) {
        var maxValue = d3.max(data, function(d) { return d.value; });
        step = maxValue / bands;
    }
    
    console.log('[renderHorizonChart] Configuration:', {
        dataPoints: data.length,
        bands: bands,
        step: step,
        colorScheme: colorScheme
    });
    
    // Get unique series names for faceting
    var uniqueNames = Array.from(new Set(data.map(function(d) { return d.name; })));
    
    // Create the horizon chart
    try {
        var plot = Plot.plot({
            width: containerWidth,
            height: containerHeight,
            marginLeft: 120,
            x: {
                axis: "top",
                label: null
            },
            y: {
                domain: [0, step],
                axis: null
            },
            fy: {
                axis: null,
                domain: uniqueNames,
                padding: 0.05
            },
            color: {
                type: "ordinal",
                scheme: colorScheme,
                label: "Value per band",
                tickFormat: function(i) {
                    return ((i + 1) * step).toLocaleString("en");
                },
                legend: showLegend
            },
            marks: [
                // Create area layers for each band
                d3.range(bands).map(function(band) {
                    return Plot.areaY(data, {
                        x: "date",
                        y: function(d) { return d.value - band * step; },
                        fy: "name",
                        fill: band,
                        sort: "date",
                        clip: true
                    });
                }),
                // Add facet axis labels on the left
                Plot.axisFy({
                    frameAnchor: "left",
                    dx: -28,
                    fill: "currentColor",
                    textStroke: "white",
                    label: null
                })
            ]
        });
        
        // Append plot to container
        container.appendChild(plot);
        
        console.log('[renderHorizonChart] Complete - ' + data.length + ' points, ' + uniqueNames.length + ' series, ' + bands + ' bands');
    } catch (error) {
        console.error('[renderHorizonChart] Error creating plot:', error);
        container.innerHTML = '<div style="color: red; padding: 20px;">Error rendering horizon chart: ' + error.message + '</div>';
    }
}
