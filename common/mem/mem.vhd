library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package mem is

    component reg is
        generic (
            size : natural
        );
        port (
            clk : in std_logic;
            rst : in std_logic;
            we : in std_logic;
            data : in std_logic_vector(size-1 downto 0);
            state : out std_logic_vector(size-1 downto 0)
        );
    end component;

    component ram is
        generic (
            adr_size : natural;
            data_size : natural
        );
        port (
            clk : in std_logic;
            we : in std_logic;
            adr : in std_logic_vector(adr_size-1 downto 0);
            di : in std_logic_vector(data_size-1 downto 0);
            do : out std_logic_vector(data_size-1 downto 0)
        );
    end component;

end package;