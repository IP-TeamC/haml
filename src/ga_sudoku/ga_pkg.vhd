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

    constant DEBUG : boolean := false;

    function serialize_sudoku(
        human_sudoku : t_human_sudoku
    ) return std_logic_vector;

    function deserialize_sudoku(
        chr : std_logic_vector(chr_size-1 downto 0)
    ) return t_human_sudoku;

    procedure print_sudoku(sol : t_human_sudoku);

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

    procedure dbg(msg : string) is
    begin
        if DEBUG then
            report msg severity note;
        end if;
    end procedure;

    procedure print_sudoku(sol : t_human_sudoku) is
        variable row_str : string(1 to 27);
    begin
            report "+---------+---------+---------+";

        for row in 1 to 9 loop

            row_str := (others => ' ');

            for col in 1 to 9 loop
                if sol(row, col) = 0 then
                    row_str(col*3-2) := '.';
                else
                    row_str(col*3-2) :=
                        character'val(sol(row,col) + character'pos('0'));
                end if;
            end loop;

            report "| " & row_str(1 to 7)
                & " | " & row_str(10 to 16)
                & " | " & row_str(19 to 25) & " |";

            if row = 3 or row = 6 then
                report "+---------+---------+---------+";
            end if;

        end loop;

            report "+---------+---------+---------+";
    end procedure;


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

    function deserialize_sudoku(
        chr : std_logic_vector(chr_size-1 downto 0)
    ) return t_human_sudoku is
        variable result : t_human_sudoku;
        variable val : integer range 0 to blsi**2-1;
    begin
        for row in 0 to susi-1 loop
            for col in 0 to susi-1 loop
                val := to_integer(unsigned(chr(
                    blsi*(col + susi*row + 1)-1 downto blsi*(col + susi*row)
                )));
                if val >= susi then
                    result(row+1, col+1) := 0;
                else
                    result(row+1, col+1) := val + 1;
                end if;
            end loop;
        end loop;
        return result;
    end function;

    function col_conflicts(
        l_chr : std_logic_vector(chr_size-1 downto 0);
        col : integer range 0 to susi-1
    ) return unsigned is
        variable mask : std_logic_vector(susi-1 downto 0);
        variable conflicts : unsigned(blsi-1 downto 0);
        variable val : integer range 0 to blsi**2-1;
    begin
        mask := (others => '0');
        conflicts := (others => '0');
        for row in 0 to susi-1 loop
            val := to_integer(unsigned(l_chr(
                blsi*(col+susi*row+1)-1 downto blsi*(col+susi*row)
            )));

            dbg("[ROW] r=" & integer'image(row) &
                " c=" & integer'image(col) &
                " val=" & integer'image(val));

            if val >= susi then
                conflicts := conflicts + 1; -- leeres/ungültiges Feld
            else
                if mask(val) = '1' then
                    conflicts := conflicts + 1; -- Duplikat

                    dbg("  -> CONFLICT: value " &
                        integer'image(val) &
                        " already in row " &
                        integer'image(row));

                end if;
                mask(val) := '1';
            end if;
        end loop;
        return conflicts;
    end function;

    function row_conflicts(
        l_chr : std_logic_vector(chr_size-1 downto 0);
        row : integer range 0 to susi-1
    ) return unsigned is
        variable mask : std_logic_vector(susi-1 downto 0);
        variable conflicts : unsigned(blsi-1 downto 0);
        variable val : integer range 0 to blsi**2-1;
    begin
        mask := (others => '0');
        conflicts := (others => '0');
        for col in 0 to susi-1 loop
            val := to_integer(unsigned(l_chr(
                blsi*(col+susi*row+1)-1 downto blsi*(col+susi*row)
            )));

            dbg("[COL] c=" & integer'image(col) &
                " r=" & integer'image(row) &
                " val=" & integer'image(val));

            if val >= susi then
                conflicts := conflicts + 1; -- leeres/ungültiges Feld
            else
                if mask(val) = '1' then
                    conflicts := conflicts + 1; -- Duplikat

                    dbg("  -> CONFLICT: value " &
                        integer'image(val) &
                        " already in column " &
                        integer'image(col));

                end if;
                mask(val) := '1';
            end if;
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
        variable val : integer range 0 to blsi**2-1;
    begin
        mask := (others => '0');
        conflicts := (others => '0');
        for ro in 0 to susiro-1 loop
            for co in 0 to susiro-1 loop
                val := to_integer(unsigned(l_chr(
                    blsi*(susiro*(bc+susi*br)+co+susi*ro+1)-1 downto blsi*(susiro*(bc+susi*br)+co+susi*ro)
                )));

                dbg("[BLOCK] br=" & integer'image(br) &
                    " bc=" & integer'image(bc) &
                    " val=" & integer'image(val));

                if val >= susi then
                    conflicts := conflicts + 1;  -- leeres/ungültiges Feld
                else
                    if mask(val) = '1' then
                        conflicts := conflicts + 1; -- Duplikat

                        dbg("  -> BLOCK CONFLICT value=" &
                            integer'image(val));

                    end if;
                    mask(val) := '1';
                end if;
            end loop;
        end loop;
        return conflicts;
    end function;

    function valid_known(
        l_chr : std_logic_vector(chr_size-1 downto 0);
        k_chr : std_logic_vector(chr_size-1 downto 0)
    ) return std_logic is
        variable valid : std_logic;
        variable l_val : integer range 0 to blsi**2-1;
        variable k_val : integer range 0 to blsi**2-1;
    begin
        valid := '1';
        for i in 0 to susi*susi-1 loop
            l_val := to_integer(unsigned(l_chr(blsi*(i+1)-1 downto blsi*i)));
            k_val := to_integer(unsigned(k_chr(blsi*(i+1)-1 downto blsi*i)));
            if k_val /= susi and l_val /= k_val then
                valid := '0';
            end if;
        end loop;
        return valid;
    end function;

end package body;