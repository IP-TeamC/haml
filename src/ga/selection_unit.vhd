library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity selection_unit is
    generic (
        fit_size : natural := 8; -- Fitnessbreite
        pop_size : natural := 64; -- Anzahl der Individuen
        k : natural := 4 -- Tournament Size
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        -- Zufallszahlen für Kandidatenauswahl
        rnd : in std_logic_vector(natural(ceil(log2(real(pop_size))))*k*2-1 downto 0);

        -- Fitnesswerte
        fit_we : in std_logic;
        fit_idx : in std_logic_vector(natural(ceil(log2(real(k*2))))-1 downto 0);
        fit_in : in std_logic_vector(fit_size-1 downto 0);

        -- Ergebnis (Indizes der beiden Gewinner)
        idx_a : out std_logic_vector(natural(ceil(log2(real(pop_size))))-1 downto 0);
        idx_b : out std_logic_vector(natural(ceil(log2(real(pop_size))))-1 downto 0);
        done : out std_logic
    );
end entity;