library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity crossover_mutation is
    generic (
        chr_size : natural := 324; -- Chromosombreite in Bit
        mut_bits : natural := 7    -- P(Mutation pro Zelle) = 0.5^mut_bits ? 0.78%
    );
    port (
        clk  : in std_logic;
        rst  : in std_logic;
        start: in std_logic;

        -- Bitmaske der festen Sudoku-Vorgaben (1 = feste Zelle, darf nicht verändert werden)
        const_mask : in std_logic_vector(chr_size-1 downto 0);

        -- Eltern
        chr_a : in std_logic_vector(chr_size-1 downto 0);
        chr_b : in std_logic_vector(chr_size-1 downto 0);

        -- Kinder
        child_a : out std_logic_vector(chr_size-1 downto 0);
        child_b : out std_logic_vector(chr_size-1 downto 0);

        -- Crossover-Punkt: ceil(log2(chr_size)) Bit
        rnd_cx  : in std_logic_vector(natural(ceil(log2(real(chr_size/4))))-1 downto 0);

        -- Mutationsmaske: cells * mut_bits Bit
        -- Pro Zelle mut_bits Zufallsbits für should_mutate,
        -- davon werden die oberen 4 Bit als neuer Zellwert für child_a genutzt,
        -- die unteren 4 Bit als neuer Zellwert für child_b
        rnd_mut : in std_logic_vector(chr_size*mut_bits-1 downto 0);

        done : out std_logic
    );
end entity;

architecture rtl of crossover_mutation is
    -- Sudoku: 4 Bit pro Zelle, 81 Zellen = 324 Bit
    constant cell_bits : natural := 4;
    constant cells     : natural := chr_size / cell_bits;  -- 81

    function should_mutate(
        rnd : std_logic_vector;  -- gesamter Mutationsvektor
        pos : natural;           -- Zellindex (0..cells-1)
        n   : natural            -- mut_bits
    ) return boolean is
        variable bits : std_logic_vector(n-1 downto 0);
        variable acc  : std_logic;
    begin
        bits := rnd(n*(pos+1)-1 downto n*pos);
        acc  := '1';
        for i in 0 to n-1 loop
            acc := acc and bits(i);
        end loop;
        return acc = '1';
    end function;

begin
    process(clk)
        variable cx_raw  : natural;
        variable cx_cell : natural range 0 to cells-1;  -- Crossover-Punkt auf Zellebene
        variable cell_a  : std_logic_vector(cell_bits-1 downto 0);
        variable cell_b  : std_logic_vector(cell_bits-1 downto 0);
        variable mut_a   : std_logic_vector(cell_bits-1 downto 0);
        variable mut_b   : std_logic_vector(cell_bits-1 downto 0);
        variable rnd_a   : unsigned(cell_bits-1 downto 0);
        variable rnd_b   : unsigned(cell_bits-1 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                done <= '0';
            else
                done <= start;

                if start = '1' then

                    -- report "==============================";
                    -- report "CROSSOVER_MUTATION START";
                    -- report "==============================";

                    cx_raw  := to_integer(unsigned(rnd_cx));
                    cx_cell := cx_raw mod cells;
                    
                    -- report "rnd_cx raw = "& integer'image(cx_raw);
                    -- report "cx_cell = "& integer'image(cx_cell);

                    for i in 0 to cells-1 loop

                        -- Aktuelle Zelle aus beiden Eltern lesen
                        cell_a := chr_a(cell_bits*(i+1)-1 downto cell_bits*i);
                        cell_b := chr_b(cell_bits*(i+1)-1 downto cell_bits*i);
                        
                        -- report "--------------------------------";
                        -- report "CELL " & integer'image(i);

                        -- report "parent A = "& integer'image(to_integer(unsigned(cell_a)));
                        -- report "parent B = "& integer'image(to_integer(unsigned(cell_b)));

                        if const_mask(cell_bits*(i+1)-1 downto cell_bits*i) /= (cell_bits-1 downto 0 => '0') then

                            -- report "CONST CELL";

                            -- Feste Zelle
                            child_a(cell_bits*(i+1)-1 downto cell_bits*i) <= cell_a;
                            child_b(cell_bits*(i+1)-1 downto cell_bits*i) <= cell_b;

                        else
                            -- Freie Zelle
                            if i < cx_cell then
                                mut_a := cell_a;
                                mut_b := cell_b;
                            else
                                mut_a := cell_b;
                                mut_b := cell_a;
                            end if;

                            if should_mutate(rnd_mut, i, mut_bits) then -- or unsigned(mut_a) > 8 or unsigned(mut_b) > 8 then

                                -- report "MUTATION ACTIVE";

                                rnd_a := unsigned(rnd_mut(4*i+3 downto 4*i)) mod 9;
                                rnd_b := unsigned(rnd_mut(4*i+7 downto 4*i+4)) mod 9;

                                -- report "raw rnd_a = "& integer'image(to_integer(rnd_a));
                                -- report "raw rnd_b = "& integer'image(to_integer(rnd_b));

                                if rnd_a > 8 then rnd_a := rnd_a mod 9; end if;
                                if rnd_b > 8 then rnd_b := rnd_b mod 9; end if;

                                child_a(cell_bits*(i+1)-1 downto cell_bits*i) <= std_logic_vector(rnd_a);
                                child_b(cell_bits*(i+1)-1 downto cell_bits*i) <= std_logic_vector(rnd_b);
                            else

                                -- report "NO MUTATION";

                                child_a(cell_bits*(i+1)-1 downto cell_bits*i) <= mut_a;
                                child_b(cell_bits*(i+1)-1 downto cell_bits*i) <= mut_b;

                                -- report "child_a final = "& integer'image(to_integer(unsigned(mut_a)));
                                -- report "child_b final = "& integer'image(to_integer(unsigned(mut_b)));
                            end if;
                        end if;
                    end loop;

                    -- report "==============================";
                    -- report "CROSSOVER_MUTATION END";
                    -- report "==============================";

                end if;
            end if;
        end if;
    end process;

end architecture;