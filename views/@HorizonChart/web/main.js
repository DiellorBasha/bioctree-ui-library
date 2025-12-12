/* HorizonChart Controller
 * Simplified VIEW pattern - DataChanged listener only
 * No event dispatching (one-way data flow)
 */

function setup(htmlComponent) {
    console.log('[HorizonChart] setup() called');
    
    var data = htmlComponent.Data;
    renderHorizonChart(data);
    
    htmlComponent.addEventListener("DataChanged", function(event) {
        console.log('[HorizonChart] DataChanged event received');
        renderHorizonChart(htmlComponent.Data);
    });
}
