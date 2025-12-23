import * as THREE from "three";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { VertexNormalsHelper } from "three/addons/helpers/VertexNormalsHelper.js";
import { VertexTangentsHelper } from "three/addons/helpers/VertexTangentsHelper.js";
import { Line2 } from "three/addons/lines/Line2.js";
import { LineGeometry } from "three/addons/lines/LineGeometry.js";
import { LineMaterial } from "three/addons/lines/LineMaterial.js";

let renderer, scene, camera, controls;
let canvas, hud;

let modelRoot = null;   // holds loaded glTF scene
let loadedScene = null; // gltf.scene reference

// Debug visuals
let targetMarker = null; // follows controls.target (rotation anchor)
let wireframeHelper = null; // WireframeGeometry visualization
let normalsHelper = null; // VertexNormalsHelper visualization
let tangentsHelper = null; // VertexTangentsHelper visualization
let wavePoints = null; // Wave animation overlay
let waveMat = null; // Wave shader material

// Axes gizmo overlay (bottom-left)
let gizmoScene = null;
let gizmoCamera = null;
let gizmoAxes = null;

// View-locked light rig (attached to camera)
let lightRig = null;

// Picking state
let pickMode = "triangle";      // "vertex" | "edge" | "triangle"
let pickingEnabled = true;
const raycaster = new THREE.Raycaster();
const pointerNDC = new THREE.Vector2();
let pickables = [];             // meshes to raycast against

// Selection FX overlays
let triFX = null;     // THREE.Mesh
let edgeFX = null;    // THREE.Line
let pin = null;       // PinMarker for vertex selection

let pulseEnabled = false;
let pulseStart = 0;        // seconds
const pulseDuration = 0.6; // seconds

/* -------------------- Pin Marker for Vertex Selection -------------------- */

class PinMarker {
  constructor(scene, renderer, opts = {}) {
    this.scene = scene;
    this.renderer = renderer;

    this.length = opts.length ?? 18;          // world units; tune for your mesh scale
    this.headRadius = opts.headRadius ?? 2.0; // world units
    this.color = opts.color ?? 0xffcc00;

    // Thick line (Line2) stem
    this.lineGeom = new LineGeometry();
    this.lineGeom.setPositions([0, 0, 0, 0, 1, 0]); // placeholder

    this.lineMat = new LineMaterial({
      color: this.color,
      linewidth: opts.lineWidthPx ?? 2.5, // in pixels when worldUnits=false
      transparent: true,
      opacity: 1.0,
      depthTest: true,
      depthWrite: false,
      worldUnits: false
    });

    // IMPORTANT: LineMaterial requires resolution (pixels)
    this._updateResolution();

    this.line = new Line2(this.lineGeom, this.lineMat);
    this.line.computeLineDistances();

    // Sphere head
    const sphGeom = new THREE.SphereGeometry(this.headRadius, 16, 16);
    const sphMat = new THREE.MeshStandardMaterial({
      color: this.color,
      roughness: 0.25,
      metalness: 0.0,
      emissive: new THREE.Color(this.color),
      emissiveIntensity: 0.25
    });
    this.head = new THREE.Mesh(sphGeom, sphMat);

    // Group for convenience
    this.group = new THREE.Group();
    this.group.renderOrder = 50; // draw later
    this.group.add(this.line);
    this.group.add(this.head);

    this.scene.add(this.group);

    // State
    this.visible = false;
    this.group.visible = false;

    // Optional pulse
    this._pulse = { active: false, t0: 0, dur: 0.35 };
  }

  _updateResolution() {
    const size = new THREE.Vector2();
    this.renderer.getSize(size);
    this.lineMat.resolution.set(size.x, size.y);
  }

  onResize() {
    this._updateResolution();
  }

  setLength(length) {
    this.length = length;
  }

  hide() {
    this.visible = false;
    this.group.visible = false;
  }

