class Resultado_gral
  attr_accessor :correctos
  attr_accessor :fallados
  attr_accessor :excepciones

  def initialize
    self.correctos =0
    self.fallados =0
    self.excepciones = 0
  end
end

class Resultado
  def imprimir
  end
  def registrarse(resultado)
  end
end

class Resultado_correcto < Resultado
  def imprimir
    print "Resultado Correcto.\n"
  end
  def registrarse(resultado)
    resultado.correctos += 1
    resultado
  end
end

class Fallo_evaluacion < Resultado
  attr_accessor :motivo

  def imprimir
    print "Fallo de evaluación. #{motivo}\n"
  end

  def initialize(motivo)
    self.motivo = motivo
  end

  def registrarse(resultado)
    resultado.fallados += 1
    resultado
  end
end

class Fallo_ejecucion < Resultado
  attr_accessor :excepcion

  def imprimir
    print "Fallo de ejecución. #{excepcion.backtrace} \n"
  end

  def initialize(excepcion)
    self.excepcion=excepcion
  end

  def registrarse(resultado)
    resultado.excepciones += 1
    resultado
  end
end

class Condicion
  attr_accessor :motivo_de_error
  def satisface(obj)
  end
end

class CondicionDeRecepcionMensajes < Condicion
  attr_accessor :simbolo
  attr_accessor :valores
  attr_accessor :cant_veces
  def satisface(obj)
    obj.diccionario.se_llamo_al_metodo_con_argumento(simbolo, valores) and obj.diccionario.cantidad_de_llamados(simbolo) == cant_veces
  end

  def initialize (simbolo)
    self.simbolo = simbolo
    self.cant_veces = 1
    self.valores = []
  end

  def veces(cant)
    self.cant_veces=cant
    return self
  end

  def con_argumentos(*args)
    self.valores=args
    return self
  end
end


class Igualdad < Condicion
  attr_accessor :objeto
  def satisface(obj)
    if (obj.class.eql? objeto.class) and ((obj.eql? objeto) or (objeto.is_a? Class and objeto.is_a? objeto.class))
     return true
    end
    self.motivo_de_error = "Se esperaba #{objeto} y se recibió #{obj}"
    false

  end
end

class Comparacion < Condicion
  attr_accessor :objeto
  attr_accessor :procedimiento
  def satisface(obj)
    if  (procedimiento.call obj, objeto)
      return true
    end
    self.motivo_de_error = "No cumplen comparación. #{obj} y #{objeto}"
    false

  end
end

class Comparacion_encapsulada < Condicion
  attr_accessor :comparacion
  attr_accessor :simbolo
  def satisface(obj)
    if not (comparacion.satisface(obj.send(simbolo)))
      self.motivo_de_error = comparacion.motivo_de_error
    return  false
    end
    true
  end
  def initialize(simbolo,comparacion)
    self.simbolo =simbolo
    self.comparacion =comparacion
  end
end

class Entendimiento < Condicion
  attr_accessor :simbolo
  def satisface(obj)
    if not (obj.respond_to? simbolo)
      self.motivo_de_error = "El objeto #{obj} no entiende el mensaje #{simbolo}"
      return false
    end
    true
  end
end

class Restriccion < Condicion
  attr_accessor :simbolo
  attr_accessor :valor

  def satisface (obj)

    if not(obj.send(simbolo) == valor)
      self.motivo_de_error = "No se cumple la restricción. Se tiene #{obj.send(simbolo)} y #{valor}"
      return false
    end
    true
  end
  def initialize (simbolo, valor)

    self.simbolo = simbolo
    self.valor = valor
  end
end


class Falla < Condicion
  attr_accessor :excepcion
  def satisface(bloq)
    begin
      bloq.call
      self.motivo_de_error = "No explotó la excepción #{excepcion}. Se ejecutó correctamente."
      false
    rescue excepcion => a
      true
    rescue Exception => otraExcepcion
      self.motivo_de_error = "No explotó la excepción #{excepcion}. Otra excepción fue lanzada."
      false
    end
  end

end

