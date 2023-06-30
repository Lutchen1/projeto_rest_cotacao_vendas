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
{Protheus.doc} PIWSEPRE
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
User Function PIWSEPRE()

Return()

//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} PIWSEPRE
Web Service RestEfetiva pre-produtos ( POST )
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
WSRESTFUL PIWSEPRE DESCRIPTION "Serviço REST - Efetiva pre-produtos" FORMAT "application/json"
	
	//WSDATA c_Fil 		AS STRING OPTIONAL
	WSDATA c_CodPre 	AS STRING OPTIONAL

	WSMETHOD POST DESCRIPTION "Recebe dados e efetiva pre-produtos incluindo produto." WSSYNTAX "/PIWSEPRE?c_CodPre={param}" //PATH "incluiCotacao" 
	

END WSRESTFUL


//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} POST
Metodo para efetivar pré produto.
@author		.iNi Sistemas
@since     	28/06/2023
@version  	P.12
@param 		c_CodPre - Código do pré produto
@return    	lRet - Retorna sucesso ou erro de execução.
@obs        Serviço REST para ambiente WEB
Alterações Realizadas desde a Estruturação Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//----------------------------------------------------------------------------------------------
WSMETHOD POST WSRECEIVE c_CodPre WSSERVICE PIWSEPRE
//User Function fIncPre()

	Local aArea     := {}
    Local cTabela   := "SB1"
    Local aCabec    := {}
	Local aFields := {}
	Local nX := 0
	Local nY := 0
	Local oJson := JsonObject():New()
	Local oJson1 	:= JsonObject():New()
	Local oJsonRec 	:= JsonObject():New()
	Local cRet := ""
	Local lRet := .T.
	Local lErro := .F.
	Local cLogMsg := ""
	Local aErroExec :={}
	Local nOpcao := 0
	Local aComPro := {}
	Local aAuxSB1:= {}
	Local nPos := 0
    Private lMsErroAuto := .F.
	Private oModel      := Nil
	Private aRotina     := {}
	Private INCLUI      := .T.
	Private ALTERA      := .F.
	Private l010Auto    := .T.
	Private lMsHelpAuto   := .F.
	Private lAutoErrNoFile:= .T.

	DEFAULT c_fil := "01"
	DEFAULT c_CodPre := "61383"

	//RpcSetEnv("01","010001","pontoini","Mudar.2023")

	SZA->(dbSetOrder(1))
	If !SZA->(dbSeek(xFilial("SZA")+c_CodPre))
		SetRestFault(403, "Pre-produto não encontrado: " + c_CodPre)
		lRet := .F.
	Else

		SB1->(dbSetOrder(1))
		SB1->(dbSeek(xFilial("SB1")+SZA->ZA_PRDSIMI))

		//--Campos vindos do pré produto e produto similar para efetivação.
		/*cBody := '{ '
		cBody += '"B1_FILIAL" : "'+xFilial("SB1")+'",'
		cBody += '"B1_COD" : "TESTELALALA",'
		cBody += '"B1_DESC" : "'+SZA->ZA_DESCRIC+'",'    
		cBody += '"B1_TIPO" : "'+SB1->B1_TIPO+'",'     
		cBody += '"B1_ESPECIF" : "'+SZA->ZA_DESCRIC+'",' 
		cBody += '"B1_ZDESCR" : "'+SZA->ZA_DESCRIC+'",' 
		cBody += '"B1_UM" : "'+SZA->ZA_UM+'",' 
		cBody += '"B1_SEGUM" : "'+SZA->ZA_SEGUM+'",' 
		cBody += '"B1_CONV" : "'+AllTrim(str(SZA->ZA_CONV))+'",' 
		cBody += '"B1_TIPCONV" : "'+SZA->ZA_TIPCONV+'",' 		
		cBody += '"B1_LOCPAD" : "'+SB1->B1_LOCPAD+'",' 
		cBody += '"B1_GRUPO" : "'+SB1->B1_GRUPO+'",' 
		cBody += '"B1_ZDESGRP" : "'+POSICIONE("SBM",1,XFILIAL("SBM")+SB1->B1_GRUPO,"BM_DESC")+'",' 
		cBody += '"B1_PESBRU" : "'+AllTrim(STR(SB1->B1_PESBRU))+'",'
		cBody += '"B1_PESO" : "'+AllTrim(Str(SB1->B1_PESO))+'",'
		cBody += '"B1_RASTRO" : "'+SB1->B1_RASTRO+'",'
		cBody += '"B1_LOCALIZ" : "'+SB1->B1_LOCALIZ+'",'
		cBody += '"B1_POSIPI" : "'+SB1->B1_POSIPI+'",'
		cBody += '"B1_ORIGEM" : "'+SB1->B1_ORIGEM+'",' 
		cBody += '"B1_ZSEGRE" : "'+SB1->B1_ZSEGRE+'",' 
		cBody += '"B1_GARANT" : "'+SB1->B1_GARANT+'",' 
		cBody += '"B1_CONTA" : "'+SB1->B1_CONTA+'",'
		cBody += '"B1_ZCCINDE" : "'+SB1->B1_ZCCINDE+'"'    
		cBody += '} '*/

		aAdd(aCabec, {"B1_FILIAL",xFilial("SB1"), Nil})
		aAdd(aCabec, {"B1_COD","TESTELALALA", Nil})
		aAdd(aCabec, {"B1_DESC",Avkey(SZA->ZA_DESCRIC,"B1_DESC"), Nil})
		aAdd(aCabec, {"B1_TIPO",SB1->B1_TIPO, Nil})
		aAdd(aCabec, {"B1_ESPECIF",Avkey(SZA->ZA_DESCRIC,"B1_ESPECIF"), Nil})
		aAdd(aCabec, {"B1_ZDESCR",AvKey(SZA->ZA_DESCRIC,"B1_ZDESCR"), Nil})
		aAdd(aCabec, {"B1_UM",SZA->ZA_UM, Nil})
		aAdd(aCabec, {"B1_SEGUM",SZA->ZA_SEGUM, Nil})
		aAdd(aCabec, {"B1_CONV",SZA->ZA_CONV, Nil})
		aAdd(aCabec, {"B1_TIPCONV",SZA->ZA_TIPCONV, Nil})
		aAdd(aCabec, {"B1_LOCPAD",SB1->B1_LOCPAD, Nil})
		aAdd(aCabec, {"B1_GRUPO",SB1->B1_GRUPO, Nil})
		aAdd(aCabec, {"B1_ZDESGRP",POSICIONE("SBM",1,XFILIAL("SBM")+SB1->B1_GRUPO,"BM_DESC"), Nil})
		aAdd(aCabec, {"B1_PESBRU",SB1->B1_PESBRU, Nil})
		aAdd(aCabec, {"B1_PESO",SB1->B1_PESO, Nil})
		aAdd(aCabec, {"B1_RASTRO",SB1->B1_RASTRO, Nil})
		aAdd(aCabec, {"B1_LOCALIZ",SB1->B1_LOCALIZ, Nil})
		aAdd(aCabec, {"B1_POSIPI",SB1->B1_POSIPI, Nil})
		aAdd(aCabec, {"B1_ORIGEM",SB1->B1_ORIGEM, Nil})
		aAdd(aCabec, {"B1_ZSEGRE",SB1->B1_ZSEGRE, Nil})
		aAdd(aCabec, {"B1_GARANT",SB1->B1_GARANT, Nil})
		aAdd(aCabec, {"B1_CONTA",SB1->B1_CONTA, Nil})
		aAdd(aCabec, {"B1_ZCCINDE",SB1->B1_ZCCINDE, Nil})

		aArea     := FWGetArea()

		//cBody := ::GetContent()
		//::SetContentType('application/json;charset=UTF-8')

		/*cRet := oJson:FromJson(cBody)
		
		If ValType(cRet) == "C"
			//SetRestFault(403, "Falha ao transformar texto em objeto json. Erro: " + cRet)
			lRet := .F.
		endif*/
		If lRet 
			//If Empty(self:c_CodPre)
			If Empty(c_CodPre)
				SetRestFault(403, "Parametro obrigatorio vazio. (Codigo pré-produto)")
				lRet := .F.
			EndIf
		EndIf

		If lRet 


			cFilAnt := "010001"
			cEmpAnt	:= substr(c_fil,1,2)
			SM0->(dbSetOrder(1))
			SM0->(DbSeek(cEmpAnt+cFilAnt))

			oModel := FwLoadModel ("MATA010")
			SetFunName("MATA010")

			nOpcao := MODEL_OPERATION_INSERT

			//--Monta Array com todos os campos dab SB1 - Produto.
			/*aFields := FWSX3Util():GetAllFields( cTabela , .F. ) //-- Retornará todos os campos presentes na SX3 de contexto real do alias.
			For nX := 1 to Len(aFields)
				If X3Uso(GetSx3Cache(aFields[nX],"X3_USADO")) .or. aFields[nX] == "B1_FILIAL"
					//Adiciona os campos para o ExecAuto de acordo com json passado.
					IF VALTYPE(oJson[aFields[nX]]) != "U"
						If GetSx3Cache(aFields[nX],"X3_TIPO") == "D"
							aAdd(aCabec, {aFields[nX], ctod(oJson[aFields[nX]]), Nil})
						ElseIf GetSx3Cache(aFields[nX],"X3_TIPO") == "N"
							aAdd(aCabec, {aFields[nX], Val(oJson[aFields[nX]]), Nil})
						Else
							aAdd(aCabec, {aFields[nX], AVKEY(oJson[aFields[nX]],aFields[nX]), Nil})
						EndIf
					EndIf
				EndIf
			Next nX*/


			//Campos vindo do webservice para subistituir do array principal.
			/*cBody := '{ '
			cBody += '"B1_GRUPO" : "0002",'    
			cBody += '"ZB1_PRDCUS" : "05"'    
			cBody += '} '*/
			cBody := ::GetContent()
			::SetContentType('application/json;charset=UTF-8')
			If !Empty(cBody)
				cRet := oJsonRec:FromJson(cBody)
				If ValType(cRet) == "C"
					SetRestFault(403, "Falha ao transformar texto em objeto json. Erro: " + cRet)
					lRet := .F.
				Endif
			EndIf

			If lRet

				//--Monta Array com todos os campos dab SB1 - Produto.
				aFields := FWSX3Util():GetAllFields( cTabela , .F. ) //-- Retornará todos os campos presentes na SX3 de contexto real do alias.
				For nX := 1 to Len(aFields)
					If X3Uso(GetSx3Cache(aFields[nX],"X3_USADO")) .or. aFields[nX] == "B1_FILIAL"
						//Adiciona os campos para o ExecAuto de acordo com json passado.
						IF VALTYPE(oJsonRec[aFields[nX]]) != "U"
							If GetSx3Cache(aFields[nX],"X3_TIPO") == "D"
								aAdd(aAuxSB1, {aFields[nX], ctod(oJsonRec[aFields[nX]]), Nil})
							ElseIf GetSx3Cache(aFields[nX],"X3_TIPO") == "N"
								aAdd(aAuxSB1, {aFields[nX], Val(oJsonRec[aFields[nX]]), Nil})
							Else
								aAdd(aAuxSB1, {aFields[nX], AVKEY(oJsonRec[aFields[nX]],aFields[nX]), Nil})
							EndIf
						EndIf
					EndIf
				Next nX

				//--Substituo informações buscadas do pré produto e produto similar com as informações passadas no json.
				For nX := 1 to Len(aAuxSB1)
					nPos := aScan(aCabec,{|x|AllTrim(x[1])==aAuxSB1[nX][1]})
					If nPos > 0
						aCabec[nPos][2] := aAuxSB1[nX][2]
					EndIf
				Next nX		

			EndIf


			aCabec := FWVetByDic( aCabec, 'SB1' )

			//Chamando a inclusão - Modelo 1
			lMsErroAuto := .F.
	
			FWMVCRotAuto( oModel,"SB1",nOpcao,{{"SB1MASTER", aCabec}})
		
			//Se houve erro no ExecAuto, mostra mensagem
			If lMsErroAuto
				aErroExec := GetAutoGRLog() //Buscar o erro reportado pelo execauto
				For nX := 1 To Len(aErroExec)
					cLogMsg += aErroExec[nX]+ Chr(13) + Chr(10)
				Next xI
				lErro := .T.
			Else

				//--Monta Array com todos os campos da ZB1 - Tabela complementar de produto.
				aFields := FWSX3Util():GetAllFields( "ZB1" , .F. ) //-- Retornará todos os campos presentes na SX3 de contexto real do alias.
				For nX := 1 to Len(aFields)
					If X3Uso(GetSx3Cache(aFields[nX],"X3_USADO")) .or. aFields[nX] == "B1_FILIAL"
						//Adiciona os campos para o ExecAuto de acordo com json passado.
						IF VALTYPE(oJsonRec[aFields[nX]]) != "U"
							If GetSx3Cache(aFields[nX],"X3_TIPO") == "D"
								aAdd(aComPro, {aFields[nX], ctod(oJsonRec[aFields[nX]]), Nil})
							ElseIf GetSx3Cache(aFields[nX],"X3_TIPO") == "N"
								aAdd(aComPro, {aFields[nX], Val(oJsonRec[aFields[nX]]), Nil})
							Else
								aAdd(aComPro, {aFields[nX], AVKEY(oJsonRec[aFields[nX]],aFields[nX]), Nil})
							EndIf
						EndIf
					EndIf
				Next nX

				//--Atualiza ZB1 com informações passadas via integração.
				If !Empty(aComPro)
					aEmp := {"01","09"}
					For nY := 1 to Len(aEmp)
						ZB1->(dbSetOrder(1))
						If ZB1->(dbSeek(AvKey(aEmp[nY],"ZB1_FILIAL")+SB1->B1_COD))
							RecLock("ZB1",.F.)
								For nX := 1 To Len(aComPro)
									ZB1->&(aComPro[nX][1]) :=aComPro[nX][2]
								Next nX 
							ZB1->(MsUnLock())
						Else
							RecLock("ZB1",.T.)
								ZB1_FILIAL :=SB1->B1_FILIAL
								ZB1_COD := SB1->B1_COD
								ZB1_DTSTAT := DDATABASE
								ZB1_HRSTAT := TIME()
								ZB1_USSTAT := cUserName
								For nX := 1 To Len(aComPro)
									ZB1->&(aComPro[nX][1]) :=aComPro[nX][2]
								Next nX 
							ZB1->(MsUnLock())
						EndIf
					Next nY
				EndIf
			EndIf

			If lErro
				//--Retorno Erro
				SetRestFault(403, StrTran( cLogMsg, CHR(13)+CHR(10), " " ))
				lRet := .F.
			Else
				oJson1['status'] 		:= "200"
				oJson1['mensagem'] 		:= "Sucesso na efetivação do pre-produto!"	

				//--Retorno ao json
				::SetResponse(oJson1)
				lRet := .T.
			EndIf

		EndIf

	EndIf

    FWRestArea(aArea)

	//RpcClearEnv()

Return(lRet)
