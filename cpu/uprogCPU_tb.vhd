LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY uprogCPU_tb IS
END uprogCPU_tb;

ARCHITECTURE func OF uprogCPU_tb IS

  -- Component Declaration for the Unit Under Test (UUT)
  COMPONENT uprogCPU
  PORT(
    clk           : IN std_logic;
    btnC          : IN std_logic;                 -- reset, active high
    RE_direction  : in unsigned(1 downto 0);      -- Direction of RE
    RE_value      : in unsigned(1 downto 0)       -- Value (Speed) of RE
  );
  END COMPONENT;

  -- Inputs
  signal clk : std_logic := '0';
  signal rst : std_logic := '0';
  signal dir : unsigned(1 downto 0) := (others => '0');
  signal val : unsigned(1 downto 0) := (others => '0');

  -- Clock period definitions
  constant clk_period : time := 10 ns; -- 100 MHz

BEGIN
  -- Instantiate the Unit Under Test (UUT)
  uut: uprogCPU PORT MAP (
    clk          => clk,
    btnC         => rst,
    RE_direction => dir,
    RE_value     => val
  );
    
  -- Clock process: ONLY generates the clock signal
  clk_process :process
  begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
  end process;

  -- Stimulus process: Controls inputs over time
  stim_proc: process
  begin
    -- 1. Initial State & Reset
    dir <= "00";
    val <= "00";
    rst <= '1';
    wait for 20 ns; -- Hold reset for two clock cycles
    rst <= '0';

    -- 2. Run for a while with dir = "00" (Nothing happens)
    -- We'll hold this state for 100 ns (10 clock cycles)
    wait for 530 ns;

    -- 3. Change dir = "01" and set a 2-bit val != "00"
    dir <= "01";
    val <= "10"; -- Setting to 2 (binary 10)

    -- Let the simulation run to observe the CPU's behavior
    wait for 500 ns;
    
    -- Suspend the process indefinitely so the simulation doesn't loop
    wait; 
  end process;

END;