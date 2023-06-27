import uxn/[emulator, types]
import std/[os, strformat]

proc main() =
  if paramCount() < 1 or paramStr(1) == "--help":
    echo &"usage: {getAppFilename()} file.rom [args...]"
  else:
    let path = paramStr(1)
    try:
      let rom = path.readFile()
      let memory = MainMemory.parse(rom)
      var program = Program.init(memory)
      program.eval()
    except IOError:
      echo &"could not read file at {path}"
    except ValueError:
      echo &"could not parse file at {path}"

when isMainModule:
  main()
