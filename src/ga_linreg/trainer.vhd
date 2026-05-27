library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.math.all;

entity trainer is

    generic (
        mask_factor : natural;
        k_sel : natural;
        k_rep : natural;
        var_num : natural;
        fp_size : natural;
        fit_size : natural;
        chr_adr_size : natural;
        replace_with_worse : boolean;
        mut_arith : boolean
    );

    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        fitness_done : in std_logic;
        fitness_fit : in std_logic_vector(fit_size-1 downto 0);

        ram_fit_do : in std_logic_vector(fit_size-1 downto 0);
        ram_chr_do : in std_logic_vector(fp_size*(var_num+1)-1 downto 0);
        ram_chr_adr : out std_logic_vector(chr_adr_size-1 downto 0);
        ram_chr_di : out std_logic_vector(fp_size*(var_num+1)-1 downto 0);
        ram_chr_fit_we : out std_logic;

        fitness_start : out std_logic;
        done : out std_logic
    );

end entity;

architecture rtl of trainer is

    -- Zustandsverwaltung
    type t_state is (s_ready, s_select, s_crossover, s_mutate, s_fit, s_replace);
    signal prev_state : t_state;
    signal state : t_state;
    signal next_state : t_state;

    -- Tournament Selection
    signal ts_start : std_logic;
    signal ts_ram_chr_adr : std_logic_vector(ram_chr_adr'range);
    signal ts_best_chr1 : std_logic_vector(ram_chr_do'range);
    signal ts_best_chr2 : std_logic_vector(ram_chr_do'range);
    signal ts_done : std_logic;

    -- Crossover
    signal cross_start : std_logic;
    signal cross_chr_child : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal cross_done : std_logic;

    -- Mutation
    signal mut_start : std_logic;
    signal mut_chr_mut : std_logic_vector(cross_chr_child'range);
    signal mut_done : std_logic;

    -- Tournament Replacement
    signal tr_start : std_logic;
    signal tr_ram_chr_adr : std_logic_vector(ram_chr_adr'range);
    signal tr_ram_chr_fit_we : std_logic;
    signal tr_done : std_logic;

begin

    done <= '1' when state = s_ready else '0';

    ram_chr_fit_we <= tr_ram_chr_fit_we;
    ram_chr_adr <= ts_ram_chr_adr when state = s_select
        else tr_ram_chr_adr;
    ram_chr_di <= mut_chr_mut;

    ts_start <= '1' when state = s_select and prev_state /= s_select
        else '0';
    cross_start <= '1' when state = s_crossover and prev_state /= s_crossover
        else '0';
    mut_start <= '1' when state = s_mutate and prev_state /= s_mutate
        else '0';
    fitness_start <= '1' when state = s_fit and prev_state /= s_fit
        else '0';
    tr_start <= '1' when state = s_replace and prev_state /= s_replace
        else '0';

    tournament_sel: entity work.tournament_sel
        generic map(
            k => k_sel,
            var_num => var_num,
            fp_size => fp_size,
            fit_size => fit_size,
            adr_size => chr_adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            start => ts_start,
            fit_do => ram_fit_do,
            chr_do => ram_chr_do,
            chr_adr => ts_ram_chr_adr,
            done => ts_done,
            best_chr1 => ts_best_chr1,
            best_chr2 => ts_best_chr2
        );

    crossover: entity work.crossover
        generic map(
            var_num => var_num,
            fp_size => fp_size
        )
        port map(
            clk => clk,
            rst => rst,
            start => cross_start,
            chr_parent1 => ts_best_chr1,
            chr_parent2 => ts_best_chr2,
            done => cross_done,
            chr_child => cross_chr_child
        );

    mutation: entity work.mutation
        generic map(
            mask_factor => mask_factor,
            var_num => var_num,
            fp_size => fp_size,
            mut_arith => mut_arith
        )
        port map(
            clk => clk,
            rst => rst,
            start => mut_start,
            chr => cross_chr_child,
            done => mut_done,
            chr_mut => mut_chr_mut
        );

    tournament_rep: entity work.tournament_rep
        generic map(
            k => k_rep,
            var_num => var_num,
            fp_size => fp_size,
            fit_size => fit_size,
            adr_size => chr_adr_size,
            replace_with_worse => replace_with_worse
        )
        port map(
            clk => clk,
            rst => rst,
            start => tr_start,
            chr_fit => fitness_fit,
            fit_do => ram_fit_do,
            chr_do => ram_chr_do,
            chr_adr => tr_ram_chr_adr,
            chr_fit_we => tr_ram_chr_fit_we,
            done => tr_done
        );

    next_state <= s_ready when rst = '1'
        else s_select when state = s_ready and start = '1'
        else s_crossover when state = s_select and ts_done = '1'
        else s_mutate when state = s_crossover and cross_done = '1'
        else s_fit when state = s_mutate and mut_done = '1'
        else s_replace when state = s_fit and fitness_done = '1'
        else s_ready when state = s_replace and tr_done = '1'
        else state;

    process (clk)
    begin
        if rising_edge(clk) then
            prev_state <= state;
            state <= next_state;
        end if;
    end process;

end architecture;