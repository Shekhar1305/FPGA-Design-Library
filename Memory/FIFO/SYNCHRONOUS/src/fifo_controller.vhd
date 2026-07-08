----------------------------------------------------------------------------------
-- Company      :
-- Engineer     : Shekhar Mishra
--
-- Create Date  : 08.07.2026
-- Module Name  : fifo_controller
-- Project Name : FPGA Design Library
-- Target Device: Generic FPGA
--
-- Description:
--
--   Parameterizable synchronous FIFO controller.
--
--   This module implements the control logic required for a synchronous FIFO,
--   including pointer management, occupancy tracking and FIFO status flags.
--   The controller is independent of the storage implementation and can be
--   paired with register arrays, distributed RAM or block RAM.
--
--   Features:
--     • Generic FIFO depth (Power-of-Two only)
--     • Independent read/write pointers
--     • Full and Empty flag generation
--     • Almost Full and Almost Empty flag generation
--     • Simultaneous read/write support
--     • Memory read/write enable generation
--     • FIFO occupancy calculation
--     • Single clock synchronous operation
--
--   Notes:
--     • FIFO_DEPTH must be a power of two.
--     • Full detection uses an extra pointer MSB to distinguish between
--       FULL and EMPTY when address bits are identical.
--     • Simultaneous read and write operations are supported even when
--       the FIFO is FULL or EMPTY, allowing maximum throughput.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.basic_package.all;

entity fifo_controller is

    generic(

        ----------------------------------------------------------------------
        -- FIFO storage depth.
        --
        -- NOTE:
        -- FIFO_DEPTH must be a power of two (2^N).
        ----------------------------------------------------------------------
        FIFO_DEPTH : natural := 16;

        ----------------------------------------------------------------------
        -- Assert Almost Full when the FIFO occupancy reaches or exceeds
        -- this value.
        ----------------------------------------------------------------------
        ALMOST_FULL_THRESHOLD : natural := 14;

        ----------------------------------------------------------------------
        -- Assert Almost Empty when the FIFO occupancy is less than or equal
        -- to this value.
        ----------------------------------------------------------------------
        ALMOST_EMPTY_THRESHOLD : natural := 2

    );

    port(

        ----------------------------------------------------------------------
        -- System Interface
        ----------------------------------------------------------------------
        clk : in std_logic;      -- System clock
        rst : in std_logic;      -- Active-high synchronous reset
        en  : in std_logic;      -- Global controller enable

        ----------------------------------------------------------------------
        -- FIFO Control Interface
        ----------------------------------------------------------------------
        wr_en : in std_logic;    -- Write request
        rd_en : in std_logic;    -- Read request

        ----------------------------------------------------------------------
        -- FIFO Status Flags
        ----------------------------------------------------------------------
        full          : out std_logic;
        almost_full   : out std_logic;
        empty         : out std_logic;
        almost_empty  : out std_logic;

        ----------------------------------------------------------------------
        -- Memory Control Interface
        ----------------------------------------------------------------------
        -- These signals indicate when a memory write/read transaction
        -- is permitted by the controller.
        ----------------------------------------------------------------------
        mem_wr : out std_logic;
        mem_rd : out std_logic;

        ----------------------------------------------------------------------
        -- Memory Address Interface
        ----------------------------------------------------------------------
        wr_ptr : out std_logic_vector(clog2(FIFO_DEPTH)-1 downto 0);
        rd_ptr : out std_logic_vector(clog2(FIFO_DEPTH)-1 downto 0)

    );

end fifo_controller;

architecture Behavioral of fifo_controller is

    --------------------------------------------------------------------------
    -- Extended write pointer.
    --
    -- The extra MSB is used to distinguish between FULL and EMPTY
    -- conditions after pointer wrap-around.
    --------------------------------------------------------------------------
    signal wr_ptr_reg  : unsigned(clog2(FIFO_DEPTH) downto 0);
    signal wr_ptr_next : unsigned(clog2(FIFO_DEPTH) downto 0);

    --------------------------------------------------------------------------
    -- Extended read pointer.
    --------------------------------------------------------------------------
    signal rd_ptr_reg  : unsigned(clog2(FIFO_DEPTH) downto 0);
    signal rd_ptr_next : unsigned(clog2(FIFO_DEPTH) downto 0);

    --------------------------------------------------------------------------
    -- Current FIFO occupancy.
    --
    -- Calculated as the difference between the write and read pointers.
    --------------------------------------------------------------------------
    signal fifo_count : unsigned(clog2(FIFO_DEPTH) downto 0);

    --------------------------------------------------------------------------
    -- Internal status flags.
    --------------------------------------------------------------------------
    signal f_full  : std_logic;
    signal f_empty : std_logic;

    --------------------------------------------------------------------------
    -- Qualified read/write enables.
    --
    -- These signals determine whether the write/read pointers and memory
    -- should advance during the current clock cycle.
    --------------------------------------------------------------------------
    signal wr_allow : std_logic;
    signal rd_allow : std_logic;

