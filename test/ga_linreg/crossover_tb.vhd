library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.util.all;
use work.math.all;

entity crossover_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant var_num : natural := 5;
    constant fp_size : natural := 4;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic;
    signal start : std_logic;
    signal chr_parent1 : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal chr_parent2 : std_logic_vector(fp_size*(var_num+1)-1 downto 0);

    -- Outputs
    signal chr_child : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal done : std_logic;

end entity;

architecture rtl of crossover_tb is

begin

    uut: entity work.crossover
        generic map(
            var_num => var_num,
            fp_size => fp_size
        )
        port map(
            clk => clk,
            rst => rst,
            start => start,
            chr_parent1 => chr_parent1,
            chr_parent2 => chr_parent2,
            done => done,
            chr_child => chr_child
        );

    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    process
        variable tmp : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        start <= '0';
        assert done = '0';
        wait for clk_period;
        assert done = '0';

        chr_parent1 <= "1000" & "0001" & "1010" & "0101" & "0000" & "0110";
        chr_parent2 <= "1100" & "1101" & "1110" & "1111" & "1001" & "1011";
        for i in 0 to 100 loop
            start <= '1';
            wait for clk_period;
            start <= '0';
            assert done = '1';
            for j in 0 to var_num loop
                assert flat_vec(chr_child, fp_size, j) = flat_vec(chr_parent1, fp_size, j) xor flat_vec(chr_child, fp_size, j) = flat_vec(chr_parent2, fp_size, j);    
            end loop;
            -- abhängig vom Seed: identisches Kind zu Parent auch möglich
            assert chr_child /= chr_parent1 and chr_child /= chr_parent2;
            
            tmp := chr_child;
            wait for clk_period;
            assert done = '0';
            assert chr_child = tmp;
            wait for clk_period;
            assert done = '0';
            assert chr_child = tmp;
        end loop;

        report "Done";
        wait;
    end process;

end architecture;