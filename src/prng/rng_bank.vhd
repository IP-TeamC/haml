library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.prng.all;

entity rng_bank is
    generic (
        degree : natural := 32;
        n : natural := 4 -- Anzahl LFSRs
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        rand : out std_logic_vector(degree*n-1 downto 0)
    );
end entity;

architecture rtl of rng_bank is
begin
    gen_lfsr: for i in 0 to n-1 generate
        inst: entity work.lfsr
            generic map(degree => degree)
            port map(
                clk => clk,
                rst => rst,
                generator => GENERATOR32,
                seed => std_logic_vector(unsigned(SEED32) + to_unsigned(i * 1234567, 32)),
                rand => rand(degree*(i+1)-1 downto degree*i)
            );
    end generate;
end architecture;