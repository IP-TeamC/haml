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
        fp_size : natural
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

    type t_rand_mem is array (0 to 2*mask_factor+4) of std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal rand_mem : t_rand_mem;
    signal rand : std_logic_vector(fp_size*(var_num+1)-1 downto 0);

    constant mask_block_size : natural := fp_size / 4;
    type t_masks is array (0 to 3) of std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal masks : t_masks;

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

    process (clk)
        variable tmp : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    begin
        if rising_edge(clk) then
            tmp := rand;
            for i in 0 to mask_factor-2 loop
                tmp := tmp and rand_mem(2*i+1);
            end loop;
            masks(0) <= tmp;
            masks(1) <= tmp and rand_mem(2*mask_factor-2);
            masks(2) <= tmp and rand_mem(2*mask_factor+1) and rand_mem(2*mask_factor+4);
            masks(3) <= tmp and rand_mem(2*mask_factor-1) and rand_mem(2*mask_factor) and rand_mem(2*mask_factor+3);

            rand_mem(0) <= rand;
            for i in 0 to 2*mask_factor+3 loop
                rand_mem(i+1) <= rand_mem(i);
            end loop;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then

            done <= start and not rst;

            if start = '1' then

                for i in 0 to var_num loop
                    -- untere Blöcke mit nach oben abnehmender Mutationswahrscheinlichkeit
                    for blk in 0 to masks'high-1 loop
                        chr_mut(flat_lower(fp_size, i)+mask_block_size*(blk+1)-1 downto flat_lower(fp_size, i)+mask_block_size*blk) <=
                            chr(flat_lower(fp_size, i)+mask_block_size*(blk+1)-1 downto flat_lower(fp_size, i)+mask_block_size*blk)
                                xor masks(blk)(flat_lower(fp_size, i)+mask_block_size*(blk+1)-1 downto flat_lower(fp_size, i)+mask_block_size*blk);
                    end loop;

                    -- oberster Block mit geringster Mutationswahrscheinlichkeit
                    chr_mut(flat_upper(fp_size, i) downto flat_lower(fp_size, i)+mask_block_size*masks'high) <=
                            chr(flat_upper(fp_size, i) downto flat_lower(fp_size, i)+mask_block_size*masks'high)
                                xor masks(masks'high)(flat_upper(fp_size, i) downto flat_lower(fp_size, i)+mask_block_size*masks'high);
                end loop;

            end if;

        end if;
    end process;

end architecture;