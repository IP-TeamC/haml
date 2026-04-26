library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity adder_tree is
    generic (
        n : natural;
        size : natural;
        data_size : natural := 0
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        values : in std_logic_vector(n*size-1 downto 0);
        sum : out std_logic_vector(size-1 downto 0);

        done : out std_logic;

        di : in std_logic_vector(data_size-1 downto 0);
        do : out std_logic_vector(data_size-1 downto 0)
    );
end entity;

architecture rtl of adder_tree is

    constant stages_num : natural := natural(ceil(log2(real(n))));

    type t_stage_config is record
        n : natural;
        values_upper : natural;
        values_lower : natural;
        sum_upper : natural;
        sum_lower : natural;
    end record;
    type t_stages_config is array (0 to stages_num-1) of t_stage_config;

    function f_stages_config
    return t_stages_config is
        variable cur_n : natural := n;
        variable next_n : natural := natural(ceil(real(n)/2.0));
        variable configs : t_stages_config;
    begin
        configs(0) := (
                n => cur_n,
                values_lower => 0,
                values_upper => n*size-1,
                sum_lower => n*size,
                sum_upper => n*size+next_n*size-1
            );
        for i in 1 to stages_num-1 loop
            cur_n := next_n;
            next_n := natural(ceil(real(cur_n)/2.0));
            configs(i) := (
                n => cur_n,
                values_lower => configs(i-1).sum_lower,
                values_upper => configs(i-1).sum_upper,
                sum_lower => configs(i-1).sum_upper+1,
                sum_upper => configs(i-1).sum_upper+next_n*size
            );
        end loop;
        return configs;
    end function;

    constant stages_config : t_stages_config := f_stages_config;
    signal stages_values : std_logic_vector(stages_config(stages_num-1).sum_upper downto 0);
    signal stages_start : std_logic_vector(stages_num downto 0);

    type t_stages_data is array (0 to stages_num) of std_logic_vector(data_size-1 downto 0);
    signal stages_data : t_stages_data;

begin

    stages_values(n*size-1 downto 0) <= values;
    stages_start(0) <= start;
    stages_data(0) <= di;

    sum <= stages_values(stages_config(stages_num-1).sum_upper downto stages_config(stages_num-1).sum_upper-size+1);
    done <= stages_start(stages_num);
    do <= stages_data(stages_num);

    stages_add: for i in 0 to stages_num-1 generate
        stage: entity work.adder_tree_stage
         generic map(
            n => stages_config(i).n,
            size => size,
            data_size => data_size
        )
         port map(
            clk => clk,
            rst => rst,
            start => stages_start(i),
            values => stages_values(stages_config(i).values_upper downto stages_config(i).values_lower),
            sum => stages_values(stages_config(i).sum_upper downto stages_config(i).sum_lower),
            done => stages_start(i+1),
            di => stages_data(i),
            do => stages_data(i+1)
        );
    end generate;

end architecture;