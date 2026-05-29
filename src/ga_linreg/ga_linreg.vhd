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

-- Strukturbeschreibung des gesamten genetischen Algorithmus fuer lineare Regression
-- beinhaltet die RAMs fuer die Datenpunkte, Chromosome und Fitness-Werte
-- beinhaltet die Fitness-Funktion, Populations-Initialisierung und den Trainer
-- 1. erlaubt das Beschreiben des Datenpunkt-RAMs von aussen
-- 2. fuehrt nach dem Start die Initialisierung der Population durch
-- 3. startet als letzter Schritt den Trainer
-- 4. gibt kontinuierlich bei Berechnungen der Fitness-Funktion das jeweils beste Chromosom und dessen Fitness aus
entity ga_linreg is

    generic (
        mask_factor : natural := 3; -- hoeherer Masken-Faktor reduziert die Mutationswahrscheinlichkeit (siehe mutation.vhd)
        k_sel : natural := 3; -- Tournament-Groesse fuer Tournament Selection
        k_rep : natural := 3; -- Tournament-Groesse fuer Tournament Replacement
        var_num : natural := 1; -- Anzahl Features
        fp_size : natural := 18; -- Fixed-Point: Groesse (insgesamt)
        fp_frac : natural := 17; -- Fixed-Point: Fraction-Anteil
        fit_size: natural := 36; -- Genauigkeit der Fitness-Funktion (siehe rse_linreg.vhd)
        dp_adr_size : natural := 8; -- Adressbreite der Datenpunkt-RAMs
        chr_adr_size : natural := 6; -- Adressbreite der Chromosom-/Fitness-RAMs (bestimmt Populations-Groesse)
        replace_with_worse : boolean := false; -- false verhindert das Ersetzen durch schlechtere Kandidaten (empfohlene Einstellung fuer Tournament Replacement)
        mut_arith : boolean := true; -- Mutations-Modus: Logisch (XOR) oder Arithmetisch (ADD/SUB, empfohlen)
        square : boolean := false -- Fehler-Funktion: Sum of Squared (square = true) / Absolute (square = false) Errors
    );

    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic; -- laeuft nach dem Start dauerhaft bis zum Reset

        mark_end : in std_logic; -- markiert den aktuellen Datenpunkt/Adresse als letzten Datenpunkt
        dp_we : in std_logic_vector(var_num downto 0); -- Auswahl des zu schreibenden Bestandteils des Datenpunkts (0 => Expected, 1 => Feature 1, ..., var_num => Feature var_num)
        dp_adr : in std_logic_vector(dp_adr_size-1 downto 0); -- Adresse des zu schreibenden Datenpunkts
        dp_data : in std_logic_vector(fp_size-1 downto 0); -- Daten des zu schreibenden Bestandteils des Datenpunkts (0 => Expected, 1 => Feature 1, ..., var_num => Feature var_num)

        best_chr : out std_logic_vector(fp_size*(var_num+1)-1 downto 0); -- bisher bestes Chromosom
        best_chr_fit : out std_logic_vector(fit_size-1 downto 0) -- Fitness des bisher besten Chromosoms
    );

end entity;

