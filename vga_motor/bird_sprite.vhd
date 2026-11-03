library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.bird_pkg.ALL;

entity bird_sprite is
    port (
        clk, v_sync : in std_logic;
        pixel_x, pixel_y : in unsigned(9 downto 0);
        pixel_en   : in std_logic;
        scale      : in integer range 1 to 4;
        base_x, base_y : in integer;
        sprite_pixel : out std_logic_vector(11 downto 0);
        sprite_on    : out std_logic;
        animStatus   : in unsigned(7 downto 0)
    );
end bird_sprite;

architecture Behavioral of bird_sprite is

    -- animation
    signal bird_frame : unsigned(2 downto 0) := "000";
    signal anim_cnt   : unsigned(3 downto 0) := "0000";
    signal v_sync_reg : std_logic;

    -- ===== PIPELINE =====
    -- stage 1
    signal curr_x_s1, curr_y_s1 : integer;
    signal rel_x_s1, rel_y_s1   : integer;

    -- stage 2
    signal scaled_x_s2, scaled_y_s2 : integer;
    signal inside_s2                : std_logic;
    signal addr_s2                  : integer;

    -- stage 3
    signal pixel_s3 : std_logic_vector(11 downto 0);
    signal on_s3    : std_logic;

begin

-- =========================================
-- Animation (oförändrad)
-- =========================================
process(clk)
begin
    if rising_edge(clk) then
        if v_sync = '0' and v_sync_reg = '1' then                   
            anim_cnt <= anim_cnt + 1;
            if anim_cnt = 4 then
                anim_cnt <= (others => '0');
                bird_frame <= bird_frame + 1;
            end if;
        end if;
        v_sync_reg <= v_sync;
    end if;
end process;

-- =========================================
-- STAGE 1: position + relativ position
-- =========================================
process(clk)
begin
    if rising_edge(clk) then
        if pixel_en = '1' then
            curr_x_s1 <= base_x + BIRD_X_LUT(to_integer(animStatus));
            curr_y_s1 <= base_y;

            rel_x_s1 <= to_integer(pixel_x) - curr_x_s1;
            rel_y_s1 <= to_integer(pixel_y) - curr_y_s1;
        end if;
    end if;
end process;

-- =========================================
-- STAGE 2: scaling + bounds + address
-- =========================================
process(clk)
    variable sx, sy : integer;
begin
    if rising_edge(clk) then
        -- scaling (ingen division!)
        case scale is
            when 1 =>
                sx := rel_x_s1;
                sy := rel_y_s1;

            when 2 =>
                sx := to_integer(shift_right(to_signed(rel_x_s1, 12), 1));
                sy := to_integer(shift_right(to_signed(rel_y_s1, 12), 1));

            when 4 =>
                sx := to_integer(shift_right(to_signed(rel_x_s1, 12), 2));
                sy := to_integer(shift_right(to_signed(rel_y_s1, 12), 2));

            when others =>
                -- fallback (undvik 3)
                sx := to_integer(shift_right(to_signed(rel_x_s1, 12), 1));
                sy := to_integer(shift_right(to_signed(rel_y_s1, 12), 1));
        end case;

        scaled_x_s2 <= sx;
        scaled_y_s2 <= sy;

        if (sx >= 0 and sx < 16) and (sy >= 0 and sy < 16) then
            inside_s2 <= '1';
            addr_s2 <= to_integer(
                bird_frame &
                to_unsigned(sy, 4) &
                to_unsigned(sx, 4)
            );
        else
            inside_s2 <= '0';
            addr_s2 <= 0;
        end if;
    end if;
end process;

-- =========================================
-- STAGE 3: ROM + output
-- =========================================
process(clk)
begin
    if rising_edge(clk) then
        if inside_s2 = '1' then
            if SPRITE_MEM(addr_s2) /= x"F0F" then
                on_s3    <= '1';
                pixel_s3 <= SPRITE_MEM(addr_s2);
            else
                on_s3 <= '0';
                pixel_s3 <= (others => '0');
            end if;
        else
            on_s3 <= '0';
            pixel_s3 <= (others => '0');
        end if;
    end if;
end process;

-- outputs (registrerade)
sprite_on    <= on_s3;
sprite_pixel <= pixel_s3;

end Behavioral;