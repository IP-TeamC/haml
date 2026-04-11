library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.signed_dist;
use work.math.all;

entity classifier is

    generic (
        k : natural := 3;
        fp_size : natural := 36;
        fp_frac : natural := 10;
        class_size : natural := 1;
        feature_num : natural := 7;
        adr_size : natural := 8
    );

    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        -- Option 1 (Alternative): Feature 1 (fp_size), Feature 2 (fp_size), ..., Feature n (fp_size), Class ([...] class_size) in aufeinanderfolgenden Zeilen
        -- Option 2 (Wahl): Feature 1 (fp_size) + Feature 2 (fp_size) + ... + Feature n (fp_size) + Class (class_size) in einer Zeile
        ram_adr : out std_logic_vector(adr_size-1 downto 0);
        ram_data : in std_logic_vector(feature_num*fp_size+class_size-1 downto 0);

        start_adr : in std_logic_vector(adr_size-1 downto 0);
        end_adr : in std_logic_vector(adr_size-1 downto 0); -- zu klassifizierender Datenpunkt ist end_adr+1

        done : out std_logic;
        class : out std_logic_vector(class_size-1 downto 0)
    );

end entity;

architecture rtl of classifier is

    subtype t_features is std_logic_vector(feature_num*fp_size-1 downto 0);
    subtype t_class is std_logic_vector(class_size-1 downto 0);

    signal started : std_logic;
    signal read_cmp : std_logic;
    signal cmp_features : t_features;

    signal cur_features : t_features;
    signal cur_class : t_class;
    signal cur_adr : std_logic_vector(adr_size-1 downto 0);

begin

    -- distance: entity signed_dist
    --     generic map (
    --         n => feature_num,
    --         fp_size => fp_size,
    --         fp_frac => fp_frac
    --     )
    --     port map (
    --         clk => clk,
    --         rst => rst,
    --         start => read_cmp,
    --         a => cmp_features,
    --         b => cur_features,
    --         dist_sq => dist_sq,
    --         done => done
    --     );

    ram_adr <= cur_adr when started = '1'
        else std_logic_vector(unsigned(end_adr)+1) ;
    cur_features <= ram_data(feature_num*fp_size+class_size-1 downto class_size);
    cur_class <= ram_data(class_size-1 downto 0);

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                started <= '0';
                read_cmp <= '0';
            elsif started = '1' then
                if read_cmp = '1' then
                    -- todo
                else
                    cmp_features <= cur_features;
                    read_cmp <= '1';
                end if;
            elsif start = '1' then
                cur_adr <= start_adr;
                started <= start;
            end if;
        end if;
    end process;



end architecture;