-- Pmod ENC Pin Mapping (6-pin Pmod, top row):
--   Pin 1 (JxA[0]) -> A
--   Pin 2 (JxA[1]) -> B
--   Pin 3 (JxA[2]) -> BTN   : Push-button (active low, debounced)
--   Pin 4 (JxA[3]) -> SWT   : Slide switch
--   Pin 5          -> GND
--   Pin 6          -> Power

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- library declaration
entity Encoder is
    Port (
        clk         : in STD_LOGIC;
        signal_A    : in STD_LOGIC;   
        signal_B    : in STD_LOGIC;
        button      : in STD_LOGIC;
        -- 00: Idle, 01: Right, 10: Left
        clear_dir   : in STD_LOGIC;
        mode        : out unsigned (1 downto 0); 
        Direction   : out unsigned (1 downto 0)
        );
        end Encoder;
        
        architecture Behavioral of Encoder is
            type stateType is (idle, R1, R2, R3, L1, L2, L3, right, left);
            signal curState, nextState: stateType;
            signal latchedDir : unsigned(1 downto 0) := "00";   -- direction (turn)
            signal turn_mode : unsigned(1 downto 0) := "01";    -- speed (press)
            signal button_last  : std_logic := '0';
            signal clear_direction : std_logic;

begin
    mode <= turn_mode;
    Direction <= latchedDir; 
    clear_direction <= clear_dir;

    clock: process (clk)
    begin
        
        if rising_edge(clk) then
            button_last <= button;
            curState <= nextState;

            if (clear_direction = '1') then 
                latchedDir <= (others => '0');
                curState <= idle;
            elsif (curState = right) then
                latchedDir <= "01"; --  'Right'
            elsif (curState = left) then
                latchedDir <= "10"; --  'Left'
            end if;
            if (button = '1' and button_last = '0') then
                if(turn_mode < 3) then
                    turn_mode <= turn_mode + 1;
                else
                    turn_mode <= "01";
                end if;
            end if;
        end if;
    end process;

    next_state: process (curState, signal_A, signal_B)
    begin
        case curState is
            when idle => if signal_B = '0' then nextState <= R1; elsif signal_A = '0' then nextState <= L1; else nextState <= idle; end if;
            when R1 => if signal_B='1' then nextState <= idle; elsif signal_A = '0' then nextState <= R2; else nextState <= R1; end if;
            when R2 => if signal_A ='1' then nextState <= R1; elsif signal_B = '1' then nextState <= R3; else nextState <= R2; end if;
            when R3 => if signal_B ='0' then nextState <= R2; elsif signal_A = '1' then nextState <= right; else nextState <= R3; end if;
            when right => nextState <= idle;
            when L1 => if signal_A ='1' then nextState <= idle; elsif signal_B = '0' then nextState <= L2; else nextState <= L1; end if;
            when L2 => if signal_B ='1' then nextState <= L1; elsif signal_A = '1' then nextState <= L3; else nextState <= L2; end if;
            when L3 => if signal_A ='0' then nextState <= L2; elsif signal_B = '1' then nextState <= left; else nextState <= L3; end if;
            when left => nextState <= idle;
            when others => nextState <= idle;
        end case;
    end process;
end Behavioral;