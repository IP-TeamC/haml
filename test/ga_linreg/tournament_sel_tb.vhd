library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.util.all;
use work.math.all;

entity tournament_sel_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant k : natural := 3;
    constant var_num : natural := 2;
    constant fp_size : natural := 4;
    constant fit_size : natural := fp_size;
    constant adr_size : natural := 8;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic;
    signal start : std_logic;
    signal fit_do : std_logic_vector(fit_size-1 downto 0);
    signal chr_do : std_logic_vector(fp_size*(var_num+1)-1 downto 0);

    -- Outputs
    signal chr_adr : std_logic_vector(adr_size-1 downto 0);
    signal done : std_logic;
    signal best_chr1 : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal best_chr2 : std_logic_vector(fp_size*(var_num+1)-1 downto 0);

end entity;

architecture rtl of tournament_sel_tb is

begin

    uut: entity work.tournament_sel
        generic map(
            k => k,
            var_num => var_num,
            fp_size => fp_size,
            fit_size => fit_size,
            adr_size => adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            start => start,
            fit_do => fit_do,
            chr_do => chr_do,
            chr_adr => chr_adr,
            done => done,
            best_chr1 => best_chr1,
            best_chr2 => best_chr2
        );

    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    process
        variable tmp : std_logic_vector(chr_adr'range);
    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        assert done = '0';
        assert chr_adr /= "00000000";
        tmp := chr_adr;

        fit_do <= "0000";
        chr_do <= "000000000000";
        start <= '1';
        wait for clk_period;

        -- Nr. 1
        fit_do <= "1011";
        chr_do <= "000100010001";
        start <= '0';
        assert done = '0';
        assert chr_adr /= "00000000";
        assert chr_adr /= tmp;
        tmp := chr_adr;
        wait for clk_period;
        fit_do <= "0101";
        chr_do <= "001000100010";
        assert done = '0';
        assert chr_adr /= "00000000";
        assert chr_adr /= tmp;
        tmp := chr_adr;
        wait for clk_period;
        fit_do <= "0111";
        chr_do <= "010001000100";
        assert done = '0';
        assert chr_adr /= "00000000";
        assert chr_adr /= tmp;
        tmp := chr_adr;
        wait for clk_period;

        -- Clear
        fit_do <= "0000";
        chr_do <= "000000000000";
        assert done = '0';
        assert chr_adr /= "00000000";
        assert chr_adr /= tmp;
        tmp := chr_adr;
        wait for clk_period;

        -- Nr. 2
        fit_do <= "1000";
        chr_do <= "000010000001";
        start <= '0';
        assert done = '0';
        assert chr_adr /= "00000000";
        assert chr_adr /= tmp;
        tmp := chr_adr;
        wait for clk_period;
        fit_do <= "0010";
        chr_do <= "000000000010";
        assert done = '0';
        assert chr_adr /= "00000000";
        assert chr_adr /= tmp;
        tmp := chr_adr;
        wait for clk_period;
        fit_do <= "0100";
        chr_do <= "000000000000";
        assert done = '0';
        assert chr_adr /= "00000000";
        assert chr_adr /= tmp;
        tmp := chr_adr;
        wait for clk_period;

        -- Delay (Caching)
        fit_do <= "0000";
        chr_do <= "000000000000";
        assert done = '0';
        assert chr_adr /= "00000000";
        assert chr_adr /= tmp;
        tmp := chr_adr;
        wait for clk_period;

        assert done = '1';
        assert best_chr1 = "001000100010";
        assert best_chr2 = "000000000010";

        report "Done";
        wait;
    end process;

end architecture;