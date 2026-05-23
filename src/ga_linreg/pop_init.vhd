library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.prng.prim_gen;
use work.prng.sample_seed;

entity pop_init is
    generic (
        var_num : natural;
        fp_size : natural;
        adr_size : natural
    );
    port (
        clk   : in std_logic;
        rst : in std_logic;
        start : in std_logic;
        fitness_done : in std_logic;

        ram_fit_we : out std_logic;
        ram_chr_we : out std_logic_vector(var_num downto 0);
        ram_chr_adr : out std_logic_vector(adr_size-1 downto 0);
        ram_chr_di : out std_logic_vector(fp_size-1 downto 0);

        fitness_start : out std_logic;
        done : out std_logic
    );
end entity;

architecture rtl of pop_init is

    type t_state is (s_ready, s_generate, s_fit_calc, s_fit_write, s_done);
    signal state : t_state;
    signal next_state : t_state;

    signal chr_we : std_logic_vector(ram_chr_we'high+1 downto 0);
    signal next_chr_we : std_logic_vector(ram_chr_we'high+1 downto 0);

    signal chr_adr : unsigned(ram_chr_adr'range);
    signal next_chr_adr : unsigned(ram_chr_adr'range);

    signal last_chr_adr : std_logic;
    signal next_last_chr_adr : std_logic;

    signal next_fitness_start : std_logic;
    signal next_done : std_logic;

begin

    ram_fit_we <= chr_we(var_num+1);
    ram_chr_we <= chr_we(var_num downto 0);
    ram_chr_adr <= std_logic_vector(chr_adr);

    lfsr: entity work.lfsr
        generic map(
            degree => fp_size
        )
        port map(
            clk => clk,
            rst => rst,
            generator => prim_gen(fp_size),
            seed => sample_seed(fp_size, 62),
            rand => ram_chr_di
        );

    next_state <= s_ready when rst = '1'
        else s_generate when state = s_ready and start = '1'
        else s_fit_calc when state = s_generate and last_chr_adr = '1' and chr_we(var_num) = '1'
        else s_fit_write when state = s_fit_calc and fitness_done = '1'
        else s_fit_calc when state = s_fit_write and last_chr_adr = '0'
        else s_done when state = s_fit_write and last_chr_adr = '1'
        else state;

    next_chr_we <= (others => '0') when rst = '1' or (start = '0' and state = s_ready)
        else (0 => '1', others => '0') when start = '1' and state = s_ready
        else chr_we(var_num downto 0) & '0' when last_chr_adr = '1'
        else chr_we;

    next_chr_adr <= (others => '0') when rst = '1' or state = s_ready
        else chr_adr + 1 when state = s_generate or state = s_fit_write
        else chr_adr;

    next_last_chr_adr <= '1' when next_chr_adr = (chr_adr'range => '1') and rst = '0' else '0';
    next_fitness_start <= '1' when state /= s_fit_calc and next_state = s_fit_calc and rst = '0' else '0';
    next_done <= '1' when state = s_fit_write and last_chr_adr = '1' and rst = '0' else '0';

    process (clk)
    begin
        if rising_edge(clk) then
            state <= next_state;
            chr_adr <= next_chr_adr;
            chr_we <= next_chr_we;
            last_chr_adr <= next_last_chr_adr;
            fitness_start <= next_fitness_start;
            done <= next_done;
        end if;
    end process;

end architecture;