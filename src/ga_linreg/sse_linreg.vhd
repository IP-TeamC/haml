library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.math.all;

entity sse_linreg is
    generic (
        var_num : natural;
        fp_size : natural;
        fp_frac : natural;
        adr_size : natural
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        valid : in std_logic;
        chr : in std_logic_vector(fp_size*(var_num+1)-1 downto 0);

        ram_dp_do : in std_logic_vector(fp_size*(var_num+1)-1 downto 0);

        fit : out std_logic_vector(fp_size-1 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of sse_linreg is

    type t_reg_chr is array (0 to var_num) of signed(fp_size-1 downto 0);
    type t_reg_dp is array (0 to var_num) of signed(fp_size-1 downto 0);
    type t_reg_neg1 is array (0 to var_num) of std_logic;
    signal reg_chr : t_reg_chr;
    signal reg_dp : t_reG_dp;
    signal reg_valid : std_logic;

    signal mul_expected : std_logic_vector(fp_size-1 downto 0);
    signal mul_neg1 : t_reg_neg1;
    signal mul_valid : std_logic;

    constant adder_extra_bits : natural := natural(ceil(log2(real(var_num+1))));
    type t_adder_values is array (0 to var_num) of std_logic_vector(adder_extra_bits+fp_size-1 downto 0);
    signal adder_values : t_adder_values;
    signal adder_values_flat : std_logic_vector((adder_extra_bits+fp_size)*(var_num+1)-1 downto 0);
    signal adder_valid : std_logic;
    signal adder_sum : std_logic_vector(adder_extra_bits+fp_size-1 downto 0);
    signal adder_expected : std_logic_vector(fp_size-1 downto 0);

    signal diff : signed(fp_size-1 downto 0);
    signal diff_neg1 : std_logic;
    signal diff_valid : std_logic;

    signal diff_sq : unsigned(2*fp_size-3 downto 0);
    signal diff_sq_neg1 : std_logic;
    signal diff_sq_valid : std_logic;

    constant err_extra_bits : natural := adr_size;
    signal err : unsigned(err_extra_bits+2*fp_size-3 downto 0);
    signal err_valid : std_logic;

    function create_pos1_adder_values return std_logic_vector is
        variable tmp : std_logic_vector(adder_extra_bits+fp_size-1 downto 0);
    begin
        tmp(adder_extra_bits+fp_size-1 downto fp_size-1) := (others => '0');
        tmp(fp_size-2 downto 0) := (others => '1');
        return tmp;
    end function;

    constant pos1_adder_values : std_logic_vector(adder_values(0)'range) := create_pos1_adder_values;
    constant pos1_err : unsigned(err'range) := (err_extra_bits-1 downto 0 => '0') & (2*fp_size-3 downto 0 => '1');
    constant neg1 : signed(fp_size-1 downto 0) := rotate_right(to_signed(1, fp_size), 1);

begin

    fit <= std_logic_vector(err(err'high downto err'high-fp_size+1));

    -- Stage 1: RAM-Daten in Register zwischenspeichern
    process (clk)
    begin
        if rising_edge(clk) then
            for i in 0 to var_num loop
                reg_chr(i) <= flat_signed(chr, fp_size, i);
                reg_dp(i) <= flat_signed(ram_dp_do, fp_size, i);
            end loop;
        end if;
    end process;

    -- Stage 2: Multiplikation der Koeffizienten mit Datenpunkt
    process (clk)
    begin
        if rising_edge(clk) then

            -- erwarteten Funktionswert weitergeben
            mul_expected <= std_logic_vector(reg_dp(0));

            for i in 0 to var_num loop

                if reg_valid = '1' and reg_dp(i) = neg1 and reg_chr(i) = neg1 then
                    mul_neg1(i) <= '1';
                else
                    mul_neg1(i) <= '0';
                end if;

                if i = 0 then
                    adder_values(0) <= std_logic_vector(resize(signed(reg_chr(0)), adder_extra_bits+fp_size));
                else
                    -- Multiplikation normalisiert zwischen -1 und +1 ist in demselben Wertebereich (aber Verlust von Genauigkeit, Sonderfall -1*-1 abrunden auf 0,99... in Folge-Stage)
                    adder_values(i) <= std_logic_vector(resize(fp_mul(reg_chr(i), reg_dp(i), fp_frac), adder_extra_bits+fp_size));
                end if;

            end loop;

        end if;
    end process;

    -- Vorbereitung innerhalb Stage 3
    gen_adder_values_flat: for i in 0 to var_num generate
        with mul_neg1(i) select
            adder_values_flat(flat_upper(adder_extra_bits+fp_size, i) downto flat_lower(adder_extra_bits+fp_size, i)) <=
                adder_values(i) when '0',
                pos1_adder_values when others; -- Sonderfall -1*-1 auf 0,99... abrunden
    end generate;

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
            start => mul_valid,
            values => adder_values_flat,
            sum => adder_sum,
            done => adder_valid,
            di => mul_expected,
            do => adder_expected
        );

    -- Stage 4: Differenz berechnen
    process (clk)
        variable tmp : signed(adder_extra_bits+fp_size downto 0);
        variable tmp_cut : signed(fp_size-1 downto 0);
    begin
        if rising_edge(clk) then

            tmp := resize(signed(adder_expected), adder_extra_bits+fp_size+1)
                - resize(signed(adder_sum), adder_extra_bits+fp_size+1);

            tmp_cut := tmp(adder_extra_bits+fp_size downto adder_extra_bits+1);
            diff <= tmp_cut;
            if adder_valid = '1' and tmp_cut = neg1 then
                diff_neg1 <= '1';
            else
                diff_neg1 <= '0';
            end if;

        end if;
    end process;

    -- Stage 5: Differenz quadrieren
    process (clk)
        variable tmp : signed(2*fp_size-1 downto 0);
    begin
        if rising_edge(clk) then
            -- Vorkomma-Bits nach Quadrieren immer 0 (außer Sonderfall 1 -> Abrunden auf 0,99... in Folge-Stage)
            tmp := diff * diff;
            diff_sq <= unsigned(tmp(tmp'high-2 downto 0));
            diff_sq_neg1 <= diff_neg1;
        end if;
    end process;

    -- Stage 6: quadr. Differenz Akkumulieren
    process (clk)
        variable valid_neg1 : std_logic_vector(1 downto 0);
    begin
        if rising_edge(clk) then
            valid_neg1 := err_valid & diff_sq_neg1;
            if diff_sq_valid = '1' then
                case valid_neg1 is
                    when "00" => err <= resize(diff_sq, err_extra_bits+2*fp_size-2);
                    when "01" => err <= pos1_err;
                    when "10" => err <= err + resize(diff_sq, err_extra_bits+2*fp_size-2);
                    when "11" => err <= err + pos1_err;
                    when others =>
                end case;
            end if;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                reg_valid <= '0';
                mul_valid <= '0';
                diff_valid <= '0';
                diff_sq_valid <= '0';
                err_valid <= '0';
                done <= '0';
            else
                reg_valid <= valid;
                mul_valid <= reg_valid;
                diff_valid <= adder_valid;
                diff_sq_valid <= diff_valid;
                err_valid <= diff_sq_valid;
                done <= diff_sq_valid and not diff_valid;
            end if;
        end if;
    end process;

end architecture;