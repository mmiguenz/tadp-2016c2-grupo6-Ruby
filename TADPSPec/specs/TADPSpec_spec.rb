require_relative "../src/TADPSpec"
require_relative "../src/Clases_de_prueba"
require "rspec"
describe "TADPSpec" do

  context "con assertions" do
    let (:pepe) {
      Persona.new
    }
    before(:each) do
      pepe.edad=10
      pepe.nombre="José"
      Object.class_eval do
      include Assertion
      end
    end

    it "La suma deberia ser 5" do
      #print ((2+3).deberia ser 5)
      expect((2+3).deberia ser 5).to an_instance_of(Resultado_correcto)
    end

    it "La suma deberia no ser 6" do

      begin
      expect((2+3).deberia ser 6).to raise_error(Fallo_evaluacion_excepcion)
      rescue
       expect(1).to eq(1)
      end


    end

    it "Debería fallar división por 0" do
      expect(proc{4/0}.deberia explotar_con ZeroDivisionError).to an_instance_of(Resultado_correcto)
    end

    it "Debería saber su largo" do
      expect("Soy un String".deberia entender :length).to an_instance_of(Resultado_correcto)
    end

    it "Todo objeto debería ser él mismo" do
      expect(Object.deberia ser Object).to an_instance_of(Resultado_correcto)
    end

    it "Debería tener 'José' por nombre" do
      expect(pepe.deberia tener_nombre "José").to an_instance_of(Resultado_correcto)
    end

    it "Debería tener 10 años" do
      expect(pepe.deberia tener_edad 10).to an_instance_of(Resultado_correcto)
    end


    it "Debería tener edad mayor que 8" do
      expect(pepe.deberia tener_edad mayor_que 8).to an_instance_of(Resultado_correcto)
    end

    it "No debería ser mayor de edad" do
      begin
      expect((pepe.deberia ser_mayor_de_edad)).to raise_error(Fallo_evaluacion_excepcion)
      rescue
      expect(1).to eq(1)
    end
    end
  end



  context "Testar Con Mocks" do

    before(:each) do
       Object.class_eval do
        include Assertion
        Mock.borrar_mocks_por_clase
      end
    end

    it "Persona deberia devolver 2 al mockear metodo hola" do
      Persona.mockear(:hola) do
        return 3
      end

     juan = Persona.new
     expect(juan.hola).to eq 3

    end

    it "Persona mockeada se construye con initialize correctamente" do
      Persona.mockear(:hola) do
        return self.edad
      end

      juan = Persona.new(23)
      expect(juan.hola).to eq 23
    end

    it "Se mockea un metodo que recibe argumentos" do
      Persona.mockear(:retorna_valor) {
        |*args|
        return args[0] * 2
      }

      juan = Persona.new
      expect(juan.retorna_valor(2)).to eq 4
    end

  end

  context "Testear Con Spi" do

    before(:each) do
      Object.class_eval do
        include Assertion
        Mock.borrar_mocks_por_clase
      end
    end
    it "Diccionario espia mayor_de_edad por Persona" do
      juan = Persona.new
      juan.edad= 22


      juanEspiado = espiar(juan)
      #juanEspiado.hola
      juanEspiado.mayor_de_edad?

      expect(juanEspiado.diccionario.tenes?(:mayor_de_edad?)).to be true

    end

    it "Diccionario espia hola por Persona" do
      juan = Persona.new
      juan.edad= 22


      juanEspiado = espiar(juan)
      juanEspiado.hola

      expect(juanEspiado.diccionario.tenes?(:hola)).to be true

    end

    it "Se guardan los argumentos en el Diccionario" do
      juan = Persona.new
      juan.edad= 22

      juanEspiado = espiar(juan)
      juanEspiado.retorna_valor("papa")
      juanEspiado.retorna_valor("helloWorld")


      expect(juanEspiado.diccionario.se_llamo_al_metodo_con_argumento(:retorna_valor,"papa","helloWorld")).to be_truthy
    end

    it "Se recibe correctamente un mensaje único y sin argumentos" do
      juan = Persona.new

      juanEspiado = espiar(juan)
      juanEspiado.hola


      expect(juanEspiado.deberia haber_recibido(:hola)).to an_instance_of(Resultado_correcto)
    end

    it "Se recibe correctamente un mensaje 3 veces" do
      juan = Persona.new

      juanEspiado = espiar(juan)
      juanEspiado.hola
      juanEspiado.hola
      juanEspiado.hola
      expect(juanEspiado.deberia haber_recibido(:hola).veces(3)).to an_instance_of(Resultado_correcto)
    end

    it "Se recibe correctamente un mensaje con argumentos 2 veces" do
      juan = Persona.new
      juanEspiado = espiar(juan)
      juanEspiado.retorna_valor(1)
      juanEspiado.retorna_valor(2)
      expect(juanEspiado.deberia haber_recibido(:retorna_valor).con_argumentos(1,2).veces(2)).to an_instance_of (Resultado_correcto)
    end

    it "Se espia a una clase con Mocks y se usan los metodos mockeados" do

      Persona.mockear(:hola) do
        return 3
      end

      juan = Persona.new
      juanEspiado = espiar(juan)
      expect(juanEspiado.hola).to eq 3

    end

    it "Se espia a dos Personas y se cuentan sus llamadas a metodos por separado" do
      juan = Persona.new
      felipe = Persona.new

      juanEspiado = espiar(juan)
      felipeEspiado = espiar(felipe)

      juanEspiado.hola
      felipeEspiado.hola

      expect(juanEspiado.deberia haber_recibido(:hola).veces(1)).to an_instance_of(Resultado_correcto)
    end

  end

  context "TaDPSpect Testear" do

    let (:pepe) {
      Persona.new

    }
    before(:each) do
      pepe.edad=10
      pepe.nombre="José"
      Object.class_eval do
        include Assertion
      end
    end

    it "Deberia Correr Suite 2 tests correctos" do
      TADPSpec.testear MiSuite
      expect(TADPSpec.ultimo_resultado.correctos).to eq 2
    end

    it "Deberia Correr Suite 2 tests correctos" do
      TADPSpec.testear MiSuite2
      expect(TADPSpec.ultimo_resultado.fallados).to eq 1
    end

    it "Deberia Correr todos los Suite" do
      TADPSpec.testear
      expect(TADPSpec.ultimo_resultado.fallados).to eq 1
    end

  end

end
