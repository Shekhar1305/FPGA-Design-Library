----------------------------------------------------------------------------------
-- Company      :
-- Engineer     : Shekhar Mishra
--
-- Create Date  : 07.07.2026
-- Module Name  : pwm_generator
-- Project Name : FPGA Design Library
-- Target Device: Generic FPGA
--
-- Description:
--
--   Parameterizable Pulse Width Modulation (PWM) Generator.
--
--   The PWM period and duty cycle are programmable at run time through
--   configurable input ports.
--
--   Features:
--     • Generic counter width
--     • Runtime configurable PWM period
--     • Runtime configurable duty cycle
--     • Clock enable
--     • Active-high synchronous reset
--     • Configuration error detection
--     • Registered PWM output
--
--   Configuration Rules:
--     • total_pulse_width = 0       -> PWM output remains LOW
--     • positive_pulse_width = 0    -> 0% duty cycle
--     • positive_pulse_width = total_pulse_width -> 100% duty cycle
--     • positive_pulse_width > total_pulse_width -> Configuration Error
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pwm_generator is

    generic(

        ----------------------------------------------------------------------
        -- Width of the PWM counter.
        ----------------------------------------------------------------------
        PULSE_COUNTER_WIDTH : natural := 4

    );

    port(

        ----------------------------------------------------------------------
        -- System Interface
        ----------------------------------------------------------------------
        clk : in std_logic;      -- System clock
        rst : in std_logic;      -- Active-high synchronous reset
        en  : in std_logic;      -- PWM enable

        ----------------------------------------------------------------------
        -- PWM Configuration
        ----------------------------------------------------------------------
        total_pulse_width :
            in std_logic_vector(PULSE_COUNTER_WIDTH-1 downto 0);

        positive_pulse_width :
            in std_logic_vector(PULSE_COUNTER_WIDTH-1 downto 0);

        ----------------------------------------------------------------------
        -- Outputs
        ----------------------------------------------------------------------

        -- Asserted whenever duty cycle exceeds the configured period.
        conf_err : out std_logic;

        -- PWM Output
        pwm_out : out std_logic

    );

end pwm_generator;

architecture Behavioral of pwm_generator is

    --------------------------------------------------------------------------
    -- Current PWM counter value.
    --------------------------------------------------------------------------
    signal pulse_width_reg : unsigned(PULSE_COUNTER_WIDTH-1 downto 0);

    --------------------------------------------------------------------------
    -- Incremented counter value.
    --------------------------------------------------------------------------
    signal pulse_width_inc : unsigned(PULSE_COUNTER_WIDTH-1 downto 0);

    --------------------------------------------------------------------------
    -- Next PWM counter value.
    --------------------------------------------------------------------------
    signal pulse_width_next : unsigned(PULSE_COUNTER_WIDTH-1 downto 0);

    --------------------------------------------------------------------------
    -- Unsigned versions of configuration inputs.
    --------------------------------------------------------------------------
    signal total_pulse_width_un :
        unsigned(PULSE_COUNTER_WIDTH-1 downto 0);

    signal positive_pulse_width_un :
        unsigned(PULSE_COUNTER_WIDTH-1 downto 0);

    --------------------------------------------------------------------------
    -- Registered PWM output.
    --------------------------------------------------------------------------
    signal pwm_out_reg  : std_logic;
    signal pwm_out_next : std_logic;

    --------------------------------------------------------------------------
    -- Internal clock enable.
    --
    -- Prevents the PWM counter from operating when an invalid configuration
    -- (Duty > Period) is detected.
    --------------------------------------------------------------------------
    signal internal_en : std_logic;

begin

    --------------------------------------------------------------------------
    -- Convert configuration inputs to unsigned.
    --------------------------------------------------------------------------
    total_pulse_width_un    <= unsigned(total_pulse_width);
    positive_pulse_width_un <= unsigned(positive_pulse_width);

    --------------------------------------------------------------------------
    -- Counter increment.
    --------------------------------------------------------------------------
    pulse_width_inc <= pulse_width_reg + 1;

    --------------------------------------------------------------------------
    -- Counter next-state logic.
    --
    -- Counter resets to zero when:
    --   • Period expires
    --   • Period is configured as zero
    --   • Duty cycle is configured as zero
    --------------------------------------------------------------------------
    pulse_width_next <=
        (others => '0')
            when ((pulse_width_inc >= total_pulse_width_un) or
                  (total_pulse_width_un = 0) or
                  (positive_pulse_width_un = 0))
        else
            pulse_width_inc;

    --------------------------------------------------------------------------
    -- PWM comparator.
    --
    -- Output remains HIGH while counter is less than the programmed duty
    -- cycle value.
    --------------------------------------------------------------------------
    pwm_out_next <=
        '0' when (pulse_width_reg >= positive_pulse_width_un)
        else '1';

    --------------------------------------------------------------------------
    -- Registered PWM output.
    --------------------------------------------------------------------------
    pwm_out <= pwm_out_reg;

    --------------------------------------------------------------------------
    -- Internal enable.
    --
    -- PWM operation is enabled only when:
    --   • Master enable is asserted.
    --   • Duty cycle does not exceed the configured period.
    --------------------------------------------------------------------------
    internal_en <=
        '1'
        when ((en = '1') and
              (total_pulse_width_un >= positive_pulse_width_un))
        else
        '0';

    --------------------------------------------------------------------------
    -- Configuration Error.
    --
    -- Asserted only when PWM is enabled and the configured duty cycle
    -- exceeds the programmed period.
    --------------------------------------------------------------------------
    conf_err <= (not internal_en) and en;

    --------------------------------------------------------------------------
    -- PWM Counter Register
    --------------------------------------------------------------------------
    pulse_counter_pr : process(clk)
    begin

        if rising_edge(clk) then

            --------------------------------------------------------------
            -- Synchronous Reset
            --------------------------------------------------------------
            if rst = '1' then

                pulse_width_reg <= (others => '0');
                pwm_out_reg     <= '0';

            --------------------------------------------------------------
            -- Normal PWM Operation
            --------------------------------------------------------------
            elsif internal_en = '1' then

                pulse_width_reg <= pulse_width_next;
                pwm_out_reg     <= pwm_out_next;

            end if;

        end if;

    end process pulse_counter_pr;

end Behavioral;