library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fitness;
use work.ga_pkg.all;

entity fitness_sudoku_tb is

    -- Constants
    constant clk_period : time := 10 ns;
    constant chr_size : natural := 324;
    constant const_size : natural := 324;
    constant fp_size : natural := 8;
    constant fp_frac : natural := 0;
    constant data_size : natural := 2;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal start : std_logic := '0';
    signal chr : std_logic_vector(chr_size-1 downto 0) := (others => '0');
    signal const : std_logic_vector(const_size-1 downto 0) := (others => '0');
    signal di : std_logic_vector(data_size-1 downto 0) := (others => '0');
    
    -- Outputs
    signal do : std_logic_vector(data_size-1 downto 0);
    signal fit : std_logic_vector(fp_size-1 downto 0);
    signal done : std_logic;

end entity;

architecture rtl of fitness_sudoku_tb is

begin

    uut: entity fitness(sudoku)
        generic map (
            chr_size => chr_size,
            const_size => const_size,
            fp_size => fp_size,
            fp_frac => fp_frac,
            data_size => data_size
        )
        port map (
            clk => clk,
            rst => rst,
            start => start,
            chr => chr,
            const => const,
            di => di,
            do => do,
            fit => fit,
            done => done
        );

    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    process
        type t_conflicts is array (0 to 8) of integer range 0 to 8;
        variable hs_unsolved : t_human_sudoku;
        variable hs_solved : t_human_sudoku;
        variable chr_s_u : std_logic_vector(323 downto 0);
        variable chr_s_s : std_logic_vector(323 downto 0);
        variable chr_k : std_logic_vector(323 downto 0);
        variable row_c : t_conflicts;
        variable col_c : t_conflicts;
        variable blk_c : t_conflicts;
        variable vk : std_logic;
    begin
        
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        assert done = '0';

        hs_unsolved := (
                (7, 0, 0,   5, 8, 2,   9, 3, 4),
                (2, 0, 5,   0, 1, 9,   0, 0, 7),
                (0, 0, 3,   0, 0, 0,   2, 0, 1),

                (0, 3, 7,   1, 0, 6,   4, 2, 5),
                (4, 9, 0,   7, 0, 0,   0, 1, 0),
                (0, 5, 2,   0, 3, 8,   7, 0, 0),

                (0, 2, 0,   0, 5, 7,   1, 9, 6),
                (5, 7, 9,   2, 6, 0,   0, 0, 3),
                (6, 0, 0,   0, 4, 3,   5, 7, 2)
            );
        hs_solved := (
                (7, 6, 1,   5, 8, 2,   9, 3, 4),
                (2, 4, 5,   3, 1, 9,   6, 8, 7),
                (9, 8, 3,   6, 7, 4,   2, 5, 1),

                (8, 3, 7,   1, 9, 6,   4, 2, 5),
                (4, 9, 6,   7, 2, 5,   3, 1, 8),
                (1, 5, 2,   4, 3, 8,   7, 6, 9),

                (3, 2, 4,   8, 5, 7,   1, 9, 6),
                (5, 7, 9,   2, 6, 1,   8, 4, 3),
                (6, 1, 8,   9, 4, 3,   5, 7, 2)
            );
        chr_k := serialize_sudoku(hs_unsolved);
        for i in 1 to 9 loop
            for j in 1 to 9 loop
                if hs_unsolved(i, j) = 0 then
                    hs_unsolved(i, j) := 1;
                end if;        
            end loop;
        end loop;
        chr_s_u := serialize_sudoku(hs_unsolved);
        chr_s_s := serialize_sudoku(hs_solved);

        const <= chr_k;
        chr <= chr_s_u;
        start <= '1';
        wait for clk_period;
        start <= '1';
        chr <= chr_s_s;
        wait for clk_period;
        start <= '0';
        assert done = '0';
        wait until done = '1';
        wait for clk_period/2;
        report "Unsolved total conflicts: " & integer'image(to_integer(unsigned(fit)));
        assert done = '1';
        assert fit /= "00000000";
        wait for clk_period;
        report "Solved total conflicts: " & integer'image(to_integer(unsigned(fit)));
        assert done = '1';
        assert fit = "00000000";
        wait for clk_period;
        assert done = '0';

        for i in 0 to 8 loop
            row_c(i) := to_integer(row_conflicts(chr_s_u, i));
            col_c(i) := to_integer(col_conflicts(chr_s_u, i));
            report "Row conflicts " & integer'image(i) & ": " & integer'image(row_c(i));
            report "Column conflicts " & integer'image(i) & ": " & integer'image(col_c(i));
        end loop;

        for br in 0 to 2 loop
            for bc in 0 to 2 loop
                blk_c(3*br+bc) := to_integer(block_conflicts(chr_s_u, br, bc));
                report "Block conflicts " & integer'image(br) & "-" & integer'image(bc) & ": " & integer'image(blk_c(3*br+bc));
            end loop;
        end loop;

        vk := valid_known(chr_s_u, chr_k);
        report "Valid known: " & std_logic'image(vk);
        
        wait;
    end process;

end architecture;