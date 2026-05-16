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
    constant adr_size : natural := 8;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic;
    signal start : std_logic;
    signal chr_do : std_logic_vector(fp_size*(var_num+2)-1 downto 0);

    -- Outputs
    signal chr_adr : std_logic_vector(adr_size-1 downto 0);
    signal done : std_logic;
    signal best_chr : std_logic_vector(fp_size*(var_num+2)-1 downto 0);

end entity;

architecture rtl of tournament_sel_tb is

begin

    uut: entity work.tournament_sel
        generic map(
            k => k,
            var_num => var_num,
            fp_size => fp_size,
            adr_size => adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            start => start,
            chr_do => chr_do,
            chr_adr => chr_adr,
            done => done,
            best_chr => best_chr
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

        start <= '1';
        wait for clk_period;
        chr_do <= "1011000100010001";
        start <= '0';
        assert done = '0';
        assert chr_adr /= "00000000";
        assert chr_adr /= tmp;
        tmp := chr_adr;
        wait for clk_period;
        chr_do <= "0101001000100010";
        assert done = '0';
        assert chr_adr /= "00000000";
        assert chr_adr /= tmp;
        tmp := chr_adr;
        wait for clk_period;
        chr_do <= "0111010001000100";
        assert done = '0';
        assert chr_adr /= "00000000";
        assert chr_adr /= tmp;
        tmp := chr_adr;
        wait for clk_period;
        assert done = '1';
        assert best_chr = "0101001000100010";

        report "Done";
        wait;
    end process;

end architecture;