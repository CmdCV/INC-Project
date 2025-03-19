-- uart_rx_fsm.vhd: UART controller - finite state machine controlling RX side
-- Author(s): Aleš Urbánek (xurbana00)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;



entity UART_RX_FSM is
    port(
        CLK : in std_logic;
        RST : in std_logic;
        DATA_IN : in std_logic;
        DATA_READ : in std_logic; 
        COUNTER : in std_logic_vector(4 downto 0);

        VALID : out std_logic;
        RECEIVE_ENABLE : out std_logic;
        COUNTER_ENABLE : out std_logic
    );
end entity;



architecture behavioral of UART_RX_FSM is
    type state_of_fsm is (
        WAIT_FOR_START_BIT, 
        WAIT_FOR_FIRST_BIT, 
        READ_DATA_BITS, 
        WAIT_FOR_STOP_BIT, 
        DATA_VALID
        );
    signal state : state_of_fsm := WAIT_FOR_START_BIT;
    signal next_state : state_of_fsm := WAIT_FOR_START_BIT;
begin
    out_setter : process(state) begin
        case state is
            when READ_DATA_BITS => 
                RECEIVE_ENABLE <= '1';
                VALID <= '0';
                COUNTER_ENABLE <= '1';
            when DATA_VALID => 
                RECEIVE_ENABLE <= '0';
                VALID <= '1';
                COUNTER_ENABLE <= '0';
            when WAIT_FOR_START_BIT => 
                RECEIVE_ENABLE <= '0';
                VALID <= '0';
                COUNTER_ENABLE <= '0';
            when others =>
                RECEIVE_ENABLE <= '0';
                VALID <= '0';
                COUNTER_ENABLE <= '1';
        end case;
    end process out_setter;

    state_setter : process(CLK) begin
        if rising_edge(CLK) then
            state <= next_state;
        end if;
    end process state_setter;

    state_controller : process(COUNTER, RST, DATA_IN, state) begin
        if RST = '1' then
            next_state <= WAIT_FOR_START_BIT;
        else
            case state is
                when WAIT_FOR_START_BIT => 
                    if DATA_IN = '0' then
                        next_state <= WAIT_FOR_FIRST_BIT;
                    end if;
                when WAIT_FOR_FIRST_BIT =>
                    if COUNTER = "11000" then -- 24 (8+16) cyklů (Start + MIDBIT)
                        next_state <= READ_DATA_BITS;
                    end if;
                when READ_DATA_BITS =>
                    if DATA_READ = '1' then
                        next_state <= WAIT_FOR_STOP_BIT;
                    end if;
                when WAIT_FOR_STOP_BIT =>
                    if COUNTER = "10000" then -- 16 cyklů (MIDBIT)
                        if DATA_IN = '1' then
                            next_state <= DATA_VALID;
                        end if;
                    end if;
                when DATA_VALID => 
                    next_state <= WAIT_FOR_START_BIT;
            end case;
        end if;
    end process state_controller;
end architecture;