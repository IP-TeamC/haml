library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.math.all;

entity kselect is
    generic (
        k : natural := 3;
        class_size : natural := 1
    );
    port (
        clk : in std_logic;
        --rst : in std_logic;
        start : in std_logic;

        top_class : in std_logic_vector(k*class_size-1 downto 0);

        class : out std_logic_vector(class_size-1 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of kselect is
    constant max_count_size : natural := natural(floor(log2(real(k))))+1;
    constant max_class : natural := 2**max_count_size-1;
    type t_class_counter is array (0 to max_class) of unsigned(max_count_size-1 downto 0);
    --signal class_counter : t_class_counter;
begin

    -- TODO gleiche Anzahl
    -- TODO Pipeline
    -- sehr unsauber und kritischer Pfad hier vermutlich Katastrophe :(

    process(clk)
        variable class_counter : t_class_counter;
        variable best_class : unsigned(class_size-1 downto 0);
        variable best_count : unsigned(max_count_size-1 downto 0);
    begin
        if rising_edge(clk) then
            if start = '1' then
                best_class := (others => '0');
                best_count := (others => '0');
                for i in t_class_counter'range loop
                    class_counter(i) := (others => '0');
                end loop;
                for i in 0 to k-1 loop
                    class_counter(to_integer(flat_unsigned(top_class, class_size, i))) := class_counter(to_integer(flat_unsigned(top_class, class_size, i))) + 1;
                end loop;
                for i in t_class_counter'range loop
                    if class_counter(i) > best_count then
                        best_class := to_unsigned(i, class_size);
                        best_count := class_counter(i);
                    end if;
                end loop;
                class <= std_logic_vector(best_class);
            end if;
            done <= start;
        end if;
    end process;

end architecture;