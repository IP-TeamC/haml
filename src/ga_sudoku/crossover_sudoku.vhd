library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ga_pkg.all;
use work.util.all;

entity crossover_sudoku is
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        const_mask : in std_logic_vector(chr_size-1 downto 0);
        parent_a : in std_logic_vector(chr_size-1 downto 0);
        parent_b : in std_logic_vector(chr_size-1 downto 0);
        rnd_blk : in std_logic_vector(blocks_per_side*blocks_per_side-1 downto 0);

        child_a : out std_logic_vector(chr_size-1 downto 0);
        child_b : out std_logic_vector(chr_size-1 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of crossover_sudoku is
begin

    process(clk)
        variable lo : natural;
        variable mask_sl : std_logic_vector(cell_bits-1 downto 0);
        variable is_fixed : boolean;
        variable blk_idx : integer range 0 to blocks_per_side*blocks_per_side-1;
        variable bit_pos : integer range 0 to blocks_per_side*blocks_per_side-1;
        variable bit_a : std_logic_vector(cell_bits-1 downto 0);
        variable bit_b : std_logic_vector(cell_bits-1 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                child_a <= (others => '0');
                child_b <= (others => '0');
                done <= '0';
            else
                done <= start;

                if start = '1' then
                    debug_print("[CX] Crossover Sudoku gestartet");
                    debug_print("[CX] Tausch-Maske (rnd_blk)", rnd_blk);

                    for br in 0 to blocks_per_side-1 loop
                        for bc in 0 to blocks_per_side-1 loop

                            blk_idx := br * blocks_per_side + bc;
                            bit_pos := rnd_blk'left - blk_idx;

                            if rnd_blk(bit_pos) = '1' then
                                debug_print("  > Block " & integer'image(blk_idx) & 
                                            " (" & integer'image(br) & "," & integer'image(bc) & 
                                            ") GEKREUZT");
                            else
                                debug_print("  > Block " & integer'image(blk_idx) & 
                                            " (" & integer'image(br) & "," & integer'image(bc) & 
                                            ") UNVERAENDERT");
                            end if;

                            for row in 0 to block_size-1 loop
                                for col in 0 to block_size-1 loop
                                    
                                    lo := cell_bits * ((br * block_size + row) * sudoku_size + (bc * block_size + col));
                                    
                                    mask_sl := const_mask(lo + cell_bits - 1 downto lo);
                                    is_fixed := mask_sl /= (cell_bits-1 downto 0 => '0');
                                    bit_a := parent_a(lo + cell_bits - 1 downto lo);
                                    bit_b := parent_b(lo + cell_bits - 1 downto lo);

                                    if is_fixed then
                                        -- Feste Zellen
                                        child_a(lo + cell_bits - 1 downto lo) <= bit_a;
                                        child_b(lo + cell_bits - 1 downto lo) <= bit_b;
                                    elsif rnd_blk(bit_pos) = '0' then
                                        -- Block wird nicht getauscht
                                        child_a(lo + cell_bits - 1 downto lo) <= bit_a;
                                        child_b(lo + cell_bits - 1 downto lo) <= bit_b;
                                    else
                                        -- Block wird gekreuzt
                                        child_a(lo + cell_bits - 1 downto lo) <= bit_b;
                                        child_b(lo + cell_bits - 1 downto lo) <= bit_a;
                                    end if;
                                    
                                end loop;
                            end loop;

                        end loop;
                    end loop;

                    debug_print("[CX] Crossover abgeschlossen (done <= '1')");
                end if;

            end if;
        end if;
    end process;

end architecture;
