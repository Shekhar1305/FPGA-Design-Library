library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_n_bit_lfsr is
end tb_n_bit_lfsr;

architecture sim of tb_n_bit_lfsr is

    --------------------------------------------------------------------------
    -- Test Configuration
    --------------------------------------------------------------------------
    constant DATA_WIDTH  : natural := 4;
    constant TAP_VALUE   : natural := 16#9#;      -- x^4 + x^3 + 1

    constant TOTAL_STATES : natural := 2**DATA_WIDTH;

    --------------------------------------------------------------------------
    -- DUT Signals
    --------------------------------------------------------------------------
    signal clk        : std_logic := '0';
    signal rst        : std_logic := '0';
    signal en         : std_logic := '0';
    signal load_seed  : std_logic := '0';

    signal seed       : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal lfsr_data  : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal lfsr_done  : std_logic;

begin

    --------------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------------
    DUT : entity work.n_bit_lfsr
    generic map
    (
        DATA_WIDTH => DATA_WIDTH,
        TAP_VALUE  => TAP_VALUE
    )
    port map
    (
        clk        => clk,
        rst        => rst,
        en         => en,
        load_seed  => load_seed,
        seed       => seed,
        lfsr_data  => lfsr_data,
        lfsr_done  => lfsr_done
    );

    --------------------------------------------------------------------------
    -- 100 MHz Clock
    --------------------------------------------------------------------------
    clk <= not clk after 5 ns;

    --------------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------------
    stim_proc : process

        type visited_array is array (0 to TOTAL_STATES-1) of boolean;

        variable visited     : visited_array := (others => false);

        variable state_count : natural := 0;

        variable idx         : natural;

        ----------------------------------------------------------------------
        procedure wait_clock is
        begin
            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure;

    begin

        ----------------------------------------------------------------------
        -- Reset
        ----------------------------------------------------------------------
        rst <= '1';
        en  <= '0';
        load_seed <= '0';

        seed <= "1010";

        wait_clock;
        wait_clock;

        rst <= '0';

        assert lfsr_data = "0000"
        report "Reset Test FAILED"
        severity error;

        report "Reset Test PASSED";

        ----------------------------------------------------------------------
        -- Load Seed
        ----------------------------------------------------------------------
        load_seed <= '1';

        wait_clock;

        load_seed <= '0';

        assert lfsr_data = seed
        report "Seed Load FAILED"
        severity error;

        report "Seed Load PASSED";

        ----------------------------------------------------------------------
        -- Enable Counting
        ----------------------------------------------------------------------
        en <= '1';

        ----------------------------------------------------------------------
        -- Record Initial Seed
        ----------------------------------------------------------------------
        idx := to_integer(unsigned(lfsr_data));

        visited(idx) := true;

        state_count := 1;

        ----------------------------------------------------------------------
        -- Walk Entire Sequence
        ----------------------------------------------------------------------
        loop

            wait_clock;

            idx := to_integer(unsigned(lfsr_data));

            ------------------------------------------------------------------
            -- Returned to seed?
            ------------------------------------------------------------------
            if (lfsr_data = seed) then

                exit;

            end if;

            ------------------------------------------------------------------
            -- Duplicate State Check
            ------------------------------------------------------------------
            assert not visited(idx)
            report "Duplicate state detected : "
                   & integer'image(idx)
            severity error;

            visited(idx) := true;

            state_count := state_count + 1;

        end loop;

        ----------------------------------------------------------------------
        -- Sequence Length Check
        ----------------------------------------------------------------------
        assert state_count = TOTAL_STATES
        report "Expected "
               & integer'image(TOTAL_STATES)
               & " states, visited "
               & integer'image(state_count)
        severity error;

        report "Sequence Length PASSED";

        ----------------------------------------------------------------------
        -- Verify Every State Was Visited
        ----------------------------------------------------------------------
        for i in 0 to TOTAL_STATES-1 loop

            assert visited(i)
            report "State missing : "
                   & integer'image(i)
            severity error;

        end loop;

        report "All States Visited PASSED";

        ----------------------------------------------------------------------
        -- Verify lfsr_done
        ----------------------------------------------------------------------
        assert lfsr_done = '1'
        report "lfsr_done FAILED"
        severity error;

        report "lfsr_done PASSED";

        ----------------------------------------------------------------------
        -- Enable Hold Test
        ----------------------------------------------------------------------
        en <= '0';

        wait_clock;

        assert lfsr_data = seed
        report "Enable Hold FAILED"
        severity error;

        report "Enable Hold PASSED";

        ----------------------------------------------------------------------
        -- Summary
        ----------------------------------------------------------------------
        report "========================================";
        report " ALL TESTS PASSED ";
        report "========================================";

        wait;

    end process;

end sim;