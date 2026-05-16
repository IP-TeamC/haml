library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math.all;
use work.prng.prim_gens;
use work.prng.sample_seed;

entity mutation is
    generic (
        mask_factor : natural := 3;
        var_num : natural := 2;
        fp_size : natural := 18
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

    type t_rand_mem is array (0 to 2*mask_factor-1) of std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal rand_mem : t_rand_mem;
    signal rand : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal mask : std_logic_vector(fp_size*(var_num+1)-1 downto 0);

begin

    gen_lfsr: for i in 0 to var_num generate
        lfsr: entity work.lfsr
            generic map(
                degree => fp_size
            )
            port map(
                clk => clk,
                rst => rst,
                generator => prim_gens(fp_size),
                seed => (sample_seed(i downto 0) & sample_seed(fp_size-1 downto i+1)) xor sample_seed(fp_size-1 downto 0),
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
            mask <= tmp;

            rand_mem(0) <= rand;
            for i in 0 to 2*mask_factor-2 loop
                rand_mem(i+1) <= rand_mem(i);
            end loop;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            chr_mut <= chr xor mask;
            done <= start and not rst;
        end if;
    end process;

end architecture;