library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tournament_sel_sudoku_tb is
end entity;

architecture sim of tournament_sel_sudoku_tb is

    constant fp_size : natural := 8;
    constant pop_size : natural := 64;
    constant k : natural := 4;
    
    constant idx_size : natural := natural(ceil(log2(real(POP_SIZE)))); -- = 6 Bit
    constant cand_in_size : natural := idx_size * k * 2; -- = 48 Bit

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal start : std_logic := '0';

    signal cand_in : std_logic_vector(cand_in_size-1 downto 0) := (others => '0');
    signal fit_we : std_logic := '0';
    signal fit_idx : std_logic_vector(natural(ceil(log2(real(K*2))))-1 downto 0) := (others => '0');
    signal fit_in : std_logic_vector(fp_size-1 downto 0) := (others => '0');

    signal idx_a : std_logic_vector(idx_size-1 downto 0);
    signal idx_b : std_logic_vector(idx_size-1 downto 0);
    signal done : std_logic;
    
    type t_integer_array is array (0 to (k*2)-1) of integer;

    function make_cand_vector(indices : t_integer_array) return std_logic_vector is
        variable res : std_logic_vector(cand_in_size-1 downto 0);
    begin
        for i in 0 to k*2-1 loop
            res(idx_size*(i+1)-1 downto idx_size*i) := std_logic_vector(to_unsigned(indices(i), idx_size));
        end loop;
        return res;
    end function;

begin

    uut: entity work.tournament_sel_sudoku
        generic map (
            fp_size => fp_size,
            pop_size => pop_size,
            k => k
        )
        port map (
            clk => clk,
            rst => rst,
            start => start,
            cand_in => cand_in,
            fit_we => fit_we,
            fit_idx => fit_idx,
            fit_in => fit_in,
            idx_a => idx_a,
            idx_b => idx_b,
            done => done
        );

    clk_process: process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    stim_proc: process
    begin
        -- Reset
        rst <= '1';
        wait for CLK_PERIOD * 3;
        rst <= '0';
        wait for CLK_PERIOD;

        -- ---------------------------------------------------------------------
        -- SCHRITT 1: Fitness-Tabelle füllen
        -- ---------------------------------------------------------------------
        report "--- Befuelle Fitnesswerte fuer die Slots ---";
        
        -- Turnierhälfte A (Slots 0..3)
        -- Slot 0: Individuum hat Fit=45
        -- Slot 1: Individuum hat Fit=12 <-- Sollte Gewinner A werden
        -- Slot 2: Individuum hat Fit=89
        -- Slot 3: Individuum hat Fit=23
        
        -- Turnierhälfte B (Slots 4..7)
        -- Slot 4: Individuum hat Fit=70
        -- Slot 5: Individuum hat Fit=55
        -- Slot 6: Individuum hat Fit=19 <-- Sollte Gewinner B werden
        -- Slot 7: Individuum hat Fit=99

        fit_we <= '1';
        
        fit_idx <= "000"; fit_in <= std_logic_vector(to_unsigned(45, fp_size)); wait for CLK_PERIOD;
        fit_idx <= "001"; fit_in <= std_logic_vector(to_unsigned(12, fp_size)); wait for CLK_PERIOD;
        fit_idx <= "010"; fit_in <= std_logic_vector(to_unsigned(89, fp_size)); wait for CLK_PERIOD;
        fit_idx <= "011"; fit_in <= std_logic_vector(to_unsigned(23, fp_size)); wait for CLK_PERIOD;
        
        fit_idx <= "100"; fit_in <= std_logic_vector(to_unsigned(70, fp_size)); wait for CLK_PERIOD;
        fit_idx <= "101"; fit_in <= std_logic_vector(to_unsigned(55, fp_size)); wait for CLK_PERIOD;
        fit_idx <= "110"; fit_in <= std_logic_vector(to_unsigned(19, fp_size)); wait for CLK_PERIOD;
        fit_idx <= "111"; fit_in <= std_logic_vector(to_unsigned(99, fp_size)); wait for CLK_PERIOD;
        
        fit_we <= '0';
        wait for CLK_PERIOD;

        -- ---------------------------------------------------------------------
        -- SCHRITT 2: Selektion starten via RND-Kandidatenindizes
        -- ---------------------------------------------------------------------
        report "--- Starte Turniervorgang ---";
        
        -- Turnier A fordert an: Individuen [5, 42, 17, 29]
        -- Turnier B fordert an: Individuen [8, 61, 33, 14]
        -- Erwartetes Ergebnis laut den Fitnesswerten oben:
        -- Gewinner A muss das Individuum an Slot 1 sein -> Index 42
        -- Gewinner B muss das Individuum an Slot 6 sein -> Index 33
        
        cand_in <= make_cand_vector((5, 42, 17, 29,  8, 61, 33, 14));
        
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

        -- Warten bis fertig gerechnet
        wait until done = '1';
        wait for CLK_PERIOD/2;

        -- Auswertung im Log ausgeben
        report "--- Turnier Beendet! ---";
        report "Gewinner-Index A (erwartet: 42): " & integer'image(to_integer(unsigned(idx_a)));
        report "Gewinner-Index B (erwartet: 33): " & integer'image(to_integer(unsigned(idx_b)));

        -- Überprüfung absichern
        assert to_integer(unsigned(idx_a)) = 42 report "Fehler bei Gewinner A!" severity failure;
        assert to_integer(unsigned(idx_b)) = 33 report "Fehler bei Gewinner B!" severity failure;

        report "--- Test erfolgreich bestanden! ---";
        wait;
    end process;

end architecture;