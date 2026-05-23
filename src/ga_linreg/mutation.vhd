library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math.all;
use work.prng.prim_gen;
use work.prng.sample_seed;

entity mutation is
    generic (
        mask_factor : natural;
        var_num : natural;
        fp_size : natural;
        mut_arith : boolean
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        chr : in std_logic_vector(fp_size*(var_num+1)-1 downto 0);

        done : out std_logic;
        chr_mut : out std_logic_vector(fp_size*(var_num+1)-1 downto 0)
    );
end entity;

architecture rtl of mutation is

    type t_rand_mem is array (0 to 2*mask_factor+4) of std_logic_vector(chr'range);
    signal rand_mem : t_rand_mem;
    signal rand : std_logic_vector(chr'range);
    signal rand_arith : std_logic_vector(fp_size-1 downto 0);

    constant mask_block_size : natural := fp_size / 4;
    type t_masks is array (0 to 3) of std_logic_vector(chr'range);
    signal masks : t_masks;
    signal mask : std_logic_vector(chr'range);

    signal next_chr_mut : std_logic_vector(chr'range);

begin

    gen_lfsr: for i in 0 to var_num generate
        lfsr: entity work.lfsr
            generic map(
                degree => fp_size
            )
            port map(
                clk => clk,
                rst => rst,
                generator => prim_gen(fp_size),
                seed => sample_seed(fp_size, i),
                rand => rand(flat_upper(fp_size, i) downto flat_lower(fp_size, i))
            );
    end generate;

    gen_lfsr_arith: if mut_arith generate
        lfsr_arith: entity work.lfsr
            generic map(
                degree => fp_size
            )
            port map(
                clk => clk,
                rst => rst,
                generator => prim_gen(fp_size),
                seed => sample_seed(fp_size, var_num+1),
                rand => rand_arith
            );
    end generate;

    process (clk)
        variable tmp : std_logic_vector(chr'range);
    begin
        if rising_edge(clk) then
            -- Teil-Masken bauen
            tmp := rand;
            for i in 0 to mask_factor-2 loop
                tmp := tmp and rand_mem(2*i+1);
            end loop;
            masks(0) <= tmp;
            masks(1) <= tmp and rand_mem(2*mask_factor-2);
            masks(2) <= tmp and rand_mem(2*mask_factor+1) and rand_mem(2*mask_factor+4);
            masks(3) <= tmp and rand_mem(2*mask_factor-1) and rand_mem(2*mask_factor) and rand_mem(2*mask_factor+3);

            -- Random-Zwischenspeicher shiften
            rand_mem(0) <= rand;
            for i in 0 to 2*mask_factor+3 loop
                rand_mem(i+1) <= rand_mem(i);
            end loop;
        end if;
    end process;

    full_mask: for i in 0 to var_num generate
        -- untere Blöcke mit nach oben abnehmender Mutationswahrscheinlichkeit
        full_mask_loop: for blk in 0 to masks'high-1 generate
            mask(flat_lower(fp_size, i)+mask_block_size*(blk+1)-1 downto flat_lower(fp_size, i)+mask_block_size*blk)
                <= masks(blk)(flat_lower(fp_size, i)+mask_block_size*(blk+1)-1 downto flat_lower(fp_size, i)+mask_block_size*blk);
        end generate;
        -- oberster Block mit geringster Mutationswahrscheinlichkeit
        mask(flat_upper(fp_size, i) downto flat_lower(fp_size, i)+mask_block_size*masks'high) <=
            masks(masks'high)(flat_upper(fp_size, i) downto flat_lower(fp_size, i)+mask_block_size*masks'high);
    end generate;

    -- Arithmetische Mutation (ADD/SUB)
    mut_addsub: if mut_arith generate
        mut_addsub_loop: for i in 0 to var_num generate
            next_chr_mut(flat_upper(fp_size, i) downto flat_lower(fp_size, i)) <=
                std_logic_vector(
                    signed(chr(flat_upper(fp_size, i) downto flat_lower(fp_size, i)))
                    + signed(mask(flat_upper(fp_size, i) downto flat_lower(fp_size, i)))
                ) when rand_arith(fp_size/2) = '1'
                else std_logic_vector(
                    signed(chr(flat_upper(fp_size, i) downto flat_lower(fp_size, i)))
                    - signed(mask(flat_upper(fp_size, i) downto flat_lower(fp_size, i)))
                );
        end generate;
    end generate;

    -- Logische Mutation (XOR)
    mut_xor: if not mut_arith generate
        mut_xor_loop: for i in 0 to var_num generate
            next_chr_mut(flat_upper(fp_size, i) downto flat_lower(fp_size, i)) <=
                chr(flat_upper(fp_size, i) downto flat_lower(fp_size, i))
                xor mask(flat_upper(fp_size, i) downto flat_lower(fp_size, i));
        end generate;
    end generate;

    process (clk)
    begin
        if rising_edge(clk) then
            done <= start and not rst;
            if start = '1' then
                chr_mut <= next_chr_mut;
            end if;
        end if;
    end process;

end architecture;