/* DensityStrip Rendering Logic
 * One-dimensional density strip visualization using Observable Plot v0.6.17
 * 
 * Uses UMD build with Plot.density() for 1D density visualization:
 * - Plot.density(data, { x: d => d, ... }) creates 1D density along x-axis
 * - bandwidth: Controls KDE smoothing
 * - thresholds: Number of contour levels
 * - stroke/fill: Visual styling
 * 
 * Observable Plot Version: 0.6.17 (UMD build from lib/observable-plot)
 * D3.js: Loaded separately (required by Plot UMD)
 */

function renderDensity(viewData, retryCount) {
    // Track retry attempts (default to 0)
    retryCount = retryCount || 0;
    var maxRetries = 20;
    
    // Validate data object
    if (!viewData || typeof viewData !== 'object') {
        console.error('[renderDensity] Invalid data object:', viewData);
        return;
    }
    
    // Get the container
    var container = document.querySelector('.density-container');
    
    if (!container) {
        console.error('[renderDensity] Container not found');
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
            console.warn('[renderDensity] Container has invalid dimensions:', containerWidth, 'x', containerHeight, '- retry', (retryCount + 1));
            setTimeout(function() {
                renderDensity(viewData, retryCount + 1);
            }, 50);
        } else {
            console.error('[renderDensity] Failed to get valid container dimensions after', maxRetries, 'retries');
        }
        return;
    }
    
    console.log('[renderDensity] Rendering with dimensions:', containerWidth, 'x', containerHeight);
    
    // Extract data and parameters
    var data = viewData.data || [];
    var bandwidth = viewData.bandwidth || 10;
    var color = viewData.color || "steelblue";
    var showDots = viewData.showDots !== false;
    var showContours = viewData.showContours !== false;
    var thresholds = viewData.thresholds || 4;
    
    // Handle empty data
    if (!data || data.length === 0) {
        console.warn('[renderDensity] No data to display');
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
    
    // Build marks array based on display options
    var marks = [];
    
    // Use Plot.density() for 1D density visualization
    // Following Observable Plot pattern: separate calls for outline and contours
    if (showContours) {
        // Density outline (thin stroke)
        marks.push(
            Plot.density(data, {
                x: function(d) { return d; },
                stroke: color,
                strokeWidth: 0.25,
                bandwidth: bandwidth
            })
        );
        
        // Density contour bands
        marks.push(
            Plot.density(data, {
                x: function(d) { return d; },
                stroke: color,
                thresholds: thresholds || 4,
                bandwidth: bandwidth
            })
        );
    }
    
    // Add individual data points as dots
    if (showDots) {
        marks.push(
            Plot.dot(data, {
                x: function(d) { return d; },
                fill: "currentColor",
                r: 1.5
            })
        );
    }
    
    // Create the plot
    try {
        var plot = Plot.plot({
            width: containerWidth,
            height: containerHeight,
            inset: 10,
            marks: marks,
            x: {
                label: null,
                grid: false
            },
            y: {
                axis: null,
                domain: [0, null]
            },
            style: {
                fontSize: "12px"
            }
        });
        
        // Append plot to container
        container.appendChild(plot);
        
        console.log('[renderDensity] Complete - ' + data.length + ' points, bandwidth: ' + bandwidth + ', thresholds: ' + thresholds);
    } catch (error) {
        console.error('[renderDensity] Error creating plot:', error);
        container.innerHTML = '<div style="color: red; padding: 20px;">Error rendering density plot: ' + error.message + '</div>';
    }
}
