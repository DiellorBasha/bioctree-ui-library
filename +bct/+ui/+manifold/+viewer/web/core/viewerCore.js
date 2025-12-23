/**
 * viewerCore.js
 * 
 * Core three.js rendering runtime: scene, camera, renderer, and render loop.
 * 
 * Responsibilities:
 * - Create and own THREE.Scene, Camera, Renderer
 * - Manage render loop (animation loop)
 * - Handle resize events
 * - Manage camera controls (OrbitControls)
 * 
 * Rules:
 * - No awareness of geometry or picking
 * - No material creation
 * - Pure rendering runtime
 */

import * as THREE from '../vendor/three.module.r169.js';
import { OrbitControls } from '../vendor/three.examples.jsm.r169.js';

/**
 * ViewerCore - Core three.js rendering system
 */
export class ViewerCore {
  constructor(canvas) {
    this.canvas = canvas;
    
    // Core three.js objects
    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.controls = null;
    
    // Animation loop state
    this.isRunning = false;
    this.renderCallbacks = [];
    this.controlsChangeCallbacks = [];
  }

  /**
   * Initialize the core rendering system
   * @param {Object} options - Configuration options
   * @param {THREE.Color} options.backgroundColor - Background color (default: black)
   * @param {Object} options.cameraConfig - Camera configuration
   * @param {Object} options.controlsConfig - Controls configuration
   */
  init(options = {}) {
    const {
      backgroundColor = 0x000000,
      cameraConfig = {},
      controlsConfig = {}
    } = options;

    // Create scene
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(backgroundColor);

    // Create camera
    const {
      fov = 45,
      near = 0.01,
      far = 1e7,
      position = [0, 0, 300],
      up = [0, 1, 0]
    } = cameraConfig;

    this.camera = new THREE.PerspectiveCamera(fov, 1, near, far);
    this.camera.up.set(...up);
    this.camera.position.set(...position);

    // IMPORTANT: Add camera to scene for view-locked lighting
    this.scene.add(this.camera);

    // Create renderer
    this.renderer = new THREE.WebGLRenderer({ 
      canvas: this.canvas, 
      antialias: true 
    });
    this.renderer.setPixelRatio(window.devicePixelRatio ?? 1);

    // Conservative tone mapping and color space
    if ('outputColorSpace' in this.renderer) {
      this.renderer.outputColorSpace = THREE.SRGBColorSpace;
    }
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.0;

    // Create orbit controls
    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    
    const {
      enableDamping = true,
      dampingFactor = 0.08,
      target = [0, 0, 0],
      cameraPosition = [-300, 0, 0]
    } = controlsConfig;

    this.controls.enableDamping = enableDamping;
    this.controls.dampingFactor = dampingFactor;
    this.controls.target.set(...target);
    
    // Set camera position and look at target
    this.camera.position.set(...cameraPosition);
    this.camera.lookAt(this.controls.target);
    this.controls.update();

    // Wire up controls change event
    this.controls.addEventListener('change', () => {
      this.controlsChangeCallbacks.forEach(cb => cb());
    });

    console.log('[ViewerCore] Initialized');
  }

  /**
   * Start the render loop
   */
  start() {
    if (this.isRunning) return;
    
    this.isRunning = true;
    this.renderer.setAnimationLoop(() => this._renderFrame());
    console.log('[ViewerCore] Render loop started');
  }

  /**
   * Stop the render loop
   */
  stop() {
    if (!this.isRunning) return;
    
    this.isRunning = false;
    this.renderer.setAnimationLoop(null);
    console.log('[ViewerCore] Render loop stopped');
  }

  /**
   * Internal render frame method
   * @private
   */
  _renderFrame() {
    // Update controls
    this.controls.update();

    // Execute all registered callbacks
    this.renderCallbacks.forEach(cb => cb());

    // Main render
    this.renderer.setViewport(0, 0, this.canvas.clientWidth, this.canvas.clientHeight);
    this.renderer.setScissorTest(false);
    this.renderer.render(this.scene, this.camera);
  }

  /**
   * Register a callback to be executed each frame
   * @param {Function} callback - Function to call each frame
   */
  onRender(callback) {
    if (typeof callback === 'function') {
      this.renderCallbacks.push(callback);
    }
  }

  /**
   * Register a callback for controls change events
   * @param {Function} callback - Function to call when controls change
   */
  onControlsChange(callback) {
    if (typeof callback === 'function') {
      this.controlsChangeCallbacks.push(callback);
    }
  }

  /**
   * Handle canvas resize
   */
  resize() {
    const w = this.canvas?.clientWidth ?? 0;
    const h = this.canvas?.clientHeight ?? 0;
    if (!w || !h) return;

    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(w, h, false);

    console.log(`[ViewerCore] Resized: ${w}x${h}`);
  }

  /**
   * Setup automatic resize observation
   */
  setupResizeObserver() {
    const ro = new ResizeObserver(() => this.resize());
    ro.observe(this.canvas);
    
    // Initial resize
    this.resize();
  }

  /**
   * Get the renderer's DOM element for event listeners
   */
  getRendererElement() {
    return this.renderer?.domElement;
  }

  /**
   * Dispose of all resources
   */
  dispose() {
    this.stop();
    
    if (this.controls) {
      this.controls.dispose();
      this.controls = null;
    }
    
    if (this.renderer) {
      this.renderer.dispose();
      this.renderer = null;
    }
    
    this.renderCallbacks = [];
    this.controlsChangeCallbacks = [];
    
    console.log('[ViewerCore] Disposed');
  }
}
