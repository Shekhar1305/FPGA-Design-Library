library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.basic_package.ALL;

entity tb_async_fifo is
end tb_async_fifo;

architecture sim of tb_async_fifo is

    --------------------------------------------------------------------------
    -- Test Configuration
    --------------------------------------------------------------------------
    constant FIFO_DEPTH : natural := 16;
    constant ALMOST_FULL_THRESHOLD : natural := 14;
    constant ALMOST_EMPTY_THRESHOLD : natural := 2;
    constant DATA_WIDTH : natural := 16;

    constant WR_CLK_PERIOD : time := 10 ns;
    constant RD_CLK_PERIOD : time := 17 ns;

    --------------------------------------------------------------------------
    -- DUT Signals
    --------------------------------------------------------------------------
    signal clk_wr : std_logic := '0';
    signal clk_rd : std_logic := '0';

    signal rst_wr : std_logic := '0';
    signal rst_rd : std_logic := '0';

    signal wr_domain_en : std_logic := '1';
    signal rd_domain_en : std_logic := '1';

    signal wr_en : std_logic := '0';
    signal rd_en : std_logic := '0';

    signal data_in  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal data_out : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal full         : std_logic;
    signal almost_full  : std_logic;
    signal empty        : std_logic;
    signal almost_empty : std_logic;

