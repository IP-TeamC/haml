library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math.all;
use work.prng.prim_gen;
use work.prng.sample_seed;

entity tournament_rep is
    generic (
        k : natural;
        var_num : natural;
        fp_size : natural;
        adr_size : natural;
        replace_with_worse : boolean
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        chr_fit : in std_logic_vector(fp_size-1 downto 0);
        chr_do : in std_logic_vector(fp_size*(var_num+2)-1 downto 0);
        chr_adr : out std_logic_vector(adr_size-1 downto 0);
        chr_we : out std_logic;

        done : out std_logic
    );
end entity;

architecture rtl of tournament_rep is

    type t_state is (s_ready, s_read, s_cmp);
    signal state : t_state;
    signal next_state : t_state;

    signal rand_adr : std_logic_vector(adr_size-1 downto 0);
    signal prev_adr : std_logic_vector(adr_size-1 downto 0);

    signal is_worse : std_logic;

    signal worst_adr : std_logic_vector(adr_size-1 downto 0);
    signal next_worst_adr : std_logic_vector(adr_size-1 downto 0);

    signal worst_fit : unsigned(fp_size-1 downto 0);
    signal next_worst_fit : unsigned(fp_size-1 downto 0);

    signal cnt : std_logic_vector(k downto 0);
    signal next_cnt : std_logic_vector(k downto 0);

    signal next_chr_we : std_logic;

begin

    done <= '1' when state = s_cmp else '0';
    chr_adr <= worst_adr when next_state /= s_read else rand_adr;

    lfsr: entity work.lfsr
        generic map(
            degree => adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            generator => prim_gen(adr_size),
            seed => sample_seed(adr_size, 61),
            rand => rand_adr
        );

    next_state <= s_ready when rst = '1'
        else s_read when state = s_ready and start = '1'
        else s_cmp when state = s_read and cnt(k) = '1'
        else s_ready when state = s_cmp
        else state;

    is_worse <= '1' when flat_unsigned(chr_do, fp_size, var_num+1) >= worst_fit
        else '0';

    next_worst_adr <= prev_adr when state = s_read and is_worse = '1'
        else worst_adr;

    next_worst_fit <= (others => '0') when rst = '1' or state = s_ready
        else flat_unsigned(chr_do, fp_size, var_num+1) when state = s_read and is_worse = '1'
        else worst_fit;

    next_cnt <= (0 => '1', others => '0') when rst = '1' or state = s_ready
        else cnt(k-1 downto 0) & '0' when state = s_read
        else cnt;

    next_chr_we <= '1' when rst = '0' and state = s_cmp and (unsigned(chr_fit) <= worst_fit or replace_with_worse)
        else '0';

    process (clk)
    begin
        if rising_edge(clk) then
            state <= next_state;
            prev_adr <= rand_adr;
            worst_adr <= next_worst_adr;
            worst_fit <= next_worst_fit;
            cnt <= next_cnt;
            chr_we <= next_chr_we;

            -- TODO Logging entfernen
            -- if state = s_cmp and (unsigned(chr_fit) <= worst_fit or replace_with_worse) then
            --     report "Replace " & work.util.to_string(worst_fit) & " with " & work.util.to_string(chr_fit) & " at " & work.util.to_string(worst_adr);
            -- end if;
        end if;
    end process;

end architecture;