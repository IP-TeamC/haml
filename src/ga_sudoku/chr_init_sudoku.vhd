library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ga_pkg.all;
use work.util.all;

entity chr_init_sudoku is
    generic (
        rnd_per_swap : natural := 4 -- Bits pro Zufallszahl (ceil(log2(9))=4)
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        const : in std_logic_vector(chr_size-1 downto 0);
        const_mask : in std_logic_vector(chr_size-1 downto 0);

        rnd : in std_logic_vector(blocks_per_side*blocks_per_side*sudoku_size*rnd_per_swap-1 downto 0);

        chr : out std_logic_vector(chr_size-1 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of chr_init_sudoku is

    type t_state is (S_IDLE, S_BLOCK_SCAN, S_BLOCK_FILL, S_NEXT_BLOCK);
    signal state : t_state;

    -- Blockposition
    signal blk_row : integer range 0 to blocks_per_side-1;
    signal blk_col : integer range 0 to blocks_per_side-1;

    -- Zähler innerhalb eines Blocks (0..8)
    signal pos : integer range 0 to sudoku_size-1;

    -- Arbeitspuffer
    signal chr_buf : std_logic_vector(chr_size-1 downto 0);

    -- missing: Enthält die Sudoku-Ziffern (1..9). 0 gilt als "leer/ungültig"
    type t_missing is array (0 to sudoku_size-1) of integer range 0 to sudoku_size;
    signal missing : t_missing;
    signal remaining : integer range 0 to sudoku_size;

    -- free_pos(i) = Blockposition (0..8) der i-ten freien Zelle
    type t_free_pos is array (0 to sudoku_size-1) of integer range 0 to sudoku_size-1;
    signal free_pos : t_free_pos;
    signal free_count : integer range 0 to sudoku_size;

    -- Hilfsfunktion: Bit-Offset der Zelle (ro,co) in Block (br,bc)
    function cell_lo(br, bc, ro, co : integer) return natural is
    begin
        return cell_bits * ((br*block_size + ro)*sudoku_size + bc*block_size + co);
    end function;

    -- Zufallsbits für Block b (0..8), Zelle i (0..8)
    function rnd_slice(
        rnd_v : std_logic_vector;
        b, i : integer
    ) return unsigned is
        variable base : integer := 4 * (b * sudoku_size + i);
    begin
        return unsigned(rnd_v(base + 3 downto base));
    end function;

begin

    chr <= chr_buf;

    process(clk)
        variable lo : natural;
        variable mask_sl : std_logic_vector(cell_bits-1 downto 0);
        variable val : integer range 0 to sudoku_size;
        variable pick : integer range 0 to sudoku_size-1;
        variable blk_flat : integer range 0 to blocks_per_side*blocks_per_side-1;
        variable ro, co : integer range 0 to block_size-1;
        
        variable v_missing : t_missing;
        variable v_remaining : integer range 0 to sudoku_size;
    begin
        if rising_edge(clk) then
            done <= '0';

            if rst = '1' then
                state <= S_IDLE;
                blk_row <= 0;
                blk_col <= 0;
                pos <= 0;
                free_count <= 0;
                remaining <= 0;
                done <= '0';

            else
                case state is

                    when S_IDLE =>
                        if start = '1' then
                            debug_print("[CHR INIT] Starte Sudoku Chromosom-Initialisierung");

                            chr_buf <= const;
                            blk_row <= 0;
                            blk_col <= 0;
                            pos <= 0;
                            free_count <= 0;
                            remaining <= sudoku_size;

                            for z in 0 to sudoku_size-1 loop
                                missing(z) <= z + 1;
                            end loop;
                                
                            state <= S_BLOCK_SCAN;
                        end if;

                    when S_BLOCK_SCAN =>
                        ro := pos / block_size;
                        co := pos mod block_size;
                        lo := cell_lo(blk_row, blk_col, ro, co);

                        mask_sl := const_mask(lo + cell_bits - 1 downto lo);

                        if mask_sl /= (cell_bits-1 downto 0 => '0') then
                            -- Feste Zelle: Wert aus missing entfernen
                            val := to_integer(unsigned(const(lo + cell_bits - 1 downto lo)));
                            
                            debug_print("[CHR INIT] Block(" & integer'image(blk_row) & "," & integer'image(blk_col) & 
                                        ") Pos " & integer'image(pos) & " ist FEST: Wert = " & integer'image(val));

                            v_missing := missing;
                            v_remaining := remaining;
                            
                            for m in 0 to sudoku_size-1 loop
                                if m < v_remaining and v_missing(m) = val then
                                    v_missing(m) := v_missing(v_remaining - 1);
                                    v_missing(v_remaining - 1) := 0;
                                    v_remaining  := v_remaining - 1;
                                end if;
                            end loop;
                            
                            missing <= v_missing;
                            remaining <= v_remaining;
                        else
                            -- Freie Zelle: Position merken
                            free_pos(free_count) <= pos;
                            free_count <= free_count + 1;
                        end if;

                        if pos = sudoku_size-1 then
                            pos <= 0;
                            state <= S_BLOCK_FILL;
                        else
                            pos <= pos + 1;
                        end if;

                    when S_BLOCK_FILL =>
                        if pos = 0 then
                            debug_print("[CHR INIT] Scannen beendet. Freie Zellen im Block: " & integer'image(free_count));
                        end if;

                        if free_count > 0 and remaining > 0 then
                            blk_flat := blk_row * blocks_per_side + blk_col;

                            -- Zufälligen Index bestimmen
                            pick := to_integer(rnd_slice(rnd, blk_flat, pos) mod to_unsigned(remaining, rnd_per_swap));

                            ro := free_pos(pos) / block_size;
                            co := free_pos(pos) mod block_size;
                            lo := cell_lo(blk_row, blk_col, ro, co);

                            -- Ziffer eintragen
                            chr_buf(lo + cell_bits - 1 downto lo) <= std_logic_vector(to_unsigned(missing(pick), cell_bits));

                            debug_print("  > Fuelle freie Zelle Nr. " & integer'image(pos) & 
                                        " (Block-Pos " & integer'image(free_pos(pos)) & 
                                        ") mit zufaelliger Ziffer: " & integer'image(missing(pick)));

                            v_missing := missing;
                            v_missing(pick) := v_missing(remaining - 1);
                            v_missing(remaining - 1) := 0;
                            
                            missing <= v_missing;
                            remaining <= remaining - 1;
                        end if;

                        if pos >= free_count - 1 or free_count = 0 then
                            state <= S_NEXT_BLOCK;
                        else
                            pos <= pos + 1;
                        end if;

                    when S_NEXT_BLOCK =>
                        pos <= 0;
                        free_count <= 0;
                        remaining <= sudoku_size;

                        for z in 0 to sudoku_size-1 loop
                            missing(z) <= z + 1;
                        end loop;

                        if blk_col = blocks_per_side-1 then
                            blk_col <= 0;
                            if blk_row = blocks_per_side-1 then
                                debug_print("[CHR INIT] Initialisierung BEENDET");
                                debug_print("[CHR INIT] Ergebnis-Chromosom", chr_buf);
                                done <= '1';
                                state <= S_IDLE;
                            else
                                blk_row <= blk_row + 1;
                                state <= S_BLOCK_SCAN;
                            end if;
                        else
                            blk_col <= blk_col + 1;
                            state <= S_BLOCK_SCAN;
                        end if;

                    when others =>
                        state <= S_IDLE;

                end case;
            end if;
        end if;
    end process;

end architecture;