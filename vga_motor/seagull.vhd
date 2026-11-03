library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.seagull_pkg.ALL;

entity seagull_sprite is
    port (
        clk, v_sync : in std_logic;
        pixel_x, pixel_y : in unsigned(9 downto 0);
        pixel_en        : in std_logic;
        scale            : in integer range 1 to 4;
        base_x, base_y : in integer;
        sprite_pixel : out std_logic_vector(11 downto 0);
        sprite_on    : out std_logic;
        animStatus : in unsigned(7 downto 0)
    );
end seagull_sprite;

architecture Behavioral of seagull_sprite is

    signal x_offset   : signed(10 downto 0) := (others => '0');
    signal v_sync_d   : std_logic := '0';

    signal frame      : unsigned(0 downto 0) := "0";
    signal anim_cnt   : unsigned(3 downto 0) := (others => '0');

    -- PIPELINE
    -- stage 1
    signal curr_x_s1, curr_y_s1 : integer;
    signal rel_x_s1, rel_y_s1 : signed(11 downto 0);

    -- stage 2
    signal sx_s2, sy_s2 : unsigned(4 downto 0);
    signal inside_s2    : std_logic;
    signal addr_s2      : unsigned(10 downto 0);

    -- stage 3
    signal pixel_s3 : std_logic_vector(11 downto 0);
    signal on_s3    : std_logic;

begin

-- Animation
process(clk)
begin
    if rising_edge(clk) then
        v_sync_d <= v_sync;

        if (v_sync = '0' and v_sync_d = '1') then
            anim_cnt <= anim_cnt + 1;

            if anim_cnt = 4 then
                anim_cnt <= (others => '0');
                frame <= frame + 1; -- växla mellan 0/1
            end if;
        end if;
    end if;
end process;

-- STAGE 1: relativa koordinater
process(clk)
begin
    if rising_edge(clk) then
        if pixel_en = '1' then

            curr_x_s1 <= base_x + BIRD_X_LUT(to_integer(animStatus));
            curr_y_s1 <= base_y;

            rel_x_s1 <= signed(resize(pixel_x, 12)) - to_signed(curr_x_s1, 12);
            rel_y_s1 <= signed(resize(pixel_y, 12)) - to_signed(curr_y_s1, 12);

        end if;
    end if;
end process;


-- STAGE 2: scaling + bounds + adress
process(clk)
    variable sx, sy : signed(11 downto 0);
begin
    if rising_edge(clk) then

        case scale is
            when 1 =>
                sx := rel_x_s1;
                sy := rel_y_s1;
            when 2 =>
                sx := shift_right(rel_x_s1, 1);
                sy := shift_right(rel_y_s1, 1);
            when 4 =>
                sx := shift_right(rel_x_s1, 2);
                sy := shift_right(rel_y_s1, 2);
            when others =>
                sx := shift_right(rel_x_s1, 1);
                sy := shift_right(rel_y_s1, 1);
        end case;

        -- bounds check
        if (sx >= 0 and sx < 32 and sy >= 0 and sy < 32) then
            inside_s2 <= '1';

            addr_s2 <= frame & unsigned(sy(4 downto 0)) & unsigned(sx(4 downto 0));

        else
            inside_s2 <= '0';
            addr_s2 <= (others => '0');
        end if;

    end if;
end process;

-- =========================================
-- STAGE 3: ROM
-- =========================================
process(clk)
begin
    if rising_edge(clk) then
        if inside_s2 = '1' then
            if SPRITE_MEM(to_integer(addr_s2)) /= x"F0F" then
                on_s3    <= '1';
                pixel_s3 <= SPRITE_MEM(to_integer(addr_s2));
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

sprite_on    <= on_s3;
sprite_pixel <= pixel_s3;
end Behavioral;