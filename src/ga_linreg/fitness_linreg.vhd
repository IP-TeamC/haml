library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Fitness-Berechnung
-- Controller fuer rse_linreg
-- liest Datenpunkte aus dem RAM und stellt diese der tatsaechlichen Fitness-Berechnung (rse_linreg) nacheinander zur Verfügung (inkl. Start-/Stopp-Signale)
entity fitness_linreg is
    generic (
        var_num : natural;
        fp_size : natural;
        fp_frac : natural;
        fit_size : natural;
        adr_size : natural;
        square : boolean
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;
        chr : in std_logic_vector(fp_size*(var_num+1)-1 downto 0);

        dp_end_adr : in std_logic_vector(adr_size-1 downto 0);
        ram_dp_do : in std_logic_vector(fp_size*(var_num+1)-1 downto 0);
        ram_dp_adr : out std_logic_vector(adr_size-1 downto 0);

        fit : out std_logic_vector(fit_size-1 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of fitness_linreg is

    type t_state is (s_ready, s_first, s_running, s_last);
    signal state : t_state;
    signal next_state : t_state;

    signal adr : unsigned(ram_dp_adr'range);
    signal next_adr : unsigned(ram_dp_adr'range);

    signal last_adr : std_logic;
    signal next_last_adr : std_logic;

    signal mse_valid : std_logic;

begin

    rse_linreg: entity work.rse_linreg
        generic map(
            var_num => var_num,
            fp_size => fp_size,
            fp_frac => fp_frac,
            fit_size => fit_size,
            adr_size => adr_size,
            square => square
        )
        port map(
            clk => clk,
            rst => rst,
            valid => mse_valid,
            chr => chr,
            ram_dp_do => ram_dp_do,
            fit => fit,
            done => done
        );

    ram_dp_adr <= std_logic_vector(adr);
    mse_valid <= '1' when state = s_running
        else '0';

    next_adr <= (others => '0') when (state = s_ready and start = '1') or rst = '1'
        else adr + 1;

    next_state <= s_ready when rst = '1' or last_adr = '1'
        else s_first when state = s_ready and start = '1'
        else s_running when state = s_first
        else state;

    next_last_adr <= '1' when rst = '0' and std_logic_vector(adr) = dp_end_adr
        else '0';

    process (clk)
    begin
        if rising_edge(clk) then
            state <= next_state;
            adr <= next_adr;
            last_adr <= next_last_adr;
        end if;
    end process;

end architecture;