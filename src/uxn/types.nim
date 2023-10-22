## Uxn deals with bytes and shorts.
type short* = uint16

## Enums in Nim are ordinal. These represent the opcodes, numerically.
type Opcode* = enum
  BRK INC POP NIP SWP ROT DUP OVR EQU NEQ GTH LTH JMP JCN JSR STH
  LDZ STZ LDR STR LDA STA DEI DEO ADD SUB MUL DIV AND ORA EOR SFT
  JCI   INC2  POP2  NIP2  SWP2  ROT2  DUP2  OVR2  EQU2  NEQ2  GTH2  LTH2  JMP2  JCN2  JSR2  STH2
  LDZ2  STZ2  LDR2  STR2  LDA2  STA2  DEI2  DEO2  ADD2  SUB2  MUL2  DIV2  AND2  ORA2  EOR2  SFT2
  JMI   INCr  POPr  NIPr  SWPr  ROTr  DUPr  OVRr  EQUr  NEQr  GTHr  LTHr  JMPr  JCNr  JSRr  STHr
  LDZr  STZr  LDRr  STRr  LDAr  STAr  DEIr  DEOr  ADDr  SUBr  MULr  DIVr  ANDr  ORAr  EORr  SFTr
  JSI   INC2r POP2r NIP2r SWP2r ROT2r DUP2r OVR2r EQU2r NEQ2r GTH2r LTH2r JMP2r JCN2r JSR2r STH2r
  LDZ2r STZ2r LDR2r STR2r LDA2r STA2r DEI2r DEO2r ADD2r SUB2r MUL2r DIV2r AND2r ORA2r EOR2r SFT2r
  LIT   INCk  POPk  NIPk  SWPk  ROTk  DUPk  OVRk  EQUk  NEQk  GTHk  LTHk  JMPk  JCNk  JSRk  STHk
  LDZk  STZk  LDRk  STRk  LDAk  STAk  DEIk  DEOk  ADDk  SUBk  MULk  DIVk  ANDk  ORAk  EORk  SFTk
  LIT2  INC2k POP2k NIP2k SWP2k ROT2k DUP2k OVR2k EQU2k NEQ2k GTH2k LTH2k JMP2k JCN2k JSR2k STH2k
  LDZ2k STZ2k LDR2k STR2k LDA2k STA2k DEI2k DEO2k ADD2k SUB2k MUL2k DIV2k AND2k ORA2k EOR2k SFT2k
  LITr  INCkr POPkr NIPkr SWPkr ROTkr DUPkr OVRkr EQUkr NEQkr GTHkr LTHkr JMPkr JCNkr JSRkr STHkr
  LDZkr STZkr LDRkr STRkr LDAkr STAkr DEIkr DEOkr ADDkr SUBkr MULkr DIVkr ANDkr ORAkr EORkr SFTkr
  LIT2r  INC2kr POP2kr NIP2kr SWP2kr ROT2kr DUP2kr OVR2kr EQU2kr NEQ2kr GTH2kr LTH2kr JMP2kr JCN2kr JSR2kr STH2kr
  LDZ2kr STZ2kr LDR2kr STR2kr LDA2kr STA2kr DEI2kr DEO2kr ADD2kr SUB2kr MUL2kr DIV2kr AND2kr ORA2kr EOR2kr SFT2kr

func keep_mode*(op: Opcode): bool =
  (op.byte and 0b100_00000'u8) == 0b0
func return_mode*(op: Opcode): bool =
  (op.byte and 0b010_00000'u8) == 0b0
func short_mode*(op: Opcode): bool =
  (op.byte and 0b001_00000'u8) == 0b0

## Get the raw instruction from an Opcode
func ins*(op: Opcode): Opcode =
  Opcode(op.byte and 0b000_11111'u8)

## Device names
type Label* = enum
  Zero One Two Three Four Five Six Seven Eight Nine Ten Eleven Twelve Thirteen Fourteen Fifteen

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
func set*(memory: var IOMemory, address: byte, value: short) =
  memory.set(address, byte(value shr 8))
  memory.set(address + 1, byte(value and 0b11111111))
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
template `//`*(a, b): untyped =
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
