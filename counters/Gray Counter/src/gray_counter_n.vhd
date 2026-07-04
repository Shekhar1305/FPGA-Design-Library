----------------------------------------------------------------------------------
-- Company      :
-- Engineer     : Shekhar Mishra
--
-- Create Date  : 04.07.2026
-- Design Name  : Generic Gray Counter
-- Module Name  : gray_counter_n
--
-- Description:
--   Parameterizable N-bit Gray code counter.
--
--   The counter internally maintains a binary count and continuously
--   converts it to Gray code using the standard Binary-to-Gray equation:
--
--       Gray = Binary XOR (Binary >> 1)
--
--   This implementation is preferred over directly storing Gray code
--   because binary counters efficiently map to the FPGA carry-chain
--   resources, resulting in lower resource utilization and better timing.
--
-- Features:
--   - Parameterizable counter width
--   - Binary counter implemented using FPGA carry chain
--   - Combinational Binary-to-Gray conversion
--   - Clock Enable support
--   - Synchronous Reset
--   - Fully synthesizable
--
-- Applications:
--   - Asynchronous FIFO pointers
--   - Clock Domain Crossing (CDC)
--   - Rotary encoders
--   - Position encoders
--   - State sequencing
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity gray_counter_n is
    generic(
        -- Width of the binary/Gray counter
        COUNT_WIDTH : natural := 4
    );

    port(
        clk       : in  std_logic;    -- System clock
        rst       : in  std_logic;    -- Active-high synchronous reset
        en        : in  std_logic;    -- Counter enable
        count_out : out std_logic_vector(COUNT_WIDTH-1 downto 0)
    );
end gray_counter_n;

architecture Behavioral of gray_counter_n is

    --------------------------------------------------------------------------
    -- Internal binary counter register.
    --
    -- The counter state is intentionally stored in binary because increment
    -- operations map directly onto the FPGA carry-chain, providing the most
    -- area and timing efficient implementation.
    --------------------------------------------------------------------------
    signal binary_count_reg : unsigned(COUNT_WIDTH-1 downto 0);

    --------------------------------------------------------------------------
    -- Combinational Gray code representation of the binary counter.
    --
    -- Gray = Binary XOR (Binary >> 1)
    --
    -- Only one output bit changes between consecutive count values.
    --------------------------------------------------------------------------
    signal gray_count : unsigned(COUNT_WIDTH-1 downto 0);

begin

    --------------------------------------------------------------------------
    -- Binary to Gray Code Conversion
    --------------------------------------------------------------------------
    gray_count <= binary_count_reg xor
                  ('0' & binary_count_reg(COUNT_WIDTH-1 downto 1));

    --------------------------------------------------------------------------
    -- Output Assignment
    --------------------------------------------------------------------------
    count_out <= std_logic_vector(gray_count);

    --------------------------------------------------------------------------
    -- Binary Counter Register
    --
    -- Operation:
    --   * Reset clears the binary counter.
    --   * When enabled, the binary counter increments on every rising edge
    --     of the input clock.
    --   * The Gray code output is generated combinationally from the current
    --     binary count.
    --
    -- Counter Sequence (Binary):
    --
    --   0000
    --   0001
    --   0010
    --   0011
    --   ...
    --
    -- Corresponding Gray Sequence:
    --
    --   0000
    --   0001
    --   0011
    --   0010
    --   0110
    --   ...
    --
    --------------------------------------------------------------------------
    binary_counter_pr : process(clk)
    begin

        if rising_edge(clk) then

            if rst = '1' then

                binary_count_reg <= (others => '0');

            elsif en = '1' then

                binary_count_reg <= binary_count_reg + 1;

            end if;

        end if;

    end process binary_counter_pr;

end Behavioral;