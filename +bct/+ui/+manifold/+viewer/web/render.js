import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { VertexNormalsHelper } from "three/addons/helpers/VertexNormalsHelper.js";
import { VertexTangentsHelper } from "three/addons/helpers/VertexTangentsHelper.js";
import { Line2 } from "three/addons/lines/Line2.js";
import { LineGeometry } from "three/addons/lines/LineGeometry.js";
import { LineMaterial } from "three/addons/lines/LineMaterial.js";
import { PinMarker } from "./geometry/pinMarker.js";
import { PickingSystem } from "./interaction/picking.js";
import { SelectionFX } from "./interaction/selectionFX.js";
import { ensureGeometryAttributes, createDownsampledGeometry, createTransformedMesh } from './geometry/meshBuilder.js';
import { ViewerCore } from './core/viewerCore.js';
import { createLightingRig } from './core/lighting.js';
import { AxesGizmo } from './core/gizmo.js';

// Core rendering system
let viewerCore = null;

// Convenience accessors (populated by viewerCore)
let renderer, scene, camera, controls;
let canvas, hud;

let modelRoot = null;   // holds loaded glTF scene
let loadedScene = null; // gltf.scene reference

// Core subsystems
let lightRig = null;
let axesGizmo = null;

// Debug visuals
let targetMarker = null; // follows controls.target (rotation anchor)
let wireframeHelper = null; // WireframeGeometry visualization
let normalsHelper = null; // VertexNormalsHelper visualization
let tangentsHelper = null; // VertexTangentsHelper visualization

// Interaction systems
let pickingSystem = null;
let selectionFX = null;
let pin = null;

/* -------------------- Defaults -------------------- */
const BASE_COLOR_HEX = 0x999999; // [0.6 0.6 0.6]
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

function hideLoader() {
  const el = document.getElementById("loaderOverlay");
  if (!el) return;
  el.classList.add("hidden");
  // Remove after fade transition
  setTimeout(() => el.remove(), 400);
}

// Pivot mode: recommended "MeshCenter" for FreeSurfer surfaces
const PIVOT_MODE = "MeshCenter";

// Debug toggles (initial state)
const SHOW_TARGET = false; // hide pivot marker
let SHOW_SURFACE = true; // surface mesh visibility
let SHOW_WIREFRAME = false; // wireframe overlay
let SHOW_NORMALS = false; // vertex normals vectors (red)
let SHOW_TANGENTS = false; // vertex tangents vectors (cyan)

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

    // Update normals helpers if active
    if (normalsHelper && normalsHelper.children) {
      normalsHelper.children.forEach(helper => {
        if (helper.update) helper.update();
      });
    }
    
    // Update tangents helpers if active
    if (tangentsHelper && tangentsHelper.children) {
      tangentsHelper.children.forEach(helper => {
        if (helper.update) helper.update();
      });
    }
  });

  // Register gizmo overlay render callback (after main render)
  viewerCore.onRender(() => {
    axesGizmo.render(renderer, canvas);
  });

  // Start render loop
  viewerCore.start();

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
  clearModel();
  setLoaderProgress(0);

  const manager = new THREE.LoadingManager();
  manager.onError = (u) => console.error("Loading error:", u);

  const loader = new GLTFLoader(manager);
  const gltf = await new Promise((resolve, reject) => {
    loader.load(
      url,
      resolve,
      (xhr) => {
        if (xhr && xhr.total) {
          setLoaderProgress((xhr.loaded / xhr.total) * 100);
        }
      },
      reject
    );
  });

  modelRoot = new THREE.Group();
  loadedScene = gltf.scene;

  // Apply defaults to all meshes
  loadedScene.traverse((obj) => {
    if (!obj.isMesh) return;

    const geom = obj.geometry;
    if (geom) {
      // Use meshBuilder to ensure all geometry attributes
      ensureGeometryAttributes(geom);
    }

    // Create and cache both base and wireframe materials
    const baseMat = new THREE.MeshStandardMaterial({
      color: BASE_COLOR_HEX,
      roughness: 0.85,
      metalness: 0.0,
      side: THREE.DoubleSide,
    });

    const wireMat = new THREE.MeshBasicMaterial({
      color: 0xffffff,
      wireframe: true,
      opacity: 0.25,
      transparent: true,
      side: THREE.DoubleSide,
    });

    obj.userData.baseMaterial = baseMat;
    obj.userData.wireMaterial = wireMat;

    // Start in base mode
    obj.material = baseMat;
  });

  modelRoot.add(loadedScene);

  // Set orbit pivot (recommended) - calculate before adding to scene
  setPivotMode(PIVOT_MODE);

  setHud(`Loaded: ${url}`);

  // Hide loader after a frame and a short delay to let animation run
  // Add mesh to scene only after loader animation completes
  requestAnimationFrame(() => {
    setLoaderProgress(100);
    setTimeout(() => {
      // Add mesh to scene after animation delay
      scene.add(modelRoot);
      
      // Wireframe visibility obeys toggle state
      syncWireframeVisibility();
      
      // Normals visibility obeys toggle state
      syncNormalsVisibility();
      
      // Tangents visibility obeys toggle state
      syncTangentsVisibility();
      
      // Surface visibility obeys toggle state
      syncSurfaceVisibility();
      
      updateAxesGizmo();
      updateTargetMarker();
      
      // Collect meshes for picking
      pickingSystem?.collectPickables(loadedScene);
      
      // Set pin length relative to mesh scale
      if (loadedScene && pin) {
        loadedScene.traverse((obj) => {
          if (obj.isMesh && obj.geometry) {
            obj.geometry.computeBoundingSphere();
            const radius = obj.geometry.boundingSphere?.radius ?? 100;
            pin.setLength(radius * 0.1);
          }
        });
      }
      
      hideLoader();
    }, 1500); // 1500ms delay to show loading animation
  });
}

