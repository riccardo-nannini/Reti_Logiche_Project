library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project_reti_logiche is
    port ( 	i_clk : in STD_LOGIC;
			i_start : in STD_LOGIC;
			i_rst : in STD_LOGIC;
			i_data : in STD_LOGIC_VECTOR (7 downto 0);
			o_address : out STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000";
			o_done : out STD_LOGIC := '0';
			o_en : out STD_LOGIC := '0';
			o_we : out STD_LOGIC := '0';
			o_data : out STD_LOGIC_VECTOR (7 downto 0) := "00000000"); 
end project_reti_logiche;

architecture project of project_reti_logiche is

component mem_macchina_stati is
    port ( 	clk_in : in STD_LOGIC;
			rst_in : in STD_LOGIC;
			NEXT_STATE : in STD_LOGIC_VECTOR (3 downto 0);
			CURRENT_STATE : out STD_LOGIC_VECTOR (3 downto 0));
end component;

component difference_calculator is
    port ( 	data_in : in STD_LOGIC_VECTOR (7 downto 0);
			data_type_in : in STD_LOGIC;
			address_data_in : in STD_LOGIC_VECTOR (7 downto 0);
			address_data_out : out STD_LOGIC_VECTOR (7 downto 0);
			difference_result_out : out STD_LOGIC_VECTOR (7 downto 0);
			ff_enable_out : out STD_LOGIC);
end component;

component difference_evaluator is
    port ( 	address_data_in : in STD_LOGIC_VECTOR (7 downto 0);
			difference_result_in : in STD_LOGIC_VECTOR (7 downto 0);
			CURRENT_STATE : in STD_LOGIC_VECTOR (3 downto 0);
			encoded_data_out : out STD_LOGIC_VECTOR (7 downto 0);
			wz_found_out : out STD_LOGIC);
end component;

component gestione_stato is
    port (  start_in : in STD_LOGIC;
            wz_found_in : in STD_LOGIC;
            CURRENT_STATE : in STD_LOGIC_VECTOR (3 downto 0);
            NEXT_STATE : out STD_LOGIC_VECTOR (3 downto 0);
            mem_address_out : out STD_LOGIC_VECTOR (15 downto 0);
            write_enable_out : out STD_LOGIC;
            done_out : out STD_LOGIC;
            enable_wire_out : out STD_LOGIC;
            data_type_out : out STD_LOGIC);
end component;

component flip_flop is
	port ( 	clk_in : STD_LOGIC;
			data_in : in STD_LOGIC_VECTOR (7 downto 0);
			enable_in : in STD_LOGIC;
			data_out : out STD_LOGIC_VECTOR (7 downto 0));
end component;

signal current_state_BUS : STD_LOGIC_VECTOR (3 downto 0);
signal next_state_BUS : STD_LOGIC_VECTOR (3 downto 0);
signal wz_found_BUS : STD_LOGIC := '0';
signal type_signal_BUS : STD_LOGIC;
signal difference_result_BUS : STD_LOGIC_VECTOR (7 downto 0);
signal address_data_2_BUS : STD_LOGIC_VECTOR(7 downto 0);
signal address_data_BUS : STD_LOGIC_VECTOR(7 downto 0);
signal enable_BUS : STD_LOGIC;

begin

FLIP_FLOP_MODULE : flip_flop
		port map (clk_in => i_clk, data_in => address_data_BUS, enable_in => enable_BUS, data_out => address_data_2_BUS);
		
MEM_FSM_MODULE : mem_macchina_stati
        port map (clk_in => i_clk, rst_in => i_rst, NEXT_STATE => next_state_BUS, CURRENT_STATE => current_state_BUS);

DIFFERENCE_CALC_MODULE : difference_calculator 
        port map (data_in => i_data, data_type_in => type_signal_BUS, address_data_in => address_data_2_BUS, address_data_out => address_data_BUS, difference_result_out => difference_result_BUS, ff_enable_out => enable_BUS);
        
