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
{Protheus.doc} PIWSPPRO
Fonte reservado rest.

@author		.iNi Sistemas - LTN
@since     	24/04/2023	
@version  	P.12
@return    	Nenhum
@obs        Nenhum

Alter��es Realizadas desde a Estrutura��o Inicial
------------+-----------------+---------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+---------------------------------------------------------
/*/
//--------------------------------------------------------------------------------------- 
User Function PIWSPPRO()

Return()

//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} PIWSPPRO
Web Service Rest Pr�-Produto ( POST / PUT / DELETE )
@author		.iNi Sistemas
@since     	24/04/2023	
@version  	P.12
@param 		c_fil - Filial a ser incluido ou alterada a cota��o de vendas
@return    	Nenhum
@obs        Servi�o REST para ambiente WEB
Altera��es Realizadas desde a Estrutura��o Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
WSRESTFUL PIWSPPRO DESCRIPTION "Servi�o REST - Pr�-Produto" FORMAT "application/json"

	WSDATA cCodPreP 	AS STRING OPTIONAL

	WSMETHOD POST DESCRIPTION "Recebe dados e inclui pr�-produto" WSSYNTAX "/PIWSPPRO?cCodPreP={param}" //PATH "incluiCotacao" 
	WSMETHOD PUT DESCRIPTION "Recebe dados e altera pr�-produto" WSSYNTAX "/PIWSPPRO?cCodPreP={param}" //PATH "alteraCotacao"
	WSMETHOD DELETE DESCRIPTION "Recebe dados e exclui pr�-produto" WSSYNTAX "/PIWSPPRO?cCodPreP={param}" //PATH "excluiCotacao"

END WSRESTFUL

//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} PIWSPPRO
Web Service Rest inclus�o Pr�-Produto ( POST )
@author		.iNi Sistemas
@since     	24/04/2023	
@version  	P.12
@param 		cCodPreP - C�digo do pr� produto
@return    	Nenhum
@obs        Servi�o REST para ambiente WEB
Altera��es Realizadas desde a Estrutura��o Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
WSMETHOD POST WSRECEIVE cCodPreP WSSERVICE PIWSPPRO
//User Function fIncPrePro()

Local lRet := .T.
Local cBody := ""
Local nX := 0
Local cRet := ""
Local aCabec := {}
Local aFields := {}
Local cTabela := "SZA"
Local nOpc := 3
Local aCPOS := {}
Local cCusBri := "" 
Private oJson 	:= JsonObject():New()

	/*RpcSetEnv("01","010001")

	cBody := '{ '
	//cBody += '"ZA_CODIGO" : "995565",'
	cBody += '"ZA_DESCRIC" : "TESTELTN",'
	cBody += '"ZA_UM" : "SC",'
	cBody += '"ZA_SEGUM" : "KG",'
	cBody += '"ZA_PRDSIMI" : "1688620",'     
	cBody += '"custo" : ['
	cBody += '	{'
	cBody += '		"FILIAL": "010050",'
	cBody += '		"CUSTO": "125.00",'
	cBody += '		"VALIDADE": "24/05/2023"'
	cBody += '  },'
	cBody += '	{'
	cBody += '		"FILIAL": "010085",'
	cBody += '		"CUSTO": "129.00",'
	cBody += '		"VALIDADE": "24/05/2023"'
	cBody += '  }'
	cBody += ']'   
	cBody += '}'*/

	cBody := ::GetContent()
	::SetContentType('application/json;charset=UTF-8')

	cRet := oJson:FromJson(cBody)
	
	If ValType(cRet) == "C"
		SetRestFault(403, "Falha ao transformar texto em objeto json. Erro: " + cRet)
		lRet := .F.
	endif
	If lRet 
		If Empty(self:cCodPreP)
			SetRestFault(403, "Parametro obrigatorio vazio. (C�digo do pr�-Produto)")
			lRet := .F.
		EndIf
	EndIf

	If lRet 

		cCusBri := ""
		if ValType(oJson['custo']) != "U"
			For nX := 1 to Len (oJson['custo'])		
				cCusBri += oJson['custo'][nX]:FILIAL+" - "+oJson['custo'][nX]:CUSTO+" - "+dtos(ctod(oJson['custo'][nX]:VALIDADE))+"/"
			Next nX
		EndIf
		cCusBri := substring(cCusBri,1,len(cCusBri)-1)

		//--Monta Array com todos os campos da SZA (Pr�-produto)
		aFields := FWSX3Util():GetAllFields( cTabela , .F. ) //-- Retornar� todos os campos presentes na SX3 de contexto real do alias.
		For nX := 1 to Len(aFields)
			If aFields[nX] == "ZA_CODIGO"
				aAdd(aCabec, {aFields[nX], self:cCodPreP, Nil})
			Else		
				If X3Uso(GetSx3Cache(aFields[nX],"X3_USADO"))

					AADD(aCPOS,AllTrim(aFields[nX]))

					//Adiciona os campos para o ExecAuto de acordo com json passado.
					IF VALTYPE(oJson[aFields[nX]]) != "U"
						If GetSx3Cache(aFields[nX],"X3_TIPO") == "D"
							aAdd(aCabec, {aFields[nX], ctod(oJson[aFields[nX]]), Nil})
						Else
							aAdd(aCabec, {aFields[nX], oJson[aFields[nX]], Nil})
						EndIf
					EndIf

				EndIf

				If aFields[nX] == "ZA_ZCUSBRI" .And. !Empty(cCusBri)
					aAdd(aCabec, {aFields[nX], cCusBri, Nil})
				EndIf
			EndIf
		Next nX

		//Chama Execauto de pre-produto. Par1=Cabe�alho; par2=Campos da tabela para validar; par3=Op�oes: 3-inclus�o; 4-Altera��o; 5-Exclus�o
		aRet := ExePrePro(aCabec,aCPOS,nOpc)
		
		If aRet[1]
			//--Retorno Erro
			SetRestFault(403, StrTran( aRet[2], CHR(13)+CHR(10), " " ))
			lRet := .F.
		Else
			//--Retorno ao json
			::SetResponse(aRet[3])
			lRet := .T.
		EndIf

	EndIf

	//RpcClearEnv()

