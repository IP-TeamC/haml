library ieee;
use ieee.std_logic_1164.all;

use work.f3x12_dataset_tb.all;

entity f3x12_tb is

    constant clk_period : time := 2.75 ns;

end entity;

architecture rtl of f3x12_tb is

    signal start : std_logic;
    signal dp_we : std_logic_vector(t_dataset'high(2) downto 0);
    signal dp_adr : std_logic_vector(ADR_SIZE-1 downto 0);
    signal dp_data : std_logic_vector(FP_SIZE-1 downto 0);

begin

    ga_linreg_tb: entity work.ga_linreg_tb
        generic map(
            clk_period => clk_period,
            var_num => t_dataset'high(2),
            dp_adr_size => ADR_SIZE,
            chr_adr_size => 5
        )
        port map(
            start => start,
            dp_we => dp_we,
            dp_adr => dp_adr,
            dp_data => dp_data
        );
    
    process
    begin
        write_dataset_to_ram_ga_and_start(dp_we, dp_adr, dp_data, start, clk_period);
        wait;
    end process;

end architecture;