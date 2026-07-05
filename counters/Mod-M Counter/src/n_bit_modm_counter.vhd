----------------------------------------------------------------------------------
-- Company      :
-- Engineer     : Shekhar Mishra
--
-- Create Date  : 01.07.2026
-- Module Name  : n_bit_modm_counter
-- Project Name : FPGA Design Library
-- Target Device: Generic FPGA
--
-- Description:
--   Parameterizable N-bit Mod-M counter.
--
--   This module implements a configurable modulo counter where the
--   input 'M' specifies the TOTAL NUMBER OF STATES rather than the
--   terminal count value.
--
--   Example:
--
--       M = 10
--
--       Counter Sequence:
--
--       0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 0
--
--       (10 unique states)
--
--   Similarly,
--
--       M = 16
--
--       Counts from
--
--       0 → 15
--
--       before rolling over to zero.
--
-- Features:
--   - Parameterizable counter width
--   - Runtime configurable modulus
--   - Counts from 0 to (M-1)
--   - Automatic rollover
--   - Synchronous active-high reset
--   - Clock enable
--   - FPGA-friendly RTL
--
-- Notes:
--   - M = 0 is treated as an invalid modulus.
--     In this case the counter remains at zero.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity n_bit_modm_counter is

    generic(

        ----------------------------------------------------------------------
        -- Width of the binary counter.
        ----------------------------------------------------------------------
        COUNTER_WIDTH : natural := 4

    );

    port(

        ----------------------------------------------------------------------
        -- System Interface
        ----------------------------------------------------------------------
        clk : in std_logic;          -- System clock
        rst : in std_logic;          -- Active-high synchronous reset
        en  : in std_logic;          -- Clock enable

        ----------------------------------------------------------------------
        -- Modulus
        --
        -- Specifies the TOTAL NUMBER OF COUNT STATES.
        --
        -- Example:
        --
        -- M = 10
        -- Counter sequence:
        -- 0 → 1 → ... → 9 → 0
        ----------------------------------------------------------------------
        m : in std_logic_vector(COUNTER_WIDTH-1 downto 0);

        ----------------------------------------------------------------------
        -- Counter Output
        ----------------------------------------------------------------------
        q : out std_logic_vector(COUNTER_WIDTH-1 downto 0)

    );

end n_bit_modm_counter;

architecture rtl of n_bit_modm_counter is

    --------------------------------------------------------------------------
    -- Current counter value.
    --------------------------------------------------------------------------
    signal r_reg : unsigned(COUNTER_WIDTH-1 downto 0);

    --------------------------------------------------------------------------
    -- Incremented counter value.
    --------------------------------------------------------------------------
    signal r_inc : unsigned(COUNTER_WIDTH-1 downto 0);

    --------------------------------------------------------------------------
    -- Next-state value of the counter.
    --------------------------------------------------------------------------
    signal r_next : unsigned(COUNTER_WIDTH-1 downto 0);

    --------------------------------------------------------------------------
    -- Unsigned representation of modulus input.
    --------------------------------------------------------------------------
    signal m_uns : unsigned(COUNTER_WIDTH-1 downto 0);

begin

    --------------------------------------------------------------------------
    -- Convert modulus input into unsigned format.
    --------------------------------------------------------------------------
    m_uns <= unsigned(m);

    --------------------------------------------------------------------------
    -- Generate incremented counter value.
    --------------------------------------------------------------------------
    r_inc <= r_reg + 1;

    --------------------------------------------------------------------------
    -- Next-State Logic
    --
    -- If the incremented count reaches the configured number of states,
    -- the counter rolls over to zero.
    --
    -- Example:
    --
    -- M = 10
    --
    -- Current Count   Incremented   Next Count
    -- -----------------------------------------
    --      8              9             9
    --      9             10             0
    --
    -- M = 0 is treated as an invalid modulus and forces the counter
    -- to remain at zero.
    --------------------------------------------------------------------------
    r_next <= (others => '0')
              when (r_inc >= m_uns) or (m_uns = 0)
              else r_inc;

    --------------------------------------------------------------------------
    -- Output Assignment
    --------------------------------------------------------------------------
    q <= std_logic_vector(r_reg);

    --------------------------------------------------------------------------
    -- Counter Register
    --
    -- Operation:
    --
    -- Reset:
    --      Clears the counter.
    --
    -- Enable:
    --      Updates the counter only when EN is asserted.
    --
    -- Normal Operation:
    --      Loads the value generated by the combinational next-state logic.
    --------------------------------------------------------------------------
    counter_pr : process(clk)
    begin

        if rising_edge(clk) then

            if rst = '1' then

                r_reg <= (others => '0');

            elsif en = '1' then

                r_reg <= r_next;

            end if;

        end if;

    end process counter_pr;

end rtl;