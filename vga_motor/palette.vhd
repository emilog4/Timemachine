library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ColorPalette is
    Port ( 
        index : in  unsigned(3 downto 0); -- 4 bitar ger 16 färger
        red   : out std_logic_vector(3 downto 0);
        green : out std_logic_vector(3 downto 0);
        blue  : out std_logic_vector(3 downto 0)
    );
end ColorPalette;

architecture Behavioral of ColorPalette is
    -- Vi definierar en typ för vår palett (16 rader x 12 bitar färg)
    type palette_t is array (0 to 15) of std_logic_vector(11 downto 0);
    
    -- Här definierar du dina färger
    constant my_palette : palette_t := (
        0  => x"000", -- Svart
        1  => x"F00", -- Röd
        2  => x"0F0", -- Grön
        3  => x"00F", -- Blå
        4  => x"FF0", -- Gul (Pacman!)
        5  => x"F0F", -- Lila
        6  => x"0FF", -- Cyan
        7  => x"FFF", -- Vit
        8  => x"888", -- Grå
        others => x"000" -- Resten blir svarta
    );

    signal full_color : std_logic_vector(11 downto 0);

begin
    -- Slå upp färgen i tabellen baserat på index
    full_color <= my_palette(to_integer(index));

    -- Dela upp 12-bitarsvärdet till de tre färgkanalerna
    red   <= full_color(11 downto 8);
    green <= full_color(7 downto 4);
    blue  <= full_color(3 downto 0);

end Behavioral;