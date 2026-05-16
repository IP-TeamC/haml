library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.math.all;
use work.fitness_linreg;
use work.pop_init;
use work.tournament_sel;
use work.mutation;
use work.tournament_rep;

entity ga_linreg is

    generic (
        mask_factor : natural := 3;
        k : natural := 4;
        var_num : natural := 2;
        fp_size : natural := 18;
        fp_frac : natural := 12;
        dp_adr_size : natural := 7;
        chr_adr_size : natural := 7
    );

    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        mark_end : in std_logic;
        dp_we : in std_logic_vector(var_num downto 0);
        dp_adr : in std_logic_vector(dp_adr_size-1 downto 0);
        dp_data : in std_logic_vector(fp_size-1 downto 0);

        best_chr_adr : out std_logic_vector(chr_adr_size-1 downto 0)
    );

end entity;

architecture rtl of ga_linreg is

    -- Zustandsverwaltung
    type t_ram_data is array(natural range <>) of std_logic_vector(fp_size-1 downto 0);
    type t_state is (s_ready, s_init, s_train);
    signal state : t_state;
    signal next_state : t_state;

    -- RAM fuer Datensatz
    signal ram_dp_we : std_logic_vector(var_num downto 0);
    signal ram_dp_adr : std_logic_vector(dp_adr_size-1 downto 0);
    signal ram_dp_di : t_ram_data(0 to var_num);
    signal ram_dp_do : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal dp_end_adr : std_logic_vector(dp_adr_size-1 downto 0);

    -- RAM für Population/Chromosome
    signal ram_chr_we : std_logic_vector(var_num+1 downto 0);
    signal ram_chr_adr : std_logic_vector(chr_adr_size-1 downto 0);
    signal ram_chr_di : t_ram_data(0 to var_num+1);
    signal ram_chr_do : std_logic_vector(fp_size*(var_num+2)-1 downto 0);

    -- Population Initializer
    signal init_start : std_logic;
    signal init_done : std_logic;
    signal init_ram_chr_we : std_logic_vector(var_num+1 downto 0);
    signal init_ram_chr_adr : std_logic_vector(chr_adr_size-1 downto 0);
    signal init_ram_chr_di : std_logic_vector(fp_size-1 downto 0);
    signal init_fitness_start : std_logic;

    -- Fitness-Funktion
    signal fitness_start : std_logic;
    signal fitness_ram_dp_adr : std_logic_vector(ram_dp_adr'range);
    signal fitness_fit : std_logic_vector(fp_size-1 downto 0);
    signal fitness_done : std_logic;

    -- Trainer
    signal trainer_start : std_logic;
    signal trainer_ram_chr_we : std_logic_vector(var_num+1 downto 0);
    signal trainer_ram_chr_adr : std_logic_vector(chr_adr_size-1 downto 0);
    signal trainer_ram_chr_di : std_logic_vector(fp_size*(var_num+2)-1 downto 0);
    signal trainer_fitness_start : std_logic;

begin

    best_chr_adr <= ram_chr_adr;

    init_start <= '1' when state = s_init else '0';
    fitness_start <= init_fitness_start or trainer_fitness_start;
    trainer_start <= '1' when state = s_train else '0';

    ram_dp_we <= dp_we;
    ram_dp_adr <= dp_adr when state = s_ready else fitness_ram_dp_adr;
    gen_ram_dp_inputs: for i in 0 to var_num generate
        ram_dp_di(i) <= dp_data;
    end generate; 

    ram_chr_we <= init_ram_chr_we or trainer_ram_chr_we;
    ram_chr_adr <= init_ram_chr_adr when state = s_init else trainer_ram_chr_adr;
    gen_ram_chr_di: for i in 0 to var_num+1 generate
        ram_chr_di(i) <= init_ram_chr_di when state = s_init else flat_vec(trainer_ram_chr_di, fp_size, i);
    end generate; 

    -- 0 => Expected, 1 => Feature 1, ...
    gen_ram_dp: for i in 0 to var_num generate
        ram_dp: entity work.ram
            generic map(
                adr_size => dp_adr_size,
                data_size => fp_size
            )
            port map(
                clk => clk,
                we => ram_dp_we(i),
                adr => ram_dp_adr,
                di => ram_dp_di(i),
                do => ram_dp_do(flat_upper(fp_size, i) downto flat_lower(fp_size, i))
            );
    end generate;

    -- 0 => theta0 (constant), 1 => theta1 (linear), ..., var_num+1 => fitness
    gen_ram_chr: for i in 0 to var_num+1 generate
        ram_dp: entity work.ram
            generic map(
                adr_size => dp_adr_size,
                data_size => fp_size
            )
            port map(
                clk => clk,
                we => ram_chr_we(i),
                adr => ram_chr_adr,
                di => ram_chr_di(i),
                do => ram_chr_do(flat_upper(fp_size, i) downto flat_lower(fp_size, i))
            );
    end generate;

    fitness_linreg: entity work.fitness_linreg
        generic map(
            var_num => var_num,
            fp_size => fp_size,
            fp_frac => fp_frac,
            adr_size => dp_adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            start => fitness_start,
            chr => ram_chr_do(flat_upper(fp_size, var_num) downto 0),
            end_adr => dp_end_adr,
            ram_data => ram_dp_do,
            ram_adr => fitness_ram_dp_adr,
            fit => fitness_fit,
            done => fitness_done
        );

    pop_init: entity work.pop_init
        generic map (
            var_num => var_num,
            fp_size => fp_size,
            adr_size => dp_adr_size
        )
        port map (
            clk => clk,
            rst => rst,
            start => init_start,
            fitness_done => fitness_done,
            fitness_fit => fitness_fit,
            ram_chr_we => init_ram_chr_we,
            ram_chr_adr => init_ram_chr_adr,
            ram_chr_di => init_ram_chr_di,
            fitness_start => init_fitness_start,
            done => init_done
        );

    trainer: entity work.trainer
        generic map(
            mask_factor => mask_factor,
            k => k,
            var_num => var_num,
            fp_size => fp_size,
            chr_adr_size => chr_adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            start => trainer_start,
            fitness_done => fitness_done,
            fitness_fit => fitness_fit,
            ram_chr_do => ram_chr_do,
            ram_chr_we => trainer_ram_chr_we,
            ram_chr_adr => trainer_ram_chr_adr,
            ram_chr_di => trainer_ram_chr_di,
            fitness_start => trainer_fitness_start
        );

    next_state <= s_ready when rst = '1'
        else s_init when state = s_ready and start = '1'
        else s_train when state = s_init and init_done = '1'
        else state;

    process (clk)
    begin
        if rising_edge(clk) then
            state <= next_state;

            if mark_end = '1' then
                dp_end_adr <= dp_adr;
            end if;
        end if;
    end process;

end architecture;