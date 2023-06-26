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
{Protheus.doc} PIWSACUS
Fonte reservado rest.

@author		.iNi Sistemas (LTN)
@since     	21/06/2023	
@version  	P.12
@return    	Nenhum
@obs        Nenhum

Alterções Realizadas desde a Estruturação Inicial
------------+-----------------+---------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+---------------------------------------------------------
/*/
//--------------------------------------------------------------------------------------- 
User Function PIWSACUS()

Return()

//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} PIWSACUS
Web Service Rest atualização de custo de produto e pré-produto (PUT)
@author		.iNi Sistemas (LTN)
@since     	22/06/2023	
@version  	P.12
@param 		c_fil - Filial
@param 		c_Cod - Código do produto
@param 		n_Cust - Custo
@param 		c_Valid - Validade
@param 		c_Tipo - 1-Produto 2=Pré-Produto
@return    	Nenhum
@obs        Serviço REST para ambiente WEB
Alterações Realizadas desde a Estruturação Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
WSRESTFUL PIWSACUS DESCRIPTION "Serviço REST - Atualiza Custo Produto/Pré-Produto" FORMAT "application/json"
	
	WSDATA c_filPrd 	AS STRING OPTIONAL
	WSDATA c_filVen 	AS STRING OPTIONAL
	WSDATA c_Cod 	    AS STRING OPTIONAL
    WSDATA n_Cust 	    AS INTEGER
    WSDATA c_Valid 	    AS STRING OPTIONAL
	WSDATA c_Tipo 	    AS STRING OPTIONAL

	WSMETHOD PUT DESCRIPTION "Recebe de atualização de custo" WSSYNTAX "/PIWSACUS?c_filPrd={param},c_filVen={param},c_Cod={param},n_Cust={param},c_Valid={param},c_Tipo={param}" 	

END WSRESTFUL

//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} PUT 
Metodo para receber dados e realizar atualização de custo.
@author		.iNi Sistemas (LTN)
@since     	21/06/2023
@version  	P.12
@param 		c_fil - Filial
@param 		c_Cod - Código do produto
@param 		n_Cust - Custo
@param 		c_Valid - Validade
@param 		c_Tipo - 1-Produto 2=Pré-Produto
@return    	lRet - Retorna sucesso ou erro de execução.
@obs        Serviço REST para ambiente WEB
Alterações Realizadas desde a Estruturação Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//----------------------------------------------------------------------------------------------
WSMETHOD PUT WSRECEIVE c_filPrd,c_filVen, c_Cod, n_Cust, c_Valid, c_Tipo WSSERVICE PIWSACUS

	Local aArea     := {}
	Local lRet := .T.
	Local aRet := {}
    Local cFilPrd   := self:c_filPrd
	Local cFilVen   := self:c_filVen
    Local cCod	 := self:c_Cod
    Local nCust  := self:n_Cust
    Local dValid := ctod(" / / ")
	Local cTipo := self:c_Tipo

	aArea     := FWGetArea()

	If lRet 
		If Empty(cFilPrd)
		//If Empty(c_fil)
			SetRestFault(403, "Parametro obrigatorio vazio. (Filial Produção)")
			lRet := .F.
		EndIf

		If Empty(cFilVen)
		//If Empty(c_fil)
			SetRestFault(403, "Parametro obrigatorio vazio. (Filial Venda)")
			lRet := .F.
		EndIf

		If Empty(cCod)
		//If Empty(cCotacao)
			SetRestFault(403, "Parametro obrigatorio vazio. (Produto)")
			lRet := .F.
		EndIf

		If Empty(nCust)
		//If Empty(cCotacao)
			SetRestFault(403, "Parametro obrigatorio vazio. (Custo)")
			lRet := .F.
		EndIf

        If Empty(self:c_Valid)
		//If Empty(cCotacao)
			SetRestFault(403, "Parametro obrigatorio vazio. (Dt Validade)")
			lRet := .F.
		Else
			dValid := stod(self:c_Valid)
		EndIf

		If Empty(cTipo)
		//If Empty(cCotacao)
			SetRestFault(403, "Parametro obrigatorio vazio. (Tipo 1=Produto 2=pre-produto)")
			lRet := .F.
		EndIf

	EndIf

	If lRet 
	
		cFilAnt := cFilPrd
		cEmpAnt	:= substr(cFilPrd,1,2)
		SM0->(dbSetOrder(1))
		SM0->(DbSeek(cEmpAnt+cFilAnt))

		If cTipo == "1" //--Produto
			//--Chama função para atualização de custo do produto
        	aRet := _CustProd(cFilPrd,cFilVen,cCod,nCust,dValid)	
		ElseIf cTipo == "2" //--Pré-Produto
			//--Chama função para atualização de custo do pré-produto
			aRet := _CustPreP(cFilPrd,cFilVen,cCod,nCust,dValid)
		EndIf 

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

    FWRestArea(aArea)

	//RpcClearEnv()

Return(lRet)

//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} _CustProd
Função que atualiza custo do produto no indicador de produtos (SBZ).

@author		.iNi Sistemas (LTN)
@since     	22/06/2023	
@version  	P.12
@param 		cFil,cCodPa,nCust,dValid
@return    	lErro, cMsg, oJson1
@obs        
Alterações Realizadas desde a Estruturação Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
Static Function _CustProd(cFilPrd,cFilVen,cCodPa,nCust,dValid)

	Local nFatEICMOr := 0 // Fator de Estorno de ICMS da Origem
    Local nFEICMDe := 0 // Fator de Estorno de ICMS do destino
	Local nCalCus    := 0
    Local nCusTran    := 0 // Custo contemplando frete de transferência.
    Local nCalCusD    := 0 //Custo com estorno do icms no destino.
    Local aFilTr := {}
    Local cAlias := ""
    Local nX     := 0
	Local lErro := .F.
	Local cMsg := ""
	Local lContinua := .F.
	Private oJson1 	:= JsonObject():New()

	/*default cFilPrd := "010025"
	default cFilVen := "010025"
	default cCodPa := "1688231"
	default nCust := 15
	default dValid := stod("20221022")*/

	//RpcSetEnv("01","010080")

	//--Se o produto tem Venda e Produção na mesma unidade
	If cFilPrd == cFilVen

		SBZ->(dbSetorder(1))
		SBZ->(dbSeek(cFilPrd+AvKey(cCodPa,'BZ_COD')))

		SB1->(dbSetOrder(1))
		If SB1->(dbSeek(xFilial("SB1")+AvKey(cCodPa,'B1_COD')))	

			//--Agora faço o calculo do custo, e gravo no produto da filial corrente, e das filiais De/Para
			nFatEICMOr := SBZ->BZ_ZCARTRB
			
			If nFatEICMOr == 0
				SBM->(dbSetOrder(1))
				If SBM->(dbSeek(xFilial('SBM')+SB1->B1_GRUPO))
					nFatEICMOr := SBM->BM_ZCARTRB
				Endif
			Endif

			nCalCus :=  u_FCalcPerBril(u_FCalcEstICMS(nCust,nFatEICMOr))	

			RecLock("SBZ",.F.)
				SBZ->BZ_ZCUSPRI := nCalCus
				SBZ->BZ_ZDTCUSP := dValid
			SBZ->(MsUnLock())

			//--Agora preciso ir na tabela SZX e calcular o custo pricing com o frete de transferência e estorno do icms no destino.
			cAlias := GetNextAlias()
			cQuery := "SELECT ZX_FILIAL FROM "+RetSqlName("SZX")+" SZX "
			cQuery += " WHERE ZX_FILORI = '"+cFilPrd+"' "
			cQuery += " AND ZX_PRODUTO = '"+cCodPa+"' "
			cQuery += " AND ZX_ATIVO = '1' "
			cQuery += " AND SZX.D_E_L_E_T_ <> '*' "
			dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .T., .T.)	

			(cAlias)->(dbGoTop())
			While !(cAlias)->(Eof())
				AADD(aFilTr,(cAlias)->ZX_FILIAL)
				(cAlias)->(dbSkip())
			EndDo
			(cAlias)->(dbCLoseArea())


			For nX := 1 to Len(aFilTr)

				nCusTran := u_FBUSFRETRA(cFilPrd,aFilTr[nX],cCodPa) //--Contemplando o Frete de Transferência.

				SBZ->(dbSetorder(1))
				If SBZ->(dbSeek(aFilTr[nX]+AvKey(cCodPa,'BZ_COD')))

					//--Agora faço o calculo do custo, e gravo no produto da filial corrente, e das filiais De/Para
					nFEICMDe := SBZ->BZ_ZCARTRB
					
					If nFEICMDe == 0
						SBM->(dbSetOrder(1))
						If SBM->(dbSeek(xFilial('SBM')+SB1->B1_GRUPO))
							nFEICMDe := SBM->BM_ZCARTRB
						Endif
					Endif        

					nCalCusD :=  u_FCalcEstICMS(nCalCus+nCusTran,nFEICMDe)

					RecLock("SBZ",.F.)
						SBZ->BZ_ZCUSPRI := nCalCusD
						SBZ->BZ_ZDTCUSP := dValid
					SBZ->(MsUnLock())

				Else

				EndIf

			Next nX
			
			lErro := .F.
			oJson1['status'] 		:= "200"
			oJson1['mensagem'] 		:= "Sucesso na atualizacao do custo do produto!"	

		Else
			lErro := .T.
			cMsg := "Produto nao encontrado"
		EndIf

	//--Se o produto tem Venda e Produção em unidades destintas:
	Else	

		//--Protheus verifica se existe cadastro de Origem/Destino (De/Para) para a filial de venda e se a filial de produção é a origem.
		cAlias := GetNextAlias()
		cQuery := "SELECT ZX_FILORI FROM "+RetSqlName("SZX")+" SZX "
		cQuery += " WHERE ZX_FILIAL = '"+cFilVen+"' " 
		cQuery += " AND ZX_FILORI = '"+cFilPrd+"' " 
		cQuery += " AND ZX_PRODUTO = '"+cCodPa+"' "
		cQuery += " AND ZX_ATIVO = '1' "
		cQuery += " AND SZX.D_E_L_E_T_ <> '*' "
		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .T., .T.)	

		(cAlias)->(dbGoTop())
		If !(cAlias)->(Eof())
			cFilAux := (cAlias)->ZX_FILORI
			lContinua:= .T.
		Else		
			lContinua := .F.
		EndIf
		(cAlias)->(dbCloseArea())

		If lContinua

			SBZ->(dbSetorder(1))
			SBZ->(dbSeek(cFilAux+AvKey(cCodPa,'BZ_COD')))

			SB1->(dbSetOrder(1))
			If SB1->(dbSeek(xFilial("SB1")+AvKey(cCodPa,'B1_COD')))	

				//--Agora faço o calculo do custo, e gravo no produto da filial corrente, e das filiais De/Para
				nFatEICMOr := SBZ->BZ_ZCARTRB
				
				If nFatEICMOr == 0
					SBM->(dbSetOrder(1))
					If SBM->(dbSeek(xFilial('SBM')+SB1->B1_GRUPO))
						nFatEICMOr := SBM->BM_ZCARTRB
					Endif
				Endif

				nCalCus :=  u_FCalcPerBril(u_FCalcEstICMS(nCust,nFatEICMOr))	

				RecLock("SBZ",.F.)
					SBZ->BZ_ZCUSPRI := nCalCus
					SBZ->BZ_ZDTCUSP := dValid
				SBZ->(MsUnLock())

				//--Agora preciso ir na tabela SZX e calcular o custo pricing com o frete de transferência e estorno do icms no destino.
				cAlias := GetNextAlias()
				cQuery := "SELECT ZX_FILIAL FROM "+RetSqlName("SZX")+" SZX "
				cQuery += " WHERE ZX_FILORI = '"+cFilAux+"' " 
				cQuery += " AND ZX_PRODUTO = '"+cCodPa+"' "
				cQuery += " AND ZX_ATIVO = '1' "
				cQuery += " AND SZX.D_E_L_E_T_ <> '*' "
				dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .T., .T.)	

				(cAlias)->(dbGoTop())
				While !(cAlias)->(Eof())
					AADD(aFilTr,(cAlias)->ZX_FILIAL)
					(cAlias)->(dbSkip())
				EndDo
				(cAlias)->(dbCLoseArea())


				For nX := 1 to Len(aFilTr)

					nCusTran := u_FBUSFRETRA(cFilAux,aFilTr[nX],cCodPa) //--Contemplando o Frete de Transferência.

					SBZ->(dbSetorder(1))
					If SBZ->(dbSeek(aFilTr[nX]+AvKey(cCodPa,'BZ_COD')))

						//--Agora faço o calculo do custo, e gravo no produto da filial corrente, e das filiais De/Para
						nFEICMDe := SBZ->BZ_ZCARTRB
						
						If nFEICMDe == 0
							SBM->(dbSetOrder(1))
							If SBM->(dbSeek(xFilial('SBM')+SB1->B1_GRUPO))
								nFEICMDe := SBM->BM_ZCARTRB
							Endif
						Endif        

						nCalCusD :=  u_FCalcEstICMS(nCalCus+nCusTran,nFEICMDe)

						RecLock("SBZ",.F.)
							SBZ->BZ_ZCUSPRI := nCalCusD
							SBZ->BZ_ZDTCUSP := dValid
						SBZ->(MsUnLock())

					Else

					EndIf

				Next nX
				
				lErro := .F.
				oJson1['status'] 		:= "200"
				oJson1['mensagem'] 		:= "Sucesso na atualizacao do custo do produto!"	

			Else
				lErro := .T.
				cMsg := "Produto nao encontrado"
			EndIf		

		Else
			lErro := .T.
			cMsg := "Nao ha unidade de producao cadastrada para a filial de venda solicitada."
		EndIf


	EndIf

	//RpcClearEnv()

