library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math.all;
use work.adder_tree;

entity adder_tree_tb is

    -- Constants
    constant clk_period : time := 10 ns;
    constant n4 : natural := 4;
    constant n5 : natural := 5;
    constant n6 : natural := 6;
    constant n8 : natural := 8;
    constant size : natural := 8;

    -- Inputs
    signal clk : std_logic := '1';
    signal start4 : std_logic := '0';
    signal start5 : std_logic := '0';
    signal start6 : std_logic := '0';
    signal start8 : std_logic := '0';
    signal values4 : std_logic_vector((n4*size)-1 downto 0);
    signal values5 : std_logic_vector((n5*size)-1 downto 0);
    signal values6 : std_logic_vector((n6*size)-1 downto 0);
    signal values8 : std_logic_vector((n8*size)-1 downto 0);

    -- Outputs
    signal sum4 : signed(size-1 downto 0);
    signal sum5 : signed(size-1 downto 0);
    signal sum6 : signed(size-1 downto 0);
    signal sum8 : signed(size-1 downto 0);
    signal done4 : std_logic;
    signal done5 : std_logic;
    signal done6 : std_logic;
    signal done8 : std_logic;

end entity;

architecture rtl of adder_tree_tb is

begin

    uut4: entity adder_tree
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
    uut5: entity adder_tree
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
    uut6: entity adder_tree
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
    uut8: entity adder_tree
        generic map (
            n => n8,
            size => size
        )
        port map (
            clk => clk,
            start => start8,
            values => values8,
            sum => sum8,
            done => done8
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
        values4 <= "00010010" & "00010011" & "00001000" & "00000111";
        wait for clk_period;
        values4 <= "00000001" & "00000100" & "00010000" & "01000000";
        assert done4 = '1';
        assert sum4 = "00111001";
        wait for clk_period;
        start4 <= '0';
        assert done4 = '1';
        assert sum4 = "00110100";
        wait for clk_period;
        assert done4 = '1';
        assert sum4 = "01010101";
        wait for clk_period;
        assert done4 = '0';
        assert sum4 = "01010101";
        wait for clk_period;
        assert done4 = '0';
        assert sum4 = "01010101";

        start5 <= '1';
        values5 <= "00001011" & "00001111" & "00001001" & "00010110" & "00100010";
        wait for clk_period;
        start5 <= '0';
        wait for clk_period;
        wait for clk_period;
        assert done5 = '1';
        assert sum5 = "01011011";
        wait for clk_period;
        assert done5 = '0';

        start6 <= '1';
        values6 <= "00001011" & "00001111" & "00001001" & "00010110" & "00100010" & "11110010";
        wait for clk_period;
        start6 <= '0';
        wait for clk_period;
        wait for clk_period;
        assert done6 = '1';
        assert sum6 = "01001101";
        wait for clk_period;
        assert done6 = '0';

        start8 <= '1';
        values8 <= "00001011" & "00001111" & "00001001" & "00010110" & "00001011" & "00001111" & "00001001" & "00010110";
        wait for clk_period;
        start8 <= '0';
        values8 <= (others => '0');
        wait for clk_period;
        wait for clk_period;
        assert done8 = '1';
        assert sum8 = "01110010";
        wait for clk_period;
        assert done8 = '0';
        assert sum8 = "01110010";
        wait for clk_period;
        assert done8 = '0';
        assert sum8 = "01110010";

        wait;
    end process;

end architecture;