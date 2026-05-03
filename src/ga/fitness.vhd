library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fitness is
    generic (
        chr_size : natural := 324;
        fp_size : natural := 8;
        fp_frac : natural := 0;
        data_size : natural := 0
    );
    port (
        clk : in std_logic;
        start : in std_logic;
        chr : in std_logic_vector(chr_size-1 downto 0);
        data_in : in std_logic_vector(data_size-1 downto 0);
        data_out : out std_logic_vector(data_size-1 downto 0);
        fit : out std_logic_vector(fp_size-1 downto 0);
        done : out std_logic
    );
end entity;