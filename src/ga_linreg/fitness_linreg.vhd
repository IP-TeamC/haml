library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fitness_linreg is
    generic (
        var_num : natural := 2;
        fp_size : natural := 18;
        fp_frac : natural := 16;
        adr_size : natural := 8
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;
        chr : in std_logic_vector(fp_size*(var_num+1)-1 downto 0);

        end_adr : in std_logic_vector(adr_size-1 downto 0);
        ram_data : in std_logic_vector(fp_size*(var_num+1)-1 downto 0);
        ram_adr : out std_logic_vector(adr_size-1 downto 0);

        fit : out std_logic_vector(fp_size-1 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of fitness_linreg is

    type t_state is (s_ready, s_first, s_running, s_last);
    signal state : t_state;
    signal next_state : t_state;

    signal adr : unsigned(ram_adr'range);
    signal next_adr : unsigned(ram_adr'range);
    signal last_adr : std_logic;

    signal mse_start : std_logic;

begin

    mse_linreg: entity work.mse_linreg
        generic map(
            var_num => var_num,
            fp_size => fp_size,
            fp_frac => fp_frac,
            adr_size => adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            start => mse_start,
            chr => chr,
            ram_data => ram_data,
            fit => fit,
            done => done
        );

    ram_adr <= std_logic_vector(adr);
    mse_start <= '1' when state = s_running else '0';

    next_adr <= (others => '0') when (state = s_ready and start = '1') or rst = '1'
        else adr + 1;

    next_state <= s_ready when rst = '1' or last_adr = '1'
        else s_first when state = s_ready and start = '1'
        else s_running when state = s_first
        else state;

    process (clk)
    begin
        if rising_edge(clk) then
            state <= next_state;
            adr <= next_adr;

            if rst = '1' then
                last_adr <= '0';
            elsif std_logic_vector(adr) = end_adr then
                last_adr <= '1';
            else
                last_adr <= '0';
            end if;
        end if;
    end process;

end architecture;