library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package prng is

    constant GENERATOR32 : std_logic_vector(32 downto 0)
        := (32 => '1', 22 => '1', 2 => '1', 1 => '1', 0 => '1', others => '0');
    constant SEED32 : std_logic_vector(31 downto 0)
        := "11010010000101011011000111111001";

    component lfsr
        generic (
            degree : natural := 32
        );
        port (
            clk : in std_logic;
            rst : in std_logic;
            -- MSB links x^degree, LSB rechts (1)
            generator : std_logic_vector(degree downto 0);
            -- Schieben in Richtung MSB
            seed : in std_logic_vector(degree-1 downto 0);
            rand : out std_logic_vector(degree-1 downto 0)
        );
        end component;

end package;
