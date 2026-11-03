library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--CPU interface
entity uprogCPU is
  port(
		clk				: in std_logic;
		btnC 			: in std_logic;     			-- Reset button (middle of the five), active high
		RE_direction 	: in unsigned(1 downto 0); 		-- Direction of RE
		RE_value 		: in unsigned(1 downto 0); 		-- Value (Speed) of RE
		RE_clear		: out std_logic;
		clk_H1 			: out unsigned(1 downto 0);		-- CLK time HH 
		clk_H2 			: out unsigned(3 downto 0);		-- CLK time hhhh
		clk_M1 			: out unsigned(2 downto 0);		-- CLK time MMM
		clk_M2 			: out unsigned(3 downto 0);		-- CLK time mmmm
		curTime			: out unsigned(15 downto 0)		-- time in day/night cycle 	
	);
end entity;

architecture func of uprogCPU is

	signal rst : std_logic;       -- synchronous clear

	-- micro memory signals
	signal uM : unsigned(24 downto 0); -- micro Memory output
	alias ALU_OP : unsigned(3 downto 0) is uM(24 downto 21);
	alias TB : unsigned(3 downto 0) is uM(20 downto 17);
	alias FB : unsigned(3 downto 0) is uM(16 downto 13);
	alias MuxSel : std_logic is uM(12); -- (0:@=GRx, 1:@=M)
	alias PCsig : std_logic is uM(11);  -- (0:PC=PC, 1:PC++)
	alias SEQ : unsigned(3 downto 0) is uM(10 downto 7);
	alias mikAddr : unsigned(6 downto 0) is uM(6 downto 0);

	-- lookup table signals
	signal K1_out : unsigned(5 downto 0);
	signal K2_out : unsigned(5 downto 0);

	-- program memory signals
	signal PM : unsigned(31 downto 0); -- Program Memory output
	signal we : std_logic := '0'; -- write enable to PM

	-- local registers
	signal uPC : unsigned(5 downto 0); -- micro Program Counter
	signal PC : unsigned(7 downto 0); -- Program Counter
	signal IR : unsigned(31 downto 0); -- Instruction Register
	alias ADR : unsigned(19 downto 0) is IR(19 downto 0); -- ADR part of IR
	signal ASR : unsigned(7 downto 0); -- Address Register
	signal AR :  signed(31 downto 0); -- Acumulator Register
	signal GR0 : unsigned(31 downto 0); -- General Register 0
	signal GR1 : unsigned(31 downto 0); -- General Register 1
	signal GR2 : unsigned(31 downto 0); -- General Register 2
	signal GR3 : unsigned(31 downto 0); -- General Register 3
	signal GRx : unsigned(3 downto 0); -- Chosen register to access via DEMUX
	signal GR_OUT : unsigned(31 downto 0); -- General Register to data bus

	-- Video registers
	signal time 	: unsigned(15 downto 0) := (others => '0');		-- animation time

	-- clock display registers
	signal clk_Hs1 	: unsigned(1 downto 0);		-- CLK time HH 
	signal clk_Hs2	: unsigned(3 downto 0);		-- CLK time hhhh
	signal clk_Ms1 	: unsigned(2 downto 0);		-- CLK time MMM
	signal clk_Ms2 	: unsigned(3 downto 0);		-- CLK time mmmm

	-- Rotary Encoder Registers
	signal RE_dir : unsigned(1 downto 0);
	signal RE_val : unsigned(1 downto 0);
	signal RE_OUT : unsigned(1 downto 0);
	signal RE_clr : std_logic := '0';

	-- flags
	signal Z : std_logic := '0';
	signal N : std_logic := '0';

	-- local combinatorials
	signal DATA_BUS : unsigned(31 downto 0); -- Data Bus

