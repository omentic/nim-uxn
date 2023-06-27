import magic, opcodes, types
import std/[strformat, sugar]

func step*(program: var Program) =
  program.opcode = program.main.get(program.pc)
  case program.opcode.demode()
  of BRK: # ends the evaluation of the current vector.
    discard
  of JCI: # if top of working stack is not zero, moves the PC to an address relative to the next short in memory, otherwise moves PC+2.
    if program.ws.pop() != 0:
      program.pc += program.main.get(program.pc + 1)
    else:
      inc program.pc
  of JMI: # moves the PC to an address relative to the next short in memory.
    program.pc += program.main.get(program.pc + 1)
  of JSI: # pushes PC+2 to RS and moves PC to an address relative to the next short in memory.
    program.rs.push(program.pc + 2)
    program.pc += program.main.get(program.pc + 1)
  of LIT: # pushes the next byte(s) in memory and moves the PC + 2.
    if program.opcode.short():
      program.push(program.pop16())
    else:
      program.push(program.pop8())
    inc program.pc
  of JMP: # moves the PC by a relative distance equal to the signed byte on the top of the stack or to an absolute address in short mode.
    if program.opcode.short():
      program.pc = program.pop16()
    else:
      let relative = int8(program.pop8())
      if relative >= 0:
        program.pc += uint8(relative.abs)
      else:
        program.pc -= uint8(relative.abs)
  of JCN: # if the byte on the top of the stack is not zero, move the PC relative to the signed byte at the second-top of the stack or to an absolute address in short mode.
    if program.opcode.short():
      let (condition, address) = program.pop16x2()
      if condition != 0:
        program.pc = address
    else:
      let (condition, address) = program.pop8x2()
      if condition != 0:
        let address = int8(address)
        if address >= 0:
          program.pc += uint8(address.abs)
        else:
          program.pc -= uint8(address.abs)
  of JSR: # pushes the PC to the return stack and moves the PC by a relative distance equal to the signed byte on the top of the stack or to an absolute address in short mode.
    program.rs.push(program.pc)
    if program.opcode.short():
      program.pc = program.pop16()
    else:
      let relative = int8(program.pop8())
      if relative >= 0:
        program.pc += uint8(relative.abs)
      else:
        program.pc -= uint8(relative.abs)
  of INC: # increments the value at the top of the stack by 1.
    program.handle((a) => (a+1))
  of POP: # removes the value at the top of the stack.
    program.handle((a) => ())
  of NIP: # removes the second value from the stack.
    program.handle((a, b) => (b))
  of SWP: # exchanges the first and second values at the top of the stack.
    program.handle((a, b) => (b, a))
  of ROT: # rotates three values at the top of the stack to the left wrapping around.
    program.handle((a, b, c) => (b, c, a))
  of DUP: # duplicates the value at the top of the stack.
    program.handle((a) => (a, a))
  of OVR: # duplicates the second value at the top of the stack.
    program.handle((a, b) => (a))
  of EQU: # pushes whether the two values at the top of the stack are equal to the stack.
    program.handle((a, b) => (typeof(a)(a == b)))
  of NEQ: # pushes whether the two values at the top of the stack are not equal to the stack.
    program.handle((a, b) => (typeof(a)(a != b)))
  of GTH: # push whether the second value at the top of the stack is greater than the value at the top of the stack.
    program.handle((a, b) => (typeof(a)(a > b)))
  of LTH: # push whether the second value at the top of the stack is lesser than the value at the top of the stack.
    program.handle((a, b) => (typeof(a)(a < b)))
  of STH: # moves the value at the top of the stack to the return stack.
    program.handle((a) => (program.rs.push(a)))
  of LDZ: # pushes a value at an address within the first 256 bytes of memory to the top of the stack.
    program.handle((a) => (program.main.get(a)))
  of STZ: # writes a value to an address within the first 256 bytes of memory.
    program.handle((a, b) => (program.main.set(b, a)))
  of LDR: # pushes a value at a relative address in relation to the PC within a int8 range to the top of the stack.
    program.handle((a) => (program.main.get(program.pc + int8(a))))
  of STR: # writes a value to a relative address in relation to the PC within a int8 range.
    program.handle((a, b) => (program.main.set(program.pc + int8(b), a)))
  of LDA: # pushes the value at a absolute address to the top of the stack.
    program.handle((a, b) => (program.main.get(uint16(a, b))))
  of STA: # writes a value to an absolute address.
    program.handle((a, b, c) => (program.main.set(uint16(b, c), a)))
  of DEI: # pushes a value from the device page to the top of the stack.
    program.handle((a) => (program.io.get(a)))
  of DEO: # writes a value to the device page.
    program.handle((a, b) => (program.io.set(b, a)))
  of ADD: # pushes the sum of the first two values to the top of the stack.
    program.handle((a, b) => (a+b))
  of SUB: # pushes the first value minus the second to the top of the stack.
    program.handle((a, b) => (a-b))
  of MUL: # pushes the product of the first two values to the top of the stack.
    program.handle((a, b) => (a*b))
  of DIV: # pushes the quotient of the first value over the second value to the top of the stack.
    program.handle((a, b) => (if b == 0: raise newException(ZeroDiv, "03 Division By Zero") else: a div b))
  of AND: # pushes the result of the bitwise operation AND to the top of the stack.
    program.handle((a, b) => (a and b))
  of ORA: # pushes the result of the bitwise operation OR to the top of the stack.
    program.handle((a, b) => (a or b))
  of EOR: # pushes the result of the bitwise operation XOR to the top of the stack.
    program.handle((a, b) => (a xor b))
  of SFT: # shifts the bits of the second value of the stack to the left or right, depending...
    program.handle((a, b) => ((b shr (a and 0b00001111'u8)) shl (a shr 4)))
  else:
    raise newException(ValueError, &"Unknown opcode {program.opcode.demode()}. Crashing...")
  inc program.pc

func eval*(program: var Program) =
  while true:
    program.step()
