library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity population_mem is
    generic (
        chr_size : natural := 324; -- Chromosombreite
        fp_size : natural := 8; -- Fitnessbreite
        pop_size : natural := 64 -- Anzahl der Individuen
    );
    port (
        clk : in  std_logic;

        -- Leseport
        rd_idx : in std_logic_vector(natural(ceil(log2(real(pop_size))))-1 downto 0);
        rd_chr : out std_logic_vector(chr_size-1 downto 0);
        rd_fit : out std_logic_vector(fp_size-1 downto 0);

        -- Schreibport
        wr_en : in std_logic;
        wr_idx : in std_logic_vector(natural(ceil(log2(real(pop_size))))-1 downto 0);
        wr_chr : in std_logic_vector(chr_size-1 downto 0);
        wr_fit : in std_logic_vector(fp_size-1 downto 0)
    );
end entity;

architecture rtl of population_mem is
    constant idx_size : natural := natural(ceil(log2(real(pop_size))));
    constant row_size : natural := chr_size + fp_size;

    signal ram_di : std_logic_vector(chr_size + fp_size - 1 downto 0);
    signal ram_do : std_logic_vector(row_size-1 downto 0);
begin
    ram_di <= wr_chr & wr_fit;

    mem: entity work.dual_ram
        generic map(
            adr_size => idx_size,
            data_size => row_size
        )
        port map(
            clk => clk,

            adr_a => rd_idx,
            do_a => ram_do,

            we_b => wr_en,
            adr_b => wr_idx,
            di_b => ram_di
        );

    rd_chr <= ram_do(row_size-1 downto fp_size);
    rd_fit <= ram_do(fp_size-1 downto 0);

end architecture;