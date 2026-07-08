----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08.07.2026 21:12:54
-- Design Name: 
-- Module Name: basic_package - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
package basic_package is


function clog2( n : natural) return natural;



end basic_package;
package body basic_package is
 function clog2( n : natural) return natural is
  begin
     if n <= 1 then
         return 1;
     end if;
     for i in 0 to 30 loop
         if (2 ** i >= n) then
             return i;
         end if;
     end loop;
      return 31; 
 end function clog2;
  
end package body;