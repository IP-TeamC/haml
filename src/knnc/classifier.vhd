library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math.all;

entity classifier is

    generic (
        k : natural := 3;
        fp_size : natural := 36;
        fp_frac : natural := 10;
        class_size : natural := 1;
        feature_num : natural := 7;
        adr_size : natural := 8
    );

    port (
        clk : in std_logic;
        rst : in std_logic;

        start : in std_logic;

        -- Feature 1 (fp_size), Feature 2 (fp_size), ..., Feature n (fp_size), Class ([...] class_size)
        ram_adr : in std_logic_vector(adr_size-1 downto 0);
        ram_data : out std_logic_vector(fp_size-1 downto 0);

        done : out std_logic;
        class : out std_logic_vector(class_size-1 downto 0)
    );

end entity;

architecture rtl of classifier is

    subtype t_fp is signed(fp_size-1 downto 0);
    type t_features is array (0 to feature_num-1) of t_fp;
    subtype t_class is std_logic_vector(class_size-1 downto 0);
    type state is (idle, read_dp, calc);

    signal cmp_features : t_features;
    signal dp_features : t_features;
    signal dp_class : t_class;

    signal diff_sq : t_features;
    signal diff_sq_next : t_features; 

    signal lowest_dist : t_fp;
    signal lowest_class : t_class;

begin

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                -- ?
            else
                diff_sq <= diff_sq_next;
            end if;
        end if;
    end process;

    gen_diff: for i in cmp_features'range generate
    begin
        diff_sq_next(i) <= fp_mul(
                cmp_features(i) - dp_features(i),
                cmp_features(i) - dp_features(i),
                cmp_features(i)'length
            );
    end generate;

    process(diff_sq, lowest_dist)
        variable dist_acc : signed(fp_size-1 downto 0);
    begin
        dist_acc := diff_sq(0);
        for i in 1 to diff_sq'length-1 loop
            dist_acc := dist_acc + diff_sq(i);
        end loop;
        --lowest_dist <= dist_acc when dist_acc < lowest_dist
        --    else lowest_dist;
    end process;

end architecture;