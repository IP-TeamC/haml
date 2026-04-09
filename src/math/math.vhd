library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package math is

    function fp_mul(
        a : signed;
        b : signed;
        frac_size : natural
    ) return signed;

    function flat_signed(
        vec : std_logic_vector;
        size : natural;
        i : natural
    ) return signed;

    function flat_upper(
        size : natural;
        i : natural
    ) return natural;

    function flat_lower(
        size : natural;
        i : natural
    ) return natural;

end package;

package body math is

    function fp_mul(
        a : signed;
        b : signed;
        frac_size : natural
    ) return signed is
        variable res : signed(2*a'length-1 downto 0);
    begin
        res := a * b;
        return res(a'length+frac_size-1 downto frac_size);
    end function;

    function flat_signed(
        vec : std_logic_vector;
        size : natural;
        i : natural
    ) return signed is
    begin
        return signed(vec((i+1)*size-1 downto i*size));
    end function;

    function flat_upper(
        size : natural;
        i : natural
    ) return natural is
    begin
        return (i+1)*size-1;
    end function;

    function flat_lower(
        size : natural;
        i : natural
    ) return natural is
    begin
        return i*size;
    end function;

end package body;
