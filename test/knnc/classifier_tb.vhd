library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.util.all;
use work.math.all;
use work.classifier;
use work.ram;

entity classifier_tb is

    -- Constants
    constant clk_period : time := 1 ns;
    constant k : natural := 3;
    constant fp_size : natural := 8;
    constant fp_frac : natural := 2;
    constant class_size : natural := 2;
    constant feature_num : natural := 2;
    constant adr_size : natural := 4;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal start : std_logic := '0';

    signal ram_data : std_logic_vector(feature_num*fp_size+class_size-1 downto 0);
    signal dp_adr : std_logic_vector(adr_size-1 downto 0);

    -- Outputs
    signal ram_adr : std_logic_vector(adr_size-1 downto 0);

    signal done : std_logic;
    signal class : std_logic_vector(class_size-1 downto 0);

    -- Dataset/RAM
    signal we : std_logic;
    signal write_data : std_logic_vector(ram_data'range);

    -- RAM Arbitrierung
    signal read_adr : std_logic_vector(ram_adr'range);
    signal write_adr : std_logic_vector(ram_adr'range);

end entity;

architecture rtl of classifier_tb is

begin

    uut: entity classifier
        generic map(
            k => k,
            fp_size => fp_size,
            fp_frac => fp_frac,
            class_size => class_size,
            feature_num => feature_num,
            adr_size => adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            start => start,
            ram_adr => read_adr,
            ram_data => ram_data,
            dp_adr => dp_adr,
            done => done,
            class => class
        );
    dataset: entity ram
        generic map(
            adr_size => adr_size,
            data_size => ram_data'length
        )
        port map(
            clk => clk,
            we => we,
            adr => ram_adr,
            di => write_data,
            do => ram_data
        );

    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    ram_adr <= write_adr when we = '1' else read_adr;

    process
    begin

        -- Dataset erzeugen
        we <= '1';
        write_adr <= "0000";
        write_data <= "00001010" & "00001100" & "00";
        wait for clk_period;
        write_adr <= "0001";
        write_data <= "00010010" & "00010010" & "01";
        wait for clk_period;
        write_adr <= "0010";
        write_data <= "00101001" & "00100001" & "10";
        wait for clk_period;
        write_adr <= "0011";
        write_data <= "00001011" & "00001101" & "00";
        wait for clk_period;
        write_adr <= "0100";
        write_data <= "00010010" & "00010010" & "01";
        wait for clk_period;
        write_adr <= "0101";
        write_data <= "00101001" & "00100001" & "10";
        wait for clk_period;
        write_adr <= "0110";
        write_data <= "00010010" & "00010010" & "XX";
        wait for clk_period;

        start <= '0';
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        we <= '0';

        start <= '1';
        dp_adr <= "0110";
        wait for clk_period;
        start <= '0';
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '1';
        assert class = "01";
        wait for clk_period;
        assert done = '0';

        we <= '1';
        write_adr <= "0110";
        write_data <= "00101001" & "00100001" & "XX";
        wait for clk_period;
        we <= '0';

        start <= '1';
        wait for clk_period;
        start <= '0';
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '0';
        wait for clk_period;
        assert done = '1';
        assert class = "10";
        wait for clk_period;
        assert done = '0';

        wait;
    end process;

end architecture;