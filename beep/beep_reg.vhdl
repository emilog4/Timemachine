-- Sound generator unit. Beeps with arbitrary frequency and magnitude.
-- 
-- There are five registers:
-- * (reg_addr=0) = freq_lo. Frequency is given in unit 0.745 Hz.
-- * (reg_addr=1) = freq_hi.
-- * (reg_addr=2) = tone. Write to freq in a more music-friendly way, described below. This is write only.
-- * (reg_addr=3) = magnitude. Sound amplitude ~ 2^(magnitude/16)
-- * (reg_addr=4) = length (in unit 5.24 ms). Value 0 means "forever"
-- * (reg_addr=5) = Ctrl - Control register, described below.
-- 
-- There is one interrupts available, trigged when a timed beep is ended.
-- Ctrl register: [INT_en, INT_flag, running, start, -, -, Snd1, Snd0]
--   INT_en    : a '1' here enables the IRQ.
--   INT_flag  : This is set by hardware when the desired flank is detected.
--               This is reset when the ISR is called (signaled by irq_ack).
--               This can be reset by writing a '1' to it.
--   running   : This is set by writing to "start". This is stopped by hardware, or by writing a zero to it.
--   start     : Copy the freq, magnitude and length to internal registers, and start the operation.
--   Snd1..0   : Defines the type of sound.
--               Snd = 0: Sinusoid
--               Snd = 1: Square wave
--               Snd = 2: Triangle wave
--               Snd = 3: White noise (freq ignored).
-- Tone register: [ mooo nnnn ]
--   m = mute, will set freq = 0, regardless of ooo and nnnn.
--   The ooo = 0..7 defines the octave, nnnn = 0..11 defines the note (half-tone) within the octave (nnnn=0 is a C).
--   Freq = (constant) * 2^(ooo + nnnn/12)
--   The constant is adjusted such that {ooo=3, nnnn=9} gives the A 440 Hz.
--   

