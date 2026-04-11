library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.math.all;

entity adder_tree_stage is
    generic (
        n : natural;
        size : natural
    );
    port (
        clk : in std_logic;
        start : in std_logic;

        values : in std_logic_vector(n*size-1 downto 0);
        sum : out std_logic_vector(natural(ceil(real(n)/2.0))*size-1 downto 0);

        done : out std_logic
    );
end entity;

architecture rtl of adder_tree_stage is
    constant sum_num : natural := natural(ceil(real(n)/2.0));
    signal sum_next : std_logic_vector(sum'range);
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if start = '1' then
                sum <= sum_next;
            end if;
            done <= start;
        end if;
    end process;

    pair_add: for i in 0 to sum_num-1 generate
        sum_next(flat_upper(size, i) downto flat_lower(size, i)) <=
            std_logic_vector(flat_signed(values, size, 2*i)) when i = sum_num-1 and n mod 2 = 1
            else std_logic_vector(flat_signed(values, size, 2*i) + flat_signed(values, size, 2*i+1));
    end generate;

end architecture;