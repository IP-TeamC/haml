library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math.all;

entity ktop is
    generic (
        k : natural := 3;
        dist_size : natural := 36;
        class_size : natural := 1
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        dist : in std_logic_vector(dist_size-1 downto 0);
        class : in std_logic_vector(class_size-1 downto 0);

        done : out std_logic
    );
end entity;

architecture rtl of ktop is

    constant dp_size : natural := dist_size+class_size;
    subtype t_top_list is std_logic_vector(k*dp_size-1 downto 0);
    type t_top_lists is array (0 to k-1) of t_top_list;
    signal top_list : t_top_list;
    signal top_lists : t_top_lists;

begin

    -- das hier pipelinen in eigener Stage
    insert_top_lists: for i in t_top_lists'range generate
        top_lists(i)(t_top_list'high downto flat_upper(dp_size, i)+1) <= top_list(t_top_list'high downto flat_upper(dp_size, i)+1);
        top_lists(i)(flat_upper(dp_size, i) downto flat_lower(dp_size, i)) <= dist & class;
        top_lists(i)(flat_lower(dp_size, i)-1 downto 0) <= top_list(flat_lower(dp_size, i)-1 downto 0);
    end generate;

    -- TODO Pipelining oder nebenläufig optimieren!
    -- TODO gleiche Distanz?
    process(clk)
        variable cur : signed(dist_size+class_size-1 downto 0);
        variable diff : signed(dist_size-1 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                top_list <= (others => '0');
            else
                for i in k-1 to 0 loop
                    cur := signed(top_list(flat_upper(dp_size, i) downto flat_lower(dp_size, i))(dp_size-1 downto class_size));
                    diff := signed(dist) - cur;
                    if diff(dist_size-1) = '1' then
                        top_list <= top_lists(i);
                    end if;
                end loop;
            end if;
        end if;
    end process;

end architecture;