library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ga_pkg.all;

entity chr_init_sudoku_tb is
end entity;

architecture sim of chr_init_sudoku_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal start : std_logic := '0';

    signal const : std_logic_vector(chr_size-1 downto 0) := (others => '0');
    signal const_mask : std_logic_vector(chr_size-1 downto 0) := (others => '0');
    
    constant RND_WIDTH : natural := blocks_per_side * blocks_per_side * sudoku_size * 4;
    signal rnd : std_logic_vector(RND_WIDTH-1 downto 0) := (others => '0');

    signal chr : std_logic_vector(chr_size-1 downto 0);
    signal done : std_logic;

begin

    uut: entity work.chr_init_sudoku
        generic map (
            rnd_per_swap => 4
        )
        port map (
            clk => clk,
            rst => rst,
            start => start,
            const => const,
            const_mask => const_mask,
            rnd => rnd,
            chr => chr,
            done => done
        );

    -- Taktgenerator
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
        variable cell_idx : natural;
    begin
        -- Reset
        rst <= '1';
        wait for CLK_PERIOD * 3;
        rst <= '0';
        wait for CLK_PERIOD;

        -- ---------------------------------------------------------------------
        -- TEST 1: Komplett leeres Sudoku zufällig füllen (keine Maske)
        -- ---------------------------------------------------------------------
        report "--- TEST 1: Starte Initialisierung ohne feste Vorgaben ---";
        
        for i in 0 to (RND_WIDTH/4)-1 loop
            rnd(4*i+3 downto 4*i) <= std_logic_vector(to_unsigned((i * 7 + 3) mod 16, 4));
        end loop;

        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

        wait until done = '1';
        wait for CLK_PERIOD/2;
        
        print_sudoku(deserialize_sudoku(chr));

        wait for CLK_PERIOD * 5;

        -- ---------------------------------------------------------------------
        -- TEST 2: Sudoku mit festen Vorgaben initialisieren
        -- ---------------------------------------------------------------------
        report "--- TEST 2: Starte Initialisierung mit festen Vorgaben (Maske) ---";
        
        const <= (others => '0');
        const_mask <= (others => '0');

        -- Zelle 0,0: fest '5'
        cell_idx := cell_bits * (0 * sudoku_size + 0);
        const(cell_idx + cell_bits - 1 downto cell_idx) <= std_logic_vector(to_unsigned(5, cell_bits));
        const_mask(cell_idx + cell_bits - 1 downto cell_idx) <= (others => '1');

        -- Zelle 0,1: fest '3'
        cell_idx := cell_bits * (0 * sudoku_size + 1);
        const(cell_idx + cell_bits - 1 downto cell_idx) <= std_logic_vector(to_unsigned(3, cell_bits));
        const_mask(cell_idx + cell_bits - 1 downto cell_idx) <= (others => '1');

        -- Zelle 4,4: fest '9'
        cell_idx := cell_bits * (4 * sudoku_size + 4);
        const(cell_idx + cell_bits - 1 downto cell_idx) <= std_logic_vector(to_unsigned(9, cell_bits));
        const_mask(cell_idx + cell_bits - 1 downto cell_idx) <= (others => '1');

        for i in 0 to (RND_WIDTH/4)-1 loop
            rnd(4*i+3 downto 4*i) <= std_logic_vector(to_unsigned((i * 13 + 1) mod 16, 4));
        end loop;

        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

        wait until done = '1';
        wait for CLK_PERIOD/2;

        print_sudoku(deserialize_sudoku(chr));

        report "--- Alle Tests erfolgreich durchgelaufen! ---";
        wait;
    end process;

end architecture;