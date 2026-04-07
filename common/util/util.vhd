library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package util is
    
    function to_string (vec : std_logic_vector)
    return string;

    function to_string (vec : signed)
    return string;

    function to_string (vec : unsigned)
    return string;

    procedure print (vec : std_logic_vector);

    procedure print (vec : signed);

    procedure print (vec : unsigned);

end package;

package body util is

    function to_string (vec : std_logic_vector)
    return string is
        variable str : string(vec'length downto 0) := (others => NUL);
    begin
        for i in vec'range loop
            str(i) := std_logic'image(vec(i))(2);
        end loop;
        return str;
    end function;

    function to_string (vec : signed)
    return string is
    begin
        return to_string(std_logic_vector(vec));
    end function;

    function to_string (vec : unsigned)
    return string is
    begin
        return to_string(std_logic_vector(vec));
    end function;

    procedure print (vec : std_logic_vector) is
    begin
        report to_string(vec);
    end procedure;

    procedure print (vec : signed) is
    begin
        print(std_logic_vector(vec));
    end procedure;
    
    procedure print (vec : unsigned) is
    begin
        print(std_logic_vector(vec));
    end procedure;

end package body;
