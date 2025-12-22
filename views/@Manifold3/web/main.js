import { initViewer, loadGLB } from "./render.js";

function getParam(name) {
  return new URLSearchParams(window.location.search).get(name);
}

async function main() {
  const canvas = document.getElementById("canvas");
  const hud = document.getElementById("hud");

  // Default to fsaverage.glb, allow override via ?asset=...
  const assetUrl = getParam("asset") ?? "./assets/fsaverage.glb";

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
