library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.util.all;
use work.math.all;
use work.classifier;
use work.ram;
use work.bq_dataset.all;

entity knnc_bq is

    -- Constants
    constant clk_period : time := 7 ns;
    constant k : natural := 3;
    constant fp_size : natural := 32;
    constant fp_frac : natural := 20;
    constant class_size : natural := 1;
    constant feature_num : natural := 7;
    constant adr_size : natural := work.bq_dataset.ADR_SIZE;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal start : std_logic := '0';

    signal ram_data : std_logic_vector(feature_num*fp_size+class_size-1 downto 0);

    signal start_adr : std_logic_vector(adr_size-1 downto 0);
    signal end_adr : std_logic_vector(adr_size-1 downto 0);

    -- Outputs
    signal ram_adr : std_logic_vector(adr_size-1 downto 0);

    signal done : std_logic;
    signal class : std_logic_vector(class_size-1 downto 0);

    -- Dataset/RAM
    signal we : std_logic := '0';
    signal we_init : std_logic := '0';
    signal we_sim : std_logic := '0';
    signal write_data : std_logic_vector(ram_data'range);
    signal write_data_init : std_logic_vector(ram_data'range);
    signal write_data_sim : std_logic_vector(ram_data'range);

    -- RAM Arbitrierung
    signal init_done : boolean := false;
    signal sim_access : std_logic := '0';
    signal read_adr : std_logic_vector(ram_adr'range) := (others => '0');
    signal init_adr : std_logic_vector(ram_adr'range) := (others => '0');
    signal sim_adr : std_logic_vector(ram_adr'range) := (others => '0');

end entity;

architecture rtl of knnc_bq is
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
            start_adr => start_adr,
            end_adr => end_adr,
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

    ram_adr <= init_adr when init_done = false
        else sim_adr when sim_access = '1'
        else read_adr;
    we <= we_init or we_sim;
    write_data <= write_data_init when init_done = false else write_data_sim;
    write_data_sim <= ram_data;

    init_process: process
    begin
        -- Dataset erzeugen
        init_done <= false;
        write_dataset_to_ram(we_init, init_adr, write_data_init, clk_period);
        report "written dataset";
        init_done <= true;
        wait;
    end process;

    process
        variable i : integer := 1975;
        variable expected : std_logic_vector(ram_data'range);
        variable correct : natural := 0;
        variable wrong : natural := 0;
    begin
        if not init_done then
            wait until init_done = true;
        end if;

        sim_access <= '1';
        we_sim <= '0';
        sim_adr <= std_logic_vector(to_unsigned(i, adr_size));
        wait for clk_period;

        -- lese verzögert!, muss 1 Takt nach hinten verschoben werden
        wait for clk_period;
        expected := ram_data;

        we_sim <= '1';
        sim_adr <= std_logic_vector(unsigned(work.bq_dataset.END_ADR) + 1);
        wait for clk_period;
        we_sim <= '0';
        start <= '0';
        rst <= '1';
        wait for clk_period;
        rst <= '0';

        sim_access <= '0';
        start <= '1';
        start_adr <= work.bq_dataset.START_ADR;
        end_adr <= work.bq_dataset.END_ADR;
        wait for clk_period;
        start <= '0';

        wait until done = '1';

        report std_logic'image(class(0));
        report std_logic'image(expected(0));
        if class(0) = expected(0) then
            report "correct";
            correct := correct + 1;
        else
            report "wrong";
            wrong := wrong + 1;
        end if;

        if to_integer(unsigned(work.bq_dataset.END_ADR)) = i or i = 2025 then
            report "Total: " & integer'image(correct + wrong);
            report "Correct: " & integer'image(correct);
            report "Wrong: " & integer'image(wrong);
            assert false report "End";
        end if;
        i := i + 1;

        wait until rising_edge(clk);

    end process;

end architecture;