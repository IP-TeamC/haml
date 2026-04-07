library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package knnc is

    constant FP_INT : natural := 26;
    constant FP_FRAC : natural := 10;
    constant FP_SIZE : natural := FP_INT + FP_FRAC;
    constant CLASS_SIZE : natural := 1;
    constant FEATURES : natural := 7;

    subtype t_fp is signed(FP_SIZE-1 downto 0);
    subtype t_class is std_logic_vector(CLASS_SIZE-1 downto 0);
    type t_features is array (0 to FEATURES-1) of t_fp;
    type t_dp is record
        features : t_features;
        class : t_class;
    end record;

end package;