--------------------------------------------------------------------------------
-- VGA MOTOR
-- Version 1.1: 2016-02-16, Anders Nilsson
-- Version 1.2: 2023-01-11, Petter Kallstrom. Changelog: Corrected a pipeline mistake.
-- Version 2.0: 2023-09-29. Anders Nilsson. 12-bit VGA.


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;				-- IEEE library for the unsigned type

use work.bird_pkg.ALL;
use work.celestial_pkg.ALL;
use work.seagull_pkg.ALL;



-- entity
entity vga_motor is
	port (
		clk      : in std_logic;
		VR_data  : in std_logic_vector(7 downto 0);
		VR_addr  : out unsigned(10 downto 0);
		clear    : in std_logic;
		video_mode : in std_logic;
		vgaRed   : out std_logic_vector(3 downto 0);
		vgaGreen : out std_logic_vector(3 downto 0);
		vgaBlue  : out std_logic_vector(3 downto 0);
		Hsync    : out std_logic;
		Vsync    : out std_logic;
		time_13bit : in unsigned(12 downto 0);
		animStatus : in unsigned(7 downto 0);
		activePalette : in unsigned(3 downto 0));
end vga_motor;


-- architecture
architecture Behavioral of vga_motor is
	
	signal Xpixel1, Xpixel2 : unsigned(9 downto 0) := "0000000000"; -- Horizontal pixel counter, and its pipelined version
	signal Ypixel1, Ypixel2 : unsigned(9 downto 0) := "0000000000"; -- Vertical pixel counter
	signal VR_addr_int, VR_addr_int2 : unsigned(10 downto 0);
	signal ClkDiv : unsigned(1 downto 0);          -- Clock divisor, to generate 25 MHz signal
	signal Clk25  : std_logic;                     -- One pulse width 25 MHz signal
	
	signal CR_addr  : unsigned(10 downto 0);       -- address for tile_rom
	signal CR_data : std_logic_vector(3 downto 0); -- data from tile_rom. 4 bit pallete
	
	signal blank1, blank2, blank : std_logic; -- blanking signal, with delayed versions
	signal Hsync1, Hsync2 : std_logic;
	signal Vsync1, Vsync2 : std_logic;


	type palette_t is array (0 to 15) of std_logic_vector(11 downto 0); -- Defining pallete
    -- ==========================================
    -- 16-STEGS NATT/DAG-CYKEL (Strand/Solnedgång)
    -- ==========================================

    -- 1. Gryning / Tidig morgon (Original Day 1)
    constant palette_01 : palette_t := (
        0 => x"000", -- Svart 
        1 => x"EBA", -- Sand (Varm, lite persikofärgad)
        2 => x"F66", -- Röd (Mjuka rosa/röda detaljer)
        3 => x"4C4", -- Grön (Mjukt morgongräs)
        4 => x"59D", -- Vatten (Pastellblått)
        8 => x"767", -- Stenar (Ljust purpurgrå)
        others => x"FDD" -- Moln/Skum (Ljust rosafärgade av morgonsolen)
    );

    -- 2. Förmiddag (Övergång)
    constant palette_02 : palette_t := (
        0 => x"000", -- Svart
        1 => x"EC5", -- Sand (Börjar bli mer gul)
        2 => x"F44", -- Röd (Röda detaljer klarnar)
        3 => x"3C3", -- Grön (Gräset ljusnar)
        4 => x"4AE", -- Vatten (Himmelsblått börjar speglas)
        8 => x"777", -- Stenar (Börjar bli mer neutrala)
        others => x"FEE" -- Moln/Skum (Vitare)
    );

    -- 3. Mitt på dagen (Original Day 2)
    constant palette_03 : palette_t := (
        0 => x"000", -- Svart
        1 => x"ED0", -- Sand (Klar sandgul)
        2 => x"F22", -- Röd (Stark röd)
        3 => x"2D2", -- Grön (Klart gräs)
        4 => x"3AF", -- Vatten (Ljus och klar havsblå)
        8 => x"888", -- Stenar (Neutral grå)
        others => x"FFF" -- Moln/Skum (Kritvit)
    );

    -- 4. Tidig eftermiddag (Övergång)
    constant palette_04 : palette_t := (
        0 => x"000", -- Svart
        1 => x"EC0", -- Sand (Värmen börjar krypa in)
        2 => x"E22", -- Röd (Aningen djupare)
        3 => x"2C1", -- Grön (Lätt varmgrön ton)
        4 => x"29E", -- Vatten (Lite djupare blå)
        8 => x"877", -- Stenar (Första tecknet på varm skugga)
        others => x"FEE" -- Moln/Skum (Börjar tappa den skarpa vitheten)
    );

    -- 5. Sen eftermiddag (Original Day 3)
    constant palette_05 : palette_t := (
        0 => x"000", -- Svart
        1 => x"DC0", -- Sand (Lite mörkare, mer guldgul)
        2 => x"E11", -- Röd (Lite djupare röd)
        3 => x"2B1", -- Grön (Varmare grön)
        4 => x"28D", -- Vatten (Lite djupare blått)
        8 => x"777", -- Stenar (Mörkare grå)
        others => x"EEE" -- Moln/Skum (Varmvit)
    );

    -- 6. Gyllene timmen (Övergång)
    constant palette_06 : palette_t := (
        0 => x"000", -- Svart
        1 => x"CA0", -- Sand (Gyllene orange)
        2 => x"D22", -- Röd (Rostar)
        3 => x"291", -- Grön (Bronsgrön)
        4 => x"36B", -- Vatten (Blålila nyanser börjar framträda)
        8 => x"666", -- Stenar (Dämpade)
        others => x"ECC" -- Moln/Skum (Börjar plocka upp lila/rosa)
    );

    -- 7. Solnedgång (Original Day 4)
    constant palette_07 : palette_t := (
        0 => x"000", -- Svart
        1 => x"C80", -- Sand (Orange/rostig ton)
        2 => x"D33", -- Röd (Dämpad röd)
        3 => x"381", -- Grön (Oliv/brunaktigt gräs i kvällssol)
        4 => x"45A", -- Vatten (Lila/Mörkblått)
        8 => x"655", -- Stenar (Varm mörkgrå)
        others => x"FBB" -- Moln/Skum (Rosa/orange solnedgångsmoln)
    );

    -- 8. Blå timmen / Sen solnedgång (Övergång)
    constant palette_08 : palette_t := (
        0 => x"000", -- Svart
        1 => x"962", -- Sand (Glöden dör ut)
        2 => x"A23", -- Röd (Djup vinröd/lila)
        3 => x"261", -- Grön (Mörk skogsgrön)
        4 => x"348", -- Vatten (Indigo)
        8 => x"545", -- Stenar (Lila-grå)
        others => x"CAB" -- Moln/Skum (Mörknande lila-rosa)
    );

    -- 9. Skymning (Original Night 1)
    constant palette_09 : palette_t := (
        0 => x"000", -- Svart
        1 => x"645", -- Sand (Lila/brunaktig, tappar färg)
        2 => x"823", -- Röd (Mörk purpur)
        3 => x"142", -- Grön (Mörkt blågrönt gräs)
        4 => x"236", -- Vatten (Mörkt purpurblått)
        8 => x"445", -- Stenar (Kall mörkgrå)
        others => x"A9B" -- Moln/Skum (Lila/blåaktiga skuggmoln)
    );

    -- 10. Sen skymning (Övergång)
    constant palette_10 : palette_t := (
        0 => x"000", -- Svart
        1 => x"435", -- Sand (Mörknar mot nattblå)
        2 => x"612", -- Röd (Tappar mer ljus)
        3 => x"131", -- Grön (Kall mörkgrön)
        4 => x"125", -- Vatten (Allt mörkare blå)
        8 => x"334", -- Stenar (Sval och mörk)
        others => x"879" -- Moln/Skum (Dovt lila/blått)
    );

    -- 11. Tidig natt (Original Night 2)
    constant palette_11 : palette_t := (
        0 => x"000", -- Svart
        1 => x"335", -- Sand (Mörkblå/grå)
        2 => x"501", -- Röd (Mycket mörkröd)
        3 => x"031", -- Grön (Väldigt mörkt gräs)
        4 => x"114", -- Vatten (Mörk marinblå)
        8 => x"223", -- Stenar (Mycket mörk blågrå)
        others => x"668" -- Moln/Skum (Månskensblått)
    );

    -- 12. Natt (Övergång)
    constant palette_12 : palette_t := (
        0 => x"000", -- Svart
        1 => x"224", -- Sand (Sval nattfärg)
        2 => x"400", -- Röd (Svagt röd-svart)
        3 => x"020", -- Grön (Nästan svart)
        4 => x"003", -- Vatten (Djupt marinblått)
        8 => x"112", -- Stenar (Mörka siluetter)
        others => x"446" -- Moln/Skum (Dovt nattblått)
    );

    -- 13. Midnatt (Original Night 3)
    constant palette_13 : palette_t := (
        0 => x"000", -- Svart
        1 => x"113", -- Sand (Nästan svart-blå)
        2 => x"300", -- Röd (Knappt synlig)
        3 => x"010", -- Grön (Svartgrön)
        4 => x"002", -- Vatten (Avgrundsblått)
        8 => x"111", -- Stenar (Nästan svarta)
        others => x"335" -- Moln/Skum (Väldigt mörkt månljus)
    );

    -- 14. Djup natt (Övergång)
    constant palette_14 : palette_t := (
        0 => x"000", -- Svart
        1 => x"123", -- Sand (Börjar vända mycket svagt)
        2 => x"300", -- Röd (Ingen förändring)
        3 => x"011", -- Grön (Svag ton av kyla)
        4 => x"002", -- Vatten (Fortfarande avgrundsblått)
        8 => x"121", -- Stenar (Lätt färgskiftning i svagt ljus)
        others => x"345" -- Moln/Skum (Kalla nyanser av blått återvänder)
    );

    -- 15. Vargtimmen (Original Night 4)
    constant palette_15 : palette_t := (
        0 => x"000", -- Svart
        1 => x"224", -- Sand (Svalt mörkblå)
        2 => x"401", -- Röd (Börjar synas lite igen)
        3 => x"021", -- Grön (Sval mörkgrön)
        4 => x"013", -- Vatten (Lite ljusare nattvatten)
        8 => x"222", -- Stenar (Mörkgrå)
        others => x"446" -- Moln/Skum (Svalt gråblått innan gryning)
    );

    -- 16. Morgonrodnad / Tidig gryning (Övergång)
    constant palette_16 : palette_t := (
        0 => x"000", -- Svart
        1 => x"867", -- Sand (Första solstrålarna värmer sanden snabbt)
        2 => x"933", -- Röd (Blommar upp i gryningsljuset)
        3 => x"272", -- Grön (Daggvått gräs ljusnar)
        4 => x"258", -- Vatten (Himlen speglar sig ljuslila)
        8 => x"444", -- Stenar (Börjar synas ordentligt)
        others => x"989" -- Moln/Skum (Snabb övergång till lilarosa morgonmoln)
    );
	signal current_pallete : palette_t;
    signal current_color : std_logic_vector(11 downto 0);

	signal tile_id : std_logic_vector(7 downto 0);
	signal h_big     : integer range 0 to 9;
	signal h_small    : integer range 0 to 9;
	signal m_big     : integer range 0 to 9;
	signal m_small    : integer range 0 to 9;

	signal s_bird1_color : std_logic_vector(11 downto 0);
	signal s_bird1_on    : std_logic;

	signal s_bird2_color : std_logic_vector(11 downto 0);
	signal s_bird2_on    : std_logic;

	signal s_seagull_color : std_logic_vector(11 downto 0);
	signal s_seagull_on    : std_logic;

	signal s_celestial_color : std_logic_vector(11 downto 0);
	signal s_celestial_on    : std_logic;

	
	-- Character image rom:
	component tile_rom is
		port (
			clk      : in std_logic;
			addr     : in unsigned(10 downto 0);
			data     : out std_logic_vector(3 downto 0));
	end component;

