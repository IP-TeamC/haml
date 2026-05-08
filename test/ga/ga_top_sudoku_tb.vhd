library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

use work.ga_pkg.all;

entity ga_top_sudoku_tb is
end entity;

architecture rtl of ga_top_sudoku_tb is

    constant clk_period : time    := 10 ns;

    constant chr_size   : natural := 324;
    constant fp_size    : natural := 8;
    constant pop_size   : natural := 64;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal start    : std_logic := '0';
    signal const    : std_logic_vector(chr_size-1 downto 0) := (others => '0');

    signal best_chr : std_logic_vector(chr_size-1 downto 0);
    signal best_fit : std_logic_vector(fp_size-1 downto 0);
    signal done     : std_logic;


begin

    uut: entity work.ga_top
        generic map(
            chr_size => chr_size,
            fp_size  => fp_size,
            pop_size => pop_size,
            k        => 4,
            mut_bits => 7,
            max_gen  => 500
        )
        port map(
            clk      => clk,
            rst      => rst,
            start    => start,
            const    => const,
            best_chr => best_chr,
            best_fit => best_fit,
            done     => done
        );

    -- Clock
    clk_process : process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    -- Stimulus
    stim_proc : process
        variable hs_unsolved : t_human_sudoku;
        variable chr_const   : std_logic_vector(chr_size-1 downto 0);
        variable sol         : t_human_sudoku;
        variable row_str     : string(1 to 27);
    begin

        -- Sudoku VOR dem Reset anlegen, damit es beim Start stabil ist
        hs_unsolved := (
            (7,0,0, 5,8,2, 9,3,4),
            (2,0,5, 0,1,9, 0,0,7),
            (0,0,3, 0,0,0, 2,0,1),
            (0,3,7, 1,0,6, 4,2,5),
            (4,9,0, 7,0,0, 0,1,0),
            (0,5,2, 0,3,8, 7,0,0),
            (0,2,0, 0,5,7, 1,9,6),
            (5,7,9, 2,6,0, 0,0,3),
            (6,0,0, 0,4,3, 5,7,2)
        );
        chr_const := serialize_sudoku(hs_unsolved);
        const <= chr_const;
        print_sudoku(hs_unsolved);

        -- Reset
        rst   <= '1';
        start <= '0';
        wait for 5 * clk_period;

        rst <= '0';
        wait for 2 * clk_period;

        -- Start-Puls (1 Takt)
        start <= '1';
        wait for clk_period;
        start <= '0';

        -- Warten auf done oder Timeout
        wait until (done = '1');

        -- Ergebnis
        report "GA finished after max_gen generations";
        report "Best fitness: "
            & integer'image(to_integer(unsigned(best_fit)));

        if best_fit = x"00" then
            report "*** Sudoku SOLVED! ***" severity note;
        else
            report "No perfect solution found. Best fitness = "
                & integer'image(to_integer(unsigned(best_fit)))
                severity warning;
        end if;

        -- Lösung als Sudoku ausgeben
        sol := deserialize_sudoku(best_chr);
        print_sudoku(sol);

        wait;
    end process;

    


end architecture;