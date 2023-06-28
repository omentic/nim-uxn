import magic, opcodes, types
import std/[strformat, sugar]

func step*(program: var Program) =
  program.opcode = program.main.get(program.pc)
  case program.opcode.demode()
  of BRK:
    discard
  of JCI:
    if program.ws.pop() != 0: program.pc += program.main.get(program.pc + 1)
    else: inc program.pc
  of JMI:
    program.pc += program.main.get(program.pc + 1)
  of JSI:
    program.rs.push(program.pc + 2)
    program.pc += program.main.get(program.pc + 1)
  of LIT:
    if program.opcode.short(): program.push(program.pop16())
    else: program.push(program.pop8())
    inc program.pc
  of JMP:
    if program.opcode.short(): program.pc = program.pop16()
    else: program.pc += int8(program.pop8())
  of JCN:
    if program.opcode.short():
      let (condition, address) = program.pop16x2()
      if condition != 0: program.pc = address
    else:
      let (condition, address) = program.pop8x2()
      if condition != 0: program.pc += int8(address)
  of JSR:
    program.rs.push(program.pc + 1)
    if program.opcode.short(): program.pc = program.pop16()
    else: program.pc += int8(program.pop8())
  of INC: program.handle((a) => (a+1))
  of POP: program.handle((a) => ())
  of NIP: program.handle((a, b) => (b))
  of SWP: program.handle((a, b) => (b, a))
  of ROT: program.handle((a, b, c) => (b, c, a))
  of DUP: program.handle((a) => (a, a))
  of OVR: program.handle((a, b) => (a))
  of EQU: program.handle((a, b) => (typeof(a)(a == b)))
  of NEQ: program.handle((a, b) => (typeof(a)(a != b)))
  of GTH: program.handle((a, b) => (typeof(a)(a > b)))
  of LTH: program.handle((a, b) => (typeof(a)(a < b)))
  of STH: program.handle((a) => (program.rs.push(a)))
  of LDZ: program.handle((a) => (program.main.get(a)))
  of STZ: program.handle((a, b) => (program.main.set(b, a)))
  of LDR: program.handle((a) => (program.main.get(program.pc + int8(a))))
  of STR: program.handle((a, b) => (program.main.set(program.pc + int8(b), a)))
  of LDA: program.handle((a, b) => (program.main.get(short(a, b))))
  of STA: program.handle((a, b, c) => (program.main.set(short(b, c), a)))
  of DEI: program.handle((a) => (program.io.get(a)))
  of DEO: program.handle((a, b) => (program.io.set(b, a)))
  of ADD: program.handle((a, b) => (a+b))
  of SUB: program.handle((a, b) => (a-b))
  of MUL: program.handle((a, b) => (a*b))
  of DIV: program.handle((a, b) => (if b == 0: raise newException(ZeroDiv, "03 Division By Zero") else: a div b))
  of AND: program.handle((a, b) => (a and b))
  of ORA: program.handle((a, b) => (a or b))
  of EOR: program.handle((a, b) => (a xor b))
  of SFT: program.handle((a, b) => ((b shr (a and 0b00001111'u8)) shl (a shr 4)))
  else: raise newException(ValueError, &"Unknown opcode {program.opcode.demode()}. Crashing...")
  inc program.pc

func eval*(program: var Program) =
  while true:
    program.step()
