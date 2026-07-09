----------------------------------------------------------------------------------
-- Company      :
-- Engineer     : Shekhar Mishra
--
-- Create Date  : 09.07.2026
-- Module Name  : sync_fifo
-- Project Name : FPGA Design Library
-- Target Device: Generic FPGA
--
-- Description:
--
--   Parameterizable synchronous FIFO.
--
--   This module combines the FIFO controller and FIFO memory into a
--   complete synchronous FIFO with a single clock domain.
--
--   Features:
--     • Parameterizable FIFO depth and data width
--     • Full and Empty status flags
--     • Almost Full and Almost Empty status flags
--     • Simultaneous read/write support
--     • Read-First memory architecture
--     • BRAM inference friendly memory implementation
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.basic_package.all;

entity sync_fifo is

    generic(

        ----------------------------------------------------------------------
        -- FIFO Parameters
        ----------------------------------------------------------------------
        FIFO_DEPTH             : natural := 16;
        DATA_WIDTH             : natural := 16;
        ALMOST_FULL_THRESHOLD  : natural := 14;
        ALMOST_EMPTY_THRESHOLD : natural := 2

    );

    port(

        ----------------------------------------------------------------------
        -- System Interface
        ----------------------------------------------------------------------
        clk : in std_logic;
        rst : in std_logic;

        ----------------------------------------------------------------------
        -- FIFO Interface
        ----------------------------------------------------------------------
        wr_en   : in std_logic;
        rd_en   : in std_logic;
        data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);

        ----------------------------------------------------------------------
        -- Status Flags
        ----------------------------------------------------------------------
        full         : out std_logic;
        almost_full  : out std_logic;
        empty        : out std_logic;
        almost_empty : out std_logic;

        ----------------------------------------------------------------------
        -- FIFO Output
        ----------------------------------------------------------------------
        data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)

    );

end sync_fifo;

architecture Structural of sync_fifo is

    --------------------------------------------------------------------------
    -- Internal Signals
    --------------------------------------------------------------------------
    signal mem_wr : std_logic;
    signal mem_rd : std_logic;

    signal wr_ptr : std_logic_vector(clog2(FIFO_DEPTH)-1 downto 0);
    signal rd_ptr : std_logic_vector(clog2(FIFO_DEPTH)-1 downto 0);

begin

    --------------------------------------------------------------------------
    -- FIFO Controller
    --------------------------------------------------------------------------
    fifo_controller_i : entity work.fifo_controller
    generic map
    (
        FIFO_DEPTH             => FIFO_DEPTH,
        ALMOST_FULL_THRESHOLD  => ALMOST_FULL_THRESHOLD,
        ALMOST_EMPTY_THRESHOLD => ALMOST_EMPTY_THRESHOLD
    )
    port map
    (
        clk           => clk,
        rst           => rst,
        en            => '1',

        wr_en         => wr_en,
        rd_en         => rd_en,

        full          => full,
        almost_full   => almost_full,
        empty         => empty,
        almost_empty  => almost_empty,

        mem_wr        => mem_wr,
        mem_rd        => mem_rd,

        wr_ptr        => wr_ptr,
        rd_ptr        => rd_ptr
    );

    --------------------------------------------------------------------------
    -- FIFO Memory
    --------------------------------------------------------------------------
    fifo_memory_i : entity work.fifo_memory
    generic map
    (
        FIFO_DEPTH => FIFO_DEPTH,
        DATA_WIDTH => DATA_WIDTH
    )
    port map
    (
        clk      => clk,

        wr_en    => mem_wr,
        rd_en    => mem_rd,

        wr_addr  => wr_ptr,
        rd_addr  => rd_ptr,

        data_in  => data_in,
        data_out => data_out
    );

end Structural;