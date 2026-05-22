library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

package util is

    constant DEBUG_ENABLE : boolean := false;

    function to_string(vec : std_logic_vector) return string;
    function to_string(vec : signed) return string;
    function to_string(vec : unsigned) return string;

    procedure print(vec : std_logic_vector);
    procedure print(vec : signed);
    procedure print(vec : unsigned);
    procedure print(msg : string);

    procedure debug_print(msg : string);
    procedure debug_print(prefix : string; vec : std_logic_vector);
    procedure debug_print(prefix : string; vec : signed);
    procedure debug_print(prefix : string; vec : unsigned);

end package;

package body util is

    function to_string(vec : std_logic_vector)
    return string is
        variable str : string(1 to vec'length);
        variable str_i : integer := 1;
    begin
        for i in vec'range loop
            case vec(i) is
                when '0' => str(str_i) := '0';
                when '1' => str(str_i) := '1';
                when 'U' => str(str_i) := 'U';
                when 'X' => str(str_i) := 'X';
                when 'Z' => str(str_i) := 'Z';
                when 'W' => str(str_i) := 'W';
                when 'L' => str(str_i) := 'L';
                when 'H' => str(str_i) := 'H';
                when '-' => str(str_i) := '-';
                when others => str(str_i) := '?';
            end case;
            str_i := str_i + 1;
        end loop;
        return str;
	 end function;

    -- to_string

    function to_string(vec : signed) return string is
    begin
        return to_string(std_logic_vector(vec));
    end function;

    function to_string(vec : unsigned) return string is
    begin
        return to_string(std_logic_vector(vec));
    end function;

    -- print

    procedure print(vec : std_logic_vector) is
    begin
        report to_string(unsigned(vec));
    end procedure;

    procedure print(vec : signed) is
    begin
        report to_string(unsigned(vec));
    end procedure;

    procedure print(vec : unsigned) is
    begin
        report to_string(vec);
    end procedure;

    procedure print(msg : string) is
    begin
        report msg;
    end procedure;

    -- debug_print

    procedure debug_print(msg : string) is
    begin
        if DEBUG_ENABLE then
            report "[DEBUG] " & msg;
        end if;
    end procedure;

    procedure debug_print(prefix : string; vec : std_logic_vector) is
    begin
        if DEBUG_ENABLE then
            report "[DEBUG] " & prefix & ": " & to_string(vec);
        end if;
    end procedure;

    procedure debug_print(prefix : string; vec : signed) is
    begin
        if DEBUG_ENABLE then
            report "[DEBUG] " & prefix & ": " & to_string(vec);
        end if;
    end procedure;

    procedure debug_print(prefix : string; vec : unsigned) is
    begin
        if DEBUG_ENABLE then
            report "[DEBUG] " & prefix & ": " & to_string(vec);
        end if;
    end procedure;

end package body;
