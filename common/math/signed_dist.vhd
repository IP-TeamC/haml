library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math.all;

entity signed_dist is
    generic (
        n : natural;
        fp_size : natural;
        fp_frac : natural := 0
    );
    port (
        clk : in std_logic;
        start : in std_logic;

        a : in t_signed_vec(0 to n-1)(fp_size-1 downto 0);
        b : in t_signed_vec(0 to n-1)(fp_size-1 downto 0);

        dist_sq : out signed(fp_size-1 downto 0);
        done : out std_logic
    );
end entity;

-- Pipeline: Difference Squared -> Addition
architecture rtl of signed_dist is

    signal started : std_logic;
    signal diff_sq : t_signed_vec(0 to n-1)(fp_size-1 downto 0);
    signal diff_sq_next : t_signed_vec(0 to n-1)(fp_size-1 downto 0);

    signal dist_sq_next : signed(fp_size-1 downto 0);

begin

    process (clk)
    begin
        if rising_edge(clk) then
            started <= start;
            if start = '1' then
                diff_sq <= diff_sq_next;
            end if;
            dist_sq <= dist_sq_next;
            done <= started;
        end if;
    end process;

    gen_diff: for i in a'range generate
    begin
        diff_sq_next(i) <= fp_mul(
                a(i) - b(i),
                a(i) - b(i),
                fp_frac
            );
    end generate;

    -- TODO: Tree Adder
    process(diff_sq)
        variable dist_sq_acc : signed(fp_size-1 downto 0);
    begin
        dist_sq_acc := diff_sq(0);
        for i in 1 to diff_sq'length-1 loop
            dist_sq_acc := dist_sq_acc + diff_sq(i);
        end loop;
        dist_sq_next <= dist_sq_acc;
    end process;

end architecture;