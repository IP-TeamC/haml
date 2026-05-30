library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.adder_tree;
use work.math.all;

-- euklidische Distanz-Berechnung ohne Wurzel (signed/mit Vorzeichen; nur zum Vergleichen)
-- a und b sind jeweils n-dimensionale Vektoren (Flat)
-- berechnet jeweils a_i - b_i für jedes i (jede Dimension), quadriert diese Differenz und addiert alle quadrierten Differenzen
-- besteht aus den Pipeline-Stufen 1. Differenz, 2. Quadrat, 3. Addition (Adder-Tree, kann je nach n zusätzlich aus mehreren Stages bestehen)
-- mit di können Daten durch die Pipeline mitgezogen werden, die nach dem Distanz-Berechnung relevant sind (werden in di synchron mit der quadrierten Distanz dist_sq ausgegeben)
entity signed_dist is
    generic (
        n : natural;
        fp_size : natural;
        fp_frac : natural := 0;
        data_size : natural := 0;
        extend : boolean := false
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        a : in std_logic_vector((n*fp_size)-1 downto 0);
        b : in std_logic_vector((n*fp_size)-1 downto 0);
        di : in std_logic_vector(data_size-1 downto 0);

        dist_sq : out std_logic_vector(calc_signed_dist_sq_size(fp_size, extend)-1 downto 0);
        done : out std_logic;
        do : out std_logic_vector(data_size-1 downto 0)
    );
end entity;

-- Pipeline: Differenz -> Quadrat -> Addition (Adder Tree mit mehreren Stages)
architecture rtl of signed_dist is

    type t_diff is array (0 to n-1) of signed(fp_size-1 downto 0);
    signal diff : t_diff;
    signal diff_next : t_diff;
    signal done_diff : std_logic;
    signal di_delayed_diff : std_logic_vector(data_size-1 downto 0);

    type t_diff_sq is array (0 to n-1) of signed(calc_signed_dist_sq_size(fp_size, extend)-1 downto 0);
    signal diff_sq : t_diff_sq;
    signal diff_sq_next : t_diff_sq;
    signal diff_sq_flat : std_logic_vector(n*calc_signed_dist_sq_size(fp_size, extend)-1 downto 0);
    signal done_diff_sq : std_logic;
    signal di_delayed_diff_sq : std_logic_vector(data_size-1 downto 0);

begin

    -- Stage 3+: Addition der quadrierten Differenzen
    adder: entity adder_tree
        generic map (
            n => n,
            size => calc_signed_dist_sq_size(fp_size, extend),
            data_size => data_size
        )
        port map (
            clk => clk,
            rst => rst,
            start => done_diff_sq,
            values => diff_sq_flat,
            sum => dist_sq,
            done => done,
            di => di_delayed_diff_sq,
            do => do
        );

    process (clk)
    begin
        if rising_edge(clk) then
            if start = '1' then
                diff <= diff_next;
                di_delayed_diff <= di;
            end if;

            diff_sq <= diff_sq_next;
            di_delayed_diff_sq <= di_delayed_diff;

            if rst = '1' then
                done_diff <= '0';
                done_diff_sq <= '0';
            else
                done_diff <= start;
                done_diff_sq <= done_diff;
            end if;
        end if;
    end process;

    -- Stage 1: Berechnung der Differenzen
    gen_diff: for i in 0 to n-1 generate
    begin
        diff_next(i) <= flat_signed(a, fp_size, i) - flat_signed(b, fp_size, i);
    end generate;

    -- Stage 2: Quadrieren der Differenzen
    gen_diff_sq: for i in 0 to n-1 generate
    begin

        gen_diff_sq_extend: if extend = true generate
            diff_sq_next(i) <= diff(i) * diff(i);
        end generate;

        gen_diff_sq_noextend: if extend = false generate
            diff_sq_next(i) <= fp_mul(diff(i), diff(i), fp_frac);
        end generate;

    end generate;

    -- Vorbereitung Stage 3: Flat-Vektor erstellen
    gen_diff_sq_flat: for i in 0 to n-1 generate

        gen_diff_sq_flat_extend: if extend = true generate
            diff_sq_flat(flat_upper(2*fp_size, i) downto flat_lower(2*fp_size, i)) <= std_logic_vector(diff_sq(i));
        end generate;

        gen_diff_sq_flat_noextend: if extend = false generate
            diff_sq_flat(flat_upper(fp_size, i) downto flat_lower(fp_size, i)) <= std_logic_vector(diff_sq(i));
        end generate;

    end generate;

end architecture;