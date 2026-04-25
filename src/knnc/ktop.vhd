library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ktop_stage;
use work.math.all;

entity ktop is
    generic (
        k : natural := 3;
        dist_size : natural := 36;
        data_size : natural := 1
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        dist : in std_logic_vector(dist_size-1 downto 0);
        data : in std_logic_vector(data_size-1 downto 0);

        top_dist : out std_logic_vector(k*dist_size-1 downto 0);
        top_data : out std_logic_vector(k*data_size-1 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of ktop is

    type t_dist is array (natural range <>) of std_logic_vector(dist_size-1 downto 0);
    type t_data is array (natural range <>) of std_logic_vector(data_size-1 downto 0);

    signal starts : std_logic_vector(k downto 0);

    signal new_dist : t_dist(0 to k);
    signal new_data : t_data(0 to k);

    signal cur_dist : t_dist(0 to k-1);
    signal cur_data : t_data(0 to k-1);

begin

    starts(0) <= start;
    done <= starts(k);
    new_dist(0) <= dist;
    new_data(0) <= data;

    gen_stages: for i in 0 to k-1 generate

        top_dist(flat_upper(dist_size, i) downto flat_lower(dist_size, i)) <= cur_dist(i);
        top_data(flat_upper(data_size, i) downto flat_lower(data_size, i)) <= cur_data(i);

        stage: entity ktop_stage
            generic map(
                dist_size => dist_size,
                data_size => data_size
            )
            port map(
                clk => clk,
                rst => rst,
                start => starts(i),
                dist_new => new_dist(i),
                data_new => new_data(i),
                dist_cur => cur_dist(i),
                data_cur => cur_data(i),
                done => starts(i+1),
                dist_move => new_dist(i+1),
                data_move => new_data(i+1),
                dist_keep => cur_dist(i),
                data_keep => cur_data(i)
            );

    end generate;

end architecture;