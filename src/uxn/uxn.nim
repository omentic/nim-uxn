import std/[macros, strformat]
import types

macro generate_branches(opcode: Opcode, body: varargs[untyped]): untyped =
  result = nnkCaseStmt.newTree()
  result.add(opcode)

  for branch in body:
    if branch.kind == nnkOfBranch and branch[1].kind == nnkStmtList and
       branch[1][0].kind == nnkInfix and branch[1][0][0] == ident("=>"):
      let function = branch[1][0]
      assert function[1].kind == nnkTupleConstr or function[1].kind == nnkPar

      var byte_branch = nnkStmtList.newTree()
      var short_branch = nnkStmtList.newTree()
      for param in function[1]:
        case param.kind
        of nnkIdent:
          byte_branch.add quote do:
            let `param` = program.pop8()
          short_branch.add quote do:
            let `param` = program.pop16()
        of nnkExprColonExpr:
          let name = param[0]
          if param[1] == ident("byte"):
            byte_branch.add quote do:
              let `name` = program.pop8()
            short_branch.add quote do:
              let `name` = program.pop8()
          elif param[1] == ident("short"):
            byte_branch.add quote do:
              let `name` = program.pop16()
            short_branch.add quote do:
              let `name` = program.pop16()
        else:
          error("Expected a tuple of parameters!")

      byte_branch.add quote do: program.restore()
      short_branch.add quote do: program.restore()

      case function[2].kind
      of nnkTupleConstr, nnkPar:
        for operation in function[2]:
          byte_branch.add quote do: program.push(`operation`)
          short_branch.add quote do: program.push(`operation`)
      of nnkBracket:
        for operation in function[2]:
          byte_branch.add(operation)
          short_branch.add(operation)
      else:
        error("Expected a tuple or a statement list!")

      result.add(nnkOfBranch.newTree())
      result[^1].add(branch[0])
      result[^1].add quote do:
        if program.opcode.short_mode():
          `short_branch`
        else:
          `byte_branch`
    else:
      result.add(branch)

func step*(program: var Program) =
  program.opcode = Opcode(program.main.get(program.pc))
  program.pc.inc()

  generate_branches program.opcode.ins():
  of BRK:
    discard # todo
  of JCI:
    if program.ws.pop() != 0:
      program.pc += program.main.get(program.pc)
    else:
      program.pc.inc()
  of JMI:
    program.pc += program.main.get(program.pc)
  of JSI:
    program.rs.push(program.pc + 1)
    program.pc += program.main.get(program.pc)
  of LIT:
    if program.opcode.short_mode():
      let value = short((program.main.get(program.pc) shl 8) and
                         program.main.get(program.pc+1))
      program.push(value)
    else:
      let value = program.main.get(program.pc)
      program.push(value)
    program.pc.inc()
    program.pc.inc()
  of JMP:
    if program.opcode.short_mode():
      program.pc = program.pop16()
    else:
      program.pc += int8(program.pop8())
    program.restore()
  of JCN:
    if program.opcode.short_mode():
      let (a, b) = (program.pop8(), program.pop16())
      if a != 0: program.pc = b
    else:
      let (a, b) = (program.pop8(), program.pop8())
      if a != 0: program.pc += int8(b)
    program.restore()
  of JSR:
    if program.opcode.short_mode():
      let a = program.pop16()
      program.rs.push(program.pc)
      program.pc = a
    else:
      let a = program.pop8()
      program.rs.push(program.pc)
      program.pc += int8(a)
    program.restore()

  # note: counterconventionally, (a, b: byte) here means (a: byte | short, b: byte)
  of LDZ: (a: byte) => (program.main.get(a))
  of LDR: (a: byte) => (program.main.get(program.pc +- int8(a)))
  of LDA: (a: short) => (program.main.get(a))
  of STZ: (a, b: byte) => [program.main.set(b, a)]
  of STR: (a, b: byte) => [program.main.set(program.pc +- int8(b), a)]
  of STA: (a, b: short) => [program.main.set(b, a)]
  of DEI: (a: byte) => (program.io.get(a)) # todo
  of DEO: (a, b: byte) => [program.io.set(b, a)] # todo
  of STH: (a) => [program.rs.push(a)]

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