Return()

//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} PIWSPPRO
Web Service Rest altera��o Pr�-Produto ( PUT )
@author		.iNi Sistemas
@since     	24/04/2023	
@version  	P.12
@param 		cCodPreP - C�digo do pr� produto
@return    	Nenhum
@obs        Servi�o REST para ambiente WEB
Altera��es Realizadas desde a Estrutura��o Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
WSMETHOD PUT WSRECEIVE cCodPreP WSSERVICE PIWSPPRO
//User Function fAltPrePro()

Local lRet := .T.
Local cBody := ""
Local nX := 0
Local cRet := ""
Local aCabec := {}
Local aFields := {}
Local cTabela := "SZA"
Local nOpc := 4
Local aCPOS := {}
Local cCusBri := "" 
Private oJson 	:= JsonObject():New()


	/*RpcSetEnv("01","010001")

	cBody := '{ '
	cBody += '"ZA_CODIGO" : "995565",'
	cBody += '"ZA_DESCRIC" : "TESTELTN2",'
	cBody += '"ZA_UM" : "SC",'
	cBody += '"ZA_SEGUM" : "KG",'
	cBody += '"ZA_PRDSIMI" : "1688620",'     
	cBody += '"custo" : ['
	cBody += '	{'
	cBody += '		"FILIAL": "010050",'
	cBody += '		"CUSTO": "125.00",'
	cBody += '		"VALIDADE": "24/05/2023"'
	cBody += '  },'
	cBody += '	{'
	cBody += '		"FILIAL": "010085",'
	cBody += '		"CUSTO": "129.00",'
	cBody += '		"VALIDADE": "24/05/2023"'
	cBody += '  }'
	cBody += ']'   
	cBody += '}'*/

	cBody := ::GetContent()
	::SetContentType('application/json;charset=UTF-8')

	cRet := oJson:FromJson(cBody)
	
	If ValType(cRet) == "C"
		SetRestFault(403, "Falha ao transformar texto em objeto json. Erro: " + cRet)
		lRet := .F.
	Endif
	If lRet 
		If Empty(self:cCodPreP)
			SetRestFault(403, "Parametro obrigatorio vazio. (C�digo do pr�-Produto)")
			lRet := .F.
		EndIf
	EndIf

	If lRet 

		cCusBri := ""
		if ValType(oJson['custo']) != "U"
			For nX := 1 to Len (oJson['custo'])		
				cCusBri += oJson['custo'][nX]:FILIAL+" - "+oJson['custo'][nX]:CUSTO+" - "+dtos(ctod(oJson['custo'][nX]:VALIDADE))+"/"
			Next nX
		EndIf
		cCusBri := substring(cCusBri,1,len(cCusBri)-1)	

		//--Monta Array com todos os campos da SZA (Pr�-produto)
		aFields := FWSX3Util():GetAllFields( cTabela , .F. ) //-- Retornar� todos os campos presentes na SX3 de contexto real do alias.
		For nX := 1 to Len(aFields)
			If aFields[nX] == "ZA_CODIGO"
				aAdd(aCabec, {aFields[nX], self:cCodPreP, Nil})
			Else
				If X3Uso(GetSx3Cache(aFields[nX],"X3_USADO"))

					AADD(aCPOS,AllTrim(aFields[nX]))

					//Adiciona os campos para o ExecAuto de acordo com json passado.
					IF VALTYPE(oJson[aFields[nX]]) != "U"
						If GetSx3Cache(aFields[nX],"X3_TIPO") == "D"
							aAdd(aCabec, {aFields[nX], ctod(oJson[aFields[nX]]), Nil})
						Else
							aAdd(aCabec, {aFields[nX], oJson[aFields[nX]], Nil})
						EndIf
					EndIf

				EndIf

				If aFields[nX] == "ZA_ZCUSBRI" .And. !Empty(cCusBri)
					aAdd(aCabec, {aFields[nX], cCusBri, Nil})
				EndIf
			EndIf

		Next nX

		//Chama Execauto de pre-produto. Par1=Cabe�alho; par2=Campos da tabela para validar; par3=Op�oes: 3-inclus�o; 4-Altera��o; 5-Exclus�o
		aRet := ExePrePro(aCabec,aCPOS,nOpc)
		
		If aRet[1]
			//--Retorno Erro
			SetRestFault(403, StrTran( aRet[2], CHR(13)+CHR(10), " " ))
			lRet := .F.
		Else
			//--Retorno ao json
			::SetResponse(aRet[3])
			lRet := .T.
		EndIf

	EndIf

	//RpcClearEnv()

