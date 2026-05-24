library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.util.all;
use work.math.all;
use work.rse_linreg;

entity rse_linreg_ds_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant var_num : natural := 1;
    constant fp_size : natural := 18;
    constant fp_frac : natural := 17;
    constant fit_size : natural := 36;
    constant adr_size : natural := 8;
    constant square : boolean := false;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic;
    signal valid : std_logic;
    signal chr : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal ram_dp_do : std_logic_vector(fp_size*(var_num+1)-1 downto 0);

    -- Outputs
    signal fit : std_logic_vector(fit_size-1 downto 0);
    signal done : std_logic;

    -- LFSR
    signal rand1 : std_logic_vector(fp_size-1 downto 0);
    signal rand2 : std_logic_vector(fp_size-1 downto 0);

end entity;

architecture rtl of rse_linreg_ds_tb is

begin

    uut: entity rse_linreg
        generic map (
            var_num => var_num,
            fp_size => fp_size,
            fp_frac => fp_frac,
            fit_size => fit_size,
            adr_size => adr_size,
            square => square
        )
        port map (
            clk => clk,
            rst => rst,
            valid => valid,
            chr => chr,
            ram_dp_do => ram_dp_do,
            fit => fit,
            done => done
        );

    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    lfsr1: entity work.lfsr
        generic map(
            degree => fp_size
        )
        port map(
            clk => clk,
            rst => rst,
            generator => work.prng.prim_gen(fp_size),
            seed => work.prng.sample_seed(fp_size, 47),
            rand => rand1
        );

    lfsr2: entity work.lfsr
        generic map(
            degree => fp_size
        )
        port map(
            clk => clk,
            rst => rst,
            generator => work.prng.prim_gen(fp_size),
            seed => work.prng.sample_seed(fp_size, 50),
            rand => rand2
        );

    process
        variable m : signed(fp_size-1 downto 0);
        variable b : signed(fp_size-1 downto 0);
        variable mx : signed(2*fp_size-1 downto 0);
        variable y : signed(2*fp_size downto 0);
        variable diff : signed(2*fp_size+1 downto 0);
        variable diff_sq : unsigned(2*(2*fp_size+2)-1 downto 0);
        variable diff_abs : unsigned(2*fp_size+1 downto 0);
        variable acc_sq : unsigned(2*(2*fp_size+2)+7 downto 0);
        variable acc_abs : unsigned(2*fp_size+6 downto 0);
    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        assert done = '0';

        for cnt in 0 to 0 loop--_000_000 loop

            m := "011000010010101000";--signed(rand1);
            b := "100111101110101101";--signed(rand2);
            valid <= '1';
            chr <= std_logic_vector(m & b);

            acc_sq := (others => '0');
            acc_abs := (others => '0');
            for i in work.lineare_regression2_dataset_tb.t_dataset'range loop
                ram_dp_do <= work.lineare_regression2_dataset_tb.dataset(i, 1) & work.lineare_regression2_dataset_tb.dataset(i, 0);
                mx := m * signed(work.lineare_regression2_dataset_tb.dataset(i, 1));
                y := resize(mx, 2*fp_size+1) + resize(b, 2*fp_size+1);
                diff := resize(signed(work.lineare_regression2_dataset_tb.dataset(i, 0)), 2*fp_size+2) - resize(y, 2*fp_size+2);
                diff_sq := unsigned(diff * diff);
                diff_abs := unsigned(abs(diff));
                acc_sq := acc_sq + resize(diff_sq, 2*(2*fp_size+2)+8);
                acc_abs := acc_abs + resize(diff_abs, 2*fp_size+7);
                wait for clk_period;
            end loop;

            valid <= '0';
            assert done = '0';
            wait until done = '1';
            wait until falling_edge(clk);

            --work.util.print(acc_sq(acc_sq'high-4 downto 0));
            work.util.print(acc_abs(acc_abs'high-1 downto 0));
            work.util.print(fit);
            assert acc_abs(acc_abs'high) = '0';

            -- assert acc(acc'high downto acc'high-1) = "00";
            -- assert unsigned(acc(acc'high-2 downto acc'high-fp_size-1)) = unsigned(fit)
            --     or (unsigned(acc(acc'high-2 downto acc'high-fp_size-1)) >= unsigned(fit) - 1 and unsigned(acc(acc'high-2 downto acc'high-fp_size-1)) - 1 <= unsigned(fit))
            --     or (unsigned(acc(acc'high-2 downto acc'high-fp_size-1)) + 1 >= unsigned(fit) and unsigned(acc(acc'high-2 downto acc'high-fp_size-1)) <= unsigned(fit) + 1);

        end loop;

        report "Done";
        wait;
    end process;

end architecture;