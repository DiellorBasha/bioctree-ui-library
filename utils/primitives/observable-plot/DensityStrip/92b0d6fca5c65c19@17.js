function _1(md){return(
md`<div style="color: grey; font: 13px/25.5px var(--sans-serif); text-transform: uppercase;"><h1 style="display: none;">Plot: One-dimensional density</h1><a href="/plot">Observable Plot</a> › <a href="/@observablehq/plot-gallery">Gallery</a></div>

# One-dimensional density

Although it is inherently two-dimensional, the [density](https://observablehq.com/plot/marks/density) mark is compatible with one-dimensional data. For a more accurate estimation of one-dimensional densities, please upvote issue [#1469](https://github.com/observablehq/plot/issues/1469).`
)}

function _2(Plot,faithful){return(
Plot.plot({
  height: 100,
  inset: 10,
  marks: [
    Plot.density(faithful, {x: "waiting", stroke: "steelblue", strokeWidth: 0.25, bandwidth: 10}),
    Plot.density(faithful, {x: "waiting", stroke: "steelblue", thresholds: 4, bandwidth: 10}),
    Plot.dot(faithful, {x: "waiting", fill: "currentColor", r: 1.5})
  ]
})
)}

function _faithful(FileAttachment){return(
FileAttachment("faithful.tsv").tsv({typed: true})
)}

export default function define(runtime, observer) {
  const main = runtime.module();
  function toString() { return this.url; }
  const fileAttachments = new Map([
    ["faithful.tsv", {url: new URL("./files/4c881d9f7d1638711375d1a555b856b4580cd47c16a41fa7446ccbd8e63d90543b81aaca584bab5cc75b295ce38ee1461010792e123724364f41709b936120ac.tsv", import.meta.url), mimeType: "text/tab-separated-values", toString}]
  ]);
  main.builtin("FileAttachment", runtime.fileAttachments(name => fileAttachments.get(name)));
  main.variable(observer()).define(["md"], _1);
  main.variable(observer()).define(["Plot","faithful"], _2);
  main.variable(observer("faithful")).define("faithful", ["FileAttachment"], _faithful);
  return main;
}
