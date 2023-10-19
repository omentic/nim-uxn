import std/[macros, sequtils, strformat, sugar]
import types

macro handle(opcode: Opcode, body: varargs[untyped]): untyped =
  result = newTree(nnkCaseStmt)
  result.add(opcode)

  for branch in body:
    if branch.kind == nnkOfBranch and branch[1].kind == nnkStmtList and
       branch[1][0].kind == nnkInfix and branch[1][0][0] == ident("=>"):
      let function = branch[1][0]
      var parameters = newTree(nnkTupleConstr)
      var pushes = newTree(nnkStmtList)
      var pop8 = newTree(nnkTupleConstr)
      var pop16 = newTree(nnkTupleConstr)
      let pop8_literal = quote do: program.pop8()
      let pop16_literal = quote do: program.pop16()

      assert function[1].kind == nnkTupleConstr or function[1].kind == nnkPar
      for param in function[1]:
        case param.kind
        of nnkIdent:
          parameters.add(param)
          pop8.add(pop8_literal)
          pop16.add(pop16_literal)
        of nnkExprColonExpr:
          if param[1] == ident("byte"):
            pop8.add(pop8_literal)
            pop16.add(pop8_literal)
          elif param[1] == ident("short"):
            pop8.add(pop16_literal)
            pop16.add(pop16_literal)
          else:
            error("Expected type to be either byte or short!", param)
          parameters.add(param[0])
        else:
          error("Expected to find a tuple of parameters!", param)

      for operation in function[2]:
        pushes.add quote do:
          program.push(`operation`)

      result.add newTree(nnkOfBranch)
      result[^1].add branch[0]
      result[^1].add quote do:
        if program.opcode.short_mode():
          let `parameters` = `pop16`
          program.restore()
          `pushes`
        else:
          let `parameters` = `pop8`
          program.restore()
          `pushes`
    else:
      result.add(branch)
  debugecho "macro has been run"

func step*(program: var Program) =
  program.opcode = Opcode(program.main.get(program.pc))
  program.pc.inc()

  handle program.opcode.ins():
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
    if program.opcode.short_mode():
      let value = short((program.main.get(program.pc) shl 8) and program.main.get(program.pc+1))
      program.push(value)
    else:
      let value = program.main.get(program.pc)
      program.push(value)
    program.pc.inc()
  of JMP:
    if program.opcode.short_mode():
      program.pc = program.pop16()
    else:
      program.pc += int8(program.pop8())
    program.restore()
  of JCN:
    if program.opcode.short_mode():
      let (condition, address) = (program.pop16(), program.pop16())
      if condition != 0: program.pc = address
    else:
      let (condition, address) = (program.pop8(), program.pop8())
      if condition != 0: program.pc += int8(address)
    program.restore()
  of JSR:
    if program.opcode.short_mode():
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
  of LDR: (a: byte) => (program.main.get(program.pc +- int8(a)))
  of LDA: (a: short) => (program.main.get(a))
  of STZ: (a, b: byte) => (program.main.set(b, a))
  of STR: (a, b: byte) => (program.main.set(program.pc +- int8(b), a))
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
