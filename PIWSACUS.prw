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

@author		.iNi Sistemas - LTN
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
Web Service Rest Cotação de vendas ( POST / PUT / DELETE )
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
WSRESTFUL PIWSACUS DESCRIPTION "Serviço REST - Atualiza Custo Produto" FORMAT "application/json"

	
	WSDATA c_fil 		AS STRING OPTIONAL
	WSDATA c_Prod 	    AS STRING OPTIONAL
    WSDATA n_Cust 	    AS STRING OPTIONAL
    WSDATA d_Valid 	    AS STRING OPTIONAL

	//WSMETHOD POST DESCRIPTION "Recebe dados e inclui Cotação de Vendas" WSSYNTAX "/PIWSACUS?c_fil={param}" //PATH "incluiCotacao" 
	WSMETHOD PUT DESCRIPTION "Recebe de atualização de custo" WSSYNTAX "/PIWSACUS?c_fil={param},c_Prod={param},n_Cust={param},d_Valid={param}" //PATH "alteraCotacao"
	

END WSRESTFUL




//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} PUT 
Metodo para receber dados e realizar atualizaçãod e custo.
@author		.iNi Sistemas
@since     	21/06/2023
@version  	P.12
@param 		c_fil - Filial
@param 		c_Prod - Código do produto
@param 		n_Cust - Custo
@param 		d_Valid - Validade
@return    	lRet - Retorna sucesso ou erro de execução.
@obs        Serviço REST para ambiente WEB
Alterações Realizadas desde a Estruturação Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//----------------------------------------------------------------------------------------------
WSMETHOD PUT WSRECEIVE c_fil, c_Prod, n_Cust, d_Valid WSSERVICE PIWSACUS

	Local aArea     := {}
	Local oJson := JsonObject():New()
	Local cRet := ""
	Local lRet := .T.
	Local aRet := {}
    Local cFil   := self:c_fil
    Local cCodPa := self:c_Prod
    Local nCust  := self:n_Cust
    Local dValid := self:d_Valid

	aArea     := FWGetArea()

	cBody := ::GetContent()
	::SetContentType('application/json;charset=UTF-8')

	cRet := oJson:FromJson(cBody)
	
	If ValType(cRet) == "C"
		SetRestFault(403, "Falha ao transformar texto em objeto json. Erro: " + cRet)
		lRet := .F.
	endif
	If lRet 
		If Empty(self:c_fil)
		//If Empty(c_fil)
			SetRestFault(403, "Parametro obrigatorio vazio. (Filial)")
			lRet := .F.
		EndIf

		If Empty(self:c_Prod)
		//If Empty(cCotacao)
			SetRestFault(403, "Parametro obrigatorio vazio. (Produto)")
			lRet := .F.
		EndIf

		If Empty(self:n_Cust)
		//If Empty(cCotacao)
			SetRestFault(403, "Parametro obrigatorio vazio. (Custo)")
			lRet := .F.
		EndIf

        If Empty(self:d_Valid)
		//If Empty(cCotacao)
			SetRestFault(403, "Parametro obrigatorio vazio. (Dt Validade)")
			lRet := .F.
		EndIf

	EndIf

	If lRet 

		//cFilAnt := c_fil
		//cEmpAnt	:= substr(c_fil,1,2)		
		cFilAnt := self:c_fil
		cEmpAnt	:= substr(self:c_fil,1,2)
		SM0->(dbSetOrder(1))
		SM0->(DbSeek(cEmpAnt+cFilAnt))

		//--Chama função para atualização de custo.
        CustProd(cFil,cCodPa,nCust,dValid)

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

/*
*Criar endpoint que recebe os dados da filial, produto, custo e validade

1-Calcular o preço pricing do produto acrescentando o estorno de Icms + custo transformação
2-Verificar a filial onde o produto pode também ser vendido (De/Para - SZX) e calcular o custo pricing transferência:
3-Custo price = Custo Enviado + Estorno de ICMS na origem + Custo Transformação + Frete de Transferência + Estorno do icms no destino. 
4-Gravar os custos nas respectivas filiais utilizando a forma de cálculo devida.

*O Endpoint de criação do pré-produto vai receber o custo formula por KG e deve calcular o custo pricing na unidade fabril informada*/
Static Function CustProd(cFil,cCodPa,nCust,dValid)

	Local nFatEICMOr := 0 // Fator de Estorno de ICMS da Origem
    Local nFEICMDe := 0 // Fator de Estorno de ICMS do destino
	Local nCalCus    := 0
    Local nCusTran    := 0 // Custo contemplando frete de transferência.
    Local nCalCusD    := 0 //Custo com estorno do icms no destino.
    Local aFilTr := {}
    Local cAlias := ""
    Local nX     := 0
	//Local nCusBri    := 0

	SBZ->(dbSetorder(1))
	SBZ->(dbSeek(xFilial("SBZ")+AvKey(cCodPa,'BZ_COD')))

	SB1->(dbSetOrder(1))
	SB1->(dbSeek(xFilial("SB1")+AvKey(cCodPa,'B1_COD')))

	//--Agora faço o calculo do custo, e gravo no produto da filial corrente, e das filiais De/Para
	nFatEICMOr := SBZ->BZ_ZCARTRB
	
	if nFatEICMOr == 0
		SBM->(dbSetOrder(1))
		if SBM->(dbSeek(xFilial('SBM')+SB1->B1_GRUPO))
			nFatEICMOr := SBM->BM_ZCARTRB
		endif
	endif

	//nCust := ( (nAtuCus / nQtdBase) * SB1->B1_PESBRU )
	nCalCus :=  u_FCalcPerBril(u_FCalcEstICMS(nCust,nFatEICMOr))

    RecLock("SBZ",.F.)
        SBZ->BZ_ZCUSPRI := nCalCus
        SBZ->BZ_ZDTCUSP := dValid
    SBZ->(MsUnLock())



    //--Agora preciso ir na tabela SZX e calcular o custo pricing com o frete de transferência e estorno do icms no destino.
    cAlias := GetNextAlias()
    cQuery := "SELECT ZX_FILIAL FROM "+RetSqlName("SZX")+" SZX "
    cQuery += " WHERE ZX_FILORI = "+cFil+" SBZ " 
    cQuery += " AND ZX_PRODUTO = "+cCodPa+" "
    cQuery += " AND ZX_ATIVO = '1' 
    cQuery += " AND SZX.D_E_L_E_T_ <> '*'
    dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAlias, .T., .T.)	

    (cAlias)->(dbGoTop())
    While (cAlias)->(Eof())
        AADD(aFilTr,(cAlias)->ZX_FILIAL)
        (cAlias)->(dbSkip())
    EndDo
    (cAlias)->(dbCLoseArea())


    For nX := 1 to Len(aFilTr)

        nCusTran := u_FBUSFRETRA(cFil,aFilTr[nX],cCodPa) //--Contemplando o Frete de Transferência.

        SBZ->(dbSetorder(1))
        If SBZ->(dbSeek(aFilTr[nX]+AvKey(cCodPa,'BZ_COD')))

            //--Agora faço o calculo do custo, e gravo no produto da filial corrente, e das filiais De/Para
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

        Else

        EndIf


    Next nX


Return()
