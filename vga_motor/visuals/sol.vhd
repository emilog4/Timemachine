library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package sprite_pkg is

    type sprite_array is array (0 to 575) of std_logic_vector(11 downto 0);

    constant CELESTIAL_MEM : sprite_array := (

        -- Frame 0
        x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",
        x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",
        x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",
        x"FFF",x"FFF",x"FFF",x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",x"FFF",x"FFF",x"FFF",
        x"FFF",x"FFF",x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",x"FFF",x"FFF",
        x"FFF",x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",x"FFF",
        x"FFF",x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",x"FFF",
        x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",
        x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",
        x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",
        x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",
        x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",
        x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",
        x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",
        x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",
        x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",
        x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",
        x"FFF",x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",x"FFF",
        x"FFF",x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",x"FFF",
        x"FFF",x"FFF",x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",x"FFF",x"FFF",
        x"FFF",x"FFF",x"FFF",x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",x"FFF",x"FFF",x"FFF",
        x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",
        x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",
        x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FF3",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF",x"FFF"

    );

end package;
