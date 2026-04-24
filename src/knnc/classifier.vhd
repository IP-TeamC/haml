library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math.all;
use work.signed_dist;
use work.ktop;
use work.kselect;

entity classifier is

    generic (
        k : natural := 3;
        fp_size : natural := 18;
        fp_frac : natural := 4;
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
    signal next_adr : std_logic_vector(adr_size-1 downto 0);

    signal dist : signed(fp_size-1 downto 0);
    signal top_dist : std_logic_vector(k*fp_size-1 downto 0);
    signal top_class : std_logic_vector(k*class_size-1 downto 0);

    signal dist_done : std_logic;
    signal cmp_done : std_logic;
    signal selector_done_prev : std_logic;
    signal selector_done_next : std_logic;

    signal dist_class : std_logic_vector(class_size-1 downto 0);
    signal selected_class : std_logic_vector(class_size-1 downto 0);

    signal component_rst : std_logic;

begin

    distance: entity signed_dist
        generic map (
            n => feature_num,
            fp_size => fp_size,
            fp_frac => fp_frac,
            data_size => class_size
        )
        port map (
            clk => clk,
            rst => component_rst,
            start => read_cmp,
            a => cmp_features,
            b => cur_features,
            dist_sq => dist,
            done => dist_done,
            di => cur_class,
            do => dist_class
        );
    comparator: entity ktop
        generic map(
            k => k,
            dist_size => fp_size,
            class_size => class_size
        )
        port map(
            clk => clk,
            rst => component_rst,
            start => dist_done,
            dist => std_logic_vector(dist),
            class => dist_class,
            top_dist => top_dist,
            top_class => top_class,
            done => cmp_done
        );
    selector: entity work.kselect
        generic map(
            k => k,
            class_size => class_size
        )
        port map(
            clk => clk,
            rst => component_rst,
            start => cmp_done,
            top_class => top_class,
            class => selected_class,
            done => selector_done_next
        );

    ram_adr <= cur_adr when started = '1'
        else std_logic_vector(unsigned(end_adr)+1) ;
    cur_features <= ram_data(feature_num*fp_size+class_size-1 downto class_size);
    cur_class <= ram_data(class_size-1 downto 0);
    next_adr <= std_logic_vector(unsigned(cur_adr) + 1);
    done <= not selector_done_next and selector_done_prev;
    component_rst <= rst or (start and not started);

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                started <= '0';
                read_cmp <= '0';
            elsif started = '1' then
                if read_cmp = '0' then
                    cmp_features <= cur_features;
                    read_cmp <= '1';
                elsif unsigned(cur_adr) = unsigned(end_adr)+1 then
                    started <= '0';
                    read_cmp <= '0';
                end if;
                cur_adr <= next_adr;
            elsif start = '1' then
                cur_adr <= (others => '0');
                started <= start;
            end if;

            if selector_done_next = '1' then
                class <= selected_class;
            end if;
            selector_done_prev <= selector_done_next;
        end if;
    end process;

end architecture;