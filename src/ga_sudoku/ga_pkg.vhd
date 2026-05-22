library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package ga_pkg is

    constant debug : boolean := true;

    -- Sudoku Size
    constant sudoku_size : natural := 9; -- Sudoku-Seitenlänge
    constant cell_bits : natural := 4; -- Bits pro Zelle zum Darstellen der Zahlen (ceil(log2(9+1))=4)
    constant chr_size : natural := sudoku_size * sudoku_size * cell_bits; -- Chromosomenlänge (324 Bit)
    constant block_size : natural := 3; -- 3x3-Blöcke
    constant blocks_per_side : natural := sudoku_size / block_size; -- Anzahl der Blöcke nebeneinander (3)

    -- Wert "leer" Encoding
    constant empty_encoding : natural := 0;

    type t_human_sudoku is array (1 to sudoku_size, 1 to sudoku_size) of integer range 0 to sudoku_size;

    -- Serialisierung & Deserialisierung

    function serialize_sudoku(
        human_sudoku : t_human_sudoku
    ) return std_logic_vector;

    function deserialize_sudoku(
        chr : std_logic_vector(chr_size-1 downto 0)
    ) return t_human_sudoku;

    -- Zellzugriff

    -- Gibt den 4-Bit-Wert der Zelle (row, col) aus einem Chromosom zurück
    function get_cell(
        chr : std_logic_vector(chr_size-1 downto 0);
        row : integer range 1 to sudoku_size; -- 1-basiert
        col : integer range 1 to sudoku_size  -- 1-basiert
    ) return std_logic_vector;
 
    -- Gibt den 4-Bit-Wert einer Zelle über den flachen Index zurück
    function get_cell_flat(
        chr : std_logic_vector(chr_size-1 downto 0);
        idx : integer range 1 to sudoku_size*sudoku_size
    ) return std_logic_vector;
 
    -- Konfliktzähler

    function col_conflicts(
        chr : std_logic_vector(chr_size-1 downto 0);
        col : integer range 0 to sudoku_size-1
    ) return unsigned;

    function row_conflicts(
        chr : std_logic_vector(chr_size-1 downto 0);
        row : integer range 0 to sudoku_size-1
    ) return unsigned;

    function block_conflicts(
        chr : std_logic_vector(chr_size-1 downto 0);
        br : integer range 0 to blocks_per_side - 1;
        bc : integer range 0 to blocks_per_side - 1
    ) return unsigned;

    -- Prüft ob alle festen Zellen korrekt übereinstimmen
    function valid_known(
        chr : std_logic_vector(chr_size-1 downto 0);
        mask : std_logic_vector(chr_size-1 downto 0)
    ) return std_logic;

    procedure print_sudoku(sol : t_human_sudoku);

end package;

