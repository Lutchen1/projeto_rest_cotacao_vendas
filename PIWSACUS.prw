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

Alter��es Realizadas desde a Estrutura��o Inicial
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
Web Service Rest atualiza��o de custo de produto e pr�-produto (PUT)
@author		.iNi Sistemas (LTN)
@since     	22/06/2023	
@version  	P.12
@param 		c_fil - Filial
@param 		c_Cod - C�digo do produto
@param 		n_Cust - Custo
@param 		c_Valid - Validade
@param 		c_Tipo - 1-Produto 2=Pr�-Produto
@return    	Nenhum
@obs        Servi�o REST para ambiente WEB
Altera��es Realizadas desde a Estrutura��o Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
WSRESTFUL PIWSACUS DESCRIPTION "Servi�o REST - Atualiza Custo Produto/Pr�-Produto" FORMAT "application/json"

	
	WSDATA c_fil 		AS STRING OPTIONAL
	WSDATA c_Cod 	    AS STRING OPTIONAL
    WSDATA n_Cust 	    AS INTEGER
    WSDATA c_Valid 	    AS STRING OPTIONAL
	WSDATA c_Tipo 	    AS STRING OPTIONAL

	WSMETHOD PUT DESCRIPTION "Recebe de atualiza��o de custo" WSSYNTAX "/PIWSACUS?c_fil={param},c_Cod={param},n_Cust={param},c_Valid={param},c_Tipo={param}" 
	

END WSRESTFUL


//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} PUT 
Metodo para receber dados e realizar atualiza��o de custo.
@author		.iNi Sistemas (LTN)
@since     	21/06/2023
@version  	P.12
@param 		c_fil - Filial
@param 		c_Cod - C�digo do produto
@param 		n_Cust - Custo
@param 		c_Valid - Validade
@param 		c_Tipo - 1-Produto 2=Pr�-Produto
@return    	lRet - Retorna sucesso ou erro de execu��o.
@obs        Servi�o REST para ambiente WEB
Altera��es Realizadas desde a Estrutura��o Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//----------------------------------------------------------------------------------------------
WSMETHOD PUT WSRECEIVE c_fil, c_Cod, n_Cust, c_Valid, c_Tipo WSSERVICE PIWSACUS

	Local aArea     := {}
	Local lRet := .T.
	Local aRet := {}
    Local cFil   := self:c_fil
    Local cCod	 := self:c_Cod
    Local nCust  := self:n_Cust
    Local dValid := ctod(" / / ")
	Local cTipo := self:c_Tipo

	aArea     := FWGetArea()

	If lRet 
		If Empty(cFil)
		//If Empty(c_fil)
			SetRestFault(403, "Parametro obrigatorio vazio. (Filial)")
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
	
		cFilAnt := cFil
		cEmpAnt	:= substr(cFil,1,2)
		SM0->(dbSetOrder(1))
		SM0->(DbSeek(cEmpAnt+cFilAnt))

		If cTipo == "1" //--Produto
			//--Chama fun��o para atualiza��o de custo do produto
        	aRet := _CustProd(cFil,cCod,nCust,dValid)	
		ElseIf cTipo == "2" //--Pr�-Produto
			//--Chama fun��o para atualiza��o de custo do pr�-produto
			aRet := _CustPreP(cFil,cCod,nCust,dValid)
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
Fun��o que atualiza custo do produto no indicador de produtos (SBZ).

@author		.iNi Sistemas (LTN)
@since     	22/06/2023	
@version  	P.12
@param 		cFil,cCodPa,nCust,dValid
@return    	lErro, cMsg, oJson1
@obs        
Altera��es Realizadas desde a Estrutura��o Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
Static Function _CustProd(cFil,cCodPa,nCust,dValid)

	Local nFatEICMOr := 0 // Fator de Estorno de ICMS da Origem
    Local nFEICMDe := 0 // Fator de Estorno de ICMS do destino
	Local nCalCus    := 0
    Local nCusTran    := 0 // Custo contemplando frete de transfer�ncia.
    Local nCalCusD    := 0 //Custo com estorno do icms no destino.
    Local aFilTr := {}
    Local cAlias := ""
    Local nX     := 0
	Local lErro := .F.
	Local cMsg := ""
	Private oJson1 	:= JsonObject():New()

	//RpcSetEnv("01","010080")

	SBZ->(dbSetorder(1))
	SBZ->(dbSeek(xFilial("SBZ")+AvKey(cCodPa,'BZ_COD')))

	SB1->(dbSetOrder(1))
	If SB1->(dbSeek(xFilial("SB1")+AvKey(cCodPa,'B1_COD')))	

	//--Agora fa�o o calculo do custo, e gravo no produto da filial corrente, e das filiais De/Para
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

    //--Agora preciso ir na tabela SZX e calcular o custo pricing com o frete de transfer�ncia e estorno do icms no destino.
    cAlias := GetNextAlias()
    cQuery := "SELECT ZX_FILIAL FROM "+RetSqlName("SZX")+" SZX "
    cQuery += " WHERE ZX_FILORI = '"+cFil+"' " 
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

        nCusTran := u_FBUSFRETRA(cFil,aFilTr[nX],cCodPa) //--Contemplando o Frete de Transfer�ncia.

        SBZ->(dbSetorder(1))
        If SBZ->(dbSeek(aFilTr[nX]+AvKey(cCodPa,'BZ_COD')))

            //--Agora fa�o o calculo do custo, e gravo no produto da filial corrente, e das filiais De/Para
            nFEICMDe := SBZ->BZ_ZCARTRB
            
            if nFEICMDe == 0
                SBM->(dbSetOrder(1))
                if SBM->(dbSeek(xFilial('SBM')+SB1->B1_GRUPO))
                    nFEICMDe := SBM->BM_ZCARTRB
                endif
            endif        

            nCalCusD :=  u_FCalcEstICMS(nCalCus+nCusTran,nFEICMDe)

            RecLock("SBZ",.F.)
                SBZ->BZ_ZCUSPRI := nCalCusD
                SBZ->BZ_ZDTCUSP := dValid
            SBZ->(MsUnLock())

			lErro := .F.
			oJson1['status'] 		:= "200"
			oJson1['mensagem'] 		:= "Sucesso na atualizacao do custo do produto!"	

        Else

        EndIf

    Next nX

	Else
		lErro := .T.
		cMsg := "Produto nao encontrado"
	EndIf

	//RpcClearEnv()

