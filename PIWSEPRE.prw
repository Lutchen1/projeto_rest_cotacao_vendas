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
	WSDATA c_CodPro 	AS STRING OPTIONAL
	WSDATA c_IdFlui	 	AS STRING OPTIONAL
	WSDATA c_FilPro	 	AS STRING OPTIONAL //Filial produtiva.

	WSMETHOD POST DESCRIPTION "Recebe dados e efetiva pre-produtos incluindo produto." WSSYNTAX "/PIWSEPRE?c_CodPre={param},c_CodPro={param},c_IdFlui={param},c_FilPro={param}" //PATH "incluiCotacao" 
	

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
//WSMETHOD POST WSRECEIVE c_CodPre,c_CodPro,c_IdFlui,c_FilPro WSSERVICE PIWSEPRE
User Function fIncPre()

    Local cTabela   := "SB1"
    Local aCabec    := {}
	Local aFields := {}
	Local nX := 0
	Local nY := 0
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
	Local cCodSeq := ""
	Local cPrdSimi := ""
	Local aRet := {}
	Local cBody := ""
    Private lMsErroAuto := .F.
	Private oModel      := Nil
	Private aRotina     := {}
	Private INCLUI      := .T.
	Private ALTERA      := .F.
	Private l010Auto    := .T.
	Private lMsHelpAuto   := .F.
	Private lAutoErrNoFile:= .T.

	//DEFAULT c_fil := "01"
	DEFAULT c_CodPre := "61383"
	DEFAULT c_CodPro := "TSTLNT2"
	DEFAULT c_filPro := "010025"
	DEFAULT c_IdFlui := "00000003"

	RpcSetEnv("01","010001","pontoini","Mudar.2023")

	//aArea     := FWGetArea()
	
	Begin Transaction 

	SZA->(dbSetOrder(1))
	If !SZA->(dbSeek(xFilial("SZA")+/*self:*/c_CodPre))
		SetRestFault(403, "Pre-produto nao encontrado: " + /*self:*/c_CodPre)
		lRet := .F.
	Else

		If Empty(SZA->ZA_DTEFETI)	

			SB1->(dbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+SZA->ZA_PRDSIMI))

			cPrdSimi := SZA->ZA_PRDSIMI
			
			//--Faz a busca do codigo sequencial ou não, dependendo do grupo do produto e faz validações.
			If Posicione("SBM",1,xFilial("SBM") + SB1->B1_GRUPO,"BM_ZCODAUT") == '1' 
				If Empty(/*self:*/c_CodPro)
					cCodSeq := U_TIVRO061("SB1","B1_COD",4,7,SB1->B1_GRUPO)  
				Else
					SetRestFault(403, "Codigo do produto a ser gerado mao deve ser informado para grupo de produto que gera codigo automaticamente!")
					lRet := .F.
				EndIf
			Else
				If !Empty(/*self:*/c_CodPro)
					cCodSeq := /*self:*/c_CodPro
				Else
					SetRestFault(403, "Codigo do produto a ser gerado nao informado (c_CodPro) ")
					lRet := .F.
				EndIf
			EndIf

			If lRet

				//--Campos que vem do pré-produto e produto similar.
				aAdd(aCabec, {"B1_FILIAL",xFilial("SB1"), Nil})
				aAdd(aCabec, {"B1_COD",cCodSeq, Nil})
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

			EndIf

			If lRet 
				//If Empty(self:c_CodPre)
				If Empty(c_CodPre)
					SetRestFault(403, "Parametro obrigatorio vazio. (Codigo pre-produto)")
					lRet := .F.
				EndIf
			EndIf

			If lRet 
				//If Empty(self:c_IdFlui)
				If Empty(c_IdFlui)
					SetRestFault(403, "Parametro obrigatorio vazio. (Id do Fluig)")
					lRet := .F.
				EndIf
			EndIf

			if lRet
				If Empty(/*self:*/c_FilPro) .and. !Empty(SB1->B1_ZKITACE)
				//If Empty(c_IdFlui)
					SetRestFault(403, "Parametro obrigatorio vazio para produto que criga estrutura. (Filial produtiva)")
					lRet := .F.
				EndIf
			EndIf


			If lRet 

				If !Empty(/*self:*/c_FilPro)
					cFilAnt := /*self:*/c_FilPro
				Else
					cFilAnt := "010001"
				EndIf
				cEmpAnt	:= substr(cFilAnt,1,2)
				SM0->(dbSetOrder(1))
				SM0->(DbSeek(cEmpAnt+cFilAnt))

				oModel := FwLoadModel ("MATA010")
				SetFunName("MATA010")

				nOpcao := MODEL_OPERATION_INSERT

				//Campos vindo do webservice para substituir do array principal.
				/*cBody := '{ '
				cBody += '"B1_GRUPO" : "0002",'    
				cBody += '"ZB1_PRDCUS" : "05"'    
				cBody += ' }'*/
				/*cBody := ::GetContent()
				::SetContentType('application/json;charset=UTF-8')*/
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
					Next nX
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
					cCodPro := SB1->B1_COD
					aEmp := {"01","09"}
					If !Empty(aComPro)
						aEmp := {"01","09"}
						For nY := 1 to Len(aEmp)
							ZB1->(dbSetOrder(1))
							If ZB1->(dbSeek(AvKey(aEmp[nY],"ZB1_FILIAL")+SB1->B1_COD))
								RecLock("ZB1",.F.)
									For nX := 1 To Len(aComPro)
										ZB1->&(aComPro[nX][1]) :=aComPro[nX][2]
									Next nX 
									ZB1->ZB1_IDFLUI := /*self:*/c_IdFlui
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
									ZB1_IDFLUI := /*self:*/c_IdFlui
								ZB1->(MsUnLock())
							EndIf
							
						Next nY 
					EndIf

					//--Atualizo produto com a informação do pré-produto que foi efetivado e gerou o produto.
					For nY := 1 to Len(aEmp)
						SB1->(dbSetOrder(1))
						If SB1->(dbSeek(AvKey(aEmp[nY],"B1_FILIAL")+cCodPro))
							RecLock("SB1",.F.)
								B1_ZPREPRD := /*self:*/c_CodPre
							SB1->(MsUnLock())
						EndIf
					Next nY

					If Empty(SZA->ZA_PRDEFET) 
						Reclock("SZA",.F.)
							SZA->ZA_PRDEFET := cCodPro
							SZA->ZA_DTEFETI := dDataBase
						SZA->(MsUnLock())
					EndIF
		
					
				EndIf

				If lErro
					//--Retorno Erro
					SetRestFault(403, StrTran( cLogMsg, CHR(13)+CHR(10), " " ))
					lRet := .F.
				Else

					SB1->(dbSetOrder(1))
					if SB1->(dbSeek(xFilial("SB1")+cPrdSimi))
						If !Empty(SB1->B1_ZKITACE)

							aRet := fPrdFan(aCabec,"6"+substring(cPrdSimi,2,len(cPrdSimi)),c_FilPro)

							If aRet[1] //--Se Erro
							
								cLogMsg += aRet[2]
								SetRestFault(403, StrTran( cLogMsg, CHR(13)+CHR(10), " " ))
								lRet := .F.
								lErro := .T.
								DisarmTransaction()
							EndIf

						Else
							
						EndIf
					Else
						

					EndIf
					
					if !lErro

						oJson1['status'] 		:= "200"
						oJson1['mensagem'] 		:= "Sucesso na efetivacao do pre-produto!"	

						//--Retorno ao json
						//::SetResponse(oJson1)
						//lRet := .T.

					EndIf

				EndIf

			EndIf

		Else
			SetRestFault(403, "Pre-produto "+AllTrim(/*self:*/c_CodPre)+" ja efetivado")
			lRet := .F.
		EndIf

	EndIf


	End Transaction 

    //FWRestArea(aArea)

	RpcClearEnv()

