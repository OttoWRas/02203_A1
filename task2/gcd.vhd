-- -----------------------------------------------------------------------------
--
--  Title      :  FSMD implementation of GCD
--             :
--  Developers :  Jens Sparsø, Rasmus Bo Sørensen and Mathias Møller Bruhn
--           :
--  Purpose    :  This is a FSMD (finite state machine with datapath) 
--             :  implementation the GCD circuit
--             :
--  Revision   :  02203 fall 2019 v.5.0
--
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gcd is
  port
  (
    clk   : in std_logic; -- The clock signal.
    reset : in std_logic; -- Reset the module.
    req   : in std_logic; -- Input operand / start computation.
    AB    : in unsigned(15 downto 0); -- The two operands.
    ack   : out std_logic; -- Computation is complete.
    C     : out unsigned(15 downto 0)); -- The result.
end gcd;

architecture fsmd of gcd is

  type state_type is (waiting_for_a, recieved_a, waiting_for_b, recieved_b, checking, done, subtract_into_a, subtract_into_b);

  signal reg_a, next_reg_a, next_reg_b, reg_b : unsigned(15 downto 0);

  signal alu_input_1, alu_input_2, alu_result : unsigned(15 downto 0);

  signal state, next_state : state_type;
begin

  -- Combinatoriel logic

  cl : process (req, ab, state, reg_a, reg_b, reset)
  begin
    -- default assignments
    ack        <= '0';
    next_reg_a <= reg_a;
    next_reg_b <= reg_b;
    C          <= (others => 'Z');

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
        next_reg_a <= AB;
        ack        <= '1';

      when waiting_for_b => -- state 2
        if (req = '1') then
          next_state <= recieved_b;
        else
          next_state <= waiting_for_b;
        end if;

      when recieved_b => -- state 3
        next_state <= checking;
        next_reg_b <= AB;

      when checking => -- state 4
        if (reg_a = reg_b) then
          next_state <= done;
        elsif (reg_a > reg_b) then
          next_state <= subtract_into_a;
        else
          next_state <= subtract_into_b;
        end if;

      when done => -- state 5
        if (req = '0') then
          next_state <= waiting_for_a;
        else
          next_state <= done;
        end if;
        C   <= reg_a;
        ack <= '1';

      when subtract_into_a => -- state 6
        next_state <= checking;
        next_reg_a <= reg_a - reg_b;

      when subtract_into_b => -- state 7
        next_state <= checking;
        next_reg_b <= reg_b - reg_a;

      when others => -- catch all
        next_state <= waiting_for_a;

    end case;
  end process cl;

  -- Registers
  seq : process (clk, reset)
  begin
    if (reset = '1') then
      state <= waiting_for_a;
      reg_a <= (others => '0');
      reg_b <= (others => '0');
    elsif (rising_edge(clk)) then
      state <= next_state;
      reg_a <= next_reg_a;
      reg_b <= next_reg_b;
    end if;

  end process seq;
end fsmd;