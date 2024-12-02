----------------------------------------------------------------------------------
-- Company       : Anadologic
-- Project Name  : 
--
-- Design Name   : -
-- File Name     : top.vhd
-- Tool versions : Vivado 2021.1, VHDL
-- Description   : 
--
--
-- Revision History: 
-- Rev.   Date        Author                 Comment
-- ----   ------      --------               ---------
-- 0v1    23.11.2024  Murat ALKAN          	First Release
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
port (
clk     : in std_logic;
rst     : in std_logic; -- (active-high synchronous reset)
rx_i    : in std_logic; -- (uart receiver port)
tx_o    : out std_logic -- (uart transmitter port)
);
end entity;

architecture behaivoral of top is
        
signal rx_data      : std_logic_vector (7 downto 0) := (others => '0'); 
signal tx_data      : std_logic_vector (7 downto 0) := (others => '0'); 
signal rx_valid     : std_logic := '0';
signal tx_start     : std_logic := '0';
signal tx_done_tick : std_logic := '0';
      
begin

-- UART RX instance
i_uart_rx : entity work.uart_rx
generic map (
c_clkfreq  => 100_000_000,
c_baudrate => 115_200
)
port map (
clk			    => clk,
rx_i		    => rx_i,
dout_o		    => rx_data,
rx_done_tick_o  => rx_valid
);
    
--Message Packet Controller Block   
i_packet_controller : entity work.packet_controller
port map (
clk             => clk ,
rst             => rst,
rx_data_8_i	    => rx_data,
rx_valid_i      => rx_valid,
tx_data_8_o     => tx_data,
tx_start_o      => tx_start,
tx_done_tick_i  => tx_done_tick
);
     
--UART TX instance
i_uart_tx : entity work.uart_tx
generic map (
c_clkfreq  => 100_000_000,
c_baudrate => 115_200,
c_stopbit  => 2
)
port map (
clk				=> clk,
din_i			=> tx_data,
tx_start_i		=> tx_start,
tx_o			=> tx_o,
tx_done_tick_o  => tx_done_tick
);

end architecture;