require_relative "../src/TADPSpec"
class Persona
  attr_accessor :nombre
  attr_accessor :edad

  def initialize(*args)
    if args[0] != nil
      self.edad= args[0]
    end
  end

  def mayor_de_edad?
    edad>=18
  end

  def hola
    return 1
  end

  def retorna_valor(valor)
    return valor
  end

end

class MiSuite
  def no_deberia_correr
    print "Corrí igual"
  end

  def testear_que_una_mas_uno_da_dos
    (1+1).deberia ser 2
  end

  def testear_que_dos_mas_tres_da_cuatro
    (2+3).deberia ser 4
  end

  def testear_que_una_mas_dos_da_tres
    (1+2).deberia ser 3
  end
end



class MiSuite2

  def testear_que_una_mas_uno_da_dos
    (1+1).deberia ser 2
    (1+1).deberia ser 3
    print 'a'
    (1+1).deberia ser 4
    (1+1).deberia ser 2
    (1+1).deberia ser 2
  end
end
