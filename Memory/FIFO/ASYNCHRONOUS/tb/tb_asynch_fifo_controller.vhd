library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.basic_package.ALL;

entity tb_async_fifo_controller is
end tb_async_fifo_controller;

architecture sim of tb_async_fifo_controller is

    --------------------------------------------------------------------------
    -- Test Configuration
    --------------------------------------------------------------------------
    constant FIFO_DEPTH : natural := 16;
    constant ALMOST_FULL_THRESHOLD : natural := 14;
    constant ALMOST_EMPTY_THRESHOLD : natural := 2;
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

    signal full          : std_logic;
    signal almost_full   : std_logic;
    signal empty         : std_logic;
    signal almost_empty  : std_logic;

    signal mem_wr : std_logic;
    signal mem_rd : std_logic;

    signal wr_ptr : std_logic_vector(clog2(FIFO_DEPTH)-1 downto 0);
    signal rd_ptr : std_logic_vector(clog2(FIFO_DEPTH)-1 downto 0);
    signal fifo_count_wr : integer := 0;
    signal fifo_count_rd : integer := 0;
    signal fifo_count: integer := 0;
begin

    --------------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------------
    dut : entity work.async_fifo_controller
    generic map
    (
        FIFO_DEPTH => FIFO_DEPTH,
        ALMOST_FULL_THRESHOLD => ALMOST_FULL_THRESHOLD,
        ALMOST_EMPTY_THRESHOLD => ALMOST_EMPTY_THRESHOLD
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

        full => full,
        almost_full => almost_full,

        empty => empty,
        almost_empty => almost_empty,

        mem_wr => mem_wr,
        mem_rd => mem_rd,

        wr_ptr => wr_ptr,
        rd_ptr => rd_ptr
    );

    --------------------------------------------------------------------------
    -- Clock Generation
    --------------------------------------------------------------------------
    clk_wr <= not clk_wr after WR_CLK_PERIOD/2;
    clk_rd <= not clk_rd after RD_CLK_PERIOD/2;
    
    fifo_count <= fifo_count_wr + fifo_count_rd;
    --------------------------------------------------------------------------
    fifo_count_wr_proc: process
    begin
        wait until rising_edge(clk_wr);
        wait for 1 ns;
         if mem_wr = '1' then
            fifo_count_wr <= fifo_count_wr + 1;
         end if;
         wait until rising_edge(clk_wr);
    
    end process fifo_count_wr_proc;
    
    
    fifo_count_rd_proc: process
    begin
         wait until rising_edge(clk_rd);
         if mem_rd = '1' then
            fifo_count_rd <= fifo_count_rd - 1;
         end if;
