library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity selection_unit is
    generic (
        fp_size : natural := 8; -- Fitnessbreite
        pop_size : natural := 64; -- Anzahl der Individuen
        k : natural := 4 -- Tournament Size
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        -- Zufallszahlen für Kandidatenauswahl
        rnd : in std_logic_vector(natural(ceil(log2(real(pop_size))))*k*2-1 downto 0);

        -- Fitnesswerte
        fit_we : in std_logic;
        fit_idx : in std_logic_vector(natural(ceil(log2(real(k*2))))-1 downto 0);
        fit_in : in std_logic_vector(fp_size-1 downto 0);

        -- Ergebnis (Indizes der beiden Gewinner)
        idx_a : out std_logic_vector(natural(ceil(log2(real(pop_size))))-1 downto 0);
        idx_b : out std_logic_vector(natural(ceil(log2(real(pop_size))))-1 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of selection_unit is
    constant idx_size   : natural := natural(ceil(log2(real(pop_size))));

    type t_candidates is array (0 to k*2-1) of std_logic_vector(idx_size-1 downto 0); -- k*2 Kandidatenindizes aus rnd-Bus extrahiert
    type t_fitness is array (0 to k*2-1) of std_logic_vector(fp_size-1 downto 0); -- k*2 Fitnesswerte

    signal candidates : t_candidates;
    signal fitness : t_fitness;

    type t_state is (S_IDLE, S_TOURNAMENT, S_DONE);
    signal state : t_state;

    signal winner_a : std_logic_vector(idx_size-1 downto 0);
    signal winner_b : std_logic_vector(idx_size-1 downto 0);
    signal best_fit_a : std_logic_vector(fp_size-1 downto 0);
    signal best_fit_b : std_logic_vector(fp_size-1 downto 0);
    signal ctr : natural range 0 to k-1;
begin

    -- Kandidatenindizes aus rnd-Bus extrahieren
    gen_candidates: for i in 0 to k*2-1 generate
        candidates(i) <= rnd(idx_size*(i+1)-1 downto idx_size*i);
    end generate;

    -- Fitnesswerte einschreiben
    process(clk)
    begin
        if rising_edge(clk) then
            if fit_we = '1' then
                fitness(to_integer(unsigned(fit_idx))) <= fit_in;
            end if;
        end if;
    end process;

    -- Tournament-FSM
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= S_IDLE;
                done <= '0';
                ctr <= 0;
            else
                done <= '0';
                case state is

                    when S_IDLE =>
                        if start = '1' then
                            best_fit_a <= (others => '1');
                            best_fit_b <= (others => '1');
                            ctr <= 0;
                            state <= S_TOURNAMENT;
                        end if;

                    when S_TOURNAMENT =>
                        -- Eltern A: Kandidaten 0 bis k-1
                        if unsigned(fitness(ctr)) < unsigned(best_fit_a) then
                            best_fit_a <= fitness(ctr);
                            winner_a <= candidates(ctr);
                        end if;
                        -- Eltern B: Kandidaten k bis 2k-1
                        if unsigned(fitness(ctr+k)) < unsigned(best_fit_b) then
                            best_fit_b <= fitness(ctr+k);
                            winner_b <= candidates(ctr+k);
                        end if;

                        if ctr = k-1 then
                            state <= S_DONE;
                        else
                            ctr <= ctr + 1;
                        end if;

                    when S_DONE =>
                        idx_a <= winner_a;
                        idx_b <= winner_b;
                        done <= '1';
                        state <= S_IDLE;

                    when others =>
                        state <= S_IDLE;
                end case;
            end if;
        end if;
    end process;

end architecture;