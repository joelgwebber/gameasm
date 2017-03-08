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

// nodes: Node {
//   addr: number;    // may be -1
//   bytes: number;
//   opcode: string;
//   params: {
//     str: string;
//     addr: number;  // possibly filled in on second pass
//     imm: number;   // ...
//   }[];
//   comment: string;
// }[]
//
// labels: string => address/value
function parseLine(line, lineNo, addr, labels) {
  line = line.trim();

  var node = {
    addr: -1,
    bytes: 0
  };

  // Find comment, if any.
  var semiIdx = line.indexOf(';');
  if (semiIdx >= 0) {
    node.comment = line.slice(semiIdx + 1).trim();
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
    if (node.comment && node.comment.length > 0) {
      // Comment-only line.
      return node;
    }
    // Blank line.
    return null;
  }

  // Ignore processor and org directives.
  if (tokens[0] == "processor" || tokens[0] == "org") {
    return null;
  }

  // Label.
  if (tokens[0].endsWith(':')) {
    var label = tokens[0].substr(0, tokens[0].length - 1).trim();
    labels[label] = addr;
    tokens = tokens.slice(1);
  }

  if (tokens.length == 0) {
    return null;
  }

  node.bytes = 1; // fake, but good enough for us
  node.addr = addr;
  if (tokens[0] == ".byte") {
    // Data.
    // TODO: .db, etc for NES.
    node.opcode = tokens[0];
    node.params = [];
    for (i = 1; i < tokens.length; i++) {
      node.params.push({ str: tokens[i] });
    }
  } else if (tokens[0] in _opcodes) {
    // Instruction.
    var node = {
      opcode: tokens[0],
      params: []
    };
    for (i = 1; i < tokens.length; i++) {
      node.params.push({ str: tokens[i] });
    }
  } else if (tokens.length == 3 && tokens[1] == "=") {
    // Macro (e.g., `FOO = 42`).
    labels[tokens[0]] = parseValue(tokens[2]);
    return null;
  } else {
    // Nope.
    console.log(lineNo, "failed to parse line: '" + line + "'");
    return null;
  }

  return node;
}

function parseValue(str) {
  switch (str[0]) {
    case '$': return parseHex(str.slice(1));
    case '%': return parseBinary(str.slice(1));
  }

  console.log("failed to parse immediate: '" + str + "'");
  return NaN;
}

function parseHex(str) {
  val = 0;
  for (var i = 0; i < str.length; i++) {
    val <<= 4;
    var ch = str.charCodeAt(i);
    if (ch >= 48 && ch <= 57) {
      val += ch - 48;
    } else if (ch >= 97 && ch <= 102) {
      val += ch - 97 + 10;
    } else {
      console.log("failed to parse hex: '" + str + "'");
      return NaN;
    }
  }
  return val;
}

function parseBinary(str) {
  val = 0;
  for (var i = 0; i < str.length; i++) {
    val <<= 1;
    var ch = str.charCodeAt(i) - 48;
    if (ch == '0') {
    } else if (ch == '1') {
      val += 1;
    } else {
      console.log("failed to parse binary: '" + str + "'");
      return NaN;
    }
  }
  return val;
}

function resolveNode(node, labels) {
  if (!node.params) {
    return;
  }

  for (var i = 0; i < node.params.length; i++) {
    var param = node.params[i];
    var str = param.str;

    // Drop indirect addressing parens. Doesn't matter to us.
    if (str[0] == '(') {
      str = str.slice(0);
    }
    if (str[str.length-1] == ')') {
      str = str.slice(0, str.length-1);
    }

    switch (str[0]) {
      case '$':
        // Address.
        param.addr = parseValue(str);
        break;
      case '#':
        // Immediate. Ignore.
        break;
      default:
        param.addr = parseLabelRef(str, labels);
        break;
    }
  }
}

function parseLabelRef(ref, labels) {
  // Strip off low/hi byte crap. Not needed for our purposes.
  if (ref[0] == '<' || ref[0] == '>') {
    ref = ref.slice(1);
  }

  if (ref in labels) {
    return labels[ref];
  }

  return NaN;
}

function hexStr(n) {
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

function parseAsm(asm) {
  var nodes = [];
  var labels = {};

  var addr = 0;
  var lines = asm.split("\n");
  for (var i = 0; i < lines.length; i++) {
    var node = parseLine(lines[i], i, addr, labels);
    if (node) {
      nodes.push(node);
      addr += node.bytes;
    }
  }
  for (var i = 0; i < nodes.length; i++) {
    resolveNode(nodes[i], labels);
  }

  return nodes;
}

