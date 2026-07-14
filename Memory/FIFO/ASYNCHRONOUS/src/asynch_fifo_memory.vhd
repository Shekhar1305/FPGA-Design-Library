----------------------------------------------------------------------------------
-- Company      :
-- Engineer     : Shekhar Mishra
--
-- Create Date  : 14.07.2026
-- Module Name  : asynch_fifo_memory
-- Project Name : FPGA Design Library
-- Target Device: Generic FPGA
--
-- Description:
--
--   Parameterizable Simple Dual-Port (SDP) asynchronous FIFO memory.
--
--   This module implements the storage element for the asynchronous FIFO.
--   Independent write and read ports operate from separate clock domains,
--   allowing simultaneous read and write operations.
--
--   Features:
--     • Parameterizable FIFO depth and data width
--     • Independent write and read clocks
--     • Independent write and read addresses
--     • Synchronous write interface
--     • Synchronous registered read output
--     • FPGA Block RAM inference friendly
--     • Vendor-independent RTL implementation
--
--   Notes:
--     • Memory contents are intentionally not reset to preserve efficient
--       Block RAM inference across FPGA vendors.
--     • This module performs only memory storage.
--     • Full, Empty, Almost Full and Almost Empty detection are implemented
--       by the asynchronous FIFO controller.
--     • The behavior of simultaneous read and write operations to the same
--       memory location is determined by the target FPGA memory primitive
--       and the relative timing of the write and read clocks.
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.basic_package.all;


entity asynch_fifo_memory is
 generic(

        ----------------------------------------------------------------------
        -- Number of memory locations.
        -- FIFO_DEPTH should be a power of two for compatibility with the
        -- FIFO controller.
        ----------------------------------------------------------------------
        FIFO_DEPTH : natural := 16;

        ----------------------------------------------------------------------
        -- Width of each memory word.
        ----------------------------------------------------------------------
        DATA_WIDTH : natural := 16

    );
    port(

        ----------------------------------------------------------------------
        -- System Interface
        ----------------------------------------------------------------------
        clk_wr : in std_logic;   -- Write clock
        clk_rd : in std_logic;   -- Read clock
        -- Write Port
        ----------------------------------------------------------------------
        wr_en   : in std_logic;      -- Write enable
        wr_addr : in std_logic_vector(clog2(FIFO_DEPTH)-1 downto 0);
        data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);

        ----------------------------------------------------------------------
        -- Read Port
        ----------------------------------------------------------------------
        rd_en   : in std_logic;      -- Read enable
        rd_addr : in std_logic_vector(clog2(FIFO_DEPTH)-1 downto 0);

        ----------------------------------------------------------------------
        -- Registered Read Data Output
        ----------------------------------------------------------------------
        data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)

    );
end asynch_fifo_memory;

architecture Behavioral of asynch_fifo_memory is
    --------------------------------------------------------------------------
    -- Design Partitioning
    --
    -- This module implements only the memory array used by the asynchronous
    -- FIFO. All FIFO control logic is intentionally separated into the
    -- asynchronous FIFO controller.
    --
    -- The controller is responsible for:
    --
    --   • Write pointer generation
    --   • Read pointer generation
    --   • Gray-code conversion
    --   • Clock domain synchronization
    --   • Full / Empty flag generation
    --   • Almost Full / Almost Empty flag generation
    --   • Read and write access control
    --
    -- This separation keeps the memory implementation reusable and
    -- independent of FIFO control logic.
    --------------------------------------------------------------------------


    --------------------------------------------------------------------------
    -- Memory Array
    --
    -- Parameterizable memory used as the storage element of the FIFO.
    --
    -- Depending on the target FPGA device and memory depth, synthesis may
    -- infer:
    --
    --   • Block RAM (preferred for larger FIFOs)
    --   • Distributed RAM (for smaller FIFOs)
    --
    -- The memory array is intentionally not reset to preserve efficient RAM
    -- inference across FPGA vendors.
    --------------------------------------------------------------------------
    
    type mem_array is array (FIFO_DEPTH-1 downto 0)
        of std_logic_vector(DATA_WIDTH-1 downto 0);

    signal ram : mem_array;


begin
    --------------------------------------------------------------------------
    -- Write Port
    --
    -- Performs synchronous writes in the write clock domain.
    --
    -- Operation:
    --
    --   • Data is written on the rising edge of CLK_WR.
    --   • A write occurs only when WR_EN = '1'.
    --   • WR_ADDR and DATA_IN shall satisfy setup and hold timing
    --     requirements with respect to CLK_WR.
    --------------------------------------------------------------------------
    ram_wr_pr : process(clk_wr)
    begin

        if rising_edge(clk_wr) then

            if wr_en = '1' then

                ram(to_integer(unsigned(wr_addr))) <= data_in;

            end if;

        end if;

    end process ram_wr_pr;
    --------------------------------------------------------------------------
    -- Read Port
    --
    -- Performs synchronous registered reads in the read clock domain.
    --
    -- Operation:
    --
    --   • Data is sampled on the rising edge of CLK_RD.
    --   • DATA_OUT is updated only when RD_EN = '1'.
    --   • When RD_EN = '0', DATA_OUT retains its previous value.
    --
    -- Notes:
    --
    --   • This module does not define the behavior when a read and write
    --     access the same memory location simultaneously from different
    --     clock domains.
    --
    --   • The returned data is dependent on the target FPGA memory
    --     implementation and the relative timing between CLK_WR and CLK_RD.
    --
    --   • The asynchronous FIFO controller guarantees valid memory accesses
    --     during normal FIFO operation.
    --------------------------------------------------------------------------
    ram_rd_pr : process(clk_rd)
    begin

        if rising_edge(clk_rd) then

            if rd_en = '1' then

                data_out <= ram(to_integer(unsigned(rd_addr)));

            end if;

        end if;

    end process ram_rd_pr;
end Behavioral;
