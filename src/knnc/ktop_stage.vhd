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

        dist_new : in std_logic_vector(dist_size-1 downto 0);
        data_new : in std_logic_vector(data_size-1 downto 0);

        dist_cur : in std_logic_vector(dist_size-1 downto 0);
        data_cur : in std_logic_vector(data_size-1 downto 0);

        done : out std_logic;

        dist_move : out std_logic_vector(dist_size-1 downto 0);
        data_move : out std_logic_vector(data_size-1 downto 0);

        dist_keep : out std_logic_vector(dist_size-1 downto 0);
        data_keep : out std_logic_vector(data_size-1 downto 0)
    );
end entity;

architecture rtl of ktop_stage is

    constant max_signed : std_logic_vector(dist_size-1 downto 0)
        := std_logic_vector((to_signed(1, dist_size) ror 1) - 1);

begin

    process (clk)
    begin
        if rising_edge(clk) then
            done <= start;
            if rst = '1' then
                dist_keep <= max_signed;
                done <= '0';
            elsif start = '1' then
                if signed(dist_new) < signed(dist_cur) then
                    dist_move <= dist_cur;
                    data_move <= data_cur;

                    dist_keep <= dist_new;
                    data_keep <= data_new;
                else
                    dist_move <= dist_new;
                    data_move <= data_new;

                    dist_keep <= dist_cur;
                    data_keep <= data_cur;
                end if;
            end if;
        end if;
    end process;

end architecture;