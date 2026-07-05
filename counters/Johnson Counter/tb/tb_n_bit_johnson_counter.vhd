library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_n_bit_johnson_counter is
end tb_n_bit_johnson_counter;

architecture sim of tb_n_bit_johnson_counter is

    --------------------------------------------------------------------------
    -- Constants
    --------------------------------------------------------------------------
    constant COUNT_WIDTH : natural := 4;

    --------------------------------------------------------------------------
    -- DUT Signals
    --------------------------------------------------------------------------
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal en  : std_logic := '0';

    signal count_out : std_logic_vector(COUNT_WIDTH-1 downto 0);

    --------------------------------------------------------------------------
    -- Expected Johnson Sequence
    --------------------------------------------------------------------------
    type johnson_array is array (0 to 8) of
        std_logic_vector(COUNT_WIDTH-1 downto 0);

    constant EXPECTED_SEQ : johnson_array :=
    (
        "0000",
        "1000",
        "1100",
        "1110",
        "1111",
        "0111",
        "0011",
        "0001",
        "0000"
    );

begin

    --------------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------------
    DUT : entity work.n_bit_johnson_counter
    generic map
    (
        COUNT_WIDTH => COUNT_WIDTH
    )
    port map
    (
        clk       => clk,
        rst       => rst,
        en        => en,
        count_out => count_out
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

        wait_clocks(2);

        rst <= '0';

        assert count_out = EXPECTED_SEQ(0)
        report "Reset Test FAILED"
        severity error;

        report "Reset Test PASSED";

        ----------------------------------------------------------------------
        -- Enable Hold Test
        ----------------------------------------------------------------------
        en <= '0';

        wait_clocks(3);

        assert count_out = EXPECTED_SEQ(0)
        report "Enable Hold Test FAILED"
        severity error;

        report "Enable Hold Test PASSED";

        ----------------------------------------------------------------------
        -- Johnson Sequence Test
        ----------------------------------------------------------------------
        report "Starting Johnson Sequence Test";

        en <= '1';

        for i in 1 to 8 loop

            wait_clocks(1);

            assert count_out = EXPECTED_SEQ(i)
            report "Sequence FAILED at state "
                   & integer'image(i)
            severity error;

            report "State "
                   & integer'image(i)
                   & " PASSED";

        end loop;

        report "Johnson Sequence Test PASSED";

        ----------------------------------------------------------------------
        -- Wrap Around Test
        ----------------------------------------------------------------------
        wait_clocks(1);

        assert count_out = EXPECTED_SEQ(1)
        report "Wrap Around Test FAILED"
        severity error;

        report "Wrap Around Test PASSED";

        ----------------------------------------------------------------------
        -- Summary
        ----------------------------------------------------------------------
        report "========================================";
        report " ALL TESTS PASSED ";
        report "========================================";

        wait;

    end process;

end sim;