library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ring_counter is
end entity;

architecture sim of tb_ring_counter is

    constant COUNT_WIDTH : natural := 5;

    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';
    signal en          : std_logic := '0';

    signal debug_load  : std_logic := '0';
    signal debug_value : std_logic_vector(COUNT_WIDTH-1 downto 0);

    signal count_out   : std_logic_vector(COUNT_WIDTH-1 downto 0);

begin

--------------------------------------------------------------------
-- DUT
--------------------------------------------------------------------

DUT : entity work.ring_counter
generic map
(
    COUNT_WIDTH => COUNT_WIDTH
)
port map
(
    clk         => clk,
    rst         => rst,
    en          => en,
    debug_load  => debug_load,
    debug_value => debug_value,
    count_out   => count_out
);

--------------------------------------------------------------------
-- Clock
--------------------------------------------------------------------

clk <= not clk after 5 ns;

--------------------------------------------------------------------
-- Stimulus
--------------------------------------------------------------------

stimulus : process

    variable pass_count : integer := 0;
    variable fail_count : integer := 0;

    ---------------------------------------------------------------
    -- Returns TRUE if exactly one bit is high
    ---------------------------------------------------------------
    function is_one_hot(
        value : std_logic_vector
    ) return boolean is

        variable ones : integer := 0;

    begin

        for i in value'range loop

            if value(i) = '1' then
                ones := ones + 1;
            end if;

        end loop;

        return (ones = 1);

    end function;

begin

    ---------------------------------------------------------------
    -- RESET
    ---------------------------------------------------------------

    rst <= '1';
    en  <= '0';

    wait until rising_edge(clk);
    wait for 1 ns;

    rst <= '0';
    en  <= '1';

    ---------------------------------------------------------------
    -- Check reset state
    ---------------------------------------------------------------

    assert is_one_hot(count_out)
        report "Reset failed."
        severity error;

    report "PASS : Reset";

    ---------------------------------------------------------------
    -- Inject every possible state
    ---------------------------------------------------------------

    for state in 0 to (2**COUNT_WIDTH)-1 loop

        -----------------------------------------------------------
        -- Inject state
        -----------------------------------------------------------

        debug_value <= std_logic_vector(to_unsigned(state, COUNT_WIDTH));
        debug_load  <= '1';

        wait until rising_edge(clk);
        wait for 1 ns;

        debug_load <= '0';

        report "Testing State = "
               & integer'image(state);

        -----------------------------------------------------------
        -- Allow recovery
        -----------------------------------------------------------

        for i in 1 to COUNT_WIDTH loop

            wait until rising_edge(clk);
            wait for 1 ns;

            exit when is_one_hot(count_out);

        end loop;

        -----------------------------------------------------------
        -- Verify recovery
        -----------------------------------------------------------

        if is_one_hot(count_out) then

            pass_count := pass_count + 1;

            report "PASS : State "
                   & integer'image(state)
                   & " recovered to "
                   & integer'image(to_integer(unsigned(count_out)));

        else

            fail_count := fail_count + 1;

            assert false
                report "FAIL : State "
                       & integer'image(state)
                       & " failed to recover."
                severity error;

        end if;

    end loop;

    ---------------------------------------------------------------
    -- Enable Test
    ---------------------------------------------------------------

    debug_value <= "10000";
    debug_load  <= '1';

    wait until rising_edge(clk);
    wait for 1 ns;

    debug_load <= '0';

    en <= '0';

    wait until rising_edge(clk);
    wait for 1 ns;

    assert count_out = "10000"
        report "Enable Hold Failed"
        severity error;

    report "PASS : Enable Hold";

    ---------------------------------------------------------------
    -- Summary
    ---------------------------------------------------------------

    report "===================================";
    report "Verification Summary";
    report "===================================";
    report "States Tested : "
           & integer'image(2**COUNT_WIDTH);

    report "PASS : "
           & integer'image(pass_count);

    report "FAIL : "
           & integer'image(fail_count);

    report "===================================";

    if fail_count = 0 then
        report "ALL TESTS PASSED";
    else
        report "TEST FAILED";
    end if;

    wait;

end process;

end architecture;