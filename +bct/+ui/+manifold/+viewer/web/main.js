import { initViewer, loadModel, setPickMode, setPickingEnabled } from "./render.js";

function getParam(name) {
  return new URLSearchParams(window.location.search).get(name);
}

function setupPickerControls() {
  // button group behavior
  const buttons = [
    ["btnPickVertex", "vertex"],
    ["btnPickEdge", "edge"],
    ["btnPickFace", "triangle"]
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
        // Toggle: if already active, deactivate
        const isActive = btn.classList.contains("active");
        if (isActive) {
          btn.classList.remove("active");
          setPickingEnabled(false);
        } else {
          setPickMode(mode);
          setActive(btnId);
          setPickingEnabled(true);
        }
      });
    }
  }

  // Start with picking disabled (no mode selected)
  setPickingEnabled(false);
}

function setupFileLoader() {
  const btnLoad = document.getElementById("btnLoad");
  const fileSelect = document.getElementById("fileSelect");

  if (btnLoad && fileSelect) {
    btnLoad.addEventListener("click", () => {
      const selectedFile = fileSelect.value;
      loadModel(selectedFile).catch((err) => {
        console.error("Load error:", err);
      });
    });
  }
}

async function main() {
  const canvas = document.getElementById("canvas");
  const hud = document.getElementById("hud");

  // Default to fsaverage.glb, allow override via ?asset=...
  const assetUrl = getParam("asset") ?? "./assets/fsaverage.glb";
  
  // Setup picker control event listeners
  setupPickerControls();

  // Setup file loader controls
  setupFileLoader();

  // Set initial dropdown value to match loaded file
  const fileSelect = document.getElementById("fileSelect");
  if (fileSelect) {
    fileSelect.value = assetUrl;
  }

  // Initialize viewer (this also loads glbUrl by default)
  initViewer({ canvasEl: canvas, hudEl: hud, glbUrl: assetUrl });
}

main().catch((err) => {
  console.error(err);
  const hud = document.getElementById("hud");
  if (hud) hud.textContent = String(err);
});
