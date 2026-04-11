library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math.all;
use work.signed_dist;

entity signed_dist_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant n : natural := 3;
    constant fp_size : natural := 13;
    constant fp_frac : natural := 3;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal start : std_logic := '0';

    signal a : std_logic_vector((n*fp_size)-1 downto 0);
    signal b : std_logic_vector((n*fp_size)-1 downto 0);

    -- Outputs
    signal dist_sq : signed(fp_size-1 downto 0);
    signal done : std_logic;

end entity;

architecture rtl of signed_dist_tb is

begin

    uut: entity signed_dist
        generic map (
            n => n,
            fp_size => fp_size,
            fp_frac => fp_frac
        )
        port map (
            clk => clk,
            rst => rst,
            start => start,
            a => a,
            b => b,
            dist_sq => dist_sq,
            done => done
        );

    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    process
    begin
        
        start <= '0';
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        assert done = '0';

        start <= '1';
        a <= std_logic_vector(to_unsigned(123, fp_size-fp_frac) & to_unsigned(4, fp_frac))
            & std_logic_vector(to_unsigned(456, fp_size-fp_frac) & to_unsigned(2, fp_frac))
            & std_logic_vector(to_unsigned(789, fp_size-fp_frac) & to_unsigned(3, fp_frac));
        b <= std_logic_vector(to_unsigned(124, fp_size-fp_frac) & to_unsigned(4, fp_frac))
            & std_logic_vector(to_unsigned(456, fp_size-fp_frac) & to_unsigned(2, fp_frac))
            & std_logic_vector(to_unsigned(789, fp_size-fp_frac) & to_unsigned(3, fp_frac));
        wait for clk_period;
        start <= '0';
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '1';
        assert dist_sq = to_signed(8, fp_size);
        wait for clk_period;
        assert done = '0';
        assert dist_sq = to_signed(8, fp_size);
        wait for clk_period;
        assert done = '0';
        assert dist_sq = to_signed(8, fp_size);

        a <= std_logic_vector(to_unsigned(123, fp_size-fp_frac) & to_unsigned(4, fp_frac))
            & std_logic_vector(to_unsigned(456, fp_size-fp_frac) & to_unsigned(2, fp_frac))
            & std_logic_vector(to_unsigned(789, fp_size-fp_frac) & to_unsigned(3, fp_frac));
        b <= std_logic_vector(to_unsigned(125, fp_size-fp_frac) & to_unsigned(4, fp_frac))
            & std_logic_vector(to_unsigned(459, fp_size-fp_frac) & to_unsigned(2, fp_frac))
            & std_logic_vector(to_unsigned(793, fp_size-fp_frac) & to_unsigned(3, fp_frac));
        wait for clk_period;
        assert done = '0';
        assert dist_sq = to_signed(8, fp_size);
        wait for clk_period;
        start <= '1';
        assert done = '0';
        wait for clk_period;
        start <= '0';
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '1';
        assert dist_sq = to_signed(232, fp_size);
        wait for clk_period;
        assert done = '0';

        wait;
    end process;

end architecture;