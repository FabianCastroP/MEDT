
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.pack_paso_temperaturas.all;

entity procesador_temperatura is
  port(
    clk:             in std_logic;
    nRst:            in std_logic;
    data_rdy:        in std_logic;
    temperatura_spi: in std_logic_vector(8 downto 0);
    T_tic_spi:       in std_logic_vector(3 downto 0);
    cambio_unidades:   in std_logic;
    temp_BCD:        buffer std_logic_vector(11 downto 0)
  );
end entity;

architecture rtl of procesador_temperatura is
  type   t_estado is (centigrados, kelvin, fahrenheit);
  signal estado:   t_estado;
  signal reg_temp:        std_logic_vector(9 downto 0);  -- 150+273 = 423K = 1 1010 0111 max
  -- signal temp_kelvin:     std_logic_vector(9 downto 0);
  -- signal temp_fahrenheit: std_logic_vector(9 downto 0);
  -- signal temp_BCD:        std_logic_vector(11 downto 0);

  begin

  process(clk, nRst)
  begin
    if nRst = '0' then
      estado <= centigrados;
      temp_BCD <= (others => '0');
    
    elsif clk'event and clk = '1' then
      case estado is

        when centigrados =>
          if cambio_unidades = '1' then
            estado <= kelvin;

            reg_temp <= centigrados_a_kelvin(temperatura_spi);
            temp_BCD <= temperatura_a_bcd(reg_temp);

          elsif data_rdy = '1' then
            temp_BCD <= temperatura_a_bcd(temperatura_spi(8) & temperatura_spi);
          end if;
        
        when kelvin =>
          if cambio_unidades = '1' then
            estado <= fahrenheit;

            reg_temp <= centigrados_a_fahrenheit(temperatura_spi);
            temp_BCD <= temperatura_a_bcd(reg_temp);

          elsif data_rdy = '1' then
            reg_temp <= centigrados_a_kelvin(temperatura_spi);
            temp_BCD <= temperatura_a_bcd(reg_temp);
          end if;

        when fahrenheit =>
          if cambio_unidades = '1' then
            estado <= centigrados;

            temp_BCD <= temperatura_a_bcd(temperatura_spi(8) & temperatura_spi);
          elsif data_rdy = '1' then
            reg_temp <= centigrados_a_fahrenheit(temperatura_spi);
            temp_BCD <= temperatura_a_bcd(reg_temp);
          end if;
    
      end case;
    end if;
  end process;

end rtl;