library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is
  generic
  (
    bitwidth : natural := 16
  );
  port
  (
    clk   : in std_logic; -- The clock signal.
    reset : in std_logic; -- Reset the module.
    AB    : in unsigned(15 downto 0); -- The two operands.

    ABorALU : in std_logic; -- Select between AB and ALU output.
    LDA     : in std_logic; -- Load A register.
    LDB     : in std_logic; -- Load B register.
    FN      : in std_logic_vector(1 downto 0); -- ALU function.

    C : out unsigned(15 downto 0); -- The result.

    N : out std_logic; -- Negative flag.
    Z : out std_logic -- Zero flag.
  );
end datapath;

architecture comb of datapath is
  signal c_int, reg_a_out, reg_b_out, Y : unsigned(15 downto 0);

  component reg is
    generic
    (
      N : natural := 16
    );
    port
    (
      clk      : in std_logic;
      en       : in std_logic;
      data_in  : in unsigned(15 downto 0);
      data_out : out unsigned(15 downto 0)
    );
  end component;

  component alu is
    generic
    (
      W : natural := 16
    );
    port
    (
      A  : in unsigned(15 downto 0);
      B  : in unsigned(15 downto 0);
      FN : in std_logic_vector(1 downto 0);
      C  : out unsigned(15 downto 0);
      Z  : out std_logic;
      N  : out std_logic
    );
  end component;

  component mux is
    generic
    (
      N : natural := 16
    );
    port
    (
      data_in1 : in unsigned(15 downto 0);
      data_in2 : in unsigned(15 downto 0);
      s        : in std_logic;
      data_out : out unsigned(15 downto 0)
    );
  end component;

  component buf is
    generic
    (
      N : natural := 16
    );
    port
    (
      data_in  : in unsigned(15 downto 0);
      data_out : out unsigned(15 downto 0)
    );
  end component;

begin

  reg_a : reg
  generic
  map (N => bitwidth)
  port map
  (
    clk      => clk,
    en       => LDA,
    data_in  => C_int,
    data_out => reg_a_out
  );

  reg_b : reg
  generic
  map (N => bitwidth)
  port
  map
  (
  clk      => clk,
  en       => LDB,
  data_in  => C_int,
  data_out => reg_b_out
  );

  alu_main : alu
  generic
  map (W => bitwidth)
  port
  map
  (
  A  => reg_a_out,
  B  => reg_b_out,
  fn => FN,
  C  => Y,
  Z  => Z,
  N  => N
  );

  mux_AB_Y : mux
  generic
  map (N => bitwidth)
  port
  map
  (
  data_in1 => Y,
  data_in2 => AB,
  s        => ABorALU,
  data_out => C_int
  );

  output_buffer : buf
  generic
  map (N => bitwidth)
  port
  map
  (
  data_in  => C_int,
  data_out => C
  );

end comb;