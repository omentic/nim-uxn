import opcodes

type short* = uint16

# Type declarations
type
  Program* = object
    main*: MainMemory   ## main memory
    io*: IOMemory       ## io memory
    ws*: ref Stack      ## working stack
    rs*: ref Stack      ## return stack
    pq*: Queue          ## program queue (for keep)
    pc*: short = 256    ## program counter
    opcode*: Opcode     ## current opcode

  MainMemory* = array[65536, byte]
  IOMemory* = array[16, Device]
  Device* = array[16, byte]
  Stack* = tuple[memory: array[255, byte], address: byte]
  Queue* = tuple[memory: array[6, byte], front, back: byte]

  UxnError* = object of CatchableError
  Underflow* = object of UxnError
  Overflow* = object of UxnError
  ZeroDiv* = object of UxnError

func init*(_: typedesc[Program], memory: MainMemory): Program =
  Program(main: memory)

## A smidgen of magic. Gets the current stack given an opcode (of the program).
## Disguised to look like a field of Program.
func cs*(program: var Program): ref Stack =
  if program.opcode.return_mode():
    program.rs
  else:
    program.ws

# fixme
func parse*(_: typedesc[MainMemory], input: string): MainMemory =
  if input.len > int(short.high):
    raise newException(ValueError, "Failed to parse bytestream")
  for i, c in input:
    result[i] = byte(c)

func `+-`*(a: short, b: int8): short =
  if b >= 0: a + byte(b)
  else: a - byte(b.abs)
func `+=`*(a: var short, b: int8) =
  if b >= 0: a += byte(b)
  else: a -= byte(b.abs)

# MainMemory functions
func get*(memory: MainMemory, address: byte | short): byte =
  memory[address]
func set*(memory: var MainMemory, address: byte | short, value: byte) =
  memory[address] = value
func set*(memory: var MainMemory, address: byte | short, value: short) =
  memory.set(address, byte(value shr 8))
  memory.set(address + 1, byte(value and 0b11111111))

# IOMemory functions
func get*(memory: IOMemory, address: Label): Device =
  memory[address.ord]
func get*(memory: IOMemory, address: byte): byte =
  memory[address div 16][address mod 16]
func set*(memory: var IOMemory, address: byte, value: byte) =
  memory[address div 16][address mod 16] = value
func set*(memory: var IOMemory, address: range[0..15], value: Device) =
  memory[address] = value

# Stack functions
func pop*(stack: ref Stack): byte =
  if stack.address == 0:
    raise newException(Underflow, "01 Underflow")
  stack.address.dec()
  return stack.memory[stack.address]
func push*(stack: ref Stack, value: byte) =
  if stack.address == 255:
    raise newException(Overflow, "02 Overflow")
  stack.memory[stack.address] = value
  stack.address.inc()
func push*(stack: ref Stack, value: short) =
  stack.push(byte(value shr 8))
  stack.push(byte(value and 0b11111111))

# Queue functions
func qinc(address: byte): byte =
  if address == 5: 0
  else: address + 1
func pop*(queue: var Queue): byte =
  if queue.front == queue.back:
    raise newException(Underflow, "01 Underflow")
  result = queue.memory[queue.front]
  queue.front = queue.front.qinc()
func push*(queue: var Queue, value: byte) =
  if queue.back.qinc() == queue.front:
    raise newException(Overflow, "02 Overflow")
  queue.memory[queue.back] = value
  queue.back = queue.back.qinc()
func empty*(queue: Queue): bool =
  queue.front == queue.back

## Checked division
template `//`*(a, b) =
  if `b` == 0:
    raise newException(ZeroDiv, "03 Division by Zero")
  else:
    `a` div `b`

# Program functions
func push*(program: var Program, bytes: byte | short) =
  program.cs.push(bytes)
func pop8*(program: var Program): byte =
  result = program.cs.pop()
  if program.opcode.keep_mode():
    program.pq.push(result)
func pop16*(program: var Program): short =
  result = short((program.cs.pop() shl 8) and program.cs.pop())
  if program.opcode.keep_mode():
    program.pq.push(byte(result shr 8))
    program.pq.push(byte(result and 0b11111111))

func restore*(program: var Program) =
  while not program.pq.empty:
    program.cs.push(program.pq.pop())
