library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.math.all;

entity knnc is

    generic (
        k : natural := 3;
        fp_size : natural := 18;
        fp_frac : natural := 12;
        class_size : natural := 1; -- Constraint: class_size <= fp_size
        feature_num : natural := 7;
        adr_size : natural := 11 -- Maximum für XC3S500E (12 max. mit 1600 und Goal Timing Performance)
    );

    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        mark_end : in std_logic;
        ram_we : in std_logic;
        ram_adr : in std_logic_vector(adr_size-1 downto 0);
        ram_data : in std_logic_vector(fp_size-1 downto 0);
        ram_part : in std_logic_vector(natural(ceil(log2(real(feature_num+1))))-1 downto 0); -- 0 => Class, 1 => Feature 1, ...

        done : out std_logic;
        class : out std_logic_vector(class_size-1 downto 0)
    );

end entity;

architecture rtl of knnc is

    subtype t_ram_adr is std_logic_vector(adr_size-1 downto 0);
    subtype t_ram_data is std_logic_vector(feature_num*fp_size+class_size-1 downto 0);
    signal i_ram_we : std_logic_vector(feature_num downto 0); -- Write Enable der RAMs
    signal i_ram_adr : t_ram_adr; -- RAM-Adresse (Read vom Classifier oder Write von außen)
    signal i_ram_data : t_ram_data; -- Zusammengesetzter RAM
    signal i_read_adr : t_ram_adr; -- Lese-Adresse vom Classifier
    signal i_dp_adr : t_ram_adr; -- Gespeicherte Datenpunkt-Adresse (zu klassifizieren)

begin

    classifier: entity work.classifier
        generic map(
            k => k,
            fp_size => fp_size,
            fp_frac => fp_frac,
            class_size => class_size,
            feature_num => feature_num,
            adr_size => adr_size
        )
        port map(
            clk => clk,
            rst => rst,
            start => start,
            ram_adr => i_read_adr,
            ram_data => i_ram_data,
            dp_adr => i_dp_adr,
            done => done,
            class => class
        );

    gen_ram: for i in 0 to feature_num generate
        i_ram_we(i) <= '1' when ram_we = '1' and to_integer(unsigned(ram_part)) = i else '0';

        gen_feature_ram: if i /= 0 generate
            ram_feature: entity work.ram
                generic map(
                    adr_size => adr_size,
                    data_size => fp_size
                )
                port map(
                    clk => clk,
                    we => i_ram_we(i),
                    adr => i_ram_adr,
                    di => ram_data,
                    do => i_ram_data(flat_upper(fp_size, i-1)+class_size downto flat_lower(fp_size, i-1)+class_size)
                );
        end generate;

        gen_class_ram: if i = 0 generate
            ram_class: entity work.ram
                generic map(
                    adr_size => adr_size,
                    data_size => class_size
                )
                port map(
                    clk => clk,
                    we => i_ram_we(i),
                    adr => i_ram_adr,
                    di => ram_data(class_size-1 downto 0),
                    do => i_ram_data(class_size-1 downto 0)
                );
        end generate;
    end generate;

    i_ram_adr <= ram_adr when ram_we = '1' else i_read_adr;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if mark_end = '1' then
                i_dp_adr <= std_logic_vector(unsigned(ram_adr)+1);
            end if;
        end if;
    end process;

end architecture;