-- Suggested advanced extensions: Define envelop for the sound.
--  (envelop: variable magnitude over time, typical phases:
--   1. attack: linear increase of magnitude from 0 to A_attack, during time T_Attack.
--   2. Decay: linear decrease of magnitude from A_attack to A_def, during time T_Decay. A_def is user defined aplitude.
--   3. Sustain: Keep magnitude A_def. Or let it attenuate slowly.
--   4. Release: Linear decrease from A2 to 0 during time T_Release).
--   Simple version:
--     * Let T_Attack = T_Decay = T_Release be 1024 samples (~21 ms). Then amplitude = A_attack*i>>10 in the attack phase.
--     * Let A_attack = 1.5*A_def.
--     * Release phase when timeout <= 1024. amplitude = A_def*timeout>>10.
--     * Implement just a few styles, and use Ctrl_reg(3..2) to select. A style is e.g. attack/decay on/off, and release on/off.
-- Polyvoice extension:
--   Remove i2s_base from beep_reg, and let parent instantiate that instead.
--   Let parent instantiate several beep_reg modules. Their "sample" can be added together before the beep_reg.
-- REALLY fancy project:
--   * Implement a digital version of Commodore 6581 Sound Interface Device ("SID"). Now we're talking.
--     (https://ccrma.stanford.edu/~chet/projects/tech_content/6581.pdf)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity beep_reg is
	port(clk, reset : in std_logic; -- syncronous, active high reset.
		-- CPU register interface:
		reg_addr : in unsigned(2 downto 0); -- There are 5 registers
		reg_we : in std_logic;
		reg_wData : in unsigned(7 downto 0);
		reg_re : in std_logic;                 -- Used only if the unit wants to know if the user did read a value. I.e. for FIFO buffers.
		reg_rData : out unsigned(7 downto 0);  -- async from reg_addr.
		-- CPU Interrupt interface
		irq : out std_logic_vector(0 to 0);    -- This is INT*_flag AND INT*_en.
		irq_ack : in std_logic_vector(0 to 0); -- Pull this high when the ISR is called. It clears the irq signal.
		
		-- Port to surrounding world:
		mclk : out std_logic; -- master clock: e.g. 12.5 MHz
		lrck : out std_logic; -- left/right clock: 48.828 kHz (mclk/256)
		sclk : out std_logic; -- bit clock: 1.56 MHz (mclk/8, or lrclk*32)
		sdat : out std_logic;  -- serial data. Connect to pmod_i2s.sdin
		piezo_out : out std_logic 
	);
end entity;

architecture behav of beep_reg is
	-- CPU registers:
	signal freq : unsigned(15 downto 0);
	signal magnitude : unsigned(7 downto 0);
	signal length : unsigned(7 downto 0);
	signal ctrl_reg : unsigned(7 downto 0);
	constant INT_en : integer := 7;
	constant INT_flag : integer := 6;
	constant RUNNING : integer := 5;
	constant START : integer := 4;
	constant SND1 : integer := 1;
	constant SND0 : integer := 0;
	
	signal tone2freq_LUT : unsigned(16 downto 0); -- LUT(reg_wData(x3..0)) when writing to tone_reg
	signal tone2freq_shift : unsigned(16 downto 0); -- shift_right(reg_wData(6..4)) + 1, where +1 is for rounding when LSB is removed.
	
	-- Internal control and Tone generators:
	signal FCW : unsigned(15 downto 0); -- "internal freq"
	signal linear_mag : unsigned(15 downto 0); -- "internal 2^(magnitude/16)"
	signal timeout : unsigned(15 downto 0); -- "internal length<<8".
	signal do_run_timeout : std_logic;
	signal phase_ack : unsigned(15 downto 0);
	component PSAC is -- Phase to Sine Amplitude Converter. Implemented in bottom of this file.
		port(clk: in std_logic;
		     x  : in unsigned(15 downto 0); -- "111..1" corresponds to (almost) 360 deg
		     a  : out signed(15 downto 0)); -- "011..1" = +1 (almost), "100..0" = -1
	end component;
	signal tone_sine : signed(15 downto 0);
	signal tone_triangle : signed(15 downto 0);
	signal tone_square : signed(15 downto 0);
	signal tone_noise : signed(15 downto 0) := x"0000";
	signal tone_before_mag : signed(15 downto 0);
	signal tone_after_mag : signed(15 downto 0); -- connected to i2s.sample.
	
	-- The i2s module:
	signal lrsel : std_logic;
	signal req : std_logic;
	component i2s_base is
		port(clk,rst : in std_logic; -- 100 MHz, sync active high reset
			-- app interface:
			lrsel : out std_logic; -- 1=left, 0=right
			req : out std_logic; -- 1=I'll read new data on sample input
			sample : in signed(15 downto 0);
			-- I2S interface:
			mclk : out std_logic; -- master clock: e.g. 12.5 MHz
			lrck : out std_logic; -- left/right clock: 48.828 kHz (mclk/256)
			sclk : out std_logic; -- bit clock: 1.56 MHz (mclk/8, or lrclk*32)
			sdat : out std_logic); -- serial data. Connect to pmod_i2s.sdin
	end component;
	
begin
	
	reg_rData <=
		freq(7 downto 0) when reg_addr = 0 else
		freq(15 downto 8) when reg_addr = 1 else
		magnitude when reg_addr = 3 else
		length when reg_addr = 4 else
		Ctrl_reg when reg_addr = 5 else
		(others=>'X'); -- don't care.

-- There are five registers:
-- * (reg_addr=0) = freq_lo. Frequency is given in unit 0.745 Hz.
-- * (reg_addr=1) = freq_hi.
-- * (reg_addr=2) = tone. Write to freq in a more music-friendly way, described below.
-- * (reg_addr=3) = magnitude. Real sound amplitude ~ 2^(magnitude/16)
-- * (reg_addr=4) = length (in unit 5.24 ms). Value 0 means "forever"
-- * (reg_addr=5) = Ctrl - Control register, described below.

	irq(0) <= Ctrl_reg(INT_flag) and Ctrl_reg(INT_en);
	
	-- tone generators:
	psac_i : psac port map(clk=>clk, x=>phase_ack, a=>tone_sine);
	tone_triangle <= signed(phase_ack); -- yep, it's that simple.
	tone_square <= to_signed(+(2**15-1), 16) when phase_ack(15) = '0' else
	               to_signed(-(2**15-1), 16);
	
	tone_before_mag <=
		tone_sine     when Ctrl_reg(Snd1 downto Snd0) = 0 else
		tone_square   when Ctrl_reg(Snd1 downto Snd0) = 1 else
		tone_triangle when Ctrl_reg(Snd1 downto Snd0) = 2 else
		tone_noise; --when Ctrl_reg(Snd1 downto Snd0) = 3
	
	process(clk)
		variable tmp : unsigned(15 downto 0);
	begin
		if rising_edge(clk) then
			-- This process controls all registers. The process is sorted on behaviour rather than register.
			
			-- CPU writes to registers:
			if reg_we = '1' then
				case to_integer(reg_addr) is
					when 0 => freq(7 downto 0) <= reg_wData;
					when 1 => freq(15 downto 8) <= reg_wData;
					when 2 => freq <= tone2freq_shift(16 downto 1);
						if reg_wData(7) = '1' then freq <= X"0000"; end if;
					when 3 => magnitude <= reg_wData;
					when 4 => length <= reg_wData;
					when 5 => Ctrl_reg <= reg_wData;
						-- INT_flags: Keep its value, unless writing a '1' to it or to START.
						Ctrl_reg(INT_flag) <= Ctrl_reg(INT_flag) and not reg_wData(INT_flag) and not reg_wData(START);
						-- RUNNING: Cannot be set, but reset by user:
						Ctrl_reg(RUNNING) <= Ctrl_reg(RUNNING) and (reg_wData(RUNNING) or reg_wData(START));
					when others =>
				end case;
			end if;

			-- irq_ack:
			if irq_ack(0) = '1' then
				Ctrl_reg(INT_flag) <= '0';
			end if;
			
			-- Actions when START:
			if Ctrl_reg(START) = '1' then
				Ctrl_reg(START) <= '0';
				Ctrl_reg(RUNNING) <= '1';
				FCW <= freq;
				-- linear_mag = (1.mag(3..0))*2^(mag(7..4))
				tmp := '1' & magnitude(3 downto 0) & b"000_0000_0000";
				if magnitude(7) = '0' then tmp := shift_right(tmp, 8); end if;
				if magnitude(6) = '0' then tmp := shift_right(tmp, 4); end if;
				if magnitude(5) = '0' then tmp := shift_right(tmp, 2); end if;
				if magnitude(4) = '0' then tmp := shift_right(tmp, 1); end if;
				linear_mag <= tmp;
				timeout <= length & x"00";
				do_run_timeout <= '1';
				if length = 0 then
					do_run_timeout <= '0';
				end if;
				-- avoid click sound by resetting phase ack iff new start
				if Ctrl_reg(RUNNING) = '0' then
					phase_ack <= (others=>'0');
				end if;
			end if;

			-- Timeout related stuffs:
			if req = '1' and lrsel = '1' and Ctrl_reg(RUNNING) = '1' and do_run_timeout = '1' then
				timeout <= timeout - 1;
				if timeout = 0 then
					Ctrl_reg(RUNNING) <= '0';
					Ctrl_reg(INT_flag) <= '1';
				end if;
			end if;
			
			-- Implement the sound generators:
			tone_noise <= (tone_noise(0) xor tone_noise(7) xor req) & tone_noise(15 downto 1); -- linear feedback shift register, with `req` as modifier
			if req = '1' and lrsel = '1' and Ctrl_reg(RUNNING) = '1' then
				phase_ack <= phase_ack + FCW;
			end if;
			-- tone_sine <= sin(phase_ack), done in psac. Latency = 2 clock cycles is no problem (we have 1024 in total)
			-- tone_triangle <= signed(phase_ack) -- yep, it's that simple.
			-- tone_square <= +-(2^15-1) when phase_ack(15)
			-- tone_before_mag <= mux(tone_sine, tone_triangle, tone_square, tone_noise);
			tone_after_mag <= resize(shift_right(signed('0'&linear_mag) * tone_before_mag, 16), 16);
			if Ctrl_reg(RUNNING) = '0' then -- shut up when not playing
				tone_after_mag <= x"0000";
			end if;
			
			-- Finally, the reset overwrites some of the registers.
			if reset = '1' then
				Ctrl_reg <= x"00";
			end if;
		end if;
	end process;
	
	i2s_base_i : component i2s_base port map(clk=>clk, rst=>reset,
		lrsel=>lrsel, req=>req, sample=>tone_after_mag,
		mclk=>mclk, lrck=>lrck, sclk=>sclk, sdat=>sdat);
	
	tone2freq_LUT <= -- round(43.89 * 2^(7+tttt/12) * 2), where *2 is for rounding and 43.89 = (440/2^(3+9/12)=32.7) / (100 MHz/2^27=0.745 Hz)
		to_unsigned(11237, 17) when reg_wData(3 downto 0) = 0 else -- 4186,01 Hz when freq = 11237/2
		to_unsigned(11905, 17) when reg_wData(3 downto 0) = 1 else -- 4434,92 Hz
		to_unsigned(12613, 17) when reg_wData(3 downto 0) = 2 else -- 4698,64 Hz
		to_unsigned(13363, 17) when reg_wData(3 downto 0) = 3 else -- 4978,03 Hz
		to_unsigned(14157, 17) when reg_wData(3 downto 0) = 4 else -- 5274,04 Hz
		to_unsigned(14999, 17) when reg_wData(3 downto 0) = 5 else -- 5587,65 Hz
		to_unsigned(15891, 17) when reg_wData(3 downto 0) = 6 else -- 5919,91 Hz
		to_unsigned(16836, 17) when reg_wData(3 downto 0) = 7 else -- 6271,93 Hz
		to_unsigned(17837, 17) when reg_wData(3 downto 0) = 8 else -- 6644,88 Hz
		to_unsigned(18898, 17) when reg_wData(3 downto 0) = 9 else -- 7040 Hz = 440 Hz * 2^(7-4)
		to_unsigned(20022, 17) when reg_wData(3 downto 0) = 10 else -- 7458,62 Hz
		to_unsigned(21212, 17) when reg_wData(3 downto 0) = 11 else -- 7902,13 Hz
		to_unsigned(0, 17);
	tone2freq_shift <= shift_right(tone2freq_LUT, to_integer(not reg_wData(6 downto 4))) + 1;

end architecture;



-- ==================== Private modules ============================

-- ===== PSAC =====
-- A sine polynomial approximation function, with 64 first order polynomials per quadrant.
-- N=16 (2^N points per rotation), F=8 (2^F points per quadrant), C=N-2-F=6 (2^C polynomials per quadrant).
-- W=16 (output wordlength)
-- latency: 2
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PSAC is
	port(
		clk: in std_logic;
		x  : in unsigned(15 downto 0);
		a  : out signed(15 downto 0) := (others=>'0'));
end PSAC;

architecture rtl of PSAC is
	signal x2    : unsigned(13 downto 0) := (others=>'0');   -- x(N-3 downto 0) xor x(N-2). This addresses each point in one quadrant
	signal xC    : unsigned(5 downto 0) := (others=>'0');   -- x(N-3 downto F) xor x(N-2). This addresses each polynomial in one quadrant
	signal xF    : unsigned(7 downto 0) := (others => '0'); -- x(F-1 downto 0) xor x(N-2). This addresses each point in one polynomial
	signal inv_res_0 : std_logic;
	-- signals for stage 1
	signal xF_1   : unsigned(7 downto 0) := (others => '0');
	signal slope_1  : unsigned(9 downto 0) := (others => '0');
	signal offset_1: unsigned(14 downto 0) := (others => '0');
	signal inv_res_1 : std_logic;
	-- signals for stage 2
	signal Res_2  : unsigned(14 downto 0) := (others => '0');
	signal inv_res_2 : std_logic;
	-- *_K => signals is delayed K clock cycles from it's x input.

	function "+"(l : unsigned; r : std_logic) return unsigned is begin
		return unsigned(ieee.std_logic_unsigned."+"(std_logic_vector(l), r));
	end "+";

	type romt is array(0 to 63) of unsigned(24 downto 0);
	signal rom_data : romt; -- constant, assigned in the bottom.
begin
	
	-- Timing diagram, ish:
	--   | x,x2 etc  |     |     |
	--   |           | *_1 | *_2 |
	--   |           |     |  a  |

	-- Initial phase adjustment to quadrant:
	x2 <= unsigned(x(13 downto 0)) when x(14) = '0' else  not unsigned(x(13 downto 0));
	xC <= x2(13 downto 8);
	xF <= x2(7 downto 0);
	inv_res_0 <= x(15);

	process(clk)
		variable tmp : unsigned(23 downto 0);
		variable rom_line : unsigned(24 downto 0);
	begin
		if rising_edge(clk) then
			------ Pipeline stage 1 -------
			xF_1 <= xF;
			rom_line := rom_data(to_integer(xC));
			slope_1 <= rom_line(24 downto 15);
			offset_1 <= rom_line(14 downto 0);
			inv_res_1 <= inv_res_0;
			------ Pipeline stage 2 -------
			tmp := (others => '0');
			tmp(17 downto 0) := slope_1 * xF_1;
			Res_2 <= offset_1 + tmp(22 downto 8);-- + tmp(7);
			inv_res_2 <= inv_res_1;
		end if;
	end process;

	-- final result adjustment to quadrant:
	a <= signed('0' & Res_2) when inv_res_2 = '0' else
	    -signed('0' & Res_2);

	rom_data <= (
		b"1100100100_000000000011001", b"1100100100_000001100111101", b"1100100011_000011001100001", b"1100100001_000100110000100",
		b"1100011111_000110010100101", b"1100011101_000111111000100", b"1100011010_001001011100001", b"1100010111_001010111111011",
		b"1100010011_001100100010001", b"1100001110_001110000100100", b"1100001010_001111100110010", b"1100000100_010001000111100",
		b"1011111111_010010101000000", b"1011111000_010100000111110", b"1011110010_010101100110111", b"1011101011_010111000101000",
		b"1011100011_011000100010011", b"1011011011_011001111110110", b"1011010011_011011011010001", b"1011001010_011100110100011",
		b"1011000001_011110001101101", b"1010110111_011111100101101", b"1010101101_100000111100011", b"1010100010_100010010010000",
		b"1010010111_100011100110010", b"1010001100_100100111001000", b"1010000000_100110001010100", b"1001110100_100111011010011",
		b"1001100111_101000101000111", b"1001011010_101001110101110", b"1001001101_101011000001000", b"1001000000_101100001010101",
		b"1000110010_101101010010100", b"1000100011_101110011000101", b"1000010101_101111011101000", b"1000000110_110000011111100",
		b"0111110111_110001100000010", b"0111100111_110010011111000", b"0111010111_110011011011110", b"0111000111_110100010110101",
		b"0110110111_110101001111011", b"0110100110_110110000110001", b"0110010101_110110111010111", b"0110000100_110111101101011",
		b"0101110010_111000011101110", b"0101100001_111001001100000", b"0101001111_111001111000000", b"0100111101_111010100001111",
		b"0100101011_111011001001011", b"0100011000_111011101110101", b"0100000110_111100010001101", b"0011110011_111100110010010",
		b"0011100000_111101010000100", b"0011001101_111101101100011", b"0010111010_111110000110000", b"0010100111_111110011101001",
		b"0010010011_111110110001111", b"0010000000_111111000100001", b"0001101100_111111010100001", b"0001011001_111111100001100",
		b"0001000101_111111101100100", b"0000110001_111111110101001", b"0000011110_111111111011001", b"0000001010_111111111110110");
	
		piezo_out <= phase_ack(15) when Ctrl_reg(5) = '1' else '0';
end architecture;

