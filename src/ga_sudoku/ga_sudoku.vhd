library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.ga_pkg.all;
use work.util.all;

entity ga_sudoku is
    generic (
        pop_size : natural := 64;
        k : natural := 4;
        mut_bits : natural := 4;
        max_gen : natural := 10000;
        fp_size : natural := 8
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;

        const : in std_logic_vector(chr_size-1 downto 0);
        const_mask : in std_logic_vector(chr_size-1 downto 0);

        best_chr : out std_logic_vector(chr_size-1 downto 0);
        best_fit : out std_logic_vector(fp_size-1 downto 0);
        done : out std_logic
    );
end entity;

architecture rtl of ga_sudoku is

    constant IDX_W : natural := natural(ceil(log2(real(pop_size))));
    constant K_IDX_W : natural := natural(ceil(log2(real(k*2))));
    constant GEN_W : natural := natural(ceil(log2(real(max_gen+1))));

    constant REPR_W : natural := IDX_W + 1;

    -- -----------------------------------------------------------------------
    -- Zufallsgenerator
    -- -----------------------------------------------------------------------
    constant RND_PER_SWAP : natural := 4;
    constant RND_INIT_BITS : natural := blocks_per_side * blocks_per_side * sudoku_size * RND_PER_SWAP; -- 324
    constant RND_SEL_BITS : natural := IDX_W * k * 2;
    constant RND_CX_BITS : natural := blocks_per_side * blocks_per_side;
    constant RND_MUT_BITS : natural := mut_bits + 4 + 4 + 4;  -- gate+blk+posA+posB
    constant RND_MUT_A_BITS : natural := RND_MUT_BITS;
    constant RND_MUT_B_BITS : natural := RND_MUT_BITS;
    constant RND_TOTAL : natural := RND_SEL_BITS + RND_CX_BITS + RND_MUT_A_BITS + RND_MUT_B_BITS + RND_INIT_BITS;

    constant LFSR_N : natural := natural(ceil(real(RND_TOTAL) / 32.0));
    constant RND_PAD : natural := LFSR_N * 32;

    signal rnd : std_logic_vector(RND_PAD-1 downto 0);
    signal rnd_sel : std_logic_vector(RND_SEL_BITS-1 downto 0);
    signal rnd_cx : std_logic_vector(RND_CX_BITS-1 downto 0);
    signal rnd_mut_a : std_logic_vector(RND_MUT_A_BITS-1 downto 0);
    signal rnd_mut_b : std_logic_vector(RND_MUT_B_BITS-1 downto 0);
    signal rnd_init : std_logic_vector(RND_INIT_BITS-1 downto 0);

    -- -----------------------------------------------------------------------
    -- pop_mem
    -- -----------------------------------------------------------------------
    signal pm_rd_idx : std_logic_vector(IDX_W downto 0);
    signal pm_rd_chr : std_logic_vector(chr_size-1 downto 0);
    signal pm_rd_fit : std_logic_vector(fp_size-1 downto 0);
    signal pm_wr_en : std_logic;
    signal pm_wr_idx : std_logic_vector(IDX_W downto 0);
    signal pm_wr_chr : std_logic_vector(chr_size-1 downto 0);
    signal pm_wr_fit : std_logic_vector(fp_size-1 downto 0);
    signal ping_pong : std_logic := '0';

    -- -----------------------------------------------------------------------
    -- chr_init
    -- -----------------------------------------------------------------------
    signal ci_start : std_logic;
    signal ci_chr : std_logic_vector(chr_size-1 downto 0);
    signal ci_done : std_logic;

    -- -----------------------------------------------------------------------
    -- fitness
    -- -----------------------------------------------------------------------
    signal fit_start : std_logic;
    signal fit_chr : std_logic_vector(chr_size-1 downto 0);
    signal fit_val : std_logic_vector(fp_size-1 downto 0);
    signal fit_done : std_logic;

    -- -----------------------------------------------------------------------
    -- tournament_sel
    -- -----------------------------------------------------------------------
    signal sel_start : std_logic;
    signal sel_fit_we : std_logic;
    signal sel_fit_idx : std_logic_vector(K_IDX_W-1 downto 0);
    signal sel_fit_in : std_logic_vector(fp_size-1 downto 0);
    signal sel_idx_a : std_logic_vector(IDX_W-1 downto 0);
    signal sel_idx_b : std_logic_vector(IDX_W-1 downto 0);
    signal sel_done : std_logic;

    type t_cand_arr is array (0 to k*2-1) of std_logic_vector(IDX_W-1 downto 0);
    signal cand : t_cand_arr;
    signal cand_latch : t_cand_arr;
    signal sel_cand_vec : std_logic_vector(IDX_W*k*2-1 downto 0);

    -- -----------------------------------------------------------------------
    -- crossover
    -- -----------------------------------------------------------------------
    signal cx_start : std_logic;
    signal cx_par_a : std_logic_vector(chr_size-1 downto 0);
    signal cx_par_b : std_logic_vector(chr_size-1 downto 0);
    signal cx_child_a : std_logic_vector(chr_size-1 downto 0);
    signal cx_child_b : std_logic_vector(chr_size-1 downto 0);
    signal cx_done : std_logic;

    -- -----------------------------------------------------------------------
    -- mutation
    -- -----------------------------------------------------------------------
    signal mut_a_start : std_logic;
    signal mut_a_out : std_logic_vector(chr_size-1 downto 0);
    signal mut_a_done : std_logic;

    signal mut_b_start : std_logic;
    signal mut_b_out : std_logic_vector(chr_size-1 downto 0);
    signal mut_b_done : std_logic;

    -- -----------------------------------------------------------------------
    -- Controller
    -- -----------------------------------------------------------------------
    type t_state is (
        S_IDLE,
        S_INIT_START, S_INIT_WAIT, S_INIT_WRITE,
        S_EVAL_READ, S_EVAL_READ_WAIT, S_EVAL_LOAD, S_EVAL_FIT_WAIT, S_EVAL_WRITE,
        S_CHECK,
        S_ELITE_WRITE,
        S_SEL_READ, S_SEL_READ_WAIT, S_SEL_LOAD, S_SEL_START, S_SEL_WAIT,
        S_REPR_READ_A, S_REPR_READ_A_WAIT, S_REPR_LOAD_A,
        S_REPR_READ_B, S_REPR_READ_B_WAIT, S_REPR_LOAD_B,
        S_CX_WAIT,
        S_MUT_WAIT,
        S_WRITE_A, S_WRITE_B,
        S_DONE
    );
    signal state : t_state;

    signal eval_ctr : unsigned(IDX_W-1 downto 0);
    signal repr_ctr : unsigned(REPR_W-1 downto 0);
    signal sel_ctr : unsigned(K_IDX_W-1 downto 0);
    signal gen_ctr : unsigned(GEN_W-1 downto 0);
    signal init_ctr : unsigned(IDX_W-1 downto 0);

    signal chr_a_buf : std_logic_vector(chr_size-1 downto 0);
    signal idx_a_buf : std_logic_vector(IDX_W-1 downto 0);
    signal idx_b_buf : std_logic_vector(IDX_W-1 downto 0);
    signal last_chr : std_logic_vector(chr_size-1 downto 0);
    signal last_fit : std_logic_vector(fp_size-1 downto 0);

    signal best_fit_r : std_logic_vector(fp_size-1 downto 0);
    signal best_chr_r : std_logic_vector(chr_size-1 downto 0);

