library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PmodENC_Top is
    Port ( 
        clk      : in  STD_LOGIC;         -- Pin W5
        button   : in  STD_LOGIC;         -- Pin J2 (Pmod JA3) - Switches between 4 states/modes
        switch   : in  STD_LOGIC;         -- Pin G2 (Pmod JA4) - Enable display
        signal_A : in  STD_LOGIC;         -- Pin J1 (Pmod JA1)
        signal_B : in  STD_LOGIC;         -- Pin L2 (Pmod JA2)
        led      : out STD_LOGIC_VECTOR (1 downto 0); -- Pins U16, E19
        seg      : out STD_LOGIC_VECTOR (6 downto 0); -- Pins W7 to U7
        an       : out STD_LOGIC_VECTOR (3 downto 0)  -- Pins U2 to W4
    );
end PmodENC_Top;

architecture Structural of PmodENC_Top is
    signal debA, debB, debBtn : std_logic;
    signal value   : std_logic_vector(1 downto 0);
begin
    Inst_Debouncer: entity work.Debouncer 
        port map(clk => clk, Ain => signal_A, Bin => signal_B, Aout => debA, Bout => debB);

    Btn_Debounce: entity work.Debouncer 
    port map(clk  => clk, Ain  => button,Bin  => '0', Aout => debBtn, Bout => open);

    Inst_Encoder: entity work.Encoder 
        port map(clk => clk, signal_A => debA, signal_B => debB, button => debBtn, mode => value, Direction => led);

    Inst_Display: entity work.DisplayController 
        port map(clk => clk, SWT => switch, mode => value, anode => an, segOut => seg);
end Structural;