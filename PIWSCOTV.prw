#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.ch"
#include "TbiConn.ch"
#include "TbiCode.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "FWMVCDEF.CH"
#Define  _CRLF  CHR(13)+CHR(10)
//--------------------------------------------------------------------------------------
/*/
{Protheus.doc} PIWSCOTV
Fonte reservado rest.

@author		.iNi Sistemas - LTN
@since     	22/03/2023	
@version  	P.12
@return    	Nenhum
@obs        Nenhum

Alterções Realizadas desde a Estruturação Inicial
------------+-----------------+---------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+---------------------------------------------------------
/*/
//--------------------------------------------------------------------------------------- 
User Function PIWSCOTV()

Return()

//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} incluiCotacao
Web Service Rest 
@author		.iNi Sistemas
@since     	22/03/2023	
@version  	P.12
@param 		c_fil - Filial a ser incluido ou alterada a cotação de vendas
@return    	Nenhum
@obs        Serviço REST para ambiente WEB
Alterações Realizadas desde a Estruturação Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
WSRESTFUL incluiCotacao DESCRIPTION "Serviço REST - Cotação de vendas" FORMAT "application/json;charset=UTF-8,text/hml"
		
	WSDATA c_fil 		AS STRING OPTIONAL
	WSMETHOD POST DESCRIPTION "Recebe dados e cadastra/altera Cotação de Vendas" WSSYNTAX "/incluiCotacao?c_fil={param}" PATH "incluiCotacao"

END WSRESTFUL


//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} alteraCotacao
Web Service Rest 
@author		.iNi Sistemas
@since     	22/03/2023	
@version  	P.12
@param 		c_fil - Filial a ser incluido ou alterada a cotação de vendas
@return    	Nenhum
@obs        Serviço REST para ambiente WEB
Alterações Realizadas desde a Estruturação Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
WSRESTFUL alteraCotacao DESCRIPTION "Serviço REST - Cotação de vendas" FORMAT "application/json;charset=UTF-8,text/hml"
		
	WSDATA c_fil 		AS STRING OPTIONAL
	WSDATA cCotacao 	AS STRING OPTIONAL
	WSMETHOD POST DESCRIPTION "Recebe dados e cadastra/altera Cotação de Vendas" WSSYNTAX "/alteraCotacao?c_fil={param}" PATH "alteraCotacao"

END WSRESTFUL


//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} excluiCotacao
Web Service Rest 
@author		.iNi Sistemas
@since     	22/03/2023	
@version  	P.12
@param 		c_fil - Filial a ser incluido ou alterada a cotação de vendas
@return    	Nenhum
@obs        Serviço REST para ambiente WEB
Alterações Realizadas desde a Estruturação Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
WSRESTFUL excluiCotacao DESCRIPTION "Serviço REST - Deleta Cotação de vendas" FORMAT "application/json;charset=UTF-8,text/hml"
		
	WSDATA c_fil 		AS STRING OPTIONAL
	WSDATA cCotacao 	AS STRING OPTIONAL
	WSMETHOD DELETE DESCRIPTION "Recebe dados e deleta Cotação de Vendas" WSSYNTAX "/excluiCotacao?c_fil={param},cCotacao={param}" PATH "excluiCotacao"

END WSRESTFUL


