library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math.all;
use work.prng.prim_gen;
use work.prng.sample_seed;

entity crossover is
    generic (
        var_num : natural := 2;
        fp_size : natural := 18
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        chr_parent1 : in std_logic_vector(fp_size*(var_num+1)-1 downto 0);
        chr_parent2 : in std_logic_vector(fp_size*(var_num+1)-1 downto 0);

        done : out std_logic;
        chr_child : out std_logic_vector(fp_size*(var_num+1)-1 downto 0)
    );
end entity;

architecture rtl of crossover is

    signal rand : std_logic_vector(var_num downto 0);

begin

    lfsr: entity work.lfsr
        generic map(
            degree => var_num+1
        )
        port map(
            clk => clk,
            rst => rst,
            generator => prim_gen(var_num+1),
            seed => sample_seed(var_num downto 0),
            rand => rand
        );

    process (clk)
    begin
        if rising_edge(clk) then
            if start = '1' then
                for i in 0 to var_num loop
                    if rand(i) = '1' then
                        chr_child(flat_upper(fp_size, i) downto flat_lower(fp_size, i)) <= chr_parent1(flat_upper(fp_size, i) downto flat_lower(fp_size, i));
                    else
                        chr_child(flat_upper(fp_size, i) downto flat_lower(fp_size, i)) <= chr_parent2(flat_upper(fp_size, i) downto flat_lower(fp_size, i));
                    end if;
                end loop;
            end if;
            done <= start and not rst;
        end if;
    end process;

end architecture;