Return(lRet)


Static Function fPrdFan(aCabec,cPrdSimi,c_FilPro)

Local lErro := .F.
Local aErroExec :={}
Local cLogMsg := ""
Local nX := 0
Local cProd := ""
Local aRet := {}
Local nOpcao := MODEL_OPERATION_INSERT
Private lMsErroAuto := .F.
Private oModel      := Nil
Private aRotina     := {}
Private INCLUI      := .T.
Private ALTERA      := .F.
Private l010Auto    := .T.
Private lMsHelpAuto   := .F.
Private lAutoErrNoFile:= .T.

	aCabec[aScan(aCabec,{|x|AllTrim(x[1])=="B1_COD"})][2] := "6"+substring(aCabec[aScan(aCabec,{|x|AllTrim(x[1])=="B1_COD"})][2],2,len(aCabec[aScan(aCabec,{|x|AllTrim(x[1])=="B1_COD"})][2]))

	aAdd(aCabec, {"B1_FANTASM","S", Nil})	

	aCabec := FWVetByDic( aCabec, 'SB1' )

	oModel := FwLoadModel ("MATA010")
	SetFunName("MATA010")

	//Chamando a inclusão - Modelo 1
	lMsErroAuto := .F.
		
	FWMVCRotAuto( oModel,"SB1",nOpcao,{{"SB1MASTER", aCabec}})
			
	//Se houve erro no ExecAuto, mostra mensagem
	If lMsErroAuto
		aErroExec := GetAutoGRLog() //Buscar o erro reportado pelo execauto
		cLogMsg += "Erro na criação do produto fantasma"+Chr(13) + Chr(10)
		For nX := 1 To Len(aErroExec)
			cLogMsg += aErroExec[nX]+ Chr(13) + Chr(10)
		Next nX
		lErro := .T.
	Else

		cProd := aCabec[aScan(aCabec,{|x|AllTrim(x[1])=="B1_COD"})][2] 
		//Incluo Estrutura do produto fantasma de acordo com produto similar.
		aRet := fIncEst(cProd,cPrdSimi,c_FilPro)

		If aRet[1] //--Se Erro
			cLogMsg += aRet[2]
			lRet := .F.
			lErro := .T.
			DisarmTransaction()
		EndIf

	EndIf

