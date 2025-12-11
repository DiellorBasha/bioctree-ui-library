/**
 * Test Utilities for D3 UI Component Browser Testing
 * Provides mock objects, logging, and validation helpers
 */

// Mock MATLAB htmlComponent
class MockHTMLComponent {
    constructor(containerId, logElementId) {
        this.containerId = containerId;
        this.logElementId = logElementId;
        this.Data = null;
        this.eventListeners = {};
        this.eventHistory = [];
    }
    
    addEventListener(eventName, callback) {
        if (!this.eventListeners[eventName]) {
            this.eventListeners[eventName] = [];
        }
        this.eventListeners[eventName].push(callback);
        console.log(`[MockHTMLComponent] addEventListener: ${eventName}`);
    }
    
    dispatchEvent(event) {
        const eventData = JSON.parse(event.detail);
        this.eventHistory.push({
            type: event.type,
            data: eventData,
            timestamp: Date.now()
        });
        
        // Log to UI
        if (this.logElementId) {
            TestLogger.logEvent(this.logElementId, event.type, eventData);
        }
        
        // Trigger registered listeners
        if (this.eventListeners[event.type]) {
            this.eventListeners[event.type].forEach(callback => {
                callback(event);
            });
        }
        
        console.log(`[MockHTMLComponent] Event dispatched:`, event.type, eventData);
    }
    
    getEventHistory() {
        return this.eventHistory;
    }
    
    clearEventHistory() {
        this.eventHistory = [];
    }
}

// Test Logger
const TestLogger = {
    logEvent(logElementId, eventType, eventData) {
        const logElement = document.getElementById(logElementId);
        if (!logElement) return;
        
        const timestamp = new Date().toLocaleTimeString();
        const logEntry = document.createElement('div');
        logEntry.className = 'event-log-entry';
        logEntry.innerHTML = `[${timestamp}] <span class="event-type">${eventType}</span>: ${JSON.stringify(eventData)}`;
        
        logElement.insertBefore(logEntry, logElement.firstChild);
    },
    
    logMessage(logElementId, message, type = 'info') {
        const logElement = document.getElementById(logElementId);
        if (!logElement) return;
        
        const timestamp = new Date().toLocaleTimeString();
        const colors = {
            'info': '#333',
            'success': 'green',
            'error': 'red',
            'warning': 'orange'
        };
        
        const logEntry = document.createElement('div');
        logEntry.className = 'event-log-entry';
        logEntry.style.color = colors[type] || colors['info'];
        logEntry.textContent = `[${timestamp}] ${message}`;
        
        logElement.insertBefore(logEntry, logElement.firstChild);
    },
    
    clear(logElementId) {
        const logElement = document.getElementById(logElementId);
        if (logElement) {
            logElement.innerHTML = '';
        }
    }
};

// Test Status Reporter
const TestStatus = {
    pass(statusElementId, message = 'Test PASSED') {
        const statusElement = document.getElementById(statusElementId);
        if (!statusElement) return;
        
        statusElement.className = 'test-status pass';
        statusElement.textContent = `✓ ${message}`;
    },
    
    fail(statusElementId, message = 'Test FAILED') {
        const statusElement = document.getElementById(statusElementId);
        if (!statusElement) return;
        
        statusElement.className = 'test-status fail';
        statusElement.textContent = `✗ ${message}`;
    },
    
    clear(statusElementId) {
        const statusElement = document.getElementById(statusElementId);
        if (statusElement) {
            statusElement.className = 'test-status';
            statusElement.textContent = '';
        }
    }
};

// Test Validators
const TestValidators = {
    svgExists(containerId) {
        const svg = document.querySelector(`#${containerId} svg`);
        return svg !== null;
    },
    
    elementExists(selector) {
        return document.querySelector(selector) !== null;
    },
    
    hasClass(selector, className) {
        const element = document.querySelector(selector);
        return element && element.classList.contains(className);
    },
    
    containerHasSize(containerId) {
        const container = document.getElementById(containerId);
        if (!container) return false;
        
        const rect = container.getBoundingClientRect();
        return rect.width > 0 && rect.height > 0;
    },
    
    dataIsValid(data, requiredFields = []) {
        if (!data || typeof data !== 'object') return false;
        
        for (const field of requiredFields) {
            if (!(field in data)) return false;
        }
        
        return true;
    },
    
    rangeIsValid(min, max) {
        return typeof min === 'number' && 
               typeof max === 'number' && 
               min < max;
    },
    
    selectionIsValid(selection, min, max) {
        if (!Array.isArray(selection) || selection.length !== 2) return false;
        
        const [start, end] = selection;
        return typeof start === 'number' && 
               typeof end === 'number' &&
               start >= min && 
               end <= max && 
               start <= end;
    }
};

