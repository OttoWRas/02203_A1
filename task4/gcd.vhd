-- -----------------------------------------------------------------------------
--
--  Title      :  Low level component-based implementation of GCD
--             :
--  Developers :  Jens Sparsø, Rasmus Bo Sørensen and Mathias Møller Bruhn
--                Andreas Lildballe, Otto Westy Rasmussen and Jacob Egebjerg Mouritsen
--           :
--  Purpose    :  This is a FSMD (finite state machine with datapath) 
--             :  implementation the GCD circuit
--             :
--  Revision   :  02203 fall 2024
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

architecture comp_fsmd of gcd is
  signal LDA, LDB, N, Z, ABorALU : std_logic;
  signal FN                      : std_logic_vector(1 downto 0);

begin

  fsm : entity work.fsm
    port map
    (
      clk     => clk,
      reset   => reset,
      req     => req,
      ack     => ack,
      LDA     => LDA,
      LDB     => LDB,
      N       => N,
      Z       => Z,
      ABorALU => ABorALU,
      FN      => FN
    );

  dp : entity work.datapath
    generic
    map (
    bitwidth => 16
    )
    port
    map
    (
    clk     => clk,
    reset   => reset,
    AB      => AB,
    ABorALU => ABorALU,
    LDA     => LDA,
    LDB     => LDB,
    FN      => FN,
    C       => C,
    N       => N,
    Z       => Z
    );

end comp_fsmd;