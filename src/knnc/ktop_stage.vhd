library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ktop_stage is
    generic (
        dist_size : natural := 36;
        data_size : natural := 1
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;
        dist_in : in std_logic_vector(dist_size-1 downto 0);
        data_in : in std_logic_vector(data_size-1 downto 0);

        done : out std_logic;
        -- Weitergabe an nächste Stage
        dist_next : out std_logic_vector(dist_size-1 downto 0);
        data_next : out std_logic_vector(data_size-1 downto 0);
        -- Aktuell kleinster Datenpunkt
        dist_min : out std_logic_vector(dist_size-1 downto 0);
        data_min : out std_logic_vector(data_size-1 downto 0)
    );
end entity;

architecture rtl of ktop_stage is
    constant signed_max : std_logic_vector(dist_size-1 downto 0) := std_logic_vector((to_signed(1, dist_size) ror 1) - 1);
    signal dist : std_logic_vector(dist_size-1 downto 0);
    signal data : std_logic_vector(data_size-1 downto 0);
begin

    dist_min <= dist;
    data_min <= data;

    process (clk)
    begin
        if rising_edge(clk) then
            done <= start;
            if rst = '1' then
                dist <= signed_max;
                done <= '0';
            elsif start = '1' then
                if signed(dist_in) < signed(dist) then
                    dist_next <= dist;
                    data_next <= data;
                    dist <= dist_in;
                    data <= data_in;
                else
                    dist_next <= dist_in;
                    data_next <= data_in;
                end if;
            end if;
        end if;
    end process;

end architecture;