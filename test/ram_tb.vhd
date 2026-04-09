library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--library common;
use work.mem.ram;
use work.util.all;

entity ram_tb is

    -- Constants
    signal clk_period : time := 1 ns;
    signal adr_size : natural := 8;
    signal data_size : natural := 8;

    -- Inputs
    signal clk : std_logic := '1';
    signal we : std_logic := '0';
    signal adr : std_logic_vector(adr_size-1 downto 0) := (others => '0');
    signal di : std_logic_vector(data_size-1 downto 0) := (others => '0');

    -- Outputs
    signal do : std_logic_vector(data_size-1 downto 0);

end entity;

architecture rtl of ram_tb is

begin

    uut: ram
        generic map (
            adr_size => adr_size,
            data_size => data_size
        )
        port map (
            clk => clk,
            we => we,
            adr => adr,
            di => di,
            do => do
        );


    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    process
        variable a_vec : std_logic_vector(adr_size-1 downto 0);
        variable d_vec : std_logic_vector(data_size-1 downto 0);
    begin
        
        we <= '1';
        for i in 0 to (2**adr_size)-1 loop
            a_vec := std_logic_vector(to_unsigned(i, adr_size));
            d_vec := std_logic_vector(resize(to_unsigned(i, adr_size), data_size));
            adr <= a_vec;
            di <= d_vec;
            wait for clk_period;
        end loop;
        
        we <= '0';
        for i in 0 to (2**adr_size)-1 loop
            a_vec := std_logic_vector(to_unsigned(i, adr_size));
            d_vec := std_logic_vector(resize(to_unsigned(i, adr_size), data_size));
            adr <= a_vec;
            wait for clk_period;
            assert do = d_vec;
        end loop;
        
        wait;
    end process;

end architecture;