begin

    --------------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------------
    dut : entity work.async_fifo
        generic map
        (
            FIFO_DEPTH => FIFO_DEPTH,
            DATA_WIDTH => DATA_WIDTH
        )
        port map
        (
            clk_wr => clk_wr,
            rst_wr => rst_wr,

            clk_rd => clk_rd,
            rst_rd => rst_rd,

            wr_domain_en => wr_domain_en,
            rd_domain_en => rd_domain_en,

            wr_en => wr_en,
            rd_en => rd_en,

            data_in => data_in,
            data_out => data_out,

            full => full,
            almost_full => almost_full,

            empty => empty,
            almost_empty => almost_empty
        );

    --------------------------------------------------------------------------
    -- Clock Generation
    --------------------------------------------------------------------------
    clk_wr <= not clk_wr after WR_CLK_PERIOD/2;
    clk_rd <= not clk_rd after RD_CLK_PERIOD/2;

    --------------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------------
    stim_proc : process
    begin

        ----------------------------------------------------------------------
        -- RESET TEST
        ----------------------------------------------------------------------
        report "===================================";
        report "TEST 1 : RESET";
        report "===================================";

        rst_wr <= '1';
        rst_rd <= '1';

        wait for 50 ns;

        rst_wr <= '0';
        rst_rd <= '0';

        wait until rising_edge(clk_wr);
        wait until rising_edge(clk_rd);

        wait for 1 ns;

        assert empty = '1'
        report "FIFO should be EMPTY after reset."
        severity error;

        assert full = '0'
        report "FIFO should not be FULL after reset."
        severity error;

        report "RESET TEST PASSED";

        ----------------------------------------------------------------------
        -- SINGLE WRITE
        ----------------------------------------------------------------------
        report "===================================";
        report "TEST 2 : SINGLE WRITE";
        report "===================================";

        data_in <= x"1234";

        wr_en <= '1';

        wait until rising_edge(clk_wr);

        wait for 1 ns;

        wr_en <= '0';

        ----------------------------------------------------------------------
        -- Allow pointer synchronization.
        ----------------------------------------------------------------------
        wait for 50 ns;

        assert empty = '0'
        report "FIFO should not be EMPTY after one write."
        severity error;

        report "SINGLE WRITE PASSED";

        ----------------------------------------------------------------------
        -- SINGLE READ
        ----------------------------------------------------------------------
        report "===================================";
        report "TEST 3 : SINGLE READ";
        report "===================================";

        rd_en <= '1';

        wait until rising_edge(clk_rd);

        wait for 1 ns;

        rd_en <= '0';

        ----------------------------------------------------------------------
        -- Data should now be available.
        ----------------------------------------------------------------------
        assert data_out = x"1234"
        report "Read Data Mismatch."
        severity error;

        ----------------------------------------------------------------------
        -- Allow synchronization back into write domain.
        ----------------------------------------------------------------------
        wait for 50 ns;

        assert empty = '1'
        report "FIFO should be EMPTY after reading the only entry."
        severity error;

        report "SINGLE READ PASSED";

        ----------------------------------------------------------------------
        -- END SIMULATION
        ----------------------------------------------------------------------
        report "===================================";
        report "PART 1 COMPLETED";
        report "===================================";

                ----------------------------------------------------------------------
        -- MULTIPLE WRITE / READ
        ----------------------------------------------------------------------
        report "===================================";
        report "TEST 4 : MULTIPLE WRITE / READ";
        report "===================================";

        ----------------------------------------------------------------------
        -- Write three data words.
        ----------------------------------------------------------------------

        data_in <= x"1111";
        wr_en <= '1';
        wait until rising_edge(clk_wr);
        wait for 1 ns;
        wr_en <= '0';

        wait until rising_edge(clk_wr);

        data_in <= x"2222";
        wr_en <= '1';
        wait until rising_edge(clk_wr);
        wait for 1 ns;
        wr_en <= '0';

        wait until rising_edge(clk_wr);

        data_in <= x"3333";
        wr_en <= '1';
        wait until rising_edge(clk_wr);
        wait for 1 ns;
        wr_en <= '0';

        ----------------------------------------------------------------------
        -- Allow pointer synchronization.
        ----------------------------------------------------------------------
        wait for 50 ns;

        assert empty = '0'
        report "FIFO should not be EMPTY after multiple writes."
        severity error;

        ----------------------------------------------------------------------
        -- Read first word.
        ----------------------------------------------------------------------
        rd_en <= '1';

        wait until rising_edge(clk_rd);
        wait for 1 ns;

        rd_en <= '0';

        assert data_out = x"1111"
        report "First FIFO data mismatch."
        severity error;

        wait until rising_edge(clk_rd);

        ----------------------------------------------------------------------
        -- Read second word.
        ----------------------------------------------------------------------
        rd_en <= '1';

        wait until rising_edge(clk_rd);
        wait for 1 ns;

        rd_en <= '0';

        assert data_out = x"2222"
        report "Second FIFO data mismatch."
        severity error;

        wait until rising_edge(clk_rd);

        ----------------------------------------------------------------------
        -- Read third word.
        ----------------------------------------------------------------------
        rd_en <= '1';

        wait until rising_edge(clk_rd);
        wait for 1 ns;

        rd_en <= '0';

        assert data_out = x"3333"
        report "Third FIFO data mismatch."
        severity error;

        ----------------------------------------------------------------------
        -- Allow EMPTY flag to synchronize.
        ----------------------------------------------------------------------
        wait for 50 ns;

        assert empty = '1'
        report "FIFO should be EMPTY after reading all entries."
        severity error;

        report "MULTIPLE WRITE / READ PASSED";
    
                ----------------------------------------------------------------------
        -- FIFO FULL / EMPTY TEST
        ----------------------------------------------------------------------
        report "===================================";
        report "TEST 5 : FIFO FULL / EMPTY";
        report "===================================";

        ----------------------------------------------------------------------
        -- Fill FIFO completely.
        ----------------------------------------------------------------------
        for i in 0 to FIFO_DEPTH-1 loop

            data_in <= std_logic_vector(to_unsigned(i, DATA_WIDTH));

            wr_en <= '1';

            wait until rising_edge(clk_wr);
            wait for 1 ns;

            wr_en <= '0';

            ------------------------------------------------------------------
            -- Check Almost Full threshold.
            ------------------------------------------------------------------
            if (i + 1) = ALMOST_FULL_THRESHOLD then

                wait for 20 ns;

                assert almost_full = '1'
                report "Almost Full Flag Failed"
                severity error;

            end if;

            wait until rising_edge(clk_wr);

        end loop;

        ----------------------------------------------------------------------
        -- Allow FULL flag to propagate through CDC.
        ----------------------------------------------------------------------
        wait for 100 ns;

        assert full = '1'
        report "FIFO FULL Flag Failed"
        severity error;

        report "FIFO FULL PASSED";

        ----------------------------------------------------------------------
        -- Read entire FIFO.
        ----------------------------------------------------------------------
        for j in 0 to FIFO_DEPTH-1 loop

            rd_en <= '1';

            wait until rising_edge(clk_rd);
            wait for 1 ns;

            rd_en <= '0';

            ------------------------------------------------------------------
            -- Verify FIFO ordering.
            ------------------------------------------------------------------
            assert data_out = std_logic_vector(to_unsigned(j, DATA_WIDTH))
            report "FIFO Data Order Failed"
            severity error;

            ------------------------------------------------------------------
            -- Check Almost Empty threshold.
            ------------------------------------------------------------------
            if (FIFO_DEPTH - (j + 1)) = ALMOST_EMPTY_THRESHOLD then

                wait for 20 ns;

                assert almost_empty = '1'
                report "Almost Empty Flag Failed"
                severity error;

            end if;

            wait until rising_edge(clk_rd);

        end loop;

        ----------------------------------------------------------------------
        -- Allow EMPTY flag to synchronize.
        ----------------------------------------------------------------------
        wait for 100 ns;

        assert empty = '1'
        report "FIFO EMPTY Flag Failed"
        severity error;

        report "FIFO EMPTY PASSED";
        
        
        wait;

    end process;

end sim;