library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.util.all;
use work.math.all;
use work.fitness_linreg;

entity fitness_linreg_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant var_num : natural := 2;
    constant fp_size : natural := 8;
    constant fp_frac : natural := 6;
    constant adr_size : natural := 2;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic;
    signal start : std_logic;
    signal chr : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal end_adr : std_logic_vector(adr_size-1 downto 0);
    signal ram_data : std_logic_vector(fp_size*(var_num+1)-1 downto 0);

    -- Outputs
    signal ram_adr : std_logic_vector(adr_size-1 downto 0);
    signal fit : std_logic_vector(fp_size-1 downto 0);
    signal done : std_logic;

    -- Setup
    signal ram_we : std_logic := '1';
    signal ram_adr_mux : std_logic_vector(ram_adr'range);
    signal ram_adr_write : std_logic_vector(ram_adr'range) := (others => '0');
    signal ram_di : std_logic_vector(ram_data'range);

end entity;

architecture rtl of fitness_linreg_tb is

begin

    ram_adr_mux <= ram_adr when ram_we = '0' else ram_adr_write;

    ram: entity work.ram
        generic map(
            adr_size => adr_size,
            data_size => ram_data'length
        )
        port map(
            clk => clk,
            we => ram_we,
            adr => ram_adr_mux,
            di => ram_di,
            do => ram_data
        );

    uut: entity fitness_linreg
        generic map (
            var_num => var_num,
            fp_size => fp_size,
            fp_frac => fp_frac,
            adr_size => adr_size
        )
        port map (
            clk => clk,
            rst => rst,
            start => start,
            chr => chr,
            end_adr => end_adr,
            ram_data => ram_data,
            ram_adr => ram_adr,
            fit => fit,
            done => done
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
        assert done = '0';

        ram_we <= '1';
        ram_adr_write <= "00";
        -- x2 = 0.1875, x1 = 0.3828125, y = 0.28125 (nicht ganz exakt)
        -- Error: 0.000214576736
        ram_di <= "00" & "001100"
            & "00" & "011001"
            & "00" & "010010";
        wait for clk_period;
        ram_adr_write <= "01";
        -- x2 = 0.0625, x1 = 0.5, y = 0.21875 (exakt)
        -- kein Error
        ram_di <= "00" & "000100"
            & "00" & "100000"
            & "00" & "001110";
        wait for clk_period;
        ram_adr_write <= "10";
        -- x2 = 0.0625, x1 = 0.5, y = 0.875 (schlecht)
        -- Error: 0.430664063
        ram_di <= "00" & "000100"
            & "00" & "100000"
            & "00" & "111000";
        wait for clk_period;
        ram_we <= '0';

        start <= '1';
        -- y = 0.5*x2-0.125*x1+0.25
        chr <= "00" & "100000"
            & "11" & "111000"
            & "00" & "010000";
        end_adr <= "10";
        wait for clk_period;
        start <= '0';
        assert done = '0';
        assert ram_adr = "00";
        wait for clk_period;
        assert done = '0';
        assert ram_adr = "01";
        wait for clk_period;
        assert done = '0';
        assert ram_adr = "10";

        wait until done = '1' and clk = '0';
        -- kleiner Fehler (zu ungenau, deshalb 0)
        assert fit = "00000000";
        wait for clk_period;
        assert done = '1';
        -- unveraenderter Fehler
        assert fit = "00000000";
        wait for clk_period;
        assert done = '1';
        -- viel groeßerer Fehler
        assert fit = "00" & "000110";
        wait for clk_period;
        assert done = '0';

        report "Done";
        wait;
    end process;

end architecture;