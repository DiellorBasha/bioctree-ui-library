import * as THREE from "three";
import { PinMarker } from "./geometry/pinMarker.js";
import { PickingSystem } from "./interaction/picking.js";
import { SelectionFX } from "./interaction/selectionFX.js";
import { ViewerCore } from './core/viewerCore.js';
import { createLightingRig } from './core/lighting.js';
import { AxesGizmo } from './core/gizmo.js';
import { createVisualizationControls } from './ui/visualizationControls.js';
import { MeshManager } from './runtime/meshManager.js';
import { VisualizationManager } from './runtime/visualizationManager.js';

// Core rendering system
let viewerCore = null;

// Convenience accessors (populated by viewerCore)
let renderer, scene, camera, controls;
let canvas, hud;

// Core subsystems
let lightRig = null;
let axesGizmo = null;

// Runtime managers
let meshManager = null;
let vizManager = null;

// Debug visuals
let targetMarker = null; // follows controls.target (rotation anchor)

// Interaction systems
let pickingSystem = null;
let selectionFX = null;
let pin = null;

/* -------------------- Defaults -------------------- */
const DEFAULT_GLB_URL = "./assets/fsaverage.glb";
const LOADER_COMPONENT_PATH = "./loaders/spinning/spinning.html";

// Loader control functions
function setLoaderProgress(pct) {
  // Progress tracking available for future use
  // Currently plasma2 loader doesn't display percentage
}

async function initLoader() {
  const loaderHost = document.getElementById("loaderHost");
  if (!loaderHost) return;

  try {
    const response = await fetch(LOADER_COMPONENT_PATH);
    const html = await response.text();
    loaderHost.innerHTML = html;
  } catch (err) {
    console.error("Failed to load loader component:", err);
    // Fallback: simple loading text
    loaderHost.innerHTML = '<div style="color: #eaeaea; font-size: 14px;">Loading...</div>';
  }
}

function showLoader() {
  const el = document.getElementById("loaderOverlay");
  if (!el) return;
  el.classList.remove("hidden");
  el.style.display = "flex"; // Ensure it's visible
}

function hideLoader() {
  const el = document.getElementById("loaderOverlay");
  if (!el) return;
  el.classList.add("hidden");
}

// Pivot mode: recommended "MeshCenter" for FreeSurfer surfaces
const PIVOT_MODE = "MeshCenter";

// Debug toggles (initial state)
const SHOW_TARGET = false; // hide pivot marker

// Visualization state (lil-gui contract)
const vizState = {
  surface: {
    visible: true,
    opacity: 1.0,
    shading: 'smooth',
    colorMode: 'uniform'
  },
  edges: {
    wireframe: false,
    width: 1.0,
    color: '#ffffff'
  },
  helpers: {
    vertexNormals: false,
    faceNormals: false,
    tangents: false
  },
  overlays: {
    scalarField: 'none',
    colormap: 'viridis',
    autoRange: true
  },
  scene: {
    lighting: true,
    axes: true,
    background: '#000000'
  }
};

// GUI instance
let vizGUI = null;

/* -------------------- Viewer Initialization -------------------- */

export function initViewer({ canvasEl, hudEl, glbUrl = DEFAULT_GLB_URL }) {
  canvas = canvasEl;
  hud = hudEl;

  // Initialize core rendering system
  viewerCore = new ViewerCore(canvas);
  viewerCore.init({
    backgroundColor: 0x000000,
    cameraConfig: {
      fov: 45,
      near: 0.01,
      far: 1e7,
      position: [0, 0, 300],
      up: [0, 1, 0]
    },
    controlsConfig: {
      enableDamping: true,
      dampingFactor: 0.08,
      target: [0, 0, 0],
      cameraPosition: [-300, 0, 0]  // Default: +Z (blue) points right
    }
  });

  // Extract convenience accessors
  scene = viewerCore.scene;
  camera = viewerCore.camera;
  renderer = viewerCore.renderer;
  controls = viewerCore.controls;

  // Initialize lighting rig
  lightRig = createLightingRig(camera);

  // Initialize axes gizmo
  axesGizmo = new AxesGizmo();
  axesGizmo.init({ backgroundColor: 0x000000 });

  // Initialize runtime managers
  meshManager = new MeshManager(viewerCore);
  vizManager = new VisualizationManager(viewerCore, meshManager, lightRig, axesGizmo);

  // Pivot marker (optional)
  if (SHOW_TARGET) installTargetMarker();
  updateTargetMarker();

  // Setup resize observation
  viewerCore.setupResizeObserver();

  // Wire up controls change callbacks
  viewerCore.onControlsChange(() => {
    axesGizmo.update(camera);
    updateTargetMarker();
  });
  
  // Initialize picking system
  pickingSystem = new PickingSystem(camera, renderer);
  
  // Start with picking disabled (tools must be explicitly activated)
  pickingSystem.setEnabled(false);
  
  // Initialize selection FX
  selectionFX = new SelectionFX();
  
  // Initialize pin marker for vertex selection
  pin = new PinMarker(scene, renderer, {
    color: 0xffcc00,
    length: 18,
    headRadius: 2.0,
    lineWidthPx: 2.5
  });
  
  // Wire up picking callbacks
  pickingSystem.onTrianglePick = (hit, tri) => {
    selectionFX.showTriangle(hit.object, tri);
  };
  
  pickingSystem.onEdgePick = (hit, edge, tri) => {
    selectionFX.showEdge(hit.object, hit.point, tri);
  };
  
  pickingSystem.onVertexPick = (hit, vertexIdx, tri) => {
    pin.setFromVertexIndex(hit.object, vertexIdx, camera);
  };
  
  // Picking: pointer event handler
  viewerCore.getRendererElement().addEventListener("pointerdown", (evt) => {
    pickingSystem.handlePointerDown(evt);
  });

  // Register render callbacks
  viewerCore.onRender(() => {
    axesGizmo.update(camera);
    updateTargetMarker();
    
    // Update selection pulse animation
    const t = performance.now() / 1000;
    selectionFX?.updatePulse(t);
    pin?.updatePulse(t);
    
    // Resize pin on viewport changes
    pin?.onResize();

    // Update normals/tangents helpers if active (via vizManager)
    vizManager?.updateNormalsHelpers();
    vizManager?.updateTangentsHelpers();
  });

  // Register gizmo overlay render callback (after main render)
  viewerCore.onRender(() => {
    axesGizmo.render(renderer, canvas);
  });

  // Start render loop
  viewerCore.start();
  
  // Create visualization controls GUI
  vizGUI = createVisualizationControls({
    vizState,
    onChange: () => vizManager?.applyState(vizState)
  });
  
  // Initial visualization sync
  vizManager?.applyState(vizState);

  setHud(`Loading: ${glbUrl}`);

  // Initialize loader component, then load GLB
  initLoader().then(() => {
    loadGLB(glbUrl).catch((err) => {
      console.error(err);
      setHud(String(err));
    });
  });
}