begin
	process(clk)
	begin
		if rising_edge(clk) then
			rst <= btnC; -- syncronize the reset signal
			curTime <= time;
			
			clk_H1 <= clk_Hs1;
			clk_H2 <= clk_Hs2;
			clk_M1 <= clk_Ms1;
			clk_M2 <= clk_Ms2; 

			RE_dir <= RE_direction;
			RE_val <= RE_value;
			RE_clear <= RE_clr;
		end if;
	end process;

	-- mPC : micro Program Counter
	process(clk)
	begin
		if rising_edge(clk) then
			if (rst = '1') then
				uPC <= (others => '0');
			else 
				case SEQ is
					when "0000" => uPC <= uPC + 1;
					when "0001" => uPC <= K1_out;
					when "0010" => uPC <= K2_out;
					when "0011" => uPC <= "000000";
					when "0100" => case Z is 
								when '0' => uPC <= mikAddr(5 downto 0);
								when others => uPC <= uPC + 1;
								end case;
					when "0101" => uPC <= mikAddr(5 downto 0);
					when "1000" => case Z is 
								when '1' => uPC <= mikAddr(5 downto 0);
								when others => uPC <= uPC + 1;
								end case;
					when "1111" => uPC <= uPC;
					--------------------------------------------------------------------------------
					-- add more cases depending on what functionality we need
					--------------------------------------------------------------------------------
					when others => uPC <= "000000";
				end case;
			end if;
		end if;
	end process;

	-- PC : Program Counter
	process(clk)
	begin
		if rising_edge(clk) then
			if (rst = '1') then
				PC <= (others => '0');
			elsif (FB = "0011") then
				PC <= DATA_BUS(7 downto 0);
			elsif (PCsig = '1') then
				PC <= PC + 1;
			end if;
		end if;
	end process;

	-- IR : Instruction Register
	process(clk)
	begin
		if rising_edge(clk) then
			if (rst = '1') then
				IR <= (others => '0');
			elsif (FB = "0001") then
				IR <= DATA_BUS;
			end if;
		end if;
	end process;

	-- ASR : Address Register
	process(clk)
	begin
		if rising_edge(clk) then
			if (rst = '1') then
				ASR <= (others => '0');
			elsif (FB = "0111") then
				ASR <= DATA_BUS(7 downto 0);
			end if;
		end if;
	end process;

	-- GRx DEMUX
	process(clk)
	begin
		if(rising_edge(clk)) then
			if (rst = '1') then
				GR0 <= (others => '0');
				GR1 <= (others => '0');
				GR2 <= (others => '0');
				GR3 <= (others => '0');
				clk_Hs1 <= (others => '0');
				clk_Hs2 <= (others => '0');
				clk_Ms1 <= (others => '0');
				clk_Ms2 <= (others => '0');
			elsif (FB = "0110") then
				case GRx is
					when "0000" => GR0 <= DATA_BUS;
					when "0001" => GR1 <= DATA_BUS;
					when "0010" => GR2 <= DATA_BUS;
					when "0011" => GR3 <= DATA_BUS;
					when "0100" => clk_Hs1 <= DATA_BUS(1 downto 0);
					when "0101" => clk_Hs2 <= DATA_BUS(3 downto 0);
					when "0110" => clk_Ms1 <= DATA_BUS(2 downto 0);
					when "0111" => clk_Ms2 <= DATA_BUS(3 downto 0);
					when others => null;
				end case;
			end if;
		end if;
	end process;

	-- ALU
	process(clk) 
		variable temp_AR : signed(AR'range); 	-- use variable to be able to update directly instead of after process is finished
        variable update_flags : std_logic;		-- keep track of if we should update flags
	begin
		if rising_edge(clk) then
			if rst = '1' then
				AR <= (others => '0');
				Z <= '0';
				N <= '0';
			else
				update_flags := '1';
				case ALU_OP is
					when "0000" => 
                    temp_AR := AR;                        				-- NOP
                    update_flags := '0';                  				-- Explicitly don't change flags
					when "0001" => temp_AR := signed(DATA_BUS);			-- AR:=BUSS
					when "0010" => temp_AR := not(signed(DATA_BUS)) + 1;-- AR:=BUSS'
					when "0011" => temp_AR := (others => '0');			-- AR:=0
					when "0100" => temp_AR := AR + signed(DATA_BUS);	-- AR:=AR+BUSS 
					when "0101" => temp_AR := AR - signed(DATA_BUS);	-- AR:=AR-BUSS
					when "0110" => temp_AR := (AR and signed(DATA_BUS));-- AR:=AR&BUSS
					when "0111" => temp_AR := (AR or signed(DATA_BUS));	-- AR:=AR|BUSS
					when "1000" =>
					 	temp_AR := AR + signed(DATA_BUS);				-- AR:=AR+BUSS (No Flags)
						update_flags := '0';							-- Explicitly don't change flags
					when "1001" => temp_AR := (AR sll 1);				-- AR:=AR << 1
					when "1010" => temp_AR := (AR srl 1);				-- AR:=AR >> 1
					when "1011" => temp_AR := (AR + 1);					-- AR:=AR + 1
					when "1100" => temp_AR := (AR - 1);					-- AR:=AR - 1
					when "1101" => 
						temp_AR := (AR + 1);					-- AR:=AR + 1 (utan flaggor)
						update_flags := '0';
					when "1110" => 
						temp_AR := (AR - 1);					-- AR:=AR - 1 (utan flaggor)
						update_flags := '0';
					when others => temp_AR := (others => '0');
				end case;
				AR <= temp_AR;											

				if (update_flags = '1') then
					-- Z-flag
					if (temp_AR = 0) then
                        Z <= '1';
                    else
                        Z <= '0';
                    end if;

					-- N-flag
                    if (temp_AR < 0) then
                        N <= '1';
                    else
                        N <= '0';
                    end if;
				end if;
			end if;
		end if;
	end process;

	-- animation registers
	process(clk) 
	begin
		if rising_edge(clk) then
			if rst = '1' then
				time <= (others => '0');
			else
				if (FB = "1001") then
					time <= DATA_BUS(15 downto 0);
				-- elsif (FB = "1010") then 
				-- 	clk_t <= DATA_BUS(10 downto 0);
				end if;
			end if;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				RE_clr <= '0';
			elsif (FB = "1000") then 
				RE_clr <= DATA_BUS(0);
			end if;
		end if;
	end process;


	-- micro memory component connection
	Umemory : entity work.uMem 
		port map(uAddr=>uPC, uData=>uM);

	-- program memory component connection
	Pmemory : entity work.pMem 
		port map(pAddr=>ASR, writeEnable=>we, busData=>DATA_BUS, pData=>PM);

	Lookup1 : entity work.K1 
		port map(OP_code => IR(31 downto 26), K1_data => K1_out);

	Lookup2 : entity work.K2 
		port map(addrMode => IR(21 downto 20), K2_data => K2_out);

	-- case for DEMUX/MUX selector
	GRx <= IR(25 downto 22) when (MuxSel = '0') else
		("00" & IR(21 downto 20)) when (MuxSel = '1') else
		(others => '0');

	-- case for GRx MUX-output
	GR_OUT <= GR0 when (GRx = "0000") else
		GR1 when (GRx = "0001") else
		GR2 when (GRx = "0010") else
		GR3 when (GRx = "0011") else
		resize(clk_Hs1, GR_OUT'length) when (GRx = "0100") else
		resize(clk_Hs2, GR_OUT'length) when (GRx = "0101") else
		resize(clk_Ms1, GR_OUT'length) when (GRx = "0110") else
		resize(clk_Ms2, GR_OUT'length) when (GRx = "0111") else
		(others => '0');

	RE_OUT <= RE_dir when (ADR = to_unsigned(255, ADR'length)) else
			RE_val when (ADR = to_unsigned(254, ADR'length)) else 
			(others => '0');

	-- data bus assignment
	DATA_BUS <= IR when (TB = "0001") else
		PM when (TB = "0010") else
		resize(PC, DATA_BUS'length) when (TB = "0011") else
		unsigned(AR) when (TB = "0100") else
		GR_OUT when (TB = "0110") else
		resize(uM, DATA_BUS'length) when (TB = "0111") else
		resize(RE_OUT, DATA_BUS'length) when (TB = "1000") else
		resize(time, DATA_BUS'length) when (TB = "1001") else
		-- resize(clk_t, DATA_BUS'length) when (TB = "1010") else
		resize(ADR, DATA_BUS'length) when (TB = "1011") else
		resize(unsigned'("" & RE_clr), DATA_BUS'length) when (TB = "1100") else
		(others => '0');

	we <= '1' when (FB = "0010") else '0';

end architecture;