  // mesh: the picked mesh
  // vidx: vertex index (0-based)
  setFromVertexIndex(mesh, vidx) {
    const g = mesh.geometry;
    const pos = g?.attributes?.position;
    if (!pos || vidx < 0 || vidx >= pos.count) return;

    // Vertex position in WORLD space
    const p = new THREE.Vector3().fromBufferAttribute(pos, vidx);
    mesh.localToWorld(p);

    // Direction: use vertex normal if available, else camera direction fallback
    let dir = new THREE.Vector3(0, 1, 0);
    const nAttr = g.attributes.normal;
    if (nAttr) {
      dir.fromBufferAttribute(nAttr, vidx);
      // transform normal to world direction
      dir.transformDirection(mesh.matrixWorld).normalize().negate();
    } else {
      // fallback: point toward camera a bit
      dir.subVectors(camera?.position ?? new THREE.Vector3(0,0,1), p).normalize();
    }

    const tip = new THREE.Vector3().copy(p).addScaledVector(dir, this.length);

    // Update stem geometry in world coordinates
    this.lineGeom.setPositions([
      p.x, p.y, p.z,
      tip.x, tip.y, tip.z
    ]);
    this.line.computeLineDistances();

    // Head at the tip
    this.head.position.copy(tip);

    // Show
    this.visible = true;
    this.group.visible = true;

    // Kick a small pulse
    this._pulse.active = true;
    this._pulse.t0 = performance.now() / 1000;
  }

  updatePulse(tSec) {
    if (!this.visible) return;

    const pulse = this._pulse;
    if (!pulse.active) return;

    const u = (tSec - pulse.t0) / pulse.dur;
    if (u >= 1) {
      pulse.active = false;
      this.head.scale.setScalar(1.0);
      this.lineMat.opacity = 1.0;
      return;
    }

    const w = Math.sin(Math.PI * u); // 0→1→0
    const s = 1.0 + 0.35 * w;
    this.head.scale.setScalar(s);
    this.lineMat.opacity = 0.75 + 0.25 * w;
  }
}

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
let SHOW_WAVE = false; // wave animation overlay

// Wave animation constants
const POINT_STRIDE = 6;          // use every Nth vertex (performance knob)
const BASE_POINT_SIZE = 1.5;     // in pixels-ish, scaled by distance in shader
const SIZE_GAIN = 6.0;
const TIME_SCALE = 0.0006;       // speed knob
const WAVE_OFFSET = 0.5;         // offset distance along normal (layers points above surface)

