library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.adder_tree;
use work.math.all;

entity signed_dist is
    generic (
        n : natural;
        fp_size : natural;
        fp_frac : natural := 0;
        data_size : natural := 0
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        a : in std_logic_vector((n*fp_size)-1 downto 0);
        b : in std_logic_vector((n*fp_size)-1 downto 0);
        di : in std_logic_vector(data_size-1 downto 0);

        dist_sq : out signed(fp_size-1 downto 0);
        done : out std_logic;
        do : out std_logic_vector(data_size-1 downto 0)
    );
end entity;

-- Pipeline: quadr. Differenz -> Addition (Adder Tree mit mehreren Stages)
architecture rtl of signed_dist is

    signal started : std_logic;
    signal diff_sq : std_logic_vector((n*fp_size)-1 downto 0);
    signal diff_sq_next : std_logic_vector((n*fp_size)-1 downto 0);
    signal di_delayed : std_logic_vector(data_size-1 downto 0);

begin

    adder: entity adder_tree
        generic map (
            n => n,
            size => fp_size,
            data_size => data_size
        )
        port map (
            clk => clk,
            rst => rst,
            start => started,
            values => diff_sq,
            sum => dist_sq,
            done => done,
            di => di_delayed,
            do => do
        );

    process (clk)
    begin
        if rising_edge(clk) then
            if start = '1' then
                diff_sq <= diff_sq_next;
                di_delayed <= di;
            end if;
            
            if rst = '1' then
                started <= '0';
            else
                -- startet Adder-Tree nach Differenzbildung
                started <= start;
            end if;
        end if;
    end process;

    gen_diff: for i in 0 to n-1 generate
    begin
        diff_sq_next(flat_upper(fp_size, i) downto flat_lower(fp_size, i)) <= std_logic_vector(fp_mul(
                flat_signed(a, fp_size, i) - flat_signed(b, fp_size, i),
                flat_signed(a, fp_size, i) - flat_signed(b, fp_size, i),
                fp_frac
            ));
    end generate;

end architecture;