library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.math.all;

entity mse_linreg is
    generic (
        var_num : natural := 2;
        fp_size : natural := 18;
        fp_frac : natural := 16
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
    signal mul_dp : t_dp;
    signal dp_done : std_logic;

    signal mul_expected : std_logic_vector(fp_size-1 downto 0);
    signal mul_done : std_logic;

    constant adder_extra_bits : natural := natural(ceil(log2(real(var_num)))); -- evtl. +1
    signal adder_values : std_logic_vector((adder_extra_bits+fp_size)*(var_num+1)-1 downto 0);
    signal adder_done : std_logic;
    signal adder_sum : std_logic_vector(adder_extra_bits+fp_size-1 downto 0);
    signal adder_expected : std_logic_vector(fp_size-1 downto 0);

    signal diff : signed(fp_size-1 downto 0);
    signal diff_done : std_logic;
    signal diff_sq : unsigned(fp_size-1 downto 0);
    signal diff_sq_done : std_logic;

    signal err : unsigned(fp_size-1 downto 0);
    signal err_done : std_logic;

begin

    fit <= std_logic_vector(err);
    done <= err_done;

    -- Stage 1: RAM-Daten in Register zwischenspeichern
    process (clk)
    begin
        if rising_edge(clk) then
            for i in 0 to var_num loop
                mul_dp(i) <= flat_signed(ram_data, fp_size, i);
            end loop;
        end if;
    end process;

    -- Stage 2: Multiplikation der Koeffizienten mit Datenpunkt
    process (clk)
    begin
        if rising_edge(clk) then
            mul_expected <= std_logic_vector(mul_dp(0));
            adder_values(adder_extra_bits+fp_size-1 downto 0) <= std_logic_vector(resize(signed(chr(fp_size-1 downto 0)), adder_extra_bits+fp_size));
            for i in 1 to var_num loop
                -- Multiplikation normalisiert zwischen -1 und +1 ist in demselben Wertebereich (aber Verlust von Genauigkeit)
                adder_values(flat_upper(adder_extra_bits+fp_size, i) downto flat_lower(adder_extra_bits+fp_size, i)) <= std_logic_vector(
                        resize(fp_mul(flat_signed(chr, fp_size, i), mul_dp(i), fp_frac), adder_extra_bits+fp_size)
                    );
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
        variable tmp : signed(adder_extra_bits+fp_size-1 downto 0);
    begin
        if rising_edge(clk) then
            tmp := resize(signed(adder_expected), adder_extra_bits+fp_size) - signed(adder_sum);
            diff <= tmp(adder_extra_bits+fp_size-1 downto adder_extra_bits);
        end if;
    end process;

    -- Stage 5: Differenz quadrieren
    process (clk)
    begin
        if rising_edge(clk) then
            diff_sq <= unsigned(fp_mul(diff, diff, fp_frac));
        end if;
    end process;

    -- Stage 6: quadr. Differenz Akkumulieren
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                err <= (others => '0');
            elsif diff_sq_done = '1' then
                -- evtl. Anpassung für Anzahl Datensätze (oder doppelt so viele Bits)
                err <= err + diff_sq;
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
            else
                dp_done <= start;
                mul_done <= dp_done;
                diff_done <= adder_done;
                diff_sq_done <= diff_done;
                err_done <= diff_sq_done;
            end if;
        end if;
    end process;

end architecture;