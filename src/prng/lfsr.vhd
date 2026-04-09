library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lfsr is
    generic (
        degree : natural := 32 -- für post-translate sim gleich wie tb
    );
    port (
        clk   : in std_logic;
        rst : in std_logic;
        -- MSB links x^degree, LSB rechts (1)
        generator : std_logic_vector(degree downto 0);
        -- Schieben in Richtung MSB
        seed : in std_logic_vector(degree-1 downto 0);
        rand : out std_logic_vector(degree-1 downto 0)
    );
end entity;

architecture rtl of lfsr is
    signal q : std_logic_vector(degree-1 downto 0);
    signal qn : std_logic_vector(degree-1 downto 0);
begin

    -- Zustandswechsel
    process(clk)
    begin
        if rising_edge(clk) then
            case rst is
                when '1' => q <= seed;
                when others => q <= qn;
            end case;
        end if;
    end process;

    -- Ausgabe
    rand <= q;

    qn(0) <= q(degree-1);
    shiftWithXor:
    for i in 1 to degree-1 generate
        qn(i) <= q(i-1) xor (generator(i) and q(degree-1));
    end generate;

end architecture;
