unit uUnmarshall;
{
  Observação: todo TJSONArray será tratado como um TObjectList<>
  Certifique-se de instanciar todas as variáveis antes de passa-las para a função.
  Faça o TypeCast de retorno nas chamadas;
  Exemplo:
  
  TLoja oJoalheria := TRttiunmarshall.JsonParaObjeto(oJoalheria, oJson) as TLoja;
  TObjectList<TLoja> oShopping := TRttiunmarshall.JsonParaObjeto(oShopping, oJson) as TObjectList<TLoja>;
  
  #o parâmetro Json pode ser enviado como TJSONValue ou String.:
    oJson : TJSONValue;
      ...
    oJson : string;
  
}
interface
uses
System.JSON,  System.Rtti, System.SysUtils, System.Variants, System.Generics.Collections;
type
    TRttiunmarshall = class
    class function JsonParaObjeto(aOBJETO : TOBject ; aJSON : TJSONValue) : TObject; overload;
    class function JsonParaObjeto(aOBJETO : TOBject ; aJSON : string)     : TObject; overload;
end;

implementation

{ TRttiunmarshall }
class function TRttiunmarshall.JsonParaObjeto(aOBJETO : TOBject ; aJSON : TJSONValue): TObject;
var
  rtContexto       : TrttiContext;          // variavel principal de rtti, deve ser iniciada antes de todas as outras
  rtProperty       : TRttiProperty;         // property do atributo a ser preenchido do objeto passado como argumento
  rtMetodo         : TRttiMethod;           // metodo add do TObjectList<> a ser usado em contexto
  rtTipoVarInObjeto: TTypeKind;             // usada no "case of" dentro do "if then" JSONObject, Tipo da Var preencida
  arraysFields     : TArray<TRttiProperty>; // array com o nome das propertys do objeto, coletada no inicio da chamada
  cont, i          : integer;               // variaveis contadoras para os laços for
  strClasse        : string;                // extrai o nome em texto da classe tipada no TObjectList<>
  oJson            : TJSONObject;           // simples conversão para evitar uso de cast do argumento aJSON (caso seja)
  arrayJson        : TJSONArray;            // simples conversão para evitar uso de cast do argumento aJSON (caso seja)
  oList, oRecurr   : TObject;               // variaveis auxiliares usadas quando há listas dentro de objetos ou listas diretas
  oClass           : TClass;                // classe do objeto a ser preenchido, usado para typecast ao adicionar nas listas
begin

     rtContexto := TRttiContext.Create;
  try

     if aJSON is TJSONObject then begin
     FreeAndNil(arraysFields);
     arraysFields := rtContexto.GetType(aOBJETO.ClassType).GetProperties;
        for i := 0 to Length(arraysFields)-1 do
        begin
        {--coleta das variaveis rtti utilizadas--}
        rtProperty := rtContexto.GetType(aOBJETO.ClassType).GetProperty(arraysFields[i].Name);
        rtTipoVarInObjeto := rtProperty.PropertyType.TypeKind;
        {-}
        oJson := aJSON as TJSONObject;

            if oJson.GetValue(arraysFields[i].Name).Value <> 'null' then
            begin
                if oJson.GetValue(arraysFields[i].Name) is  TJSONString then
                begin
                    case rtTipoVarInObjeto of
                         tkInteger, tkInt64:
                               rtProperty.SetValue(aOBJETO, StrToInt(oJson.GetValue(arraysFields[i].Name).Value));
                         tkString, tkUString, tkLString, tkWString:
                               rtProperty.SetValue(aOBJETO, oJson.GetValue(arraysFields[i].Name).Value);
                         tkFloat:
                         begin
                             if rtProperty.PropertyType.ToString = 'TDateTime' then
                                rtProperty.SetValue(aOBJETO, VarToDateTime(oJson.GetValue(arraysFields[i].Name).Value))
                            else
                                rtProperty.SetValue(aOBJETO, StrToFloat(oJson.GetValue(arraysFields[i].Name).Value));
                         end;

                     end;
                end
                else if oJson.GetValue(arraysFields[i].Name) is  TJSONArray then
                begin
                     arrayJson := oJson.GetValue(arraysFields[i].Name) as TJSONArray;
                     strClasse := StringReplace(rtProperty.PropertyType.ToString, 'TOBjectList<', '', [rfReplaceAll, rfIgnoreCase]);
                     strClasse := StringReplace(strClasse, '>', '', [rfReplaceAll, rfIgnoreCase]);
                     oList := rtProperty.GetValue(aOBJETO).AsObject;
                     rtMetodo := rtContexto.GetType(oList.ClassType).GetMethod('Add');

                     for cont := 0 to arrayJson.Count -1 do
                     begin
                         try
                            oClass  := TRttiInstanceType(rtContexto.FindType(strClasse)).MetaclassType;
                            oRecurr := oClass.Create;
                            oRecurr := Self.JsonParaObjeto(oRecurr, arrayJson.Items[cont]);
                            rtMetodo.Invoke(oList, [oRecurr]);
                         finally

                         end;
                     end;
                rtProperty.SetValue(aOBJETO, oList); //adiciona a lista auxiliar no objeto

                end;
            end;

        end;
     end
     else if aJSON is TJSONArray then
     begin
          arrayJson := aJSON as TJSONArray;
          strClasse := StringReplace(aOBJETO.ClassName, 'TOBjectList<', '', [rfReplaceAll, rfIgnoreCase]);
          strClasse := StringReplace(strClasse, '>', '', [rfReplaceAll, rfIgnoreCase]);
          rtMetodo  := rtContexto.GetType(aOBJETO.ClassType).GetMethod('Add');
          for cont  := 0 to arrayJson.Count -1 do
          begin
               oClass  := TRttiInstanceType(rtContexto.FindType(strClasse)).MetaclassType;
               oRecurr := oClass.Create;
               oRecurr := Self.JsonParaObjeto(oRecurr, arrayJson.Items[cont]);
               rtMetodo.Invoke(aOBJETO, [oRecurr]);

          end;
     end;

     Result := aOBJETO;

  finally

    rtContexto.Free;

   end;
end;

class function TRttiunmarshall.JsonParaObjeto(aOBJETO: TOBject; aJSON: string): TObject;
var
  oJSON : TJSONValue;
begin
      oJSON := TJSONObject.ParseJSONValue(aJSON);
      try
          Result := Self.JsonParaObjeto(aOBJETO, oJSON);
      finally
          oJSON.Free;
      end;
end;

end.
