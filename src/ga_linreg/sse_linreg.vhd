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

        ram_data : in std_logic_vector(fp_size*(var_num+1)-1 downto 0);

        fit : out std_logic_vector(fp_size-1 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of sse_linreg is

    constant neg1 : signed(fp_size-1 downto 0) := rotate_right(to_signed(1, fp_size), 1);

    type t_reg_chr is array (0 to var_num) of signed(fp_size-1 downto 0);
    type t_reg_dp is array (0 to var_num) of signed(fp_size-1 downto 0);
    type t_reg_neg1 is array (0 to var_num) of std_logic;
    signal reg_chr : t_reg_chr;
    signal reg_dp : t_reG_dp;
    signal reg_dp_neg1 : t_reg_neg1;
    signal reg_chr_neg1 : t_reg_neg1;
    signal reg_valid : std_logic;

    signal mul_expected : std_logic_vector(fp_size-1 downto 0);
    signal mul_valid : std_logic;

    constant adder_extra_bits : natural := natural(ceil(log2(real(var_num+1))));
    signal adder_values : std_logic_vector((adder_extra_bits+fp_size)*(var_num+1)-1 downto 0);
    signal adder_valid : std_logic;
    signal adder_sum : std_logic_vector(adder_extra_bits+fp_size-1 downto 0);
    signal adder_expected : std_logic_vector(fp_size-1 downto 0);

    signal diff : signed(fp_size-1 downto 0);
    signal diff_neg1 : std_logic;
    signal diff_valid : std_logic;
    signal diff_sq : unsigned(2*fp_size-3 downto 0);
    signal diff_sq_valid : std_logic;

    constant err_extra_bits : natural := adr_size;
    signal err : unsigned(err_extra_bits+2*fp_size-3 downto 0);
    signal err_valid : std_logic;

begin

    fit <= std_logic_vector(err(err'high downto err'high-fp_size+1));

    -- Stage 1: RAM-Daten in Register zwischenspeichern
    process (clk)
    begin
        if rising_edge(clk) then
            for i in 0 to var_num loop
                reg_chr(i) <= flat_signed(chr, fp_size, i);
                reg_dp(i) <= flat_signed(ram_data, fp_size, i);
                if valid = '1' and flat_signed(ram_data, fp_size, i) = neg1 then
                    reg_dp_neg1(i) <= '1';
                else
                    reg_dp_neg1(i) <= '0';
                end if;
                if valid = '1' and flat_signed(chr, fp_size, i) = neg1 then
                    reg_chr_neg1(i) <= '1';
                else
                    reg_chr_neg1(i) <= '0';
                end if;
            end loop;
        end if;
    end process;

    -- Stage 2: Multiplikation der Koeffizienten mit Datenpunkt
    process (clk)
    begin
        if rising_edge(clk) then
            -- erwarteten Funktionswert weitergeben, Konstante der linearen Funktion weitergeben
            mul_expected <= std_logic_vector(reg_dp(0));
            adder_values(adder_extra_bits+fp_size-1 downto 0)
                <= std_logic_vector(
                        resize(
                            signed(reg_chr(0)),
                            adder_extra_bits+fp_size
                        )
                    );

            for i in 1 to var_num loop
                -- Multiplikation normalisiert zwischen -1 und +1 ist in demselben Wertebereich (aber Verlust von Genauigkeit, Sonderfall -1*-1 abrunden auf 0,99...)
                if (reg_chr_neg1(i) = '1' and reg_dp_neg1(i) = '1') then
                    -- Sonderfall -1*-1 auf 0,99... abrunden
                    adder_values(flat_upper(adder_extra_bits+fp_size, i) downto flat_upper(adder_extra_bits+fp_size, i)-adder_extra_bits)
                        <= (others => '0');
                    adder_values(flat_upper(adder_extra_bits+fp_size, i)-adder_extra_bits-1 downto flat_lower(adder_extra_bits+fp_size, i))
                        <= (others => '1');
                else
                    adder_values(flat_upper(adder_extra_bits+fp_size, i) downto flat_lower(adder_extra_bits+fp_size, i))
                        <= std_logic_vector(
                                resize(
                                    fp_mul(reg_chr(i), reg_dp(i), fp_frac),
                                    adder_extra_bits+fp_size
                                )
                            );
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
            start => mul_valid,
            values => adder_values,
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

            -- Vorkomma-Bits nach Quadrieren immer 0 (außer Sonderfall 1 -> Abrunden auf 0,99...)
            tmp := diff * diff;
            if diff_neg1 = '1' then
                diff_sq <= (others => '1');
            else
                diff_sq <= unsigned(tmp(tmp'high-2 downto 0));
            end if;

        end if;
    end process;

    -- Stage 6: quadr. Differenz Akkumulieren
    process (clk)
    begin
        if rising_edge(clk) then
            if diff_sq_valid = '1' then
                if err_valid = '1' then
                    err <= err + resize(diff_sq, err_extra_bits+2*fp_size-2);
                else
                    err <= resize(diff_sq, err_extra_bits+2*fp_size-2);
                end if;
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