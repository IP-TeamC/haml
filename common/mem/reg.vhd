library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg is
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
end entity;

architecture rtl of reg is
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= (others => '0');
            elsif we = '1' then
                state <= data;
            end if;
        end if;
    end process;

end architecture;