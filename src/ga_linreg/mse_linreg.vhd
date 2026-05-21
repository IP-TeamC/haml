library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.math.all;

entity mse_linreg is
    generic (
        var_num : natural;
        fp_size : natural;
        fp_frac : natural;
        adr_size : natural
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;
        chr : in std_logic_vector(fp_size*(var_num+1)-1 downto 0);

        ram_data : in std_logic_vector(fp_size*(var_num+1)-1 downto 0);

        fit : out std_logic_vector(fp_size-1 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of mse_linreg is

    type t_dp is array (0 to var_num) of signed(fp_size-1 downto 0);
    type t_dp_neg1 is array (0 to var_num) of std_logic;
    signal mul_dp : t_dp;
    signal mul_dp_neg1 : t_dp_neg1;
    signal mul_chr_neg1 : t_dp_neg1;
    signal dp_done : std_logic;

    signal mul_expected : std_logic_vector(fp_size-1 downto 0);
    signal mul_done : std_logic;

    constant adder_extra_bits : natural := natural(ceil(log2(real(var_num+1))));
    signal adder_values : std_logic_vector((adder_extra_bits+fp_size)*(var_num+1)-1 downto 0);
    signal adder_done : std_logic;
    signal adder_sum : std_logic_vector(adder_extra_bits+fp_size-1 downto 0);
    signal adder_expected : std_logic_vector(fp_size-1 downto 0);

    signal diff : signed(adder_extra_bits+fp_size downto 0);
    signal diff_done : std_logic;
    signal diff_sq : unsigned(2*(adder_extra_bits+fp_size+1)-1 downto 0);
    signal diff_sq_done : std_logic;

    constant err_extra_bits : natural := adr_size;
    signal err : unsigned(err_extra_bits+2*(adder_extra_bits+fp_size+1)-1 downto 0);
    signal err_done : std_logic;

    constant neg1 : signed(fp_size-1 downto 0) := rotate_right(to_signed(1, fp_size), 1);
    --constant pos1 : std_logic_vector(fp_size-1 downto 0) := std_logic_vector(not(neg1));

    signal s_chr : std_logic_vector(fp_size*(var_num+1)-1 downto 0);

begin

    fit <= std_logic_vector(err(err_extra_bits+2*(adder_extra_bits+fp_size+1)-1 downto err_extra_bits+2*(adder_extra_bits+fp_size+1)-fp_size));

    -- Stage 1: RAM-Daten in Register zwischenspeichern
    process (clk)
    begin
        if rising_edge(clk) then
            for i in 0 to var_num loop
                mul_dp(i) <= flat_signed(ram_data, fp_size, i);
                if flat_signed(ram_data, fp_size, i) = neg1 then
                    mul_dp_neg1(i) <= '1';
                else
                    mul_dp_neg1(i) <= '0';
                end if;
                if flat_signed(chr, fp_size, i) = neg1 then
                    mul_chr_neg1(i) <= '1';
                else
                    mul_chr_neg1(i) <= '0';
                end if;
            end loop;
        end if;
    end process;

    -- Stage 2: Multiplikation der Koeffizienten mit Datenpunkt
    process (clk)
    begin
        if rising_edge(clk) then
            mul_expected <= std_logic_vector(mul_dp(0));
            if dp_done = '1' and mul_done = '0' then
                work.util.print(chr);
                s_chr <= chr;
                assert mul_dp(0) = "100000000000000000" severity failure;
                assert mul_dp(1) = "100000000000000000" severity failure;
            end if;
            if dp_done = '1' and mul_done = '1' then
                assert s_chr = chr severity failure;
            end if;
            if dp_done = '1' and start = '0' then
                s_chr <= chr;
                assert mul_dp(0) = "011111111111111111" severity failure;
                assert mul_dp(1) = "011111111111111111" severity failure;
            end if;
            --work.util.print(chr);
            -- adder_values(adder_extra_bits+fp_size-1 downto 0) <= std_logic_vector(resize(signed(chr(fp_size-1 downto 0)), adder_extra_bits+fp_size));
            adder_values(adder_extra_bits+fp_size-1 downto 0) <= std_logic_vector(resize(signed(chr(fp_size-1 downto 0)), adder_extra_bits+fp_size));
            for i in 1 to var_num loop
                -- Multiplikation normalisiert zwischen -1 und +1 ist in demselben Wertebereich (aber Verlust von Genauigkeit)
                if dp_done = '1' and not (mul_chr_neg1(i) = '1' and mul_dp_neg1(i) = '1') then -- TODO dp_done entfernen, nicht notwendig
                    --report "mx_mse_ur: " & work.util.to_string(fp_mul(flat_signed(chr, fp_size, i), mul_dp(i), fp_frac));
                    --report "mx_mse: " & work.util.to_string(resize(fp_mul(flat_signed(chr, fp_size, i), mul_dp(i), fp_frac), adder_extra_bits+fp_size));
                    adder_values(flat_upper(adder_extra_bits+fp_size, i) downto flat_lower(adder_extra_bits+fp_size, i)) <= std_logic_vector(
                            resize(fp_mul(flat_signed(chr, fp_size, i), mul_dp(i), fp_frac), adder_extra_bits+fp_size)
                        );
                elsif dp_done = '1' then
                    assert false severity failure;
                    adder_values(flat_upper(adder_extra_bits+fp_size, i) downto flat_upper(adder_extra_bits+fp_size, i)-adder_extra_bits+1) <= (others => '0');
                    --adder_values(flat_upper(adder_extra_bits+fp_size, i)-adder_extra_bits downto flat_lower(adder_extra_bits+fp_size, i)) <= pos1;
                end if;
            end loop;
        end if;
    end process;

    -- Stage 3+: Addition der Multiplikationsergebnisse im Adder-Tree (Multi-Stage)
    adder_tree: entity work.adder_tree
        generic map(
            n => var_num+1,
            size => adder_extra_bits+fp_size,
            data_size => fp_size
        )
        port map(
            clk => clk,
            rst => rst,
            start => mul_done,
            values => adder_values,
            sum => adder_sum,
            done => adder_done,
            di => mul_expected,
            do => adder_expected
        );

    -- Stage 4: Differenz berechnen
    process (clk)
        variable tmp : signed(adder_extra_bits+fp_size downto 0);
    begin
        if rising_edge(clk) then
            tmp := resize(signed(adder_expected), adder_extra_bits+fp_size+1) - resize(signed(adder_sum), adder_extra_bits+fp_size+1);
            if adder_done = '1' then
                --report "y_mse: " & work.util.to_string(adder_sum);
                --report "e_mse: " & work.util.to_string(adder_expected);
                --report "diff_mse: " & work.util.to_string(tmp);
            end if;
            diff <= tmp;--(adder_extra_bits+fp_size downto adder_extra_bits+1);
        end if;
    end process;

    -- Stage 5: Differenz quadrieren
    process (clk)
    begin
        if rising_edge(clk) then
            if diff_done = '1' then --and diff /= neg1 then -- TODO dp_done entfernen, nicht notwendig
                diff_sq <= unsigned(diff * diff);
                --report "diff_sq_mse: " & work.util.to_string(unsigned(diff * diff));
            --elsif diff_done = '1' then
                --assert false severity failure;
                --diff_sq <= unsigned(pos1);
            end if;
        end if;
    end process;

    -- Stage 6: quadr. Differenz Akkumulieren
    process (clk)
    begin
        if rising_edge(clk) then
            if diff_sq_done = '1' then
                --report "err_add_mse: " & work.util.to_string(resize(diff_sq, err_extra_bits+2*(adder_extra_bits+fp_size+1)));
                --report "err_mse: " & work.util.to_string(err);
                if err_done = '1' then
                    err <= err + resize(diff_sq, err_extra_bits+2*(adder_extra_bits+fp_size+1));
                else
                    --report "neu erstllen";
                    err <= resize(diff_sq, err_extra_bits+2*(adder_extra_bits+fp_size+1));
                end if;
            end if;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                dp_done <= '0';
                mul_done <= '0';
                diff_done <= '0';
                diff_sq_done <= '0';
                err_done <= '0';
                done <= '0';
            else
                dp_done <= start;
                mul_done <= dp_done;
                diff_done <= adder_done;
                diff_sq_done <= diff_done;
                err_done <= diff_sq_done;
                done <= diff_sq_done and not diff_done;
            end if;
        end if;
    end process;

end architecture;