/* -------------------- Public debug API -------------------- */

export function setShowSurface(show) {
  SHOW_SURFACE = !!show;
  syncSurfaceVisibility();
  updateToggleButtonStates();
}

export function toggleSurface() {
  SHOW_SURFACE = !SHOW_SURFACE;
  syncSurfaceVisibility();
  updateToggleButtonStates();
}

export function setShowWireframe(show) {
  SHOW_WIREFRAME = !!show;
  syncWireframeVisibility();
  updateToggleButtonStates();
}

export function toggleWireframe() {
  SHOW_WIREFRAME = !SHOW_WIREFRAME;
  syncWireframeVisibility();
  updateToggleButtonStates();
}

export function setShowNormals(show) {
  SHOW_NORMALS = !!show;
  syncNormalsVisibility();
  updateToggleButtonStates();
}

export function toggleNormals() {
  SHOW_NORMALS = !SHOW_NORMALS;
  syncNormalsVisibility();
  updateToggleButtonStates();
}

export function setShowTangents(show) {
  SHOW_TANGENTS = !!show;
  syncTangentsVisibility();
  updateToggleButtonStates();
}

export function toggleTangents() {
  SHOW_TANGENTS = !SHOW_TANGENTS;
  syncTangentsVisibility();
  updateToggleButtonStates();
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

/* -------------------- Surface Visibility -------------------- */

function syncSurfaceVisibility() {
  if (!loadedScene) return;

  loadedScene.traverse((obj) => {
    if (!obj.isMesh) return;

    const baseMat = obj.userData.baseMaterial;
    const wireMat = obj.userData.wireMaterial;

    if (!baseMat || !wireMat) return;

    // If surface is hidden, don't render any material
    // If surface is shown, use appropriate material based on wireframe state
    if (SHOW_SURFACE) {
      obj.material = SHOW_WIREFRAME ? wireMat : baseMat;
      obj.material.visible = true;
    } else {
      obj.material.visible = false;
    }
    obj.material.needsUpdate = true;
  });
}

/* -------------------- Wireframe -------------------- */

function syncWireframeVisibility() {
  if (!loadedScene) return;

  loadedScene.traverse((obj) => {
    if (!obj.isMesh) return;

    const baseMat = obj.userData.baseMaterial;
    const wireMat = obj.userData.wireMaterial;

    if (!baseMat || !wireMat) return;

    // Swap materials based on wireframe state (only if surface is visible)
    if (SHOW_SURFACE) {
      obj.material = SHOW_WIREFRAME ? wireMat : baseMat;
      obj.material.visible = true;
    } else {
      obj.material.visible = false;
    }
    obj.material.needsUpdate = true;
  });

  // Remove old helper-based wireframe if it exists
  if (wireframeHelper) {
    scene.remove(wireframeHelper);
    wireframeHelper = null;
  }
}

/* -------------------- Normals -------------------- */

function syncNormalsVisibility() {
  if (!SHOW_NORMALS) {
    if (normalsHelper) {
      scene.remove(normalsHelper);
      normalsHelper = null;
    }
    
    // Restore mesh visibility if both normals and tangents are off
    if (!SHOW_TANGENTS) {
      restoreMeshVisibility();
    }
    return;
  }

  if (!loadedScene) return;

  // Remove existing helper if present
  if (normalsHelper) {
    scene.remove(normalsHelper);
    normalsHelper = null;
  }

  // Hide mesh only if wireframe is NOT active
  if (loadedScene && !SHOW_WIREFRAME) {
    hideMeshMaterials();
  }

  // Create vertex normals helpers for all meshes
  let meshCount = 0;
  
  loadedScene.traverse((obj) => {
    if (!obj.isMesh) return;
    meshCount++;

    const downsampleFactor = 1; // Testing: no downsampling (was 100)
    const geometry = obj.geometry;
    
    console.log(`[Manifold3] Normals - Mesh ${meshCount}: has geometry=${!!geometry}`);
    
    // Create downsampled geometry using meshBuilder
    const sparseGeometry = createDownsampledGeometry(geometry, downsampleFactor, false);
    if (!sparseGeometry) return;
    
    // Create temporary mesh with transforms copied from source
    const tempMesh = createTransformedMesh(sparseGeometry, obj);
    
    // Create normals helper (red)
    const helper = new VertexNormalsHelper(tempMesh, 2, 0xff0000);
    
    if (!normalsHelper) {
      normalsHelper = new THREE.Group();
      scene.add(normalsHelper);
    }
    
    normalsHelper.add(helper);
  });
  
  console.log(`[Manifold3] Normals: ${meshCount} meshes`);
}

/* -------------------- Tangents -------------------- */

function syncTangentsVisibility() {
  if (!SHOW_TANGENTS) {
    if (tangentsHelper) {
      scene.remove(tangentsHelper);
      tangentsHelper = null;
    }
    
    // Restore mesh visibility if both normals and tangents are off
    if (!SHOW_NORMALS) {
      restoreMeshVisibility();
    }
    return;
  }

  if (!loadedScene) return;

  // Remove existing helper if present
  if (tangentsHelper) {
    scene.remove(tangentsHelper);
    tangentsHelper = null;
  }

  // Hide mesh only if wireframe is NOT active
  if (loadedScene && !SHOW_WIREFRAME) {
    hideMeshMaterials();
  }

  // Create vertex tangents helpers for all meshes
  let meshCount = 0;
  let tangentCount = 0;
  
  loadedScene.traverse((obj) => {
    if (!obj.isMesh) return;
    meshCount++;

    const downsampleFactor = 1; // Testing: no downsampling (was 100)
    const geometry = obj.geometry;
    const positions = geometry.attributes.position;
    const normals = geometry.attributes.normal;
    const tangents = geometry.attributes.tangent;
    const uvs = geometry.attributes.uv;
    
    console.log(`[Manifold3] Tangents - Mesh ${meshCount}: positions=${!!positions}, normals=${!!normals}, tangents=${!!tangents}, uvs=${!!uvs}`);
    
    if (!positions || !normals || !tangents) return;

    tangentCount++;

    // Create downsampled geometry with tangents using meshBuilder
    const sparseGeometry = createDownsampledGeometry(geometry, downsampleFactor, true);
    if (!sparseGeometry) return;
    
    // Create temporary mesh with transforms copied from source
    const tempMesh = createTransformedMesh(sparseGeometry, obj);
    
    // Create tangents helper (cyan)
    const helper = new VertexTangentsHelper(tempMesh, 2, 0x00ffff);
    
    if (!tangentsHelper) {
      tangentsHelper = new THREE.Group();
      scene.add(tangentsHelper);
    }
    
    tangentsHelper.add(helper);
    console.log(`[Manifold3] Created tangents helper for mesh ${meshCount}`);
  });
  
  console.log(`[Manifold3] Tangents: ${meshCount} meshes, ${tangentCount} with tangents`);
}

// Helper functions to reduce duplication
function hideMeshMaterials() {
  if (!loadedScene) return;
  loadedScene.traverse((obj) => {
    if (obj.isMesh && obj.material) {
      obj.material.visible = false;
    }
  });
}

function restoreMeshVisibility() {
  if (!loadedScene) return;
  loadedScene.traverse((obj) => {
    if (!obj.isMesh) return;
    const baseMat = obj.userData.baseMaterial;
    const wireMat = obj.userData.wireMaterial;
    if (!baseMat || !wireMat) return;
    
    // Restore appropriate material based on wireframe toggle
    obj.material = SHOW_WIREFRAME ? wireMat : baseMat;
    obj.material.visible = true;
  });
}



/* -------------------- Axes gizmo (bottom-left) -------------------- */

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

function clearModel() {
  if (lightRig && lightRig.parent) {
    lightRig.parent.remove(lightRig);
  }

  lightRig = new THREE.Group();

  // Attach to camera so illumination is consistent across mesh rotations
  camera.add(lightRig);

  // Base lift: keep low to preserve contrast
  const ambient = new THREE.AmbientLight(0xffffff, 0.2);
  lightRig.add(ambient);

  // Key (front-right in view space)
  const key = new THREE.DirectionalLight(0xffffff, 1.45);
  key.position.set(1.0, 0.8, 1.2);
  lightRig.add(key);

  // DirectionalLight uses a target to define direction; parent target to rig for view-lock
  key.target.position.set(0, 0, 0);
  lightRig.add(key.target);

  // Fill (front-left in view space)
  const fill = new THREE.DirectionalLight(0xffffff, 0.95);
  fill.position.set(-1.0, 0.4, 1.0);
  lightRig.add(fill);

  fill.target.position.set(0, 0, 0);
  lightRig.add(fill.target);

  // Rim/back light (adds edge definition without creating a permanent “dark side”)
  const rim = new THREE.DirectionalLight(0xffffff, 0.45);
  rim.position.set(0.0, 1.0, -1.2);
  lightRig.add(rim);

  rim.target.position.set(0, 0, 0);
  lightRig.add(rim.target);
}

/* --------------------------- helpers --------------------------- */

function clearModel() {
  // Remove wireframe if present
  if (wireframeHelper) {
    scene.remove(wireframeHelper);
    wireframeHelper = null;
  }

  // Remove normals if present
  if (normalsHelper) {
    scene.remove(normalsHelper);
    normalsHelper = null;
  }
  
  // Remove tangents if present
  if (tangentsHelper) {
    scene.remove(tangentsHelper);
    tangentsHelper = null;
  }
  
  // Clear pickables
  pickables = [];

  if (modelRoot) {
    scene.remove(modelRoot);
    disposeObject3D(modelRoot);
  }
  modelRoot = null;
  loadedScene = null;
}

function disposeObject3D(obj) {
  obj.traverse((o) => {
    if (o.geometry && typeof o.geometry.dispose === "function") o.geometry.dispose();
    if (o.material) {
      if (Array.isArray(o.material)) {
        o.material.forEach((m) => m && typeof m.dispose === "function" && m.dispose());
      } else if (typeof o.material.dispose === "function") {
        o.material.dispose();
      }
    }
  });
}

function setHud(text) {
  const hudText = document.getElementById("hudText");
  if (hudText) hudText.textContent = text;
}

function updateToggleButtonStates() {
  const btnSurface = document.getElementById("btnSurface");
  const btnWireframe = document.getElementById("btnWireframe");
  const btnNormals = document.getElementById("btnNormals");
  const btnTangents = document.getElementById("btnTangents");

  if (btnSurface) {
    btnSurface.classList.toggle("active", SHOW_SURFACE);
  }
  if (btnWireframe) {
    btnWireframe.classList.toggle("active", SHOW_WIREFRAME);
  }
  if (btnNormals) {
    btnNormals.classList.toggle("active", SHOW_NORMALS);
  }
  if (btnTangents) {
    btnTangents.classList.toggle("active", SHOW_TANGENTS);
  }
}