begin

    -- -----------------------------------------------------------------------
    -- Zufallsgenerator
    -- -----------------------------------------------------------------------
    rng: entity work.rng_bank
        generic map(degree => 32, n => LFSR_N)
        port map(
            clk => clk,
            rst => rst,
            rand => rnd
        );

    rnd_sel <= rnd(RND_SEL_BITS - 1 downto 0);
    rnd_cx <= rnd(RND_SEL_BITS + RND_CX_BITS - 1 downto RND_SEL_BITS);
    rnd_mut_a <= rnd(RND_SEL_BITS + RND_CX_BITS + RND_MUT_A_BITS - 1 downto RND_SEL_BITS + RND_CX_BITS);
    rnd_mut_b <= rnd(RND_SEL_BITS + RND_CX_BITS + RND_MUT_A_BITS + RND_MUT_B_BITS - 1 downto RND_SEL_BITS + RND_CX_BITS + RND_MUT_A_BITS);
    rnd_init <= rnd(RND_SEL_BITS + RND_CX_BITS + RND_MUT_A_BITS + RND_MUT_B_BITS + RND_INIT_BITS - 1 downto RND_SEL_BITS + RND_CX_BITS + RND_MUT_A_BITS + RND_MUT_B_BITS);

    gen_cand: for i in 0 to k*2-1 generate
        cand(i) <= rnd_sel(IDX_W*(i+1)-1 downto IDX_W*i);
    end generate;

    gen_sel_cand: for i in 0 to k*2-1 generate
        sel_cand_vec(IDX_W*(i+1)-1 downto IDX_W*i) <= cand_latch(i);
    end generate;

    -- -----------------------------------------------------------------------
    -- pop_mem
    -- -----------------------------------------------------------------------
    pop_mem: entity work.pop_mem_sudoku
        generic map(chr_size => chr_size, fp_size => fp_size, pop_size => pop_size)
        port map(
            clk => clk,
            rd_idx => pm_rd_idx,
            rd_chr => pm_rd_chr,
            rd_fit => pm_rd_fit,
            wr_en  => pm_wr_en,
            wr_idx => pm_wr_idx,
            wr_chr => pm_wr_chr,
            wr_fit => pm_wr_fit
        );

    -- -----------------------------------------------------------------------
    -- chr_init
    -- -----------------------------------------------------------------------
    chr_init_u: entity work.chr_init_sudoku
        generic map(rnd_per_swap => RND_PER_SWAP)
        port map(
            clk => clk,
            rst => rst,
            start => ci_start,
            const => const,
            const_mask => const_mask,
            rnd => rnd_init,
            chr => ci_chr,
            done => ci_done
        );

    -- -----------------------------------------------------------------------
    -- fitness
    -- -----------------------------------------------------------------------
    fit_u: entity work.fitness_sudoku
        generic map(chr_size => chr_size, fp_size => fp_size)
        port map(
            clk => clk,
            rst => rst,
            start => fit_start,
            chr => fit_chr,
            di => (others => '0'),
            do => open,
            const => const,
            fit => fit_val,
            done => fit_done
        );

    -- -----------------------------------------------------------------------
    -- tournament_sel
    -- -----------------------------------------------------------------------
    sel_u: entity work.tournament_sel_sudoku
        generic map(fp_size => fp_size, pop_size => pop_size, k => k)
        port map(
            clk => clk,
            rst => rst,
            start => sel_start,
            cand_in  => sel_cand_vec,
            fit_we => sel_fit_we,
            fit_idx => sel_fit_idx,
            fit_in => sel_fit_in,
            idx_a => sel_idx_a,
            idx_b => sel_idx_b,
            done => sel_done
        );

    -- -----------------------------------------------------------------------
    -- crossover
    -- -----------------------------------------------------------------------
    cx_u: entity work.crossover_sudoku
        port map(
            clk => clk,
            rst => rst,
            start => cx_start,
            const_mask => const_mask,
            parent_a => cx_par_a,
            parent_b => cx_par_b,
            rnd_blk => rnd_cx,
            child_a => cx_child_a,
            child_b => cx_child_b,
            done => cx_done
        );

    -- -----------------------------------------------------------------------
    -- mutation: Kind A
    -- -----------------------------------------------------------------------
    mut_a_u: entity work.mutation_sudoku
        generic map(mut_bits => mut_bits)
        port map(
            clk => clk,
            rst => rst,
            start => mut_a_start,
            const_mask => const_mask,
            chr_in => cx_child_a,
            chr_out => mut_a_out,
            rnd_gate => rnd_mut_a(mut_bits-1 downto 0),
            rnd_blk => rnd_mut_a(mut_bits+3 downto mut_bits),
            rnd_pos_a => rnd_mut_a(mut_bits+7 downto mut_bits+4),
            rnd_pos_b => rnd_mut_a(mut_bits+11 downto mut_bits+8),
            done => mut_a_done
        );

    -- -----------------------------------------------------------------------
    -- mutation: Kind B
    -- -----------------------------------------------------------------------
    mut_b_u: entity work.mutation_sudoku
        generic map(mut_bits => mut_bits)
        port map(
            clk => clk,
            rst => rst,
            start => mut_b_start,
            const_mask => const_mask,
            chr_in => cx_child_b,
            chr_out => mut_b_out,
            rnd_gate => rnd_mut_b(mut_bits-1 downto 0),
            rnd_blk => rnd_mut_b(mut_bits+3 downto mut_bits),
            rnd_pos_a => rnd_mut_b(mut_bits+7 downto mut_bits+4),
            rnd_pos_b => rnd_mut_b(mut_bits+11 downto mut_bits+8),
            done => mut_b_done
        );

    -- -----------------------------------------------------------------------
    -- Ausgaben
    -- -----------------------------------------------------------------------
    best_fit <= best_fit_r;
    best_chr <= best_chr_r;

    -- -----------------------------------------------------------------------
    -- Controller
    -- -----------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then

            pm_wr_en <= '0';
            fit_start <= '0';
            sel_start <= '0';
            sel_fit_we <= '0';
            cx_start <= '0';
            mut_a_start <= '0';
            mut_b_start <= '0';
            ci_start <= '0';
            done <= '0';

            if rst = '1' then
                state <= S_IDLE;
                eval_ctr <= (others => '0');
                repr_ctr <= (others => '0');
                sel_ctr <= (others => '0');
                gen_ctr <= (others => '0');
                init_ctr <= (others => '0');
                best_fit_r <= (others => '1');

            else
                case state is

                    when S_IDLE =>
                        if start = '1' then
                            eval_ctr <= (others => '0');
                            repr_ctr <= (others => '0');
                            
                            gen_ctr <= to_unsigned(1, GEN_W); 
                            init_ctr <= (others => '0');
                            best_fit_r <= (others => '1');
                            
                            report "[GA] Sudoku geladen (Uninitialisiertes Feld)" severity note;
                            print_sudoku(deserialize_sudoku(const));
                            report "[GA] Starte Solver..." severity note;
                            report "[GA] Initialisiere leere Felder..." severity note;

                            state <= S_INIT_START;
                        end if;

                    -- --------------------------------------------------------
                    -- INITIALISIERUNG
                    -- --------------------------------------------------------
                    when S_INIT_START =>
                        ci_start <= '1';

                        state <= S_INIT_WAIT;

                    when S_INIT_WAIT =>
                        if ci_done = '1' then
                            state <= S_INIT_WRITE;
                        end if;

                    when S_INIT_WRITE =>
                        pm_wr_en <= '1';
                        pm_wr_idx <= ping_pong & std_logic_vector(init_ctr);
                        pm_wr_chr <= ci_chr;
                        pm_wr_fit <= (others => '1');

                        if init_ctr = pop_size - 1 then
                            eval_ctr <= (others => '0');
                            state <= S_EVAL_READ;
                        else
                            init_ctr <= init_ctr + 1;
                            state <= S_INIT_START;
                        end if;

                    -- --------------------------------------------------------
                    -- EVALUATION
                    -- --------------------------------------------------------
                    when S_EVAL_READ =>
                        pm_rd_idx <= ping_pong & std_logic_vector(eval_ctr);
                        state <= S_EVAL_READ_WAIT;

                    when S_EVAL_READ_WAIT =>
                        state <= S_EVAL_LOAD;

                    when S_EVAL_LOAD =>
                        last_chr <= pm_rd_chr;
                        fit_chr <= pm_rd_chr;
                        fit_start <= '1';
                        state <= S_EVAL_FIT_WAIT;

                    when S_EVAL_FIT_WAIT =>
                        if fit_done = '1' then
                            last_fit <= fit_val;
                            state <= S_EVAL_WRITE;
                        end if;

                    when S_EVAL_WRITE =>
                        pm_wr_en <= '1';
                        pm_wr_idx <= ping_pong & std_logic_vector(eval_ctr);
                        pm_wr_chr <= last_chr;
                        pm_wr_fit <= last_fit;

                        if last_fit = (last_fit'range => '1') then
                            report "[GA] WARNUNG: Individuum idx=" & integer'image(to_integer(eval_ctr)) & 
                                " hat fit=255 (ungueltig)!" severity warning;
                            print_sudoku(deserialize_sudoku(last_chr));
                            report "[GA] const:" severity warning;
                            print_sudoku(deserialize_sudoku(const));
                        end if;

                        if unsigned(last_fit) <= unsigned(best_fit_r) then
                            best_fit_r <= last_fit;
                            best_chr_r <= last_chr;
                            debug_print("[GA] Neues elitaeres Individuum: idx=" & integer'image(to_integer(eval_ctr)) & " fit=" & integer'image(to_integer(unsigned(last_fit))));
                        end if;

                        if eval_ctr = pop_size - 1 then
                            state <= S_CHECK;
                        else
                            eval_ctr <= eval_ctr + 1;
                            state <= S_EVAL_READ;
                        end if;
                        

                    -- --------------------------------------------------------
                    -- CHECK
                    -- --------------------------------------------------------
                    when S_CHECK =>
                        report "[GA] Generation " & integer'image(to_integer(gen_ctr)) & " best_fit=" & integer'image(to_integer(unsigned(best_fit_r))) severity note;
                        print_sudoku(deserialize_sudoku(best_chr_r));

                        if best_fit_r = (best_fit_r'range => '0') then
                            report "[GA] Sudoku richtig nach " & integer'image(to_integer(gen_ctr)) & " Generationen!" severity note;
                            state <= S_DONE;

                        elsif gen_ctr = max_gen then
                            report "[GA] Generationslimit. fit=" & integer'image(to_integer(unsigned(best_fit_r))) severity warning;
                            state <= S_DONE;

                        else
                            gen_ctr <= gen_ctr + 1;
                            state <= S_ELITE_WRITE;
                        end if;

                    -- --------------------------------------------------------
                    -- ELITISMUS
                    -- --------------------------------------------------------
                    when S_ELITE_WRITE =>
                        pm_wr_en <= '1';
                        pm_wr_idx <= (not ping_pong) & std_logic_vector(to_unsigned(0, IDX_W));
                        pm_wr_chr <= best_chr_r;
                        pm_wr_fit <= best_fit_r;

                        repr_ctr <= to_unsigned(1, REPR_W); -- Slot 0 = Elite
                        sel_ctr <= (others => '0');

                        for i in 0 to k*2-1 loop
                            cand_latch(i) <= cand(i); -- LFSR-Snapshot
                        end loop;
                        state <= S_SEL_READ;

                    -- --------------------------------------------------------
                    -- SELEKTION
                    -- --------------------------------------------------------
                    when S_SEL_READ =>
                        pm_rd_idx <= ping_pong & cand_latch(to_integer(sel_ctr));
                        state <= S_SEL_READ_WAIT;

                    when S_SEL_READ_WAIT =>
                        state <= S_SEL_LOAD;

                    when S_SEL_LOAD =>
                        sel_fit_we <= '1';
                        sel_fit_idx <= std_logic_vector(sel_ctr);
                        sel_fit_in <= pm_rd_fit;

                        debug_print("[SEL_LOAD] sel_ctr=" & integer'image(to_integer(sel_ctr)) & 
                                    " idx=" & integer'image(to_integer(unsigned(cand_latch(to_integer(sel_ctr))))) &
                                    " fit=" & integer'image(to_integer(unsigned(pm_rd_fit))));
                        -- if DEBUG_ENABLE then
                        --     print_sudoku(deserialize_sudoku(pm_rd_chr));
                        -- end if;

                        if sel_ctr = k*2 - 1 then
                            state <= S_SEL_START;
                        else
                            sel_ctr <= sel_ctr + 1;
                            state <= S_SEL_READ;
                        end if;

                    when S_SEL_START =>
                        sel_start <= '1';
                        state <= S_SEL_WAIT;

                    when S_SEL_WAIT =>
                        if sel_done = '1' then
                            idx_a_buf <= sel_idx_a;
                            idx_b_buf <= sel_idx_b;
                            state <= S_REPR_READ_A;
                        end if;

                    -- --------------------------------------------------------
                    -- REPRODUKTION
                    -- --------------------------------------------------------
                    when S_REPR_READ_A =>
                        pm_rd_idx <= ping_pong & idx_a_buf;
                        state <= S_REPR_READ_A_WAIT;

                    when S_REPR_READ_A_WAIT =>
                        state <= S_REPR_LOAD_A;
                        
                    when S_REPR_LOAD_A =>
                        chr_a_buf <= pm_rd_chr;
                        state <= S_REPR_READ_B;

                    when S_REPR_READ_B =>
                        pm_rd_idx <= ping_pong & idx_b_buf;
                        state <= S_REPR_READ_B_WAIT;

                    when S_REPR_READ_B_WAIT =>
                        state <= S_REPR_LOAD_B;
                        
                    when S_REPR_LOAD_B =>
                        cx_par_a <= chr_a_buf;
                        cx_par_b <= pm_rd_chr;
                        cx_start <= '1';
                        state <= S_CX_WAIT;

                    -- --------------------------------------------------------
                    -- CROSSOVER
                    -- --------------------------------------------------------
                    when S_CX_WAIT =>
                        if cx_done = '1' then
                            mut_a_start <= '1';
                            mut_b_start <= '1';
                            state <= S_MUT_WAIT;
                        end if;

                    -- --------------------------------------------------------
                    -- MUTATION
                    -- --------------------------------------------------------
                    when S_MUT_WAIT =>
                        if mut_a_done = '1' and mut_b_done = '1' then
                            state <= S_WRITE_A;
                        end if;

                    -- --------------------------------------------------------
                    -- KINDER SCHREIBEN
                    -- --------------------------------------------------------
                    when S_WRITE_A =>
                        pm_wr_en <= '1';
                        pm_wr_idx <= (not ping_pong) & std_logic_vector(repr_ctr(IDX_W-1 downto 0));
                        pm_wr_chr <= mut_a_out;
                        pm_wr_fit <= (others => '1');
                        state <= S_WRITE_B;

                    when S_WRITE_B =>
                        if repr_ctr < pop_size - 1 then
                            pm_wr_en  <= '1';
                            pm_wr_idx <= (not ping_pong) & std_logic_vector(resize(repr_ctr + 1, IDX_W));
                            pm_wr_chr <= mut_b_out;
                            pm_wr_fit <= (others => '1');
                        else
                            pm_wr_en  <= '0';
                        end if;

                        if repr_ctr >= pop_size - 2 then
                            eval_ctr <= (others => '0');
                            ping_pong <= not ping_pong;
                            state <= S_EVAL_READ;
                        else
                            repr_ctr <= repr_ctr + 2;
                            sel_ctr <= (others => '0');
                            for i in 0 to k*2-1 loop
                                cand_latch(i) <= cand(i);
                            end loop;
                            state <= S_SEL_READ;
                        end if;

                    -- --------------------------------------------------------
                    when S_DONE =>
                        done <= '1';
                        state <= S_IDLE;

                    when others =>
                        state <= S_IDLE;

                end case;
            end if;
        end if;
    end process;

end architecture;