Return({lErro,cMsg,oJson1})


//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} _CustPreP
Fun��o que atualiza custo do pr�-produto (SZA - ZA_ZCUSBRI).

@author		.iNi Sistemas (LTN)
@since     	22/06/2023	
@version  	P.12
@param 		cFil,cCodPa,nCust,dValid
@return    	lErro, cMsg, oJson1
@obs        
Altera��es Realizadas desde a Estrutura��o Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
Static Function _CustPreP(cFil,cCodPre,nCust,dValid)

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
	Private oJson1 	:= JsonObject():New()

	//RpcSetEnv("01","010080")
	
	aFilCus  := FWAllFilial(cEmpAnt,,,.F.)

	
	SZA->(dbSetOrder(1))
	If SZA->(dbSeek(xFilial("SZA")+cCodPre))

		cPrdSim := SZA->ZA_PRDSIMI

		SBZ->(dbSetorder(1))
		SBZ->(dbSeek(xFilial("SBZ")+AvKey(cPrdSim,'BZ_COD')))

		SB1->(dbSetOrder(1))
		SB1->(dbSeek(xFilial("SB1")+AvKey(cPrdSim,'B1_COD')))

		//--Agora fa�o o calculo do custo, e gravo no produto da filial corrente, e das filiais De/Para
		nFatEICMOr := SBZ->BZ_ZCARTRB
		
		If nFatEICMOr == 0
			SBM->(dbSetOrder(1))
			if SBM->(dbSeek(xFilial('SBM')+SB1->B1_GRUPO))
				nFatEICMOr := SBM->BM_ZCARTRB
			endif
		endif

		nCalCus :=  u_FCalcPerBril(u_FCalcEstICMS(nCust,nFatEICMOr))


		//--Verifico se existe informa��o no custo brill.
		aDados := IIF(!Empty(AllTrim(SZA->ZA_ZCUSBRI)),StrTokArr2(SZA->ZA_ZCUSBRI,"/"),{})

		//--Montagem de informa��es do campo custo brill.
		For xI := 1 To Len(aFilCus)
			nPosFil := aScan(aDados,{|a| SubStr(a,1,Len(aFilCus[xI])) == aFilCus[xI]})
			aArrAux	:= {}

			//--Verifica se ja existe registros gravados no campo.
			If Len(aDados) > 0 .And. nPosFil > 0
				aArrAux := StrTokArr2(aDados[nPosFil],"-")
			Endif

			//--Montagem dos registros, caso n�o exista cria zerado.
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
		For xI := 1 To Len(aArray)
			cValores += SubStr(aArray[xI][1],1,6) + " - " + AllTrim(Str(aArray[xI][2])) + " - " + AllTrim(DTOS(aArray[xI][3])) + "/"
		Next xI
		cValores := SubStr(cValores,1,Len(cValores) - 1)

		//--Identifico a filial e gravo o custo do pr�-produto para a filial correta e atualizo valores.
		aCstPrd := StrTokArr2(cValores,"/")		
		aCstPrd[ASCAN(aCstPrd ,{|a| SubStr(a,1,Len(xFilial("SBZ"))) == xFilial("SBZ")})] := xFIlial("SBZ")+" - "+AllTrim(Str(nCalCus))+" - "+dtos(dValid)//REPLACE(dtoc(YearSum(ddatabase,1)),"/","")
		For xI := 1 to Len(aCstPrd)
			cAtuCus += aCstPrd[xI]+"/"
		Next xI

		//--Gravo a atualiza��o do custo na SZA.
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
   
	//RpcClearEnv()

Return({lErro,cMsg,oJson1})
