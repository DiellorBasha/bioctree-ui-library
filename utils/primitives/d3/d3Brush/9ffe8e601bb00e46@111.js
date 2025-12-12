// https://observablehq.com/@d3/brush-snapping@111
function _1(md){return(
md`# Brush Snapping

The brush below snaps to twelve-hour boundaries. The brush fires *brush* events during brushing, allowing a listener to modify the brush selection by calling *brush*.move. By testing *event*.sourceEvent, this avoids an infinite loop.`
)}

function _chart(d3,width,height,margin,xAxis,x,interval)
{
  const svg = d3.create("svg")
      .attr("viewBox", [0, 0, width, height]);

  const brush = d3.brushX()
      .extent([[margin.left, margin.top], [width - margin.right, height - margin.bottom]])
      .on("brush", brushed);

  svg.append("g")
      .call(xAxis);

  svg.append("g")
      .call(brush);

  function brushed(event) {
    if (!event.sourceEvent) return;
    const d0 = event.selection.map(x.invert);
    const d1 = d0.map(interval.round);

    // If empty when rounded, use floor instead.
    if (d1[0] >= d1[1]) {
      d1[0] = interval.floor(d0[0]);
      d1[1] = interval.offset(d1[0]);
    }

    d3.select(this).call(brush.move, d1.map(x));
  }

  return svg.node();
}


function _interval(d3){return(
d3.timeHour.every(12)
)}

function _x(d3,width,margin){return(
d3.scaleTime()
    .domain([new Date(2013, 7, 1), new Date(2013, 7, width / 60) - 1])
    .rangeRound([margin.left, width - margin.right])
)}

function _xAxis(height,margin,d3,x,interval){return(
g => g
    .attr("transform", `translate(0,${height - margin.bottom})`)
    .call(g => g.append("g")
        .call(d3.axisBottom(x)
            .ticks(interval)
            .tickSize(-height + margin.top + margin.bottom)
            .tickFormat(() => null))
        .call(g => g.select(".domain")
            .attr("fill", "#ddd")
            .attr("stroke", null))
        .call(g => g.selectAll(".tick line")
            .attr("stroke", "#fff")
            .attr("stroke-opacity", d => d <= d3.timeDay(d) ? 1 : 0.5)))
    .call(g => g.append("g")
        .call(d3.axisBottom(x)
            .ticks(d3.timeDay)
            .tickPadding(0))
        .attr("text-anchor", null)
        .call(g => g.select(".domain").remove())
        .call(g => g.selectAll("text").attr("x", 6)))
)}

function _margin(){return(
{top: 10, right: 0, bottom: 20, left: 0}
)}

function _height(){return(
120
)}

export default function define(runtime, observer) {
  const main = runtime.module();
  main.variable(observer()).define(["md"], _1);
  main.variable(observer("chart")).define("chart", ["d3","width","height","margin","xAxis","x","interval"], _chart);
  main.variable(observer("interval")).define("interval", ["d3"], _interval);
  main.variable(observer("x")).define("x", ["d3","width","margin"], _x);
  main.variable(observer("xAxis")).define("xAxis", ["height","margin","d3","x","interval"], _xAxis);
  main.variable(observer("margin")).define("margin", _margin);
  main.variable(observer("height")).define("height", _height);
  return main;
}