begin

    --------------------------------------------------------------------------
    -- Pointer Registers
    --------------------------------------------------------------------------
    pointer_pr : process(clk)
    begin

        if rising_edge(clk) then

            --------------------------------------------------------------
            -- Synchronous Reset
            --------------------------------------------------------------
            if rst = '1' then

                wr_ptr_reg <= (others => '0');
                rd_ptr_reg <= (others => '0');

            --------------------------------------------------------------
            -- Normal FIFO Operation
            --------------------------------------------------------------
            elsif en = '1' then

                wr_ptr_reg <= wr_ptr_next;
                rd_ptr_reg <= rd_ptr_next;

            end if;

        end if;

    end process pointer_pr;

    --------------------------------------------------------------------------
    -- Write Pointer Next-State Logic
    --------------------------------------------------------------------------
    wr_ptr_next <=
        wr_ptr_reg + 1
        when (wr_allow = '1')
        else
        wr_ptr_reg;

    --------------------------------------------------------------------------
    -- FIFO Full Detection
    --
    -- FIFO is FULL when:
    --   • Address bits are identical.
    --   • Pointer MSBs differ.
    --------------------------------------------------------------------------
    f_full <=
        '1'
        when (
                wr_ptr_reg(wr_ptr_reg'left) /=
                rd_ptr_reg(rd_ptr_reg'left)
             and
                wr_ptr_reg(clog2(FIFO_DEPTH)-1 downto 0) =
                rd_ptr_reg(clog2(FIFO_DEPTH)-1 downto 0)
             )
        else
        '0';

    --------------------------------------------------------------------------
    -- Write Permission
    --
    -- A write is allowed when:
    --   • FIFO is not full, or
    --   • A simultaneous read creates space.
    --------------------------------------------------------------------------
    wr_allow <=
        wr_en and
        (
            (not f_full)
            or
            rd_en
        );

    --------------------------------------------------------------------------
    -- Read Permission
    --
    -- A read is allowed when:
    --   • FIFO is not empty, or
    --   • A simultaneous write provides new data.
    --------------------------------------------------------------------------
    rd_allow <=
        rd_en and
        (
            (not f_empty)
            or
            wr_en
        );

    --------------------------------------------------------------------------
    -- Read Pointer Next-State Logic
    --------------------------------------------------------------------------
    rd_ptr_next <=
        rd_ptr_reg + 1
        when (rd_allow = '1')
        else
        rd_ptr_reg;

    --------------------------------------------------------------------------
    -- FIFO Empty Detection
    --------------------------------------------------------------------------
    f_empty <=
        '1'
        when (wr_ptr_reg = rd_ptr_reg)
        else
        '0';

    --------------------------------------------------------------------------
    -- Memory Control Outputs
    --------------------------------------------------------------------------
    mem_wr <= wr_allow;
    mem_rd <= rd_allow;

    --------------------------------------------------------------------------
    -- FIFO Status Outputs
    --------------------------------------------------------------------------
    full  <= f_full;
    empty <= f_empty;

    --------------------------------------------------------------------------
    -- Memory Address Outputs
    --------------------------------------------------------------------------
    wr_ptr <= std_logic_vector(wr_ptr_reg(clog2(FIFO_DEPTH)-1 downto 0));
    rd_ptr <= std_logic_vector(rd_ptr_reg(clog2(FIFO_DEPTH)-1 downto 0));

    --------------------------------------------------------------------------
    -- FIFO Occupancy
    --------------------------------------------------------------------------
    fifo_count <= wr_ptr_reg - rd_ptr_reg;

    --------------------------------------------------------------------------
    -- Almost Full Detection
    --------------------------------------------------------------------------
    almost_full <=
        '1'
        when (fifo_count >= ALMOST_FULL_THRESHOLD)
        else
        '0';

    --------------------------------------------------------------------------
    -- Almost Empty Detection
    --------------------------------------------------------------------------
    almost_empty <=
        '1'
        when (fifo_count <= ALMOST_EMPTY_THRESHOLD)
        else
        '0';

end Behavioral;