library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Pseudo-Random-Number-Generator
-- primitiv Generator-Polynome und Beispiel-Seeds für verschiedene Grade
package prng is

    constant GENERATOR32 : std_logic_vector(32 downto 0)
        := (32 => '1', 22 => '1', 2 => '1', 1 => '1', 0 => '1', others => '0');
    constant SEED32 : std_logic_vector(31 downto 0)
        := "11010010000101011011000111111001";

    type t_generators is array (1 to 32) of std_logic_vector(32 downto 0);
    constant prim_gens : t_generators := (
        1 => (1 => '1', 0 => '1', others => '0'),
        2 => (2 => '1', 1 => '1', 0 => '1', others => '0'),
        3 => (3 => '1', 2 => '1', 0 => '1', others => '0'),
        4 => (4 => '1', 3 => '1', 0 => '1', others => '0'),
        5 => (5 => '1', 3 => '1', 0 => '1', others => '0'),
        6 => (6 => '1', 5 => '1', 0 => '1', others => '0'),
        7 => (7 => '1', 6 => '1', 0 => '1', others => '0'),
        8 => (8 => '1', 6 => '1', 5 => '1', 4 => '1', 0 => '1', others => '0'),
        9 => (9 => '1', 5 => '1', 0 => '1', others => '0'),
        10 => (10 => '1', 7 => '1', 0 => '1', others => '0'),
        11 => (11 => '1', 9 => '1', 0 => '1', others => '0'),
        12 => (12 => '1', 11 => '1', 8 => '1', 6 => '1', 0 => '1', others => '0'),
        13 => (13 => '1', 12 => '1', 10 => '1', 6 => '1', 0 => '1', others => '0'),
        14 => (14 => '1', 13 => '1', 11 => '1', 9 => '1', 0 => '1', others => '0'),
        15 => (15 => '1', 14 => '1', 0 => '1', others => '0'),
        16 => (16 => '1', 14 => '1', 13 => '1', 11 => '1', 0 => '1', others => '0'),
        17 => (17 => '1', 14 => '1', 0 => '1', others => '0'),
        18 => (18 => '1', 11 => '1', 0 => '1', others => '0'),
        19 => (19 => '1', 18 => '1', 17 => '1', 14 => '1', 0 => '1', others => '0'),
        20 => (20 => '1', 17 => '1', 0 => '1', others => '0'),
        21 => (21 => '1', 19 => '1', 0 => '1', others => '0'),
        22 => (22 => '1', 21 => '1', 0 => '1', others => '0'),
        23 => (23 => '1', 18 => '1', 0 => '1', others => '0'),
        24 => (24 => '1', 23 => '1', 21 => '1', 20 => '1', 0 => '1', others => '0'),
        32 => (32 => '1', 22 => '1', 2 => '1', 1 => '1', 0 => '1', others => '0'),
        others => (others => 'U')
    );

    type t_seeds is array (0 to 63) of std_logic_vector(32 downto 0);
    constant sample_seeds : t_seeds := (
        0  => '0' & x"E6981A42",
        1  => '1' & x"7C3F92BD",
        2  => '0' & x"15A7D4E8",
        3  => '0' & x"9B02F16C",
        4  => '1' & x"4E8DC731",
        5  => '1' & x"AF319B56",
        6  => '1' & x"2087E4DA",
        7  => '0' & x"D54A1F90",
        8  => '0' & x"6BC8D273",
        9  => '0' & x"F13E5A0C",
        10 => '0' & x"82D7B649",
        11 => '0' & x"39ACFE12",
        12 => '1' & x"C7E1048F",
        13 => '0' & x"5D92AB36",
        14 => '1' & x"18F4C7E1",
        15 => '1' & x"B30D5A8C",
        16 => '0' & x"4A91C7DE",
        17 => '0' & x"F2385B10",
        18 => '1' & x"7D0E94A6",
        19 => '1' & x"C16BF823",
        20 => '1' & x"58D3A17F",
        21 => '1' & x"E4AC6902",
        22 => '0' & x"2397FD51",
        23 => '1' & x"9AB042EC",
        24 => '1' & x"6F18C3B7",
        25 => '1' & x"D572AE48",
        26 => '0' & x"81E49F25",
        27 => '1' & x"3CB6D104",
        28 => '1' & x"AF07E962",
        29 => '1' & x"5401BC8D",
        30 => '1' & x"ED39A476",
        31 => '1' & x"127F58C1",
        32 => '0' & x"78C20D9B",
        33 => '1' & x"B4E91A35",
        34 => '1' & x"05FD672A",
        35 => '0' & x"CA381EF4",
        36 => '0' & x"91B7D603",
        37 => '0' & x"2E4A8FC9",
        38 => '1' & x"F0C15B7E",
        39 => '1' & x"63D8A214",
        40 => '0' & x"8A24F5D0",
        41 => '1' & x"1F9C37AB",
        42 => '1' & x"D8E60542",
        43 => '0' & x"467BA1FD",
        44 => '0' & x"BC10987E",
        45 => '0' & x"2504DE63",
        46 => '1' & x"9EF73A18",
        47 => '1' & x"71C84B95",
        48 => '1' & x"3D7FA812",
        49 => '0' & x"E1B4C56F",
        50 => '1' & x"94D203AB",
        51 => '0' & x"6ACF7E58",
        52 => '1' & x"0F198D34",
        53 => '1' & x"B72E41C9",
        54 => '0' & x"5CE8F260",
        55 => '0' & x"DA4307BE",
        56 => '1' & x"218CF59A",
        57 => '1' & x"F6841D73",
        58 => '1' & x"879AB02D",
        59 => '0' & x"4BE16FC8",
        60 => '1' & x"C30592E1",
        61 => '1' & x"1AD74B6F",
        62 => '0' & x"E8903C25",
        63 => '1' & x"56F1A8DC"
    );

    function prim_gen(
        degree : natural range prim_gens'range
    ) return std_logic_vector;

    function sample_seed(
        degree : natural range prim_gens'range;
        i : natural range sample_seeds'range
    ) return std_logic_vector;

end package;

package body prng is

    function prim_gen(
        degree : natural range prim_gens'range
    ) return std_logic_vector is
    begin
        return prim_gens(degree)(degree downto 0);
    end function;

    function sample_seed(
        degree : natural range prim_gens'range;
        i : natural range sample_seeds'range
    ) return std_logic_vector is
    begin
        return sample_seeds(i)(degree-1 downto 0);
    end function;

end package body;