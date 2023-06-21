import std/sugar

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

# two problems: varying # of args and different uint8 or uint16

proc handle[T](program: var Program, op: (T, T) -> T) =
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

