library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tree_adder is
    generic (
        n : natural;
        size : natural
    );
    port (
        signal clk : in std_logic;
        signal values : in std_logic -- todo
    ); 
end entity;

architecture rtl of tree_adder is

begin

    

end architecture;