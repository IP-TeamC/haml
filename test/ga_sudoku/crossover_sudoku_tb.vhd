library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_sudoku.all;

entity crossover_sudoku_tb is
-- Testbench hat keine Ports
end entity;

architecture sim of crossover_sudoku_tb is

    -- Signale zur UUT
    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';
    signal start       : std_logic := '0';
    signal const_mask  : std_logic_vector(chr_size-1 downto 0) := (others => '0');
    signal parent_a    : std_logic_vector(chr_size-1 downto 0) := (others => '0');
    signal parent_b    : std_logic_vector(chr_size-1 downto 0) := (others => '0');
    signal rnd_blk     : std_logic_vector(blocks_per_side*blocks_per_side-1 downto 0) := (others => '0');
    signal child_a     : std_logic_vector(chr_size-1 downto 0);
    signal child_b     : std_logic_vector(chr_size-1 downto 0);
    signal done        : std_logic;

    -- 100 MHz Systemtakt
    constant clk_period : time := 10 ns;

    -- Test-Muster-Definitionen
    constant grid_mask : t_human_sudoku := (
        (5,3,0, 0,7,0, 0,0,0),
        (6,0,0, 1,9,5, 0,0,0),
        (0,9,8, 0,0,0, 0,6,0),
        (8,0,0, 0,6,0, 0,0,3),
        (4,0,0, 8,0,3, 0,0,1),
        (7,0,0, 0,2,0, 0,0,6),
        (0,6,0, 0,0,0, 2,8,0),
        (0,0,0, 4,1,9, 0,0,5),
        (0,0,0, 0,8,0, 0,7,9)
    );

    constant grid_a : t_human_sudoku := (
        (5,3,1, 1,7,1, 1,1,1),
        (6,1,1, 1,9,5, 1,1,1),
        (1,9,8, 1,1,1, 1,6,1),
        (8,1,1, 1,6,1, 1,1,3),
        (4,1,1, 8,1,3, 1,1,1),
        (7,1,1, 1,2,1, 1,1,6),
        (1,6,1, 1,1,1, 2,8,1),
        (1,1,1, 4,1,9, 1,1,5),
        (1,1,1, 1,8,1, 1,7,9)
    );

    constant grid_b : t_human_sudoku := (
        (5,3,2, 2,7,2, 2,2,2),
        (6,2,2, 1,9,5, 2,2,2),
        (2,9,8, 2,2,2, 2,6,2),
        (8,2,2, 2,6,2, 2,2,3),
        (4,2,2, 8,2,3, 2,2,2),
        (7,2,2, 2,2,2, 2,2,6),
        (2,6,2, 2,2,2, 2,8,2),
        (2,2,2, 4,1,9, 2,2,5),
        (2,2,2, 2,8,2, 2,7,9)
    );

begin

    uut: entity work.crossover_sudoku
        port map (
            clk => clk,
            rst => rst,
            start => start,
            const_mask => const_mask,
            parent_a => parent_a,
            parent_b => parent_b,
            rnd_blk => rnd_blk,
            child_a => child_a,
            child_b => child_b,
            done => done
        );

    -- Taktgenerator
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimuli
    stim_proc: process
    begin
        -- Reset
        rst <= '1';
        start <= '0';
        wait for clk_period * 2;
        rst <= '0';
        wait for clk_period;

        -- Daten vorbereiten
        const_mask <= serialize_sudoku(grid_mask);
        parent_a <= serialize_sudoku(grid_a);
        parent_b <= serialize_sudoku(grid_b);
        rnd_blk <= "100010011"; -- Crossover-Muster
        wait for clk_period;

        -- Start
        start <= '1';
        wait for clk_period;
        start <= '0';

        -- Warten bis fertig
        wait until rising_edge(clk) and done = '1';
        
        wait for 1 ns; 

        report "=== ERGEBNIS KIND A ===";
        print_sudoku(deserialize_sudoku(child_a));
        
        report "=== ERGEBNIS KIND B ===";
        print_sudoku(deserialize_sudoku(child_b));

        -- Erneuter Durchlauf mit anderem Crossover-Muster
        wait for clk_period * 2;
        rnd_blk <= "011101100";
        wait for clk_period;

        start <= '1';
        wait for clk_period;
        start <= '0';

        wait until rising_edge(clk) and done = '1';
        wait for 1 ns;

        report "=== NEUES ERGEBNIS KIND A (Zweiter Durchlauf) ===";
        print_sudoku(deserialize_sudoku(child_a));

        report "--- Simulation erfolgreich beendet ---";
        wait;
    end process;

end architecture;