Return({lErro,cMsg,oJson1})


//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} _CustPreP
Função que atualiza custo do pré-produto (SZA - ZA_ZCUSBRI).

@author		.iNi Sistemas (LTN)
@since     	22/06/2023	
@version  	P.12
@param 		cFil,cCodPa,nCust,dValid
@return    	lErro, cMsg, oJson1
@obs        
Alterações Realizadas desde a Estruturação Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
Static Function _CustPreP(cFilPrd,cFilVen,cCodPre,nCust,dValid)

	Local nFatEICMOr := 0 // Fator de Estorno de ICMS da Origem
	Local nCalCus    := 0
	Local cValores := ""
	Local xI	   := 0
	Local nPosFil  := 0
	Local aArray   := {}
	Local aDados   := {}
	Local aFilCus  := {}
	Local aArrAux  := {}
	Local aCstPrd  :={}
	Local cAtuCus  := ""
	Local lErro    := .F.
	Local cMsg     := ""
	Local nX 	   := 0
	Private oJson1 

	/*default cFilPrd := "010025"
	default cFilVen := "010020"
	default cCodPre := "61383"
	default nCust := 15
	default dValid := stod("20221022")*/

	//RpcSetEnv("01","010080")

	oJson1 := JsonObject():New()
	
	aFilCus  := FWAllFilial(cEmpAnt,,,.F.)

	If cFilPrd == cFilVen
		nVezes := 1 	
	Else
		nVezes := 2
	EndIf

	For nX := 1 to nVezes

		If nX == 1
			cFilAux := cFilPrd
		Else
			cFilAux := cFilVen
		EndIf
	
		SZA->(dbSetOrder(1))
		If SZA->(dbSeek(xFilial("SZA")+cCodPre))

			cPrdSim := SZA->ZA_PRDSIMI

			SBZ->(dbSetorder(1))
			SBZ->(dbSeek(cFilAux+AvKey(cPrdSim,'BZ_COD')))

			SB1->(dbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+AvKey(cPrdSim,'B1_COD')))

			//--Agora faço o calculo do custo, e gravo no produto da filial corrente, e das filiais De/Para
			nFatEICMOr := SBZ->BZ_ZCARTRB
			
			If nFatEICMOr == 0
				SBM->(dbSetOrder(1))
				If SBM->(dbSeek(xFilial('SBM')+SB1->B1_GRUPO))
					nFatEICMOr := SBM->BM_ZCARTRB
				Endif
			Endif

			nCalCus :=  u_FCalcPerBril(u_FCalcEstICMS(nCust,nFatEICMOr))


			//--Verifico se existe informação no custo brill.
			aDados := IIF(!Empty(AllTrim(SZA->ZA_ZCUSBRI)),StrTokArr2(SZA->ZA_ZCUSBRI,"/"),{})

			//--Limpo Array.
			aArray := {}

			//--Montagem de informações do campo custo brill.
			For xI := 1 To Len(aFilCus)
				nPosFil := aScan(aDados,{|a| SubStr(a,1,Len(aFilCus[xI])) == aFilCus[xI]})
				aArrAux	:= {}

				//--Verifica se ja existe registros gravados no campo.
				If Len(aDados) > 0 .And. nPosFil > 0
					aArrAux := StrTokArr2(aDados[nPosFil],"-")
				Endif

				//--Montagem dos registros, caso não exista cria zerado.
				If Len(aArrAux) == 3
					AADD(aArray,{aFilCus[xI] + " - " + FWFilialName(SubStr(aFilCus[xI],1,2),aFilCus[xI]),;
							IIF(Len(aArrAux) > 1, Val(AllTrim(aArrAux[2])), 0),;
							IIF(Len(aArrAux) > 2 .And. !Empty((AllTrim(aArrAux[3]))), STOD(AllTrim(aArrAux[3])), CTOD("//")) })
				Else
					AADD(aArray,{aFilCus[xI] + " - " + FWFilialName(SubStr(aFilCus[xI],1,2),aFilCus[xI]),;
							IIF(Len(aDados) > 0 .And. nPosFil > 0,;
								Val(SubStr(aDados[nPosFil],9,Len(aDados[nPosFil]))),;
								0),;
								CTOD("//")})
				Endif		
			Next xI

			//--Monto valores do campo custo brill.
			cValores := ""
			For xI := 1 To Len(aArray)
				cValores += SubStr(aArray[xI][1],1,6) + " - " + AllTrim(Str(aArray[xI][2])) + " - " + AllTrim(DTOS(aArray[xI][3])) + "/"
			Next xI
			cValores := SubStr(cValores,1,Len(cValores) - 1)

			//--Identifico a filial e gravo o custo do pré-produto para a filial correta e atualizo valores.
			aCstPrd := StrTokArr2(cValores,"/")		
			//aCstPrd[ASCAN(aCstPrd ,{|a| SubStr(a,1,Len(xFilial("SBZ"))) == xFilial("SBZ")})] := xFIlial("SBZ")+" - "+AllTrim(Str(nCalCus))+" - "+dtos(dValid)//REPLACE(dtoc(YearSum(ddatabase,1)),"/","")
			aCstPrd[ASCAN(aCstPrd ,{|a| SubStr(a,1,Len(cFilAux)) == cFilAux})] := cFilAux+" - "+AllTrim(Str(nCalCus))+" - "+dtos(dValid)//REPLACE(dtoc(YearSum(ddatabase,1)),"/","")
			cAtuCus := ""
			For xI := 1 to Len(aCstPrd)
				cAtuCus += aCstPrd[xI]+"/"
			Next xI

			//--Gravo a atualização do custo na SZA.
			RecLock("SZA",.F.)			
				SZA->ZA_ZCUSBRI := substring(cAtuCus,1,len(cAtuCus)-1)
			SZA->(MsUnLock())	
		
			lErro := .F.
			oJson1['status'] 		:= "200"
			oJson1['mensagem'] 		:= "Sucesso na atualizacao do custo do pre-produto!"	
		Else
			lErro := .T.
			cMsg := "Pre-Produto nao encontrado"
		EndIf   

	Next nX

	//RpcClearEnv()

Return({lErro,cMsg,oJson1})
