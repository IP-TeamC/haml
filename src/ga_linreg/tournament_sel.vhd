library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math.all;
use work.prng.prim_gen;
use work.prng.sample_seed;

entity tournament_sel is
    generic (
        k : natural;
        var_num : natural;
        fp_size : natural;
        fit_size : natural;
        adr_size : natural
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        fit_do : in std_logic_vector(fit_size-1 downto 0);
        chr_do : in std_logic_vector(fp_size*(var_num+1)-1 downto 0);
        chr_adr : out std_logic_vector(adr_size-1 downto 0);

        done : out std_logic;
        best_chr1 : out std_logic_vector(fp_size*(var_num+1)-1 downto 0);
        best_chr2 : out std_logic_vector(fp_size*(var_num+1)-1 downto 0)
    );
end entity;

architecture rtl of tournament_sel is

    type t_state is (s_ready, s_cache, s_read1, s_clear, s_read2);
    signal state : t_state;
    signal next_state : t_state;

    signal is_better : std_logic;
    signal best : std_logic_vector(chr_do'range);
    signal next_best : std_logic_vector(chr_do'range);
    signal best_fit : unsigned(fit_do'range);
    signal next_best_fit : unsigned(fit_do'range);
    
    signal best_first : std_logic_vector(chr_do'range);
    signal next_best_first : std_logic_vector(chr_do'range);

    signal cnt : std_logic_vector(2*k+2 downto 0);
    signal next_cnt : std_logic_vector(cnt'range);

    signal fit_cache : unsigned(fit_do'range);
    signal chr_cache : std_logic_vector(chr_do'range);

begin

    done <= cnt(2*k+2);
    best_chr1 <= best_first;
    best_chr2 <= best;

    lfsr: entity work.lfsr
        generic map(
            degree => adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            generator => prim_gen(adr_size),
            seed => sample_seed(adr_size, 60),
            rand => chr_adr
        );

    next_state <= s_ready when rst = '1'
        else s_cache when state = s_ready and start = '1'
        else s_read1 when state = s_cache
        else s_clear when state = s_read1 and cnt(k) = '1'
        else s_read2 when state = s_clear
        else s_ready when state = s_read2 and cnt(2*k+1) = '1'
        else state;

    is_better <= '1' when fit_cache <= best_fit
        else '0';

    next_best <= chr_cache when (state = s_read1 or state = s_read2) and is_better = '1'
        else best;

    next_best_fit <= (others => '1') when (state = s_ready and start = '1') or (state = s_clear)
        else fit_cache when (state = s_read1 or state = s_read2) and is_better = '1'
        else best_fit;

    next_cnt <= (0 => '1', others => '0') when state = s_ready
        else cnt(2*k+1 downto 0) & '0';

    next_best_first <= best when state = s_clear
        else best_first;

    process (clk)
    begin
        if rising_edge(clk) then
            state <= next_state;
            best <= next_best;
            best_fit <= next_best_fit;
            best_first <= next_best_first;
            cnt <= next_cnt;
            fit_cache <= unsigned(fit_do);
            chr_cache <= chr_do;
        end if;
    end process;

end architecture;