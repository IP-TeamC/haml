library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.util.all;
use work.math.all;
use work.mse_linreg;

entity mse_linreg_ds_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant var_num : natural := 1;
    constant fp_size : natural := 18;
    constant fp_frac : natural := 17;
    constant adr_size : natural := 6;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic;
    signal start : std_logic;
    signal chr : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal ram_data : std_logic_vector(fp_size*(var_num+1)-1 downto 0);

    -- Outputs
    signal fit : std_logic_vector(fp_size-1 downto 0);
    signal done : std_logic;

end entity;

architecture rtl of mse_linreg_ds_tb is

begin

    uut: entity mse_linreg
        generic map (
            var_num => var_num,
            fp_size => fp_size,
            fp_frac => fp_frac,
            adr_size => adr_size
        )
        port map (
            clk => clk,
            rst => rst,
            start => start,
            chr => chr,
            ram_data => ram_data,
            fit => fit,
            done => done
        );

    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    process
        variable m : signed(17 downto 0) := "001111001001101000";
        variable b : signed(17 downto 0) := "100110010001111011";
        variable mx : signed(17 downto 0);
        variable y : signed(18 downto 0);
        variable diff : signed(19 downto 0);
        variable diff_sq : signed(39 downto 0);
        variable acc : signed(45 downto 0);
        
    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        assert done = '0';

        start <= '1';

        chr <= std_logic_vector(m & b);
        acc := (others => '0');
        for i in work.f3x12_dataset_tb.t_dataset'range loop
            ram_data <= work.f3x12_dataset_tb.dataset(i, 1) & work.f3x12_dataset_tb.dataset(i, 0);
            --if i > 5 then
            if m = "100000000000000000" and work.f3x12_dataset_tb.dataset(i, 1) = "100000000000000000" then
                mx := not("100000000000000000");
            else
                mx := fp_mul(m, signed(work.f3x12_dataset_tb.dataset(i, 1)), 17);
            end if;
            --report "mx: " & work.util.to_string(mx);
            y := resize(mx, 19) + resize(b, 19);
            --report "y: " & work.util.to_string(y);
            --report "e: " & work.util.to_string(resize(signed(work.f3x12_dataset_tb.dataset(i, 0)), 19));
            diff := resize(signed(work.f3x12_dataset_tb.dataset(i, 0)), 20) - resize(y, 20);
            --report "diff: " & work.util.to_string(diff);
            diff_sq := diff * diff; -- <-- hier ist fehler! fraction anteil? unklar. -1 bis +1 range? nein...
            --report "diff_sq: " & work.util.to_string(diff_sq);
            report "err_: " & work.util.to_string(acc);
            acc := acc + resize(diff_sq, 45);
            --report "err_add_: " & work.util.to_string(resize(diff_sq, 46));
            --report "acc: " & work.util.to_string(acc);-- severity failure;
            --end if;
            wait for clk_period;
            -- start <= '0';
            -- wait for clk_period;
            -- wait for clk_period;
            -- wait for clk_period;
            -- wait for clk_period;
            -- wait for clk_period;
            -- wait for clk_period;
            -- wait for clk_period;
            -- wait for clk_period;
            -- wait for clk_period;
            -- wait for clk_period;
            -- assert false severity failure;
        end loop;
        start <= '0';
        assert done = '0';
        wait until done = '1';
        wait until falling_edge(clk);
        work.util.print(acc);
        work.util.print(fit);
        

        report "done";
        wait;

        start <= '1';
        -- y = 0.5*x2-0.125*x1+0.25
        chr <= "00" & "100000"
            & "11" & "111000"
            & "00" & "010000";

        -- x2 = 0.1875, x1 = 0.3828125, y = 0.28125 (nicht ganz exakt)
        -- Error: 0.000214576736
        ram_data <= "00" & "001100"
            & "00" & "011001"
            & "00" & "010010";
        wait for clk_period;
        assert done = '0';
        -- x2 = 0.0625, x1 = 0.5, y = 0.21875 (exakt)
        -- kein Error
        ram_data <= "00" & "000100"
            & "00" & "100000"
            & "00" & "001110";
        wait for clk_period;
        assert done <= '0';
        -- x2 = 0.0625, x1 = 0.5, y = 0.875 (schlecht)
        -- Error: 0.430664063
        ram_data <= "00" & "000100"
            & "00" & "100000"
            & "00" & "111000";
        wait for clk_period;
        start <= '0';
        assert done <= '0';

        wait until done = '1' and clk = '0';
        -- kleiner Fehler (zu ungenau, deshalb 0)
        assert fit = "00000000";
        wait for clk_period;
        assert done = '1';
        -- unveraenderter Fehler
        assert fit = "00000000";
        wait for clk_period;
        assert done = '1';
        -- viel groeßerer Fehler
        assert fit = "00" & "000110";
        wait for clk_period;
        assert done = '0';

        report "Done";
        wait;
    end process;

end architecture;