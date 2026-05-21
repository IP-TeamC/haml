library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.util.all;
use work.math.all;
use work.sse_linreg;

entity sse_linreg_ds_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant var_num : natural := 1;
    constant fp_size : natural := 18;
    constant fp_frac : natural := 17;
    constant adr_size : natural := 6;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic;
    signal valid : std_logic;
    signal chr : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal ram_dp_do : std_logic_vector(fp_size*(var_num+1)-1 downto 0);

    -- Outputs
    signal fit : std_logic_vector(fp_size-1 downto 0);
    signal done : std_logic;

    -- LFSR
    signal rand1 : std_logic_vector(fp_size-1 downto 0);
    signal rand2 : std_logic_vector(fp_size-1 downto 0);

end entity;

architecture rtl of sse_linreg_ds_tb is

begin

    uut: entity sse_linreg
        generic map (
            var_num => var_num,
            fp_size => fp_size,
            fp_frac => fp_frac,
            adr_size => adr_size
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
        variable mx : signed(fp_size-1 downto 0);
        variable y : signed(fp_size downto 0);
        variable diff : signed(fp_size+1 downto 0);
        variable diff_sq : signed(2*(fp_size+2)-1 downto 0);
        variable acc : signed(2*(fp_size+2)+5 downto 0);
    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        assert done = '0';

        for cnt in 0 to 1_000_000 loop

            m := signed(rand1);
            b := signed(rand2);
            valid <= '1';
            chr <= std_logic_vector(m & b);

            acc := (others => '0');
            for i in work.f3x12_dataset_tb.t_dataset'range loop
                ram_dp_do <= work.f3x12_dataset_tb.dataset(i, 1) & work.f3x12_dataset_tb.dataset(i, 0);
                if m = "100000000000000000" and work.f3x12_dataset_tb.dataset(i, 1) = "100000000000000000" then
                    mx := not("100000000000000000");
                else
                    mx := fp_mul(m, signed(work.f3x12_dataset_tb.dataset(i, 1)), fp_frac);
                end if;
                y := resize(mx, fp_size+1) + resize(b, fp_size+1);
                diff := resize(signed(work.f3x12_dataset_tb.dataset(i, 0)), fp_size+2) - resize(y, fp_size+2);
                diff_sq := diff * diff;
                acc := acc + resize(diff_sq, 2*fp_size+1+6+1);
                wait for clk_period;
            end loop;

            valid <= '0';
            assert done = '0';
            wait until done = '1';
            wait until falling_edge(clk);

            work.util.print(acc(acc'high-2 downto acc'high-fp_size-1));
            work.util.print(fit);

            assert acc(acc'high downto acc'high-1) = "00";
            assert unsigned(acc(acc'high-2 downto acc'high-fp_size-1)) = unsigned(fit)
                or (unsigned(acc(acc'high-2 downto acc'high-fp_size-1)) >= unsigned(fit) - 1 and unsigned(acc(acc'high-2 downto acc'high-fp_size-1)) - 1 <= unsigned(fit))
                or (unsigned(acc(acc'high-2 downto acc'high-fp_size-1)) + 1 >= unsigned(fit) and unsigned(acc(acc'high-2 downto acc'high-fp_size-1)) <= unsigned(fit) + 1);

        end loop;

        report "Done";
        wait;
    end process;

end architecture;