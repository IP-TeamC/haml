library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math.all;
use work.prng.prim_gen;
use work.prng.sample_seed;

-- Populations-Initialisierung
-- generiert ein Chromosom, berechnet dessen Fitness und schreibt das Chromosom sowie die Fitness in die RAMs
-- wiederholt die Chromosom-Generierung, Fitness-Berechnung und das Schreiben fuer jede RAM-Adresse der Chromosome/Fitness
entity pop_init is
    generic (
        var_num : natural;
        fp_size : natural;
        adr_size : natural
    );
    port (
        clk   : in std_logic;
        rst : in std_logic;
        start : in std_logic;
        fitness_done : in std_logic;

        ram_chr_fit_we : out std_logic;
        ram_chr_adr : out std_logic_vector(adr_size-1 downto 0);
        ram_chr_di : out std_logic_vector(fp_size*(var_num+1)-1 downto 0);

        fitness_start : out std_logic;
        done : out std_logic
    );
end entity;

architecture rtl of pop_init is

    type t_state is (s_ready, s_generate, s_fit, s_write, s_done);
    signal state : t_state;
    signal next_state : t_state;

    signal rand : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal i_ram_chr_di : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal next_ram_chr_di : std_logic_vector(fp_size*(var_num+1)-1 downto 0);

    signal chr_adr : unsigned(ram_chr_adr'range);
    signal next_chr_adr : unsigned(ram_chr_adr'range);

    signal last_chr_adr : std_logic;
    signal next_last_chr_adr : std_logic;

    signal next_fitness_start : std_logic;
    signal next_done : std_logic;

    signal lfsr_rst : std_logic;

begin

    ram_chr_di <= i_ram_chr_di;
    ram_chr_fit_we <= '1' when state = s_write
        else '0';
    ram_chr_adr <= std_logic_vector(chr_adr);

    lfsr_rst <= '1' when rst = '1' or state = s_done
        else '0';
    gen_lfsr: for i in 0 to var_num generate
        lfsr: entity work.lfsr
            generic map(
                degree => fp_size
            )
            port map(
                clk => clk,
                rst => lfsr_rst,
                generator => prim_gen(fp_size),
                seed => sample_seed(fp_size, 59-i),
                rand => rand(flat_upper(fp_size, i) downto flat_lower(fp_size, i))
            );
    end generate;

    next_state <= s_ready when rst = '1'
        else s_generate when state = s_ready and start = '1'
        else s_fit when state = s_generate
        else s_write when state = s_fit and fitness_done = '1'
        else s_generate when state = s_write and last_chr_adr = '0'
        else s_done when state = s_write and last_chr_adr = '1'
        else state;

    next_ram_chr_di <= rand when state = s_generate
        else i_ram_chr_di;

    next_chr_adr <= (others => '0') when rst = '1' or state = s_ready
        else chr_adr + 1 when state = s_write
        else chr_adr;
    next_last_chr_adr <= '1' when chr_adr = (chr_adr'range => '1') and rst = '0'
        else '0';

    next_fitness_start <= '1' when state = s_generate and rst = '0'
        else '0';
    next_done <= '1' when state = s_done and rst = '0'
        else '0';

    process (clk)
    begin
        if rising_edge(clk) then
            state <= next_state;
            i_ram_chr_di <= next_ram_chr_di;
            chr_adr <= next_chr_adr;
            last_chr_adr <= next_last_chr_adr;
            fitness_start <= next_fitness_start;
            done <= next_done;
        end if;
    end process;

end architecture;