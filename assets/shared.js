/* ============================================================
   Bioctree UI — shared.js
   Shared utilities for MATLAB <-> JavaScript components
   ============================================================ */

/* ------------------------------------------------------------
   1. Messaging Utilities (MATLAB <-> JS)
   ------------------------------------------------------------ */

/**
 * Send a CustomEvent to MATLAB uihtml HTMLEventReceivedFcn
 */
export function sendToMATLAB(htmlComponent, eventName, payload = {}) {
    try {
        let event = new CustomEvent(eventName, {
            detail: JSON.stringify(payload)
        });
        htmlComponent.dispatchEvent(event);
    } catch (err) {
        console.error("[Bioctree][sendToMATLAB] Error:", err);
    }
}

/**
 * Write debug logs both to browser console and optionally MATLAB
 */
export function log(...args) {
    console.log("[Bioctree]", ...args);
}

/**
 * Safe JSON parsing
 */
export function safeParse(json) {
    try {
        return JSON.parse(json);
    } catch (err) {
        console.warn("[Bioctree] Failed to parse JSON:", json);
        return null;
    }
}


/* ------------------------------------------------------------
   2. Tailwind Theme Helpers (Dark/Light)
   ------------------------------------------------------------ */

export function enableDarkMode() {
    document.documentElement.classList.add("dark");
}

export function enableLightMode() {
    document.documentElement.classList.remove("dark");
}

/**
 * Toggle theme
 */
export function toggleTheme() {
    document.documentElement.classList.toggle("dark");
}


/* ------------------------------------------------------------
   3. SVG Icon Injection
   ------------------------------------------------------------ */

/**
 * Inject raw SVG content into a target element
 */
export function injectIcon(targetSelector, svgString) {
    const el = document.querySelector(targetSelector);
    if (el) el.innerHTML = svgString;
    else console.warn("[Bioctree] injectIcon: target not found:", targetSelector);
}

/**
 * Load an external SVG file (D3 brush sometimes requires dynamic loading)
 */
export async function loadSVG(url) {
    try {
        const response = await fetch(url);
        const text = await response.text();
        return text;
    } catch (err) {
        console.error("[Bioctree] Failed to load SVG:", url, err);
        return "";
    }
}


/* ------------------------------------------------------------
   4. D3 Integration Helpers
   ------------------------------------------------------------ */

/**
 * Clamp a value between min and max
 */
export function clamp(x, min, max) {
    return Math.max(min, Math.min(max, x));
}

/**
 * Snap to interval
 */
export function snap(x, interval) {
    return Math.round(x / interval) * interval;
}

/**
 * Notify MATLAB of D3 brush change
 */
export function notifyBrushChange(htmlComponent, selection) {
    sendToMATLAB(htmlComponent, "BrushChanged", {
        type: "brushMove",
        selection: selection
    });
}


/* ------------------------------------------------------------
   5. Component Initialization Utilities
   ------------------------------------------------------------ */

/**
 * Wait for MATLAB htmlComponent.Data to be ready
 */
export function waitForData(htmlComponent, callback) {
    let tries = 0;
    let interval = setInterval(() => {
        if (htmlComponent && htmlComponent.Data) {
            clearInterval(interval);
            callback(htmlComponent.Data);
        }
        if (tries++ > 50) {
            clearInterval(interval);
            console.warn("[Bioctree] waitForData: No data received from MATLAB.");
        }
    }, 50);
}


/**
 * Watch MATLAB DataChanged events
 */
export function attachDataListener(htmlComponent, callback) {
    htmlComponent.addEventListener("DataChanged", () => {
        callback(htmlComponent.Data);
    });
}


/* ------------------------------------------------------------
   6. Error Reporting
   ------------------------------------------------------------ */

/**
 * Report errors to MATLAB console as UIHTML warnings
 */
export function reportError(htmlComponent, msg, err = null) {
    console.error("[Bioctree Error]", msg, err);
    sendToMATLAB(htmlComponent, "JSException", {
        message: msg,
        stack: err?.stack || null
    });
}


/* ------------------------------------------------------------
   7. DOM Utilities
   ------------------------------------------------------------ */

/**
 * Remove all children from an element
 */
export function clearElement(selector) {
    const el = document.querySelector(selector);
    if (el) el.innerHTML = "";
}

/**
 * Create an element with classes
 */
export function createEl(tag, classes = "") {
    const el = document.createElement(tag);
    if (classes) el.className = classes;
    return el;
}
