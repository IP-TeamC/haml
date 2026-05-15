library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

        fit : out std_logic_vector(4*fp_size-1 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of mse_linreg is

    type t_dp is array (0 to var_num) of signed(fp_size-1 downto 0);
    signal mul_dp : t_dp;
    signal dp_done : std_logic;

    signal mul_expected : std_logic_vector(fp_size-1 downto 0);
    signal mul_done : std_logic;

    signal adder_values : std_logic_vector(2*fp_size*(var_num+1)-1 downto 0);
    signal adder_done : std_logic;
    signal adder_sum : std_logic_vector(2*fp_size-1 downto 0);
    signal adder_expected : std_logic_vector(2*fp_size-1 downto 0);

    signal diff : signed(2*fp_size-1 downto 0);
    signal diff_done : std_logic;
    signal diff_sq : unsigned(4*fp_size-1 downto 0);
    signal diff_sq_done : std_logic;

    signal err : unsigned(4*fp_size-1 downto 0);
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
            adder_values(2*fp_size-1 downto fp_size+fp_frac) <= (others => chr(fp_size-1));
            adder_values(fp_size+fp_frac-1 downto fp_frac) <= chr(fp_size-1 downto 0);
            adder_values(fp_frac-1 downto 0) <= (others => '0');
            for i in 1 to var_num loop
                adder_values(flat_upper(2*fp_size, i) downto flat_lower(2*fp_size, i)) <= std_logic_vector(
                        flat_signed(chr, fp_size, i) * mul_dp(i)
                    );
            end loop;
        end if;
    end process;

    -- Stage 3+: Addition der Multiplikationsergebnisse im Adder-Tree (Multi-Stage)
    adder_tree: entity work.adder_tree
        generic map(
            n => var_num+1,
            size => 2*fp_size,
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
            do => adder_expected(fp_size+fp_frac-1 downto fp_frac)
        );
    adder_expected(2*fp_size-1 downto fp_size+fp_frac) <= (others => adder_expected(fp_size+fp_frac-1));
    adder_expected(fp_frac-1 downto 0) <= (others => '0');

    -- Stage 4: Differenz berechnen
    process (clk)
    begin
        if rising_edge(clk) then
            diff <= signed(adder_expected) - signed(adder_sum);
        end if;
    end process;

    -- Stage 5: Differenz quadrieren
    process (clk)
    begin
        if rising_edge(clk) then
            diff_sq <= unsigned(diff * diff);
        end if;
    end process;

    -- Stage 6: quadr. Differenz Akkumulieren
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                err <= (others => '0');
            elsif diff_sq_done = '1' then
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