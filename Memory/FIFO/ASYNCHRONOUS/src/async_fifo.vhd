----------------------------------------------------------------------------------
-- Company      :
-- Engineer     : Shekhar Mishra
--
-- Create Date  : 14.07.2026
-- Module Name  : async_fifo
-- Project Name : FPGA Design Library
-- Target Device: Generic FPGA
--
-- Description:
--
--   Parameterizable asynchronous FIFO.
--
--   This module combines the asynchronous FIFO controller and memory into
--   a complete dual-clock FIFO suitable for clock domain crossing (CDC)
--   applications.
--
--   Architecture
--
--           +-----------------------------+
--           |     async_fifo_controller   |
--           |                             |
--  wr_en -->|                             |--> mem_wr
--  rd_en -->|                             |--> mem_rd
--           |                             |
--           |          wr_ptr             |
--           |          rd_ptr             |
--           +-------------+---------------+
--                         |
--                         |
--                         v
--           +-----------------------------+
--           |      asynch_fifo_memory     |
--           |                             |
--           |  Dual Clock SDP Memory      |
--           +-----------------------------+
--
--   Features:
--     • Independent write/read clock domains
--     • Gray-code based CDC
--     • Full / Empty protection
--     • Almost Full / Almost Empty flags
--     • Parameterizable FIFO depth
--     • Parameterizable data width
--     • Generic synchronizer depth
--     • Vendor-independent RTL
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.basic_package.ALL;
entity async_fifo is

    generic(

        ----------------------------------------------------------------------
        -- FIFO Parameters
        ----------------------------------------------------------------------
        FIFO_DEPTH : natural := 16;
        DATA_WIDTH : natural := 16;

        ----------------------------------------------------------------------
        -- Status Flag Thresholds
        ----------------------------------------------------------------------
        ALMOST_FULL_THRESHOLD  : natural := 14;
        ALMOST_EMPTY_THRESHOLD : natural := 2;

        ----------------------------------------------------------------------
        -- Synchronizer Stages
        ----------------------------------------------------------------------
        CDC_STAGES : natural := 2

    );

    port(

        ----------------------------------------------------------------------
        -- Write Clock Domain
        ----------------------------------------------------------------------
        clk_wr       : in std_logic;
        rst_wr       : in std_logic;
        wr_domain_en : in std_logic;
        wr_en        : in std_logic;
        data_in      : in std_logic_vector(DATA_WIDTH-1 downto 0);

        ----------------------------------------------------------------------
        -- Read Clock Domain
        ----------------------------------------------------------------------
        clk_rd       : in std_logic;
        rst_rd       : in std_logic;
        rd_domain_en : in std_logic;
        rd_en        : in std_logic;

        ----------------------------------------------------------------------
        -- Read Data
        ----------------------------------------------------------------------
        data_out : out std_logic_vector(DATA_WIDTH-1 downto 0);

        ----------------------------------------------------------------------
        -- FIFO Status
        ----------------------------------------------------------------------
        full         : out std_logic;
        almost_full  : out std_logic;

        empty        : out std_logic;
        almost_empty : out std_logic

    );

end async_fifo;

architecture Structural of async_fifo is

    --------------------------------------------------------------------------
    -- Internal Memory Interface
    --------------------------------------------------------------------------
    signal mem_wr : std_logic;
    signal mem_rd : std_logic;

    signal wr_addr :
        std_logic_vector(clog2(FIFO_DEPTH)-1 downto 0);

    signal rd_addr :
        std_logic_vector(clog2(FIFO_DEPTH)-1 downto 0);

begin

    --------------------------------------------------------------------------
    -- Asynchronous FIFO Controller
    --------------------------------------------------------------------------
    controller_inst : entity work.async_fifo_controller

        generic map(

            FIFO_DEPTH             => FIFO_DEPTH,
            ALMOST_FULL_THRESHOLD  => ALMOST_FULL_THRESHOLD,
            ALMOST_EMPTY_THRESHOLD => ALMOST_EMPTY_THRESHOLD,
            CDC_STAGES             => CDC_STAGES

        )

        port map(

            clk_wr => clk_wr,
            rst_wr => rst_wr,

            clk_rd => clk_rd,
            rst_rd => rst_rd,

            wr_domain_en => wr_domain_en,
            rd_domain_en => rd_domain_en,

            wr_en => wr_en,
            rd_en => rd_en,

            full         => full,
            almost_full  => almost_full,

            empty        => empty,
            almost_empty => almost_empty,

            mem_wr => mem_wr,
            mem_rd => mem_rd,

            wr_ptr => wr_addr,
            rd_ptr => rd_addr

        );

    --------------------------------------------------------------------------
    -- Asynchronous FIFO Memory
    --------------------------------------------------------------------------
    memory_inst : entity work.asynch_fifo_memory

        generic map(

            FIFO_DEPTH => FIFO_DEPTH,
            DATA_WIDTH => DATA_WIDTH

        )

        port map(

            clk_wr => clk_wr,
            clk_rd => clk_rd,

            wr_en => mem_wr,
            wr_addr => wr_addr,
            data_in => data_in,

            rd_en => mem_rd,
            rd_addr => rd_addr,

            data_out => data_out

        );

end Structural;