export async function loadGLB(url) {
  showLoader();
  setLoaderProgress(0);

  try {
    await meshManager.loadGLB(url);
    
    // Post-load setup
    const loadedScene = meshManager.getLoadedScene();
    const modelRoot = meshManager.getModelRoot();
    
    // Set orbit pivot (recommended) - calculate before adding to scene
    setPivotMode(PIVOT_MODE);

    setHud(`Loaded: ${url}`);

    // Hide loader after a frame and a short delay to let animation run
    requestAnimationFrame(() => {
      setLoaderProgress(100);
      setTimeout(() => {
        // Apply visualization state
        vizManager?.applyState(vizState);
        
        updateTargetMarker();
        
        // Collect meshes for picking
        pickingSystem?.collectPickables(loadedScene);
        
        // Set pin length relative to mesh scale
        if (loadedScene && pin) {
          const bounds = meshManager.getBounds();
          pin.setLength(bounds.radius * 0.1);
        }
        
        hideLoader();
      }, 1500); // 1500ms delay to show loading animation
    });
  } catch (err) {
    console.error(err);
    setHud(String(err));
    hideLoader();
    throw err;
  }
}

/**
 * Load model from URL - detects file type and uses appropriate loader
 * @param {string} url - Path to model file (.glb or .json)
 */
export async function loadModel(url) {
  return meshManager.loadModelFromUrl(url);
}

/**
 * Load JSON geometry file
 * @param {string} url - Path to JSON geometry file
 */
async function loadJSON(url) {
  showLoader();
  setLoaderProgress(0);
  setHud(`Loading: ${url}`);

  try {
    await meshManager.loadJSON(url);
    
    setLoaderProgress(100);

    // Post-load setup
    const loadedScene = meshManager.getLoadedScene();
    const bounds = meshManager.getBounds();

    // Add to scene after short delay
    setTimeout(() => {
      // Apply visualization state
      vizManager?.applyState(vizState);
      
      updateTargetMarker();
      
      // Collect meshes for picking
      pickingSystem?.collectPickables(loadedScene);
      
      // Set pin length relative to mesh scale
      if (pin) {
        pin.setLength(bounds.radius * 0.1);
      }
      
      setHud(`Loaded: ${url}`);
      hideLoader();
    }, 1500);

  } catch (err) {
    console.error(err);
    setHud(String(err));
    hideLoader();
    throw err;
  }
}

/* -------------------- Picking API -------------------- */

export function setPickMode(mode) {
  pickingSystem?.setMode(mode);
}

export function setPickingEnabled(enabled) {
  pickingSystem?.setEnabled(enabled);
}

/* -------------------- Pivot control -------------------- */

function setPivotMode(mode) {
  if (!controls) return;

  if (mode === "WorldOrigin") {
    controls.target.set(0, 0, 0);
  } else {
    const modelRoot = meshManager?.getModelRoot();
    if (modelRoot) {
      const center = new THREE.Box3().setFromObject(modelRoot).getCenter(new THREE.Vector3());
      controls.target.copy(center);
    } else {
      controls.target.set(0, 0, 0);
    }
  }

  // Keep your canonical view direction relative to pivot
  const t = controls.target;
  camera.position.set(t.x - 300, t.y, t.z);
  camera.lookAt(t);

  controls.update();
  updateTargetMarker();
}

/* -------------------- Pivot marker -------------------- */

function installTargetMarker() {
  if (targetMarker) scene.remove(targetMarker);

  const geom = new THREE.SphereGeometry(4.0, 16, 16);
  const mat = new THREE.MeshBasicMaterial({ color: 0xffcc00 });
  targetMarker = new THREE.Mesh(geom, mat);
  targetMarker.position.copy(controls?.target ?? new THREE.Vector3());
  scene.add(targetMarker);
}

function updateTargetMarker() {
  if (!targetMarker || !controls) return;
  targetMarker.position.copy(controls.target);
}

/* --------------------------- helpers --------------------------- */

function setHud(text) {
  const hudText = document.getElementById("hudText");
  if (hudText) hudText.textContent = text;
}