architecture rtl of ga_linreg is

    -- Zustandsverwaltung
    type t_ram_data is array(natural range <>) of std_logic_vector(fp_size-1 downto 0);
    type t_state is (s_ready, s_init, s_train);
    signal prev_state : t_state;
    signal state : t_state;
    signal next_state : t_state;

    -- RAM fuer Datensatz
    signal ram_dp_we : std_logic_vector(var_num downto 0);
    signal ram_dp_adr : std_logic_vector(dp_adr_size-1 downto 0);
    signal ram_dp_di : t_ram_data(0 to var_num);
    signal ram_dp_do : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal dp_end_adr : std_logic_vector(ram_dp_adr'range);
    signal next_dp_end_adr : std_logic_vector(dp_end_adr'range);

    -- RAM fuer Population/Chromosome
    signal ram_chr_we : std_logic;
    signal ram_chr_adr : std_logic_vector(chr_adr_size-1 downto 0);
    signal ram_chr_di : t_ram_data(0 to var_num);
    signal ram_chr_do : std_logic_vector(fp_size*(var_num+1)-1 downto 0);

    -- RAM fuer Fitness der Population/Chromosome
    signal ram_fit_we : std_logic;
    signal ram_fit_adr : std_logic_vector(chr_adr_size-1 downto 0);
    signal ram_fit_di : std_logic_vector(fit_size-1 downto 0);
    signal ram_fit_do : std_logic_vector(fit_size-1 downto 0);

    -- Population Initializer
    signal init_start : std_logic;
    signal init_done : std_logic;
    signal init_ram_chr_fit_we : std_logic;
    signal init_ram_chr_adr : std_logic_vector(ram_chr_adr'range);
    signal init_ram_chr_di : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal init_fitness_start : std_logic;

    -- Fitness-Funktion
    signal fitness_start : std_logic;
    signal fitness_chr : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal fitness_ram_dp_adr : std_logic_vector(ram_dp_adr'range);
    signal fitness_fit : std_logic_vector(ram_fit_di'range);
    signal fitness_done : std_logic;

    -- Trainer
    signal trainer_start : std_logic;
    signal trainer_ram_chr_adr : std_logic_vector(ram_chr_adr'range);
    signal trainer_ram_chr_di : std_logic_vector(ram_chr_do'range);
    signal trainer_ram_chr_fit_we : std_logic;
    signal trainer_fitness_start : std_logic;

    -- Kontinuierliche Bestimmung der besten Chromosome
    signal better_chr : std_logic;
    signal next_better_chr : std_logic;

    signal i_best_chr : std_logic_vector(best_chr'range);
    signal next_best_chr : std_logic_vector(best_chr'range);

    signal i_best_chr_fit : unsigned(fitness_fit'range);
    signal next_best_chr_fit : unsigned(fitness_fit'range);

    signal cache_fitness_chr : std_logic_vector(fitness_chr'range);
    signal cache_fitness_fit : unsigned(fitness_fit'range);

begin

    best_chr <= i_best_chr;
    best_chr_fit <= std_logic_vector(i_best_chr_fit);

    -- Startsignale fuer Komponenten
    init_start <= '1' when state = s_init and prev_state /= s_init
        else '0';
    fitness_start <= init_fitness_start or trainer_fitness_start;
    trainer_start <= '1' when state = s_train
        else '0';

    -- Datapoint-RAM-Signale
    ram_dp_we <= dp_we;
    ram_dp_adr <= dp_adr when state = s_ready
        else fitness_ram_dp_adr;
    gen_ram_dp_inputs: for i in 0 to var_num generate
        ram_dp_di(i) <= dp_data;
    end generate;

    -- Chromosom-RAM-Signale
    fitness_chr <= init_ram_chr_di when state = s_init
        else trainer_ram_chr_di;
    ram_chr_we <= init_ram_chr_fit_we or trainer_ram_chr_fit_we;
    ram_chr_adr <= init_ram_chr_adr when state = s_init
        else trainer_ram_chr_adr;
    gen_ram_chr_di: for i in 0 to var_num generate
        ram_chr_di(i) <= flat_vec(init_ram_chr_di, fp_size, i) when state = s_init
            else flat_vec(trainer_ram_chr_di, fp_size, i);
    end generate;

    -- Fitness-RAM-Signale
    ram_fit_we <= init_ram_chr_fit_we or trainer_ram_chr_fit_we;
    ram_fit_adr <= ram_chr_adr;
    ram_fit_di <= fitness_fit;

    -- RAMs fuer Datenpunkte
    -- 0 => Expected, 1 => Feature 1, ..., var_num => Feature var_num
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

    -- RAMs fuer Chromosome
    -- 0 => theta_0 (constant), 1 => theta_1 (linear), ..., var_num => theta_var_num (linear)
    gen_ram_chr: for i in 0 to var_num generate
        ram_chr: entity work.ram
            generic map(
                adr_size => chr_adr_size,
                data_size => fp_size
            )
            port map(
                clk => clk,
                we => ram_chr_we,
                adr => ram_chr_adr,
                di => ram_chr_di(i),
                do => ram_chr_do(flat_upper(fp_size, i) downto flat_lower(fp_size, i))
            );
    end generate;

    -- RAM fuer Fitness-Werte der Chromosome (identische Adresse)
    ram_fit: entity work.ram
        generic map(
            adr_size => chr_adr_size,
            data_size => fit_size
        )
        port map(
            clk => clk,
            we => ram_fit_we,
            adr => ram_fit_adr,
            di => ram_fit_di,
            do => ram_fit_do
        );

    -- Fitness-Funktion (von pop_init und trainer genutzt)
    fitness_linreg: entity work.fitness_linreg
        generic map(
            var_num => var_num,
            fp_size => fp_size,
            fp_frac => fp_frac,
            fit_size => fit_size,
            adr_size => dp_adr_size,
            square => square
        )
        port map(
            clk => clk,
            rst => rst,
            start => fitness_start,
            chr => fitness_chr,
            dp_end_adr => dp_end_adr,
            ram_dp_do => ram_dp_do,
            ram_dp_adr => fitness_ram_dp_adr,
            fit => fitness_fit,
            done => fitness_done
        );

    -- Populations-Initialisierung
    pop_init: entity work.pop_init
        generic map (
            var_num => var_num,
            fp_size => fp_size,
            adr_size => chr_adr_size
        )
        port map (
            clk => clk,
            rst => rst,
            start => init_start,
            fitness_done => fitness_done,
            ram_chr_fit_we => init_ram_chr_fit_we,
            ram_chr_adr => init_ram_chr_adr,
            ram_chr_di => init_ram_chr_di,
            fitness_start => init_fitness_start,
            done => init_done
        );

    -- Trainer (Durchfuehrung des genetischen Algorithmus)
    trainer: entity work.trainer
        generic map(
            mask_factor => mask_factor,
            k_sel => k_sel,
            k_rep => k_rep,
            var_num => var_num,
            fp_size => fp_size,
            fit_size => fit_size,
            chr_adr_size => chr_adr_size,
            replace_with_worse => replace_with_worse,
            mut_arith => mut_arith
        )
        port map(
            clk => clk,
            rst => rst,
            start => trainer_start,
            fitness_done => fitness_done,
            fitness_fit => fitness_fit,
            ram_fit_do => ram_fit_do,
            ram_chr_do => ram_chr_do,
            ram_chr_adr => trainer_ram_chr_adr,
            ram_chr_di => trainer_ram_chr_di,
            ram_chr_fit_we => trainer_ram_chr_fit_we,
            fitness_start => trainer_fitness_start
        );

    next_state <= s_ready when rst = '1'
        else s_init when state = s_ready and start = '1'
        else s_train when state = s_init and init_done = '1'
        else state;

    next_dp_end_adr <= dp_adr when mark_end = '1'
        else dp_end_adr;

    -- zusaetzlicher Vergleich mit Fitness in Cache/Pipeline notwendig (koennte besser sein)
    next_better_chr <= '1' when fitness_done = '1' and unsigned(fitness_fit) <= i_best_chr_fit and unsigned(fitness_fit) <= cache_fitness_fit
        else '0';
    
    next_best_chr <= cache_fitness_chr when better_chr = '1' or state = s_init
        else i_best_chr;

    next_best_chr_fit <= cache_fitness_fit when better_chr = '1' or state = s_init
        else i_best_chr_fit;

    process (clk)
    begin
        if rising_edge(clk) then
            prev_state <= state;
            state <= next_state;
            dp_end_adr <= next_dp_end_adr;
            better_chr <= next_better_chr;
            i_best_chr <= next_best_chr;
            i_best_chr_fit <= next_best_chr_fit;

            if fitness_done = '1' then
                cache_fitness_chr <= fitness_chr;
                cache_fitness_fit <= unsigned(fitness_fit);
            end if;
        end if;
    end process;

end architecture;