let meshOpacity = 1.0;           // mesh transparency (0 = transparent, 1 = opaque)

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
  
  // Picking: pointer event handler
  renderer.domElement.addEventListener("pointerdown", onPointerDown);

  // Initialize pin marker for vertex selection
  pin = new PinMarker(scene, renderer, {
    color: 0xffcc00,
    length: 18,
    headRadius: 2.0,
    lineWidthPx: 2.5
  });

  renderer.setAnimationLoop(() => {
    controls.update();
    updateAxesGizmo();
    updateTargetMarker();
    
    // Update selection pulse animation
    const t = performance.now() / 1000;
    updateSelectionPulse(t);
    pin?.updatePulse(t);
    
    // Update wave animation time uniform
    if (waveMat) {
      waveMat.uniforms.uTime.value = performance.now() * TIME_SCALE;
    }

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
      
      // Surface visibility obeys toggle state
      syncSurfaceVisibility();
      
      updateAxesGizmo();
      updateTargetMarker();
      
      // Collect meshes for picking
      collectPickables();
      
      // Wave animation obeys toggle state
      syncWaveVisibility();
      
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

export function setShowWave(show) {
  SHOW_WAVE = !!show;
  syncWaveVisibility();
  updateToggleButtonStates();
}

export function toggleWave() {
  SHOW_WAVE = !SHOW_WAVE;
  syncWaveVisibility();
  updateToggleButtonStates();
}

export function setMeshOpacity(opacity) {
  meshOpacity = THREE.MathUtils.clamp(opacity, 0, 1);
  updateMeshOpacity();
}

function updateMeshOpacity() {
  if (!loadedScene) return;
  
  loadedScene.traverse((obj) => {
    if (!obj.isMesh) return;
    
    const baseMat = obj.userData.baseMaterial;
    const wireMat = obj.userData.wireMaterial;
    
    if (baseMat) {
      baseMat.transparent = meshOpacity < 1.0;
      baseMat.opacity = meshOpacity;
      baseMat.needsUpdate = true;
    }
    
    if (wireMat) {
      wireMat.transparent = true; // wireframe always transparent
      wireMat.opacity = Math.min(0.25, meshOpacity);
      wireMat.needsUpdate = true;
    }
  });
}

/* -------------------- Picking API -------------------- */

export function setPickMode(mode) {
  if (mode === "vertex" || mode === "edge" || mode === "triangle") {
    pickMode = mode;
  } else {
    pickMode = "triangle";
  }
  console.log(`[Manifold3] Pick mode: ${pickMode}`);
}

export function setPickingEnabled(v) {
  pickingEnabled = !!v;
}

function collectPickables() {
  pickables = [];
  if (!loadedScene) return;

  loadedScene.traverse((obj) => {
    if (!obj.isMesh) return;

    // Recommended for cortex picking from inside/outside
    if (obj.material && obj.userData.baseMaterial) {
      obj.userData.baseMaterial.side = THREE.DoubleSide;
    }
    if (obj.material && obj.userData.wireMaterial) {
      obj.userData.wireMaterial.side = THREE.DoubleSide;
    }

    pickables.push(obj);
  });
  
  console.log(`[Manifold3] Collected ${pickables.length} pickable meshes`);
}

function updatePointerNDC(evt) {
  const rect = renderer.domElement.getBoundingClientRect();
  const x = ((evt.clientX - rect.left) / rect.width) * 2 - 1;
  const y = -(((evt.clientY - rect.top) / rect.height) * 2 - 1);
  pointerNDC.set(x, y);
}

function onPointerDown(evt) {
  if (!pickingEnabled || pickables.length === 0) return;

  updatePointerNDC(evt);
  raycaster.setFromCamera(pointerNDC, camera);

  const hits = raycaster.intersectObjects(pickables, true);
  if (!hits.length) return;

  const hit = hits[0];

  if (pickMode === "triangle") {
    pickTriangle(hit);
  } else if (pickMode === "vertex") {
    pickVertex(hit);
  } else if (pickMode === "edge") {
    pickEdge(hit);
  }
}

function getTriVertexIndices(geom, faceIndex) {
  const base = faceIndex * 3;
  if (geom.index) {
    return {
      i0: geom.index.getX(base + 0),
      i1: geom.index.getX(base + 1),
      i2: geom.index.getX(base + 2)
    };
  }
  return { i0: base + 0, i1: base + 1, i2: base + 2 };
}

function pickTriangle(hit) {
  const mesh = hit.object;
  const geom = mesh.geometry;
  if (!geom || hit.faceIndex == null) return;

  const tri = getTriVertexIndices(geom, hit.faceIndex);
  
  // Show visual feedback
  showTriangleHighlight(hit);
  const t = performance.now() / 1000;
  startPulse(t);
  
  // TODO: emit to MATLAB later
  console.log("[pick triangle]", tri, "faceIndex:", hit.faceIndex, "mesh:", mesh.name || "unnamed");
}

function pickVertex(hit) {
  const mesh = hit.object;
  const geom = mesh.geometry;
  if (!geom || hit.faceIndex == null) return;

  const tri = getTriVertexIndices(geom, hit.faceIndex);
  const pos = geom.attributes.position;

  const v0 = new THREE.Vector3().fromBufferAttribute(pos, tri.i0);
  const v1 = new THREE.Vector3().fromBufferAttribute(pos, tri.i1);
  const v2 = new THREE.Vector3().fromBufferAttribute(pos, tri.i2);

  // Compare in world space
  mesh.localToWorld(v0);
  mesh.localToWorld(v1);
  mesh.localToWorld(v2);

  const p = hit.point;
  const d0 = v0.distanceToSquared(p);
  const d1 = v1.distanceToSquared(p);
  const d2 = v2.distanceToSquared(p);

  let chosen = { idx: tri.i0, pt: v0, d: d0 };
  if (d1 < chosen.d) chosen = { idx: tri.i1, pt: v1, d: d1 };
  if (d2 < chosen.d) chosen = { idx: tri.i2, pt: v2, d: d2 };

  // Show visual feedback
  showVertexHighlight(hit);
  const t = performance.now() / 1000;
  startPulse(t);

  // TODO: emit to MATLAB later
  console.log("[pick vertex] idx:", chosen.idx);
}

function pickEdge(hit) {
  const mesh = hit.object;
  const geom = mesh.geometry;
  if (!geom || hit.faceIndex == null) return;

  const tri = getTriVertexIndices(geom, hit.faceIndex);
  const pos = geom.attributes.position;

  // Get triangle vertices in world space
  const a = new THREE.Vector3().fromBufferAttribute(pos, tri.i0); mesh.localToWorld(a);
  const b = new THREE.Vector3().fromBufferAttribute(pos, tri.i1); mesh.localToWorld(b);
  const c = new THREE.Vector3().fromBufferAttribute(pos, tri.i2); mesh.localToWorld(c);

  const p = hit.point;

  const e01 = distPointToSegmentSq(p, a, b);
  const e12 = distPointToSegmentSq(p, b, c);
  const e20 = distPointToSegmentSq(p, c, a);

  let best = { edge: [tri.i0, tri.i1], d: e01 };
  if (e12 < best.d) best = { edge: [tri.i1, tri.i2], d: e12 };
  if (e20 < best.d) best = { edge: [tri.i2, tri.i0], d: e20 };

  // Show visual feedback
  showEdgeHighlight(hit);
  const t = performance.now() / 1000;
  startPulse(t);

  console.log("[pick edge]", best.edge, "distSq:", best.d.toFixed(4));
}

function distPointToSegmentSq(p, a, b) {
  // Returns squared distance from point p to segment ab
  const ab = new THREE.Vector3().subVectors(b, a);
  const ap = new THREE.Vector3().subVectors(p, a);
  const t = THREE.MathUtils.clamp(ap.dot(ab) / ab.lengthSq(), 0, 1);
  const proj = new THREE.Vector3().copy(a).addScaledVector(ab, t);
  return proj.distanceToSquared(p);
}

/* -------------------- Selection Visual Feedback -------------------- */

function updateSelectionPulse(timeSec) {
  if (!pulseEnabled) return;

  const u = (timeSec - pulseStart) / pulseDuration;
  if (u >= 1) {
    pulseEnabled = false;
    // Leave highlight at steady visibility at end
    setFXOpacity(0.35);
    return;
  }

  // Smooth pulse: 0..1..0
  const w = Math.sin(Math.PI * u);              // 0->1->0
  const opacity = 0.15 + 0.35 * w;              // tune
  setFXOpacity(opacity);
}

function setFXOpacity(a) {
  if (triFX?.material) triFX.material.opacity = a;
  if (edgeFX?.material) edgeFX.material.opacity = Math.min(1, a + 0.25);
  // Note: pin marker has its own pulse animation via pin.updatePulse()
}

function startPulse(timeSec) {
  pulseEnabled = true;
  pulseStart = timeSec;
}

function showTriangleHighlight(hit) {
  clearSelectionFX();

  const mesh = hit.object;
  const geom = mesh.geometry;
  if (!geom || hit.faceIndex == null) return;

  const tri = getTriVertexIndices(geom, hit.faceIndex);
  const pos = geom.attributes.position;

  // Build in mesh LOCAL coordinates
  const a = new THREE.Vector3().fromBufferAttribute(pos, tri.i0);
  const b = new THREE.Vector3().fromBufferAttribute(pos, tri.i1);
  const c = new THREE.Vector3().fromBufferAttribute(pos, tri.i2);

  const triGeom = new THREE.BufferGeometry().setFromPoints([a, b, c]);
  triGeom.setIndex([0, 1, 2]);
  triGeom.computeVertexNormals();

  const triMat = new THREE.MeshBasicMaterial({
    color: 0xffaa00,
    transparent: true,
    opacity: 0.35,
    side: THREE.DoubleSide,
    depthTest: true,
    polygonOffset: true,
    polygonOffsetFactor: -2, // Pull slightly forward to avoid z-fighting
  });

  triFX = new THREE.Mesh(triGeom, triMat);

  // Attach to mesh so it inherits transforms (no world-matrix headaches)
  mesh.add(triFX);
}

function showEdgeHighlight(hit) {
  clearSelectionFX();

  const mesh = hit.object;
  const geom = mesh.geometry;
  if (!geom || hit.faceIndex == null) return;

  const tri = getTriVertexIndices(geom, hit.faceIndex);
  const pos = geom.attributes.position;

  const a = new THREE.Vector3().fromBufferAttribute(pos, tri.i0);
  const b = new THREE.Vector3().fromBufferAttribute(pos, tri.i1);
  const c = new THREE.Vector3().fromBufferAttribute(pos, tri.i2);

  // Compare distance in WORLD space to choose best edge
  const Aw = a.clone(); const Bw = b.clone(); const Cw = c.clone();
  mesh.localToWorld(Aw); mesh.localToWorld(Bw); mesh.localToWorld(Cw);

  const p = hit.point;
  const dAB = distPointToSegmentSq(p, Aw, Bw);
  const dBC = distPointToSegmentSq(p, Bw, Cw);
  const dCA = distPointToSegmentSq(p, Cw, Aw);

  let e0 = a, e1 = b;
  if (dBC < dAB && dBC <= dCA) { e0 = b; e1 = c; }
  else if (dCA < dAB && dCA < dBC) { e0 = c; e1 = a; }

  // Render edge in LOCAL space as a line attached to mesh
  const g = new THREE.BufferGeometry().setFromPoints([e0, e1]);
  const m = new THREE.LineBasicMaterial({ color: 0x00aaff, transparent: true, opacity: 0.6, linewidth: 2 });

  edgeFX = new THREE.Line(g, m);
  mesh.add(edgeFX);
}

function showVertexHighlight(hit) {
  clearSelectionFX();

  const mesh = hit.object;
  const geom = mesh.geometry;
  if (!geom || hit.faceIndex == null) return;

  const tri = getTriVertexIndices(geom, hit.faceIndex);
  const pos = geom.attributes.position;

  const v0 = new THREE.Vector3().fromBufferAttribute(pos, tri.i0);
  const v1 = new THREE.Vector3().fromBufferAttribute(pos, tri.i1);
  const v2 = new THREE.Vector3().fromBufferAttribute(pos, tri.i2);

  // Decide nearest in WORLD space
  const w0 = v0.clone(); const w1 = v1.clone(); const w2 = v2.clone();
  mesh.localToWorld(w0); mesh.localToWorld(w1); mesh.localToWorld(w2);

  const p = hit.point;
  const d0 = w0.distanceToSquared(p);
  const d1 = w1.distanceToSquared(p);
  const d2 = w2.distanceToSquared(p);

  let chosenIdx = tri.i0;
  if (d1 < d0 && d1 <= d2) chosenIdx = tri.i1;
  else if (d2 < d0 && d2 < d1) chosenIdx = tri.i2;

  // Use pin marker for vertex selection
  pin?.setFromVertexIndex(mesh, chosenIdx);
}

function clearSelectionFX() {
  if (triFX) {
    triFX.parent?.remove(triFX);
    triFX.geometry?.dispose?.();
    triFX.material?.dispose?.();
    triFX = null;
  }
  if (edgeFX) {
    edgeFX.parent?.remove(edgeFX);
    edgeFX.geometry?.dispose?.();
    edgeFX.material?.dispose?.();
    edgeFX = null;
  }
  pin?.hide();
  pulseEnabled = false;
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

/* -------------------- Wave Animation -------------------- */

function syncWaveVisibility() {
  if (!SHOW_WAVE) {
    if (wavePoints) {
      wavePoints.parent?.remove(wavePoints);
      wavePoints.geometry?.dispose?.();
      waveMat?.dispose?.();
      wavePoints = null;
      waveMat = null;
    }
    return;
  }

  if (!loadedScene) return;

  // Remove existing wave if present
  if (wavePoints) {
    wavePoints.parent?.remove(wavePoints);
    wavePoints.geometry?.dispose?.();
    waveMat?.dispose?.();
    wavePoints = null;
    waveMat = null;
  }

  // Find first mesh to build wave from
  let firstMesh = null;
  loadedScene.traverse((obj) => {
    if (!firstMesh && obj.isMesh && obj.geometry?.attributes?.position) {
      firstMesh = obj;
    }
  });

  if (!firstMesh) return;

  wavePoints = buildWavePointsFromMesh(firstMesh, {
    stride: POINT_STRIDE,
    baseSize: BASE_POINT_SIZE,
    sizeGain: SIZE_GAIN
  });
  
  // Parent to mesh so it inherits transforms
  firstMesh.add(wavePoints);
}

function buildWavePointsFromMesh(mesh, { stride, baseSize, sizeGain }) {
  const srcPos = mesh.geometry.attributes.position;
  const srcNorm = mesh.geometry.attributes.normal;
  const count = Math.floor(srcPos.count / stride);

  const positions = new Float32Array(count * 3);
  let j = 0;
  
  // Offset points along normals to layer above surface
  const offset = new THREE.Vector3();
  const pos = new THREE.Vector3();
  
  for (let i = 0; i < srcPos.count; i += stride) {
    pos.set(
      srcPos.getX(i),
      srcPos.getY(i),
      srcPos.getZ(i)
    );
    
    // Offset along normal if available
    if (srcNorm) {
      offset.set(
        srcNorm.getX(i),
        srcNorm.getY(i),
        srcNorm.getZ(i)
      ).normalize().multiplyScalar(WAVE_OFFSET);
      pos.add(offset);
    }
    
    positions[j++] = pos.x;
    positions[j++] = pos.y;
    positions[j++] = pos.z;
  }

  const geom = new THREE.BufferGeometry();
  geom.setAttribute("position", new THREE.BufferAttribute(positions, 3));

  waveMat = new THREE.ShaderMaterial({
    uniforms: {
      uTime: { value: 0.0 },
      uBaseSize: { value: baseSize },
      uSizeGain: { value: sizeGain }
    },
    vertexShader: /* glsl */ `
      uniform float uTime;
      uniform float uBaseSize;
      uniform float uSizeGain;

      varying float vScale;

      void main() {
        // Billboard-style wave field
        vec3 trTime = vec3(position.x + uTime, position.y + uTime, position.z + uTime);
        float scale = sin(trTime.x * 2.1) + sin(trTime.y * 3.2) + sin(trTime.z * 4.3);
        vScale = scale;

        vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);

        // Perspective-correct point sizing
        float s = uBaseSize + uSizeGain * (0.5 + 0.5 * sin(scale));
        gl_PointSize = s * (300.0 / -mvPosition.z);

        gl_Position = projectionMatrix * mvPosition;
      }
    `,
    fragmentShader: /* glsl */ `
      precision highp float;
      varying float vScale;

      // HSL to RGB conversion
      vec3 hue2rgb(float h) {
        h = mod(h, 1.0);
        float r = abs(h * 6.0 - 3.0) - 1.0;
        float g = 2.0 - abs(h * 6.0 - 2.0);
        float b = 2.0 - abs(h * 6.0 - 4.0);
        return clamp(vec3(r, g, b), 0.0, 1.0);
      }

      vec3 hsl2rgb(vec3 hsl) {
        vec3 rgb = hue2rgb(hsl.x);
        float c = (1.0 - abs(2.0 * hsl.z - 1.0)) * hsl.y;
        return (rgb - 0.5) * c + hsl.z;
      }

      void main() {
        // Make the point a circle (billboard disc)
        vec2 p = gl_PointCoord - vec2(0.5);
        float r = length(p);
        if (r > 0.5) discard;

        // Soft edge
        float alpha = smoothstep(0.5, 0.15, r);

        // Map vScale to a hue
        float hue = fract(vScale / 5.0);
        vec3 col = hsl2rgb(vec3(hue, 1.0, 0.55));

        gl_FragColor = vec4(col, alpha);
      }
    `,
    transparent: true,
    depthTest: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending
  });

  const pts = new THREE.Points(geom, waveMat);
  pts.frustumCulled = false;
  pts.renderOrder = 10;
  return pts;
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
  
  // Remove wave if present
  if (wavePoints) {
    wavePoints.parent?.remove(wavePoints);
    wavePoints.geometry?.dispose?.();
    waveMat?.dispose?.();
    wavePoints = null;
    waveMat = null;
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

function resize() {
  const w = canvas?.clientWidth ?? 0;
  const h = canvas?.clientHeight ?? 0;
  if (!w || !h) return;

  camera.aspect = w / h;
  camera.updateProjectionMatrix();
  renderer.setSize(w, h, false);
  pin?.onResize();

  updateAxesGizmo();
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
  const btnWave = document.getElementById("btnWave");

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
  if (btnWave) {
    btnWave.classList.toggle("active", SHOW_WAVE);
  }
}