Return()

//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} PIWSPPRO
Web Service Rest exclus�o Pr�-Produto ( DELETE )
@author		.iNi Sistemas
@since     	24/04/2023	
@version  	P.12
@param 		cCodPreP - C�digo do pr� produto
@return    	Nenhum
@obs        Servi�o REST para ambiente WEB
Altera��es Realizadas desde a Estrutura��o Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
WSMETHOD DELETE WSRECEIVE cCodPreP WSSERVICE PIWSPPRO
//User Function fExPrePro()

Local lRet := .T.
Local aCabec := {}
Local nOpc := 5
Local aCPOS := {}

//Local cCodPreP := "995565"

	//RpcSetEnv("01","010001")

	If Empty(self:cCodPreP)
		SetRestFault(403, "Parametro obrigatorio vazio. (C�digo do pr�-Produto)")
		lRet := .F.
	EndIf

	aAdd(aCabec, {"ZA_CODIGO", self:cCodPreP, Nil})

	If lRet 

		//Chama Execauto de pre-produto. Par1=Cabe�alho; par2=Campos da tabela para validar; par3=Op�oes: 3-inclus�o; 4-Altera��o; 5-Exclus�o
		aRet := ExePrePro(aCabec,aCPOS,nOpc)
		
		If aRet[1]
			//--Retorno Erro
			SetRestFault(403, StrTran( aRet[2], CHR(13)+CHR(10), " " ))
			lRet := .F.
		Else
			//--Retorno ao json
			::SetResponse(aRet[3])
			lRet := .T.
		EndIf

	EndIf

	//RpcClearEnv()

Return()


Static Function ExePrePro(aCabec,aCPOS,nOpc)

Local lErro := .F.
Local cMsgErro := ""
Local lRet := .T.
Local cTabela := "SZA"
Local cTransact := ""