//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} POST - incluiCotacao
Metodo para receber dados e criar/alterar Cotação de Vendas
@author		.iNi Sistemas
@since     	27/03/2023
@version  	P.12
@param 		c_fil - Filial a ser incluido ou alterada a cotação de vendas
@return    	lRet - Retorna sucesso ou erro de execução.
@obs        Serviço REST para ambiente WEB
Alterações Realizadas desde a Estruturação Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//----------------------------------------------------------------------------------------------
//WSMETHOD POST WSRECEIVE c_fil WSSERVICE incluiCotacao
User Function fIncCot()

	Local aArea     := {}
    Local cTabela   := "SZC"
	Local cTabIt   := "SZD"
    Local aCabec    := {}
	Local aItens    := {}
	Local aItAux := {}
	Local aFields := {}
	Local aCPOS := {}
	Local nX := 0
	Local nY := 0
	Local oJson := JsonObject():New()
	Local cRet := ""
	Local lRet := .T.
	Local aRet := {}

	RpcSetEnv("01","010001")

	/*cFilAnt := self:c_fil
	cEmpAnt	:= substr(self:c_fil,1,2)
	SM0->(dbSetOrder(1))
	SM0->(DbSeek(cEmpAnt+cFilAnt))*/

	cBody := '{ '
	//cBody += '"ZC_CODIGO" : "000000052",'
	cBody += '"ZC_CLIENTE" : "000007",'
	cBody += '"ZC_LOJACLI" : "01",'
	cBody += '"ZC_TIPFRET" : "C",'
	cBody += '"ZC_DTVALID" : "'+dtoc(DDATABASE+20)+'",'
	cBody += '"ZC_DTINIFO" : "'+dtoc(DDATABASE)+'",'
	cBody += '"ZC_DTFIMFO" : "'+dtoc(DDATABASE+2)+'",'	
	cBody += '"ZC_CONDPAG" : "002",'
	cBody += '"ZC_MOEDA" : "1",'
	cBody += '"ZC_VEND1" : "000557",'		
	cBody += '"ZC_VEND2" : "000557",'	
	cBody += '"itens" : ['
	cBody += '	{'
	//cBody += '		"ZD_PRODUTO": "",'
	cBody += '		"ZD_PREPROD": "15779",'
	cBody += '		"ZD_UMPAD": "KG",'
	cBody += '		"ZD_QUANT1": "8",'
	//cBody += '		"ZD_QUANT2": "200",'
	cBody += '		"ZD_CUSTUSU": "65"'
	//cBody += '		"D_E_L_E_T_": "*"'
	cBody += '	},'
	cBody += '	{'
	cBody += '		"ZD_PRODUTO": "",'
	cBody += '		"ZD_PREPROD": "115000",'
	cBody += '		"ZD_UMPAD": "KG",'
	cBody += '		"ZD_QUANT1": "0",'
	cBody += '		"ZD_QUANT2": "125.00",'
	cBody += '		"ZD_CUSTUSU": "120.00"'
	//cBody += '		"D_E_L_E_T_": "*"'
	cBody += '    }'
	cBody += ']'
	cBody += '}'

	aArea     := FWGetArea()

	//cBody := ::GetContent()
	//::SetContentType('application/json;charset=UTF-8')

	cRet := oJson:FromJson(cBody)
	
	If ValType(cRet) == "C"
		SetRestFault(403, "Falha ao transformar texto em objeto json. Erro: " + cRet)
		lRet := .F.
	endif
	/*If lRet 
		If Empty(self:c_fil)
			SetRestFault(403, "Parametro obrigatorio vazio. (filial)")
			lRet := .F.
		EndIf
	EndIf*/

	If lRet 
		//--Monta Array com todos os campos da SZC (CABEÇALHO)
		aFields := FWSX3Util():GetAllFields( cTabela , .F. ) //-- Retornará todos os campos presentes na SX3 de contexto real do alias.
		For nX := 1 to Len(aFields)
			If X3Uso(GetSx3Cache(aFields[nX],"X3_USADO"))

				//IF AllTrim(aFields[nX]) != "ZC_CODIGO"
				AADD(aCPOS,AllTrim(aFields[nX]))
				//EndIf

				//Adiciona os campos para o ExecAuto de acordo com json passado.
				IF VALTYPE(oJson[aFields[nX]]) != "U"
					If GetSx3Cache(aFields[nX],"X3_TIPO") == "D"
						aAdd(aCabec, {aFields[nX], ctod(oJson[aFields[nX]]), Nil})
					Else
						aAdd(aCabec, {aFields[nX], oJson[aFields[nX]], Nil})
						//Não é permitido informar o campo código na inclusão.
						//If AllTrim(GetSx3Cache(aFields[nX],"X3_CAMPO")) == "ZC_CODIGO"
						//	lRet := .F.
						//EndIf
					EndIf
				EndIf

			EndIf
		Next nX
		aAdd(aCabec, {"ZC_STATUS", "I", Nil})

		//--Monta Array com todos os campos da SZD (ITENS)
		aFields := FWSX3Util():GetAllFields( cTabIt , .F. ) //-- Retornará todos os campos presentes na SX3 de contexto real do alias.
		For nX := 1 to Len(oJson['itens'])
			For nY := 1 to Len(aFields)
				IF VALTYPE(oJson['itens'][nX][aFields[nY]]) != "U"
					If GetSx3Cache(aFields[nY],"X3_TIPO") == "D"
						aAdd(aItAux, {aFields[nY], ctod(oJson['itens'][nX][aFields[nY]]), Nil})
					Else
						aAdd(aItAux, {aFields[nY], oJson['itens'][nX][aFields[nY]], Nil})
					EndIf
				EndIf
			Next nY
			//--Inclui campo de deleção de item para quando na alteração se desejar deletar um item.
			If ValType(oJson['itens'][nX]["D_E_L_E_T_"]) != "U"
				aAdd(aItAux, {"D_E_L_E_T_", oJson['itens'][nX]["D_E_L_E_T_"], Nil})
			EndIf 
			aadd(aItens, aItAux)
			aItAux := {}
		Next nX

		//Chama Execauto da cotação de vendas. Par1=Cabeçalho; Par2=Itens; par3=Campos da tabela para validar; par4=Opçoes: 3-inclusão; 4-Alteração
		aRet := U_F_ExeCotV(aCabec,aItens,aCPOS,3)

		If aRet[1]
			//--Retorno Erro
			//SetRestFault(403, StrTran( aRet[2], CHR(13)+CHR(10), " " ))
			lRet := .F.
		Else
			//--Retorno ao json
			//::SetResponse(aRet[3])
			lRet := .T.
		EndIf

	EndIf

    FWRestArea(aArea)

	RpcClearEnv()

