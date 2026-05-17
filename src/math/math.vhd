library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package math is

    function fp_mul(
        a : signed;
        b : signed;
        frac_size : natural
    ) return signed;

    function flat_vec(
        vec : std_logic_vector;
        size : natural;
        i : natural
    ) return std_logic_vector;

    function flat_vec_slice(
        vec : std_logic_vector;
        size : natural;
        i : natural;
        upper : natural;
        lower : natural
    ) return std_logic_vector;

    function flat_signed(
        vec : std_logic_vector;
        size : natural;
        i : natural
    ) return signed;

    function flat_signed_slice(
        vec : std_logic_vector;
        size : natural;
        i : natural;
        upper : natural;
        lower : natural
    ) return signed;

    function flat_unsigned(
        vec : std_logic_vector;
        size : natural;
        i : natural
    ) return unsigned;

    function flat_unsigned_slice(
        vec : std_logic_vector;
        size : natural;
        i : natural;
        upper : natural;
        lower : natural
    ) return unsigned;

    function flat_upper(
        size : natural;
        i : natural
    ) return natural;

    function flat_lower(
        size : natural;
        i : natural
    ) return natural;

    function calc_signed_dist_sq_size(
        fp_size : natural;
        extend : boolean
    ) return natural;

end package;

package body math is

    function fp_mul(
        a : signed;
        b : signed;
        frac_size : natural
    ) return signed is
        variable res : signed(2*a'length-1 downto 0);
        variable all_zero : signed(res'range) := (others => '0');
        variable all_one : signed(res'range) := (others => '1');
    begin
        res := a * b;
        -- TODO Logging entfernen
        if res(res'high downto a'length+frac_size) /= all_zero(res'high downto a'length+frac_size)
            and not
                (res(res'high downto a'length+frac_size) = all_one(res'high downto a'length+frac_size)
                and res(a'length+frac_size-1) = '1') then
            work.util.print(res(res'high downto a'length+frac_size));
            work.util.print(res(a'length+frac_size-1 downto frac_size));
            work.util.print(res(frac_size-1 downto 0));
            report "overflow!!!" severity failure;
        end if;

        return res(a'length+frac_size-1 downto frac_size);
    end function;

    function flat_vec(
        vec : std_logic_vector;
        size : natural;
        i : natural
    ) return std_logic_vector is
    begin
        return vec((i+1)*size-1 downto i*size);
    end function;

    function flat_vec_slice(
        vec : std_logic_vector;
        size : natural;
        i : natural;
        upper : natural;
        lower : natural
    ) return std_logic_vector is
        variable unflattened : std_logic_vector(size-1 downto 0);
    begin
        unflattened := vec((i+1)*size-1 downto i*size);
        return unflattened(upper downto lower);
    end function;

    function flat_signed(
        vec : std_logic_vector;
        size : natural;
        i : natural
    ) return signed is
    begin
        return signed(flat_vec(vec, size, i));
    end function;

    function flat_signed_slice(
        vec : std_logic_vector;
        size : natural;
        i : natural;
        upper : natural;
        lower : natural
    ) return signed is
    begin
        return signed(flat_vec_slice(vec, size, i, upper, lower));
    end function;

    function flat_unsigned(
        vec : std_logic_vector;
        size : natural;
        i : natural
    ) return unsigned is
    begin
        return unsigned(flat_vec(vec, size, i));
    end function;

    function flat_unsigned_slice(
        vec : std_logic_vector;
        size : natural;
        i : natural;
        upper : natural;
        lower : natural
    ) return unsigned is
    begin
        return unsigned(flat_vec_slice(vec, size, i, upper, lower));
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

    function calc_signed_dist_sq_size(
        fp_size : natural;
        extend : boolean
    ) return natural is
    begin
        if extend then
            return 2 * fp_size;
        else
            return fp_size;
        end if;
    end function;

end package body;
