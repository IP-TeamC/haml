library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

use work.pkg_sudoku.all;

entity ga_sudoku_mid_tb is
end entity;

architecture rtl of ga_sudoku_mid_tb is

    constant clk_period : time := 10 ns;

    constant chr_size : natural := 324;
    constant fp_size : natural := 8;

    constant pop_size : natural := 128;
    constant k : natural := 2;
    constant mut_bits : natural := 2;

    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal start : std_logic := '0';

    signal const : std_logic_vector(chr_size-1 downto 0) := (others => '0');
    signal const_mask : std_logic_vector(chr_size-1 downto 0);

    signal best_chr : std_logic_vector(chr_size-1 downto 0);
    signal best_fit : std_logic_vector(fp_size-1 downto 0);
    signal done : std_logic;

begin

    uut: entity work.ga_sudoku
        generic map(
            fp_size => fp_size,
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
            const_mask => const_mask,
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
            (0,0,0, 2,0,3, 8,0,5),
            (1,4,0, 0,0,0, 0,3,9),
            (5,0,3, 0,0,0, 0,0,0),
            (4,0,0, 3,0,0, 0,9,1),
            (0,0,0, 0,0,4, 7,2,0),
            (6,2,5, 9,0,0, 0,4,0),
            (0,3,0, 5,0,6, 2,0,0),
            (0,0,6, 0,0,0, 0,0,0),
            (2,0,0, 0,0,0, 0,0,0)
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

    -- Kombinatorischer Prozess für die Maske
    process(const)
        variable cell_val : std_logic_vector(cell_bits-1 downto 0);
    begin
        for i in 0 to (sudoku_size * sudoku_size) - 1 loop
            cell_val := const(cell_bits*(i+1)-1 downto cell_bits*i);

            if cell_val = std_logic_vector(to_unsigned(0, cell_bits)) then
                -- Freies Feld -> Darf vom GA verändert werden (Maske = 0)
                const_mask(cell_bits*(i+1)-1 downto cell_bits*i) <= (others => '0');
            else
                -- Fest vorgegebenes Feld -> Gesperrt für GA (Maske = 1)
                const_mask(cell_bits*(i+1)-1 downto cell_bits*i) <= (others => '1');
            end if;
        end loop;
    end process;

end architecture rtl;