
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity display_7seg is
  port(
    clk:             in std_logic;
    nRst:            in std_logic;
    data_rdy:        in std_logic;
    signo:           in std_logic;
    temperatura_spi: in std_logic_vector(7 downto 0);
    T_tic_spi:       in std_logic_vector(3 downto 0);
    cambio_estado:   in std_logic
  );
end entity;

architecture rtl of display_7seg is
  type   t_estado is (centigrados, kelvin, fahrenheit);
  signal estado:   t_estado;
  signal reg_temp: std_logic_vector(8 downto 0);  -- 150+273 = 423K = 1 1010 0111 max

  begin

  process(clk, nRst)
  begin
    if nRst = '0' then
      estado <= centigrados;
    
    elsif clk'event and clk = '1' then
      case estado is

        when centigrados =>
          if cambio_estado = '1' then
            estado <= kelvin;
            if signo = '1' then 
              reg_temp <= 273 - reg_temp;
            
            else
              reg_temp <= reg_temp + 273;

            end if;
          end if;
        
        when kelvin =>
          if cambio_estado = '1' then
            estado <= fahrenheit;

            reg_temp <= reg_temp                        + 
                        ('0'    & reg_temp(7 downto 0)) +
                        ("00"   & reg_temp(6 downto 0)) +
                        ("0000" & reg_temp(4 downto 0));

          end if;

        when fahrenheit =>
          if cambio_estado = '1' then
            estado <= centigrados;
            if signo = '1' then 
              reg_temp <= 32 + reg_temp                   + 
                          ('1'    & reg_temp(7 downto 0)) +
                          ("11"   & reg_temp(6 downto 0)) +
                          ("1111" & reg_temp(4 downto 0));
            
            else
              reg_temp <= 32 + reg_temp                   + 
                          ('0'    & reg_temp(7 downto 0)) +
                          ("00"   & reg_temp(6 downto 0)) +
                          ("0000" & reg_temp(4 downto 0));

            end if;
          end if;
    
      end case;
    end if;
  end process;

  -- Registro temperatura
  process(clk, nRst)
  begin
    if nRst = '0' then
        reg_temp <= (others => '0');

    elsif clk'event and clk = '1' then
      if data_rdy = '1' then
        
      
      end if;
    end if;
  end process;

end rtl;