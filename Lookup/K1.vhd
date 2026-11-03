library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- Instruction lookup table interface
entity K1 is
    port(OP_code : in unsigned(5 downto 0);
        K1_data : out unsigned(5 downto 0));
end K1;

architecture Behavioral of K1 is

    -- K1 Lookup table
    type K1_t is array (0 to 31) of unsigned(7 downto 0);
    constant K1_c : K1_t :=
       (
        x"34",  -- 00
        x"0C",  -- 01
        x"0F",  -- 02
        x"00",  -- 03
        x"12",  -- 04
        x"00",  -- 05
        x"00",  -- 06
        x"00",  -- 07
        x"00",  -- 08
        x"0A",  -- 09
        x"0B",  -- 0A
        x"19",  -- 0B
        x"2B",  -- 0C
        x"37",  -- 0D
        x"20",  -- 0E
        x"23",  -- 0F
        x"26",  -- 10
        x"39",  -- 11
        x"00",  -- 12
        x"1E",  -- 13
        x"3A",  -- 14
        x"21",  -- 15
        x"24",  -- 16
        x"27",  -- 17
        x"2E",  -- 18
        x"2C",  -- 19
        x"35",  -- 1A
        x"00",  -- 1B
        x"00",  -- 1C
        x"00",  -- 1D
        x"00",  -- 1E
        x"00"   -- 1F
       );
    
    signal K1_d : K1_t := K1_c;
    
    begin  -- Behavioral
      K1_data <= resize(K1_d(to_integer(OP_code)), K1_data'length);
    
end Behavioral;
