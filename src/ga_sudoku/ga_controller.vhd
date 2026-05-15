library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.ga_pkg.all;

entity ga_controller is
    generic (
        chr_size : natural := 324; -- Chromosombreite
        fp_size : natural := 8; -- Fitnessbreite
        pop_size : natural := 64; -- Anzahl der Individuen
        k : natural := 4; -- Tournament Size
        max_gen : natural := 100 -- Maximale Generationen
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        const : in std_logic_vector(chr_size-1 downto 0);

        -- population_mem
        rd_idx : out std_logic_vector(natural(ceil(log2(real(pop_size))))-1 downto 0);
        rd_chr : in std_logic_vector(chr_size-1 downto 0);
        rd_fit : in std_logic_vector(fp_size-1 downto 0);

        wr_en : out std_logic;
        wr_idx : out std_logic_vector(natural(ceil(log2(real(pop_size))))-1 downto 0);
        wr_chr : out std_logic_vector(chr_size-1 downto 0);
        wr_fit : out std_logic_vector(fp_size-1 downto 0);

        -- fitness
        fit_start : out std_logic;
        fit_chr : out std_logic_vector(chr_size-1 downto 0);
        fit_val : in std_logic_vector(fp_size-1 downto 0);
        fit_done : in std_logic;

        -- selection_unit
        sel_start : out std_logic;
        sel_fit_we : out std_logic;
        sel_fit_idx : out std_logic_vector(natural(ceil(log2(real(k*2))))-1 downto 0);
        sel_fit_in : out std_logic_vector(fp_size-1 downto 0);
        sel_idx_a : in std_logic_vector(natural(ceil(log2(real(pop_size))))-1 downto 0);
        sel_idx_b : in std_logic_vector(natural(ceil(log2(real(pop_size))))-1 downto 0);
        sel_done : in std_logic;

        -- crossover_mutation
        cx_start : out std_logic;
        cx_chr_a : out std_logic_vector(chr_size-1 downto 0);
        cx_chr_b : out std_logic_vector(chr_size-1 downto 0);
        cx_child_a : in std_logic_vector(chr_size-1 downto 0);
        cx_child_b : in std_logic_vector(chr_size-1 downto 0);
        cx_done : in std_logic;

        -- Ergebnis
        best_chr : out std_logic_vector(chr_size-1 downto 0);
        best_fit : out std_logic_vector(fp_size-1 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of ga_controller is
    constant idx_size : natural := natural(ceil(log2(real(pop_size))));
    constant k_idx_size : natural := natural(ceil(log2(real(k*2))));
    constant gen_size : natural := natural(ceil(log2(real(max_gen+1))));

    type t_state is (
        S_IDLE,

        -- Initialisierung
        S_INIT_POP,

        -- Evaluation
        S_EVAL_READ,
        S_EVAL_READ_WAIT,
        S_EVAL_FIT_WAIT,
        S_EVAL_WRITE,

        -- Check
        S_CHECK,

        -- Elitismus
        S_REPR_WRITE_ELITE,

        -- Selektion
        S_SEL_READ,
        S_SEL_READ_WAIT,
        S_SEL_LOAD,
        S_SEL_START,
        S_SEL_WAIT,

        -- Reproduktion
        S_REPR_READ_A,
        S_REPR_READ_A_WAIT,
        S_REPR_READ_B,
        S_REPR_READ_B_WAIT,
        S_REPR_CX_WAIT,
        S_REPR_WRITE_A,
        S_REPR_WRITE_B,

        S_DONE
    );
    signal state : t_state; -- Aktueller Zustand (Moore-Automat)

    signal eval_ctr : unsigned(idx_size-1 downto 0); -- Zähler für das aktuell zu bewertende Individuum
    signal repr_ctr : unsigned(idx_size-1 downto 0); -- Zähler für den Schreibindex der neuen Kinder
    signal sel_ctr : unsigned(k_idx_size-1 downto 0); -- Zähler für die k*2 Kandidaten, die in die selection_unit geladen werden
    signal gen_ctr : unsigned(gen_size-1 downto 0); -- Generationenzähler

    signal chr_a_buf : std_logic_vector(chr_size-1 downto 0); -- Zwischenpuffer für Chromosom von Eltern A
    signal idx_a_buf : std_logic_vector(idx_size-1 downto 0); -- RAM-Index des Turniersiegers A
    signal idx_b_buf : std_logic_vector(idx_size-1 downto 0); -- RAM-Index des Turniersiegers B
    signal last_chr : std_logic_vector(chr_size-1 downto 0); -- zuletzt gelesene Chromosom
    signal last_fit : std_logic_vector(fp_size-1 downto 0); -- zuletzt berechneter Fitnesswert

    signal best_fit_r : std_logic_vector(fp_size-1 downto 0); -- bester Fitnesswert über alle Generationen
    signal best_chr_r : std_logic_vector(chr_size-1 downto 0); -- Chromosom des besten bisher gefundenen Individuums

begin
    best_fit <= best_fit_r;
    best_chr <= best_chr_r;

    process(clk)
    begin
        if rising_edge(clk) then

            wr_en <= '0';
            fit_start <= '0';
            sel_start <= '0';
            sel_fit_we <= '0';
            cx_start <= '0';

            rd_idx <= (others => '0');
            wr_idx <= (others => '0');

            if rst = '1' then
                state <= S_IDLE;
                eval_ctr <= (others => '0');
                repr_ctr <= (others => '0');
                sel_ctr <= (others => '0');
                gen_ctr <= (others => '0');
                best_fit_r <= (others => '1');
                done <= '0';

            else
                case state is

                    -- IDLE
                    -- Warten auf start-Impuls vom Nutzer
                    when S_IDLE =>
                        if start = '1' then
                            eval_ctr <= (others => '0');
                            gen_ctr <= (others => '0');
                            best_fit_r <= (others => '1');
                            state <= S_INIT_POP;
                            done <= '0';
                        end if;

                    -- INIT
                    -- Problem laden
                    when S_INIT_POP =>
                        wr_en  <= '1';
                        wr_idx <= std_logic_vector(repr_ctr);
                        wr_chr <= const;
                        wr_fit <= (others => '1');
                        if repr_ctr = pop_size-1 then
                            repr_ctr <= (others => '0');
                            state <= S_EVAL_READ;
                        else
                            repr_ctr <= repr_ctr + 1;
                        end if;

                    -- EVALUATION
                    -- Jedes Individuum aus RAM lesen, Fitness berechnen, Fitnesswert zurückschreiben
                    when S_EVAL_READ =>
                        rd_idx <= std_logic_vector(eval_ctr);
                        state <= S_EVAL_READ_WAIT;

                    when S_EVAL_READ_WAIT =>
                        -- 1 Takt RAM-Latenz abgewartet,
                        -- Chromosom für Fitness einfrieren
                        last_chr <= rd_chr;
                        fit_chr <= rd_chr;
                        fit_start <= '1';
                        state <= S_EVAL_FIT_WAIT;

                    when S_EVAL_FIT_WAIT =>
                        -- fitness-Modul rechnet und warten bis fit_done='1'
                        if fit_done = '1' then
                            last_fit <= fit_val;
                            state <= S_EVAL_WRITE;
                        end if;

                    when S_EVAL_WRITE =>
                        -- Fitnesswert zurückschreiben
                        wr_en <= '1';
                        wr_idx <= std_logic_vector(eval_ctr);
                        wr_chr <= last_chr;
                        wr_fit <= last_fit;
                        -- Bestes Individuum tracken
                        if unsigned(last_fit) < unsigned(best_fit_r) then
                            best_fit_r <= last_fit;
                            best_chr_r <= last_chr;
                            -- report "[ctrl] Neues Bestes: idx=" & integer'image(to_integer(eval_ctr)) & " fit=" & integer'image(to_integer(unsigned(last_fit))) severity note;
                        end if;
                        -- Alle Individuen bewertet?
                        if eval_ctr = pop_size-1 then
                            state <= S_CHECK;
                        else
                            eval_ctr <= eval_ctr + 1;
                            state <= S_EVAL_READ;
                        end if;

                    -- CHECK
                    -- Abbruchbedingungen prüfen
                    when S_CHECK =>
                        if best_fit_r = (best_fit_r'range => '0') then
                            report "[ctrl] LÖSUNG GEFUNDEN nach " & integer'image(to_integer(gen_ctr)) & " Generationen!" severity note;
                            state <= S_DONE;
                        elsif gen_ctr = max_gen then
                            report "[ctrl] Generationslimit erreicht (" & integer'image(max_gen) & "), bestes fit=" & integer'image(to_integer(unsigned(best_fit_r))) severity warning;
                            state <= S_DONE;
                        else
                            if to_integer(gen_ctr) mod 1 = 0 then -- mod 10
                                report "[ctrl] Generation " & integer'image(to_integer(gen_ctr)) & " best_fit=" & integer'image(to_integer(unsigned(best_fit_r))) severity note;
                                print_sudoku(deserialize_sudoku(best_chr_r));
                            end if;
                            gen_ctr <= gen_ctr + 1;
                            repr_ctr <= to_unsigned(1, idx_size);
                            sel_ctr <= (others => '0');
                            state <= S_REPR_WRITE_ELITE;
                        end if;

                    -- ELITISMUS
                    -- Bestes bekanntes Individuum in Slot 0 der neuen Generation schreiben
                    when S_REPR_WRITE_ELITE =>
                        wr_en <= '1';
                        wr_idx <= (others => '0');
                        wr_chr <= best_chr_r;
                        wr_fit <= best_fit_r;
                        state <= S_SEL_READ;

                    -- SELEKTION
                    -- Fitnesswerte für Kandidaten aus RAM lesen und in selection_unit laden, dann Tournament starten
                    when S_SEL_READ =>
                        -- Erste k Kandidaten für Eltern A, zweite k für Eltern B
                        if to_integer(sel_ctr) < k then
                            rd_idx <= sel_idx_a;
                        else
                            rd_idx <= sel_idx_b;
                        end if;
                        state <= S_SEL_READ_WAIT;

                    when S_SEL_READ_WAIT =>
                        -- 1 Takt RAM-Latenz, rd_fit jetzt gültig
                        state <= S_SEL_LOAD;

                    when S_SEL_LOAD =>
                        -- Fitnesswert in selection_unit schreiben
                        sel_fit_we <= '1';
                        sel_fit_idx <= std_logic_vector(sel_ctr);
                        sel_fit_in <= rd_fit;
                        if sel_ctr = k*2-1 then
                            -- Alle k*2 Fitnesswerte geladen, dann Tournament starten
                            state <= S_SEL_START;
                        else
                            sel_ctr <= sel_ctr + 1;
                            state <= S_SEL_READ;
                        end if;

                    when S_SEL_START =>
                        sel_start <= '1';
                        state <= S_SEL_WAIT;

                    when S_SEL_WAIT =>
                        if sel_done = '1' then
                            -- Gewinner festhalten
                            idx_a_buf <= sel_idx_a;
                            idx_b_buf <= sel_idx_b;
                            state <= S_REPR_READ_A;
                        end if;

                    -- REPRODUKTION
                    when S_REPR_READ_A =>
                        rd_idx <= idx_a_buf;
                        state <= S_REPR_READ_A_WAIT;

                    when S_REPR_READ_A_WAIT =>
                        -- 1 Takt RAM-Latenz, Eltern A jetzt gültig
                        chr_a_buf <= rd_chr;
                        state <= S_REPR_READ_B;

                    when S_REPR_READ_B =>
                        rd_idx <= idx_b_buf;
                        state <= S_REPR_READ_B_WAIT;

                    when S_REPR_READ_B_WAIT =>
                        -- 1 Takt RAM-Latenz, Eltern B jetzt gültig
                        cx_chr_a <= chr_a_buf;
                        cx_chr_b <= rd_chr;
                        -- Beide Eltern geladen, Crossover-Mutation starten
                        cx_start <= '1';
                        state <= S_REPR_CX_WAIT;

                    when S_REPR_CX_WAIT =>
                        -- Warten bis Crossover-Mutation fertig
                        if cx_done = '1' then
                            state <= S_REPR_WRITE_A;
                        end if;

                    when S_REPR_WRITE_A =>
                        -- Kind A in RAM schreiben
                        wr_en <= '1';
                        wr_idx <= std_logic_vector(repr_ctr);
                        wr_chr <= cx_child_a;
                        wr_fit <= (others => '1'); -- ungültig, noch nicht bewertet

                        state <= S_REPR_WRITE_B;

                    when S_REPR_WRITE_B =>
                        -- Kind B in RAM schreiben
                        wr_en <= '1';
                        wr_idx <= std_logic_vector(repr_ctr + 1);
                        wr_chr <= cx_child_b;
                        wr_fit <= (others => '1'); -- ungültig, noch nicht bewertet

                        if repr_ctr >= pop_size-2 then
                            -- Population voll -> neue Generation bewerten
                            eval_ctr <= (others => '0');
                            state <= S_EVAL_READ;
                        else
                            repr_ctr <= repr_ctr + 2;
                            sel_ctr <= (others => '0');
                            state <= S_SEL_READ;
                        end if;

                    -- DONE
                    -- best_chr/best_fit liegen am Ausgang an
                    when S_DONE =>
                        report "[ctrl] GA beendet. best_fit=" & integer'image(to_integer(unsigned(best_fit_r))) severity note;
                        done  <= '1';
                        state <= S_IDLE;

                    when others =>
                        state <= S_IDLE;

                end case;
            end if;
        end if;
    end process;

end architecture;