Return(lRet)


//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} POST - alteraCotacao
Metodo para receber dados e criar/alterar Cotação de Vendas
@author		.iNi Sistemas
@since     	27/03/2023
@version  	P.12
@param 		c_fil - Filial de alteração da cotação de vendas.
@param 		cCotacao - Código da cotação a ser alterada.
@return    	lRet - Retorna sucesso ou erro de execução.
@obs        Serviço REST para ambiente WEB
Alterações Realizadas desde a Estruturação Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//----------------------------------------------------------------------------------------------
//WSMETHOD POST WSRECEIVE c_fil, cCotacao WSSERVICE alteraCotacao
User Function fAltCot(c_fil,cCotacao)

	Local aArea     := {}
    Local cTabela   := "SZC"
	Local cTabIt   := "SZD"
    Local aCabec    := {}
	Local aItens    := {}
	Local aItAux := {}
	Local aFields := {}
	Local aCPOS := {}
	Local nX := 0
	Local nY := 0
	Local oJson := JsonObject():New()
	Local cRet := ""
	Local lRet := .T.
	Local aRet := {}

	Default c_fil    := "010001"
	Default cCotacao := "000000003"

	RpcSetEnv("01","010001")

	/*cFilAnt := self:c_fil
	cEmpAnt	:= substr(self:c_fil,1,2)
	SM0->(dbSetOrder(1))
	SM0->(DbSeek(cEmpAnt+cFilAnt))*/

	cBody := '{ '
	//cBody += '"ZC_CODIGO" : "000000052",'
	cBody += '"ZC_CLIENTE" : "000007",'
	cBody += '"ZC_LOJACLI" : "01",'
	cBody += '"ZC_TIPFRET" : "C",'
	cBody += '"ZC_DTVALID" : "'+dtoc(DDATABASE+20)+'",'
	cBody += '"ZC_DTINIFO" : "'+dtoc(DDATABASE)+'",'
	cBody += '"ZC_DTFIMFO" : "'+dtoc(DDATABASE+2)+'",'	
	cBody += '"ZC_CONDPAG" : "002",'
	cBody += '"ZC_MOEDA" : "1",'
	cBody += '"ZC_VEND1" : "000557",'		
	cBody += '"ZC_VEND2" : "000557",'	
	cBody += '"itens" : ['
	cBody += '	{'
	//cBody += '		"ZD_PRODUTO": "",'
	cBody += '		"ZD_PREPROD": "15779",'
	cBody += '		"ZD_UMPAD": "KG",'
	cBody += '		"ZD_QUANT1": "8",'
	//cBody += '		"ZD_QUANT2": "200",'
	cBody += '		"ZD_CUSTUSU": "65"'
	//cBody += '		"D_E_L_E_T_": "*"'
	cBody += '	},'
	cBody += '	{'
	cBody += '		"ZD_PRODUTO": "",'
	cBody += '		"ZD_PREPROD": "115000",'
	cBody += '		"ZD_UMPAD": "KG",'
	cBody += '		"ZD_QUANT1": "0",'
	cBody += '		"ZD_QUANT2": "125.00",'
	cBody += '		"ZD_CUSTUSU": "120.00",
	cBody += '		"ZD_STATUS": "I"
	//cBody += '		"D_E_L_E_T_": "*"'
	cBody += '    }'
	cBody += ']'
	cBody += '}'

	aArea     := FWGetArea()

	//cBody := ::GetContent()
	//::SetContentType('application/json;charset=UTF-8')

	cRet := oJson:FromJson(cBody)
	
	If ValType(cRet) == "C"
		SetRestFault(403, "Falha ao transformar texto em objeto json. Erro: " + cRet)
		lRet := .F.
	endif
	/*If lRet 
		If Empty(self:c_fil)
			SetRestFault(403, "Parametro obrigatorio vazio. (Filial)")
			lRet := .F.
		EndIf

		If Empty(self:cCotacao)
			SetRestFault(403, "Parametro obrigatorio vazio. (Numero da cotação)")
			lRet := .F.
		EndIf
	EndIf*/

	If lRet 
		//--Monta Array com todos os campos da SZC (CABEÇALHO)
		aAdd(aCabec, {"ZC_CODIGO", cCotacao, Nil}) //Campo código é passado de acordo com parâmetro enviado.
		aFields := FWSX3Util():GetAllFields( cTabela , .F. ) //-- Retornará todos os campos presentes na SX3 de contexto real do alias.
		For nX := 1 to Len(aFields)
			If X3Uso(GetSx3Cache(aFields[nX],"X3_USADO"))

				//IF AllTrim(aFields[nX]) != "ZC_CODIGO"
				AADD(aCPOS,AllTrim(aFields[nX]))
				//EndIf

				//Adiciona os campos para o ExecAuto de acordo com json passado.
				IF VALTYPE(oJson[aFields[nX]]) != "U"
					If GetSx3Cache(aFields[nX],"X3_TIPO") == "D"
						aAdd(aCabec, {aFields[nX], ctod(oJson[aFields[nX]]), Nil})
					Else						
						//Desconsidera o campo código na alteração pois é enviado nos parâmetros e ja foi incluído no cabeçalho.
						If AllTrim(GetSx3Cache(aFields[nX],"X3_CAMPO")) != "ZC_CODIGO"
							aAdd(aCabec, {aFields[nX], oJson[aFields[nX]], Nil})
						EndIf
					EndIf
				EndIf

			EndIf
		Next nX
		//aAdd(aCabec, {"ZC_STATUS", "I", Nil})

		//--Monta Array com todos os campos da SZD (ITENS)
		aFields := FWSX3Util():GetAllFields( cTabIt , .F. ) //-- Retornará todos os campos presentes na SX3 de contexto real do alias.
		For nX := 1 to Len(oJson['itens'])
			For nY := 1 to Len(aFields)
				IF VALTYPE(oJson['itens'][nX][aFields[nY]]) != "U"
					If GetSx3Cache(aFields[nY],"X3_TIPO") == "D"
						aAdd(aItAux, {aFields[nY], ctod(oJson['itens'][nX][aFields[nY]]), Nil})
					Else
						aAdd(aItAux, {aFields[nY], oJson['itens'][nX][aFields[nY]], Nil})
					EndIf
				EndIf
			Next nY
			//--Inclui campo de deleção de item para quando na alteração se desejar deletar um item.
			If ValType(oJson['itens'][nX]["D_E_L_E_T_"]) != "U"
				aAdd(aItAux, {"D_E_L_E_T_", oJson['itens'][nX]["D_E_L_E_T_"], Nil})
			EndIf 
			aadd(aItens, aItAux)
			aItAux := {}
		Next nX

		//Chama Execauto da cotação de vendas. Par1=Cabeçalho; Par2=Itens; par3=Campos da tabela para validar; par4=Opçoes: 3-inclusão; 4-Alteração
		aRet := U_F_ExeCotV(aCabec,aItens,aCPOS,4)

		If aRet[1]
			//--Retorno Erro
			//SetRestFault(403, StrTran( aRet[2], CHR(13)+CHR(10), " " ))
			lRet := .F.
		Else
			//--Retorno ao json
			//::SetResponse(aRet[3])
			lRet := .T.
		EndIf

	EndIf

    FWRestArea(aArea)

	RpcClearEnv()

