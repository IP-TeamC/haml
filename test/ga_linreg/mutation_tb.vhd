library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.util.all;
use work.math.all;

entity mutation_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant mask_factor : natural := 1;
    constant var_num : natural := 2;
    constant fp_size : natural := 18;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic;
    signal start : std_logic;
    signal chr : std_logic_vector(fp_size*(var_num+1)-1 downto 0);

    -- Outputs
    signal chr_mut : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal done : std_logic;

end entity;

architecture rtl of mutation_tb is

begin

    uut: entity work.mutation
        generic map (
            mask_factor => mask_factor,
            var_num => var_num,
            fp_size => fp_size
        )
        port map (
            clk => clk,
            rst => rst,
            start => start,
            chr => chr,
            done => done,
            chr_mut => chr_mut
        );

    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    process
    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        start <= '0';
        assert done = '0';
        wait for clk_period*mask_factor*2;
        assert done = '0';

        -- abhängig vom Seed: keine Mutation ist auch möglich, aber eher selten
        for i in 0 to 100 loop
            start <= '1';
            chr <= "00" & "100000" & "0000000000"
                & "11" & "111000" & "0000000000"
                & "00" & "010000" & "0000000000";
            wait for clk_period;
            start <= '0';
            assert done = '1';
            assert chr_mut /= chr;
            wait for clk_period;
            assert done = '0';
        end loop;

        report "Done";
        wait;
    end process;

end architecture;