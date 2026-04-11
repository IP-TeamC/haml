library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.math.all;
use work.adder_tree_stage;

entity adder_tree_stage_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant n4 : natural := 4;
    constant n5 : natural := 5;
    constant n6 : natural := 6;
    constant size : natural := 8;

    -- Inputs
    signal clk : std_logic := '1';
    signal start4 : std_logic := '0';
    signal start5 : std_logic := '0';
    signal start6 : std_logic := '0';
    signal values4 : std_logic_vector((n4*size)-1 downto 0);
    signal values5 : std_logic_vector((n5*size)-1 downto 0);
    signal values6 : std_logic_vector((n6*size)-1 downto 0);

    -- Outputs
    signal sum4 : std_logic_vector(natural(ceil(real(n4)/2.0))*size-1 downto 0);
    signal sum5 : std_logic_vector(natural(ceil(real(n5)/2.0))*size-1 downto 0);
    signal sum6 : std_logic_vector(natural(ceil(real(n6)/2.0))*size-1 downto 0);
    signal done4 : std_logic;
    signal done5 : std_logic;
    signal done6 : std_logic;

end entity;

architecture rtl of adder_tree_stage_tb is

begin

    uut4: entity adder_tree_stage
        generic map (
            n => n4,
            size => size
        )
        port map (
            clk => clk,
            start => start4,
            values => values4,
            sum => sum4,
            done => done4
        );
    uut5: entity adder_tree_stage
        generic map (
            n => n5,
            size => size
        )
        port map (
            clk => clk,
            start => start5,
            values => values5,
            sum => sum5,
            done => done5
        );
    uut6: entity adder_tree_stage
        generic map (
            n => n6,
            size => size
        )
        port map (
            clk => clk,
            start => start6,
            values => values6,
            sum => sum6,
            done => done6
        );

    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    process
    begin
        
        wait for clk_period;

        start4 <= '1';
        values4 <= "00001011" & "00001111" & "00001001" & "00010110";
        wait for clk_period;
        start4 <= '0';
        assert done4 = '1';
        assert sum4 = "00011010" & "00011111";
        wait for clk_period;
        assert done4 = '0';
        assert sum4 = "00011010" & "00011111";

        -- Achtung v links v  -   v addiert (Mitte) v   -  v addiert (rechts) v
        start5 <= '1';
        values5 <= "00001011" & "00001111" & "00001001" & "00010110" & "00101101";
        wait for clk_period;
        assert done5 = '1';
        assert sum5 = "00001011" & "00011000" & "01000011";
    
        start6 <= '1';
        values6 <= "00001011" & "00001111" & "00001001" & "00010110" & "00010110" & "00010111";
        wait for clk_period;
        assert done6 = '1';
        assert sum6 = "00011010" & "00011111" & "00101101";

        wait;
    end process;

end architecture;