Return(lRet)


//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} POST - excluiCotacao
Metodo para receber dados e criar/alterar Cotação de Vendas
@author		.iNi Sistemas
@since     	27/03/2023
@version  	P.12
@param 		c_fil - Filial de alteração da cotação de vendas.
@param 		cCotacao - Código da cotação a ser alterada.
@return    	lRet - Retorna sucesso ou erro de execução.
@obs        Serviço REST para ambiente WEB
Alterações Realizadas desde a Estruturação Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//----------------------------------------------------------------------------------------------
//WSMETHOD POST WSRECEIVE c_fil, cCotacao WSSERVICE alteraCotacao
User Function fExcCot(c_fil,cCotacao)

Local aCabec    := {}
Default c_fil := "010001"
Default cCotacao := "000000005"

RpcSetEnv("01","010001")

aAdd(aCabec, {"ZC_CODIGO", cCotacao, Nil})

//Chama Execauto da cotação de vendas. Par1=Cabeçalho; Par2=Itens; par3=Campos da tabela para validar; par4=Opçoes: 3-inclusão; 4-Alteração
aRet := U_F_ExeCotV(aCabec,{},{},5)

If aRet[1]
	//--Retorno Erro
	//SetRestFault(403, StrTran( aRet[2], CHR(13)+CHR(10), " " ))
	lRet := .F.
Else
	//--Retorno ao json
	//::SetResponse(aRet[3])
	lRet := .T.
EndIf

RpcClearEnv()

Return(lRet)
