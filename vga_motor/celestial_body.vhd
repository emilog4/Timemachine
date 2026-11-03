library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.celestial_pkg.all;

entity celestial_body is
    port (
        clk, vsync : in std_logic;
        is_day : in std_logic;
        pixel_x, pixel_y : in unsigned(9 downto 0);
        pixel_en : in std_logic;
        scale : in integer range 1 to 4 := 4;
        animStatus : in unsigned(7 downto 0);
        sprite_pixel : out std_logic_vector(11 downto 0);
        sprite_on : out std_logic
    );
end celestial_body;

architecture Behavioral of celestial_body is

    -- Stage 0: Positioner
    signal obj_x, obj_y : integer := 0;

    -- Stage 1: Relativa koordinater
    signal rel_x_s1, rel_y_s1 : integer := 0;
    signal py_s1 : integer := 0;
    signal valid_s1 : std_logic := '0';
    signal day_s1 : std_logic := '0';
    signal scale_s1 : integer := 4;

    -- Stage 2: Skalning (Shifter istället för dividerare)
    signal scaled_x_s2, scaled_y_s2 : integer := 0;
    signal py_s2 : integer := 0;
    signal valid_s2 : std_logic := '0';
    signal day_s2 : std_logic := '0';

    -- Stage 3: Minnesadress & Indexering
    signal mem_index_s3 : integer := 0;
    signal py_s3 : integer := 0;
    signal valid_s3 : std_logic := '0';

    constant SPRITE_SIZE : integer := 24;
    constant FRAME_SIZE : integer := 576; -- 24 * 24
    constant HORIZON_Y : integer := 144;

begin

    --------------------------------------------------------------------
    -- Stage 0: Position från LUT
    --------------------------------------------------------------------
    process (clk)
    begin
        if rising_edge(clk) then
            obj_x <= SUN_X_LUT(to_integer(animStatus));
            obj_y <= SUN_Y_LUT(to_integer(animStatus));
        end if;
    end process;

    --------------------------------------------------------------------
    -- Rendering Pipeline
    --------------------------------------------------------------------
    process (clk)
        variable v_mem_index : integer;
    begin
        if rising_edge(clk) then

            -- STAGE 1: Beräkna avstånd (Subtraktion)
            -- Uppdatera BARA när pixel_en är 1. Värdena hålls stabila annars.
            if pixel_en = '1' then
                rel_x_s1 <= to_integer(pixel_x) - obj_x;
                rel_y_s1 <= to_integer(pixel_y) - obj_y;
                py_s1 <= to_integer(pixel_y);
                day_s1 <= is_day;
                scale_s1 <= scale;
            end if;

            -- STAGE 2: Skalning
            case scale_s1 is
                when 2 =>
                    scaled_x_s2 <= to_integer(shift_right(to_signed(rel_x_s1, 16), 1));
                    scaled_y_s2 <= to_integer(shift_right(to_signed(rel_y_s1, 16), 1));
                when 4 =>
                    scaled_x_s2 <= to_integer(shift_right(to_signed(rel_x_s1, 16), 2));
                    scaled_y_s2 <= to_integer(shift_right(to_signed(rel_y_s1, 16), 2));
                when others =>
                    scaled_x_s2 <= rel_x_s1;
                    scaled_y_s2 <= rel_y_s1;
            end case;
            py_s2 <= py_s1;
            day_s2 <= day_s1;

            -- STAGE 3: Adressberäkning och Bounding Box
            if scaled_x_s2 >= 0 and scaled_x_s2 < SPRITE_SIZE and
                scaled_y_s2 >= 0 and scaled_y_s2 < SPRITE_SIZE then
                if day_s2 = '1' then
                    v_mem_index := FRAME_SIZE + (scaled_y_s2 * SPRITE_SIZE) + scaled_x_s2;
                else
                    v_mem_index := (scaled_y_s2 * SPRITE_SIZE) + scaled_x_s2;
                end if;
                mem_index_s3 <= v_mem_index;
                valid_s3 <= '1'; -- Här betyder valid_s3 "inuti bounding box"
            else
                valid_s3 <= '0';
            end if;
            py_s3 <= py_s2;

            -- STAGE 4: Output (Minnesuppslag)
            if valid_s3 = '1' then
                -- Läs från minnet och kolla transparens + horisont
                if CELESTIAL_MEM(mem_index_s3) /= x"F0F" and py_s3 < HORIZON_Y then
                    sprite_on <= '1';
                    sprite_pixel <= CELESTIAL_MEM(mem_index_s3);
                else
                    sprite_on <= '0';
                    sprite_pixel <= (others => '0');
                end if;
            else
                sprite_on <= '0';
                sprite_pixel <= (others => '0');
            end if;

        end if;
    end process;

end Behavioral;