// Test Data Generator
const TestDataGenerator = {
    validBrushData(overrides = {}) {
        return Object.assign({
            min: 0,
            max: 100,
            snapInterval: 5,
            initialSelection: [20, 60]
        }, overrides);
    },
    
    invalidBrushData(type) {
        const generators = {
            'null': () => null,
            'undefined': () => undefined,
            'invalidRange': () => ({ min: 100, max: 0, snapInterval: 5, initialSelection: [20, 60] }),
            'negativeSnap': () => ({ min: 0, max: 100, snapInterval: -5, initialSelection: [20, 60] }),
            'zeroSnap': () => ({ min: 0, max: 100, snapInterval: 0, initialSelection: [20, 60] }),
            'hugeSnap': () => ({ min: 0, max: 100, snapInterval: 200, initialSelection: [20, 60] }),
            'invalidSelection': () => ({ min: 0, max: 100, snapInterval: 5, initialSelection: [80, 20] }),
            'outOfRangeSelection': () => ({ min: 0, max: 100, snapInterval: 5, initialSelection: [-10, 150] })
        };
        
        return generators[type] ? generators[type]() : null;
    }
};

// Performance Tester
const PerformanceTester = {
    measureRenderTime(renderFunction, iterations = 10) {
        const times = [];
        
        for (let i = 0; i < iterations; i++) {
            const start = performance.now();
            renderFunction();
            const end = performance.now();
            times.push(end - start);
        }
        
        const average = times.reduce((a, b) => a + b, 0) / times.length;
        const min = Math.min(...times);
        const max = Math.max(...times);
        
        return {
            average: average.toFixed(2),
            min: min.toFixed(2),
            max: max.toFixed(2),
            times: times
        };
    },
    
    measureEventThroughput(mockComponent, durationMs = 1000) {
        const startTime = Date.now();
        let eventCount = 0;
        
        const interval = setInterval(() => {
            mockComponent.dispatchEvent(new CustomEvent('TestEvent', {
                detail: JSON.stringify({ count: eventCount })
            }));
            eventCount++;
        }, 10);
        
        return new Promise(resolve => {
            setTimeout(() => {
                clearInterval(interval);
                const endTime = Date.now();
                const actualDuration = endTime - startTime;
                
                resolve({
                    eventCount: eventCount,
                    duration: actualDuration,
                    eventsPerSecond: (eventCount / (actualDuration / 1000)).toFixed(2)
                });
            }, durationMs);
        });
    }
};

// DOM Helpers
const DOMHelpers = {
    clearContainer(containerId) {
        const container = document.getElementById(containerId);
        if (container) {
            container.innerHTML = '<div class="brush-container"></div>';
        }
    },
    
    setContainerSize(containerId, width, height) {
        const container = document.getElementById(containerId);
        if (container) {
            container.style.width = width;
            container.style.height = height;
        }
    },
    
    getContainerSize(containerId) {
        const container = document.getElementById(containerId);
        if (!container) return null;
        
        const rect = container.getBoundingClientRect();
        return {
            width: rect.width,
            height: rect.height
        };
    }
};

// Export for use in test files
if (typeof window !== 'undefined') {
    window.MockHTMLComponent = MockHTMLComponent;
    window.TestLogger = TestLogger;
    window.TestStatus = TestStatus;
    window.TestValidators = TestValidators;
    window.TestDataGenerator = TestDataGenerator;
    window.PerformanceTester = PerformanceTester;
    window.DOMHelpers = DOMHelpers;
}

console.log('[Test Utils] Test utilities loaded successfully');
