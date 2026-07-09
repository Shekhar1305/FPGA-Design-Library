library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.basic_package.all;

entity tb_fifo_memory is
end tb_fifo_memory;

architecture sim of tb_fifo_memory is

    --------------------------------------------------------------------------
    -- Test Parameters
    --------------------------------------------------------------------------
    constant FIFO_DEPTH : natural := 16;
    constant DATA_WIDTH : natural := 16;

    --------------------------------------------------------------------------
    -- DUT Signals
    --------------------------------------------------------------------------
    signal clk      : std_logic := '0';

    signal wr_en    : std_logic := '0';
    signal rd_en    : std_logic := '0';

    signal wr_addr  : std_logic_vector(clog2(FIFO_DEPTH)-1 downto 0) := (others=>'0');
    signal rd_addr  : std_logic_vector(clog2(FIFO_DEPTH)-1 downto 0) := (others=>'0');

    signal data_in  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others=>'0');
    signal data_out : std_logic_vector(DATA_WIDTH-1 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    --------------------------------------------------------------------------
    -- Clock Generation
    --------------------------------------------------------------------------
    clk <= not clk after CLK_PERIOD/2;

    --------------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------------
    dut : entity work.fifo_memory
    generic map
    (
        FIFO_DEPTH => FIFO_DEPTH,
        DATA_WIDTH => DATA_WIDTH
    )
    port map
    (
        clk      => clk,
        wr_en    => wr_en,
        rd_en    => rd_en,
        wr_addr  => wr_addr,
        rd_addr  => rd_addr,
        data_in  => data_in,
        data_out => data_out
    );

    --------------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------------
    stim_proc : process

        variable expected : std_logic_vector(DATA_WIDTH-1 downto 0);

    begin

        ----------------------------------------------------------------------
        -- SINGLE WRITE
        ----------------------------------------------------------------------
        wr_addr <= std_logic_vector(to_unsigned(3, wr_addr'length));
        data_in <= x"1234";
        wr_en   <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        wr_en <= '0';

        report "Single Write PASSED";

        ----------------------------------------------------------------------
        -- SINGLE READ
        ----------------------------------------------------------------------
        rd_addr <= std_logic_vector(to_unsigned(3, rd_addr'length));
        rd_en   <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert data_out = x"1234"
        report "Single Read FAILED"
        severity error;

        rd_en <= '0';

        report "Single Read PASSED";

        ----------------------------------------------------------------------
        -- FILL ENTIRE MEMORY
        ----------------------------------------------------------------------
        wr_en <= '1';

        for i in 0 to FIFO_DEPTH-1 loop

            wr_addr <= std_logic_vector(to_unsigned(i, wr_addr'length));
            data_in <= std_logic_vector(to_unsigned(i + 100, DATA_WIDTH));

            wait until rising_edge(clk);

        end loop;

        wait for 1 ns;

        wr_en <= '0';

        report "Memory Fill PASSED";

        ----------------------------------------------------------------------
        -- READ ENTIRE MEMORY
        ----------------------------------------------------------------------
        rd_en <= '1';

        for i in 0 to FIFO_DEPTH-1 loop

            rd_addr <= std_logic_vector(to_unsigned(i, rd_addr'length));

            wait until rising_edge(clk);
            wait for 1 ns;

            expected := std_logic_vector(to_unsigned(i + 100, DATA_WIDTH));

            assert data_out = expected
            report "Memory Read FAILED at address "
            & integer'image(i)
            severity error;

        end loop;

        rd_en <= '0';

        report "Memory Read PASSED";

        ----------------------------------------------------------------------
        -- OVERWRITE TEST
        ----------------------------------------------------------------------
        wr_addr <= std_logic_vector(to_unsigned(5, wr_addr'length));
        data_in <= x"AAAA";
        wr_en   <= '1';

        wait until rising_edge(clk);

        wr_en <= '0';

        rd_addr <= std_logic_vector(to_unsigned(5, rd_addr'length));
        rd_en   <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert data_out = x"AAAA"
        report "Overwrite FAILED"
        severity error;

        rd_en <= '0';

        report "Overwrite PASSED";

        ----------------------------------------------------------------------
        -- READ-FIRST TEST
        ----------------------------------------------------------------------
        -- Address 7 currently contains 107.
        -- Simultaneous read and write should return OLD DATA.
        ----------------------------------------------------------------------

        wr_addr <= std_logic_vector(to_unsigned(7, wr_addr'length));
        rd_addr <= std_logic_vector(to_unsigned(7, rd_addr'length));

        data_in <= x"5555";

        wr_en <= '1';
        rd_en <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        assert data_out = std_logic_vector(to_unsigned(107, DATA_WIDTH))
        report "Read-First FAILED"
        severity error;

        wr_en <= '0';

        ----------------------------------------------------------------------
        -- VERIFY UPDATED VALUE
        ----------------------------------------------------------------------
        wait until rising_edge(clk);
        wait for 1 ns;

        assert data_out = x"5555"
        report "Updated Value FAILED"
        severity error;

        rd_en <= '0';

        report "Read-First PASSED";

        ----------------------------------------------------------------------
        -- HOLD OUTPUT TEST
        ----------------------------------------------------------------------
        -- When RD_EN is deasserted, DATA_OUT must retain its last value.
        ----------------------------------------------------------------------

        rd_en <= '0';

        rd_addr <= std_logic_vector(to_unsigned(2, rd_addr'length));

        wait until rising_edge(clk);
        wait for 1 ns;

        assert data_out = x"5555"
        report "Output Hold FAILED"
        severity error;

        report "Output Hold PASSED";

        ----------------------------------------------------------------------
        report "======================================";
        report " ALL FIFO MEMORY TESTS PASSED ";
        report "======================================";

        wait;

    end process;

end sim;