Return({lErro,cLogMsg})



Static Function fIncEst(cProd,cPrdSimi,c_FilPro)

Local cQuery 	:= ""
Local cAlias 	:= GetNextAlias()
Local aCabec 	:={}
Local aComp 	:= {}
Local aGets 	:= {}
Local lErro 	:= .F.
Local aErroExec :={}
Local cLogMsg 	:= ""
Local nX 		:= 0
Local cFili := ""
Private lMsErroAuto := .F.
Private lMsHelpAuto   := .F.
Private lAutoErrNoFile:= .T.

cQuery := "SELECT * FROM "+RetSqlName("SG1")+" SG1 " 
cQuery += "WHERE G1_COD = '"+cPrdSimi+"' "
cQuery += "AND G1_FILIAL =  '"+c_FilPro+"' "
cQuery += "AND SG1.D_E_L_E_T_ <> '*' "

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .T., .T.)	
 
aCabec := {{"G1_COD",cProd,NIL},;
            {"G1_QUANT",1,NIL},;
            {"NIVALT","S",NIL}} // A variavel NIVALT eh utilizada pra recalcular ou nao a estrutura

(cAlias)->(dbGoTop())
If !(cAlias)->(Eof())
	cFili := (cAlias)->G1_FILIAL
	While !(cAlias)->(Eof()) .AND. cFili == (cAlias)->G1_FILIAL

		aGets := {}
		aadd(aGets,{"G1_COD",cProd,NIL})
		aadd(aGets,{"G1_COMP",(cAlias)->G1_COMP,NIL})
		aadd(aGets,{"G1_TRT",(cAlias)->G1_TRT,NIL})
		aadd(aGets,{"G1_QUANT",(cAlias)->G1_QUANT,NIL})
		aadd(aGets,{"G1_PERDA",(cAlias)->G1_PERDA,NIL})
		aadd(aGets,{"G1_INI",(cAlias)->G1_ININIL})
		aadd(aGets,{"G1_FIM",(cAlias)->G1_FIM,NIL})
		aadd(aComp,aGets)

		(cAlias)->(dbSkip())
	EndDo 
EndIf

(cAlias)->(dbCloseArea())

If Empty(aComp)

	cAlias := GetNextALias()
	cQuery := "SELECT * FROM "+RetSqlName("SG1")+" SG1 " 
	cQuery += "WHERE G1_COD = '"+cPrdSimi+"' "
	cQuery += "AND SG1.D_E_L_E_T_ <> '*' "

	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .T., .T.)	

	(cAlias)->(dbGoTop())
	If !(cAlias)->(Eof())
		cFili := (cAlias)->G1_FILIAL
		While !(cAlias)->(Eof()) .AND. cFili == (cAlias)->G1_FILIAL

			aGets := {}
			aadd(aGets,{"G1_COD",cProd,NIL})
			aadd(aGets,{"G1_COMP",(cAlias)->G1_COMP,NIL})
			aadd(aGets,{"G1_TRT",(cAlias)->G1_TRT,NIL})
			aadd(aGets,{"G1_QUANT",(cAlias)->G1_QUANT,NIL})
			aadd(aGets,{"G1_PERDA",(cAlias)->G1_PERDA,NIL})
			aadd(aGets,{"G1_INI",(cAlias)->G1_INI,NIL})
			aadd(aGets,{"G1_FIM",(cAlias)->G1_FIM,NIL})
			aadd(aComp,aGets)

			(cAlias)->(dbSkip())
		EndDo 
	EndIf
	(cAlias)->(dbCloseArea())

EndIf

If !Empty(aComp)
 
	MSExecAuto({|x,y,z| mata200(x,y,z)},aCabec,aComp,3)

	If lMsErroAuto
		aErroExec := GetAutoGRLog() //Buscar o erro reportado pelo execauto
		cLogMsg += "Erro na criação da estrutura do produto fantasma"+Chr(13) + Chr(10)
		For nX := 1 To Len(aErroExec)
			cLogMsg += aErroExec[nX]+ Chr(13) + Chr(10)
		Next nX
		lErro := .T.
	Else
	EndIf

Else

	cLogMsg += "Não encontrado estrutura de produto similar"
	lErro := .T.

EndIf

Return({lErro,cLogMsg})

