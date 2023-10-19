import npeg

type
  Token = object
    kind: char
    value: string
  TokenStream = seq[Token]

func init(_: typedesc[Token], kind: char, value: string): Token =
  Token(kind: kind, value: value)

func init(_: typedesc[Token], kind: string, value: string): Token =
  assert kind.len == 1
  Token.init(kind[0], value)

# output: list of file names to include verbatium
# yes, spaces in file names are not supported...
const includes = peg("includes"):
  ws <- Space | '[' | ']'
  incl <- '~' * +ws * >+Graph
  includes <- *Print * >incl * *((+ws * >incl) | +Print) * *ws

# output: list of strings, every other is a label and every other is a replacement
const macros = peg("macros"):
  ws <- Space | '[' | ']'
  mcro <- '%' * >+Graph * +Space * '{' * +Space * >+Print * +Space * '}'
  macros <- *Print * >mcro * *((+ws * >mcro) | +Print) * *ws

# assumption: macros and includes have already been expanded
# output: sequence of unparsed tokens
const uxntal = peg("uxntal", tokens: TokenStream):
  ws <- Space | '[' | ']'
  comment <- '(' * *((Print-{'(',')'}) | comment) * ')':
    tokens.add(Token.init('c', $0))
  ascii <- >('"') * >+Graph:
    tokens.add(Token.init($1, $2))
  hex <- >('#'|'$'|'|') * >+Xdigit:
    tokens.add(Token.init($1, $2))
  address <- >('.'|'-'|','|'_'|';'|'=') * >((0|'&'|'@') * +Graph):
    tokens.add(Token.init($1, $2))
  expression <- comment | ascii | hex | address
  uxntal <- *ws * expression * *(+ws * expression) * *ws

# include files. todo
func intake(input: var string): bool = false

# expand macros. todo
func expand(input: var string): bool = false

# parse the metaprogramming-less uxntal into tokens
func parse(input: string): TokenStream = @[]

# resolve labels and padding, and transform into assembly. maybe should be two steps?
func resolve(input: TokenStream): seq[byte] = @[]

func assemble*(input: string): seq[byte] =
  var input = input
  var success = false
  while not success:
    success = input.intake()
  success = false
  while not success:
    success = input.expand()
  let tokens = input.parse()
  let rom = tokens.resolve()
  return rom

# type
#   TokenKind = enum
#     AbsPadding, RelPadding,
#     RawHex, RawAscii,
#     ParentLabel, ChildLabel, Label
#     LitZeroAddr, RawZeroAddr, LitAbsAddr, RawAbsAddr, LitRelAddr, RawRelAddr,

# type TokenMore = object
#   case kind: TokenKind
#   of AbsPadding, RelPadding, RawHex, RawAscii:
#     number: int
#   of ParentLabel, ChildLabel, Label, LitZeroAddr, RawZeroAddr, LitAbsAddr, RawAbsAddr, LitRelAddr, RawRelAddr:
#     label: string
#     address: int

# func validate(input: TokenStream): UxnTal =
#   discard
