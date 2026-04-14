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

-- Pipeline: Differenz -> Quadrat -> Addition (Adder Tree mit mehreren Stages)
architecture rtl of signed_dist is

    signal diff : std_logic_vector((n*fp_size)-1 downto 0);
    signal diff_next : std_logic_vector((n*fp_size)-1 downto 0);
    signal done_diff : std_logic;
    signal di_delayed_diff : std_logic_vector(data_size-1 downto 0);

    signal diff_sq : std_logic_vector((n*fp_size)-1 downto 0);
    signal diff_sq_next : std_logic_vector((n*fp_size)-1 downto 0);
    signal done_diff_sq : std_logic;
    signal di_delayed_diff_sq : std_logic_vector(data_size-1 downto 0);

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
            start => done_diff_sq,
            values => diff_sq,
            sum => dist_sq,
            done => done,
            di => di_delayed_diff_sq,
            do => do
        );

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                done_diff <= '0';
                done_diff_sq <= '0';
            else
                if start = '1' then
                    diff <= diff_next;
                    di_delayed_diff <= di;
                end if;

                if done_diff = '1' then
                    diff_sq <= diff_sq_next;
                    di_delayed_diff_sq <= di_delayed_diff;
                end if;

                done_diff <= start;
                done_diff_sq <= done_diff;
            end if;
        end if;
    end process;

    gen_diff: for i in 0 to n-1 generate
    begin
        diff_next(flat_upper(fp_size, i) downto flat_lower(fp_size, i)) <= std_logic_vector(flat_signed(a, fp_size, i) - flat_signed(b, fp_size, i));
    end generate;

    gen_diff_sq: for i in 0 to n-1 generate
    begin
        diff_sq_next(flat_upper(fp_size, i) downto flat_lower(fp_size, i)) <= std_logic_vector(fp_mul(
                flat_signed(diff, fp_size, i),
                flat_signed(diff, fp_size, i),
                fp_frac
            ));
    end generate;

end architecture;