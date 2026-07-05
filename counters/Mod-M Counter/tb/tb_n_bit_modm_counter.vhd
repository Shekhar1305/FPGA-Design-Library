library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_n_bit_modm_counter is
end tb_n_bit_modm_counter;

architecture sim of tb_n_bit_modm_counter is

    --------------------------------------------------------------------------
    -- Constants
    --------------------------------------------------------------------------
    constant COUNTER_WIDTH : natural := 4;

    --------------------------------------------------------------------------
    -- DUT Signals
    --------------------------------------------------------------------------
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal en  : std_logic := '0';

    signal m : std_logic_vector(COUNTER_WIDTH-1 downto 0);
    signal q : std_logic_vector(COUNTER_WIDTH-1 downto 0);

begin

    --------------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------------
    DUT : entity work.n_bit_modm_counter
    generic map
    (
        COUNTER_WIDTH => COUNTER_WIDTH
    )
    port map
    (
        clk => clk,
        rst => rst,
        en  => en,
        m   => m,
        q   => q
    );

    --------------------------------------------------------------------------
    -- Clock Generation (100 MHz)
    --------------------------------------------------------------------------
    clk <= not clk after 5 ns;

    --------------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------------
    stim_proc : process

        ----------------------------------------------------------------------
        -- Wait for N clock cycles
        ----------------------------------------------------------------------
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
        rst <= '1';
        en  <= '0';
        m   <= std_logic_vector(to_unsigned(10, COUNTER_WIDTH));

        wait_clocks(2);

        rst <= '0';

        assert q = "0000"
        report "Reset Test FAILED"
        severity error;

        report "Reset Test PASSED";

        ----------------------------------------------------------------------
        -- Enable Hold Test
        ----------------------------------------------------------------------
        en <= '0';

        wait_clocks(3);

        assert q = "0000"
        report "Enable Hold Test FAILED"
        severity error;

        report "Enable Hold Test PASSED";

        ----------------------------------------------------------------------
        -- MOD-10 Test
        ----------------------------------------------------------------------
        report "Starting MOD-10 Test";

        en <= '1';
        m  <= std_logic_vector(to_unsigned(10, COUNTER_WIDTH));

        for expected in 1 to 9 loop

            wait_clocks(1);

            assert unsigned(q) = expected
            report "MOD-10 FAILED. Expected="
                   & integer'image(expected)
                   & " Actual="
                   & integer'image(to_integer(unsigned(q)))
            severity error;

        end loop;

        -- Wrap Around

        wait_clocks(1);

        assert q = "0000"
        report "MOD-10 Wrap FAILED"
        severity error;

        report "MOD-10 Test PASSED";

        ----------------------------------------------------------------------
        -- MOD-5 Test
        ----------------------------------------------------------------------
        report "Starting MOD-5 Test";

        rst <= '1';
        wait_clocks(1);
        rst <= '0';

        m <= std_logic_vector(to_unsigned(5, COUNTER_WIDTH));

        for expected in 1 to 4 loop

            wait_clocks(1);

            assert unsigned(q) = expected
            report "MOD-5 FAILED"
            severity error;

        end loop;

        wait_clocks(1);

        assert q = "0000"
        report "MOD-5 Wrap FAILED"
        severity error;

        report "MOD-5 Test PASSED";

        ----------------------------------------------------------------------
        -- MOD-1 Test
        ----------------------------------------------------------------------
        report "Starting MOD-1 Test";

        rst <= '1';
        wait_clocks(1);
        rst <= '0';

        m <= std_logic_vector(to_unsigned(1, COUNTER_WIDTH));

        wait_clocks(5);

        assert q = "0000"
        report "MOD-1 Test FAILED"
        severity error;

        report "MOD-1 Test PASSED";

        ----------------------------------------------------------------------
        -- Invalid Modulus Test (M = 0)
        ----------------------------------------------------------------------
        report "Starting Invalid Modulus Test";

        rst <= '1';
        wait_clocks(1);
        rst <= '0';

        m <= (others => '0');

        wait_clocks(5);

        assert q = "0000"
        report "Invalid Modulus Test FAILED"
        severity error;

        report "Invalid Modulus Test PASSED";

        ----------------------------------------------------------------------
        -- Summary
        ----------------------------------------------------------------------
        report "========================================";
        report " ALL TESTS PASSED ";
        report "========================================";

        wait;

    end process;

end sim;