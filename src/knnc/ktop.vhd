library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ktop_stage;
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
        top_class : out std_logic_vector(k*class_size-1 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of ktop is

    signal starts : std_logic_vector(k downto 0);
    signal dist_next : std_logic_vector((k+1)*dist_size-1 downto 0);
    signal class_next : std_logic_vector((k+1)*class_size-1 downto 0);

begin

    starts(0) <= start;
    done <= starts(k);
    dist_next(dist_size-1 downto 0) <= dist;
    class_next(class_size-1 downto 0) <= class;

    gen_stages: for i in 0 to k-1 generate
        stage: entity ktop_stage
            generic map(
                dist_size => dist_size,
                data_size => class_size
            )
            port map(
                clk => clk,
                rst => rst,
                start => starts(i),
                dist_in => dist_next(flat_upper(dist_size, i) downto flat_lower(dist_size, i)),
                data_in => class_next(flat_upper(class_size, i) downto flat_lower(class_size, i)),
                done => starts(i+1),
                dist_next => dist_next(flat_upper(dist_size, i+1) downto flat_lower(dist_size, i+1)),
                data_next => class_next(flat_upper(class_size, i+1) downto flat_lower(class_size, i+1)),
                dist_min => top_dist(flat_upper(dist_size, i) downto flat_lower(dist_size, i)),
                data_min => top_class(flat_upper(class_size, i) downto flat_lower(class_size, i))
            );
    end generate;

end architecture;