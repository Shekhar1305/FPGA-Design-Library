library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_pwm_generator is
end tb_pwm_generator;

architecture Behavioral of tb_pwm_generator is

    --------------------------------------------------------------------------
    -- Test Configuration
    --------------------------------------------------------------------------
    constant PULSE_COUNTER_WIDTH : natural := 4;

    --------------------------------------------------------------------------
    -- DUT Signals
    --------------------------------------------------------------------------
    signal clk                  : std_logic := '0';
    signal rst                  : std_logic := '0';
    signal en                   : std_logic := '0';

    signal total_pulse_width    : std_logic_vector(PULSE_COUNTER_WIDTH-1 downto 0);
    signal positive_pulse_width : std_logic_vector(PULSE_COUNTER_WIDTH-1 downto 0);

    signal conf_err             : std_logic;
    signal pwm_out              : std_logic;

begin

    --------------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------------
    DUT : entity work.pwm_generator
    generic map
    (
        PULSE_COUNTER_WIDTH => PULSE_COUNTER_WIDTH
    )
    port map
    (
        clk                  => clk,
        rst                  => rst,
        en                   => en,
        total_pulse_width    => total_pulse_width,
        positive_pulse_width => positive_pulse_width,
        conf_err             => conf_err,
        pwm_out              => pwm_out
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
        procedure wait_clock is
        begin
            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure;

        variable high_count : integer;

    begin

        ----------------------------------------------------------------------
        -- Reset Test
        ----------------------------------------------------------------------
        rst <= '1';
        en  <= '0';

        total_pulse_width    <= std_logic_vector(to_unsigned(10,PULSE_COUNTER_WIDTH));
        positive_pulse_width <= std_logic_vector(to_unsigned(5,PULSE_COUNTER_WIDTH));

        wait_clock;
        wait_clock;

        rst <= '0';

        assert pwm_out = '0'
        report "Reset Test FAILED"
        severity error;

        report "Reset Test PASSED";

        ----------------------------------------------------------------------
        -- Enable Hold Test
        ----------------------------------------------------------------------
        en <= '0';

        wait_clock;
        wait_clock;
        wait_clock;

        assert pwm_out = '0'
        report "Enable Hold FAILED"
        severity error;

        report "Enable Hold PASSED";

        ----------------------------------------------------------------------
        -- 50% Duty Cycle Test
        ----------------------------------------------------------------------
        en <= '1';

        high_count := 0;

        for i in 0 to 9 loop

            wait_clock;

            if pwm_out='1' then
                high_count := high_count + 1;
            end if;

        end loop;

        assert high_count = 5
        report "50 Percent Duty Test FAILED"
        severity error;

        report "50 Percent Duty Test PASSED";

        ----------------------------------------------------------------------
        -- 0% Duty Cycle Test
        ----------------------------------------------------------------------
        positive_pulse_width <= std_logic_vector(to_unsigned(0,PULSE_COUNTER_WIDTH));

        high_count := 0;

        for i in 0 to 9 loop

            wait_clock;

            if pwm_out='1' then
                high_count := high_count + 1;
            end if;

        end loop;

        assert high_count = 0
        report "0 Percent Duty Test FAILED"
        severity error;

        report "0 Percent Duty Test PASSED";

        ----------------------------------------------------------------------
        -- 100% Duty Cycle Test
        ----------------------------------------------------------------------
        positive_pulse_width <= std_logic_vector(to_unsigned(10,PULSE_COUNTER_WIDTH));

        high_count := 0;

        for i in 0 to 9 loop

            wait_clock;

            if pwm_out='1' then
                high_count := high_count + 1;
            end if;

        end loop;

        assert high_count = 10
        report "100 Percent Duty Test FAILED"
        severity error;

        report "100 Percent Duty Test PASSED";

        ----------------------------------------------------------------------
        -- Configuration Error Test
        ----------------------------------------------------------------------
        positive_pulse_width <= std_logic_vector(to_unsigned(12,PULSE_COUNTER_WIDTH));

        wait_clock;

        assert conf_err='1'
        report "Configuration Error Test FAILED"
        severity error;

        report "Configuration Error Test PASSED";

        ----------------------------------------------------------------------
        -- Recover from Error
        ----------------------------------------------------------------------
        positive_pulse_width <= std_logic_vector(to_unsigned(8,PULSE_COUNTER_WIDTH));

        wait_clock;

        assert conf_err='0'
        report "Configuration Recovery FAILED"
        severity error;

        report "Configuration Recovery PASSED";

        ----------------------------------------------------------------------
        -- Disable PWM
        ----------------------------------------------------------------------
        en <= '0';

        wait_clock;

        assert conf_err='0'
        report "Disable Test FAILED"
        severity error;

        report "Disable Test PASSED";

        ----------------------------------------------------------------------
        -- End of Simulation
        ----------------------------------------------------------------------
        report "========================================";
        report " ALL TESTS PASSED ";
        report "========================================";

        wait;

    end process;

end Behavioral;