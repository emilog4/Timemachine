-- Modified DisplayController.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity DisplayController is
    Port ( 
        clk : in std_logic;
        SWT: in std_logic; -- Enable switch
        mode : in  STD_LOGIC_VECTOR (1 downto 0); -- From Encoder
        anode: out std_logic_vector(3 downto 0);
        segOut : out  STD_LOGIC_VECTOR (6 downto 0));
end DisplayController;

architecture Behavioral of DisplayController is
    -- Patterns for Basys 3 (Active Low: 0=On, 1=Off)
    -- segOut order: gfedcba
    constant CHAR_1 : std_logic_vector(6 downto 0) := "1111001"; -- 1
    constant CHAR_2 : std_logic_vector(6 downto 0) := "1100100"; -- 2
    constant CHAR_3 : std_logic_vector(6 downto 0) := "0110000"; -- 3
    constant CHAR_4 : std_logic_vector(6 downto 0) := "1011001"; -- 4
    constant CHAR_OFF : std_logic_vector(6 downto 0) := "1111111";
begin
    process(clk, SWT)
    begin 
        if (SWT = '0') then
            anode <= "1111"; -- All digits off
            segOut <= CHAR_OFF;
        elsif rising_edge(clk) then
            anode <= "1110"; -- Only enable the rightmost digit on segmenet display
            case mode is
                when "00" => segOut <= CHAR_1;
                when "01" => segOut <= CHAR_2;
                when "10" => segOut <= CHAR_3;
                when "11" => segOut <= CHAR_4;
                when others => segOut <= CHAR_OFF;
            end case;
        end if;
    end process;
end Behavioral;