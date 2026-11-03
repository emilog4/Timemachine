--------------------------------------------------------------------------------
-- VGA lab
-- Version 1.0: 2015-12-16. Anders Nilsson
-- Version 2.0: 2023-01-12. Petter Kallstrom. Changelog: Splitting KBD_ENC into KBD_ENC + PRETENDED_CPU
-- Version 3.0: 2023-09-29. Anders Nilsson. 12-bit VGA.


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

-- entity
entity main is
	port (
		clk      : in std_logic;                         -- system clock
		btnC     : in std_logic;                         -- reset
		button	 : in std_logic;						-- -- Pin J2 (Pmod JA3) - Switches between 4 states/modes
		switch   : in  std_logic;         				-- Pin G2 (Pmod JA4) - On/Off switch
        signal_A : in  std_logic;         				-- Pin J1 (Pmod JA1)
        signal_B : in  std_logic;         				-- Pin L2 (Pmod JA2)
		Hsync    : out std_logic;                        -- horizontal sync
		Vsync    : out std_logic;                        -- vertical sync
		vgaRed   : out std_logic_vector(3 downto 0);     -- VGA red
		vgaGreen : out std_logic_vector(3 downto 0);     -- VGA green
		vgaBlue  : out std_logic_vector(3 downto 0));     -- VGA blue
end main;


-- architecture
architecture Behavioral of main is
	-- intermediate signals between CPU and VIDEO_RAM
	signal time 		: unsigned(15 downto 0);
	alias day_s			: std_logic is time(15);
	alias animS 		: unsigned(7 downto 0) is time(14 downto 7);
	alias pallette_s 	: unsigned(3 downto 0) is time(15 downto 12);
	signal clk_H1s		: unsigned(1 downto 0);		-- CLK time HH 
	signal clk_H2s		: unsigned(3 downto 0);		-- CLK time hhhh
	signal clk_M1s		: unsigned(2 downto 0);		-- CLK time MMM
	signal clk_M2s		: unsigned(3 downto 0);		-- CLK time mmmm
	signal clk_t		: unsigned(12 downto 0);	-- concatenated clock time
	
	-- intermediate signals between VIDEO_RAM and VGA_MOTOR
	signal data_out2_s 	: std_logic_vector(7 downto 0); -- data
	signal addr2_s     	: unsigned(10 downto 0);        -- address

	-- signals from rotery encoder
	signal debA, debB, debBtn : std_logic;

	-- intermediate signals between Rotary Encoder and CPU
    signal RE_val   	: unsigned(1 downto 0);
	signal RE_direction : unsigned(1 downto 0);
	signal RE_clr		: std_logic;
	
begin
	clk_t <= clk_H1s & clk_H2s & clk_M1s & clk_M2s;
	-- cpu component connection
	CPU : entity work.uprogCPU 
		port map(
		clk=>clk, 
		btnC=>btnC, 
		curTime=>time, 
		clk_H1=>clk_H1s,
		clk_H2=>clk_H2s,
		clk_M1=>clk_M1s,
		clk_M2=>clk_M2s,
		RE_direction=>RE_direction,
		RE_value=>RE_val,
		RE_clear=>RE_clr);

	-- picture memory component connection
	VRAM : entity work.video_ram 
		port map(
        clk       => clk, 
        we1       => '0', 
        data_in1  => x"00", 
        addr1     => "00000000000", 
        we2       => '0', 
        data_in2  => x"00", 
        data_out2 => data_out2_s, 
        addr2     => addr2_s);
	
	-- VGA motor component connection
	VGA : entity work.vga_motor 
		port map(
		clk=>clk, 
		clear=>btnC, 
		time_13bit=>clk_t,
		animStatus=>animS, 
		activePalette=>pallette_s, 
		VR_data=>data_out2_s, 
		VR_addr=>addr2_s, 
		video_mode=>day_s, 
		vgaRed=>vgaRed, 
		vgaGreen=>vgaGreen, 
		vgaBlue=>vgaBlue, 
		Hsync=>Hsync, 
		Vsync=>Vsync);

	-- Rotery encoder
	ROT_DEBOUNCE: entity work.Debouncer 
        port map(clk => clk, Ain => signal_A, Bin => signal_B, Aout => debA, Bout => debB);

	BUT_DEBOUNCE: entity work.Debouncer 
    	port map(clk  => clk, Ain  => button,Bin  => '0', Aout => debBtn, Bout => open);

    ENCODER: entity work.Encoder 
        port map(clk => clk, signal_A => debA, signal_B => debB, button => debBtn, clear_dir => RE_clr, mode => RE_val, Direction => RE_direction);
	
	-- RE_dir <= RE_direction;
	
end Behavioral;