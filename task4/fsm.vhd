library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm is
  port
  (
    clk   : in std_logic; -- The clock signal.
    reset : in std_logic; -- Reset the module.
    req   : in std_logic; -- Input operand / start computation.
    N     : in std_logic; -- Negative flag.
    Z     : in std_logic; -- Zero flag.

    ack     : out std_logic; -- Computation is complete.
    LDA     : out std_logic; -- Load A register.
    LDB     : out std_logic; -- Load B register.
    ABorALU : out std_logic; -- Select between AB and ALU output.
    FN      : out std_logic_vector(1 downto 0) -- ALU function.
  );
end fsm;

architecture fsm of fsm is
  type state_type is (waiting_for_a, recieved_a, waiting_for_b, recieved_b, checking, done, subtract_into_a, subtract_into_b);

  signal state, next_state : state_type;
begin
  -- Combinatoriel logic

  cl : process (all)
  begin
    -- default assignments
    ack     <= '0'; -- no ack
    LDA     <= '0'; -- switch of new A
    LDB     <= '0'; -- switch of new B
    ABorALU <= '1'; -- default to AB
    FN      <= (others => '0'); -- default to A-B

    case (state) is
      when waiting_for_a => -- state 0 
        if (req = '1') then
          next_state <= recieved_a;
        else
          next_state <= waiting_for_a;
        end if;

      when recieved_a => -- state 1
        if (req = '0') then
          next_state <= waiting_for_b;
        else
          next_state <= recieved_a;
        end if;
        LDA <= '1';
        ack <= '1';

      when waiting_for_b => -- state 2
        if (req = '1') then
          next_state <= recieved_b;
        else
          next_state <= waiting_for_b;
        end if;

      when recieved_b => -- state 3
        next_state <= checking;
        LDB        <= '1';

      when checking => -- state 4
        if (Z = '1') then -- if A-B = 0
          next_state <= done;
        elsif (N = '1') then -- if A-B < 0
          next_state <= subtract_into_b;
        else -- if A-B > 0
          next_state <= subtract_into_a;
        end if;

      when done => -- state 5
        if (req = '0') then
          next_state <= waiting_for_a;
        else
          next_state <= done;
        end if;
        FN      <= "10"; -- set ALU to output A
        ABorALU <= '0'; -- switch to ALU output
        ack     <= '1';

      when subtract_into_a => -- state 6
        next_state <= checking;
        LDA        <= '1'; -- write back A
        ABorALU    <= '0'; -- switch to ALU output

      when subtract_into_b => -- state 7
        next_state <= checking;
        LDB        <= '1'; -- write back B
        ABorALU    <= '0'; -- switch to ALU output
        FN         <= "01"; -- set ALU to B-A

      when others => -- catch all
        next_state <= waiting_for_a;

    end case;
  end process cl;

  -- Registers
  seq : process (clk, reset)
  begin
    if (reset = '1') then
      state <= waiting_for_a;
      elsif (rising_edge(clk)) then
      state <= next_state;
    end if;

  end process seq;
end fsm;