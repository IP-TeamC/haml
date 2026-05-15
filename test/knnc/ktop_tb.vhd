library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.util.all;
use work.math.all;
use work.ktop;

entity ktop_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant k : natural := 3;
    constant dist_size : natural := 8;
    constant data_size : natural := 2;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal start : std_logic := '0';
    signal dist : std_logic_vector(dist_size-1 downto 0);
    signal data : std_logic_vector(data_size-1 downto 0);

    -- Outputs
    signal top_dist : std_logic_vector(k*dist_size-1 downto 0);
    signal top_data : std_logic_vector(k*data_size-1 downto 0);
    signal done : std_logic;
end entity;

architecture rtl of ktop_tb is

begin

    uut: entity ktop
        generic map (
            k => k,
            dist_size => dist_size,
            data_size => data_size
        )
        port map (
            clk => clk,
            rst => rst,
            start => start,
            dist => dist,
            data => data,
            top_dist => top_dist,
            top_data => top_data,
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
        dist <= "00101111";
        data <= "01";
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        start <= '0';
        assert done = '0';
        wait for clk_period;
        assert done = '1';
        assert top_dist(dist_size-1 downto 0) = "00101111";
        assert top_data(data_size-1 downto 0) = "01";
        wait for clk_period;
        assert done = '1';
        assert top_dist(2*dist_size-1 downto 0) = "00101111" & "00101111";
        assert top_data(2*data_size-1 downto 0) = "0101";
        dist <= "00001010";
        data <= "10";
        start <= '1';
        wait for clk_period;
        start <= '0';
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '1';
        assert top_dist = "00101111" & "00101111" & "00001010";
        assert top_data = "01" & "01" & "10";
        dist <= "01001000";
        data <= "11";
        start <= '1';
        wait for clk_period;
        start <= '0';
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '1';
        assert top_dist = "00101111" & "00101111" & "00001010";
        assert top_data = "01" & "01" & "10";
        dist <= "00000000";
        data <= "00";
        start <= '1';
        wait for clk_period;
        start <= '0';
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '1';
        assert top_dist = "00101111" & "00001010" & "00000000";
        assert top_data = "01" & "10" & "00";
        start <= '0';
        wait for clk_period;
        assert top_dist = "00101111" & "00001010" & "00000000";
        assert top_data = "01" & "10" & "00";
        wait for clk_period;
        assert top_dist = "00101111" & "00001010" & "00000000";
        assert top_data = "01" & "10" & "00";
        start <= '1';
        wait for clk_period;
        start <= '0';
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '1';
        assert top_dist = "00001010" & "00000000" & "00000000";
        assert top_data = "10" & "00" & "00";

        wait;
    end process;

end architecture;