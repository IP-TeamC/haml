library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

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
--         data_in : in std_logic_vector(data_size-1 downto 0);
--         data_out : out std_logic_vector(data_size-1 downto 0);
--         fit : out std_logic_vector(fp_size-1 downto 0);
--         done : out std_logic
--     );
-- end entity;

architecture sudoku of fitness is

    -- Sudoku Size
    constant susi : natural := 9;
    constant susiro : natural := natural(sqrt(real(susi)));
    constant blsi : natural := natural(ceil(log2(real(susi))));

    function line_conflicts(
        l_chr : std_logic_vector(chr_size-1 downto 0);
        line1 : integer range 0 to susi-1
    ) return unsigned is
        variable mask : std_logic_vector(susi-1 downto 0);
        variable conflicts : unsigned(blsi-1 downto 0);
        variable val : integer range 0 to susi-1;
    begin
        mask := (others => '0');
        conflicts := (others => '0');
        for line2 in 0 to susi-1 loop
            val := to_integer(unsigned(l_chr(
                blsi*(line1+susi*line2+1)-1 downto blsi*(line1+susi*line2)
            )));

            if mask(val) = '1' then
                conflicts := conflicts + 1;
            end if;
            mask(val) := '1';
        end loop;
        return conflicts;
    end function;

    function block_conflicts(
        l_chr : std_logic_vector(chr_size-1 downto 0);
        br : integer range 0 to susiro-1;
        bc : integer range 0 to susiro-1
    ) return unsigned is
        variable mask : std_logic_vector(susi-1 downto 0);
        variable conflicts : unsigned(blsi-1 downto 0);
        variable val : integer range 0 to susi-1;
    begin
        mask := (others => '0');
        conflicts := (others => '0');
        for ro in 0 to susiro-1 loop
            for co in 0 to susiro-1 loop
            val := to_integer(unsigned(l_chr(
                blsi*(susiro*(bc+susi*br)+co+susi*ro+1)-1 downto blsi*(susiro*(bc+susi*br)+co+susi*ro)
            )));

            if mask(val) = '1' then
                conflicts := conflicts + 1;
            end if;
            mask(val) := '1';
            end loop;
        end loop;
        return conflicts;
    end function;

begin

    process (clk)
    begin
        if rising_edge(clk) then
            if start = '1' then
                
            end if;
        end if;
    end process;

end architecture;