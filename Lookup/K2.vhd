library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- adress mode lookup table interface
entity K2 is
    port(addrMode : in unsigned(1 downto 0);
        K2_data : out unsigned(5 downto 0));
end K2;

architecture Behavioral of K2 is

    -- K2 Lookup table
    type K2_t is array (0 to 3) of unsigned(5 downto 0);
    constant K2_c : K2_t :=
       (
        b"000011",    -- addrMode "00" implemented in uM(row 3)
        b"000100",    -- addrMode "01" implemented in uM(row 4)
        b"000101",    -- addrMode "10" implemented in uM(row 5)
        b"000111"     -- addrMode "11" implemented in uM(row 7)
       );
    
    signal K2_d : K2_t := K2_c;
    
    begin  -- Behavioral
      K2_data <= K2_d(to_integer(addrMode));
    
end Behavioral;