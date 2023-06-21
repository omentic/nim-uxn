import strutils

type uint4* = distinct uint8

proc `'u4`*(n: string): uint4 =
  let a = parseInt(n)
  if (a and 0b11110000) != 0x0:
    raise newException(ValueError, "Parsed integer outside of valid range")
  return a.uint4

# converter toUnsignedInt8*(x: uint4): uint8 =
#   return cast[uint8](uint4)
