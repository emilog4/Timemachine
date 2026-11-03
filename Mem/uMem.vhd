library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- uMem interface
entity uMem is
  port (
    uAddr : in unsigned(5 downto 0);
    uData : out unsigned(24 downto 0));
end uMem;

architecture Behavioral of uMem is

  -- micro Memory
  type u_mem_t is array (0 to 72) of unsigned(24 downto 0);
  constant u_mem_c : u_mem_t :=
  --_ALU__TB___FB__S_P__SEQ___ADR
  (b"0000_0011_0111_0_0_0000_0000000", -- ASR:=PC (hämtfas börjar)
  b"0000_0010_0001_0_1_0000_0000000", -- IR:=PM, PC:=PC+1 (hämtfas slutar)
  b"0000_0000_0000_0_0_0010_0000000", -- uPC:=K2 (addresseringsmodsfas börjar)

  b"0000_0001_0111_0_0_0001_0000000", -- ASR:=IR, uPC:=K1 (Direktadressering)

  b"0000_0011_0111_0_1_0001_0000000", -- ASR:=PC, PC:=PC+1, uPC:=K1 (Immediate)

  b"0000_0001_0111_0_0_0000_0000000", -- ASR:=IR (Indirekt adressering)
  b"0000_0010_0111_0_0_0001_0000000", -- ASR:=PM, uPC:=K1 (indirekt adressering)

  b"0001_0001_0000_0_0_0000_0000000", -- AR:=IR (Indexerad adressering)
  b"1000_0110_0000_1_0_0000_0000000", -- AR:=GR3+AR (Indexerad adressering)
  b"0000_0100_0111_0_0_0001_0000000", -- ASR:=AR, uPC:=K1 (Indexerad adressering) (addresseringsmodsfas slutar)

  b"0000_0010_0110_0_0_0011_0000000", -- GRx:=PM(A) (LOAD) (ADR = 0x0A)

  b"0000_0110_0010_0_0_0011_0000000", -- PM(A):=GRx (STORE) (ADR = 0x0B)

  b"0001_0110_0000_0_0_0000_0000000", -- AR:=GRx (ADD)  (ADR = 0x0C)
  b"0100_0010_0000_0_0_0000_0000000", -- AR:=AR+PM(A) (ADD)
  b"0000_0100_0110_0_0_0011_0000000", -- Grx:=AR  (ADD)

  b"0001_0110_0000_0_0_0000_0000000", -- AR:=GRx (SUB) (ADR = 0x0F)
  b"0101_0010_0000_0_0_0000_0000000", -- AR:=AR-PM(A) (SUB)
  b"0000_0100_0110_0_0_0011_0000000", -- Grx:=AR  (SUB)

  b"0001_0110_0000_0_0_0000_0000000", -- AR:=GRx  (AND) (ADR = 0x12)
  b"0110_0010_0000_0_0_0000_0000000", -- AR:=AR&PM(A) (AND)
  b"0000_0100_0110_0_0_0011_0000000", -- GRx:=AR  (AND)

  b"0001_0110_0000_0_0_0000_0000000", --AR:=GRx (LSR) (ADR = 0x15)
  b"1010_0000_0000_0_0_0000_0000000", --AR:=AR>>1 (LSR)
  b"0000_0100_0110_0_0_0011_0000000", --GRx:=AR (LSR)

  b"0000_0000_0000_0_0_1111_0000000", -- Halt (ADR = 0x18)

  b"0001_0011_0000_0_0_0000_0000000", -- AR:=PC (JMP) (ADR = 0x19)
  b"1000_0010_0000_0_0_0000_0000000", -- AR:=AR+PM(A) (OBS utan flaggor) (JMP)
  b"1110_0000_0000_0_0_0000_0000000", -- AR:=AR-1 (OBS utan flaggor) (JMP)
  b"1110_0000_0000_0_0_0000_0000000", -- AR:=AR-1 (OBS utan flaggor) (JMP)
  b"0000_0100_0011_0_0_0011_0000000", -- PC:=AR (JMP)

  b"0001_1001_0000_0_0_0000_0000000", -- AR:=Time (Sum_Time) (ADR = 0x1E)
  b"1000_0010_0000_0_0_0000_0000000", -- AR:=AR+PM(A) (Sum_Time)
  b"0000_0100_1001_0_0_0011_0000000", -- Time:=AR (Sum_Time)

  b"0001_1010_0000_0_0_0000_0000000", -- AR:=activePalette (INC activePalette) (ADR = 0x21)
  b"1011_0000_0000_0_0_0000_0000000", -- AR:=AR+1 (INC activePalette)
  b"0000_0100_1010_0_0_0011_0000000", -- activePalette:=AR (INC activePalette)

  b"0001_1010_0000_0_0_0000_0000000", -- AR:=activePalette (DEC activePalette) (ADR = 0x24)
  b"1100_0000_0000_0_0_0000_0000000", -- AR:=AR-1 (DEC activePalette)
  b"0000_0100_1010_0_0_0011_0000000", -- activePalette:=AR (DEC activePalette)

  b"0001_0010_0000_0_0_0000_0000000", -- AR:=PM(A) (WAIT) (ADR = 0x27)
  b"1100_0000_0000_0_0_0000_0000000", -- AR:=AR-1  (WAIT)
  b"0000_0000_0000_0_0_0100_0101000", -- Branch to 0x28 if Z=0 (WAIT)
  b"0000_0000_0000_0_0_0011_0000000", -- End       (WAIT)

  b"0000_0000_0000_0_0_1000_0011001", -- JMP if z = 1 (BEQ) (ADR = 0x2B)

  b"0000_1000_0000_0_0_0000_0000000", -- AR:= RE_dir (CRE compare rotary encoder direction)  (ADR = 0x2C)
  b"0101_0010_0000_0_0_0011_0000000", -- AR:= AR-PM(A) | If (AR == PM(A)) set z = 1 (CRE)

  b"0001_1100_0000_0_0_0000_0000000", -- AR:=RE_clr (RRE Reset rotary encoder direction) (ADR = 0x2E)
  b"1101_0000_0000_0_0_0000_0000000", -- AR:=AR+1 (inga flaggor)
  b"0000_0100_1000_0_0_0000_0000000", -- RE_clr:=AR
  b"0001_1100_0000_0_0_0000_0000000", -- AR:=RE_clr 
  b"1100_0000_0000_0_0_0000_0000000", -- AR:=AR-1 (inga flaggor)
  b"0000_0100_1000_0_0_0011_0000000", -- RE_clr:=AR

  b"0000_0000_0000_0_0_0011_0000000", -- (NOOP)(ADR = 0x34)

  b"0001_0110_0000_0_0_0000_0000000", -- AR:=GRx (CMP) (ADR = 0x35)
  b"0101_0010_0000_0_0_0011_0000000", -- AR:=GRx-PM(A)

  b"0000_0000_0000_0_0_0100_0011001", -- JMP if z = 0 (BNE) (ADR = 0x37)
  b"0000_0000_0000_0_0_0011_0000000", -- reset uPC

  b"0000_1000_0110_0_0_0011_0000000", -- GRx:=INx (IN)  (ADR = 0x39)

  b"0001_1010_0000_0_0_0000_0000000", -- AR:=clk_time (ADR = 0x3A)
  b"0100_0010_0000_0_0_0000_0000000", -- AR:=AR + PM(A)
  b"0000_0100_1010_0_0_0011_0000000", -- clk_time = AR

  b"0000_0000_0000_0_0_0000_0000000",
  b"0000_0000_0000_0_0_0000_0000000",
  b"0000_0000_0000_0_0_0000_0000000",
  b"0000_0000_0000_0_0_0000_0000000",
  b"0000_0000_0000_0_0_0000_0000000",
  b"0000_0000_0000_0_0_0000_0000000",
  b"0000_0000_0000_0_0_0000_0000000",
  b"0000_0000_0000_0_0_0000_0000000",
  b"0000_0000_0000_0_0_0000_0000000",
  b"0000_0000_0000_0_0_0000_0000000",
  b"0000_0000_0000_0_0_0000_0000000",
  b"0000_0000_0000_0_0_0000_0000000");
  signal u_mem : u_mem_t := u_mem_c;

begin -- Behavioral
  uData <= u_mem(to_integer(uAddr));

end Behavioral;