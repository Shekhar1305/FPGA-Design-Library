----------------------------------------------------------------------------------
-- Company      :
-- Engineer     : Shekhar Mishra
--
-- Create Date  : 03.07.2026
-- Design Name  : Generic Timer
-- Module Name  : timer
--
-- Description:
--   Generic timer implementation which generates Seconds and Minutes counters
--   from a high frequency input clock.
--
--   Operation:
--   1. A programmable clock divider generates a one-clock-wide pulse (sen)
--      every MAIN_CLK_COUNT clock cycles.
--   2. The seconds counter increments on every sen pulse.
--   3. When the seconds counter rolls over from 59 to 0, a one-clock-wide
--      minute enable pulse (men) is generated.
--   4. The minutes counter increments on every men pulse.
--
--   Example:
--      Input Clock = 1 MHz
--      MAIN_CLK_COUNT = 1_000_000
--
--      1,000,000 input clocks -> 1 second
--      60 seconds             -> 1 minute
--
-- Features:
--   - Generic clock divider
--   - Clock enable support
--   - Self-recovering divider counter
--   - Synthesizable RTL
--   - FPGA friendly (single clock domain)
--
-- Notes:
--   * This design generates clock enable pulses rather than derived clocks.
--     This is the recommended FPGA design practice.
--
--   * The divider counter uses '<' comparison instead of '='.
--     If the divider counter ever enters an illegal state (for example due
--     to a transient fault or corruption), it automatically recovers by
--     resetting to zero instead of waiting for the natural binary overflow.
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity timer is
    generic(
        MAIN_CLK_COUNT : natural := 100000
    );
    
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           sec : out STD_LOGIC_VECTOR (5 downto 0);
           min : out STD_LOGIC_VECTOR (5 downto 0));
end timer;

architecture Behavioral of timer is

-- Divider counter.
-- Counts input clock cycles from 0 to MAIN_CLK_COUNT-1.
signal r_reg : unsigned(19 downto 0);

-- Seconds and Minutes counters.
-- Range: 0 to 59.
signal s_reg, m_reg : unsigned(5 downto 0);

-- Clock enable pulse generated every MAIN_CLK_COUNT cycles.
signal sen : std_logic;

-- Minute enable pulse generated every 60 seconds.
signal men : std_logic;

begin
--------------------------------------------------------------------
-- Output assignments
--------------------------------------------------------------------
sec <= std_logic_vector(s_reg);
min <= std_logic_vector(m_reg);

--------------------------------------------------------------------
-- Second Enable Pulse
--
-- Generates a single clock wide pulse every MAIN_CLK_COUNT cycles.
--
-- The additional "en='1'" qualification prevents sen from remaining
-- asserted if the timer is disabled while the divider counter is at
-- its terminal count.
--------------------------------------------------------------------
sen <= '1'
       when (r_reg = (MAIN_CLK_COUNT-1) and en='1')
       else '0';

--------------------------------------------------------------------
-- Minute Enable Pulse
--
-- Generates a single clock pulse every 60 seconds.
--------------------------------------------------------------------
men <= '1'
       when (s_reg = 59 and sen='1')
       else '0';
       
--------------------------------------------------------------------
-- Clock Divider
--
-- Divides the input clock by MAIN_CLK_COUNT.
--
-- Counter Sequence:
--
--   0 -> 1 -> 2 -> ... -> MAIN_CLK_COUNT-1 -> 0
--
-- The '<' comparison provides automatic recovery if the counter ever
-- exceeds the programmed terminal count.
--------------------------------------------------------------------

count_process: process(clk, rst)
begin
    if rst = '1' then 
        r_reg <= (others => '0');
    elsif rising_edge(clk) then
        if en = '1' then
            -- Increment until terminal count is reached.
            if r_reg < (MAIN_CLK_COUNT-1) then
                r_reg <= r_reg + 1;
                -- Terminal count reached.
                -- Restart divider from zero.
            else
                r_reg <= (others => '0');
             end if;
        end if;
    end if;
end process count_process;

--------------------------------------------------------------------
-- Seconds Counter
--
-- Increments once for every divider pulse.
--
-- Sequence:
--
--   0 -> 1 -> ... -> 59 -> 0
--------------------------------------------------------------------

sec_process: process(clk, rst)
begin
    if rst = '1' then
        s_reg <= (others => '0');
    elsif rising_edge(clk) then
        if sen = '1' then
            -- Increment until terminal count is reached.
            if s_reg < 59 then
                s_reg <= s_reg + 1;
                -- Terminal count reached.
                -- Restart divider from zero.
            else
                s_reg <= (others => '0');
            end if;
        end if;
     end if;
end process sec_process;

--------------------------------------------------------------------
-- Minutes Counter
--
-- Increments once every 60 seconds.
--
-- Sequence:
--
--   0 -> 1 -> ... -> 59 -> 0
--------------------------------------------------------------------

min_process: process(clk, rst)
begin
    if rst = '1' then
        m_reg <= (others => '0');
    elsif rising_edge(clk) then
        if men = '1' then
        -- Increment until terminal count is reached.
            if m_reg < 59 then
                m_reg <= m_reg + 1;
                -- Terminal count reached.
                -- Restart divider from zero.
            else
                m_reg <= (others => '0');
            end if;
        end if;
     end if;
end process min_process;

end Behavioral;
