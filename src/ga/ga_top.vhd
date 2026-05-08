library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.prng.all;

entity ga_top is
    generic (
        chr_size : natural := 324; -- Chromosombreite
        fp_size : natural := 8; -- Fitnessbreite
        pop_size : natural := 64; -- Anzahl der Individuen
        k : natural := 4; -- Tournament Size
        mut_bits : natural := 7; -- Mutationswahrscheinlichkeit: P(mutation) = 0.5^mut_bits
        max_gen : natural := 10000 -- Maximale Generationen
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        -- Problemkonstante (immutable)
        const : in std_logic_vector(chr_size-1 downto 0);

        -- Ergebnis
        -- best_chr : out std_logic;
        best_chr : out std_logic_vector(chr_size-1 downto 0);
        best_fit : out std_logic_vector(fp_size-1 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of ga_top is
    constant idx_size : natural := natural(ceil(log2(real(pop_size))));
    constant k_idx_size : natural := natural(ceil(log2(real(k*2))));
    constant cx_size : natural := natural(ceil(log2(real(chr_size))));

    constant rnd_sel_bits : natural := idx_size * k * 2;
    constant rnd_cx_bits : natural := cx_size;
    constant rnd_mut_bits : natural := chr_size * mut_bits;
    constant rnd_total : natural := rnd_sel_bits + rnd_cx_bits + rnd_mut_bits;
    constant lfsr_n : natural := natural(ceil(real(rnd_total) / 32.0));
    constant rnd_padded : natural := lfsr_n * 32;

    signal rnd : std_logic_vector(rnd_padded-1 downto 0);

    -- population_mem 
    signal rd_idx : std_logic_vector(idx_size-1 downto 0);
    signal rd_chr : std_logic_vector(chr_size-1 downto 0);
    signal rd_fit : std_logic_vector(fp_size-1 downto 0);

    signal wr_en : std_logic;
    signal wr_idx : std_logic_vector(idx_size-1 downto 0);
    signal wr_chr : std_logic_vector(chr_size-1 downto 0);
    signal wr_fit : std_logic_vector(fp_size-1 downto 0);

    -- fitness
    signal fit_start : std_logic;
    signal fit_chr : std_logic_vector(chr_size-1 downto 0);
    signal fit_val : std_logic_vector(fp_size-1 downto 0);
    signal fit_done : std_logic;

    -- selection_unit
    signal sel_start : std_logic;
    signal sel_fit_we : std_logic;
    signal sel_fit_idx : std_logic_vector(k_idx_size-1 downto 0);
    signal sel_fit_in : std_logic_vector(fp_size-1 downto 0);
    signal sel_idx_a : std_logic_vector(idx_size-1 downto 0);
    signal sel_idx_b : std_logic_vector(idx_size-1 downto 0);
    signal sel_done : std_logic;

    -- crossover_mutation
    signal cx_start : std_logic;
    signal cx_chr_a : std_logic_vector(chr_size-1 downto 0);
    signal cx_chr_b : std_logic_vector(chr_size-1 downto 0);
    signal cx_child_a : std_logic_vector(chr_size-1 downto 0);
    signal cx_child_b : std_logic_vector(chr_size-1 downto 0);
    signal cx_done : std_logic;

    -- signal l_done : std_logic;
    -- signal l_best_chr : std_logic_vector(chr_size-1 downto 0);

    -- signal s_best_chr : std_logic_vector(chr_size-1 downto 0);

begin

    -- best_chr <= s_best_chr(chr_size-1);
    
    -- process(clk)
    -- begin
    --     if rising_edge(clk) then
    -- 
    --         s_best_chr(chr_size-1 downto 1) <= s_best_chr(chr_size-2 downto 0);
    --         
    --         if l_done = '1' then
    --             s_best_chr <= l_best_chr;
    --         end if;
    -- 
    -- 
    --     end if;
    -- end process;

    -- Zufallsgenerator
    rng: entity work.rng_bank
        generic map(
            degree => 32,
            n => lfsr_n
        )
        port map(
            clk => clk,
            rst => rst,
            rand => rnd
        );

    -- Populationsspeicher
    pop_mem: entity work.population_mem
        generic map(
            chr_size => chr_size,
            fp_size => fp_size,
            pop_size => pop_size
        )
        port map(
            clk => clk,
            rd_idx => rd_idx,
            rd_chr => rd_chr,
            wr_en => wr_en,
            wr_idx => wr_idx,
            wr_chr => wr_chr,
            wr_fit => wr_fit
        );

    -- Fitness
    fit: entity work.fitness
        generic map(
            chr_size => chr_size,
            const_size => chr_size,
            fp_size => fp_size,
            fp_frac => 0,
            data_size => 1
        )
        port map(
            clk => clk,
            rst => rst,
            start => fit_start,
            chr => fit_chr,
            const => const,
            di => "0",
            do => open,
            fit => fit_val,
            done => fit_done
        );

    -- Selektion
    -- rnd[rnd_sel_bits-1 : 0] reserviert fr Kandidatenindizes
    sel: entity work.selection_unit
        generic map(
            fp_size => fp_size,
            pop_size => pop_size,
            k => k
        )
        port map(
            clk => clk,
            rst => rst,
            start => sel_start,
            rnd => rnd(rnd_sel_bits-1 downto 0),
            fit_we => sel_fit_we,
            fit_idx => sel_fit_idx,
            fit_in => sel_fit_in,
            idx_a => sel_idx_a,
            idx_b => sel_idx_b,
            done => sel_done
        );

    -- Crossover + Mutation
    -- rnd[sel+cx-1 : sel] (Crossover-Punkt)
    -- rnd[sel+cx+mut-1 : sel+cx] (Mutationsmaske)
    cx: entity work.crossover_mutation
        generic map(
            chr_size => chr_size,
            mut_bits => mut_bits
        )
        port map(
            clk => clk,
            rst => rst,
            start => cx_start,
            chr_a => cx_chr_a,
            chr_b => cx_chr_b,
            rnd_cx => rnd(rnd_sel_bits + rnd_cx_bits - 1 downto rnd_sel_bits),
            rnd_mut => rnd(rnd_sel_bits + rnd_cx_bits + rnd_mut_bits - 1 downto rnd_sel_bits + rnd_cx_bits),
            child_a => cx_child_a,
            child_b => cx_child_b,
            done => cx_done
        );

    -- Controller
    ctrl: entity work.ga_controller
        generic map(
            chr_size => chr_size,
            fp_size => fp_size,
            pop_size => pop_size,
            k => k,
            max_gen => max_gen
        )
        port map(
            clk => clk,
            rst => rst,
            start => start,
            const => const,
            -- population_mem
            rd_idx => rd_idx,
            rd_chr => rd_chr,
            rd_fit => rd_fit,
            wr_en => wr_en,
            wr_idx => wr_idx,
            wr_chr => wr_chr,
            wr_fit => wr_fit,
            -- fitness
            fit_start => fit_start,
            fit_chr => fit_chr,
            fit_val => fit_val,
            fit_done => fit_done,
            -- selection_unit
            sel_start => sel_start,
            sel_fit_we => sel_fit_we,
            sel_fit_idx => sel_fit_idx,
            sel_fit_in => sel_fit_in,
            sel_idx_a => sel_idx_a,
            sel_idx_b => sel_idx_b,
            sel_done => sel_done,
            -- crossover_mutation
            cx_start => cx_start,
            cx_chr_a => cx_chr_a,
            cx_chr_b => cx_chr_b,
            cx_child_a => cx_child_a,
            cx_child_b => cx_child_b,
            cx_done => cx_done,
            -- Ergebnis
            -- best_chr => l_best_chr,
            best_chr => best_chr,
            best_fit => best_fit,
            -- done => l_done
            done => done
        );
    -- done <= l_done;

end architecture;