function _1(md){return(
md`<div style="color: grey; font: 13px/25.5px var(--sans-serif); text-transform: uppercase;"><h1 style="display: none;">Plot: Horizon Chart</h1><a href="/plot">Observable Plot</a> › <a href="/@observablehq/plot-gallery">Gallery</a></div>

# Horizon Chart

Horizon charts are an alternative to [ridgeline plots](/@observablehq/plot-ridgeline) and small-multiple area charts that allow greater precision for a given vertical space by using colored bands. These charts can be used with diverging color scales to differentiate positive and negative values. See also the [D3 version](/@d3/horizon-chart/2). Data: [Christopher Möller](https://gist.github.com/chrtze/c74efb46cadb6a908bbbf5227934bfea).`
)}

function _bands(Inputs){return(
Inputs.range([2, 8], {step: 1, label: "Bands"})
)}

function _chart(Plot,step,traffic,d3,bands){return(
Plot.plot({
  height: 1100,
  width: 928,
  x: {axis: "top"},
  y: {domain: [0, step], axis: null},
  fy: {axis: null, domain: traffic.map((d) => d.name), padding: 0.05},
  color: {
    type: "ordinal",
    scheme: "Greens",
    label: "Vehicles per hour",
    tickFormat: (i) => ((i + 1) * step).toLocaleString("en"),
    legend: true
  },
  marks: [
    d3.range(bands).map((band) => Plot.areaY(traffic, {x: "date", y: (d) => d.value - band * step, fy: "name", fill: band, sort: "date", clip: true})),
    Plot.axisFy({frameAnchor: "left", dx: -28, fill: "currentColor", textStroke: "white", label: null})
  ]
})
)}

function _traffic(FileAttachment){return(
FileAttachment("traffic.csv").csv({typed: true})
)}

function _step(d3,traffic,bands){return(
+(d3.max(traffic, (d) => d.value) / bands).toPrecision(2)
)}

export default function define(runtime, observer) {
  const main = runtime.module();
  function toString() { return this.url; }
  const fileAttachments = new Map([
    ["traffic.csv", {url: new URL("./files/4ea24221b4db5e916702f2056cc385f5a14a80a44c7c304af89957c5cb6c5707cf64372ab0c4ecd9858375af251ce70e9eb397da832f22afc57faf2f54eec9f9.csv", import.meta.url), mimeType: "text/csv", toString}]
  ]);
  main.builtin("FileAttachment", runtime.fileAttachments(name => fileAttachments.get(name)));
  main.variable(observer()).define(["md"], _1);
  main.variable(observer("viewof bands")).define("viewof bands", ["Inputs"], _bands);
  main.variable(observer("bands")).define("bands", ["Generators", "viewof bands"], (G, _) => G.input(_));
  main.variable(observer("chart")).define("chart", ["Plot","step","traffic","d3","bands"], _chart);
  main.variable(observer("traffic")).define("traffic", ["FileAttachment"], _traffic);
  main.variable(observer("step")).define("step", ["d3","traffic","bands"], _step);
  return main;
}
