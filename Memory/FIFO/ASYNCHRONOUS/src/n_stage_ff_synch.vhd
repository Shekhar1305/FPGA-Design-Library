----------------------------------------------------------------------------------
-- Company      :
-- Engineer     : Shekhar Mishra
--
-- Create Date  : 10.07.2026
-- Module Name  : n_stage_ff_synch
-- Project Name : FPGA Design Library
-- Target Device: Generic FPGA
--
-- Description:
--
--   Generic N-stage flip-flop synchronizer for Clock Domain Crossing (CDC).
--
--   This module synchronizes a single-bit or multi-bit signal from one clock
--   domain into another using a configurable number of cascaded flip-flops.
--
--   Typical applications:
--     • Asynchronous reset synchronization
--     • Gray-coded FIFO pointer synchronization
--     • Status/control signal synchronization
--
--   Features:
--     • Configurable synchronizer depth
--     • Configurable bus width
--     • FPGA synthesis friendly
--     • Vivado ASYNC_REG attribute for improved placement
--
--   Notes:
--     • This module is intended for Gray-coded buses or single-bit control
--       signals only.
--     • It must NOT be used to synchronize arbitrary multi-bit binary buses,
--       as individual bits may be sampled on different clock edges.
--     • A minimum of two synchronization stages is recommended to reduce
--       metastability probability.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity n_stage_ff_synch is

    generic(

        ----------------------------------------------------------------------
        -- Number of synchronization stages.
        -- Two stages are recommended for most FPGA applications.
        ----------------------------------------------------------------------
        STAGES : natural := 2;

        ----------------------------------------------------------------------
        -- Width of the synchronized bus in bits.
        ----------------------------------------------------------------------
        MSB_INDEX : natural := 5

    );

    port(

        ----------------------------------------------------------------------
        -- Destination clock domain.
        ----------------------------------------------------------------------
        clk : in std_logic;

        ----------------------------------------------------------------------
        -- Asynchronous input signal.
        ----------------------------------------------------------------------
        sig_in : in std_logic_vector(MSB_INDEX downto 0);

        ----------------------------------------------------------------------
        -- Synchronized output signal.
        ----------------------------------------------------------------------
        sig_out : out std_logic_vector(MSB_INDEX downto 0)

    );

end n_stage_ff_synch;

architecture Behavioral of n_stage_ff_synch is

    --------------------------------------------------------------------------
    -- Synchronizer register array.
    --
    -- Index STAGES-1 receives the asynchronous input.
    -- Index 0 provides the fully synchronized output.
    --------------------------------------------------------------------------
    type sync_array_t is array (STAGES-1 downto 0)
        of std_logic_vector(MSB_INDEX downto 0);

    signal sync_regs : sync_array_t;

    --------------------------------------------------------------------------
    -- Instruct Vivado to treat these registers as CDC synchronizers.
    --------------------------------------------------------------------------
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of sync_regs : signal is "TRUE";

begin

    --------------------------------------------------------------------------
    -- Prevent illegal generic configurations.
    --------------------------------------------------------------------------
    assert STAGES >= 2
    report "n_stage_ff_synch: STAGES must be greater than or equal to 2."
    severity failure;

    --------------------------------------------------------------------------
    -- Output Assignment
    --------------------------------------------------------------------------
    sig_out <= sync_regs(0);

    --------------------------------------------------------------------------
    -- Synchronizer Pipeline
    --
    -- The asynchronous input is sampled by the last stage and propagated
    -- towards stage 0. Each additional stage further reduces the probability
    -- of metastability reaching downstream logic.
    --------------------------------------------------------------------------
    synch_pr : process(clk)
    begin

        if rising_edge(clk) then

            --------------------------------------------------------------
            -- Capture asynchronous input.
            --------------------------------------------------------------
            sync_regs(STAGES-1) <= sig_in;

            --------------------------------------------------------------
            -- Shift synchronized data through remaining stages.
            --------------------------------------------------------------
            for i in 0 to STAGES-2 loop

                sync_regs(i) <= sync_regs(i+1);

            end loop;

        end if;

    end process synch_pr;

end Behavioral;