library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_sync_fifo is
end tb_sync_fifo;

architecture sim of tb_sync_fifo is

    --------------------------------------------------------------------------
    -- Test Parameters
    --------------------------------------------------------------------------
    constant FIFO_DEPTH             : natural := 16;
    constant DATA_WIDTH             : natural := 16;
    constant ALMOST_FULL_THRESHOLD  : natural := 14;
    constant ALMOST_EMPTY_THRESHOLD : natural := 2;

    constant CLK_PERIOD : time := 10 ns;

    --------------------------------------------------------------------------
    -- DUT Signals
    --------------------------------------------------------------------------
    signal clk  : std_logic := '0';
    signal rst  : std_logic := '0';

    signal wr_en : std_logic := '0';
    signal rd_en : std_logic := '0';

    signal data_in  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others=>'0');
    signal data_out : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal full         : std_logic;
    signal almost_full  : std_logic;
    signal empty        : std_logic;
    signal almost_empty : std_logic;

begin

    --------------------------------------------------------------------------
    -- Clock Generation
    --------------------------------------------------------------------------
    clk <= not clk after CLK_PERIOD/2;

    --------------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------------
    dut : entity work.sync_fifo
    generic map
    (
        FIFO_DEPTH             => FIFO_DEPTH,
        DATA_WIDTH             => DATA_WIDTH,
        ALMOST_FULL_THRESHOLD  => ALMOST_FULL_THRESHOLD,
        ALMOST_EMPTY_THRESHOLD => ALMOST_EMPTY_THRESHOLD
    )
    port map
    (
        clk            => clk,
        rst            => rst,

        wr_en          => wr_en,
        rd_en          => rd_en,

        data_in        => data_in,

        full           => full,
        almost_full    => almost_full,
        empty          => empty,
        almost_empty   => almost_empty,

        data_out       => data_out
    );

    --------------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------------
    stim_proc : process

        ----------------------------------------------------------------------
        -- FIFO WRITE
        ----------------------------------------------------------------------
        procedure fifo_write
        (
            constant wr_data : in std_logic_vector(DATA_WIDTH-1 downto 0)
        ) is
        begin

            data_in <= wr_data;
            wr_en   <= '1';

            wait until rising_edge(clk);
            wait for 1 ns;

            wr_en <= '0';

        end procedure;

        ----------------------------------------------------------------------
        -- FIFO READ
        ----------------------------------------------------------------------
        procedure fifo_read
        (
            constant expected_data : in std_logic_vector(DATA_WIDTH-1 downto 0)
        ) is
        begin

            rd_en <= '1';

            wait until rising_edge(clk);
            wait for 1 ns;

            rd_en <= '0';

            assert data_out = expected_data
            report "FIFO Read FAILED"
            severity error;

        end procedure;

        ----------------------------------------------------------------------
        -- FLAG CHECK
        ----------------------------------------------------------------------
        procedure check_flags
        (
            constant exp_full         : in std_logic;
            constant exp_empty        : in std_logic;
            constant exp_almost_full  : in std_logic;
            constant exp_almost_empty : in std_logic
        ) is
        begin

            assert full = exp_full
            report "FULL flag mismatch"
            severity error;

            assert empty = exp_empty
            report "EMPTY flag mismatch"
            severity error;

            assert almost_full = exp_almost_full
            report "ALMOST_FULL flag mismatch"
            severity error;

            assert almost_empty = exp_almost_empty
            report "ALMOST_EMPTY flag mismatch"
            severity error;

        end procedure;

    begin

        ----------------------------------------------------------------------
        -- RESET
        ----------------------------------------------------------------------
        report "--------------------------------------";
        report "TEST : RESET";
        report "--------------------------------------";

        rst <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        rst <= '0';

        check_flags
        (
            exp_full         => '0',
            exp_empty        => '1',
            exp_almost_full  => '0',
            exp_almost_empty => '1'
        );

        report "Reset PASSED";

        ----------------------------------------------------------------------
        -- SINGLE WRITE
        ----------------------------------------------------------------------
        report "--------------------------------------";
        report "TEST : SINGLE WRITE";
        report "--------------------------------------";

        fifo_write(x"1234");

        check_flags
        (
            exp_full         => '0',
            exp_empty        => '0',
            exp_almost_full  => '0',
            exp_almost_empty => '1'
        );

        report "Single Write PASSED";

        ----------------------------------------------------------------------
        -- SINGLE READ
        ----------------------------------------------------------------------
        report "--------------------------------------";
        report "TEST : SINGLE READ";
        report "--------------------------------------";

        fifo_read(x"1234");

        check_flags
        (
            exp_full         => '0',
            exp_empty        => '1',
            exp_almost_full  => '0',
            exp_almost_empty => '1'
        );

        report "Single Read PASSED";

        report "======================================";
        report "PART 1 COMPLETED SUCCESSFULLY";
        report "======================================";

        
        ----------------------------------------------------------------------
        -- FILL FIFO
        ----------------------------------------------------------------------
        report "--------------------------------------";
        report "TEST : FILL FIFO";
        report "--------------------------------------";

        for i in 0 to FIFO_DEPTH-1 loop

            fifo_write(std_logic_vector(to_unsigned(i, DATA_WIDTH)));

        end loop;

        check_flags
        (
            exp_full         => '1',
            exp_empty        => '0',
            exp_almost_full  => '1',
            exp_almost_empty => '0'
        );

        report "Fill FIFO PASSED";
        
                ----------------------------------------------------------------------
        -- OVERFLOW PROTECTION
        ----------------------------------------------------------------------
        report "--------------------------------------";
        report "TEST : OVERFLOW";
        report "--------------------------------------";

        fifo_write(x"AAAA");

        check_flags
        (
            exp_full         => '1',
            exp_empty        => '0',
            exp_almost_full  => '1',
            exp_almost_empty => '0'
        );

        report "Overflow Protection PASSED";
        ----------------------------------------------------------------------
        -- EMPTY FIFO
        ----------------------------------------------------------------------
        report "--------------------------------------";
        report "TEST : EMPTY FIFO";
        report "--------------------------------------";

        for i in 0 to FIFO_DEPTH-1 loop

            fifo_read(std_logic_vector(to_unsigned(i, DATA_WIDTH)));

        end loop;

        check_flags
        (
            exp_full         => '0',
            exp_empty        => '1',
            exp_almost_full  => '0',
            exp_almost_empty => '1'
        );

        report "Empty FIFO PASSED";
        ----------------------------------------------------------------------
        -- UNDERFLOW PROTECTION
        ----------------------------------------------------------------------
        report "--------------------------------------";
        report "TEST : UNDERFLOW";
        report "--------------------------------------";

        rd_en <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        rd_en <= '0';

        check_flags
        (
            exp_full         => '0',
            exp_empty        => '1',
            exp_almost_full  => '0',
            exp_almost_empty => '1'
        );

        report "Underflow Protection PASSED";
        fifo_write(x"1111");
        ----------------------------------------------------------------------
        -- SIMULTANEOUS READ / WRITE
        ----------------------------------------------------------------------
        report "--------------------------------------";
        report "TEST : SIMULTANEOUS READ / WRITE";
        report "--------------------------------------";

        data_in <= x"2222";

        wr_en <= '1';
        rd_en <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        wr_en <= '0';
        rd_en <= '0';

        assert data_out = x"1111"
        report "Simultaneous Read/Write FAILED"
        severity error;

        report "Simultaneous Read/Write PASSED";
      
     wait;
    end process;

end sim;