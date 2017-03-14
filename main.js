var SVGNS = "http://www.w3.org/2000/svg";
var WIDTH = 4096;
var HEIGHT = 8192;

function printNode(node, includeComment) {
  var str = "";

  if (node.opcode) {
    str += node.opcode;
  }

  if (node.params) {
    str += " ";
    for (var i = 0; i < node.params.length; i++) {
      var param = node.params[i];
      str += param.str;
      if (i < node.params.length - 1) {
        str += ",";
      }
    }
  }

  if (includeComment && node.comment) {
    var l = 60 - str.length;
    for (var i = 0; i < l; i++) {
      str += " ";
    }

    str += " ;" + node.comment;
  }

  return str;
}

function createSVG(tag, parent) {
  var e = document.createElementNS(SVGNS, tag);
  parent.appendChild(e);
  return e;
}

function posSVG(elem, x, y) {
  elem.setAttribute("x", x);
  elem.setAttribute("y", y);
}

function renderCode(grp, params, svg) {
  grp.elem = createSVG("g", svg);

  var h = grp.nodes.length + 1;

  grp.w = 12 * 10;
  grp.h = h * 12;

  var y = 1;
  for (var i = 0; i < grp.nodes.length; i++) {
    var node = grp.nodes[i];
    var text = createSVG("text", grp.elem);
    posSVG(text, 0, 12 * y++);
    text.textContent = printNode(node, false);
  }
}

function renderBytes(grp, params, svg) {
  grp.elem = createSVG("g", svg);

  var maxWidth = 0;
  var y = 1;
  for (var i = 0; i < grp.nodes.length; i++) {
    var node = grp.nodes[i];
    var text = createSVG("text", grp.elem);
    posSVG(text, 0, 12 * y++);
    text.textContent = printNode(node, false);
    if (text.textContent.length > maxWidth) {
      maxWidth = text.textContent.length;
    }
  }

  grp.w = 12 * maxWidth;
  grp.h = y * 12;
}

function gatherBytes(grp) {
  var bytes = [];
  for (var i = 0; i < grp.nodes.length; i++) {
    var node = grp.nodes[i];
    if (isData(node)) {
      for (var j = 0; j < node.params.length; j++) {
        var param = node.params[j];
        bytes.push(parseValue(param.str));
      }
    }
  }
  return bytes;
}

function createPixel(color, x, y, w, h, parent) {
  var box = createSVG("rect", grp.elem);
  box.setAttribute("width", w);
  box.setAttribute("height", h);
  box.setAttribute("style", "fill:" + color);
  posSVG(box, x, y);
}

function renderImage(grp, params, svg) {
  grp.elem = createSVG("g", svg);

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

function positionGroup(grp) {
  grp.elem.setAttribute("transform", "translate(" + grp.x + ", " + grp.y + ")");
}

function renderGroup(grp, svg) {
  var kind = grp.kind.split("-");
  var params = kind.slice(1);
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

var codeElem = document.getElementById("code");
var code = codeElem.firstChild.textContent;
var nodes = parseAsm(code);
var groups = groupNodes(nodes);

var renderElem = document.getElementById("render");
renderElem.setAttribute("viewBox", "0 0 " + WIDTH + " " + HEIGHT);

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
