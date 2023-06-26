import opcodes

type
  Program* = object
    main*: MainMemory   # main memory
    io*: IOMemory       # io memory
    ws*: Stack          # working stack
    rs*: Stack          # return stack
    pc*: uint16 = 256   # program counter
    opcode*: Opcode

  MainMemory* = array[65536, uint8]
  IOMemory* = array[16, Device]
  Device* = array[16, uint8]
  Stack* = tuple[memory: array[256, uint8], address: uint8]

  UxnError* = object of CatchableError
  Underflow* = object of UxnError
  Overflow* = object of UxnError
  ZeroDiv* = object of UxnError

func init*(_: typedesc[Program]) =
  return Program()

func uint16(a, b: uint8): uint16 = (a shl 8) and b

## Memory Functions
func get*(memory: MainMemory, address: uint8 | uint16): uint8 =
  memory[address]
func set*(memory: var MainMemory, address: uint8 | uint16, value: uint8) =
  memory[address] = value
func get*(memory: IOMemory, address: range[0..15]): Device =
  memory[address]
func get*(memory: IOMemory, address: uint8): uint8 =
  memory[address div 16][address mod 16]
func set*(memory: var IOMemory, address: uint8, value: uint8) =
  memory[address div 16][address mod 16] = value
func set*(memory: var IOMemory, address: range[0..15], value: Device) =
  memory[address] = value

## Stack Functions
# fixme: stack semantics are wrong. i am very sure there is an off-by-one error wrt. pop/push & exceptions
func push*(stack: var Stack, value: uint8) =
  if stack.address == 255:
    raise newException(Overflow, "02 Overflow")
  stack.memory[stack.address] = value
  inc stack.address
func push*(stack: var Stack, value: uint16) =
  # todo: order correct?
  stack.push(uint8(value shr 8))
  stack.push(uint8(value and 0b11111111))
func pop*(stack: var Stack): uint8 =
  if stack.address == 0:
    raise newException(Underflow, "01 Underflow")
  dec stack.address
  return stack.memory[stack.address]
func peek*(stack: Stack, offset: int8): uint8 =
  # todo: detect under/overflow
  stack.memory[stack.address - offset]

## Program Functions
func push*(program: var Program, bytes: uint8 | uint16) =
  if program.opcode.ret():
    program.rs.push(bytes)
  else:
    program.ws.push(bytes)
func pop8*(program: var Program): uint8 =
  if program.opcode.ret():
    if program.opcode.keep():
      return program.rs.peek()
    else:
      return program.rs.pop()
  else:
    if program.opcode.keep():
      return program.ws.peek()
    else:
      return program.ws.pop()
func pop16*(program: var Program): uint16 =
  if program.opcode.ret():
    if program.opcode.keep():
      return uint16(program.rs.peek(), program.rs.peek(1))
    else:
      return uint16(program.rs.pop(), program.rs.pop())
  else:
    if program.opcode.keep():
      return uint16(program.ws.peek(), program.ws.peek(1))
    else:
      return uint16(program.ws.pop(), program.ws.pop())
func pop8x2*(program: var Program): (uint8, uint8) =
  discard
func pop16x2*(program: var Program): (uint16, uint16) =
  discard
