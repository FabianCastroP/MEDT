-- Circuito encargado de la temporizacion para la lectura de la temperatura 
-- Temporizacion: 2, 4, 6 y 8 segundos.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity temporizador_lectura is
  generic (periodo_2s : natural := 100000000);
  port(
    clk:           in     std_logic;
    nRst:          in     std_logic;
    cambio_estado: in     std_logic;  -- key0
    tic_spi:       buffer std_logic;                    -- Habilitacion comunicacion SPI
    T_tic_spi:     buffer std_logic_vector(3 downto 0)  -- Periodo en binario natural
  );
end entity;

architecture rtl of temporizador_lectura is
  type     t_estado is (T_2s, T_4s, T_6s, T_8s);
  signal   estado:         t_estado;
  signal   cnt_pulsos_clk: std_logic_vector(26 downto 0);  -- 100M
  signal   cnt_2seg:       std_logic_vector(2 downto 0);   -- Veces que se alcanzan 2 seg (1 a 4)


begin

  -- Maquina de estados seleccion temporizacion
  process(clk, nRst)
  begin
  
    if nRst = '0' then
      estado <= T_4s;  -- Hito 1
      T_tic_spi <= "0100";
  
    elsif clk'event and clk = '1' then
      case estado is

        when T_2s =>
          if cambio_estado = '1' then
            estado <= T_4s;
            T_tic_spi <= "0100";
          end if;

        when T_4s =>
          if cambio_estado = '1' then
            estado <= T_6s;
            T_tic_spi <= "0110";
          end if;

        when T_6s =>
          if cambio_estado = '1' then
            estado <= T_8s;
            T_tic_spi <= "1000";
          end if;

        when T_8s =>
          if cambio_estado = '1' then
            estado <= T_2s;
            T_tic_spi <= "0010";
          end if;

      end case;
    end if;
  end process;

  -- Contador pulsos clk
  process(clk, nRst)
  begin
  
    if nRst = '0' then
      cnt_pulsos_clk <= (others => '0');
  
    elsif clk'event and clk = '1' then
      if cambio_estado = '1' then
        cnt_pulsos_clk <= (0 => '1', others => '0');

      elsif cnt_pulsos_clk = periodo_2s then
        cnt_pulsos_clk <= (0 => '1', others => '0');
      
      else
        cnt_pulsos_clk <= cnt_pulsos_clk + 1;
      
      end if;
    end if;
  end process;

  -- Contador veces que se alcanzan 2 seg hasta llegar 
  -- al periodo actual de lectura sensor
  process(clk, nRst)
  begin
  
    if nRst = '0' then
      cnt_2seg <= (others => '0');
  
    elsif clk'event and clk = '1' then
      if cambio_estado = '1' then
        cnt_2seg <= (others => '0');

      elsif cnt_pulsos_clk = periodo_2s - 1 then
          cnt_2seg <= cnt_2seg + 1;

      elsif cnt_2seg = T_tic_spi(3 downto 1) then
         cnt_2seg <= (others => '0');

      end if;
    end if;
  end process;

 tic_spi <= '1' when cnt_2seg = T_tic_spi(3 downto 1) else
            '0';

end rtl;