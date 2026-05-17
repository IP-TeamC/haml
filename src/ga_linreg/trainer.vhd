library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.math.all;

entity trainer is

    generic (
        mask_factor : natural := 3;
        k : natural := 4;
        var_num : natural := 2;
        fp_size : natural := 18;
        chr_adr_size : natural := 7
    );

    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        fitness_done : in std_logic;
        fitness_fit : in std_logic_vector(fp_size-1 downto 0);

        ram_chr_do : in std_logic_vector(fp_size*(var_num+2)-1 downto 0);
        ram_chr_we : out std_logic_vector(var_num+1 downto 0);
        ram_chr_adr : out std_logic_vector(chr_adr_size-1 downto 0);
        ram_chr_di : out std_logic_vector(fp_size*(var_num+2)-1 downto 0);
        
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
    signal ts_best_chr : std_logic_vector(fp_size*(var_num+2)-1 downto 0);
    signal ts_done : std_logic;

    -- Mutation
    signal mut_start : std_logic;
    signal mut_chr_mut : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal mut_done : std_logic;

    -- Tournament Replacement
    signal tr_start : std_logic;
    signal tr_ram_chr_adr : std_logic_vector(chr_adr_size-1 downto 0);
    signal tr_ram_chr_we : std_logic;
    signal tr_done : std_logic;
    
    -- Fitness
    signal fitness_done_prev : std_logic;

begin

    done <= '1' when state = s_ready else '0';

    ram_chr_we <= (others => tr_ram_chr_we);
    ram_chr_adr <= ts_ram_chr_adr when state = s_select else tr_ram_chr_adr;
    ram_chr_di(fp_size*(var_num+2)-1 downto fp_size*(var_num+1)) <= fitness_fit;
    ram_chr_di(fp_size*(var_num+1)-1 downto 0) <= mut_chr_mut;

    ts_start <= '1' when state = s_select and prev_state /= s_select else '0';
    mut_start <= '1' when state = s_mutate and prev_state /= s_mutate else '0';
    fitness_start <= '1' when state = s_fit and prev_state /= s_fit else '0';
    tr_start <= '1' when state = s_replace and prev_state /= s_replace else '0';

    tournament_sel: entity work.tournament_sel
        generic map(
            k => k,
            var_num => var_num,
            fp_size => fp_size,
            adr_size => chr_adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            start => ts_start,
            chr_do => ram_chr_do,
            chr_adr => ts_ram_chr_adr,
            done => ts_done,
            best_chr => ts_best_chr
        );

    mutation: entity work.mutation
        generic map(
            mask_factor => mask_factor,
            var_num => var_num,
            fp_size => fp_size
        )
        port map(
            clk => clk,
            rst => rst,
            start => mut_start,
            chr => ts_best_chr(flat_upper(fp_size, var_num) downto 0),
            done => mut_done,
            chr_mut => mut_chr_mut
        );

    tournament_rep: entity work.tournament_rep
        generic map(
            k => k,
            var_num => var_num,
            fp_size => fp_size,
            adr_size => chr_adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            start => tr_start,
            chr_fit => fitness_fit,
            chr_do => ram_chr_do,
            chr_adr => tr_ram_chr_adr,
            chr_we => tr_ram_chr_we,
            done => tr_done
        );

    next_state <= s_ready when rst = '1'
        else s_select when state = s_ready and start = '1'
        else s_mutate when state = s_select and ts_done = '1'
        else s_fit when state = s_mutate and mut_done = '1'
        else s_replace when state = s_fit and fitness_done = '0' and fitness_done_prev = '1'
        else s_ready when state = s_replace and tr_done = '1'
        else state;

    process (clk)
    begin
        if rising_edge(clk) then
            prev_state <= state;
            state <= next_state;
            fitness_done_prev <= fitness_done;
        end if;
    end process;

end architecture;