library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.ga_pkg.all;

-- entity fitness is
--     generic (
--         chr_size : natural := 324;
--         fp_size : natural := 8;
--         fp_frac : natural := 0;
--         data_size : natural := 0
--     );
--     port (
--         clk : in std_logic;
--         start : in std_logic;
--         chr : in std_logic_vector(chr_size-1 downto 0);
--         di : in std_logic_vector(data_size-1 downto 0);
--         do : out std_logic_vector(data_size-1 downto 0);
--         fit : out std_logic_vector(fp_size-1 downto 0);
--         done : out std_logic
--     );
-- end entity;

architecture sudoku of fitness is

    type t_line_conflicts is array (0 to 8) of unsigned(3 downto 0);
    type t_blk_conflicts is array (0 to 2, 0 to 2) of unsigned(3 downto 0);
    signal row_c : t_line_conflicts;
    signal col_c : t_line_conflicts;
    signal blk_c : t_blk_conflicts;

    signal adder_values : std_logic_vector(215 downto 0);
    signal adder_start : std_logic;
    signal adder_di : std_logic_vector(data_size downto 0);

    signal adder_sum : std_logic_vector(7 downto 0);
    signal adder_done : std_logic;
    signal adder_do : std_logic_vector(data_size downto 0);

begin

    adder: entity work.adder_tree
        generic map(
            n => 27,
            size => 8,
            data_size => data_size+1
        )
        port map(
            clk => clk,
            rst => rst,
            start => adder_start,
            values => adder_values,
            sum => adder_sum,
            done => adder_done,
            di => adder_di,
            do => adder_do
        );
    
    gen_values_line: for i in 0 to 8 generate
        adder_values(8*(i+1)-1 downto 8*i) <= std_logic_vector(resize(row_c(i), 8));
        adder_values(9*8+8*(i+1)-1 downto 9*8+8*i) <= std_logic_vector(resize(col_c(i), 8));
    end generate;
    gen_values_blk: for br in 0 to 2 generate
        gen_values_blk_inner: for bc in 0 to 2 generate
            adder_values(2*9*8+8*(bc+3*br+1)-1 downto 2*9*8+8*(bc+3*br)) <= std_logic_vector(resize(blk_c(br, bc), 8));
        end generate;
    end generate;

    process (clk)
    begin
        if rising_edge(clk) then
            if start = '1' then
                adder_di <= valid_known(chr, const) & di;

                for i in 0 to 8 loop
                    row_c(i) <= row_conflicts(chr, i);
                    col_c(i) <= col_conflicts(chr, i);
                end loop;

                for br in 0 to 2 loop
                    for bc in 0 to 2 loop
                        blk_c(br, bc) <= block_conflicts(chr, br, bc);
                    end loop;
                end loop;
            end if;

            if adder_done = '1' then
                if data_size > 0 then
                    do <= adder_do(data_size-1 downto 0);
                end if;
                if adder_do(data_size) = '1' then
                    fit <= adder_sum;
                    -- report "[fitness] fit=" & integer'image(to_integer(unsigned(adder_sum))) & " (conflicts)" severity note;
                else
                    fit <= (others => '1');
                end if;
            end if;

            if rst = '1' then
                done <= '0';
                adder_start <= '0';
            else
                done <= adder_done;
                adder_start <= start;
            end if;
        end if;
    end process;

end architecture;