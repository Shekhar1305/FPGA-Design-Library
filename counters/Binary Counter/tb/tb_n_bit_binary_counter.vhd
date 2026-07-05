library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_n_bit_binary_counter is
end entity;

architecture sim of tb_n_bit_binary_counter is

    constant COUNTER_WIDTH : natural := 4;

    signal clk  : std_logic := '0';
    signal rst  : std_logic := '0';
    signal en   : std_logic := '0';
    signal ctrl : std_logic_vector(1 downto 0);
    signal d    : std_logic_vector(COUNTER_WIDTH-1 downto 0);
    signal q    : std_logic_vector(COUNTER_WIDTH-1 downto 0);

begin

------------------------------------------------------------------
-- DUT
------------------------------------------------------------------

DUT : entity work.n_bit_binary_counter
generic map
(
    COUNTER_WIDTH => COUNTER_WIDTH
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

------------------------------------------------------------------
-- Clock Generation
------------------------------------------------------------------

clk <= not clk after 5 ns;

------------------------------------------------------------------
-- Test Process
------------------------------------------------------------------

process

    --------------------------------------------------------------
    -- Self Checking Procedure
    --------------------------------------------------------------

    procedure check(
        constant test_name : in string;
        constant expected  : in std_logic_vector
    ) is
    begin

        assert q = expected
            report test_name & " FAILED"
            severity error;

        report test_name & " PASSED";

    end procedure;

begin

    --------------------------------------------------------------
    -- RESET
    --------------------------------------------------------------

    rst  <= '1';
    en   <= '0';
    ctrl <= "00";
    d    <= (others => '0');

    wait until rising_edge(clk);

    rst <= '0';

    wait until rising_edge(clk);

    check("Reset", "0000");

    --------------------------------------------------------------
    -- PARALLEL LOAD
    --------------------------------------------------------------

    en   <= '1';
    ctrl <= "01";
    d    <= "0101";

    wait until rising_edge(clk);

    check("Parallel Load", "0101");

    --------------------------------------------------------------
    -- COUNT UP
    --------------------------------------------------------------

    ctrl <= "10";

    wait until rising_edge(clk);
    check("Count Up 1", "0110");

    wait until rising_edge(clk);
    check("Count Up 2", "0111");

    wait until rising_edge(clk);
    check("Count Up 3", "1000");

    --------------------------------------------------------------
    -- COUNT DOWN
    --------------------------------------------------------------

    ctrl <= "11";

    wait until rising_edge(clk);
    check("Count Down 1", "0111");

    wait until rising_edge(clk);
    check("Count Down 2", "0110");

    --------------------------------------------------------------
    -- CLEAR
    --------------------------------------------------------------

    ctrl <= "00";

    wait until rising_edge(clk);

    check("Clear", "0000");

    --------------------------------------------------------------
    -- CLOCK ENABLE
    --------------------------------------------------------------

    ctrl <= "10";
    en   <= '0';

    wait until rising_edge(clk);

    check("Clock Enable", "0000");

    --------------------------------------------------------------
    -- ENABLE AGAIN
    --------------------------------------------------------------

    en <= '1';

    wait until rising_edge(clk);

    check("Clock Enable Released", "0001");

    --------------------------------------------------------------
    -- WRAP AROUND UP
    --------------------------------------------------------------

    ctrl <= "01";
    d    <= "1111";

    wait until rising_edge(clk);

    check("Load 1111", "1111");

    ctrl <= "10";

    wait until rising_edge(clk);

    check("Wrap Around Up", "0000");

    --------------------------------------------------------------
    -- WRAP AROUND DOWN
    --------------------------------------------------------------

    ctrl <= "11";

    wait until rising_edge(clk);

    check("Wrap Around Down", "1111");

    --------------------------------------------------------------

    report "====================================";
    report " ALL TESTS PASSED SUCCESSFULLY ";
    report "====================================";

    wait;

end process;

end architecture;