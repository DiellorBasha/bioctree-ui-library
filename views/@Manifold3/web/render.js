import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { VertexNormalsHelper } from "three/addons/helpers/VertexNormalsHelper.js";
import { VertexTangentsHelper } from "three/addons/helpers/VertexTangentsHelper.js";

let renderer, scene, camera, controls;
let canvas, hud;

let modelRoot = null;   // holds loaded glTF scene
let loadedScene = null; // gltf.scene reference

// Debug visuals
let targetMarker = null; // follows controls.target (rotation anchor)
let wireframeHelper = null; // WireframeGeometry visualization
let normalsHelper = null; // VertexNormalsHelper visualization
let tangentsHelper = null; // VertexTangentsHelper visualization

// Axes gizmo overlay (bottom-left)
let gizmoScene = null;
let gizmoCamera = null;
let gizmoAxes = null;

// View-locked light rig (attached to camera)
let lightRig = null;

// Defaults
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
let SHOW_WIREFRAME = false; // wireframe overlay
let SHOW_NORMALS = false; // vertex normals vectors (red)
let SHOW_TANGENTS = false; // vertex tangents vectors (cyan)

/* -------------------- UV synthesis helper -------------------- */

function addSphericalUVs(geometry) {
  const pos = geometry.attributes.position;
  if (!pos) return;

  // Use bounding sphere center for stable parameterization
  geometry.computeBoundingSphere();
  const c = geometry.boundingSphere?.center ?? new THREE.Vector3();

  const uvs = new Float32Array(pos.count * 2);
  const v = new THREE.Vector3();

  for (let i = 0; i < pos.count; i++) {
    v.fromBufferAttribute(pos, i).sub(c).normalize();

    // longitude/latitude on unit sphere
    const lon = Math.atan2(v.z, v.x);  // [-pi, pi]
    const lat = Math.asin(v.y);        // [-pi/2, pi/2]

    const u = (lon + Math.PI) / (2 * Math.PI);
    const t = (lat + Math.PI / 2) / Math.PI;

    uvs[2 * i + 0] = u;
    uvs[2 * i + 1] = t;
  }

  geometry.setAttribute("uv", new THREE.BufferAttribute(uvs, 2));
  geometry.attributes.uv.needsUpdate = true;
  console.log('[Manifold3] Synthesized spherical UVs for tangent computation');
}

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

    // Main render
    renderer.setViewport(0, 0, canvas.clientWidth, canvas.clientHeight);
    renderer.setScissorTest(false);
    renderer.render(scene, camera);

    // Axes overlay render (bottom-left)
    renderAxesGizmoOverlay();
  });

  resize();
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
    
    // Ensure normals exist
    if (geom && !geom.attributes.normal) {
      geom.computeVertexNormals();
      if (geom.attributes.normal) geom.attributes.normal.needsUpdate = true;
    }
    
    // Ensure UVs exist (synthesize spherical UVs if missing for tangent visualization)
    if (geom && !geom.attributes.uv) {
      addSphericalUVs(geom);
    }
    
    // Compute tangents if we have all required attributes
    if (geom && !geom.attributes.tangent) {
      const hasRequiredAttrs = geom.index && geom.attributes.position && geom.attributes.normal && geom.attributes.uv;
      if (hasRequiredAttrs) {
        try {
          geom.computeTangents();
          console.log('[Manifold3] Computed tangents for mesh');
        } catch (err) {
          console.warn('[Manifold3] Failed to compute tangents:', err.message);
        }
      } else {
        console.warn('[Manifold3] Cannot compute tangents: missing required attributes (index/position/normal/uv)');
      }
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
      
      updateAxesGizmo();
      updateTargetMarker();
      
      hideLoader();
    }, 1500); // 1500ms delay to show loading animation
  });
}

/* -------------------- Public debug API -------------------- */

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

/* -------------------- Wireframe -------------------- */

function syncWireframeVisibility() {
  if (!loadedScene) return;

  loadedScene.traverse((obj) => {
    if (!obj.isMesh) return;

    const baseMat = obj.userData.baseMaterial;
    const wireMat = obj.userData.wireMaterial;

    if (!baseMat || !wireMat) return;

    // Swap materials based on wireframe state
    obj.material = SHOW_WIREFRAME ? wireMat : baseMat;
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
    const positions = geometry.attributes.position;
    const normals = geometry.attributes.normal;
    
    console.log(`[Manifold3] Normals - Mesh ${meshCount}: positions=${!!positions}, normals=${!!normals}`);
    
    if (!positions || !normals) return;

    // Create downsampled geometry
    const downsampledPositions = [];
    const downsampledNormals = [];
    
    for (let i = 0; i < positions.count; i += downsampleFactor) {
      downsampledPositions.push(
        positions.getX(i),
        positions.getY(i),
        positions.getZ(i)
      );
      downsampledNormals.push(
        normals.getX(i),
        normals.getY(i),
        normals.getZ(i)
      );
    }
    
    // Create sparse geometry for helpers
    const sparseGeometry = new THREE.BufferGeometry();
    sparseGeometry.setAttribute('position', new THREE.Float32BufferAttribute(downsampledPositions, 3));
    sparseGeometry.setAttribute('normal', new THREE.Float32BufferAttribute(downsampledNormals, 3));
    
    // Create temporary mesh for the helper
    const tempMesh = new THREE.Mesh(sparseGeometry, obj.material);
    tempMesh.position.copy(obj.position);
    tempMesh.rotation.copy(obj.rotation);
    tempMesh.scale.copy(obj.scale);
    tempMesh.matrixWorld.copy(obj.matrixWorld);
    
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

    // Create downsampled geometry
    const downsampledPositions = [];
    const downsampledNormals = [];
    const downsampledTangents = [];
    
    for (let i = 0; i < positions.count; i += downsampleFactor) {
      downsampledPositions.push(
        positions.getX(i),
        positions.getY(i),
        positions.getZ(i)
      );
      downsampledNormals.push(
        normals.getX(i),
        normals.getY(i),
        normals.getZ(i)
      );
      downsampledTangents.push(
        tangents.getX(i),
        tangents.getY(i),
        tangents.getZ(i),
        tangents.getW(i)
      );
    }
    
    // Create sparse geometry for helpers
    const sparseGeometry = new THREE.BufferGeometry();
    sparseGeometry.setAttribute('position', new THREE.Float32BufferAttribute(downsampledPositions, 3));
    sparseGeometry.setAttribute('normal', new THREE.Float32BufferAttribute(downsampledNormals, 3));
    sparseGeometry.setAttribute('tangent', new THREE.Float32BufferAttribute(downsampledTangents, 4));
    
    // Create temporary mesh for the helper
    const tempMesh = new THREE.Mesh(sparseGeometry, obj.material);
    tempMesh.position.copy(obj.position);
    tempMesh.rotation.copy(obj.rotation);
    tempMesh.scale.copy(obj.scale);
    tempMesh.matrixWorld.copy(obj.matrixWorld);
    
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
  const hudText = document.getElementById("hudText");
  if (hudText) hudText.textContent = text;
}

function updateToggleButtonStates() {
  const btnWireframe = document.getElementById("btnWireframe");
  const btnNormals = document.getElementById("btnNormals");
  const btnTangents = document.getElementById("btnTangents");

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
