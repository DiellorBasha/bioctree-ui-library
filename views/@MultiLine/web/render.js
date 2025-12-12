/* MultiLine Rendering Logic
 * Observable Plot visualization using Observable Plot v0.6.17
 * 
 * Observable Plot Version: 0.6.17 (UMD build)
 * D3.js: Required dependency (UMD build)
 * 
 * Reference: [Add Observable Plot example URL here]
 */

function renderMultiLine(viewData, retryCount) {
    // Track retry attempts (default to 0)
    retryCount = retryCount || 0;
    var maxRetries = 20;
    
    // Validate data object
    if (!viewData || typeof viewData !== 'object') {
        console.error('[renderMultiLine] Invalid data object:', viewData);
        return;
    }
    
    // Get the container
    var container = document.querySelector('.multiline-container');
    
    if (!container) {
        console.error('[renderMultiLine] Container not found');
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
            console.warn('[renderMultiLine] Container has invalid dimensions:', containerWidth, 'x', containerHeight, '- retry', (retryCount + 1));
            setTimeout(function() {
                renderMultiLine(viewData, retryCount + 1);
            }, 50);
        } else {
            console.error('[renderMultiLine] Failed to get valid container dimensions after', maxRetries, 'retries');
        }
        return;
    }
    
    console.log('[renderMultiLine] Rendering with dimensions:', containerWidth, 'x', containerHeight);
    
    // Extract data and parameters
    var data = viewData.data || [];
    
    // Handle empty data
    if (!data || data.length === 0) {
        console.warn('[renderMultiLine] No data to display');
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
    
    try {
        // Create Observable Plot visualization for multiple line chart
        // Groups tidy data into series using the z channel (or stroke, or fill)
        var plot = Plot.plot({
            width: containerWidth,
            height: containerHeight,
            y: {
                grid: true,
                label: "↑ Unemployment (%)"
            },
            marks: [
                Plot.ruleY([0]),
                Plot.lineY(data, {
                    x: "date",
                    y: "unemployment",
                    z: "division"
                })
            ]
        });
        
        container.appendChild(plot);
        
        console.log('[renderMultiLine] Complete - ' + data.length + ' data points');
    } catch (error) {
        console.error('[renderMultiLine] Error creating plot:', error);
        container.innerHTML = '<div style="color: red; padding: 20px;">Error rendering plot: ' + error.message + '</div>';
    }
}
