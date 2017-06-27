var _opcodes = {
  "adc": true, "and": true, "asl": true, "bit": true, "bpl": true, "bmi": true,
  "bvc": true, "bvs": true, "bcc": true, "bcs": true, "bne": true, "beq": true,
  "brk": true, "cmp": true, "cpx": true, "cpy": true, "dec": true, "eor": true,
  "clc": true, "sec": true, "cli": true, "sei": true, "clv": true, "cld": true,
  "sed": true, "inc": true, "jmp": true, "jsr": true, "lda": true, "ldx": true,
  "ldy": true, "lsr": true, "nop": true, "ora": true, "tax": true, "txa": true,
  "dex": true, "inx": true, "tay": true, "tya": true, "dey": true, "iny": true,
  "ror": true, "rol": true, "rti": true, "rts": true, "sbc": true, "sta": true,
  "txs": true, "tsx": true, "pha": true, "pla": true, "php": true, "plp": true,
  "stx": true, "sty": true,
  "lda.wy": true, "sta.wy": true, "cmp.wy": true, // WTF?
};

export interface Param {
  str: string;
  addr?: Inst;    // possibly filled in on second pass
  imm?: number;   // ...
}

export interface Edge {
  from: Inst;
  to:   Inst;
  elem: SVGPathElement;
}

export interface Inst {
  label?: string;
  opcode: string;
  params: Param[];
  comment?: string;

  outEdge?: Edge;
  inEdges?: Edge[];

  elem?:   SVGElement;
}

var lastLabel: string;

function parseLine(line: string, lineNo: number, labels: {[label: string]: Inst}, constants: {[name: string]: number}) {
  line = line.trim();

  var inst: Inst = {
    opcode: null,
    params: [],
  };
  if (lastLabel) {
    inst.label = lastLabel;
    labels[lastLabel] = inst;
    lastLabel = null;
  }

  // Find comment, if any.
  var semiIdx = line.indexOf(';');
  if (semiIdx >= 0) {
    inst.comment = line.slice(semiIdx + 1).trim();
    line = line.slice(0, semiIdx);
  }

  // Tokenize what remains.
  // This is so shitbag, because there's no strtok().
  var tokens = line.split(/[\s,]/); // whitespace, or comma to separate instruction params
  for (var i = 0; i < tokens.length; i++) {
    tokens[i] = tokens[i].trim().toLowerCase();
    if (tokens[i] == "") {
      tokens.splice(i, 1);
      i--;
    }
  }

  if (tokens.length == 0) {
    if (inst.comment && inst.comment.length > 0) {
      // Comment-only line.
      return inst;
    }
    // Blank line.
    return null;
  }

  // Ignore various directives.
  switch (tokens[0]) {
    case "processor":
    case "org":
    case ".org":
    case "include":
    case "seg":
    case "seg.u":
    case "if":
    case "else":
    case "endif":
    case "mac":
    case "repeat":
    case "repend":
      return null;
  }

  // Label.
  if (tokens[0].indexOf(':') == tokens[0].length - 1) {
    var label = tokens[0].substr(0, tokens[0].length - 1).trim();
    tokens = tokens.slice(1);
  }

  if (tokens.length == 0) {
    lastLabel = label;
    return null;
  }

  labels[label] = inst;

  if (tokens[0] == ".byte" || tokens[0] == ".db" || tokens[0] == ".dw") {
    // Data.
    // TODO: .db, etc for NES.
    inst.opcode = tokens[0];
    inst.params = [];
    for (i = 1; i < tokens.length; i++) {
      inst.params.push({str: tokens[i]});
    }
  } else if (tokens[0] in _opcodes) {
    // Instruction.
    inst.opcode = tokens[0];
    for (i = 1; i < tokens.length; i++) {
      inst.params.push({str: tokens[i]});
    }
  } else if (tokens.length == 3 && tokens[1] == "=") {
    // Macro (e.g., `FOO = 42`).
    constants[tokens[0]] = parseValue(tokens[2]);
    return null;
  } else {
    // Nope.
    console.log(lineNo, "failed to parse line: '" + line + "'");
    return null;
  }

  return inst;
}

function parseValue(str: string): number {
  switch (str[0]) {
    case '$':
      return parseHex(str.slice(1));
    case '%':
      return parseBinary(str.slice(1));
  }

  return parseInt(str);
}

function parseHex(str: string): number {
  var v = 0;
  for (var i = 0; i < str.length; i++) {
    v <<= 4;
    var ch = str.charCodeAt(i);
    if (ch >= 48 && ch <= 57) {
      v += ch - 48;
    } else if (ch >= 97 && ch <= 102) {
      v += ch - 97 + 10;
    } else {
      console.log("failed to parse hex: '" + str + "'");
      return NaN;
    }
  }
  return v;
}

function parseBinary(str: string): number {
  var v = 0;
  for (var i = 0; i < str.length; i++) {
    v <<= 1;
    var ch = str.charCodeAt(i) - 48;
    if (ch == 0) {
    } else if (ch == 1) {
      v += 1;
    } else {
      console.log("failed to parse binary: '" + str + "'");
      return NaN;
    }
  }
  return v;
}

function resolveNode(inst: Inst, labels: {[label: string]: Inst}, constants: {[name: string]: number}): void {
  if (!inst.params) {
    return;
  }

  for (var i = 0; i < inst.params.length; i++) {
    var param = inst.params[i];
    var str = param.str;

    // Drop indirect addressing parens. Doesn't matter to us.
    if (str[0] == '(') {
      str = str.slice(0);
    }
    if (str[str.length - 1] == ')') {
      str = str.slice(0, str.length - 1);
    }

    switch (str[0]) {
      case '$':
        // Address.
        param.imm = parseValue(str);
        break;
      case '#':
        // Immediate. Ignore.
        break;
      default:
        resolveRef(param, str, labels, constants);
        break;
    }
  }
}

function resolveRef(param: Param, ref: string, labels: {[label: string]: Inst}, constants: {[name: string]: number}) {
  // Strip off low/hi byte crap. Not needed for our purposes.
  if (ref[0] == '<' || ref[0] == '>') {
    ref = ref.slice(1);
  }

  if (ref in labels) {
    param.addr = labels[ref];
  } else if (ref in constants) {
    param.imm = constants[ref];
  }
}

function hexStr(n: number): string {
  var str = [];
  while (n) {
    var nybble = n & 0xf;
    if (nybble < 10) {
      str.unshift(String.fromCharCode(48 + nybble));
    } else {
      str.unshift(String.fromCharCode(97 + nybble - 10));
    }
    n >>= 4;
  }
  return '$' + str.join('');
}

export function parseAsm(asm: string): Inst[] {
  var insts: Inst[] = [];
  var labels: {[label: string]: Inst} = {};
  var constants: {[name: string]: number} = {};

  var lines = asm.split("\n");
  for (var i = 0; i < lines.length; i++) {
    var node = parseLine(lines[i], i, labels, constants);
    if (node) {
      insts.push(node);
    }
  }
  for (var i = 0; i < insts.length; i++) {
    resolveNode(insts[i], labels, constants);
  }

  return insts;
}
