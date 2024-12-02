----------------------------------------------------------------------------------
-- Company       : Anadologic
-- Project Name  : 
--
-- Design Name   : -
-- File Name     : tb_top.vhd
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
use std.textio.all;
use IEEE.std_logic_textio.all;

entity tb_top is
end tb_top;

architecture Behavioral of tb_top is

    component top is
        port (
            clk     : in std_logic;
            rst   : in std_logic; -- (active-high synchronous reset)
            rx_i    : in std_logic; -- (uart receiver port)
            tx_o    : out std_logic -- (uart transmitter port)
        );
    end component;
    
    component uart_rx is
        generic (
            c_clkfreq		: integer := 100_000_000;
            c_baudrate		: integer := 115_200
        );
        port (
            clk				: in std_logic;
            rx_i			: in std_logic;
            dout_o			: out std_logic_vector (7 downto 0);
            rx_done_tick_o	: out std_logic
        );
    end component;
    
    component uart_tx is 
        generic (
            c_clkfreq		: integer := 100_000_000;
            c_baudrate		: integer := 115_200;
            c_stopbit		: integer := 2
        );
        port (
            clk				: in std_logic;
            din_i			: in std_logic_vector (7 downto 0);
            tx_start_i		: in std_logic;
            tx_o			: out std_logic;
            tx_done_tick_o	: out std_logic
        );
    end component;
    
    -- Clock period for 100 MHz 
    constant clk_period     : time := 10 ns; 

    --Top Level Signals
    signal clk              :   std_logic := '0';
    signal rst            :   std_logic := '0';
    signal rx_i             :   std_logic := '1'; -- Idle state is HIGH for UART
    signal tx_o             :   std_logic ;
    
    --Other Signals
    signal tx_start_i       :   std_logic                           := '1';
    signal tx_done_tick_o   :   std_logic                           := '0';
    signal din_i            :   std_logic_vector(7 downto 0)        := (others =>'0'); 
    signal dout_o			:   std_logic_vector (7 downto 0)       := (others =>'0');
    signal rx_done_tick		:   std_logic                           := '0';
    signal test_dout_buf    :   std_logic_vector(5*8-1 downto 0)    := (others => '0');     
    
    constant TEST_FILE_RD :string  := "C:\Users\Murat\PycharmProjects\python_project\test_input.txt" ;
    constant TEST_FILE_WD :string  := "C:\Users\Murat\PycharmProjects\python_project\test_output.txt";
begin

    uut: top
        port map (
            clk  => clk,
            rst  => rst,
            rx_i => rx_i,
            tx_o => tx_o  
        );
    
    uut_tb_tx : uart_tx
        generic map (
            c_clkfreq  => 100_000_000,
            c_baudrate => 115_200,
            c_stopbit  => 2
        )
        port map (
            clk            => clk,
            din_i          => din_i,
            tx_start_i     => tx_start_i,
            tx_o           => rx_i,
            tx_done_tick_o => tx_done_tick_o
        );
       
    uut_tb_rx : uart_rx
        generic map (
            c_clkfreq  => 100_000_000,
            c_baudrate => 115_200
        )
        port map (
            clk            => clk,
            rx_i           => tx_o,
            dout_o         => dout_o,
            rx_done_tick_o => rx_done_tick 
        ); 
       
    -- Clock process
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;
    
    rx_buf_process: process(clk) 
      begin 
            if rising_edge(clk) then
                if (rx_done_tick = '1') then 
                    test_dout_buf(7 downto 0)       <= dout_o;
                    test_dout_buf(5*8-1 downto 1*8) <= test_dout_buf(4*8-1 downto 0);  
                end if;
            end if;                
      end process;
      
    test_process : process
        procedure test_with_pythone_file( constant FILE_NAME_RD : string;
                                          constant FILE_NAME_WD : string ) is
                                                                
            variable input_line   : line;
            variable output_line  : line;
            
            variable header_15_8  : std_logic_vector(7 downto 0);
            variable header_7_0   : std_logic_vector(7 downto 0);
            variable Num1_15_8    : std_logic_vector(7 downto 0);
            variable Num1_7_0     : std_logic_vector(7 downto 0);
            variable Num2_15_8    : std_logic_vector(7 downto 0);
            variable Num2_7_0     : std_logic_vector(7 downto 0);
            variable Opcode       : std_logic_vector(7 downto 0);
            variable checksum     : std_logic_vector(7 downto 0);
            
            file input_file     : text open read_mode is FILE_NAME_RD;
            file output_file    : text open write_mode is FILE_NAME_WD;            
          
        begin
            
            while not endfile(input_file) loop
                
                readline(input_file, input_line);-- Read a row from the text file
                
                hread(input_line,header_15_8);
                hread(input_line,header_7_0 );
                hread(input_line,Num1_15_8  );
                hread(input_line,Num1_7_0   );
                hread(input_line,Num2_15_8  );
                hread(input_line,Num2_7_0   );
                hread(input_line,Opcode     );
                hread(input_line,checksum   );
                
                tx_start_i	<= '0';      din_i <= header_15_8;   wait until tx_done_tick_o = '1';    tx_start_i <= '1';  wait for 2*clk_period; 
                tx_start_i	<= '0';      din_i <= header_7_0;    wait until tx_done_tick_o = '1';    tx_start_i <= '1';  wait for 2*clk_period; 
                tx_start_i	<= '0';      din_i <= Num1_15_8;     wait until tx_done_tick_o = '1';    tx_start_i <= '1';  wait for 2*clk_period; 
                tx_start_i	<= '0';      din_i <= Num1_7_0;      wait until tx_done_tick_o = '1';    tx_start_i <= '1';  wait for 2*clk_period;
                tx_start_i	<= '0';      din_i <= Num2_15_8;     wait until tx_done_tick_o = '1';    tx_start_i <= '1';  wait for 2*clk_period; 
                tx_start_i	<= '0';      din_i <= Num2_7_0;      wait until tx_done_tick_o = '1';    tx_start_i <= '1';  wait for 2*clk_period; 
                tx_start_i	<= '0';      din_i <= Opcode;        wait until tx_done_tick_o = '1';    tx_start_i <= '1';  wait for 2*clk_period;
                tx_start_i	<= '0';      din_i <= checksum;      wait until tx_done_tick_o = '1';    tx_start_i <= '1';  wait for 2*clk_period;
                
                wait until test_dout_buf (5*8-1 downto 3*8) = x"ABCD";
                hwrite(output_line,test_dout_buf);
                writeline(output_file,output_line);
            end loop;

            file_close(input_file);
        end procedure;    
    
    begin 
        -- Initial reset
        rst <= '0';
        wait for 5*clk_period;
        rst  <= '1';
        wait for 5*clk_period;
        rst <= '0';
        wait for 5*clk_period;
    
        test_with_pythone_file(TEST_FILE_RD, TEST_FILE_WD);
        
        wait for 5*clk_period;
		assert FALSE
        report "SIM DONE"
        severity failure;        
        -- End of simulation
    
    end process test_process;
    
end Behavioral;
