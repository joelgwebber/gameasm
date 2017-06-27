import {Group, groupInsts, isData} from "./grouper";
import {Edge, Inst, parseAsm} from "./parser";

var SVGNS = "http://www.w3.org/2000/svg";
var HEIGHT = 4096;

function printInst(inst: Inst, includeComment: boolean): string {
  var str = "";

  if (inst.label) {
    str += inst.label + ": ";
  }

  if (inst.opcode) {
    str += inst.opcode;
  }

  if (inst.params) {
    str += " ";
    for (var i = 0; i < inst.params.length; i++) {
      var param = inst.params[i];
      str += param.str;
      if (i < inst.params.length - 1) {
        str += ",";
      }
    }
  }

  if (includeComment && inst.comment) {
    var l = 60 - str.length;
    for (var i = 0; i < l; i++) {
      str += " ";
    }

    str += " ;" + inst.comment;
  }

  return str;
}

function createSVG(tag: string, parent: SVGElement): SVGElement {
  var e = document.createElementNS(SVGNS, tag);
  parent.appendChild(e);
  return <SVGElement>e;
}

function posSVG(elem: SVGElement, x: number, y: number): void {
  elem.setAttribute("x", "" + x);
  elem.setAttribute("y", "" + y);
}

function renderCode(grp: Group, params: string[], svg: SVGElement): void {
  var h = grp.insts.length + 1;

  grp.w = 12 * 10;
  grp.h = h * 12;

  var y = 1;
  for (var i = 0; i < grp.insts.length; i++) {
    var inst = grp.insts[i];
    var text = createSVG("text", grp.elem);
    posSVG(text, 0, 12 * y++);
    text.textContent = printInst(inst, false);
    inst.elem = text;

    for (var j = 0; j < inst.params.length; j++) {
      var p = inst.params[j];
      if (p.addr) {
        inst.outEdge = { from: inst, to: p.addr, elem: <SVGPathElement>createSVG("path", svg) };
        inst.outEdge.elem.setAttribute("stroke", "lightblue");
        if (!p.addr.inEdges) {
          p.addr.inEdges = [];
        }
        p.addr.inEdges.push(inst.outEdge);
      }
    }
  }
}

function renderBytes(grp: Group, params: string[], svg: SVGElement): void {
  var maxWidth = 0;
  var y = 1;
  for (var i = 0; i < grp.insts.length; i++) {
    var inst = grp.insts[i];
    var text = createSVG("text", grp.elem);
    posSVG(text, 0, 12 * y++);
    text.textContent = printInst(inst, false);
    inst.elem = text;
    if (text.textContent.length > maxWidth) {
      maxWidth = text.textContent.length;
    }
  }

  grp.w = 12 * maxWidth;
  grp.h = y * 12;
}

function gatherBytes(grp: Group): number[] {
  var bytes = [];
  for (var i = 0; i < grp.insts.length; i++) {
    var node = grp.insts[i];
    if (isData(node)) {
      for (var j = 0; j < node.params.length; j++) {
        var param = node.params[j];
        bytes.push(param.imm);
      }
    }
  }
  return bytes;
}

function createPixel(color: string, x: number, y: number, w: number, h: number, parent: SVGElement): void {
  var box = createSVG("rect", parent);
  box.setAttribute("width", "" + w);
  box.setAttribute("height", "" + h);
  box.setAttribute("style", "fill:" + color);
  posSVG(box, x, y);
}

function renderImage(grp: Group, params: string[], svg: SVGElement): void {
  var bpp = parseInt(params[0]);
  if (bpp != 1) {
    // That's all we support for now.
    return;
  }

  var byteWidth = parseInt(params[1]);
  var bytes = gatherBytes(grp);

  var y = 0, pos = 0;
  while (pos < bytes.length) {
    var x = 0;
    for (var i = 0; i < byteWidth; i++) {
      var b = bytes[pos++];
      var bit = 0x80;
      for (var j = 0; j < 8; j++) {
        if (b & bit) {
          createPixel("lightblue", x * 6, y * 6, 6, 6, grp.elem);
        }
        bit >>= 1;
        x++;
      }
    }
    x = 0;
    y++;
  }

  grp.w = byteWidth * 6 * 6;
  grp.h = y * 6;
}

