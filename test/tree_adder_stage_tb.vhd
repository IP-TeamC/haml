library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.math.all;
use work.tree_adder_stage;

entity tree_adder_stage_tb is

    -- Constants
    signal clk_period : time := 1 ns;
    signal n : natural := 4;
    signal size : natural := 8;

    -- Inputs
    signal clk : std_logic := '1';
    signal values : std_logic_vector((n*size)-1 downto 0);

    -- Outputs
    signal sum : std_logic_vector(natural(ceil(real(n)/2.0))*size-1 downto 0);

end entity;

architecture rtl of tree_adder_stage_tb is

begin

    uut: entity tree_adder_stage
        generic map (
            n => n,
            size => size
        )
        port map (
            clk => clk,
            values => values,
            sum => sum
        );

    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    process
    begin
        
        wait for clk_period;
        values <= "00001011" & "00001111" & "00001001" & "00010110";
        wait for clk_period;
        wait for clk_period;
        assert sum = "00011010" & "00011111";

        wait;
    end process;

end architecture;