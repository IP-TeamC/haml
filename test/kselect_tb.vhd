library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.util.all;
use work.math.all;
use work.kselect;

entity kselect_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant k : natural := 3;
    constant class_size : natural := 2;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal start : std_logic := '0';
    signal top_class : std_logic_vector(k*class_size-1 downto 0);

    -- Outputs
    signal class : std_logic_vector(class_size-1 downto 0);
    signal done : std_logic;
end entity;

architecture rtl of kselect_tb is

begin

    uut: entity kselect
        generic map (
            k => k,
            class_size => class_size
        )
        port map (
            clk => clk,
            rst => rst,
            start => start,
            top_class => top_class,
            class => class,
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
        
        start <= '1';
        top_class <= "011101";
        wait for clk_period;
        assert class = "01";

        wait;
    end process;

end architecture;