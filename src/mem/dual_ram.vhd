library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dual_ram is
    generic (
        adr_size : natural;
        data_size : natural
    );
    port (
        clk : in std_logic;

        -- Port A (READ)
        adr_a : in std_logic_vector(adr_size-1 downto 0);
        do_a : out std_logic_vector(data_size-1 downto 0);

        -- Port B (WRITE)
        we_b : in std_logic;
        adr_b : in std_logic_vector(adr_size-1 downto 0);
        di_b : in std_logic_vector(data_size-1 downto 0)
    );
end entity;

architecture rtl of dual_ram is
    constant rows : natural := 2**adr_size;
    type ram_type is array (0 to rows-1) of std_logic_vector(data_size-1 downto 0);
    signal memory : ram_type := (others => (others => '0'));
begin

    process(clk)
        variable a_int : integer;
        variable b_int : integer;
    begin
        if rising_edge(clk) then

            if (is_x(adr_a)) then
                a_int := 0;
            else
                a_int := to_integer(unsigned(adr_a));
            end if;
            if (is_x(adr_b)) then
                b_int := 0;
            else
                b_int := to_integer(unsigned(adr_b));
            end if;

            -- WRITE Port B
            if we_b = '1' then
                memory(b_int) <= di_b;
            end if;

            -- READ Port A
            do_a <= memory(a_int);

        end if;
    end process;

end architecture;