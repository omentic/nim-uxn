type Opcode* = uint8

func keep*(op: Opcode): bool =
  (op and 0b100_00000'u8) == 0x0
func ret*(op: Opcode): bool =
  (op and 0b010_00000'u8) == 0x0
func short*(op: Opcode): bool =
  (op and 0b001_00000'u8) == 0x0

func demode*(op: Opcode): Opcode =
  op and 0b000_11111'u8

# we take *heavy* advantage of ordinal enums.
type Literal* = enum
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

# hell. fucking. yes.
converter literalify*(op: Literal): Opcode =
  uint8(op.ord)