package body ga_pkg is
    
    function cell_lo(row, col : integer) return natural is
    begin
        return cell_bits * ((col - 1) + sudoku_size * (row - 1));
    end function;
 
    function get_cell(
        chr : std_logic_vector(chr_size-1 downto 0);
        row : integer range 1 to sudoku_size;
        col : integer range 1 to sudoku_size
    ) return std_logic_vector is
        variable lo : natural := cell_lo(row, col);
    begin
        return chr(lo + cell_bits - 1 downto lo);
    end function;
 
    function get_cell_flat(
        chr : std_logic_vector(chr_size-1 downto 0);
        idx : integer range 1 to sudoku_size*sudoku_size
    ) return std_logic_vector is
        variable lo : natural := cell_bits * (idx - 1);
    begin
        return chr(lo + cell_bits - 1 downto lo);
    end function;

    function serialize_sudoku(
        human_sudoku : t_human_sudoku
    ) return std_logic_vector is
        variable serialized : std_logic_vector(323 downto 0);
        variable lo : natural;
        variable v : natural;
    begin
        for row in 1 to sudoku_size loop
            for col in 1 to sudoku_size loop
                lo := cell_lo(row, col);
                v := human_sudoku(row, col);
                if v = 0 then
                    serialized(lo + cell_bits - 1 downto lo) := std_logic_vector(to_unsigned(empty_encoding, cell_bits));
                else
                    serialized(lo + cell_bits - 1 downto lo) := std_logic_vector(to_unsigned(v, cell_bits));
                end if;
            end loop;
        end loop;
        return serialized;
    end function;

    function deserialize_sudoku(
        chr : std_logic_vector(chr_size-1 downto 0)
    ) return t_human_sudoku is
        variable result : t_human_sudoku;
        variable lo : natural;
        variable val : natural;
    begin
        for row in 1 to sudoku_size loop
            for col in 1 to sudoku_size loop
                lo := cell_lo(row, col);
                val  := to_integer(unsigned(chr(lo + cell_bits - 1 downto lo)));
                if val = empty_encoding or val > sudoku_size then
                    result(row, col) := 0;
                else
                    result(row, col) := val;
                end if;
            end loop;
        end loop;
        return result;
    end function;

    function col_conflicts(
        chr : std_logic_vector(chr_size-1 downto 0);
        col : integer range 0 to sudoku_size-1
    ) return unsigned is
        variable mask : std_logic_vector(sudoku_size downto 1) := (others => '0');
        variable conflicts : unsigned(cell_bits-1 downto 0) := (others => '0');
        variable val : integer range 0 to 2**cell_bits-1;
    begin
        for row in 1 to sudoku_size loop
            val := to_integer(unsigned(get_cell(chr, row, col + 1)));
            if val = empty_encoding or val > sudoku_size then
                conflicts := conflicts + 1; 
            elsif mask(val) = '1' then
                conflicts := conflicts + 1; 
            else
                mask(val) := '1';
            end if;
        end loop;
        return conflicts;
    end function;

    function row_conflicts(
        chr : std_logic_vector(chr_size-1 downto 0);
        row : integer range 0 to sudoku_size-1
    ) return unsigned is
        variable mask : std_logic_vector(sudoku_size downto 1) := (others => '0');
        variable conflicts : unsigned(cell_bits-1 downto 0) := (others => '0');
        variable val : integer range 0 to 2**cell_bits-1;
    begin
        for col in 1 to sudoku_size loop
            val := to_integer(unsigned(get_cell(chr, row + 1, col)));

            if val = empty_encoding or val > sudoku_size then
                conflicts := conflicts + 1; 
            elsif mask(val) = '1' then
                conflicts := conflicts + 1; 
            else
                mask(val) := '1';
            end if;
        end loop;
        return conflicts;
    end function;

    function block_conflicts(
        chr : std_logic_vector(chr_size-1 downto 0);
        br : integer range 0 to blocks_per_side - 1;
        bc : integer range 0 to blocks_per_side - 1
    ) return unsigned is
        variable mask : std_logic_vector(sudoku_size downto 1) := (others => '0');
        variable conflicts : unsigned(cell_bits-1 downto 0) := (others => '0');
        variable ro, co : integer;
        variable val : integer range 0 to 2**cell_bits-1;
    begin
        for row in 1 to block_size loop
            for col in 1 to block_size loop

                ro := br * block_size + row;
                co := bc * block_size + col;
                val := to_integer(unsigned(get_cell(chr, ro, co)));

                if val = empty_encoding or val > sudoku_size then
                    conflicts := conflicts + 1; 
                elsif mask(val) = '1' then
                    conflicts := conflicts + 1; 
                else
                    mask(val) := '1';
                end if;
            end loop;
        end loop;
        return conflicts;
    end function;

    function valid_known(
        chr : std_logic_vector(chr_size-1 downto 0);
        mask : std_logic_vector(chr_size-1 downto 0)
    ) return std_logic is
        variable lo : natural;
    begin
        for i in 0 to sudoku_size*sudoku_size-1 loop
            lo := cell_bits * i;
            if mask(lo + cell_bits - 1 downto lo) /= (cell_bits-1 downto 0 => '0') then
                if chr(lo + cell_bits - 1 downto lo) /= mask(lo + cell_bits - 1 downto lo) then
                    return '0';
                end if;
            end if;
        end loop;
        return '1';
    end function;

    procedure print_sudoku(sol : t_human_sudoku) is
        variable line : string(1 to 25);
        variable b, k, idx : integer;
    begin
            report "+-------+-------+-------+"; -- Extra eingerückt für besseres Printing
        for row in 1 to sudoku_size loop
            line := (others => ' ');
            for col in 1 to sudoku_size loop

                b := (col - 1) / 3;
                k := (col - 1) rem 3;
                idx := 2 + (b * 9) + (k * 2);

                if sol(row, col) = 0 then
                    line(idx) := '.';
                else
                    line(idx) := character'val(sol(row,col) + character'pos('0'));
                end if;
            end loop;
            report "|" & line(1 to 7) & "|" & line(10 to 16) & "|" & line(19 to 25) & "|";
            if row = 3 or row = 6 then
                report "+-------+-------+-------+";
            end if;
        end loop;
            report "+-------+-------+-------+"; -- Extra eingerückt für besseres Printing
    end procedure;

end package body;