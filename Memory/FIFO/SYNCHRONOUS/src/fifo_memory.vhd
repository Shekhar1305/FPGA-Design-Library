----------------------------------------------------------------------------------
-- Company      :
-- Engineer     : Shekhar Mishra
--
-- Create Date  : 09.07.2026
-- Module Name  : fifo_memory
-- Project Name : FPGA Design Library
-- Target Device: Generic FPGA
--
-- Description:
--
--   Parameterizable Simple Dual-Port (SDP) synchronous FIFO memory.
--
--   This module provides the storage element for the synchronous FIFO IP.
--   Independent write and read ports operate on the same clock, allowing
--   simultaneous read and write operations.
--
--   Features:
--     • Generic FIFO depth and data width
--     • Independent write and read addresses
--     • Synchronous write interface
--     • Synchronous registered read output
--     • Read-First behavior during read/write collisions
--     • FPGA Block RAM inference friendly
--
--   Notes:
--     • Memory contents are intentionally not reset to maximize Block RAM
--       inference across FPGA devices.
--     • The read output retains its previous value when RD_EN = '0'.
--     • Intended for use with the fifo_controller module.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.basic_package.all;

entity fifo_memory is

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
        DATA_WIDTH : natural := 16;
        ----------------------------------------------------------------------
        -- Memory Write and Read Feature.
        ----------------------------------------------------------------------
        READ_MODE : string := "READ_FIRST"
    );

    port(

        ----------------------------------------------------------------------
        -- System Clock
        ----------------------------------------------------------------------
        clk : in std_logic;

        ----------------------------------------------------------------------
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

end fifo_memory;

architecture Behavioral of fifo_memory is

    --------------------------------------------------------------------------
    -- Memory declaration.
    --
    -- This memory array can infer FPGA Block RAM or Distributed RAM
    -- depending on the target device and synthesis settings.
    --------------------------------------------------------------------------
    type mem_array is array (FIFO_DEPTH-1 downto 0)
        of std_logic_vector(DATA_WIDTH-1 downto 0);

    signal ram : mem_array;

begin

    --------------------------------------------------------------------------
    -- Write Port
    --
    -- Performs synchronous writes into memory.
    --
    -- Write occurs when:
    --   • WR_EN = '1'
    --------------------------------------------------------------------------
    ram_wr_pr : process(clk)
    begin

        if rising_edge(clk) then

            if wr_en = '1' then

                ram(to_integer(unsigned(wr_addr))) <= data_in;

            end if;

        end if;

    end process ram_wr_pr;

    --------------------------------------------------------------------------
    -- Read Port
    --
    -- Performs synchronous registered reads.
    --
    -- Features:
    --   • Independent read address
    --   • Registered read output
    --   • Read enable
    --   • Read-First behavior during simultaneous read/write to the same
    --     address
    --
    -- Notes:
    --   • When RD_EN = '0', DATA_OUT retains its previous value.
    --   • During a simultaneous read and write to the same address,
    --     the previous memory contents are presented on DATA_OUT
    --     (Read-First behavior).
    --------------------------------------------------------------------------
    ram_rd_pr : process(clk)
    begin

        if rising_edge(clk) then

            if rd_en = '1' then

                data_out <= ram(to_integer(unsigned(rd_addr)));

            end if;

        end if;

    end process ram_rd_pr;

end Behavioral;