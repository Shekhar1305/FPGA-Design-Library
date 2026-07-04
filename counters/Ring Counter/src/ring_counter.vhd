----------------------------------------------------------------------------------
-- Company      :
-- Engineer     : Shekhar Mishra
--
-- Create Date  : 04.07.2026
-- Module Name  : ring_counter
-- Project Name : FPGA Design Library
-- Target Device: Generic FPGA
--
-- Description:
--   Parameterizable self-recovering one-hot ring counter.
--
--   The design circulates a single logic '1' through an N-bit shift
--   register. Under normal operation the active bit rotates through
--   every register position.
--
--   Unlike a conventional ring counter, this implementation is capable
--   of recovering from illegal states that may occur due to transient
--   faults (SEU), initialization errors or fault injection during
--   verification.
--
--   Recovery Mechanism:
--   -------------------
--   If all upper bits are cleared, a logic '1' is automatically inserted
--   into the MSB during the next shift operation. This causes illegal
--   states such as:
--
--       0000
--       1111
--       1010
--       1100
--
--   to naturally converge to a valid one-hot state without requiring
--   an external reset.
--
--   Example Recovery:
--
--       1111
--         |
--         V
--       0111
--         |
--         V
--       0011
--         |
--         V
--       0001
--         |
--         V
--       1000
--
-- Features:
--   - Parameterizable counter width
--   - One-hot ring counter
--   - Automatic self-recovery from illegal states
--   - Valid output indicating legal one-hot state
--   - Clock enable
--   - Synchronous active-high reset
--   - Simulation-only fault injection interface
--
-- Applications:
--   - Token Passing
--   - LED Chasers
--   - Sequencers
--   - FSM State Generation
--   - Fault Injection Verification
--   - Safety Critical Digital Designs
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ring_counter is

    generic(

        -- Number of stages in the ring counter.
        COUNT_WIDTH : natural := 4

    );

    port(

        ----------------------------------------------------------------------
        -- System Interface
        ----------------------------------------------------------------------
        clk : in std_logic;                     -- System clock
        rst : in std_logic;                     -- Active-high synchronous reset
        en  : in std_logic;                     -- Clock enable

        ----------------------------------------------------------------------
        -- Simulation Debug Interface
        --
        -- Used only during simulation to inject arbitrary states into the
        -- counter for recovery verification.
        ----------------------------------------------------------------------
        -- synthesis translate_off

        debug_load  : in std_logic;
        debug_value : in std_logic_vector(COUNT_WIDTH-1 downto 0);

        -- synthesis translate_on

        ----------------------------------------------------------------------
        -- Outputs
        ----------------------------------------------------------------------
        valid     : out std_logic;              -- Indicates legal one-hot state
        count_out : out std_logic_vector(COUNT_WIDTH-1 downto 0)

    );

end ring_counter;

architecture rtl of ring_counter is

    --------------------------------------------------------------------------
    -- Current ring counter state.
    --------------------------------------------------------------------------
    signal ring_reg : std_logic_vector(COUNT_WIDTH-1 downto 0);

    --------------------------------------------------------------------------
    -- Next state of the ring counter.
    --------------------------------------------------------------------------
    signal ring_next : std_logic_vector(COUNT_WIDTH-1 downto 0);

    --------------------------------------------------------------------------
    -- Self-recovery control.
    --
    -- When all upper bits are zero, a logic '1' is inserted into the MSB.
    -- This allows illegal states to naturally converge towards a valid
    -- one-hot sequence.
    --------------------------------------------------------------------------
    signal self_corr : std_logic;

begin

    --------------------------------------------------------------------------
    -- Self Recovery Logic
    --
    -- Detects when all upper bits are zero and inserts a logic '1'
    -- into the MSB during the next shift operation.
    --------------------------------------------------------------------------
    self_corr <= '1'
        when ring_reg(COUNT_WIDTH-1 downto 1) =
             (COUNT_WIDTH-2 downto 0 => '0')
        else
        '0';

    --------------------------------------------------------------------------
    -- Next-State Logic
    --
    -- Right shift the register while inserting either:
    --   1 -> Recovery mode
    --   0 -> Normal ring operation
    --------------------------------------------------------------------------
    ring_next <= self_corr &
                 ring_reg(COUNT_WIDTH-1 downto 1);

    --------------------------------------------------------------------------
    -- One-Hot Detection
    --
    -- Valid is asserted whenever exactly one bit of the register is high.
    --
    -- Uses the standard one-hot detection equation:
    --
    --      x != 0  AND  (x & (x-1)) == 0
    --
    --------------------------------------------------------------------------
    valid <= '1'
        when (unsigned(ring_reg) /= 0) and
             ((unsigned(ring_reg) and
              (unsigned(ring_reg)-1)) = 0)
        else
        '0';

    --------------------------------------------------------------------------
    -- Output Assignment
    --------------------------------------------------------------------------
    count_out <= ring_reg;

    --------------------------------------------------------------------------
    -- Ring Counter Register
    --
    -- Operation:
    --
    --  Reset:
    --      Initializes the counter to a valid one-hot state.
    --
    --  Debug Mode:
    --      Allows arbitrary state injection during simulation.
    --
    --  Normal Mode:
    --      Shifts the active bit through the register.
    --
    --  Recovery:
    --      Illegal states automatically converge to a legal one-hot state
    --      without external intervention.
    --------------------------------------------------------------------------
    ring_counter_pr : process(clk)
    begin

        if rising_edge(clk) then

            --------------------------------------------------------------
            -- Reset
            --------------------------------------------------------------
            if rst = '1' then

                ring_reg <= '1' &
                            (COUNT_WIDTH-2 downto 0 => '0');

            -- synthesis translate_off

            --------------------------------------------------------------
            -- Simulation Fault Injection
            --------------------------------------------------------------
            elsif debug_load = '1' then

                ring_reg <= debug_value;

            -- synthesis translate_on

            --------------------------------------------------------------
            -- Normal Counter Operation
            --------------------------------------------------------------
            elsif en = '1' then

                ring_reg <= ring_next;

            end if;

        end if;

    end process ring_counter_pr;

end rtl;