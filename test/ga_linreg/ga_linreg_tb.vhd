library ieee;
use ieee.std_logic_1164.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.util.all;
use work.math.all;

entity ga_linreg_tb is

    generic (
        clk_period : time;
        mask_factor : natural := 3;
        k_sel : natural := 3;
        k_rep : natural := 3;
        var_num : natural;
        fp_size : natural := 18;
        fp_frac : natural := 17;
        fit_size: natural := 36;
        dp_adr_size : natural;
        chr_adr_size : natural;
        replace_with_worse : boolean := false;
        mut_arith : boolean := true;
        square : boolean := false
    );

    port (
        start : std_logic;
        dp_we : std_logic_vector(var_num downto 0);
        dp_adr : std_logic_vector(dp_adr_size-1 downto 0);
        dp_data : std_logic_vector(fp_size-1 downto 0)
    );

end entity;

architecture rtl of ga_linreg_tb is

    signal clk : std_logic := '1';
    signal rst : std_logic;
    signal mark_end : std_logic;
    signal best_chr : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    signal best_chr_fit : std_logic_vector(fit_size-1 downto 0);

begin

    ga_linreg: entity work.ga_linreg
        generic map(
            mask_factor => mask_factor,
            k_sel => k_sel,
            k_rep => k_rep,
            var_num => var_num,
            fp_size => fp_size,
            fp_frac => fp_frac,
            fit_size => fit_size,
            dp_adr_size => dp_adr_size,
            chr_adr_size => chr_adr_size,
            replace_with_worse => replace_with_worse,
            mut_arith => mut_arith,
            square => square
        )
        port map(
            clk => clk,
            rst => rst,
            start => start,
            mark_end => mark_end,
            dp_we => dp_we,
            dp_adr => dp_adr,
            dp_data => dp_data,
            best_chr => best_chr,
            best_chr_fit => best_chr_fit
        );

    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    process
        variable prev_best_chr : std_logic_vector(fp_size*(var_num+1)-1 downto 0);
    begin
        rst <= '1';
        mark_end <= '1';
        wait for clk_period;
        rst <= '0';

        wait until start = '1';
        mark_end <= '0';

        while start = '1' loop
            if best_chr /= prev_best_chr then
                prev_best_chr := best_chr;
            end if;
            report "Fit: " & work.util.to_string(best_chr_fit);
            for i in 0 to var_num loop
                report integer'image(i) & ": " & work.util.to_string(flat_vec(best_chr, fp_size, i));
            end loop;
            report "------";
            wait for 1 us;
        end loop;

        report "Done";
        wait;
    end process;

end architecture;