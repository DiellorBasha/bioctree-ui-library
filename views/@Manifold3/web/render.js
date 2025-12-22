import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";

let renderer, scene, camera, controls;
let canvas, hud;

let modelRoot = null;   // holds loaded glTF scene
let loadedScene = null; // gltf.scene reference

// Debug visuals
let targetMarker = null; // follows controls.target (rotation anchor)
let bboxHelper = null;   // Box3Helper around loaded model

// Axes gizmo overlay (bottom-left)
let gizmoScene = null;
let gizmoCamera = null;
let gizmoAxes = null;

// View-locked light rig (attached to camera)
let lightRig = null;

// Defaults
const BASE_COLOR_HEX = 0x999999; // [0.6 0.6 0.6]
const DEFAULT_GLB_URL = "./assets/fsaverage.glb";

// Loader control functions
function setLoaderProgress(pct) {
  const bar = document.getElementById("loaderBar");
  const txt = document.getElementById("loaderPct");
  if (bar) bar.style.width = `${pct}%`;
  if (txt) txt.textContent = String(Math.round(pct));
}

function hideLoader() {
  const el = document.getElementById("loader");
  if (!el) return;
  el.classList.add("hidden");
  // Remove after fade transition
  setTimeout(() => el.remove(), 400);
}

// Pivot mode: recommended "MeshCenter" for FreeSurfer surfaces
const PIVOT_MODE = "MeshCenter";

// Debug toggles (initial state)
let SHOW_BBOX = false;     // start hidden; user can show via API
const SHOW_TARGET = false; // hide pivot marker

export function initViewer({ canvasEl, hudEl, glbUrl = DEFAULT_GLB_URL }) {
  canvas = canvasEl;
  hud = hudEl;

  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x000000);

  camera = new THREE.PerspectiveCamera(45, 1, 0.01, 1e7);
  camera.up.set(0, 1, 0);
  camera.position.set(0, 0, 300);

  // IMPORTANT: add camera to scene so we can parent lights to it (view-locked lighting)
  scene.add(camera);

  renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
  renderer.setPixelRatio(window.devicePixelRatio ?? 1);

  // Conservative tone/exposure
  if ("outputColorSpace" in renderer) renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.0;

  // View-locked lighting rig
  installDefaultLights();

  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.08;

  // Default view so +Z (blue) points right:
  // camera on -X looking toward target, with up = +Y.
  controls.target.set(0, 0, 0);
  camera.position.set(-300, 0, 0);
  camera.lookAt(controls.target);
  controls.update();

  // Axes gizmo overlay
  initAxesGizmo();
  updateAxesGizmo();

  // Pivot marker (optional)
  if (SHOW_TARGET) installTargetMarker();
  updateTargetMarker();

  // Resize handling
  const ro = new ResizeObserver(() => resize());
  ro.observe(canvas);

  // Keep gizmo + target marker synchronized
  controls.addEventListener("change", () => {
    updateAxesGizmo();
    updateTargetMarker();
  });

  renderer.setAnimationLoop(() => {
    controls.update();
    updateAxesGizmo();
    updateTargetMarker();

    // Main render
    renderer.setViewport(0, 0, canvas.clientWidth, canvas.clientHeight);
    renderer.setScissorTest(false);
    renderer.render(scene, camera);

    // Axes overlay render (bottom-left)
    renderAxesGizmoOverlay();
  });

  resize();
  setHud(`Loading: ${glbUrl}`);

  loadGLB(glbUrl).catch((err) => {
    console.error(err);
    setHud(String(err));
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
    if (geom && !geom.attributes.normal) {
      geom.computeVertexNormals();
      if (geom.attributes.normal) geom.attributes.normal.needsUpdate = true;
    }

    obj.material = new THREE.MeshStandardMaterial({
      color: BASE_COLOR_HEX,
      roughness: 0.85,
      metalness: 0.0,
      side: THREE.DoubleSide
    });
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
      
      // BBox visibility obeys toggle state
      syncBoundingBoxVisibility();
      
      updateAxesGizmo();
      updateTargetMarker();
      
      hideLoader();
    }, 800); // 800ms delay to show loading animation
  });
}

/* -------------------- Public debug API -------------------- */

export function setShowBoundingBox(show) {
  SHOW_BBOX = !!show;
  syncBoundingBoxVisibility();
}

export function toggleBoundingBox() {
  SHOW_BBOX = !SHOW_BBOX;
  syncBoundingBoxVisibility();
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

/* -------------------- Bounding box -------------------- */

function syncBoundingBoxVisibility() {
  if (!SHOW_BBOX) {
    if (bboxHelper) {
      scene.remove(bboxHelper);
      bboxHelper = null;
    }
    return;
  }

  if (!modelRoot) return;

  const box = new THREE.Box3().setFromObject(modelRoot);

  if (!bboxHelper) {
    bboxHelper = new THREE.Box3Helper(box, 0x00ffff);
    scene.add(bboxHelper);
  } else {
    bboxHelper.box.copy(box);
    bboxHelper.updateMatrixWorld(true);
  }
}

/* -------------------- Axes gizmo (bottom-left) -------------------- */

function initAxesGizmo() {
  gizmoScene = new THREE.Scene();
  gizmoScene.background = new THREE.Color(0x000000); // match main scene

  gizmoAxes = new THREE.AxesHelper(1);
  gizmoScene.add(gizmoAxes);

  gizmoCamera = new THREE.PerspectiveCamera(50, 1, 0.1, 10);
  gizmoCamera.position.set(0, 0, 3);
  gizmoCamera.up.set(0, 1, 0);
  gizmoCamera.lookAt(0, 0, 0);
}

function updateAxesGizmo() {
  if (!gizmoAxes || !camera) return;

  // Invert camera rotation so the gizmo shows world axes relative to current view
  gizmoAxes.quaternion.copy(camera.quaternion).invert();
}

function renderAxesGizmoOverlay() {
  if (!gizmoScene || !gizmoCamera || !renderer) return;

  const minDim = Math.min(canvas.clientWidth, canvas.clientHeight);
  const vp = Math.max(90, Math.floor(minDim * 0.18)); // ~18% of smaller dimension

  const margin = 12;
  const x = margin;
  const y = margin;

  renderer.clearDepth(); // ensure overlay draws on top
  renderer.setScissorTest(true);
  renderer.setScissor(x, y, vp, vp);
  renderer.setViewport(x, y, vp, vp);

  gizmoCamera.aspect = 1;
  gizmoCamera.updateProjectionMatrix();

  renderer.render(gizmoScene, gizmoCamera);

  renderer.setScissorTest(false);

  // Restore viewport to full canvas for any future draws
  renderer.setViewport(0, 0, canvas.clientWidth, canvas.clientHeight);
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

/* -------------------- View-locked lighting (camera rig) -------------------- */

function installDefaultLights() {
  // Remove any existing rig
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
  // Remove bbox if present
  if (bboxHelper) {
    scene.remove(bboxHelper);
    bboxHelper = null;
  }

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

function resize() {
  const w = canvas?.clientWidth ?? 0;
  const h = canvas?.clientHeight ?? 0;
  if (!w || !h) return;

  camera.aspect = w / h;
  camera.updateProjectionMatrix();
  renderer.setSize(w, h, false);

  updateAxesGizmo();
}

function setHud(text) {
  if (hud) hud.textContent = text;
}
