library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_universal_shift_reg is
end tb_universal_shift_reg;

architecture sim of tb_universal_shift_reg is

    --------------------------------------------------------------------------
    -- Constants
    --------------------------------------------------------------------------
    constant WIDTH : natural := 4;

    --------------------------------------------------------------------------
    -- DUT Signals
    --------------------------------------------------------------------------
    signal clk  : std_logic := '0';
    signal rst  : std_logic := '0';
    signal en   : std_logic := '0';

    signal ctrl : std_logic_vector(1 downto 0);
    signal d    : std_logic_vector(WIDTH-1 downto 0);

    signal q    : std_logic_vector(WIDTH-1 downto 0);

begin

    --------------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------------
    DUT : entity work.universal_shift_reg
    generic map
    (
        WIDTH => WIDTH
    )
    port map
    (
        clk  => clk,
        rst  => rst,
        en   => en,
        ctrl => ctrl,
        d    => d,
        q    => q
    );

    --------------------------------------------------------------------------
    -- Clock Generation (100 MHz)
    --------------------------------------------------------------------------
    clk <= not clk after 5 ns;

    --------------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------------
    stim_proc : process

        procedure wait_clocks(
            constant N : natural
        ) is
        begin
            for i in 1 to N loop
                wait until rising_edge(clk);
                wait for 1 ns;
            end loop;
        end procedure;

    begin

        ----------------------------------------------------------------------
        -- Reset Test
        ----------------------------------------------------------------------
        rst  <= '1';
        en   <= '0';
        ctrl <= "00";
        d    <= "0000";

        wait_clocks(2);

        rst <= '0';

        assert q = "0000"
        report "Reset Test FAILED"
        severity error;

        report "Reset Test PASSED";

        ----------------------------------------------------------------------
        -- Parallel Load Test
        ----------------------------------------------------------------------
        en   <= '1';
        ctrl <= "11";
        d    <= "1010";

        wait_clocks(1);

        assert q = "1010"
        report "Parallel Load FAILED"
        severity error;

        report "Parallel Load PASSED";

        ----------------------------------------------------------------------
        -- Hold Test
        ----------------------------------------------------------------------
        ctrl <= "00";
        d    <= "1111";

        wait_clocks(3);

        assert q = "1010"
        report "Hold Test FAILED"
        severity error;

        report "Hold Test PASSED";

        ----------------------------------------------------------------------
        -- Shift Left Test
        ----------------------------------------------------------------------
        ctrl <= "01";
        d(0) <= '1';

        wait_clocks(1);

        assert q = "0101"
        report "Shift Left #1 FAILED"
        severity error;

        d(0) <= '0';

        wait_clocks(1);

        assert q = "1010"
        report "Shift Left #2 FAILED"
        severity error;

        report "Shift Left PASSED";

        ----------------------------------------------------------------------
        -- Parallel Load Again
        ----------------------------------------------------------------------
        ctrl <= "11";
        d    <= "1010";

        wait_clocks(1);

        ----------------------------------------------------------------------
        -- Shift Right Test
        ----------------------------------------------------------------------
        ctrl <= "10";
        d(WIDTH-1) <= '0';

        wait_clocks(1);

        assert q = "0101"
        report "Shift Right #1 FAILED"
        severity error;

        d(WIDTH-1) <= '1';

        wait_clocks(1);

        assert q = "1010"
        report "Shift Right #2 FAILED"
        severity error;

        report "Shift Right PASSED";

        ----------------------------------------------------------------------
        -- Clock Enable Test
        ----------------------------------------------------------------------
        en <= '0';

        ctrl <= "11";
        d    <= "1111";

        wait_clocks(2);

        assert q = "1010"
        report "Clock Enable FAILED"
        severity error;

        report "Clock Enable PASSED";

        ----------------------------------------------------------------------
        -- Simulation Summary
        ----------------------------------------------------------------------
        report "========================================";
        report " ALL TESTS PASSED ";
        report "========================================";

        wait;

    end process;

end sim;