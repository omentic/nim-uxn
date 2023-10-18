import opcodes, types
import std/[sequtils, strformat, sugar]

macro handle(program: var Program, body: untyped) =
  result = newTree(nnkCaseStmt)
  result.add(body[0])

  for branch in body[1 ..< ^1]:
    if branch.kind == nnkInfix and branch[0] == ident("=>"):
      var parameters: NimNode = newTree(nnkTupleConstr)
      var pop8: NimNode = newTree(nnkTupleConstr)
      var pop16: NimNode = newTree(nnkTupleConstr)
      let pop8_literal = quote do: program.pop8()
      let pop16_literal = quote do: program.pop16()
      let operation = branch[2]
      for param in parameters:
        if param.kind == nnkIdent:
          parameters.append(param)
          pop8.append(pop8_literal)
          pop16.append(pop16_literal)
        else:
          assert param.kind == nnkExprColonExpr
          if param[1] == ident("byte"):
            pop8.append(pop8_literal)
            pop16.append(pop8_literal)
          elif param[1] == ident("short"):
            pop8.append(pop16_literal)
            pop16.append(pop16_literal)
          else:
            raise Error
          parameters.add(param[0])

      # Nim doesn't like `let (a) = (function)`
      if pop8.sons.len == 1 or pop16.sons.len == 1:
        pop8 = pop8_literal
        pop16 = pop16_literal

      result.add quote do:
        if program.opcode.short():
          let `parameters` = `pop16`
          program.restore()
          program.push(`operation`)
        else:
          let `parameters` = `pop8`
          program.restore()
          program.push(`operation`)

    else:
      result.add(branch)

func step*(program: var Program) =
  program.opcode = program.main.get(program.pc)
  program.pc.inc()

  handle program.opcode.ins()
  of BRK:
    discard # todo
  of JCI:
    if program.ws.pop() != 0: program.pc += program.main.get(program.pc)
    else: program.pc.inc()
  of JMI:
    program.pc += program.main.get(program.pc)
  of JSI:
    program.rs.push(program.pc + 2)
    program.pc += program.main.get(program.pc)
  of LIT:
    if program.opcode.short():
      let value = program.pop16()
      program.restore() # LIT always has keep enabled
      program.push(value)
    else:
      let value = program.pop8()
      program.restore()
      program.push(value)
    program.pc.inc()
  of JMP:
    if program.opcode.short():
      program.pc = program.pop16()
    else:
      program.pc += int8(program.pop8())
    program.restore()
  of JCN:
    if program.opcode.short():
      let (condition, address) = (program.pop16(), program.pop16())
      if condition != 0: program.pc = address
    else:
      let (condition, address) = (program.pop8(), program.pop8())
      if condition != 0: program.pc += int8(address)
    program.restore()
  of JSR:
    if program.opcode.short():
      let value = program.pop16()
      program.rs.push(program.pc)
      program.pc = value
    else:
      let value = program.pop8()
      program.rs.push(program.pc)
      program.pc += int8(value)
    program.restore()

  # note: counterconventionally, (a, b: byte) here means (a: byte | short, b: byte)
  of LDZ: (a: byte) => (program.main.get(a))
  of LDR: (a: byte) => (program.main.get(program.pc + int8(b)))
  of LDA: (a: short) => (program.main.get(a))
  of STZ: (a, b: byte) => (program.main.set(b, a))
  of STR: (a, b: byte) => (program.main.set(program.pc + int8(b), a))
  of STA: (a, b: short) => (program.main.set(b, a))
  of DEI: (a: byte) => (program.io.get(a)) # todo
  of DEO: (a, b: byte) => (program.io.set(b, a)) # todo
  of STH: (a) => (program.rs.push(a))

  of INC: (a) => (a + 1)
  of POP: (a) => ()
  of NIP: (a, b) => (b)
  of SWP: (a, b) => (b, a)
  of ROT: (a, b, c) => (b, c, a)
  of DUP: (a) => (a, a)
  of OVR: (a, b) => (a)
  of EQU: (a, b) => (typeof(a)(a == b))
  of NEQ: (a, b) => (typeof(a)(a != b))
  of GTH: (a, b) => (typeof(a)(a > b))
  of LTH: (a, b) => (typeof(a)(a < b))

  of ADD: (a, b) => (a + b)
  of SUB: (a, b) => (a - b)
  of MUL: (a, b) => (a * b)
  of DIV: (a, b) => (a // b)
  of AND: (a, b) => (a and b)
  of ORA: (a, b) => (a or b)
  of EOR: (a, b) => (a xor b)
  of SFT: (a, b) => ((b shr (a and 0b00001111'u8)) shl (a shr 4))

  else: raise newException(ValueError, &"Unknown opcode {program.opcode.ins()}. Crashing...")

func eval*(program: var Program) =
  while true:
    program.step()
