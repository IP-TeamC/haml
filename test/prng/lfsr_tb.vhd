library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.lfsr;

entity lfsr_tb is
end entity;

architecture rtl of lfsr_tb is

    -- Constants
    constant clk_period : time := 10 ns; -- erhöhen für post-translate sim
    constant degree : natural := 8;

    -- Inputs
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal generator : std_logic_vector(degree downto 0);
    signal seed : std_logic_vector(degree-1 downto 0);

    -- Outputs
    signal rand : std_logic_vector(degree-1 downto 0);

begin

    uut: entity lfsr
        -- generic auskommentieren für post-translate sim
        generic map (
            degree => degree
        )
        port map (
            clk   => clk,
            rst => rst,
            generator => generator,
            seed => seed,
            rand => rand
        );

    clk_process: process
        begin
            clk <= not(clk);
            wait for clk_period/2;
        end process;

    process
    begin
        generator <= "100011101";
        seed <= "11001101";
        wait for clk_period/2;

        rst <= '1';
        wait for clk_period;

        rst <= '0';
        wait for clk_period;
        assert rand = "10000111";

        wait for clk_period;
        assert rand = "00010011";

        wait for clk_period;
        assert rand = "00100110";

        wait for clk_period;
        assert rand = "01001100";

        wait for clk_period;
        assert rand = "10011000";

        wait for clk_period;
        assert rand = "00101101";

        wait;

    end process;

end architecture;
