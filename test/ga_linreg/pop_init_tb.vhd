library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.util.all;
use work.math.all;

entity pop_init_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant var_num : natural := 2;
    constant fp_size : natural := 8;
    constant adr_size : natural := 2;
    constant generator : std_logic_vector(8 downto 0) := "101110000";
    constant seed : std_logic_vector(7 downto 0) := "01100111";

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic;
    signal start : std_logic;
    signal fitness_done : std_logic;
    signal fitness_fit : std_logic_vector(fp_size-1 downto 0);

    -- Outputs
    signal ram_chr_we : std_logic_vector(var_num+1 downto 0);
    signal ram_chr_adr : std_logic_vector(adr_size-1 downto 0);
    signal ram_chr_di : std_logic_vector(fp_size-1 downto 0);
    signal fitness_rst : std_logic;
    signal fitness_start : std_logic;
    signal done : std_logic;

end entity;

architecture rtl of pop_init_tb is

begin

    uut: entity work.pop_init
        generic map(
            var_num => var_num,
            fp_size => fp_size,
            adr_size => adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            start => start,
            fitness_done => fitness_done,
            fitness_fit => fitness_fit,
            generator => generator,
            seed => seed,
            ram_chr_we => ram_chr_we,
            ram_chr_adr => ram_chr_adr,
            ram_chr_di => ram_chr_di,
            fitness_rst => fitness_rst,
            fitness_start => fitness_start,
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
        wait until rising_edge(clk);
        wait for 1 ps;
        rst <= '0';
        fitness_done <= '0';
        assert fitness_start = '0';
        assert fitness_rst = '1';
        assert done = '0';
        wait until falling_edge(clk);
        assert ram_chr_we = "0000";

        -- Generate
        start <= '1';
        wait for clk_period;
        assert ram_chr_we = "0001";
        assert ram_chr_adr = "00";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert unsigned(ram_chr_di) >= 0;
        wait for clk_period;
        start <= '0';
        assert ram_chr_we = "0001";
        assert ram_chr_adr = "01";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert unsigned(ram_chr_di) >= 0;
        wait for clk_period;
        assert ram_chr_we = "0001";
        assert ram_chr_adr = "10";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert unsigned(ram_chr_di) >= 0;
        wait for clk_period;
        assert ram_chr_we = "0001";
        assert ram_chr_adr = "11";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert unsigned(ram_chr_di) >= 0;
        wait for clk_period;
        assert ram_chr_we = "0010";
        assert ram_chr_adr = "00";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert unsigned(ram_chr_di) >= 0;
        wait for clk_period;
        assert ram_chr_we = "0010";
        assert ram_chr_adr = "01";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert unsigned(ram_chr_di) >= 0;
        wait for clk_period;
        assert ram_chr_we = "0010";
        assert ram_chr_adr = "10";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert unsigned(ram_chr_di) >= 0;
        wait for clk_period;
        assert ram_chr_we = "0010";
        assert ram_chr_adr = "11";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert unsigned(ram_chr_di) >= 0;
        wait for clk_period;
        assert ram_chr_we = "0100";
        assert ram_chr_adr = "00";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert unsigned(ram_chr_di) >= 0;
        wait for clk_period;
        assert ram_chr_we = "0100";
        assert ram_chr_adr = "01";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert unsigned(ram_chr_di) >= 0;
        wait for clk_period;
        assert ram_chr_we = "0100";
        assert ram_chr_adr = "10";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert unsigned(ram_chr_di) >= 0;
        wait for clk_period;
        assert ram_chr_we = "0100";
        assert ram_chr_adr = "11";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert unsigned(ram_chr_di) >= 0;
        wait for clk_period;

        -- Fitness
        assert ram_chr_we = "0000";
        assert ram_chr_adr = "00";
        assert fitness_start = '1';
        assert fitness_rst = '0';
        assert done = '0';
        wait for clk_period;
        assert ram_chr_we = "0000";
        assert ram_chr_adr = "00";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        wait for clk_period;
        assert ram_chr_we = "0000";
        assert ram_chr_adr = "00";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        fitness_fit <= "10001100";
        fitness_done <= '1';
        wait for clk_period;
        assert ram_chr_we = "1000";
        assert ram_chr_adr = "00";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert ram_chr_di = fitness_fit;
        wait for clk_period;
        assert ram_chr_we = "1000";
        assert ram_chr_adr = "00";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert ram_chr_di = fitness_fit;
        fitness_done <= '0';
        wait for clk_period;
        assert ram_chr_we = "0000";
        assert ram_chr_adr = "00";
        assert fitness_start = '0';
        assert fitness_rst = '1';
        assert done = '0';
        assert ram_chr_di = fitness_fit;
        wait for clk_period;
        assert ram_chr_we = "0000";
        assert ram_chr_adr = "01";
        assert fitness_start = '1';
        assert fitness_rst = '0';
        assert done = '0';
        wait for clk_period;
        assert ram_chr_di = fitness_fit;
        assert ram_chr_we = "0000";
        assert ram_chr_adr = "01";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert ram_chr_di = fitness_fit;
        fitness_done <= '1';
        wait for clk_period;
        assert ram_chr_di = fitness_fit;
        assert ram_chr_we = "1000";
        assert ram_chr_adr = "01";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert ram_chr_di = fitness_fit;
        fitness_done <= '0';
        wait for clk_period;
        assert ram_chr_di = fitness_fit;
        assert ram_chr_we = "0000";
        assert ram_chr_adr = "01";
        assert fitness_start = '0';
        assert fitness_rst = '1';
        assert done = '0';
        assert ram_chr_di = fitness_fit;
        wait for clk_period;
        assert ram_chr_di = fitness_fit;
        assert ram_chr_we = "0000";
        assert ram_chr_adr = "10";
        assert fitness_start = '1';
        assert fitness_rst = '0';
        assert done = '0';
        assert ram_chr_di = fitness_fit;
        fitness_done <= '1';
        wait for clk_period;
        assert ram_chr_di = fitness_fit;
        assert ram_chr_we = "1000";
        assert ram_chr_adr = "10";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert ram_chr_di = fitness_fit;
        fitness_done <= '0';
        wait for clk_period;
        assert ram_chr_di = fitness_fit;
        assert ram_chr_we = "0000";
        assert ram_chr_adr = "10";
        assert fitness_start = '0';
        assert fitness_rst = '1';
        assert done = '0';
        assert ram_chr_di = fitness_fit;
        wait for clk_period;
        assert ram_chr_di = fitness_fit;
        assert ram_chr_we = "0000";
        assert ram_chr_adr = "11";
        assert fitness_start = '1';
        assert fitness_rst = '0';
        assert done = '0';
        assert ram_chr_di = fitness_fit;
        fitness_done <= '1';
        wait for clk_period;
        assert ram_chr_di = fitness_fit;
        assert ram_chr_we = "1000";
        assert ram_chr_adr = "11";
        assert fitness_start = '0';
        assert fitness_rst = '0';
        assert done = '0';
        assert ram_chr_di = fitness_fit;
        fitness_done <= '0';
        wait for clk_period;
        assert ram_chr_di = fitness_fit;
        assert ram_chr_we = "0000";
        assert ram_chr_adr = "11";
        assert fitness_start = '0';
        assert fitness_rst = '1';
        assert done = '0';
        assert ram_chr_di = fitness_fit;
        wait for clk_period;
        assert ram_chr_di = fitness_fit;
        assert ram_chr_we = "0000";
        assert ram_chr_adr = "00";
        assert fitness_start = '0';
        assert fitness_rst = '1';
        assert done = '1';
        assert ram_chr_di = fitness_fit;

        wait for clk_period;
        assert ram_chr_di = fitness_fit;
        assert ram_chr_we = "0000";
        assert ram_chr_adr = "00";
        assert fitness_start = '0';
        assert fitness_rst = '1';
        assert done = '0';
        wait for clk_period;
        assert ram_chr_di = fitness_fit;
        assert ram_chr_we = "0000";
        assert ram_chr_adr = "00";
        assert fitness_start = '0';
        assert fitness_rst = '1';
        assert done = '0';

        report "Done";
        wait;
    end process;

end architecture;