import util

type
  Program* = object
    main*: MainMemory   # main memory
    io*: IOMemory       # io memory
    ws*: Stack          # working stack
    rs*: Stack          # return stack
    pc*: uint16 = 256   # program counter
    opcode: Opcode

  MainMemory* = array[65536, uint8]
  IOMemory* = array[16, Device]
  Device* = array[16, uint8]
  Stack* = tuple[memory: array[256, uint8], address: uint8]

  Error* = enum
    Underflow = 1
    Overflow = 2
    ZeroDiv = 3

func init*(_: typedesc[Program]) =
  return Program()

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

func push*(stack: var Stack, value: uint8) =
  stack.memory[stack.address] = value
  inc stack.address
func pop*(stack: var Stack): uint8 =
  result = stack.memory[stack.address]
  dec stack.address
func peek*(stack: Stack): uint8 =
  stack.memory[stack.address]
