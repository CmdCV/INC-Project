-- uart_rx.vhd: UART controller - receiving (RX) side
-- Author(s): Aleš Urbánek (xurbana00)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;



-- Entity declaration (DO NOT ALTER THIS PART!)
entity UART_RX is
    port(
        CLK      : in std_logic;
        RST      : in std_logic;
        DIN      : in std_logic;
        DOUT     : out std_logic_vector(7 downto 0);
        DOUT_VLD : out std_logic
    );
end entity;



-- Architecture implementation (INSERT YOUR IMPLEMENTATION HERE)
architecture behavioral of UART_RX is
    signal receive_enable : std_logic;
    signal counter_enable : std_logic;
    signal valid : std_logic;
    signal tick_counter : std_logic_vector(4 downto 0);
    signal bit_counter : std_logic_vector(3 downto 0);
begin
    -- Instance of RX FSM
    fsm: entity work.UART_RX_FSM
    port map (
        CLK => CLK,
        RST => RST,
        DATA_IN => DIN,
        DATA_READ => bit_counter(3),
		COUNTER => tick_counter,
        VALID => valid,
		RECEIVE_ENABLE => receive_enable,
        COUNTER_ENABLE => counter_enable
    );

    main : process(CLK) begin
        if rising_edge(CLK) then
            if RST = '1' then
                tick_counter <= "00000";
                bit_counter <= "0000";
            else
                if counter_enable = '1' then
                    tick_counter <= tick_counter + 1;
                else
                    tick_counter <= "00000";
                end if;
                if receive_enable = '1' then
                    if tick_counter(4) = '1' then -- každých 16 ticků hodin (nevím proč ale tick_counter = "10000" tady nefunguje)
                        tick_counter <= "00001"; -- reset counteru na 1
                        DOUT(conv_integer(bit_counter)) <= DIN; -- nastaví příchozí byt na pozici v DOUT
                        bit_counter <= bit_counter + 1; -- posune pozici bitu
                    end if;
                else 
                    bit_counter <= "0000";
                end if;
            end if;
            DOUT_VLD <= valid;
        end if;
    end process main;
end architecture;