--         wait until rising_edge(clk_rd);
    end process fifo_count_rd_proc;

    --------------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------------
    stim_proc : process
    variable wr_ptr_before : std_logic_vector(wr_ptr'range);
    variable rd_ptr_before : std_logic_vector(rd_ptr'range);
    begin

        report "===================================";
        report "TEST 1 : RESET";
        report "===================================";

        ----------------------------------------------------------------------
        -- Apply reset
        ----------------------------------------------------------------------
        rst_wr <= '1';
        rst_rd <= '1';

        wait for 50 ns;

        rst_wr <= '0';
        rst_rd <= '0';

        ----------------------------------------------------------------------
        -- Wait for both clock domains
        ----------------------------------------------------------------------
        wait until rising_edge(clk_wr);
        wait until rising_edge(clk_rd);

        wait for 1 ns;

        ----------------------------------------------------------------------
        -- Check outputs after reset
        ----------------------------------------------------------------------
        assert wr_ptr = (wr_ptr'range => '0')
        report "Write Pointer Reset Failed"
        severity error;

        assert rd_ptr = (rd_ptr'range => '0')
        report "Read Pointer Reset Failed"
        severity error;

        assert empty = '1'
        report "EMPTY flag should be HIGH after reset"
        severity error;

        assert full = '0'
        report "FULL flag should be LOW after reset"
        severity error;

        report "RESET TEST PASSED";
                ----------------------------------------------------------------------
        -- SINGLE WRITE
        ----------------------------------------------------------------------

        report "===================================";
        report "TEST 2 : SINGLE WRITE";
        report "===================================";

        wr_en <= '1';

        ----------------------------------------------------------------------
        -- Write occurs on write clock
        ----------------------------------------------------------------------
        

        wait for 1 ns;

        ----------------------------------------------------------------------
        -- Write request should be accepted
        ----------------------------------------------------------------------
        assert mem_wr = '1'
        report "Memory Write Enable Failed"
        severity error;
        wait until rising_edge(clk_wr);
        wait for 1 ns;
        assert unsigned(wr_ptr) = 1
        report "Write Pointer Increment Failed"
        severity error;

        wr_en <= '0';

        report "SINGLE WRITE PASSED";

        ----------------------------------------------------------------------
        -- Allow write pointer to synchronize into read clock domain.
        ----------------------------------------------------------------------
        wait for 50 ns;

        ----------------------------------------------------------------------
        -- SINGLE READ
        ----------------------------------------------------------------------

        report "===================================";
        report "TEST 3 : SINGLE READ";
        report "===================================";

        rd_en <= '1';

        wait for 1 ns;
        
        assert mem_rd='1'
        report "Memory Read Enable Failed"
        severity error;
        
        wait until rising_edge(clk_rd);
        
        wait for 1 ns;
        
        assert unsigned(rd_ptr)=1
        report "Read Pointer Increment Failed"
        severity error;
        
        rd_en <= '0';

        report "SINGLE READ PASSED";
        
                ----------------------------------------------------------------------
        -- FIFO FULL TEST
        ----------------------------------------------------------------------

        report "===================================";
        report "TEST 4 : FIFO FULL";
        report "===================================";

        ----------------------------------------------------------------------
        -- Fill FIFO.
        ----------------------------------------------------------------------
        
        for i in 1 to FIFO_DEPTH loop

            wr_en <= '1';

            ------------------------------------------------------------------
            -- Before the write clock, write should be allowed.
            ------------------------------------------------------------------
            wait for 1 ns;

            assert mem_wr = '1'
            report "Memory Write Enable Failed"
            severity error;

            wait until rising_edge(clk_wr);
            if fifo_count = ALMOST_FULL_THRESHOLD - 1 then
                assert almost_full = '1'
                report "FIFO almost Full Failed"
                severity error;
                report "FIFO ALMOST FULL TEST PASSED";
            end if;
            wait for 1 ns;

            wr_en <= '0';

            wait until rising_edge(clk_wr);

        end loop;
        
        ----------------------------------------------------------------------
        -- FIFO should now report FULL.
        ----------------------------------------------------------------------
        assert full = '1'
        report "FIFO FULL flag failed"
        severity error;

        report "FIFO FULL TEST PASSED";
        report "===================================";
        report "TEST 6 : OVERFLOW";
        report "===================================";
        wr_en <= '1';
        
        wait for 1 ns;
        
        assert mem_wr = '0'
        report "Write should be blocked when FIFO is FULL"
        severity error;
        wr_ptr_before := wr_ptr;
        wait until rising_edge(clk_wr);
        
        wait for 1 ns;
        
        assert full = '1'
        report "FULL flag unexpectedly cleared"
        severity error;
        
        assert wr_ptr_before = wr_ptr
        report "Write pointer changed during overflow"
        severity error;
        
        wr_en <= '0';
        
        report "OVERFLOW TEST PASSED";
                ----------------------------------------------------------------------
        -- FIFO EMPTY TEST
        ----------------------------------------------------------------------

        report "===================================";
        report "TEST 5 : FIFO EMPTY";
        report "===================================";

        ----------------------------------------------------------------------
        -- Read entire FIFO.
        ----------------------------------------------------------------------
        while empty = '0' loop

            rd_en <= '1';

            ------------------------------------------------------------------
            -- Read should be allowed.
            ------------------------------------------------------------------
            wait for 1 ns;

            assert mem_rd = '1'
            report "Memory Read Enable Failed"
            severity error;

            ------------------------------------------------------------------
            -- Perform read.
            ------------------------------------------------------------------
            wait until rising_edge(clk_rd);
            if fifo_count = ALMOST_EMPTY_THRESHOLD - 1 then
                assert almost_empty = '1'
                report "FIFO almost Empty Failed"
                severity error;
                report "FIFO ALMOST EMPTY TEST PASSED";
            end if;
            wait for 1 ns;

            rd_en <= '0';

            ------------------------------------------------------------------
            -- Give one read clock before next read.
            ------------------------------------------------------------------
            wait until rising_edge(clk_rd);

        end loop;

        ----------------------------------------------------------------------
        -- FIFO should now be empty.
        ----------------------------------------------------------------------
        assert empty = '1'
        report "FIFO EMPTY flag failed"
        severity error;

        ----------------------------------------------------------------------
        -- Read pointer should equal write pointer.
        ----------------------------------------------------------------------
        assert rd_ptr = wr_ptr
        report "Read and Write pointers are not equal."
        severity error;

        report "FIFO EMPTY TEST PASSED";
        
       
        ----------------------------------------------------------------------
        -- Under flow test
        ----------------------------------------------------------------------
        rd_ptr_before := rd_ptr;

        rd_en <= '1';
        
        wait for 1 ns;
        
        assert mem_rd='0';
        
        wait until rising_edge(clk_rd);
        
        assert rd_ptr = rd_ptr_before;
        report "Write pointer changed during overflow"
        severity error;
        
        rd_en <= '0';
        
        report "UNDERFLOW TEST PASSED";
        ----------------------------------------------------------------------
        -- Global WR Enable test
        ----------------------------------------------------------------------
        wr_domain_en <= '0';
    
        wr_en <= '1';
        
        wait for 1 ns;
       
        assert mem_wr = '0'
        report "Write should be disabled when wr_domain_en = 0"
        severity error;
        report "WR GLOBAL ENABLE TEST PASSED";
        wait until rising_edge(clk_wr);
        
        assert wr_ptr = wr_ptr_before
        report "Write pointer changed while write domain disabled"
        severity error;
        report "DURING WR GLOBAL TEST WR PTR NOT CHANGED PASSED";
        
         ----------------------------------------------------------------------
        -- Global WR Enable test
        ----------------------------------------------------------------------
        rd_domain_en <= '0';
    
        rd_en <= '1';
        
        wait for 1 ns;
       
        assert mem_rd = '0'
        report "Read should be disabled when rd_domain_en = 0"
        severity error;
        report "RD GLOBAL ENABLE TEST PASSED";
        wait until rising_edge(clk_rd);
        
        assert rd_ptr = rd_ptr_before
        report "Read pointer changed while read domain disabled"
        severity error;
        report "DURING RD GLOBAL TEST RD PTR NOT CHANGED PASSED";
        wait;
    end process;

end sim;