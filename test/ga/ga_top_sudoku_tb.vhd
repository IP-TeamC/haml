library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

use work.ga_pkg.all;

entity ga_top_sudoku_tb is
end entity;

architecture rtl of ga_top_sudoku_tb is

    constant clk_period : time := 10 ns;

    constant chr_size : natural := 324;
    constant fp_size : natural := 8;
    constant pop_size : natural := 64;

    constant idx_size : natural := natural(ceil(log2(real(pop_size))));

    -- DUT signals
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal start : std_logic := '0';

    signal const : std_logic_vector(chr_size-1 downto 0);

    signal best_chr : std_logic_vector(chr_size-1 downto 0);
    signal best_fit : std_logic_vector(fp_size-1 downto 0);
    signal done : std_logic;

    -- Init interface
    signal init_mode : std_logic := '0';
    signal init_we : std_logic := '0';
    signal init_idx : std_logic_vector(idx_size-1 downto 0);
    signal init_chr : std_logic_vector(chr_size-1 downto 0);
    signal init_fit : std_logic_vector(fp_size-1 downto 0);

begin

    --------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------
    uut: entity work.ga_top
        generic map(
            chr_size => chr_size,
            fp_size  => fp_size,
            pop_size => pop_size,
            k        => 4,
            mut_bits => 7,
            max_gen  => 1000
        )
        port map(
            clk => clk,
            rst => rst,
            start => start,

            const => const,

            init_mode => init_mode,
            init_we   => init_we,
            init_idx  => init_idx,
            init_chr  => init_chr,
            init_fit  => init_fit,

            best_chr => best_chr,
            best_fit => best_fit,
            done => done
        );

    --------------------------------------------------------------------
    -- Clock
    --------------------------------------------------------------------
    clk_process : process
    begin
        clk <= not clk;
        wait for clk_period/2;
    end process;

    --------------------------------------------------------------------
    -- Testprozess
    --------------------------------------------------------------------
    process
        variable hs_unsolved : t_human_sudoku;
        variable hs_fill     : t_human_sudoku;
        variable chr_const   : std_logic_vector(323 downto 0);
        variable chr_init    : std_logic_vector(323 downto 0);
    begin

        ----------------------------------------------------------------
        -- RESET
        ----------------------------------------------------------------
        rst <= '1';
        wait for 2 * clk_period;
        rst <= '0';

        ----------------------------------------------------------------
        -- Sudoku definieren
        ----------------------------------------------------------------
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

        ----------------------------------------------------------------
        -- INIT
        ----------------------------------------------------------------
        init_mode <= '1';

        for p in 0 to pop_size-1 loop

            hs_fill := hs_unsolved;

            -- einfache deterministische Füllung der freien Felder
            for r in 1 to 9 loop
                for c in 1 to 9 loop
                    if hs_fill(r,c) = 0 then
                        hs_fill(r,c) := ((r + c + p) mod 9) + 1;
                    end if;
                end loop;
            end loop;

            chr_init := serialize_sudoku(hs_fill);

            init_we  <= '1';
            init_idx <= std_logic_vector(to_unsigned(p, idx_size));
            init_chr <= chr_init;
            init_fit <= (others => '1');

            wait for clk_period;

        end loop;

        init_we <= '0';
        init_mode <= '0';

        wait for clk_period;

        ----------------------------------------------------------------
        -- GA START
        ----------------------------------------------------------------
        start <= '1';
        wait for clk_period;
        start <= '0';

        ----------------------------------------------------------------
        -- WAIT FOR FINISH
        ----------------------------------------------------------------
        wait until done = '1';

        ----------------------------------------------------------------
        -- REPORT
        ----------------------------------------------------------------
        report "GA finished";
        report "Best fitness: "
            & integer'image(to_integer(unsigned(best_fit)));

        assert valid_known(best_chr, chr_const) = '1'
            report "ERROR: fixed Sudoku fields were modified!"
            severity failure;

        if best_fit = x"00" then
            report "Sudoku solved successfully.";
        else
            report "No perfect solution found (yet).";
        end if;

        wait;

    end process;

end architecture;