library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util.all;

entity ram is
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
end entity;

architecture rtl of ram is
    type ram_type is array ((2**adr_size)-1 downto 0) of std_logic_vector(data_size-1 downto 0);
    signal memory : ram_type;
begin

    process(clk)
        variable adr_int : integer;
    begin
        if rising_edge(clk) then
            adr_int := to_integer(unsigned(adr));
            if we = '1' then
                memory(adr_int) <= di;
            end if;
            do <= memory(adr_int);
        end if;
    end process;

end architecture;