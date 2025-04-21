

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity interfaz_spi is
  port(
    clk:   in     std_logic;
    nRst:  in     std_logic;
    tic:   in     std_logic;
    CS:    buffer std_logic;
    CL:    buffer std_logic;
    SDAT:  in std_logic
  );
end entity;

architecture rtl of interfaz_spi is
  type t_estado is (idle, comunicando);
  signal   estado:         t_estado;
  signal   cnt_pulsos_clk: std_logic_vector(5 downto 0);  -- Hasta 25
  signal   cnt_pulsos_CL:  std_logic_vector(5 downto 0);  -- Hasta 16
  signal   ena_CL:         std_logic;
  signal   ena_rd:         std_logic;
  signal   stop:           std_logic;
  signal   reg_SDAT:       std_logic_vector(15 downto 0);
  constant T_CL_toggle:    natural := 25;                 -- 50MHz/50 = 1MHz -> 25 = semiperiodo

  begin 

  -- Maquina de estados para el control de transacciones
  process(clk, nRst)
  begin
    if nRst = '0' then
      estado         <= idle;

    elsif clk'event and clk = '1' then
      case estado is

        when idle =>
          if tic = '1' then
            estado <= comunicando;
          end if;

        when comunicando =>
          if stop = '1' then
            estado <= idle;
          end if;
     
      end case;
    end if;
  end process;

  ena_CL <= '0' when estado = idle else
            '1';

  CS <= '1' when estado = idle else
        '0';

  -- Contador pulsos clk
  process(clk, nRst)
  begin
  
    if nRst = '0' then
      cnt_pulsos_clk <= (others => '0');
  
    elsif clk'event and clk = '1' then
      if ena_CL = '1' and stop = '0' then
      
        if cnt_pulsos_clk < T_CL_toggle then
            cnt_pulsos_clk <= cnt_pulsos_clk + 1;
        
        else
          cnt_pulsos_clk <= (0 => '1', others => '0');
        
        end if;
      
      else
        cnt_pulsos_clk <= (others => '0');

      end if;
    end if;
  end process;

  -- Contador pulsos CL
  process(clk, nRst)
  begin
  
    if nRst = '0' then
      cnt_pulsos_CL <= (others => '0');
  
    elsif clk'event and clk = '1' then
      if ena_CL = '1' and stop = '0' then
        if ena_rd = '1' then
        
          if cnt_pulsos_CL < 16 then
            cnt_pulsos_CL <= cnt_pulsos_CL + 1;
          
          else
            cnt_pulsos_CL <= (0 => '1', others => '0');
          
          end if;

        end if;
      else
        cnt_pulsos_CL <= (others => '0');
      end if;
    end if;
  end process;
  
  stop <= '1' when (cnt_pulsos_CL = 16) and cnt_pulsos_clk = (T_CL_toggle - 1) else
          '0';

  process(clk, nRst)
  begin
  
    if nRst = '0' then
      CL <= '1';

    elsif clk'event and clk = '1' then
      if tic = '1' then
        CL <= '0';

      elsif stop = '1' then
        CL <= '1';

      elsif cnt_pulsos_clk = (T_CL_toggle - 1) then
        CL <= not CL;
      end if;
    end if;
  end process;
  
  ena_rd <= '1' when cnt_pulsos_clk = (T_CL_toggle - 1) and CL = '0' else
            '0';

  -- Registro recepcion datos
  process(clk, nRst)
  begin

    if nRst = '0' then
        reg_SDAT <= (others => '0');
    
    elsif clk'event and clk = '1' then
      if tic = '1' then
        reg_SDAT <= (others => '0');
      elsif ena_rd = '1' then
        reg_SDAT <= reg_SDAT(14 downto 0) & SDAT;
      
      end if;
    end if;
  end process;

end rtl;