library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_sudoku.all;
use work.util.all;

entity mutation_sudoku is
    generic (
        mut_bits : natural := 3 -- Mutationswahrscheinlichkeit: P(mutation) = 0.5^mut_bits
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        const_mask : in std_logic_vector(chr_size-1 downto 0);

        chr_in : in std_logic_vector(chr_size-1 downto 0);
        chr_out : out std_logic_vector(chr_size-1 downto 0);

        -- Zufallsbits
        rnd_gate : in std_logic_vector(mut_bits-1 downto 0);
        rnd_blk : in std_logic_vector(3 downto 0);
        rnd_pos_a : in std_logic_vector(3 downto 0);
        rnd_pos_b : in std_logic_vector(3 downto 0);

        done : out std_logic
    );
end entity;

architecture rtl of mutation_sudoku is
begin

    process(clk)
        variable blk_idx : integer range 0 to blocks_per_side*blocks_per_side-1;
        variable br, bc : integer range 0 to blocks_per_side-1;
        variable pos_a : integer range 0 to sudoku_size-1;
        variable pos_b : integer range 0 to sudoku_size-1;
        variable ro_a, co_a : integer range 0 to block_size-1;
        variable ro_b, co_b : integer range 0 to block_size-1;
        variable lo_a, lo_b : natural;
        variable mask_a : std_logic_vector(cell_bits-1 downto 0);
        variable mask_b : std_logic_vector(cell_bits-1 downto 0);
        variable val_a : std_logic_vector(cell_bits-1 downto 0);
        variable val_b : std_logic_vector(cell_bits-1 downto 0);
        variable tmp : std_logic_vector(chr_size-1 downto 0);
        variable gate : std_logic;
    begin
        if rising_edge(clk) then

            if rst = '1' then
                done <= '0';
            else
                done <= start;
                if start = '1' then
                    tmp := chr_in;

                    debug_print("[MUT] Mutation gestartet");
                    debug_print("[MUT] Pruefe Mutationswahrscheinlichkeit");

                    -- Mutationswahrscheinlichkeit prüfen
                    gate := '1';
                    for i in 0 to mut_bits-1 loop
                        gate := gate and rnd_gate(i);
                    end loop;

                    if gate = '1' then

                        -- Block bestimmen
                        blk_idx := to_integer(unsigned(rnd_blk)) mod (blocks_per_side * blocks_per_side);
                        br := blk_idx / blocks_per_side;
                        bc := blk_idx mod blocks_per_side;

                        -- Positionen im Block
                        pos_a := to_integer(unsigned(rnd_pos_a)) mod sudoku_size;
                        pos_b := to_integer(unsigned(rnd_pos_b)) mod sudoku_size;

                        ro_a := pos_a / block_size;
                        co_a := pos_a mod block_size;
                        ro_b := pos_b / block_size;
                        co_b := pos_b mod block_size;

                        -- Bit-Offsets
                        lo_a := cell_bits * ((br*block_size + ro_a)*sudoku_size + bc*block_size + co_a);
                        lo_b := cell_bits * ((br*block_size + ro_b)*sudoku_size + bc*block_size + co_b);

                        mask_a := const_mask(lo_a + cell_bits - 1 downto lo_a);
                        mask_b := const_mask(lo_b + cell_bits - 1 downto lo_b);
                        
                        debug_print("[MUT] Swap-Check im Block " & integer'image(blk_idx) & 
                            " | Pos A: " & integer'image(pos_a) & " (Maske: " & to_string(mask_a) & ")" &
                            " <-> Pos B: " & integer'image(pos_b) & " (Maske: " & to_string(mask_b) & ")");


                        -- Nur tauschen wenn beide Zellen frei und verschieden
                        if pos_a /= pos_b
                            and mask_a = (cell_bits-1 downto 0 => '0')
                            and mask_b = (cell_bits-1 downto 0 => '0')
                        then
                            val_a := chr_in(lo_a + cell_bits - 1 downto lo_a);
                            val_b := chr_in(lo_b + cell_bits - 1 downto lo_b);
                            tmp(lo_a + cell_bits - 1 downto lo_a) := val_b;
                            tmp(lo_b + cell_bits - 1 downto lo_b) := val_a;

                            debug_print("  > Swap in Block " & integer'image(blk_idx) & 
                                ": Position " & integer'image(pos_a) & " <-> " & integer'image(pos_b));
                        end if;
                    end if;

                    chr_out <= tmp;
                    debug_print("[MUT] Mutation beendet");

                end if;
            end if;
        end if;
    end process;

end architecture;