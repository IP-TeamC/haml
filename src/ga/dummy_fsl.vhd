library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dummy_fsl is
    port (
        clk   : in std_logic;
        rst : in std_logic;
        start : in std_logic;
        we : in std_logic;
        chr_bit : in std_logic;
        const_bit : in std_logic;
        di : in std_logic_vector(12-1 downto 0);
        do : out std_logic_vector(12-1 downto 0);
        fit : out std_logic_vector(8-1 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of dummy_fsl is

    signal chr : std_logic_vector(324-1 downto 0);
    signal const : std_logic_vector(324-1 downto 0);

begin

    fitness_inst: entity work.fitness
        generic map(
            chr_size => 324,
            const_size => 324,
            fp_size => 8,
            fp_frac => 0,
            data_size => 12
        )
        port map(
            clk => clk,
            rst => rst,
            start => start,
            chr => chr,
            const => const,
            di => di,
            do => do,
            fit => fit,
            done => done
        );

    process (clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                chr(323 downto 1) <= chr(322 downto 0);
                chr(0) <= chr_bit;
                const(323 downto 1) <= const(322 downto 0);
                const(0) <= const_bit;
            end if;
        end if;
    end process;

end architecture;