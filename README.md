# Rtti-unmarshall-manual
A beta Rtti Json Unmarshall

* All Arrays into the JSON is transformed in a TObjectList<*T*> Var. With all your special features!
## Requisitos para funcionamento ##

* O nome de todas as properties do objeto a ser preenchido pelo argumento json devem ser idênticas aos campos 'chave' do mesmo.

* Todo objeto a ser passado como argumento deve ser devidamente instanciado ( ser diferente de nil).

* Você continua responsável por dar Free em seus objetos.

***TLoja** oJoalheria := TRttiunmarshall.JsonParaObjeto(oJoalheria, oJson) as **TLoja;***
  
*TObjectList<**TLoja**> oShopping := TRttiunmarshall.JsonParaObjeto(oShopping, oJson) as TObjectList<**TLoja**>;*
