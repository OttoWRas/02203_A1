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
    C     : out unsigned(15 downto 0) -- The result.
  );
end gcd;

-- https://en.wikipedia.org/wiki/Greatest_common_divisor#Binary_GCD_algorithm
-- Could probably do with some operator sharing
architecture binary of gcd is

  type state_type is (waiting_for_a, recieved_a, waiting_for_b, recieved_b, checking, done, divide_both, divide_a, divide_b, subtract_into_a, subtract_into_b);

  signal reg_a, next_reg_a, next_reg_b, reg_b : unsigned(15 downto 0);
  signal reg_d, next_reg_d                    : unsigned(15 downto 0);

  signal reg_a_odd, reg_b_odd, reg_a_equal_b, reg_a_less_b : std_logic;
  signal state, next_state                                 : state_type;

begin
  reg_a_odd     <= reg_a(0);
  reg_b_odd     <= reg_b(0);
  reg_a_equal_b <= '1' when reg_a = reg_b else
    '0';
  reg_a_less_b <= '1' when reg_a < reg_b else
    '0';

  cl : process (req, state, reg_a, reg_b, reg_d, reg_a_odd, reg_b_odd, reg_a_equal_b, reg_a_less_b)
  begin
    -- default assignments
    ack        <= '0';
    next_reg_a <= reg_a;
    next_reg_b <= reg_b;
    next_reg_d <= reg_d;
    C          <= (others => 'Z');

    case (state) is
      when waiting_for_a =>
        if (req = '1') then
          next_state <= recieved_a;
        else
          next_state <= waiting_for_a;
        end if;

      when recieved_a =>
        if (req = '0') then
          next_state <= waiting_for_b;
        else
          next_state <= recieved_a;
        end if;
        next_reg_a <= AB;
        ack        <= '1';

      when waiting_for_b =>
        if (req = '1') then
          next_state <= recieved_b;
        else
          next_state <= waiting_for_b;
        end if;

      when recieved_b =>
        next_state <= checking;
        next_reg_b <= AB;

      when checking =>
        if (reg_a_odd = '0' and reg_b_odd = '0') then -- both are even
          next_state <= divide_both; -- divide both by 2, increment d
        elsif (reg_a_odd = '0' and reg_b_odd = '1') then -- a is even, b is odd
          next_state <= divide_a; -- divide a by 2
        elsif (reg_a_odd = '1' and reg_b_odd = '0') then -- a is odd, b is even
          next_state <= divide_b; -- divide b by 2
        else -- both are odd
          if (reg_a_equal_b = '1') then
            next_state <= done;
          elsif (reg_a_less_b = '1') then
            next_state <= subtract_into_b;
          else -- reg_a > reg_b
            next_state <= subtract_into_a;
          end if;
        end if;

      when done =>
        if (req = '0') then
          next_state <= waiting_for_a;
        else
          next_state <= done;
        end if;
        C          <= reg_a sll to_integer(reg_d);
        next_reg_d <= (others => '0'); -- reset d
        ack        <= '1';

      when divide_both =>
        next_state <= checking;
        next_reg_a <= reg_a srl 1;
        next_reg_b <= reg_b srl 1;
        next_reg_d <= reg_d + 1;

      when divide_a =>
        next_state <= checking;
        next_reg_a <= reg_a srl 1;

      when divide_b =>
        next_state <= checking;
        next_reg_b <= reg_b srl 1;

      when subtract_into_a =>
        next_state <= checking;
        next_reg_a <= reg_a - reg_b;

      when subtract_into_b =>
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
      reg_d <= (others => '0');
    elsif (rising_edge(clk)) then
      state <= next_state;
      reg_a <= next_reg_a;
      reg_b <= next_reg_b;
      reg_d <= next_reg_d;
    end if;

  end process seq;
end binary;