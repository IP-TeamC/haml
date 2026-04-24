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
    constant part_size : natural := 3;
    constant start_dp : natural := 1990;
    constant end_dp : natural := 2010;

    -- Inputs
    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal start : std_logic := '0';

    signal mark_end : std_logic;
    signal ram_we : std_logic := '0';
    signal ram_adr : std_logic_vector(adr_size-1 downto 0);
    signal ram_part : std_logic_vector(part_size-1 downto 0);
    signal ram_data : std_logic_vector(fp_size-1 downto 0);

    -- Outputs
    signal done : std_logic;
    signal class : std_logic_vector(class_size-1 downto 0);

end entity;

architecture rtl of knnc_bq is

    -- RAM-Splitter für Init/Simulation
    signal init_done : boolean := false;
    signal ram_we_init : std_logic := '0';
    signal ram_we_sim : std_logic := '0';
    signal ram_data_init : std_logic_vector(ram_data'range);
    signal ram_data_sim : std_logic_vector(ram_data'range);
    signal ram_part_init : std_logic_vector(ram_part'range);
    signal ram_part_sim : std_logic_vector(ram_part'range);
    signal ram_adr_init : std_logic_vector(ram_adr'range) := (others => '0');
    signal ram_adr_sim : std_logic_vector(ram_adr'range) := (others => '0');

begin

    knnc: entity work.knnc
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
            mark_end => mark_end,
            ram_we => ram_we,
            ram_adr => ram_adr,
            ram_data => ram_data,
            ram_part => ram_part,
            done => done,
            class => class
        );

    clk_process: process
    begin
        clk <= not(clk);
        wait for clk_period/2;
    end process;

    ram_we <= ram_we_sim or ram_we_init;
    ram_adr <= ram_adr_sim when init_done else ram_adr_init;
    ram_part <= ram_part_sim when init_done else ram_part_init;
    ram_data <= ram_data_sim when init_done else ram_data_init;

    init_process: process
    begin
        init_done <= false;

        -- Dataset erzeugen
        mark_end <= '1';
        write_dataset_to_ram(ram_we_init, ram_adr_init, ram_part_init, ram_data_init, clk_period);
        mark_end <= '0';

        report "written dataset";
        init_done <= true;
        wait;
    end process;

    process
        variable i : integer := start_dp;
        variable correct : natural := 0;
        variable wrong : natural := 0;
    begin
        if not init_done then
            wait until init_done = true;
        end if;

        write_datapoint_to_ram(ram_we_sim, ram_adr_sim, ram_part_sim, ram_data_sim, clk_period, i);

        start <= '0';
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        start <= '1';
        wait for clk_period;
        start <= '0';

        wait until done = '1';

        if class(0) = dataset(i, 0)(0) then
            report "correct (pred/exp): " & std_logic'image(class(0)) & " " & std_logic'image(dataset(i, 0)(0));
            correct := correct + 1;
        else
            report "wrong (pred/exp): " & std_logic'image(class(0)) & " " & std_logic'image(dataset(i, 0)(0));
            wrong := wrong + 1;
        end if;

        if i = end_dp or i mod 10 = 0 then
            report "Total: " & integer'image(correct + wrong);
            report "Correct: " & integer'image(correct);
            report "Wrong: " & integer'image(wrong);
            if i = end_dp then
                assert false report "End";
            end if;
        end if;
        i := i + 1;

        wait until rising_edge(clk);

    end process;

end architecture;