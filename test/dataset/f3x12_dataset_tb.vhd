library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package f3x12_dataset_tb is

    constant FP_SIZE : natural := 18;
    constant FP_FRAC : natural := 17;
    constant ADR_SIZE : natural := 6;
    constant PART_SIZE : natural := 0;
    constant DATA_SIZE : natural := 18;

    constant START_ADR : std_logic_vector(ADR_SIZE-1 downto 0) := (others => '0');
    constant END_ADR : std_logic_vector(ADR_SIZE-1 downto 0) := "111111";

    type t_dataset is array (0 to 63, 0 to 1) of std_logic_vector(DATA_SIZE-1 downto 0);

    procedure write_dataset_to_ram_ga_and_start (
        signal we : out std_logic_vector(t_dataset'high(2) downto 0);
        signal write_adr : out std_logic_vector(ADR_SIZE-1 downto 0);
        signal write_data : out std_logic_vector(FP_SIZE-1 downto 0);
        signal start : out std_logic;
        clk_period : time
    );

    procedure write_dataset_to_ram (
        signal we : out std_logic;
        signal write_adr : out std_logic_vector(ADR_SIZE-1 downto 0);
        signal write_part : out std_logic_vector(PART_SIZE-1 downto 0);
        signal write_data : out std_logic_vector(DATA_SIZE-1 downto 0);
        clk_period : time
    );

    procedure write_datapoint_to_ram (
        signal we : out std_logic;
        signal write_adr : out std_logic_vector;
        signal write_part : out std_logic_vector(PART_SIZE-1 downto 0);
        signal write_data : out std_logic_vector(DATA_SIZE-1 downto 0);
        external_end_adr : std_logic_vector;
        clk_period : time;
        i : natural
    );

    signal dataset : t_dataset := (
        0 => (0 => "100000000000000000", 1 => "100000000000000000"),
        1 => (0 => "100001000001000001", 1 => "100001000001000001"),
        2 => (0 => "100010000010000010", 1 => "100010000010000010"),
        3 => (0 => "100011000011000011", 1 => "100011000011000011"),
        4 => (0 => "100100000100000100", 1 => "100100000100000100"),
        5 => (0 => "100101000101000101", 1 => "100101000101000101"),
        6 => (0 => "100110000110000110", 1 => "100110000110000110"),
        7 => (0 => "100111000111000111", 1 => "100111000111000111"),
        8 => (0 => "101000001000001000", 1 => "101000001000001000"),
        9 => (0 => "101001001001001001", 1 => "101001001001001001"),
        10 => (0 => "101010001010001010", 1 => "101010001010001010"),
        11 => (0 => "101011001011001011", 1 => "101011001011001011"),
        12 => (0 => "101100001100001100", 1 => "101100001100001100"),
        13 => (0 => "101101001101001101", 1 => "101101001101001101"),
        14 => (0 => "101110001110001110", 1 => "101110001110001110"),
        15 => (0 => "101111001111001111", 1 => "101111001111001111"),
        16 => (0 => "110000010000010000", 1 => "110000010000010000"),
        17 => (0 => "110001010001010001", 1 => "110001010001010001"),
        18 => (0 => "110010010010010010", 1 => "110010010010010010"),
        19 => (0 => "110011010011010011", 1 => "110011010011010011"),
        20 => (0 => "110100010100010100", 1 => "110100010100010100"),
        21 => (0 => "110101010101010101", 1 => "110101010101010101"),
        22 => (0 => "110110010110010110", 1 => "110110010110010110"),
        23 => (0 => "110111010111010111", 1 => "110111010111010111"),
        24 => (0 => "111000011000011000", 1 => "111000011000011000"),
        25 => (0 => "111001011001011001", 1 => "111001011001011001"),
        26 => (0 => "111010011010011010", 1 => "111010011010011010"),
        27 => (0 => "111011011011011011", 1 => "111011011011011011"),
        28 => (0 => "111100011100011100", 1 => "111100011100011100"),
        29 => (0 => "111101011101011101", 1 => "111101011101011101"),
        30 => (0 => "111110011110011110", 1 => "111110011110011110"),
        31 => (0 => "111111011111011111", 1 => "111111011111011111"),
        32 => (0 => "000000100000100000", 1 => "000000100000100000"),
        33 => (0 => "000001100001100001", 1 => "000001100001100001"),
        34 => (0 => "000010100010100010", 1 => "000010100010100010"),
        35 => (0 => "000011100011100011", 1 => "000011100011100011"),
        36 => (0 => "000100100100100100", 1 => "000100100100100100"),
        37 => (0 => "000101100101100101", 1 => "000101100101100101"),
        38 => (0 => "000110100110100110", 1 => "000110100110100110"),
        39 => (0 => "000111100111100111", 1 => "000111100111100111"),
        40 => (0 => "001000101000101000", 1 => "001000101000101000"),
        41 => (0 => "001001101001101001", 1 => "001001101001101001"),
        42 => (0 => "001010101010101010", 1 => "001010101010101010"),
        43 => (0 => "001011101011101011", 1 => "001011101011101011"),
        44 => (0 => "001100101100101100", 1 => "001100101100101100"),
        45 => (0 => "001101101101101101", 1 => "001101101101101101"),
        46 => (0 => "001110101110101110", 1 => "001110101110101110"),
        47 => (0 => "001111101111101111", 1 => "001111101111101111"),
        48 => (0 => "010000110000110000", 1 => "010000110000110000"),
        49 => (0 => "010001110001110001", 1 => "010001110001110001"),
        50 => (0 => "010010110010110010", 1 => "010010110010110010"),
        51 => (0 => "010011110011110011", 1 => "010011110011110011"),
        52 => (0 => "010100110100110100", 1 => "010100110100110100"),
        53 => (0 => "010101110101110101", 1 => "010101110101110101"),
        54 => (0 => "010110110110110110", 1 => "010110110110110110"),
        55 => (0 => "010111110111110111", 1 => "010111110111110111"),
        56 => (0 => "011000111000111000", 1 => "011000111000111000"),
        57 => (0 => "011001111001111001", 1 => "011001111001111001"),
        58 => (0 => "011010111010111010", 1 => "011010111010111010"),
        59 => (0 => "011011111011111011", 1 => "011011111011111011"),
        60 => (0 => "011100111100111100", 1 => "011100111100111100"),
        61 => (0 => "011101111101111101", 1 => "011101111101111101"),
        62 => (0 => "011110111110111110", 1 => "011110111110111110"),
        63 => (0 => "011111111111111111", 1 => "011111111111111111")
    );

end package;

package body f3x12_dataset_tb is

    procedure write_dataset_to_ram_ga_and_start (
        signal we : out std_logic_vector(t_dataset'high(2) downto 0);
        signal write_adr : out std_logic_vector(ADR_SIZE-1 downto 0);
        signal write_data : out std_logic_vector(FP_SIZE-1 downto 0);
        signal start : out std_logic;
        clk_period : time
    ) is
    begin
        start <= '0';
        wait for clk_period;
        we <= (others => '0');
        for adr in t_dataset'range(1) loop
            write_adr <= std_logic_vector(to_unsigned(adr, ADR_SIZE));
            for part in t_dataset'range(2) loop
                we(part) <= '1';
                write_data <= dataset(adr, part);
                wait for clk_period;
                we(part) <= '0';
            end loop;
        end loop;
        we <= (others => '0');
        start <= '1';
    end procedure;

    procedure write_dataset_to_ram (
        signal we : out std_logic;
        signal write_adr : out std_logic_vector(ADR_SIZE-1 downto 0);
        signal write_part : out std_logic_vector(PART_SIZE-1 downto 0);
        signal write_data : out std_logic_vector(DATA_SIZE-1 downto 0);
        clk_period : time
    ) is
    begin
        we <= '1';
        for adr in 0 to to_integer(unsigned(END_ADR)) loop
            write_adr <= std_logic_vector(to_unsigned(adr, ADR_SIZE));
            for part in t_dataset'range(2) loop
                write_part <= std_logic_vector(to_unsigned(part, PART_SIZE));
                write_data <= dataset(adr, part);
                wait for clk_period;
            end loop;
        end loop;
        we <= '0';
    end procedure;

    procedure write_datapoint_to_ram (
        signal we : out std_logic;
        signal write_adr : out std_logic_vector;
        signal write_part : out std_logic_vector(PART_SIZE-1 downto 0);
        signal write_data : out std_logic_vector(DATA_SIZE-1 downto 0);
        external_end_adr : std_logic_vector;
        clk_period : time;
        i : natural
    ) is
    begin
        we <= '1';
        write_adr <= std_logic_vector(unsigned(external_end_adr)+1);
        for part in t_dataset'range(2) loop
            if part /= 0 then
                write_part <= std_logic_vector(to_unsigned(part, PART_SIZE));
                write_data <= dataset(i, part);
                wait for clk_period;
            end if;
        end loop;
        we <= '0';
    end procedure;

end package body;
