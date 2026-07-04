library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_gray_counter_n is
end entity;

architecture sim of tb_gray_counter_n is

    constant COUNT_WIDTH : natural := 4;
    constant NUM_STATES  : natural := 2**COUNT_WIDTH;

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '0';
    signal en        : std_logic := '0';
    signal count_out : std_logic_vector(COUNT_WIDTH-1 downto 0);

begin

----------------------------------------------------------------------
-- DUT
----------------------------------------------------------------------

DUT : entity work.gray_counter_n
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

----------------------------------------------------------------------
-- Clock
----------------------------------------------------------------------

clk <= not clk after 5 ns;

----------------------------------------------------------------------
-- Test Process
----------------------------------------------------------------------

stimulus : process

    type visited_array is array (0 to NUM_STATES-1) of boolean;

    variable visited : visited_array := (others => false);

    variable previous_gray : std_logic_vector(COUNT_WIDTH-1 downto 0);

    variable ones : integer;
    variable value : integer;

    variable pass : integer := 0;
    variable fail : integer := 0;

begin

    ------------------------------------------------------------
    -- RESET TEST
    ------------------------------------------------------------

    rst <= '1';
    en  <= '0';

    wait until rising_edge(clk);
    wait for 1 ns;

    assert count_out = (count_out'range => '0')
        report "Reset failed."
        severity error;

    report "PASS : Reset";

    pass := pass + 1;

    rst <= '0';
    en  <= '1';

    previous_gray := count_out;

    visited(0) := true;

    ------------------------------------------------------------
    -- MAIN TEST
    ------------------------------------------------------------

    for i in 1 to NUM_STATES-1 loop

        wait until rising_edge(clk);
        wait for 1 ns;

        --------------------------------------------------------
        -- Property 1
        -- Only one bit changes
        --------------------------------------------------------

        ones := 0;

        for j in 0 to COUNT_WIDTH-1 loop

            if previous_gray(j) /= count_out(j) then
                ones := ones + 1;
            end if;

        end loop;

        assert ones = 1
            report "More than one bit changed at count "
                   & integer'image(i)
            severity error;

        --------------------------------------------------------
        -- Property 2
        -- No duplicate Gray codes
        --------------------------------------------------------

        value := to_integer(unsigned(count_out));

        assert not visited(value)
            report "Duplicate Gray value detected : "
                   & integer'image(value)
            severity error;

        visited(value) := true;

        previous_gray := count_out;

        report "PASS : State "
               & integer'image(i)
               & " Gray = "
               & integer'image(value);

        pass := pass + 1;

    end loop;

    ------------------------------------------------------------
    -- WRAP TEST
    ------------------------------------------------------------

    wait until rising_edge(clk);
    wait for 1 ns;

    assert count_out = (count_out'range => '0')
        report "Wrap-around failed."
        severity error;

    report "PASS : Wrap Around";

    pass := pass + 1;

    ------------------------------------------------------------
    -- ENABLE TEST
    ------------------------------------------------------------

    previous_gray := count_out;

    en <= '0';

    for i in 1 to 5 loop
        wait until rising_edge(clk);
    end loop;

    wait for 1 ns;

    assert count_out = previous_gray
        report "Clock Enable failed."
        severity error;

    report "PASS : Clock Enable";

    pass := pass + 1;

    ------------------------------------------------------------
    -- SUMMARY
    ------------------------------------------------------------

    report "======================================";
    report "GRAY COUNTER VERIFICATION COMPLETE";
    report "Tests Passed : " & integer'image(pass);
    report "Tests Failed : " & integer'image(fail);
    report "======================================";

    wait;

end process;

end architecture;