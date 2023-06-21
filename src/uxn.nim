import uxn/[types, opcodes]
import std/sugar

type
  Program* = object
    main*: MainMemory   # main memory
    io*: IOMemory       # io memory
    ws*: Stack          # working stack
    rs*: Stack          # return stack
    pc*: uint16 = 256   # program counter
    opcode: Opcode

func init*(_: typedesc[Program]) =
  return Program()

proc handle(program: var Program, op: uint -> uint) =
  case program.opcode.mode()
  of None:
    program.ws.push(cast[uint8](op(program.ws.pop())))
  of Short:
    discard
  of Return:
    discard
  of ReturnShort:
    discard
  of Keep:
    discard
  of KeepShort:
    discard
  of KeepReturn:
    discard
  of KeepShortReturn:
    discard
  else:
    discard

proc handle(program: var Program, op: (uint, uint) -> uint) =
  case program.opcode.mode()
  of None:
    discard
  of Short:
    discard
  of Return:
    discard
  of ReturnShort:
    discard
  of Keep:
    discard
  of KeepShort:
    discard
  of KeepReturn:
    discard
  of KeepShortReturn:
    discard
  else:
    discard

func step(program: var Program) =
  # todo: handle errors
  program.opcode = program.main.get(program.pc)
  case program.opcode.demode()
  of BRK: # ends the evaluaton of the current vector.
    discard
  of INC: # increments the value at the top of the stack by 1.
    discard
  of POP: # removes the value at the top of the stack.
    discard
  of NIP:
    discard
  of SWP:
    discard
  of ROT:
    discard
  of DUP:
    discard
  of OVR:
    discard
  of EQU:
    discard
  of NEQ: # pushes whether the two values at the top of the stack are not equal to the stack.
    program.handle((a, b) => cast[uint](a != b))
  of GTH: # push whether the second value at the top of the stack is greater than the value at the top of the stack.
    program.handle((a, b) => cast[uint](a > b))
  of LTH: # push whether the second value at the top of the stack is lesser than the value at the top of the stack.
    program.handle((a, b) => cast[uint](a < b))
  of JMP:
    discard
  of JCN:
    discard
  of JSR:
    discard
  of STH: # moves the value at the top of the stack to the return stack.
    discard
  of LDZ: # pushes a value at an address within the first 256 bytes of memory to the top of the stack.
    discard
  of STZ:
    discard
  of LDR:
    discard
  of STR:
    discard
  of LDA:
    discard
  of STA:
    discard
  of DEI:
    discard
  of DEO:
    discard
  of ADD:
    discard
  of SUB:
    discard
  of MUL:
    discard
  of DIV:
    discard
  of AND:
    discard
  of ORA:
    discard
  of EOR:
    discard
  of SFT:
    discard
  else:
    raise newException(Exception, "what the fuck")
  # JMI, JSI, LIT

func eval*(program: var Program): uint8 =
  while true:
    program.step()
