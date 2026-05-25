library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.util.all;
use work.math.all;
use work.rse_linreg;

entity rse_linreg_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant var_num : natural := 2;
    constant fp_size : natural := 8;
    constant fp_frac : natural := 6;
    constant fit_size : natural := 2*fp_size;
    constant adr_size : natural := 2;
    constant square : boolean := false;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic;
    signal valid : std_logic;
    signal chr : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal ram_dp_do : std_logic_vector(fp_size*(var_num+1)-1 downto 0);

    -- Outputs
    signal fit : std_logic_vector(fit_size-1 downto 0);
    signal done : std_logic;

end entity;

architecture rtl of rse_linreg_tb is

begin

    uut: entity rse_linreg
        generic map (
            var_num => var_num,
            fp_size => fp_size,
            fp_frac => fp_frac,
            fit_size => fit_size,
            adr_size => adr_size,
            square => square
        )
        port map (
            clk => clk,
            rst => rst,
            valid => valid,
            chr => chr,
            ram_dp_do => ram_dp_do,
            fit => fit,
            done => done
        );

    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    process
        variable tmp1 : std_logic_vector(fit_size-1 downto 0);
        variable tmp2 : std_logic_vector(fit_size-1 downto 0);
    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        assert done = '0';

        valid <= '1';
        -- y = 0.5*x2-0.125*x1+0.25
        chr <= "00" & "100000"
            & "11" & "111000"
            & "00" & "010000";

        -- x2 = 0.1875, x1 = 0.3828125, y = 0.28125 (nicht ganz exakt)
        -- Error: 0.000214576736
        ram_dp_do <= "00" & "001100"
            & "00" & "011001"
            & "00" & "010010";
        wait for clk_period;
        assert done = '0';
        -- x2 = 0.0625, x1 = 0.5, y = 0.21875 (exakt)
        -- kein Error
        ram_dp_do <= "00" & "000100"
            & "00" & "100000"
            & "00" & "001110";
        wait for clk_period;
        assert done <= '0';
        -- x2 = 0.0625, x1 = 0.5, y = 0.875 (schlecht)
        -- Error: 0.430664063
        ram_dp_do <= "00" & "000100"
            & "00" & "100000"
            & "00" & "111000";
        wait for clk_period;
        valid <= '0';
        assert done <= '0';

        while done = '0' loop
            tmp1 := tmp2;
            tmp2 := fit;
            wait until falling_edge(clk);
        end loop;
        assert done = '1';

        -- kleiner Fehler für 1. DP
        assert tmp1 = "0000000000000111";
        -- unveraenderter Fehler für 2. DP
        assert tmp2 = tmp1;
        -- viel groeßerer Fehler für 3. DP
        assert fit = "0000000101010111";

        -- stabile Ausgabe, wenn start = 0
        for i in 0 to 30 loop
            wait for clk_period;
            assert done = '0';
            assert fit = "0000000101010111";
        end loop;

        report "Done";
        wait;
    end process;

end architecture;