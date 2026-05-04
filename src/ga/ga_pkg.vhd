library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package ga_pkg is

    type t_human_sudoku is array (1 to 9, 1 to 9) of integer range 0 to 9;

    -- Sudoku Size
    constant chr_size : natural := 324;
    constant susi : natural := 9;
    constant susiro : natural := natural(sqrt(real(susi)));
    constant blsi : natural := natural(ceil(log2(real(susi))));

    function serialize_sudoku(
        human_sudoku : t_human_sudoku
    ) return std_logic_vector;

    function col_conflicts(
        l_chr : std_logic_vector(chr_size-1 downto 0);
        col : integer range 0 to susi-1
    ) return unsigned;

    function row_conflicts(
        l_chr : std_logic_vector(chr_size-1 downto 0);
        row : integer range 0 to susi-1
    ) return unsigned;

    function block_conflicts(
        l_chr : std_logic_vector(chr_size-1 downto 0);
        br : integer range 0 to 3-1;
        bc : integer range 0 to 3-1
    ) return unsigned;

    function valid_known(
        l_chr : std_logic_vector(chr_size-1 downto 0);
        k_chr : std_logic_vector(chr_size-1 downto 0)
    ) return std_logic;

end package;

package body ga_pkg is

    function serialize_sudoku(
        human_sudoku : t_human_sudoku
    ) return std_logic_vector is
        variable serialized : std_logic_vector(323 downto 0);
    begin
        for row in 0 to 8 loop
            for col in 0 to 8 loop
                if human_sudoku(row+1, col+1) /= 0 then
                    serialized(blsi*(col+susi*row+1)-1 downto blsi*(col+susi*row)) := std_logic_vector(to_unsigned(human_sudoku(row+1, col+1) - 1, 4));
                else
                    serialized(blsi*(col+susi*row+1)-1 downto blsi*(col+susi*row)) := std_logic_vector(to_unsigned(9, 4));
                end if;
            end loop;
        end loop;
        return serialized;
    end function;

    function col_conflicts(
        l_chr : std_logic_vector(chr_size-1 downto 0);
        col : integer range 0 to susi-1
    ) return unsigned is
        variable mask : std_logic_vector(susi-1 downto 0);
        variable conflicts : unsigned(blsi-1 downto 0);
        variable val : integer range 0 to susi-1;
    begin
        mask := (others => '0');
        conflicts := (others => '0');
        for row in 0 to susi-1 loop
            val := to_integer(unsigned(l_chr(
                blsi*(col+susi*row+1)-1 downto blsi*(col+susi*row)
            )));

            if mask(val) = '1' then
                conflicts := conflicts + 1;
            end if;
            mask(val) := '1';
        end loop;
        return conflicts;
    end function;

    function row_conflicts(
        l_chr : std_logic_vector(chr_size-1 downto 0);
        row : integer range 0 to susi-1
    ) return unsigned is
        variable mask : std_logic_vector(susi-1 downto 0);
        variable conflicts : unsigned(blsi-1 downto 0);
        variable val : integer range 0 to susi-1;
    begin
        mask := (others => '0');
        conflicts := (others => '0');
        for col in 0 to susi-1 loop
            val := to_integer(unsigned(l_chr(
                blsi*(col+susi*row+1)-1 downto blsi*(col+susi*row)
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
        br : integer range 0 to 3-1;
        bc : integer range 0 to 3-1
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

    function valid_known(
        l_chr : std_logic_vector(chr_size-1 downto 0);
        k_chr : std_logic_vector(chr_size-1 downto 0)
    ) return std_logic is
        variable valid : std_logic;
        variable l_val : integer range 0 to susi-1;
        variable k_val : integer range 0 to susi;
    begin
        valid := '1';
        for i in 0 to chr_size/blsi-1 loop
            l_val := to_integer(unsigned(l_chr(blsi*(i+1)-1 downto blsi*i)));
            k_val := to_integer(unsigned(k_chr(blsi*(i+1)-1 downto blsi*i)));
            if k_val /= 9 and l_val /= k_val then
                valid := '0';
            end if;
        end loop;
        return valid;
    end function;

end package body;