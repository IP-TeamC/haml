library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math.all;
use work.prng.prim_gen;
use work.prng.sample_seed;

entity tournament_sel is
    generic (
        k : natural := 5;
        var_num : natural := 2;
        fp_size : natural := 18;
        adr_size : natural := 8
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        chr_do : in std_logic_vector(fp_size*(var_num+2)-1 downto 0);
        chr_adr : out std_logic_vector(adr_size-1 downto 0);

        done : out std_logic;
        best_chr : out std_logic_vector(fp_size*(var_num+2)-1 downto 0)
    );
end entity;

architecture rtl of tournament_sel is

    type t_state is (s_ready, s_read);
    signal state : t_state;
    signal next_state : t_state;

    signal best : std_logic_vector(fp_size*(var_num+2)-1 downto 0);
    signal cnt : std_logic_vector(k downto 0);

    signal is_better : std_logic;

begin

    done <= cnt(k);
    best_chr <= best;

    lfsr: entity work.lfsr
        generic map(
            degree => adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            generator => prim_gen(adr_size),
            seed => sample_seed(adr_size-1 downto 0),
            rand => chr_adr
        );

    next_state <= s_ready when rst = '1'
        else s_read when state = s_ready and start = '1'
        else s_ready when state = s_read and cnt(k-1) = '1'
        else state;

    is_better <= '1' when flat_unsigned(chr_do, fp_size, var_num+1) < flat_unsigned(best, fp_size, var_num+1) else '0';

    process (clk)
    begin
        if rising_edge(clk) then
            state <= next_state;

            if state = s_ready then
                if start = '1' then
                    best <= (others => '1');
                end if;
                cnt <= (0 => '1', others => '0');
            elsif state = s_read then
                cnt <= cnt(k-1 downto 0) & '0';
            end if;

            if state = s_read and is_better = '1' then
                best <= chr_do;
            end if;
        end if;
    end process;

end architecture;