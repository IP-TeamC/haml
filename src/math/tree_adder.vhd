library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tree_adder is
    generic (
        n : natural;
        size : natural
    );
    port (
        signal clk : in std_logic;
        signal values : in std_logic_vector(n*size-1 downto 0);
        signal sum : out signed(size-1 downto 0)
    );
end entity;

architecture rtl of tree_adder is
    constant stages_num : natural := natural(ceil(log2(real(n))));
    constant stages_num_p1exp2_size : natural := natural(2**(stages_num+1))*size;
    signal stages_values : std_logic_vector(stages_num_p1exp2_size-size-1 downto 0);
begin

    process (clk)
    begin
        if rising_edge(clk) then
            sum <= signed(stages_values(stages_num_p1exp2_size-size-1 downto stages_num_p1exp2_size-2*size));
        end if;
    end process;

    stages_values(n*size-1 downto 0) <= values;

    stages_add: for i in 0 to stages_num-1 generate
        stage: entity work.tree_adder_stage
         generic map(
            n => natural(ceil(real(n)/real(2**i))), -- falsch für nicht 2er-Potenzen
            size => size
        )
         port map(
            clk => clk,
            values => stages_values(stages_num_p1exp2_size-2**(stages_num-i)*size-1 downto stages_num_p1exp2_size-2**(stages_num+1-i)*size),
            sum => stages_values(stages_num_p1exp2_size-2**(stages_num-i-1)*size-1 downto stages_num_p1exp2_size-2**(stages_num-i)*size)
        );
    end generate;

end architecture;