class TADPSpec

  @@ultimo_resultado = Resultado_gral.new

  def self.testear(*args)
    case args.length
      when 0
        Object.send(:remove_const, :TimeoutError)
        clases = Object.constants.select { |k| Object.const_get(k).instance_of? Class  }
        suites = clases.select{|clase| es_suite? clase }
        suites.each do |s|
          clase = convertir_en_clase(s)
          ejecutar(clase, obtener_tests(clase))
        end
      when 1
        clase = args[0]
        tests= obtener_tests(clase)
        ejecutar(clase, tests)
      else
        clase = args[0]
        ejecutar(clase, args[1..-1].map {|m| self.convertir_a_formato_test(m)})
    end

  end

  def self.convertir_en_clase(suite)
    Object.const_get(suite[0..-1])
  end

  def self.es_suite? (clase)
    Object.const_get(clase[0..-1]).instance_methods(false).select{|metodo| es_test? metodo }.length > 0
  end

  def self.obtener_tests(suite)
    suite.instance_methods(false).select{|metodo| es_test? metodo }
  end

  def self.es_test? (metodo)
    metodo.to_s.start_with?("testear_que_")
  end

  def self.convertir_a_formato_test(simbolo)
    ('testear_que_'+(simbolo.to_s))
  end

  def self.ejecutar (suite, tests)
    resultado_gral = Resultado_gral.new
    resultado = nil

    tests.each do
    |t|
      objeto = suite.new

     begin
      resultado = objeto.send(t)
     rescue Fallo_evaluacion_excepcion => ex
        resultado =  ex.fallo_evaluacion

     rescue ex
       resultado = Fallo_ejecucion.new(ex)

     ensure
       resultado.imprimir
       resultado_gral = resultado.registrarse(resultado_gral)
       Mock.borrar_mocks_por_clase
     end
    end

    @@ultimo_resultado = resultado_gral
    print "Resultado de conjunto - Correctos : #{resultado_gral.correctos} Fallados : #{resultado_gral.fallados} Errores : #{resultado_gral.excepciones}\n"


    end

  def self.ultimo_resultado
    @@ultimo_resultado
  end
end

class MockPorClase
  attr_accessor :clase, :mocks

  def initialize (clase)
    self.mocks= Array.new
    self.clase= clase
  end

  def agrega_mock (mock)
    self.mocks << mock
  end

  def cantidad_de_mocks
    self.mocks.size
  end

end

class Mock

  @@mocks_por_clase= Set.new

  attr_accessor :simbolo
  attr_accessor :bloque

  def self.agrega(clase, mock)
    n = self.encontrar_mock_por_clase(clase)
    if n != nil
      n.agrega_mock(mock)
    else
      n = MockPorClase.new(clase)
      n.agrega_mock(mock)
      @@mocks_por_clase.add(n)
    end
  end

  def self.cantidad_de_mocks_para(clase)
    n = self.encontrar_mock_por_clase(clase)
    if n != nil
      return n.cantidad_de_mocks
    else
      return 0
    end
  end

  def self.dame_mocks_de(clase)
    n = self.encontrar_mock_por_clase(clase)
    if n != nil
      return n.mocks
    else
      return n
    end
  end

  def self.encontrar_mock_por_clase(clase)
    n = @@mocks_por_clase.find{
        |m|
      m.clase == clase
    }
    return n
  end

  def self.borrar_mocks_por_clase
    @@mocks_por_clase= Set.new
  end

  def setear(simbolo, &bloque)
    self.simbolo =  simbolo
    self.bloque = bloque
  end

end

class Diccionario

  attr_accessor :hash

  def initialize (hash)
    self.hash= hash
  end

  def agrega(n, *args)
    if self.hash.include?(n)
      self.hash[n].te_llamaron(*args)
    else
      metodo = RepositorioArgumentos.new
      metodo.agrega_argumentos(*args)
      self.hash[n] = metodo
    end
  end

  def cantidad_de_llamados(simbolo)
    self.hash.has_key?(simbolo)? repositorio_argumentos = self.hash[simbolo].vecesLlamado : 0
  end

  def tenes?(simbolo)
    return self.hash.has_key?(simbolo)
  end

  def se_llamo_al_metodo_con_argumento(simbolo, *args)
    argumentos = args.first
    if self.hash.has_key?(simbolo) == false
      return false
    end
    return true if argumentos.empty?
    repositorio_argumentos = self.hash[simbolo]
    argumentos.all? {
      |argumento|
      repositorio_argumentos.tenes_argumento?(argumento)
    }
  end
