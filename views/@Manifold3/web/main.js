import { initViewer, loadGLB, toggleSurface, toggleWireframe, toggleNormals, toggleTangents, toggleWave, setPickMode, setMeshOpacity } from "./render.js";

function getParam(name) {
  return new URLSearchParams(window.location.search).get(name);
}

function setupToggleControls() {
  const btnSurface = document.getElementById("btnSurface");
  const btnWireframe = document.getElementById("btnWireframe");
  const btnNormals = document.getElementById("btnNormals");
  const btnTangents = document.getElementById("btnTangents");
  const btnWave = document.getElementById("btnWave");

  if (btnSurface) {
    btnSurface.addEventListener("click", () => {
      toggleSurface();
    });
  }

  if (btnWireframe) {
    btnWireframe.addEventListener("click", () => {
      toggleWireframe();
    });
  }

  if (btnNormals) {
    btnNormals.addEventListener("click", () => {
      toggleNormals();
    });
  }
  
  if (btnTangents) {
    btnTangents.addEventListener("click", () => {
      toggleTangents();
    });
  }
  
  if (btnWave) {
    btnWave.addEventListener("click", () => {
      toggleWave();
    });
  }
}

function setupPickerControls() {
  // button group behavior
  const buttons = [
    ["btnPickVertex", "vertex"],
    ["btnPickEdge", "edge"],
    ["btnPickTri", "triangle"]
  ];

  function setActive(id) {
    for (const [btnId] of buttons) {
      const btn = document.getElementById(btnId);
      if (btn) btn.classList.toggle("active", btnId === id);
    }
  }

  for (const [btnId, mode] of buttons) {
    const btn = document.getElementById(btnId);
    if (btn) {
      btn.addEventListener("click", () => {
        setPickMode(mode);
        setActive(btnId);
      });
    }
  }

  // default to triangle
  setPickMode("triangle");
  setActive("btnPickTri");
}

function setupOpacityControl() {
  const slider = document.getElementById("meshOpacitySlider");
  
  if (slider) {
    slider.addEventListener("input", (evt) => {
      const value = parseFloat(evt.target.value) / 100; // Convert 0-100 to 0-1
      setMeshOpacity(value);
    });
  }
}

async function main() {
  const canvas = document.getElementById("canvas");
  const hud = document.getElementById("hud");

  // Default to fsaverage.glb, allow override via ?asset=...
  const assetUrl = getParam("asset") ?? "./assets/fsaverage.glb";

  // Setup toggle control event listeners
  setupToggleControls();
  
  // Setup picker control event listeners
  setupPickerControls();
  
  // Setup opacity control
  setupOpacityControl();

  // Initialize viewer (this also loads glbUrl by default)
  initViewer({ canvasEl: canvas, hudEl: hud, glbUrl: assetUrl });

  // If you prefer initViewer to not auto-load, you could instead do:
  // initViewer({ canvasEl: canvas, hudEl: hud });
  // await loadGLB(assetUrl);
}

main().catch((err) => {
  console.error(err);
  const hud = document.getElementById("hud");
  if (hud) hud.textContent = String(err);
});
