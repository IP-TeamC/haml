library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mem.reg;

entity reg_tb is
end entity;

architecture rtl of reg_tb is

    -- Constants
    constant clk_period : time := 10 ns;
    constant size : natural := 8;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal we : std_logic := '0';
    signal data : std_logic_vector(size-1 downto 0);
    
    -- Outputs
    signal state : std_logic_vector(size-1 downto 0);

begin

    uut: reg
        generic map (
            size => size
        )
        port map (
            clk   => clk,
            rst => rst,
            we => we,
            data => data,
            state => state
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
        assert state = "00000000";
        
        rst <= '0';
        wait for clk_period;
        assert state = "00000000";

        we <= '1';
        data <= "11111111";
        assert state = "00000000";
        wait for clk_period;
        assert state = "11111111";

        wait for clk_period;
        assert state = "11111111";

        wait for clk_period;
        assert state = "11111111";

        data <= "00000000";
        assert state = "11111111";
        wait for clk_period;
        assert state = "00000000";

        we <= '0';
        wait for clk_period;
        assert state = "00000000";

        data <= "11111111";
        assert state = "00000000";
        wait for clk_period;
        assert state = "00000000";

        wait;

    end process;

end architecture;