end

class RepositorioArgumentos
  attr_accessor :vecesLlamado
  attr_accessor :argumentos

  def initialize
    self.vecesLlamado= 1
    self.argumentos= Array.new
  end

  def te_llamaron(*args)
    self.vecesLlamado+= 1
    self.agrega_argumentos(*args)
  end


  def agrega_argumentos(*args)
    if args.size == 1
      self.argumentos.concat(Array(args))
    end
    if args.size > 1
      self.argumentos.concat(*args)
    end
  end

  def tenes_argumento?(argumento)
    self.argumentos.include?(argumento)
  end

end

module Assertion

 attr_accessor :prototipo, :diccionario

 def deberia (cond)
      #cond.satisface(self) ? return Resultado_correcto.new: Fallo_evaluacion.new(cond.motivo_de_error)
      #raise cond.motivo_de_error

      return Resultado_correcto.new if (cond.satisface(self))
      raise Fallo_evaluacion_excepcion.new(Fallo_evaluacion.new(cond.motivo_de_error))

  end

  def ser (arg)

    if arg.is_a? Comparacion
      arg
    else
      igualdad = Igualdad.new
      igualdad.objeto = arg
      igualdad
    end
  end

  def entender (metodo)
    entendimiento = Entendimiento.new
    entendimiento.simbolo =metodo
    entendimiento
  end


  def method_missing(simbolo, *arg)
      return  Restriccion.new(simbolo[0..-1],true) if(simbolo.to_s.end_with?("?")) ## es un "ser"
      return  Restriccion.new(simbolo[4..-1]<<"?",true) if simbolo.to_s.start_with?("ser_") ## es un "ser"

      if simbolo.to_s.start_with?("tener_") ## es un "tener"
        return (arg[0].is_a? Comparacion)?
            Comparacion_encapsulada.new(simbolo[6..-1],arg[0])
        : Restriccion.new(simbolo[6..-1], arg[0])
      end

      super

  end

  def mockear (simbolo, &bloque)
    if Mock.cantidad_de_mocks_para(self) == 0
      self.define_singleton_method(:new) {
        |*args|
        if Mock.cantidad_de_mocks_para(self) == 0
          n = super(*args)
          return n
        else
          obj = super(*args)
          mocks = Mock.dame_mocks_de(self)
          mocks.each {
              |n|
            obj.define_singleton_method(n.simbolo, &n.bloque)
          }
          return obj
        end
      }
    end
    mock = Mock.new
    mock.setear(simbolo, &bloque)
    Mock.agrega(self, mock)
  end

  def espiar(obj)
    m = obj.class.new
    m.prototipo= obj
    m.diccionario= Diccionario.new(Hash.new)
    obj.class.instance_methods(false).each{
        |n|
      m.define_singleton_method(n) {
        |*args|
        self.diccionario.agrega(n, *args)
        return self.prototipo.method(n).call *args
      }
    }
    obj.singleton_class.instance_methods(false).each{
        |n|
      m.define_singleton_method(n) {
          |*args|
        self.diccionario.agrega(n, *args)
        return self.prototipo.method(n).call *args
      }
    }
    return m
  end

  def haber_recibido(simbolo)
    CondicionDeRecepcionMensajes.new(simbolo)
  end

end

def mayor_que(valor)
  comparacion = Comparacion.new
  comparacion.objeto = valor
  comparacion.procedimiento = proc {|x| x > valor }
  comparacion
end

def explotar_con(excepcion)
  falla = Falla.new
  falla.excepcion = excepcion
  falla
end


class Fallo_evaluacion_excepcion< RuntimeError

  attr_accessor :fallo_evaluacion

  def initialize(fallo_evaluacion)
    self.fallo_evaluacion = fallo_evaluacion
  end
end
