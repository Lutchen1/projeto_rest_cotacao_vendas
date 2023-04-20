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
@since     	20/04/2023	
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
{Protheus.doc} PIWSCOTV
Web Service Rest Pr�-Produto ( POST / PUT / DELETE )
@author		.iNi Sistemas
@since     	22/03/2023	
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
WSRESTFUL PIWSCOTV DESCRIPTION "Servi�o REST - Pr�-Produto" FORMAT "application/json"

	
	WSDATA c_fil 		AS STRING OPTIONAL
	WSDATA cCotacao 	AS STRING OPTIONAL

	WSMETHOD POST DESCRIPTION "Recebe dados e inclui pr�-produto" WSSYNTAX "/PIWSPPRO?c_fil={param}" //PATH "incluiCotacao" 
	WSMETHOD PUT DESCRIPTION "Recebe dados e altera pr�-produto" WSSYNTAX "/PIWSPPRO?c_fil={param},cCotacao={param}" //PATH "alteraCotacao"
	WSMETHOD DELETE DESCRIPTION "Recebe dados e exclui pr�-produto" WSSYNTAX "/PIWSPPRO?c_fil={param},ccotacao={param}" //PATH "excluiCotacao"

END WSRESTFUL



User Function fIncPrePro()

Local cBody := ""
Local nX := 0
Local cRet := ""
Local aCabec := {}
Local aFields := {}
Local cTabela := "SZA"
Local nOpc := 3


	RpcSetEnv("01","010001")

	cBody := '{ '
	//cBody += '"ZA_CODIGO" : "000007",'
	cBody += '"ZA_DESCRIC" : "01",'
	cBody += '"ZA_UM" : "C",'
	cBody += '"ZA_SEGUM" : "'+dtoc(DDATABASE+20)+'"'
	cBody += '}'

	cRet := oJson:FromJson(cBody)
	
	If ValType(cRet) == "C"
		//SetRestFault(403, "Falha ao transformar texto em objeto json. Erro: " + cRet)
		lRet := .F.
	endif


	If lRet 

		//--Monta Array com todos os campos da SZA (Pr�-produto)
		aFields := FWSX3Util():GetAllFields( cTabela , .F. ) //-- Retornar� todos os campos presentes na SX3 de contexto real do alias.
		For nX := 1 to Len(aFields)
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
		Next nX



		ExePrePro(aCabec,aCPOS,nOpc)


	EndIf


	RpcClearEnv()

Return()






Static Function ExePrePro(aCabec,aCPOS,nOpc)

Local lErro := .F.
Local cMsgErro := ""
Local lRet := .T.

Private oJson 	:= JsonObject():New()
Private oJson2	:= JsonObject():New()

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
				If nOpc == 5 //.And. !(SZC->ZC_STATUS == 'I') .And. !(SZC->ZC_STATUS == 'B')
					//cMsgErro += "Nao e permitida a exclusao da cotacao para o status atual."
					//lRet := .F.
				EndIf

			EndIf

		Else
			
			If aScan(aCabec,{ |x| ALLTRIM(x[1]) == "ZA_CODIGO" }) > 0
				cMsgErro += "Nao e permitido informar o codigo da cotacao na operacao de inclusao."
				lRet := .F.
			EndIf

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

					oJson['status'] 		:= "200"
					oJson['mensagem'] 		:= "Sucesso!"	
					oJson['conteudo'] 		:= {}			
					
					oJson2['ZA_FILIAL'] 	= SZA->ZA_FILIAL
					oJson2['ZA_CODIGO'] 	:= SZA->ZA_CODIGO
					oJson2['ZA_DESCRIC'] 	:= SZA->ZA_DESCRIC

					Aadd(oJson['conteudo'],oJson2)

				EndIf

			Else
				oJson['status'] 		:= "200"
				oJson['mensagem'] 		:= "Sucesso na exclusao da cotacao!"	
			EndIf

		Else
			lErro := .T.	
		EndIf


	End Transaction 


Return({lErro,cMsgErro,oJson1})
