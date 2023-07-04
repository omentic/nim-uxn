import opcodes

## Type Declarations
type
  Program* = object
    main*: MainMemory   # main memory
    io*: IOMemory       # io memory
    ws*: ref Stack      # working stack
    rs*: ref Stack      # return stack
    pc*: uint16 = 256   # program counter
    opcode*: Opcode     # current opcode

  MainMemory* = array[65536, uint8]
  IOMemory* = array[16, Device]
  Device* = array[16, uint8]
  Stack* = tuple[memory: array[256, uint8], address: uint8]

  UxnError* = object of CatchableError
  Underflow* = object of UxnError
  Overflow* = object of UxnError
  ZeroDiv* = object of UxnError

# woah wait how did this compile without a return type
func init*(_: typedesc[Program], memory: MainMemory): Program =
  Program(main: memory)

# a smidgen of magic
func cs*(program: var Program): ref Stack =
  if program.opcode.ret():
    program.rs
  else:
    program.ws

func parse*(_: typedesc[MainMemory], input: string): MainMemory =
  if input.len > int(uint16.high):
    raise newException(ValueError, "Failed to parse bytestream")
  for i, c in input:
    result[i] = uint8(c)

func uint16*(a, b: uint8): uint16 = (a shl 8) and b

func `+=`*(a: var uint16, b: int8) =
  if b >= 0:
    a += uint8(b)
  else:
    a -= uint8(b.abs)

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
func push*(stack: ref Stack, value: uint8) =
  if stack.address == 255:
    raise newException(Overflow, "02 Overflow")
  stack.memory[stack.address] = value
  inc stack.address
func push*(stack: ref Stack, value: uint16) =
  # todo: order correct?
  stack.push(uint8(value shr 8))
  stack.push(uint8(value and 0b11111111))
func pop*(stack: ref Stack): uint8 =
  if stack.address == 0:
    raise newException(Underflow, "01 Underflow")
  dec stack.address
  return stack.memory[stack.address]
func peek*(stack: ref Stack, offset: int8 = 0): uint8 =
  # todo: detect under/overflow
  if offset >= 0:
    stack.memory[stack.address - uint8(offset)]
  else:
    stack.memory[stack.address + uint8(offset)]

## Program Functions
func push*(program: var Program, bytes: uint8 | uint16) =
  program.cs.push(bytes)
func pop8*(program: var Program): uint8 =
  if program.opcode.keep():
    program.cs.peek()
  else:
    program.cs.pop()
func pop16*(program: var Program): uint16 =
  if program.opcode.keep():
    uint16(program.cs.peek(), program.cs.peek(1))
  else:
    uint16(program.cs.pop(), program.cs.pop())
func pop8x2*(program: var Program): (uint8, uint8) =
  if program.opcode.keep():
    (program.cs.peek(), program.cs.peek(1))
  else:
    (program.cs.pop(), program.cs.pop())
func pop16x2*(program: var Program): (uint16, uint16) =
  if program.opcode.keep():
    (uint16(program.cs.peek(), program.cs.peek(1)), uint16(program.cs.peek(2), program.cs.peek(3)))
  else:
    (uint16(program.cs.pop(), program.cs.pop()), uint16(program.cs.pop(), program.cs.pop()))
func pop8x3*(program: var Program): (uint8, uint8, uint8) =
  if program.opcode.keep():
    (program.cs.peek(), program.cs.peek(1), program.cs.peek(2))
  else:
    (program.cs.pop(), program.cs.pop(), program.cs.pop())
func pop16x3*(program: var Program): (uint16, uint16, uint16) =
  if program.opcode.keep():
    (uint16(program.cs.peek(), program.cs.peek(1)), uint16(program.cs.peek(2), program.cs.peek(3)), uint16(program.cs.peek(4), program.cs.peek(5)))
  else:
    (uint16(program.cs.pop(), program.cs.pop()), uint16(program.cs.pop(), program.cs.pop()), uint16(program.cs.pop(), program.cs.pop()))
# todo: can we abstract the above away any?
