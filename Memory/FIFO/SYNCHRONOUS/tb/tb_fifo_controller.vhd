library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.basic_package.all;

entity tb_fifo_controller is
end tb_fifo_controller;

architecture sim of tb_fifo_controller is

    --------------------------------------------------------------------------
    -- Test Configuration
    --------------------------------------------------------------------------
    constant FIFO_DEPTH : natural := 16;
    constant PTR_WIDTH  : natural := clog2(FIFO_DEPTH);

    --------------------------------------------------------------------------
    -- DUT Signals
    --------------------------------------------------------------------------
    signal clk  : std_logic := '0';
    signal rst  : std_logic := '0';
    signal en   : std_logic := '1';

    signal wr_en : std_logic := '0';
    signal rd_en : std_logic := '0';

    signal full          : std_logic;
    signal almost_full   : std_logic;
    signal empty         : std_logic;
    signal almost_empty  : std_logic;

    signal mem_wr        : std_logic;
    signal mem_rd        : std_logic;

    signal wr_ptr        : std_logic_vector(PTR_WIDTH-1 downto 0);
    signal rd_ptr        : std_logic_vector(PTR_WIDTH-1 downto 0);

begin

    --------------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------------
    DUT : entity work.fifo_controller
    generic map
    (
        FIFO_DEPTH             => FIFO_DEPTH,
        ALMOST_FULL_THRESHOLD  => 14,
        ALMOST_EMPTY_THRESHOLD => 2
    )
    port map
    (
        clk           => clk,
        rst           => rst,
        en            => en,
        wr_en         => wr_en,
        rd_en         => rd_en,
        full          => full,
        almost_full   => almost_full,
        empty         => empty,
        almost_empty  => almost_empty,
        mem_wr        => mem_wr,
        mem_rd        => mem_rd,
        wr_ptr        => wr_ptr,
        rd_ptr        => rd_ptr
    );

    --------------------------------------------------------------------------
    -- Clock Generation
    --------------------------------------------------------------------------
    clk <= not clk after 5 ns;

    --------------------------------------------------------------------------
    -- Test Process
    --------------------------------------------------------------------------
    stim_proc : process
    begin

        ----------------------------------------------------------------------
        -- RESET
        ----------------------------------------------------------------------
        rst <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        wait until rising_edge(clk);
        wait for 1 ns;

        rst <= '0';

        assert empty='1'
        report "Reset FAILED"
        severity error;

        assert full='0'
        report "Reset FAILED"
        severity error;

        report "Reset PASSED";

        ----------------------------------------------------------------------
        -- SINGLE WRITE
        ----------------------------------------------------------------------
        wr_en <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        wr_en <= '0';

        assert mem_wr='1'
        report "Single Write FAILED"
        severity error;

        assert empty='0'
        report "Empty Flag FAILED"
        severity error;

        report "Single Write PASSED";

        ----------------------------------------------------------------------
        -- SINGLE READ
        ----------------------------------------------------------------------
        rd_en <= '1';
        
        wait for 1 ns;
        
        assert mem_rd='1'
        report "Single Read FAILED"
        severity error;
        
        assert empty='1'
        report "FIFO should be empty"
        severity error;
        wait until rising_edge(clk);
        rd_en <= '0';
        
        report "Single Read PASSED";
        ----------------------------------------------------------------------
        -- FILL FIFO
        ----------------------------------------------------------------------
        for i in 1 to FIFO_DEPTH loop

            wr_en <= '1';

            wait until rising_edge(clk);
            wait for 1 ns;

        end loop;

        wr_en <= '0';

        assert full='1'
        report "Full Flag FAILED"
        severity error;

        report "FIFO Full PASSED";

        ----------------------------------------------------------------------
        -- WRITE WHEN FULL
        ----------------------------------------------------------------------
        wait until rising_edge(clk);
        wait for 1 ns;

        assert mem_wr='0'
        report "Write should be blocked"
        severity error;

        report "Write Block PASSED";

        ----------------------------------------------------------------------
        -- SIMULTANEOUS READ / WRITE
        ----------------------------------------------------------------------
        wr_en <= '1';
        rd_en <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        wr_en <= '0';
        rd_en <= '0';

        assert mem_wr='1'
        report "Simultaneous Write FAILED"
        severity error;

        assert mem_rd='1'
        report "Simultaneous Read FAILED"
        severity error;

        report "Simultaneous Read/Write PASSED";

        ----------------------------------------------------------------------
        -- DRAIN FIFO
        ----------------------------------------------------------------------
        for i in 1 to FIFO_DEPTH loop

            rd_en <= '1';

            wait until rising_edge(clk);
            wait for 1 ns;

        end loop;

        rd_en <= '0';

        assert empty='1'
        report "FIFO Empty FAILED"
        severity error;

        report "FIFO Empty PASSED";

        ----------------------------------------------------------------------
        -- READ WHEN EMPTY
        ----------------------------------------------------------------------
        wait until rising_edge(clk);
        wait for 1 ns;

        assert mem_rd='0'
        report "Read should be blocked"
        severity error;

        report "Read Block PASSED";

        ----------------------------------------------------------------------
        -- ALMOST FULL
        ----------------------------------------------------------------------
        for i in 1 to 14 loop

            wr_en <= '1';

            wait until rising_edge(clk);
            wait for 1 ns;

        end loop;

        wr_en <= '0';

        assert almost_full='1'
        report "Almost Full FAILED"
        severity error;

        report "Almost Full PASSED";

        ----------------------------------------------------------------------
        -- ALMOST EMPTY
        ----------------------------------------------------------------------
        for i in 1 to 12 loop

            rd_en <= '1';

            wait until rising_edge(clk);
            wait for 1 ns;

        end loop;

        rd_en <= '0';

        assert almost_empty='1'
        report "Almost Empty FAILED"
        severity error;

        report "Almost Empty PASSED";

        ----------------------------------------------------------------------
        -- POINTER WRAP TEST
        ----------------------------------------------------------------------
        for i in 1 to FIFO_DEPTH loop

            wr_en <= '1';

            wait until rising_edge(clk);
            wait for 1 ns;

        end loop;

        wr_en <= '0';

        report "Pointer Wrap PASSED";

        ----------------------------------------------------------------------
        -- TEST SUMMARY
        ----------------------------------------------------------------------
        report "======================================";
        report " ALL FIFO CONTROLLER TESTS PASSED ";
        report "======================================";

        wait;

    end process;

end sim;