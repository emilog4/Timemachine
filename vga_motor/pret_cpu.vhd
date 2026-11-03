--------------------------------------------------------------------------------
-- PRETENDED_CPU
-- Version 1.0: See KBD_ENC.
-- Version 2.0: 2023-01-12. Petter Kallstrom. Changelog: Moved this to an own module
-- Description:
-- * This reads scancodes, and writes to the video RAM
-- * This module is instead of a CPU.

-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

-- entity
entity PRET_CPU is
	port (
		clk      : in std_logic;   -- system clock (100 MHz)
		rst      : in std_logic;   -- reset signal
		data     : out std_logic_vector(7 downto 0);  -- tile data
		addr     : out unsigned(10 downto 0);         -- tile address
		we       : out std_logic;						-- write enable
		video_mode : out std_logic);                    
end PRET_CPU;

-- architecture
architecture behavioral of PRET_CPU is

	signal timer : unsigned(28 downto 0) := (others => '0');
	signal mode_reg : std_logic := '0';
	
begin
	process(clk)
	begin
		if rising_edge(clk) then
			if rst='1' then
				timer <= (others => '0');
				mode_reg <= '0';
			elsif timer = 300000000 then
				timer <= (others => '0');
				mode_reg <= not mode_reg;
			else
				timer <= timer + 1;
			end if;
		end if;
	end process;

	video_mode <= mode_reg;
	we <= '0';
	addr <= (others => '0');
    data <= (others => '0');
	
	
end behavioral;

