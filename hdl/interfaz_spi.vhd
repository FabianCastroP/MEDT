

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity interfaz_spi is
  generic (T_CL_toggle : natural := 25);  -- 50MHz/50 = 1MHz -> 25 = semiperiodo
  port(
    clk:         in     std_logic;
    nRst:        in     std_logic;
    tic:         in     std_logic;
    SDAT:        in     std_logic;
    CS:          buffer std_logic;
    CL:          buffer std_logic;
    data_rdy:    buffer std_logic;
    temperatura: buffer std_logic_vector(8 downto 0)  -- Salida no varía hasta data_rdy
  );
end entity;

architecture rtl of interfaz_spi is
  signal   cnt_pulsos_clk: std_logic_vector(5 downto 0);  -- Hasta 25
  signal   cnt_pulsos_CL:  std_logic_vector(3 downto 0);  -- Hasta 9
  signal   fdc_toggle_CL:  std_logic;
  signal   fdc_bits_rd:    std_logic;
  signal   ena_rd:         std_logic;
  signal   stop:           std_logic;
  signal   reg_SDAT:       std_logic_vector(8 downto 0);  -- En C2
  -- constant T_CL_toggle:    natural := 25;                 -- 50MHz/50 = 1MHz -> 25 = semiperiodo
  constant num_bits_rd:    natural := 9;                  -- Numero de bits a leer
                                                          -- 100 MHz/100 = 1MHz
  begin 
  
  -- Flip-flop CS
  process(clk, nRst)
  begin
    if nRst = '0' then
      CS <= '1';

    elsif clk'event and clk = '1' then
      if tic = '1' then
        CS <= '0';

      elsif stop = '1' then
        CS <= '1';
      end if;
     
    end if;
  end process;

  -- Contador pulsos clk
  process(clk, nRst)
  begin
  
    if nRst = '0' then
      cnt_pulsos_clk <= (0 => '1', others => '0');
  
    elsif clk'event and clk = '1' then
      if CS = '0' then
      
        if fdc_toggle_CL = '1' then
          cnt_pulsos_clk <= (0 => '1', others => '0');
          
        else
          cnt_pulsos_clk <= cnt_pulsos_clk + 1;
        
        end if;
      
      else
        cnt_pulsos_clk <= (0 => '1', others => '0');

      end if;
    end if;
  end process;

  -- Fin de cuenta para producir toogle CL tras 25*20ns = 500ns = T_CL/2 con T_clk = 50MHz
  fdc_toggle_CL <= '1' when cnt_pulsos_clk = T_CL_toggle else
                   '0';

  -- Habilita lectura en toggle a CL = '1'
  ena_rd <= '1' when CL = '0' and fdc_toggle_CL = '1' else
            '0';

  -- Contador pulsos CL
  process(clk, nRst)
  begin
  
    if nRst = '0' then
      cnt_pulsos_CL <= (others => '0');
  
    elsif clk'event and clk = '1' then
      if CS = '0' then
        if ena_rd = '1' then
        
          if fdc_toggle_CL = '1' then
            cnt_pulsos_CL <= cnt_pulsos_CL + 1;

          else
            cnt_pulsos_CL <= (0 => '1', others => '0');
          
          end if;
        
        elsif stop = '1' then
          cnt_pulsos_CL <= (others => '0');

        end if;
        
      else
        cnt_pulsos_CL <= (others => '0');

      end if;
    end if;
  end process;
  
  -- Habilitacion para fin comunicacion
  fdc_bits_rd <= '1' when cnt_pulsos_CL = num_bits_rd else
                 '0';
  
  -- Detiene comunicacion
  stop <= '1' when fdc_bits_rd = '1' and fdc_toggle_CL = '1' else
          '0';

  -- Generador CL
  process(clk, nRst)
  begin
  
    if nRst = '0' then
      CL <= '1';

    elsif clk'event and clk = '1' then

      if tic = '1' then
        CL <= '0';
        
      elsif stop = '1' then
        CL <= '1';
      
      elsif fdc_toggle_CL = '1' then
        CL <= not CL;


      end if;
    end if;
  end process;
  
  -- Registro recepcion datos
  process(clk, nRst)
  begin

    if nRst = '0' then
        reg_SDAT <= (others => '0');
    
    elsif clk'event and clk = '1' then

      if tic = '1' then
        reg_SDAT <= (others => '0');
      
      elsif ena_rd = '1' then
        reg_SDAT <= reg_SDAT(7 downto 0) & SDAT;
      
      end if;
    end if;
  end process;

  -- Registro salida datos con conformador de pulso para data_rdy
  process(clk, nRst)
  begin

    if nRst = '0' then
      temperatura <= (others => '0');
      data_rdy    <= '0';
    
    elsif clk'event and clk = '1' then

      if CS = '0' and stop = '1' then
        temperatura <= reg_SDAT;
        data_rdy    <= '1';

      else
        data_rdy <= '0';
      
      end if;
    end if;
  end process;

end rtl;