begin

	-- Fågel 1
	U_bird1 : entity work.bird_sprite 
		port map (
			clk => clk, 
			v_sync => Vsync2,
			pixel_en => Clk25,
			pixel_x => Xpixel2, pixel_y => Ypixel2,
			scale => 2,
			animStatus => animStatus,
			base_x => 700,
			base_y =>  100,
			sprite_pixel => s_bird1_color, sprite_on => s_bird1_on
		);

	-- Fågel 2
	U_bird2 : entity work.bird_sprite 
		port map (
			clk => clk, 
			v_sync => Vsync2,
			pixel_en => Clk25,
			pixel_x => Xpixel2, pixel_y => Ypixel2,
			scale => 3,
			animStatus => animStatus,
			base_x => 730,
			base_y =>  130,
			sprite_pixel => s_bird2_color, sprite_on => s_bird2_on
		);

	-- Sol/måne
	U_celestial : entity work.celestial_body
		port map (
			clk => clk,
			vsync => Vsync2,
			pixel_en => Clk25,
			is_day => video_mode,
			animStatus => animStatus,
			pixel_x => Xpixel2, pixel_y => Ypixel2,
			scale => 3,
			sprite_pixel => s_celestial_color,
			sprite_on => s_celestial_on
		);

	U_seagull : entity work.seagull_sprite
		port map (
			clk => clk,
			v_sync =>  Vsync2,
			pixel_en => Clk25,
			pixel_x => Xpixel2, pixel_y => Ypixel2,
			scale => 3,
			animStatus => animStatus,
			base_x => -100,
			base_y =>  200,
			sprite_pixel => s_seagull_color, sprite_on => s_seagull_on
		);

	-- Clock divisor
	-- Divide system clock (100 MHz) by 4
	process(clk)
	begin
		if rising_edge(clk) then
			if clear='1' then
				ClkDiv <= (others => '0');
			else
				ClkDiv <= ClkDiv + 1;
			end if;
		end if;
	end process;

	-- 25 MHz clock (one system clock pulse width)
	Clk25 <= '1' when (ClkDiv = 3) else '0';
	
	-- ClkDiv:  | 0 | 1 | 2 | 3 | 0 | 1 | 2 | 3 | 0 | 1 | 2 | 3 |
	-- Clk25:   |___|___|___|---|___|___|___|---|___|___|___|---|
	-- Xpixel1: |<     ...     >|<     ...     >|<     ...     >|
	-- Ypixel1: ...            >|<     ...                       
	-- VR_addr: |<     ...     >|<     ...     >|<     ...     >|  f(*pixel)
	-- VR_data: ...>|<     ...     >|<     ...     >|<     ...     f(addr) @ cc
	-- CR_Addr: ...>|<     ...     >|<     ...     >|<     ...     f(data, *pixel)
	-- CR_data:     ...>|<     ...     >|<     ...     >|< ...     f(tAddr) @ cc
	-- RGB:         ...>|<     ...     >|<     ...     >|< ...     f(tPixel)
	-- blank1:  |___|___|___|___|---|---|---|---|___|___|___|___|
	-- blank2:  |___|___|___|___|___|---|---|---|---|___|___|___|
	-- *sync1:  |---|---|---|---|___|___|___|___|---|---|---|---|
	-- *sync2:  |---|---|---|---|---|___|___|___|___|---|---|---|
	-- *sync:   |---|---|---|---|---|---|___|___|___|___|---|---|
	

	-- Horizontal pixel counter
	-- *******************************
	process(clk) begin
		if rising_edge(clk) then
			if clear ='1' then
					Xpixel1 <= "0000000000";
			elsif Clk25 = '1' then
				if Xpixel1 = 800 then
					Xpixel1 <= "0000000000";
				else
					Xpixel1 <= Xpixel1 + 1;
				end if;
			else
				Xpixel1 <= Xpixel1;
			end if;
		end if;
	end process;
	-- *******************************



        -- Horizontal sync
	-- *******************************
	process(clk) begin
		if rising_edge(clk) then
			if clear = '1' then
				Hsync1 <= '1';
			elsif ((Xpixel1 > 656) and (Xpixel1 < 753)) then
				Hsync1 <= '0';
			else
				Hsync1 <= '1';
			end if;
		end if;
	end process;

	-- *******************************



        -- Vertical pixel counter
	-- *******************************
	process(clk) begin
		if rising_edge(clk) then
			if clear ='1' then
					Ypixel1 <= "0000000000";
			elsif Clk25 = '1' then
				if Xpixel1 = 800 then
					if Ypixel1 = 521 then
						Ypixel1 <= "0000000000";
					else
						Ypixel1 <= Ypixel1 + 1;
					end if;
				else 
					Ypixel1 <= Ypixel1;
				end if;
			else
				Ypixel1 <= Ypixel1;
			end if;
		end if;
	end process;
	-- *******************************



        -- Vertical Sync
	-- *******************************
	process(clk) begin
		if rising_edge(clk) then
			if clear = '1' then
				Vsync1 <= '1';
			elsif ((Ypixel1 > 490) and (Ypixel1 < 493)) then
				Vsync1 <= '0';
			else
				Vsync1 <= '1';
			end if;
		end if;
	end process;
	-- *******************************



        -- Video blanking signal
	-- *******************************
	process(clk) begin
		if rising_edge(clk) then
			if ((Xpixel1 > 640) or (Ypixel1 > 480)) then
				blank1 <= '1';
			else
			blank1 <= '0';
			end if;
		end if;
	end process;
	-- *******************************
        
	


	-- Video ram address composite
	VR_addr_int <= to_unsigned(20, 7) * Ypixel1(8 downto 5) + Xpixel1(9 downto 5);-- which tile we are at
    
    -- Send value to physical port
    VR_addr <= VR_addr_int; 
	
	-- VIDEO_RAM:
	-- data <= mem(addr), with one clock cycle delay
	
	-- Delay
	process(clk)
	    variable addr : integer;
	begin
		if rising_edge(clk) then
			blank2 <= blank1;
			Hsync2 <= Hsync1;
			Vsync2 <= Vsync1;
			Xpixel2 <= Xpixel1;
			Ypixel2 <= Ypixel1;
			VR_addr_int2 <= VR_addr_int;
		end if;
	end process;
	

	h_big   <= to_integer(time_13bit(12 downto 11));
    h_small <= to_integer(time_13bit(10 downto 7));
    m_big   <= to_integer(time_13bit(6 downto 4));
    m_small <= to_integer(time_13bit(3 downto 0));

	-- Chose right tile, clock or standard
	process(VR_addr_int2, VR_data, h_big, h_small, m_big, m_small)
    begin
        -- Standard: rita det som finns i Video RAM
        tile_id <= VR_data; 

        -- Om vi är på klockans positioner (t.ex. index 31-35)
        case to_integer(VR_addr_int2) is
            when 31 => 
                tile_id <= std_logic_vector(to_unsigned(h_big + 10, 8));   -- H_tiotal
            when 32 => 
                tile_id <= std_logic_vector(to_unsigned(h_small + 10, 8)); -- H_ental
            when 33 => 
                tile_id <= x"14"; -- Kolon ":" (Index 20 i tile_rom)
            when 34 => 
                tile_id <= std_logic_vector(to_unsigned(m_big + 10, 8));   -- M_tiotal
            when 35 => 
                tile_id <= std_logic_vector(to_unsigned(m_small + 10, 8)); -- M_ental
            when others => 
                tile_id <= VR_data;
        end case;
    end process;

	-- Character rom address:
	CR_addr <=
		unsigned(tile_id(4 downto 0)) & -- convert to unsigned
		to_unsigned(to_integer(Ypixel2(4 downto 2)), 3) &
		to_unsigned(to_integer(Xpixel2(4 downto 2)), 3);
	
	U0b : tile_rom port map (clk=>clk, addr=>CR_addr, data=>CR_data); -- one clock cycle delay.

	process(activePalette)
    begin
        case activePalette is
            when "0000" => current_pallete <= palette_01;
            when "0001" => current_pallete <= palette_02;
            when "0010" => current_pallete <= palette_03;
            when "0011" => current_pallete <= palette_04;
            when "0100" => current_pallete <= palette_05;
            when "0101" => current_pallete <= palette_06;
            when "0110" => current_pallete <= palette_07;
            when "0111" => current_pallete <= palette_08;
            when "1000" => current_pallete <= palette_09;
            when "1001" => current_pallete <= palette_10;
            when "1010" => current_pallete <= palette_11;
            when "1011" => current_pallete <= palette_12;
            when "1100" => current_pallete <= palette_13;
            when "1101" => current_pallete <= palette_14;
            when "1110" => current_pallete <= palette_15;
            when "1111" => current_pallete <= palette_16;
            when others =>  current_pallete <= palette_16; -- Säkerhetsfall
        end case;
    end process;

	current_color <= current_pallete(to_integer(unsigned(CR_data))); -- Sets the color (12 bit) based on current color palette and CR_data

	process(clk)
	begin
		if rising_edge(clk) then
			Hsync <= Hsync2;
			Vsync <= Vsync2;
			blank <= blank2;
		end if;
	end process;
		
	
	-- VGA generation : 4 bit red, 4 bit green ,4 bit blue (lade till pixelväljare)
	process(clk)
	begin
		if rising_edge(clk) then
			if blank = '1' then
				vgaRed <= "0000";
				vgaGreen <= "0000";
				vgaBlue <= "0000";
			
			elsif s_seagull_on = '1' then
				vgaRed   <= s_seagull_color(11 downto 8);
				vgaGreen <= s_seagull_color(7 downto 4);
				vgaBlue  <= s_seagull_color(3 downto 0);
			elsif s_bird1_on = '1' then
				vgaRed   <= s_bird1_color(11 downto 8);
				vgaGreen <= s_bird1_color(7 downto 4);
				vgaBlue  <= s_bird1_color(3 downto 0);

			elsif s_bird2_on = '1' then
				vgaRed   <= s_bird2_color(11 downto 8);
				vgaGreen <= s_bird2_color(7 downto 4);
				vgaBlue  <= s_bird2_color(3 downto 0);

			elsif s_celestial_on = '1' then
				vgaRed   <= s_celestial_color(11 downto 8);
				vgaGreen <= s_celestial_color(7 downto 4);
				vgaBlue  <= s_celestial_color(3 downto 0);

				else
                vgaRed   <= current_color(11 downto 8);
                vgaGreen <= current_color(7 downto 4);
                vgaBlue  <= current_color(3 downto 0);
            end if;
        end if;
    end process;
end Behavioral;