function positionGroup(grp: Group): void {
  grp.elem.setAttribute("transform", "translate(" + grp.x + ", " + grp.y + ")");
}

function renderGroup(grp: Group, svg: SVGElement): void {
  var kind = grp.kind.split("-");
  var params = kind.slice(1);

  grp.elem = createSVG("g", svg);
  grp.elem.setAttribute("class", "Group");
  grp.elem.addEventListener("mousedown", (e) => groupMouseDown(e, grp) );

  switch (kind[0]) {
    case "code":
      renderCode(grp, params, svg);
      break;
    case "bytes":
      renderBytes(grp, params, svg);
      break;
    case "image":
      renderImage(grp, params, svg);
      break;
  }
}

function updateEdge(edge: Edge) {
  var r0 = edge.from.elem.getBoundingClientRect();
  var r1 = edge.to.elem.getBoundingClientRect();
  var x0 = r0.left + r0.width / 2;
  var y0 = r0.top;// + r0.height / 2;
  var x1 = r1.left + r1.width / 2;
  var y1 = r1.top;// + r1.height / 2;
  edge.elem.setAttribute("d", "M" + x0 + "," + y0 + " L" + x1 + "," + y1);
}

function updateAllEdges(groups: Group[]) {
  for (var i = 0; i < groups.length; i++) {
    var grp = groups[i];
    for (var j = 0; j < grp.insts.length; j++) {
      var inst = grp.insts[j];
      if (inst.outEdge) {
        updateEdge(inst.outEdge);
      }
    }
  }
}

function updateGroup(grp: Group) {
  positionGroup(grp);
  for (var i = 0; i < grp.insts.length; i++) {
    var inst = grp.insts[i];
    if (inst.outEdge) {
      updateEdge(inst.outEdge);
    }
    if (inst.inEdges) {
      for (var j = 0; j < inst.inEdges.length; j++) {
        updateEdge(inst.inEdges[j]);
      }
    }
  }
}

var dragGroup: Group;
var dragOffX: number;
var dragOffY: number;

function groupMouseDown(e: MouseEvent, grp: Group) {
  if (grp) {
    dragGroup = grp;
    var r = grp.elem.getBoundingClientRect();
    dragOffX = e.clientX - r.left;
    dragOffY = e.clientY - r.top;
  }
  e.preventDefault();
}

function mouseUp(e: MouseEvent) {
  dragGroup = null;
  e.preventDefault();
}

function mouseMove(e: MouseEvent) {
  if (dragGroup) {
    dragGroup.x = e.clientX - dragOffX;
    dragGroup.y = e.clientY - dragOffY;
    updateGroup(dragGroup);
    e.preventDefault();
  }
}

window.addEventListener("mouseup", mouseUp, true);
window.addEventListener("mousemove", mouseMove, true);

function fetchAsm(name, done: (asm: string) => void) {
  var xhr = new XMLHttpRequest();
  xhr.open("GET", name, true);
  xhr.onreadystatechange = () => {
    if (xhr.readyState == 4) {
      if (xhr.status == 200) {
        done(xhr.responseText);
      } else {
        alert("failed: " + xhr.statusText);
      }
    }
  };
  xhr.send();
}

fetchAsm("adventure.asm", (code) => {
  var insts = parseAsm(code);
  var groups = groupInsts(insts);

  var renderElem = <SVGSVGElement><Element>document.getElementById("render");

  var x = 0, y = 0;
  for (var i = 0; i < groups.length; i++) {
    var grp = groups[i];
    renderGroup(grp, renderElem);
    if (y + grp.h > HEIGHT) {
      x += 12 * 15;
      y = 0;
    }

    grp.x = x;
    grp.y = y;
    positionGroup(grp);

    y += grp.h;
  }

  updateAllEdges(groups);

  var width = (x + (12 * 15));
  renderElem.setAttribute("viewBox", "0 0 " + width + " " + HEIGHT);
  renderElem.setAttribute("width", "" + width);
  renderElem.setAttribute("height", "" + HEIGHT);
});
