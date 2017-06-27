import {Inst} from "./parser";

export interface Group {
  kind:  string; // code, image, bytes
  insts: Inst[];

  x, y:  number;
  w, h:  number;

  elem:     SVGElement;
}

export function groupInsts(insts: Inst[]): Group[] {
  var groups = [];
  var grp = null;

  for (var i = 0; i < insts.length; i++) {
    var inst = insts[i];

    if (!grp) {
      // Time for a new group.
      grp = {
        kind:  groupKindForInst(inst),
        x: 0, y: 0,
        w: 0, h: 0,
        insts: []
      };
      groups.push(grp);
    }

    if (!grp.kind) {
      grp.kind = groupKindForInst(inst);
    }

    // Push onto the last group.
    if (!isComment(inst)) {
      grp.insts.push(inst);
    }

    var nextNode = insts[i + 1];
    if (shouldSplitGroup(grp, inst, nextNode)) {
      grp = null;
    }
  }

  return groups;
}

function groupKindForInst(inst: Inst): string {
  if (isData(inst)) {
    return "bytes";
  } else if (isCode(inst)) {
    return "code";
  }

  // Directive comments.
  if (inst.comment) {
    var dir = inst.comment;
    if (isDirective(inst)) {
      dir = dir.slice(2, dir.length - 2);
      return dir;
    }
  }

  return null;
}

function isDirective(inst: Inst): boolean {
  var cmt = inst.comment;
  return isComment(inst) && (cmt.indexOf("[[") == 0) && (cmt.indexOf("]]") == cmt.length - 2);
}

function shouldSplitGroup(grp: Group, inst: Inst, nextInst: Inst): boolean {
  if (!nextInst || isDirective(nextInst)) {
    return true;
  }

  switch (grp.kind) {
    case "code":
      return hasLabel(nextInst) || canBranch(inst) || isData(nextInst);
    case "image":
    case "bytes":
      return hasLabel(nextInst) || isCode(nextInst);
  }
  return false;
}

function isComment(inst: Inst): boolean {
  return !inst.opcode && !!inst.comment;
}

function isCode(inst: Inst): boolean {
  return !isData(inst) && !isComment(inst);
}

export function isData(inst: Inst): boolean {
  switch (inst.opcode) {
    case ".byte":
    case ".db":
    case ".dw":
      return true;
    default:
      return false;
  }
}

function canBranch(inst: Inst): boolean {
  switch (inst.opcode) {
    case "bcc":
    case "bcs":
    case "beq":
    case "bmi":
    case "bne":
    case "bpl":
    case "bvc":
    case "bvs":
    case "jmp":
    case "jsr":
    case "rts":
    case "rti":
      return true;
    default:
      return false;
  }
}

function hasLabel(inst: Inst): boolean {
  return !!inst.label;
}
