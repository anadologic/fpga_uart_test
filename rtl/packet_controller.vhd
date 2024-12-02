----------------------------------------------------------------------------------
-- Company       : Anadologic
-- Project Name  : 
--
-- Design Name   : -
-- File Name     : packet_controller.vhd
-- Tool versions : Vivado 2021.1, VHDL
-- Description   : 
--
--
-- Revision History: 
-- Rev.   Date        Author                 Comment
-- ----   ------      --------               ---------
-- 0v1    23.11.2024  Murat ALKAN          	First Release
--
------------------------------- Notes ----------------------------------------------- 
-- Message 0xBACD001000200049 Response: 0xABCD003058
-- Message 0xBACD001000200148 Response: 0xABCDFFF099

-- Example incoming message: 0xBACD001000200049
-- 0xBACD: Header
-- 0x0010: Num1 (decimal 16)
-- 0x0020: Num2 (decimal 32)
-- 0x00: Opcode
-- 0x49: Checksum
-- Adding them all results in 0x200.

-- When this message is received, the required operation will be performed, 
-- and the result will be returned in the following format:
-- Header: 0xABCD
-- Result: 2 bytes
-- Checksum: 1 byte
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
 
entity packet_controller is
port (
clk             : in std_logic;
rst             : in std_logic;  
rx_valid_i      : in std_logic;
tx_done_tick_i  : in std_logic;
rx_data_8_i	    : in std_logic_vector (7 downto 0);
tx_start_o      : out std_logic;
tx_data_8_o     : out std_logic_vector(7 downto 0)
);
end packet_controller ;
  
architecture Behavioral of packet_controller is

-- STATES
type state_type is (S_IDLE, S_RECV_CHECKSUM, S_XMIT_CHECKSUM, S_RESPONSE_READY);
signal state : state_type := S_IDLE;

-- CONSTANTS
constant c_header_1       : std_logic_vector(15 downto 0) := x"BACD";
constant c_header_2       : std_logic_vector(15 downto 0) := x"ABCD";
constant zero             : std_logic_vector(7 downto 0)  := (others => '0');

-------------------Some notes about Digital Design----------------------------
-- always know what will synthesize a signal definition, FF or LUT 
-- any signal assigned in a clocked process will infer FF (left hand side of a <= assignment)
-- any signal assigned in a non-clocked (combinational) process will infer comb logic, which means LUT 
-- any signal assigned outside a process will infer combinational assignment (no FF)
-- always give initial assignment to every signal
-------------------------------------------------------------------------------
signal data_buffer      : std_logic_vector (8*8-1 downto 0) := (others => '0');
signal num1             : std_logic_vector (15 downto 0)    := (others => '0');
signal num2             : std_logic_vector (15 downto 0)    := (others => '0');
signal opcode           : std_logic_vector (7 downto 0)     := (others => '0');
signal checksum         : std_logic_vector (7 downto 0)     := (others => '0');
signal result           : std_logic_vector (15 downto 0)    := (others => '0');
--------------------------------------------------------------------------------
-- in simulation testbench you can use integer without range constraint since it does not syntehsize 
-- in synthesis RTL code you HAVE TO use range constraint for integer data types 
-- otherwise it will synthesize 32-bit FF register 
--------------------------------------------------------------------------------
signal  checksum_calculation     : std_logic_vector (7 downto 0)     := (others => '0');
signal  xmit_buffer              : std_logic_vector (4*8-1 downto 0) := (others => '0');
signal  xmit_checksum            : std_logic_vector (7 downto 0)     := (others => '0');
signal  counter_for_transmit     : integer range 0 to 4              := 4;

begin
      
P_MAIN : process (clk) 
    variable temp_sum : integer := 0; -- Variable to accumulate sum       
begin 
   
if (rising_edge(clk)) then

    if (rst = '1') then
        data_buffer             <= (others => '0');
        num1                    <= (others => '0');
        num2                    <= (others => '0');
        opcode                  <= (others => '0');
        checksum                <= (others => '0');
        result                  <= (others => '0');
        checksum_calculation    <= (others => '0');
        xmit_buffer             <= (others => '0');
        state                   <= s_IDLE;
        counter_for_transmit    <= 4;
        tx_start_o	            <= '0';
    else  
    
    case state is
    ------------------------------------------------------------------------
    when s_IDLE =>
        
        if (rx_valid_i = '1') then 
            data_buffer(7 downto 0)       <= rx_data_8_i;
            data_buffer(8*8-1 downto 1*8) <= data_buffer(7*8-1 downto 0);  
        end if;
        
        if data_buffer (8*8-1 downto 6*8) = c_header_1 then -- x"BACD"                
            state <= s_RECV_CHECKSUM;                
            for i in 0 to 7 loop    -- Loop through each byte in the binary_read       
                temp_sum := temp_sum + to_integer(unsigned(data_buffer(i*8 + 7 downto i*8))); -- Extract each byte and add to the temporary sum
            end loop;           
            -- Assign the final checksum value
            checksum_calculation    <= std_logic_vector(to_unsigned(temp_sum mod 256, 8)); -- Ensures result fits in 8 bits
            num1                    <= data_buffer(6*8-1 downto 4*8);   
            num2                    <= data_buffer(4*8-1 downto 2*8);
            opcode                  <= data_buffer(2*8-1 downto 1*8);
            checksum                <= data_buffer(1*8-1 downto 0*8);                
        else 
            state <= s_IDLE;
        end if;
        
        counter_for_transmit    <=  4 ;
        tx_start_o	            <= '0';
    ------------------------------------------------------------------------
    when s_RECV_CHECKSUM =>
    
        data_buffer <= (others => '0');
        
        if (checksum_calculation = x"00") then                
            state <= s_XMIT_CHECKSUM;                
            if opcode =  x"00" then 
                result <= std_logic_vector(signed(num1) + signed(num2));                      
            elsif opcode =  x"01" then
                result <= std_logic_vector(signed(num1) - signed(num2));             
            end if;
        else
            state <= s_IDLE;
        end if;
    ------------------------------------------------------------------------
    when s_XMIT_CHECKSUM =>          

        xmit_buffer <= c_header_2(1*8-1 downto 0*8) & result & xmit_checksum; 
        tx_data_8_o <= c_header_2(2*8-1 downto 1*8);
        tx_start_o  <= '1';
        state       <= S_RESPONSE_READY;
    ------------------------------------------------------------------------
    when S_RESPONSE_READY =>    
        
        tx_start_o  <= '0';

        if (tx_done_tick_i = '1') then
            if (counter_for_transmit = 0) then
                state       <= S_IDLE;
            else
                tx_data_8_o             <= xmit_buffer(counter_for_transmit*8-1 downto (counter_for_transmit-1)*8);
                tx_start_o	            <= '1';
                counter_for_transmit    <= counter_for_transmit - 1;                 
            end if;
        end if;

    end case;
end if;

end if;
end process;

xmit_checksum <= std_logic_vector(unsigned(zero) 
                - unsigned(std_logic_vector(to_unsigned((to_integer(unsigned(c_header_2(15 downto 8))) + to_integer(unsigned(c_header_2(7 downto 0))) 
                + to_integer(unsigned(result(15 downto 8)))
                + to_integer(unsigned(result(7 downto 0)))) mod 256, 8))));
   
end architecture;