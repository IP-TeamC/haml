library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math.all;
use work.prng.prim_gen;
use work.prng.sample_seed;

entity tournament_rep is
    generic (
        k : natural := 5;
        var_num : natural := 2;
        fp_size : natural := 18;
        adr_size : natural := 8;
        replace_if_worse : boolean := true
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
    signal prev_state : t_state;
    signal next_state : t_state;

    signal rand_adr : std_logic_vector(adr_size-1 downto 0);
    signal prev_adr : std_logic_vector(adr_size-1 downto 0);
    signal worst_adr : std_logic_vector(adr_size-1 downto 0);
    signal worst_fit : unsigned(fp_size-1 downto 0);
    signal cnt : std_logic_vector(k downto 0);

    signal is_worse : std_logic;

begin

    done <= '1' when state = s_cmp else '0';
    chr_adr <= worst_adr when prev_state = s_cmp else rand_adr;

    lfsr: entity work.lfsr
        generic map(
            degree => adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            generator => prim_gen(adr_size),
            seed => sample_seed(sample_seed'high downto sample_seed'high-adr_size+1),
            rand => rand_adr
        );

    next_state <= s_ready when rst = '1'
        else s_read when state = s_ready and start = '1'
        else s_cmp when state = s_read and cnt(k) = '1'
        else s_ready when state = s_cmp
        else state;

    is_worse <= '1' when flat_unsigned(chr_do, fp_size, var_num+1) > worst_fit else '0';

    process (clk)
    begin
        if rising_edge(clk) then
            prev_state <= state;
            state <= next_state;
            prev_adr <= rand_adr;

            if rst = '1' or state = s_ready then
                chr_we <= '0';
                worst_fit <= (others => '0');
                cnt <= (0 => '1', others => '0');
            elsif state = s_read then
                cnt <= cnt(k-1 downto 0) & '0';
            end if;

            if state = s_read and is_worse = '1' then
                worst_adr <= prev_adr;
                worst_fit <= flat_unsigned(chr_do, fp_size, var_num+1);
            end if;

            -- TODO Logging entfernen
            if state = s_cmp and (unsigned(chr_fit) < worst_fit or replace_if_worse) then
                report "Replace " & work.util.to_string(worst_fit) & " with " & work.util.to_string(chr_fit) & " at " & work.util.to_string(worst_adr);
                chr_we <= '1';
            end if;
        end if;
    end process;

end architecture;