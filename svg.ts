var SVGNS = "http://www.w3.org/2000/svg";

export var svgElem = <SVGSVGElement><Element>document.getElementById("render");

export function sizeSVG(width: number, height: number) {
  svgElem.setAttribute("viewBox", "0 0 " + width + " " + height);
  svgElem.setAttribute("width", "" + width);
  svgElem.setAttribute("height", "" + height);
}

export function createSVG(tag: string, parent: SVGElement): SVGElement {
  var e = document.createElementNS(SVGNS, tag);
  parent.appendChild(e);
  return <SVGElement>e;
}

export function posSVG(elem: SVGElement, x: number, y: number): void {
  elem.setAttribute("x", "" + x);
  elem.setAttribute("y", "" + y);
}

export function svgBBox(elem: SVGElement): SVGRect {
  return <SVGRect>(elem["getBBox"]());
}
