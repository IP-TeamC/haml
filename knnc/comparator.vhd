library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.knnc.all;

entity comparator is
    port (
        cmp_to : in t_dp;
        avail : in std_logic;
        next_dp : in t_dp;
        next_class : in t_class;
        distance : out t_fp
    );
end entity;

architecture rtl of comparator is
begin

    -- todo (überhaupt entity)

end architecture;