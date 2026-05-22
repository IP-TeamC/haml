library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ga_pkg.all;

entity mutation_sudoku_tb is
end entity;

architecture sim of mutation_sudoku_tb is

    constant TEST_MUT_BITS : natural := 4;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal start : std_logic := '0';
    
    signal const_mask : std_logic_vector(chr_size-1 downto 0) := (others => '0');
    signal chr_in : std_logic_vector(chr_size-1 downto 0) := (others => '0');
    signal chr_out : std_logic_vector(chr_size-1 downto 0);
    
    signal rnd_gate : std_logic_vector(TEST_MUT_BITS-1 downto 0) := (others => '0');
    signal rnd_blk : std_logic_vector(3 downto 0) := (others => '0');
    signal rnd_pos_a : std_logic_vector(3 downto 0) := (others => '0');
    signal rnd_pos_b : std_logic_vector(3 downto 0) := (others => '0');
    
    signal done : std_logic;

    -- 100 MHz Takt (10 ns Periode)
    constant clk_period : time := 10 ns;

    -- Maske
    constant grid_mask : t_human_sudoku := (
        (5,3,0,  0,0,0,  0,0,0),
        (0,0,0,  0,0,0,  0,0,0),
        (0,0,0,  0,0,0,  0,0,0),
        
        (0,0,0,  0,0,0,  0,0,0),
        (0,0,0,  0,0,0,  0,0,0),
        (0,0,0,  0,0,0,  0,0,0),
        
        (0,0,0,  0,0,0,  0,0,0),
        (0,0,0,  0,0,0,  0,0,0),
        (0,0,0,  0,0,0,  0,0,0)
    );

    -- Individuum vor der Mutation
    constant grid_in : t_human_sudoku := (
        (5,3,1,  0,0,0,  0,0,0),
        (2,4,6,  0,0,0,  0,0,0),
        (7,8,9,  0,0,0,  0,0,0),
        
        (0,0,0,  0,0,0,  0,0,0),
        (0,0,0,  0,0,0,  0,0,0),
        (0,0,0,  0,0,0,  0,0,0),
        
        (0,0,0,  0,0,0,  0,0,0),
        (0,0,0,  0,0,0,  0,0,0),
        (0,0,0,  0,0,0,  0,0,0)
    );  

begin

    uut: entity work.mutation_sudoku
        generic map (
            mut_bits => TEST_MUT_BITS
        )
        port map (
            clk => clk,
            rst => rst,
            start => start,
            const_mask => const_mask,
            chr_in => chr_in,
            chr_out => chr_out,
            rnd_gate => rnd_gate,
            rnd_blk => rnd_blk,
            rnd_pos_a => rnd_pos_a,
            rnd_pos_b => rnd_pos_b,
            done => done
        );

    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimuli-Prozess
    stim_proc: process
    begin
        -- 1. Reset
        rst  <= '1';
        start <= '0';
        wait for clk_period * 2;
        rst <= '0';
        wait for clk_period;

        const_mask <= serialize_sudoku(grid_mask);
        chr_in <= serialize_sudoku(grid_in);
        wait for clk_period;

        -- =====================================================================
        -- TEST 1: Erfolgreiche Mutation (Tausch zweier freier Zellen)
        -- Ziel: Im Block 0 (oben links) Position 2 (Wert 1) mit Position 5 (Wert 6) tauschen.
        -- =====================================================================
        report "--- TEST 1: Starte gueltige Mutation ---";
        rnd_gate <= (others => '1'); -- Mutation erzwingen
        rnd_blk <= "0000"; -- Block 0 wählen
        rnd_pos_a <= "0010"; -- Position 2 (Zelle (0,2) -> Wert 1)
        rnd_pos_b <= "0101"; -- Position 5 (Zelle (1,2) -> Wert 6)
        
        start <= '1';
        wait for clk_period;
        start <= '0';

        wait until rising_edge(clk) and done = '1';
        wait for 1 ns;

        report "=== SUDOKU VOR MUTATION ===";
        print_sudoku(deserialize_sudoku(chr_in));
        report "=== SUDOKU NACH MUTATION 1 (Sollte Position 2 und 5 getauscht haben) ===";
        print_sudoku(deserialize_sudoku(chr_out));

        -- =====================================================================
        -- TEST 2: Keine Mutation (rnd_gate = 0)
        -- =====================================================================
        wait for clk_period * 2;
        report "--- TEST 2: Tor geschlossen (rnd_gate /= 1) -> Keine Aenderung ---";
        rnd_gate <= "0110";
        rnd_blk <= "0000";
        rnd_pos_a <= "0010";
        rnd_pos_b <= "0101";

        start <= '1';
        wait for clk_period;
        start <= '0';

        wait until rising_edge(clk) and done = '1';
        wait for 1 ns;

        report "=== ERGEBNIS TEST 2 (Sollte identisch zum Eingang sein) ===";
        print_sudoku(deserialize_sudoku(chr_out));

        -- =====================================================================
        -- TEST 3: Blockiert durch feste Zelle (Zelle darf sich nicht verändern)
        -- Ziel: Tausch von Position 0 (Wert 5, FEST!) mit Position 8 (Wert 9, FREI)
        -- =====================================================================
        wait for clk_period * 2;
        report "--- TEST 3: Tauschversuch mit einer fixierten Zelle (Konstante) -> Abbruch erwartet ---";
        rnd_gate <= (others => '1'); -- Mutation erzwingen
        rnd_blk <= "0000"; -- Block 0
        rnd_pos_a <= "0000"; -- Position 0 (Wert 5 -> FEST laut Maske!)
        rnd_pos_b <= "1000"; -- Position 8 (Wert 9 -> Frei)

        start <= '1';
        wait for clk_period;
        start <= '0';

        wait until rising_edge(clk) and done = '1';
        wait for 1 ns;

        report "=== ERGEBNIS TEST 3 (Sollte unveraendert geblieben sein) ===";
        print_sudoku(deserialize_sudoku(chr_out));

        report "--- Simulation der Mutation erfolgreich beendet ---";
        wait;
    end process;

end architecture;