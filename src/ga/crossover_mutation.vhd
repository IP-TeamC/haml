library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity crossover_mutation is
    generic (
        chr_size : natural := 324; -- Chromosombreite
        mut_bits : natural := 7 -- Mutationswahrscheinlichkeit: P(mutation) = 0.5^mut_bits
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;
        
        -- Eltern:
        chr_a : in std_logic_vector(chr_size-1 downto 0);
        chr_b : in std_logic_vector(chr_size-1 downto 0);
        -- Kinder:
        child_a : out std_logic_vector(chr_size-1 downto 0);
        child_b : out std_logic_vector(chr_size-1 downto 0);

        -- Crossover-Punkt:
        rnd_cx : in std_logic_vector(natural(ceil(log2(real(chr_size))))-1 downto 0);
        -- Mutationsmaske:
        rnd_mut : in std_logic_vector(chr_size*mut_bits-1 downto 0);

        done : out std_logic
    );
end entity;

architecture rtl of crossover_mutation is

    -- Prüft, ob ein Bit mutiert werde soll
    function should_mutate(
        rnd : std_logic_vector; -- Zufallsvektor
        pos : natural; -- Position des aktuellen Bits im Chromosom
        n : natural -- Anzahl Zufallsbits pro Gen
    ) return boolean is
        variable bits : std_logic_vector(n-1 downto 0);
        variable acc : std_logic;
    begin
        bits := rnd(n*(pos+1)-1 downto n*pos); -- Teilbereich der Zufallsbits
        acc := '1';
    
        -- AND-Reduktion über Zufallsbits -> true wenn alle '1'
        for i in 0 to n-1 loop
            acc := acc and bits(i);
        end loop;

        return acc = '1';
    end function;

begin
    process(clk)
        variable cx : natural range 0 to chr_size-1;
        variable ba : std_logic;
        variable bb : std_logic;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                done <= '0';
            else
                done <= start;
                if start = '1' then
                    cx := to_integer(unsigned(rnd_cx)) mod chr_size;
                    for i in 0 to chr_size-1 loop
                        -- Crossover
                        if i < cx then
                            ba := chr_a(i);
                            bb := chr_b(i);
                        else
                            ba := chr_b(i);
                            bb := chr_a(i);
                        end if;
                        -- Mutation
                        if should_mutate(rnd_mut, i, mut_bits) then
                            child_a(i) <= not ba;
                            child_b(i) <= not bb;
                        else
                            child_a(i) <= ba;
                            child_b(i) <= bb;
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;

end architecture;