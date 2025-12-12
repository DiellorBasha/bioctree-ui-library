function _1(md){return(
md`<div style="color: grey; font: 13px/25.5px var(--sans-serif); text-transform: uppercase;"><h1 style="display: none;">Plot: Multiple line chart</h1><a href="/plot">Observable Plot</a> › <a href="/@observablehq/plot-gallery">Gallery</a></div>

# Multiple line chart

Use the **z** channel (or **stroke**, or **fill**) to group [tidy data](https://r4ds.had.co.nz/tidy-data.html) into series and create multiple lines.`
)}

function _2(Plot,bls){return(
Plot.plot({
  y: {
    grid: true,
    label: "↑ Unemployment (%)"
  },
  marks: [
    Plot.ruleY([0]),
    Plot.lineY(bls, {x: "date", y: "unemployment", z: "division"})
  ]
})
)}

function _bls(FileAttachment){return(
FileAttachment("bls-metro-unemployment.csv").csv({typed: true})
)}

export default function define(runtime, observer) {
  const main = runtime.module();
  function toString() { return this.url; }
  const fileAttachments = new Map([
    ["bls-metro-unemployment.csv", {url: new URL("./files/cf77aaa2e0dab4123d57f8421210e5fa6955d75017369c93e3086b7369e4a040e398ed494b71d541a9c0c72575ac29cdc9e7038b6ae681cc1d761fec2c99a85f.csv", import.meta.url), mimeType: "text/csv", toString}]
  ]);
  main.builtin("FileAttachment", runtime.fileAttachments(name => fileAttachments.get(name)));
  main.variable(observer()).define(["md"], _1);
  main.variable(observer()).define(["Plot","bls"], _2);
  main.variable(observer("bls")).define("bls", ["FileAttachment"], _bls);
  return main;
}
