library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.util.all;
use work.math.all;
use work.mse_linreg;

entity mse_linreg_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant var_num : natural := 2;
    constant fp_size : natural := 8;
    constant fp_frac : natural := 6;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic;
    signal start : std_logic;
    signal chr : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal ram_data : std_logic_vector(fp_size*(var_num+1)-1 downto 0);

    -- Outputs
    signal fit : std_logic_vector(4*fp_size-1 downto 0);
    signal done : std_logic;

end entity;

architecture rtl of mse_linreg_tb is

begin

    uut: entity mse_linreg
        generic map (
            var_num => var_num,
            fp_size => fp_size,
            fp_frac => fp_frac
        )
        port map (
            clk => clk,
            rst => rst,
            start => start,
            chr => chr,
            ram_data => ram_data,
            fit => fit,
            done => done
        );

    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    process
        variable tmp : std_logic_vector(31 downto 0);
    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        assert done = '0';

        start <= '1';
        -- y = 0.5*x2-0.125*x1+0.25
        chr <= "00" & "100000"
            & "11" & "111000"
            & "00" & "010000";

        -- x2 = 0.1875, x1 = 0.3828125, y = 0.28125 (nicht ganz exakt)
        -- Error: 0.000214576736
        ram_data <= "00" & "001100"
            & "00" & "011001"
            & "00" & "010010";
        wait for clk_period;
        assert done = '0';
        -- x2 = 0.0625, x1 = 0.5, y = 0.21875 (exakt)
        -- kein Error
        ram_data <= "00" & "000100"
            & "00" & "100000"
            & "00" & "001110";
        wait for clk_period;
        assert done <= '0';
        -- x2 = 0.0625, x1 = 0.5, y = 0.875 (schlecht)
        -- Error: 0.430664063
        ram_data <= "00" & "000100"
            & "00" & "100000"
            & "00" & "111000";
        wait for clk_period;
        start <= '0';
        assert done <= '0';

        wait until done = '1' and clk = '0';
        -- kleiner Fehler
        assert fit /= "00000000" & "000000000000000000000000";
        assert signed(fit) >= "00000000" & "000000000000100000000000";
        assert signed(fit) <= "00000000" & "000000000001000000000000";
        tmp := fit;
        wait for clk_period;
        assert done = '1';
        -- unveraenderter Fehler
        assert fit = tmp;
        wait for clk_period;
        assert done = '1';
        -- viel groeßerer Fehler
        assert signed(fit) >= "00000000" & "011011100100000000000000";
        assert signed(fit) <= "00000000" & "011011111111111111111111";
        wait for clk_period;
        assert done = '0';

        report "Done";
        wait;
    end process;

end architecture;