Private oJson1 	:= JsonObject():New()
Private oJson2	:= JsonObject():New()
Private lMsErroAuto := .F.
Private aTELA[0][0],aGETS[0]


    //--Inicializa a transa��o
    Begin Transaction

		//--Valida��o da altera��o/exclus�o, A da fun��o EnchAuto retorna um erro que n�o indica o motivo correto.
		If nOpc == 4 .OR. nOpc == 5

			SZA->(dbSetOrder(1))
			If !SZA->(dbSeek(xFilial("SZA")+ACABEC[aScan(aCabec,{ |x| ALLTRIM(x[1]) == "ZA_CODIGO" })][2]))
				
				cMsgErro += "Pre-produto "+Alltrim(ACABEC[aScan(aCabec,{ |x| ALLTRIM(x[1]) == "ZA_CODIGO" })][2])+" nao encontrado! 
				lRet := .F.

			Else

				//--Valida��o de altera��o do registro.
				If nOpc == 4 //.And. !(SZC->ZC_STATUS $ cStaBlAlt)
					//cMsgErro += "Nao e permitida a altera��o da cota��o para o status atual."
					//lRet := .F.
				EndIf

				//--Valida��o de exclus�o do registro.
				If nOpc == 5 

					If fValExc()
						cMsgErro += "Existe cotacao de venda para o pre-produto! Nao sera possivel excluir."
						lRet := .f.
					EndIf

				EndIf

			EndIf

		Else
			
			/*If aScan(aCabec,{ |x| ALLTRIM(x[1]) == "ZA_CODIGO" }) > 0
				cMsgErro += "Nao e permitido informar o codigo da pr�-produto na operacao de inclusao."
				lRet := .F.
			EndIf*/

		EndIf

		If lRet

			//Joga a tabela para a mem�ria (M->)
			RegToMemory(;
				cTabela,; // cAlias - Alias da Tabela
				iif(nOpc==4 .or. nOpc==5,.F.,.T.),;     // lInc   - Define se � uma opera��o de inclus�o ou atualiza��o
				.F.;      // lDic   - Define se ir� inicilizar os campos conforme o dicion�rio
			)
			
		
			//--Se conseguir fazer a execu��o autom�tica - Valida��o do cabe�alho.
			If EnchAuto(;
				cTabela,; // cAlias  - Alias da Tabela
				aCabec,;  // aField  - Array com os campos e valores
				{ || Obrigatorio( aGets, aTela ) },; // uTUDOOK - Valida��o do bot�o confirmar
				nOpc,;        // nOPC    - Opera��o do Menu (3=inclus�o, 4=altera��o, 5=exclus�o)
				aCPOS;
			)


				If nOpc != 5

					//--Aciona a efetiva��o da grava��o do cabe�alho.
					nRetorno := AxIncluiAuto(;
						cTabela,;   // cAlias     - Alias da Tabela
						,;          // cTudoOk    - Opera��o do TudoOk (se usado no EnchAuto n�o precisa usar aqui)
						cTransact,; // cTransact  - Opera��o acionada ap�s a grava��o mas dentro da transa��o
						nOpc,;          // nOpcaoAuto - Opera��o do Menu (3=inclus�o, 4=altera��o, 5=exclus�o)
						SZA->(recno());
					)					

				Else

					//--Realiza exclus�o da cota��o.
					SZA->(dbSetOrder(1))
					If SZA->(dbSeek(xFilial("SAA")+M->ZA_CODIGO))	

						RecLock("SZA",.F.)
							SZA->(dbDelete())
						SZA->(MsUnlock())
						
					EndIf

				EndIf

			Else            
				//MostraErro()
				lRet := .F.
				cMsgErro := MemoRead(NomeAutoLog())
				Ferase(NomeAutoLog())
				DisarmTransaction()
			EndIf
		EndIf

		If lRet
			If nOpc != 5

				SZA->(dbSetOrder(1))
				If SZA->(dbSeek(xFilial("SZA")+M->ZA_CODIGO))

					oJson1['status'] 		:= "200"
					oJson1['mensagem'] 		:= "Sucesso!"	
					oJson1['conteudo'] 		:= {}			
					
					oJson2['ZA_FILIAL'] 	= SZA->ZA_FILIAL
					oJson2['ZA_CODIGO'] 	:= SZA->ZA_CODIGO
					oJson2['ZA_DESCRIC'] 	:= SZA->ZA_DESCRIC

					Aadd(oJson1['conteudo'],oJson2)

				EndIf

			Else
				oJson1['status'] 		:= "200"
				oJson1['mensagem'] 		:= "Sucesso na exclusao do pre-produto!"	
			EndIf

		Else
			lErro := .T.	
		EndIf


	End Transaction 


Return({lErro,cMsgErro,oJson1})





Static Function fValExc()

Local lExist := .F.
Local cQuery := ""

If Select("QRYTMP")>0
	QRYTMP->(DbCloseArea())
EndIf

cQuery := " SELECT ZD_PREPROD "
cQuery += " FROM "+RetSqlName("SZD")
cQuery += " WHERE ZD_PREPROD = '"+SZA->ZA_CODIGO+"'"
cQuery += " AND D_E_L_E_T_ <> '*' "
cQuery += " AND ROWNUM = 1 "

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "QRYTMP", .T., .T.)		

If !QRYTMP->(Eof())
	lExist := .T.
EndIf

QRYTMP->(dbCloseArea())

Return(lOk)
