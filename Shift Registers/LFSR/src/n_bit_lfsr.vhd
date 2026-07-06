----------------------------------------------------------------------------------
-- Company      :
-- Engineer     : Shekhar Mishra
--
-- Create Date  : 06.07.2026
-- Module Name  : n_bit_lfsr
-- Project Name : FPGA Design Library
-- Target Device: Generic FPGA
--
-- Description:
--
--   Parameterizable N-bit Fibonacci Linear Feedback Shift Register (LFSR).
--
--   This implementation supports configurable feedback tap locations through
--   a generic tap mask, allowing different primitive polynomials to be
--   selected without modifying the RTL.
--
--   Unlike a conventional XOR-based LFSR, which generates (2^N - 1) states
--   and excludes the all-zero state, this implementation intentionally inserts
--   the all-zero state into the sequence.
--
--   The transition immediately preceding the normal zero lock-up condition is
--   detected and the feedback bit is temporarily modified so that the sequence
--   becomes:
--
--       ... -> 00001 -> 00000 -> 10000 -> ...
--
--   This enhancement allows the LFSR to traverse all 2^N possible states
--   while maintaining deterministic operation.
--
-- Features:
--   • Generic register width
--   • Generic feedback tap mask
--   • Runtime seed loading
--   • Clock enable
--   • Synchronous active-high reset
--   • Sequence completion indication
--   • Enhanced full-state traversal (2^N states)
--   • Fully synthesizable FPGA-friendly RTL
--
-- Applications:
--   • Pseudo-random sequence generation
--   • Built-In Self Test (BIST)
--   • PRBS generators
--   • Scramblers
--   • Simulation stimulus generation
--   • Digital test pattern generation
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity n_bit_lfsr is

    generic(

        ----------------------------------------------------------------------
        -- Number of stages in the LFSR.
        ----------------------------------------------------------------------
        DATA_WIDTH : natural := 5;

        ----------------------------------------------------------------------
        -- Feedback tap mask.
        --
        -- Each '1' represents a feedback tap used to generate the next
        -- feedback bit.
        --
        -- Example:
        --     DATA_WIDTH = 5
        --     TAP_VALUE  = 16#5#
        ----------------------------------------------------------------------
        TAP_VALUE : natural := 16#5#

    );

    port(

        ----------------------------------------------------------------------
        -- System Interface
        ----------------------------------------------------------------------
        clk : in std_logic;      -- System clock
        rst : in std_logic;      -- Active-high synchronous reset
        en  : in std_logic;      -- Clock enable

        ----------------------------------------------------------------------
        -- Seed Loading
        ----------------------------------------------------------------------
        load_seed : in std_logic;    -- Load external seed
        seed      : in std_logic_vector(DATA_WIDTH-1 downto 0);

        ----------------------------------------------------------------------
        -- Outputs
        ----------------------------------------------------------------------
        lfsr_data : out std_logic_vector(DATA_WIDTH-1 downto 0);

        -- Asserted when the generated sequence returns to the loaded seed.
        lfsr_done : out std_logic

    );

end n_bit_lfsr;

architecture rtl of n_bit_lfsr is

    --------------------------------------------------------------------------
    -- Current LFSR state.
    --------------------------------------------------------------------------
    signal lfsr_reg : std_logic_vector(DATA_WIDTH-1 downto 0);

    --------------------------------------------------------------------------
    -- Next LFSR state.
    --------------------------------------------------------------------------
    signal lfsr_next : std_logic_vector(DATA_WIDTH-1 downto 0);

    --------------------------------------------------------------------------
    -- XOR feedback generated from the selected tap positions.
    --------------------------------------------------------------------------
    signal p_xor : std_logic;

    --------------------------------------------------------------------------
    -- Feedback bit applied to the shift register.
    --------------------------------------------------------------------------
    signal fb : std_logic;

    --------------------------------------------------------------------------
    -- Detects the transition region used to insert the otherwise unreachable
    -- all-zero state into the LFSR sequence.
    --------------------------------------------------------------------------
    signal zero : std_logic;

    --------------------------------------------------------------------------
    -- Feedback XOR Function
    --
    -- Computes the XOR of all register bits selected by the tap mask.
    --
    -- Arguments:
    --      reg  : Current LFSR state.
    --      taps : Feedback tap mask.
    --
    -- Returns:
    --      XOR of all enabled tap positions.
    --------------------------------------------------------------------------
    function feedback_xor(
        reg  : std_logic_vector;
        taps : std_logic_vector
    ) return std_logic is

        variable result     : std_logic := '0';
        variable first_flag : std_logic := '1';

    begin

        for i in reg'range loop

            if taps(i) = '1' then

                if first_flag = '1' then
                    result := reg(i);
                    first_flag := '0';
                else
                    result := result xor reg(i);
                end if;

            end if;

        end loop;

        return result;

    end function;

begin

    --------------------------------------------------------------------------
    -- Output Assignment
    --------------------------------------------------------------------------
    lfsr_data <= lfsr_reg;

    --------------------------------------------------------------------------
    -- Generate XOR feedback from the selected tap positions.
    --------------------------------------------------------------------------
    p_xor <= feedback_xor(
                 lfsr_reg,
                 std_logic_vector(to_unsigned(TAP_VALUE, lfsr_reg'length))
             );

    --------------------------------------------------------------------------
    -- Detect the transition immediately before the normal zero lock-up state.
    --
    -- When asserted, the feedback bit is inverted for one cycle so that the
    -- all-zero state is intentionally inserted into the sequence.
    --------------------------------------------------------------------------
    zero <= '1'
        when unsigned(lfsr_reg(DATA_WIDTH-1 downto 1)) = 0
        else '0';

    --------------------------------------------------------------------------
    -- Modified feedback bit.
    --
    -- Conventional XOR feedback is altered during the transition through the
    -- inserted all-zero state to enable full 2^N-state traversal.
    --------------------------------------------------------------------------
    fb <= p_xor xor zero;

    --------------------------------------------------------------------------
    -- Next-State Logic
    --------------------------------------------------------------------------
    lfsr_next <= fb &
                 lfsr_reg(DATA_WIDTH-1 downto 1);

    --------------------------------------------------------------------------
    -- Sequence Complete Indicator
    --
    -- Asserted whenever the LFSR returns to the loaded seed value.
    --------------------------------------------------------------------------
    lfsr_done <= '1'
        when lfsr_reg = seed
        else '0';

    --------------------------------------------------------------------------
    -- LFSR Register
    --
    -- Reset:
    --      Clears the register.
    --
    -- Load Seed:
    --      Loads the user-supplied initialization value.
    --
    -- Enable:
    --      Advances the LFSR sequence.
    --------------------------------------------------------------------------
    lfsr_shift_pr : process(clk)
    begin

        if rising_edge(clk) then

            if rst = '1' then

                lfsr_reg <= (others => '0');

            elsif load_seed = '1' then

                lfsr_reg <= seed;

            elsif en = '1' then

                lfsr_reg <= lfsr_next;

            end if;

        end if;

    end process lfsr_shift_pr;

end rtl;