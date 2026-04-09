library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package prng is

    constant GENERATOR32 : std_logic_vector(32 downto 0)
        := (32 => '1', 22 => '1', 2 => '1', 1 => '1', 0 => '1', others => '0');
    constant SEED32 : std_logic_vector(31 downto 0)
        := "11010010000101011011000111111001";

end package;
