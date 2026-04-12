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

        top_dist : out std_logic_vector(k*dist_size-1 downto 0);
        top_class : out std_logic_vector(k*class_size-1 downto 0)
    );
end entity;

architecture rtl of ktop is

    constant dp_size : natural := dist_size+class_size;
    subtype t_top_list is std_logic_vector(k*dp_size-1 downto 0);
    type t_top_lists is array (0 to k-1) of t_top_list;
    signal top_list : t_top_list;
    signal top_lists : t_top_lists;

    signal lt_indices : std_logic_vector(k-1 downto 0);
    function lt_index(
        dist_local : std_logic_vector(dist_size-1 downto 0);
        top_list_local : t_top_list;
        i : natural
    ) return std_logic is
        variable diff : signed(dist_size-1 downto 0);
    begin
        diff := signed(dist_local) - flat_signed_sub(top_list_local, dp_size, i, dp_size-1, class_size);
        return diff(dist_size-1);
    end function;

begin

    -- TODO gleiche Distanz?
    -- das hier pipelinen in eigener Stage?
    -- das hier mit indirektem Shift (Indizes zu diesen Werten)?
    -- das hier drunter zumindest als Multiplexer statt alle zu generieren?

    -- unterhalb i beibehalten
    copy_best: for i in 1 to t_top_lists'high generate
        top_lists(i)(flat_lower(dp_size, i)-1 downto 0) <= top_list(flat_lower(dp_size, i)-1 downto 0);
    end generate;

    -- i einfügen
    insert_new: for i in t_top_lists'range generate
        top_lists(i)(flat_upper(dp_size, i) downto flat_lower(dp_size, i)) <= dist & class;
    end generate;

    -- oberhalb i shiften
    copy_worst: for i in 0 to t_top_lists'high-1 generate
        top_lists(i)(t_top_list'high downto flat_upper(dp_size, i)+1) <= top_list(t_top_list'high-dp_size downto flat_lower(dp_size, i));
    end generate;

    gen_lt: for i in 0 to k-1 generate
        lt_indices(i) <= lt_index(dist, top_list, i);
        top_dist(flat_upper(dist_size, i) downto flat_lower(dist_size, i)) <= flat_vec_sub(top_list, dp_size, i, dp_size-1, class_size);
        top_class(flat_upper(class_size, i) downto flat_lower(class_size, i)) <= flat_vec_sub(top_list, dp_size, i, class_size-1, 0);
    end generate;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                top_list <= (others => '1');
                for i in 1 to k loop
                    top_list(dp_size*i-1) <= '0';
                end loop;
            elsif start = '1' then
                for i in 0 to k-1 loop
                    if lt_indices(i) = '1' then
                        top_list <= top_lists(i);
                        exit;
                    end if;
                end loop;
            end if;
        end if;
    end process;

end architecture;