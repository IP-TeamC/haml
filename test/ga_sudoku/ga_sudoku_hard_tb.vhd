library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

use work.pkg_sudoku.all;

entity ga_sudoku_hard_tb is
end entity;

architecture rtl of ga_sudoku_hard_tb is

    constant clk_period : time := 15 ns;

    constant pop_size : natural := 2048;
    constant k : natural := 2;
    constant mut_bits : natural := 1;
    
    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal start : std_logic := '0';

    signal const : std_logic_vector(chr_size-1 downto 0) := (others => '0');

    signal best_chr : std_logic_vector(chr_size-1 downto 0);
    signal best_fit : std_logic_vector(fit_size-1 downto 0);
    signal done : std_logic;

begin

    uut: entity work.ga_sudoku
        generic map(
            pop_size => pop_size,
            k => k,
            mut_bits => mut_bits,
            max_gen => 10000
        )
        port map(
            clk => clk,
            rst => rst,
            start => start,
            const => const,
            best_chr => best_chr,
            best_fit => best_fit,
            done => done
        );

    clk_process : process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    stim_proc : process
        variable hs_unsolved : t_human_sudoku;
        variable chr_const : std_logic_vector(chr_size-1 downto 0);
        variable sol : t_human_sudoku;
    begin
        hs_unsolved := (
            (0,0,0, 6,3,0, 4,0,0),
            (6,0,9, 0,0,8, 2,0,0),
            (0,5,0, 0,2,0, 0,0,0),
            (0,0,2, 0,0,0, 0,9,7),
            (0,0,0, 0,0,0, 0,0,0),
            (4,3,0, 0,0,0, 6,0,0),
            (0,0,0, 0,7,0, 0,5,0),
            (0,0,6, 3,0,0, 7,0,2),
            (0,0,3, 0,9,5, 0,0,0)
        );
        
        chr_const := serialize_sudoku(hs_unsolved);
        const <= chr_const;
        
        wait for 1 ns; 

        -- Reset
        rst <= '1';
        wait for 5 * clk_period;
        rst <= '0';
        
        wait until falling_edge(clk);
        assert done = '0' report "Fehler: Core meldet 'done' direkt nach dem Reset!" severity error;

        -- Start-Puls
        start <= '1';
        wait for clk_period;
        start <= '0';

        -- Warten auf das Ende der Berechnung
        wait until done = '1';

        -- Ergebnis-Auswertung
        report "GA finished after execution.";
        report "Best fitness: " & integer'image(to_integer(unsigned(best_fit)));

        if unsigned(best_fit) = 0 then
            report "*** Sudoku SOLVED! ***" severity note;
        else
            report "No perfect solution found." severity warning;
        end if;

        sol := deserialize_sudoku(best_chr);
        print_sudoku(sol);

        wait;
    end process;

end architecture rtl;