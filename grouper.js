// Group {
//   kind:  string; // code, image, bytes
//   nodes: Node[];
//
//   x, y:  number;
//   w, h:  number;
//   elem:  SVGElement;
// }
function groupNodes(nodes) {
  var groups = [];
  var grp = null;

  for (var i = 0; i < nodes.length; i++) {
    var node = nodes[i];

    if (!grp) {
      // Time for a new group.
      grp = {
        kind:  groupKindForNode(node),
        x: 0, y: 0,
        w: 0, h: 0,
        nodes: []
      };
      groups.push(grp);
      pending = [];
    }

    if (!grp.kind) {
      grp.kind = groupKindForNode(node);
    }

    // Push onto the last group.
    if (!isComment(node)) {
      grp.nodes.push(node);
    }

    var nextNode = nodes[i + 1];
    if (shouldSplitGroup(grp, node, nextNode)) {
      grp = null;
    }
  }

  return groups;
}

function groupKindForNode(node) {
  if (isData(node)) {
    return "bytes";
  } else if (isCode(node)) {
    return "code";
  }

  // Directive comments.
  if (node.comment) {
    var dir = node.comment;
    if (isDirective(node)) {
      dir = dir.slice(2, dir.length - 2);
      return dir;
    }
  }

  return null;
}

function isDirective(node) {
  var cmt = node.comment;
  return isComment(node) && (cmt.indexOf("[[") == 0) && (cmt.indexOf("]]") == cmt.length - 2);
}

function shouldSplitGroup(grp, node, nextNode) {
  if (!nextNode || isDirective(nextNode)) {
    return true;
  }

  switch (grp.kind) {
    case "code":
      return isReturn(node) || isData(nextNode);
    case "image":
    case "bytes":
      return isCode(nextNode);
  }
  return false;
}

function isComment(node) {
  return !node.opcode && node.comment;
}

function isCode(node) {
  return !isData(node) && !isComment(node);
}

function isData(node) {
  switch (node.opcode) {
    case ".byte":
    case ".db":
    case ".dw":
      return true;
    default:
      return false;
  }
}

function isReturn(node) {
  switch (node.opcode) {
    case "rts":
    case "rti":
      return true;
    default:
      return false;
  }
}