DIFFERENCE_EVAL_MODULE : difference_evaluator
        port map (address_data_in => address_data_2_BUS, difference_result_in => difference_result_BUS, CURRENT_STATE => current_state_BUS, encoded_data_out => o_data, wz_found_out => wz_found_BUS);

STATE_MANAGER_MODULE : gestione_stato
        port map (start_in => i_start, wz_found_in => wz_found_BUS, CURRENT_STATE => current_state_BUS, NEXT_STATE => next_state_BUS, 
                  mem_address_out => o_address, write_enable_out => o_we , done_out => o_done, enable_wire_out => o_en, data_type_out => type_signal_BUS);
        
end project;

--------------------------------------------------------------------------------------------------------
--FLIP_FLOP_MODULE
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity flip_flop is 
	port ( 	clk_in : STD_LOGIC;
			data_in : in STD_LOGIC_VECTOR (7 downto 0);
			enable_in : in STD_LOGIC;
			data_out : out STD_LOGIC_VECTOR (7 downto 0));
end flip_flop;

architecture behavioural of flip_flop is
begin	
	process(clk_in, data_in) 
	begin
		if(clk_in'EVENT and clk_in='1') then
			if enable_in = '1' then 
				data_out <= data_in;
			end if;
		end if;
	end process;
end behavioural;

--------------------------------------------------------------------------------------------------------
--MEM_FSM_MODULE
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mem_macchina_stati is
    port ( 	clk_in : in STD_LOGIC;
			rst_in : in STD_LOGIC;
			NEXT_STATE : in STD_LOGIC_VECTOR (3 downto 0);
			CURRENT_STATE : out STD_LOGIC_VECTOR (3 downto 0));
end mem_macchina_stati;

architecture behavioural of mem_macchina_stati is

constant READY : STD_LOGIC_VECTOR (3 downto 0) := "1000";

begin
	process(clk_in, rst_in) 
	begin 
		if(clk_in'EVENT and clk_in='1') then
			if(rst_in = '1') then
				CURRENT_STATE <= READY;
			else
				CURRENT_STATE <= NEXT_STATE;
			end if;
		end if;
	end process;
end behavioural;

--------------------------------------------------------------------------------------------------------
--DIFFERENCE_CALC_MODULE
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity difference_calculator is
    port ( 	data_in : in STD_LOGIC_VECTOR (7 downto 0);
			data_type_in : in STD_LOGIC;
			address_data_in : in STD_LOGIC_VECTOR (7 downto 0);
			address_data_out : out STD_LOGIC_VECTOR (7 downto 0);
			difference_result_out : out STD_LOGIC_VECTOR (7 downto 0);
			ff_enable_out : out STD_LOGIC);
end difference_calculator;

architecture behavioural of difference_calculator is

constant ADDRESS : STD_LOGIC := '0';
constant WZ : STD_LOGIC := '1';

begin
    calcolo : process(data_in, data_type_in) 
	begin	
		case data_type_in is
			when ADDRESS =>
				address_data_out <= data_in;
				ff_enable_out <= '1';
				difference_result_out <= "--------";
			when WZ =>
				if data_in <= address_data_in then
					difference_result_out <= std_logic_vector(UNSIGNED(address_data_in) - UNSIGNED(data_in));
					address_data_out <= "--------";
					ff_enable_out <= '0';
				else 
					difference_result_out <= "11111111"; 
					address_data_out <= "--------";
					ff_enable_out <= '0';
				end if;
			when others =>
				difference_result_out <= "--------"; 
				address_data_out <= "--------";
				ff_enable_out <= '0';
	    end case;
    end process;
end behavioural;

--------------------------------------------------------------------------------------------------------
--DIFFERENCE_EVAL_MODULE
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity difference_evaluator is
    port ( 	address_data_in : in STD_LOGIC_VECTOR (7 downto 0);
			difference_result_in : in STD_LOGIC_VECTOR (7 downto 0);
			CURRENT_STATE : in STD_LOGIC_VECTOR (3 downto 0);
			encoded_data_out : out STD_LOGIC_VECTOR (7 downto 0);
			wz_found_out : out STD_LOGIC);
end difference_evaluator;

architecture behavioural of difference_evaluator is
begin
	process(difference_result_in) 
	begin	
		case difference_result_in is 
			when "00000000" =>
				encoded_data_out <= '1' & CURRENT_STATE(2 downto 0) & "0001";
				wz_found_out <= '1';
			when "00000001" =>
				encoded_data_out <= '1' & CURRENT_STATE(2 downto 0) & "0010"; 
				wz_found_out <= '1';
			when "00000010" =>
				encoded_data_out <= '1' & CURRENT_STATE(2 downto 0) & "0100";
				wz_found_out <= '1';
			when "00000011" =>
				encoded_data_out <= '1' & CURRENT_STATE(2 downto 0) & "1000";
				wz_found_out <= '1';
			when others =>
				encoded_data_out <= address_data_in;
				wz_found_out <= '0';
        end case;
	end process;
end behavioural;

--------------------------------------------------------------------------------------------------------
--STATE_MANAGER_MODULE
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity gestione_stato is
    port (  start_in : in STD_LOGIC;
            wz_found_in : in STD_LOGIC;
            CURRENT_STATE : in STD_LOGIC_VECTOR (3 downto 0);
            NEXT_STATE : out STD_LOGIC_VECTOR (3 downto 0);
            mem_address_out : out STD_LOGIC_VECTOR (15 downto 0);
            write_enable_out : out STD_LOGIC;
            done_out : out STD_LOGIC;
            enable_wire_out : out STD_LOGIC;
            data_type_out : out STD_LOGIC);
end gestione_stato;

architecture behavioural of gestione_stato is

constant WZ0 : STD_LOGIC_VECTOR (3 downto 0) := "0000";
constant WZ1 : STD_LOGIC_VECTOR (3 downto 0) := "0001";
constant WZ2 : STD_LOGIC_VECTOR (3 downto 0) := "0010";
constant WZ3 : STD_LOGIC_VECTOR (3 downto 0) := "0011";
constant WZ4 : STD_LOGIC_VECTOR (3 downto 0) := "0100";
constant WZ5 : STD_LOGIC_VECTOR (3 downto 0) := "0101";
constant WZ6 : STD_LOGIC_VECTOR (3 downto 0) := "0110";
constant WZ7 : STD_LOGIC_VECTOR (3 downto 0) := "0111";
constant READY : STD_LOGIC_VECTOR (3 downto 0) := "1000";
constant ADDR : STD_LOGIC_VECTOR (3 downto 0) := "1001";
constant WAIT_NEXT_START : STD_LOGIC_VECTOR (3 downto 0) := "1010";

begin
	process(CURRENT_STATE, start_in, wz_found_in) 
	begin	
	   case CURRENT_STATE is 
	       when READY =>
	           write_enable_out <= '0';
			   data_type_out <= '-';
			   enable_wire_out <= '1';
	           if start_in = '1' then
	               mem_address_out <= "0000000000001000";
	               NEXT_STATE <= ADDR;
				   done_out <= '0';
	           else
	               NEXT_STATE <= READY;
				   mem_address_out <= "----------------";
				   done_out <= '0';
	           end if;
           when ADDR =>
                data_type_out <= '0';
                mem_address_out <= "0000000000000000";
                NEXT_STATE <= WZ0;
				done_out <= '0';
				enable_wire_out <= '1';
				write_enable_out <= '0';
           when WZ0 =>
                data_type_out <= '1';
				enable_wire_out <= '1';
                if wz_found_in = '0' then
                    mem_address_out <= "0000000000000001";
                    NEXT_STATE <= WZ1;
					done_out <= '0';
					write_enable_out <= '0';
                else
                    write_enable_out <= '1';
                    mem_address_out <= "0000000000001001";
                    done_out <= '0';
                    NEXT_STATE <= WAIT_NEXT_START;
                end if;
           when WZ1 =>
                data_type_out <= '1';
				enable_wire_out <= '1';
                if wz_found_in = '0' then
                    mem_address_out <= "0000000000000010";
                    NEXT_STATE <= WZ2;
					done_out <= '0';
					write_enable_out <= '0';
                else
                    write_enable_out <= '1';
                    mem_address_out <= "0000000000001001";
                    done_out <= '0';
                    NEXT_STATE <= WAIT_NEXT_START;
                end if;
			when WZ2 =>
                data_type_out <= '1';
				enable_wire_out <= '1';
                if wz_found_in = '0' then
                    mem_address_out <= "0000000000000011";
                    NEXT_STATE <= WZ3;
					done_out <= '0';
					write_enable_out <= '0';
                else
                    write_enable_out <= '1';
                    mem_address_out <= "0000000000001001";
                    done_out <= '0';
                    NEXT_STATE <= WAIT_NEXT_START;
                end if;
			when WZ3 =>
                data_type_out <= '1';
				enable_wire_out <= '1';
                if wz_found_in = '0' then
                    mem_address_out <= "0000000000000100";
                    NEXT_STATE <= WZ4;
					done_out <= '0';
					write_enable_out <= '0';
                else
                    write_enable_out <= '1';
                    mem_address_out <= "0000000000001001";
                    done_out <= '0';
                    NEXT_STATE <= WAIT_NEXT_START;
                end if;
			when WZ4 =>
                data_type_out <= '1';
				enable_wire_out <= '1';
                if wz_found_in = '0' then
                    mem_address_out <= "0000000000000101";
                    NEXT_STATE <= WZ5;
					done_out <= '0';
					write_enable_out <= '0';
                else
                    write_enable_out <= '1';
                    mem_address_out <= "0000000000001001";
                    done_out <= '0';
                    NEXT_STATE <= WAIT_NEXT_START;
                end if;
			when WZ5 =>
                data_type_out <= '1';
				enable_wire_out <= '1';
                if wz_found_in = '0' then
                    mem_address_out <= "0000000000000110";
                    NEXT_STATE <= WZ6;
					done_out <= '0';
					write_enable_out <= '0';
                else
                    write_enable_out <= '1';
                    mem_address_out <= "0000000000001001";
                    done_out <= '0';
                    NEXT_STATE <= WAIT_NEXT_START;
                end if;
			when WZ6 =>
                data_type_out <= '1';
				enable_wire_out <= '1';
                if wz_found_in = '0' then
                    mem_address_out <= "0000000000000111";
                    NEXT_STATE <= WZ7;
					done_out <= '0';
					write_enable_out <= '0';
                else
                    write_enable_out <= '1';
                    mem_address_out <= "0000000000001001";
                    done_out <= '0';
                    NEXT_STATE <= WAIT_NEXT_START;
                end if;
			when WZ7 =>
                data_type_out <= '1';
				write_enable_out <= '1';
                mem_address_out <= "0000000000001001";
                done_out <= '0';
				NEXT_STATE <= WAIT_NEXT_START;
				enable_wire_out <= '1';
			when WAIT_NEXT_START =>
				if start_in = '0' then	
					done_out <= '0';
					NEXT_STATE <= READY;
					data_type_out <= '-';
					write_enable_out <= '0';
					mem_address_out <= "0000000000001001";
					enable_wire_out <= '1';
				else	
					NEXT_STATE <= WAIT_NEXT_START;
					done_out <= '1';
					data_type_out <= '-';
					write_enable_out <= '0';
					mem_address_out <= "----------------";
					enable_wire_out <= '1';
				end if;
           when others => 
				NEXT_STATE <= READY;
				done_out <= '0';
				data_type_out <= '-';
				write_enable_out <= '0';
				mem_address_out <= "----------------";
				enable_wire_out <= '0';
       end case;                
	end process;
end behavioural;



