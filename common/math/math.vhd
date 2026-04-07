library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package math is

    function fp_mul(
        a : in signed;
        b : in signed;
        frac_size : in natural
    ) return signed;

end package;

package body math is

    function fp_mul(
        a : in signed;
        b : in signed;
        frac_size : in natural
    ) return signed is
        variable res : signed(2*a'length-1 downto 0);
    begin
        res := a * b;
        return res(a'length+frac_size-1 downto frac_size);
    end function;

end package body;
