import uxn/[magic, opcodes, types]
import std/sugar

# todo: handle errors
func step(program: var Program) =
  program.opcode = program.main.get(program.pc)
  case program.opcode
  of BRK: # ends the evaluation of the current vector.
    discard
  of JCI:
    if program.ws.pop() != 0:
      program.pc += (program.ws.pop() shl 8) and program.ws.pop()
    else:
      program.pc = program.pc + 2
  of JMI: # moves the PC to a relative address at a distance equal to the next short in memory.
    program.pc += (program.ws.pop() shl 8) and program.ws.pop()
  of JSI:
    program.rs.push(program.pc + 2)
    program.pc += (program.ws.pop() shl 8) and program.ws.pop()
  of LIT:
    discard
  else:
    future_macro(program.opcode.mode(), program): # future: should autogenerate conditionals and somehow run these lambdas
      case program.opcode.demode()
      of INC: # increments the value at the top of the stack by 1.
        (a) => (a+1)
      of POP: # removes the value at the top of the stack.
        (a) => ()
      of NIP: # removes the second value from the stack.
        (a, b) => (b)
      of SWP: # exchanges the first and second values at the top of the stack.
        (a, b) => (b, a)
      of ROT: # rotates three values at the top of the stack to the left wrapping around.
        (a, b, c) => (b, c, a)
      of DUP: # duplicates the value at the top of the stack.
        (a) => (a, a)
      of OVR: # duplicates the second value at the top of the stack.
        (a, b) => (a)
      of EQU: # pushes whether the two values at the top of the stack are equal to the stack.
        (a, b) => (typeof(a)(a == b))
      of NEQ: # pushes whether the two values at the top of the stack are not equal to the stack.
        (a, b) => (typeof(a)(a != b))
      of GTH: # push whether the second value at the top of the stack is greater than the value at the top of the stack.
        (a, b) => (typeof(a)(a > b))
      of LTH: # push whether the second value at the top of the stack is lesser than the value at the top of the stack.
        (a, b) => (typeof(a)(a < b))
      of JMP:
        discard
      of JCN:
        discard
      of JSR:
        discard
      of STH: # moves the value at the top of the stack to the return stack.
        (a) => (program.rs.push(a))
      of LDZ: # pushes a value at an address within the first 256 bytes of memory to the top of the stack.
        (a) => (program.main.get(a))
      of STZ: # writes a value to an address within the first 256 bytes of memory.
        (a, b) => (program.main.set(b, a))
      of LDR: # pushes a value at a relative address in relation to the PC within a int8 range to the top of the stack.
        (a) => (program.main.get(program.pc + int8(a)))
      of STR: # writes a value to a relative address in relation to the PC within a int8 range.
        (a, b) => (program.main.set(program.pc + int8(b), a))
      of LDA: # pushes the value at a absolute address to the top of the stack.
        (a, b) => (program.main.get((a shl 4) and b))
      of STA: # writes a value to an absolute address.
        (a, b, c) => (program.main.set((b shl 4) and (c), a))
      of DEI: # pushes a value from the device page to the top of the stack.
        (a) => (program.io.get(a))
      of DEO: # writes a value to the device page.
        (a, b) => (program.io.set(b, a))
      # todo: over/underflow and dividing by zero
      of ADD: # pushes the sum of the first two values to the top of the stack.
        (a, b) => (a+b)
      of SUB: # pushes the first value minus the second to the top of the stack.
        (a, b) => (a-b)
      of MUL: # pushes the product of the first two values to the top of the stack.
        (a, b) => (a*b)
      of DIV: # pushes the quotient of the first value over the second value to the top of the stack.
        (a, b) => (a div b)
      of AND: # pushes the result of the bitwise operation AND to the top of the stack.
        (a, b) => (a and b)
      of ORA: # pushes the result of the bitwise operation OR to the top of the stack.
        (a, b) => (a or b)
      of EOR: # pushes the result of the bitwise operation XOR to the top of the stack.
        (a, b) => (a xor b)
      of SFT: # shifts the bits of the second value of the stack to the left or right, depending...
        (a, b) => ((b shr (a and 0b00001111'u8)) shl (a shr 4))
      else:
        raise newException(Exception, "what the fuck")

func eval*(program: var Program): uint8 =
  while true:
    program.step()
