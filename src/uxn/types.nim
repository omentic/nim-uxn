import util

type
  MainMemory* = array[65536, uint8]
  IOMemory* = array[16, Device]
  Device* = array[16, uint8]
  Stack* = tuple[memory: array[256, uint8], address: uint8]

  Error* = enum
    Underflow = 1
    Overflow = 2
    ZeroDiv = 3

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

  #[MainMemory = concept
    proc get(m: Self, a: uint8): uint8
    proc set(m: var Self, a: uint8, v: uint8)
    proc get(m: Self, a: uint16): uint16
    proc set(m: var Self, a: uint16, v: uint16)]#

  #[IOMemory = concept
    proc get(m: Self, a: DeviceLabel): Device
    proc set(m: var Self, a: DeviceLabel, v: Device)
    proc get(m: Self, a: uint8): uint8
    proc set(m: var Self, a: uint8, v: uint8)]#

  #[Device* = concept
    proc get(d: Self, a: range[0..15]): uint8
    proc set(d: Self, a: range[0..15], v: uint8)]#

  #[Stack = concept
    proc pop(s: Self): uint8
    proc push(s: var Self, v: uint8)]#
