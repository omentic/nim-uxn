import types, opcodes
import std/sugar

macro handle*(program: var Program, op: typed) = discard

# all of the main cases, actually
# two problems: varying # of args and different uint8 or uint16
# func handle[T](program: var Program, op: T -> void) = discard
# func handle[T](program: var Program, op: T -> T) = discard
# func handle[T](program: var Program, op: T -> (T, T)) = discard
# func handle[T](program: var Program, op: (T, T) -> void) = discard
# func handle[T](program: var Program, op: (T, T) -> T) = discard
# func handle[T](program: var Program, op: (T, T) -> (T, T)) = discard
# func handle[T](program: var Program, op: (T, T, T) -> void) = discard
# func handle[T](program: var Program, op: (T, T, T) -> (T, T, T)) = discard

# this is vaguely what it'll look like idk
#[
func handle(program: var Program, op: func) =
  func pop(stack: var Stack) =
    if program.opcode.keep():
      true
    else:
      false
  let stack =
    if program.opcode.ret():
      program.rs
    else:
      program.ws
  if program.opcode.short():
    discard
  else:
    discard
]#
