library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.util.all;
use work.math.all;
use work.salary_dataset_tb.all;

entity ga_linreg_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant mask_factor : natural := 3;
    constant k : natural := 4;
    constant var_num : natural := 2;
    constant fp_size : natural := 18;
    constant fp_frac : natural := 16;
    constant dp_adr_size : natural := 8;
    constant chr_adr_size : natural := 8;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic;
    signal start : std_logic;
    signal mark_end : std_logic;
    signal dp_we : std_logic_vector(var_num downto 0);
    signal dp_adr : std_logic_vector(dp_adr_size-1 downto 0);
    signal dp_data : std_logic_vector(fp_size-1 downto 0);

    -- Outputs
    signal best_chr_adr : std_logic_vector(chr_adr_size-1 downto 0);

end entity;

architecture rtl of ga_linreg_tb is

    procedure custom_write_dataset_to_ram (
        signal we : out std_logic_vector(var_num downto 0);
        signal write_adr : out std_logic_vector(ADR_SIZE-1 downto 0);
        signal write_data : out std_logic_vector(DATA_SIZE-1 downto 0)
    ) is
    begin
        we <= (others => '0');
        for adr in 0 to to_integer(unsigned(END_ADR)) loop
            write_adr <= std_logic_vector(to_unsigned(adr, ADR_SIZE));
            for part in t_dataset'range(2) loop
                we(part) <= '1';
                write_data <= dataset(adr, part);
                wait for clk_period;
                we(part) <= '0';
            end loop;
        end loop;
        we <= (others => '0');
    end procedure;
    
begin

    ga_linreg: entity work.ga_linreg
        generic map(
            mask_factor => mask_factor,
            k => k,
            var_num => var_num,
            fp_size => fp_size,
            fp_frac => fp_frac,
            dp_adr_size => dp_adr_size,
            chr_adr_size => chr_adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            start => start,
            mark_end => mark_end,
            dp_we => dp_we,
            dp_adr => dp_adr,
            dp_data => dp_data,
            best_chr_adr => best_chr_adr
        );

    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    process
    begin
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        start <= '0';

        custom_write_dataset_to_ram(dp_we, dp_adr, dp_data);

        wait for clk_period;
        start <= '1';

        wait;

        report "Done";
        wait;
    end process;

end architecture;