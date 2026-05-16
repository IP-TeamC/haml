library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- TODO Testen
entity signed_mul36 is
    port (
        clk   : in std_logic;
        rst : in std_logic;
        start : in std_logic;
        a, b : in signed(35 downto 0);
        res : out signed(71 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of signed_mul36 is

    signal a_low, b_low : signed(17 downto 0);
    signal a_high, b_high : signed(17 downto 0);
    signal split_done : std_logic;

    signal low_low : signed(35 downto 0);
    signal low_high : signed(35 downto 0);
    signal high_low : signed(35 downto 0);
    signal high_high : signed(35 downto 0);
    signal mul_done : std_logic;

    signal outer : signed(71 downto 0);
    signal inner : signed(71 downto 0);
    signal add1_done : std_logic;

begin

    -- Stage 0
    process (clk)
    begin
        if rising_edge(clk) then
            a_low <= a(17 downto 0);
            a_high <= a(35 downto 18);
            b_low <= b(17 downto 0);
            b_high <= b(35 downto 18);
        end if;
    end process;

    -- Stage 1
    process (clk)
    begin
        if rising_edge(clk) then
            low_low <= a_low * b_low;
            low_high <= a_low * b_high;
            high_low <= a_high * b_low;
            high_high <= a_high * b_high;
        end if;
    end process;

    -- Stage 2
    process (clk)
    begin
        if rising_edge(clk) then
            inner <= shift_left(resize(low_high + high_low, 72), 18);
            outer <= shift_left(resize(high_high, 72), 36) + signed(resize(low_low, 72));
        end if;
    end process;

    -- Stage 3
    process (clk)
    begin
        if rising_edge(clk) then
            res <= outer + inner;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                split_done <= '0';
                mul_done <= '0';
                add1_done <= '0';
                done <= '0';
            else
                split_done <= start;
                mul_done <= split_done;
                add1_done <= mul_done;
                done <= add1_done;
            end if;
        end if;
    end process;

end architecture;