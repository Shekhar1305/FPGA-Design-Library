library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_timer is
end entity;

architecture sim of tb_timer is

    constant MAIN_CLK_COUNT : natural := 10;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal en  : std_logic := '0';

    signal sec : std_logic_vector(5 downto 0);
    signal min : std_logic_vector(5 downto 0);

begin

    ------------------------------------------------------------------
    -- DUT
    ------------------------------------------------------------------

    DUT : entity work.timer
    generic map
    (
        MAIN_CLK_COUNT => MAIN_CLK_COUNT
    )
    port map
    (
        clk => clk,
        rst => rst,
        en  => en,
        sec => sec,
        min => min
    );

    ------------------------------------------------------------------
    -- Clock Generation
    ------------------------------------------------------------------

    clk <= not clk after 5 ns;

    ------------------------------------------------------------------
    -- Stimulus
    ------------------------------------------------------------------

    process

        variable sec_before : std_logic_vector(5 downto 0);

    begin

        ----------------------------------------------------------
        -- Reset
        ----------------------------------------------------------

        rst <= '1';
        en  <= '0';

        wait for 20 ns;

        rst <= '0';
        en  <= '1';

        ----------------------------------------------------------
        -- Wait until just before terminal count
        ----------------------------------------------------------

        for i in 1 to MAIN_CLK_COUNT-1 loop
            wait until rising_edge(clk);
        end loop;

        ----------------------------------------------------------
        -- Disable timer
        ----------------------------------------------------------

        sec_before := sec;

        report "Disabling timer";

        en <= '0';

        ----------------------------------------------------------
        -- Wait 20 clocks
        ----------------------------------------------------------

        for i in 1 to 20 loop
            wait until rising_edge(clk);
        end loop;
        en <= '1';
        
        wait for 6000 ns;

        ----------------------------------------------------------
        -- Self Check
        ----------------------------------------------------------

        assert sec = sec_before
            report "FAIL : Seconds counter changed after EN was deasserted."
            severity error;

        report "PASS : Seconds counter remained constant after EN deassertion.";

        report "Simulation Completed.";

        wait;

    end process;

end architecture;