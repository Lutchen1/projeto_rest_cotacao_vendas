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
{Protheus.doc} cadastraOrcamento
Web Service Rest para comunicação com o App de portal do cliente
@author		.iNi Sistemas
@since     	01/04/2022
@version  	P.12
@param 		Nenhum
@return    	Nenhum
@obs        Serviço REST para ambiente WEB
Alterações Realizadas desde a Estruturação Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
WSRESTFUL cadastraOrcamento DESCRIPTION "Serviço REST - Cadastra Orcamento" FORMAT "application/json;charset=UTF-8,text/hml"
		
	WSDATA c_fil 		AS STRING OPTIONAL
	WSMETHOD POST DESCRIPTION "Recebe dados e cadastra/altera orcamentos" WSSYNTAX "/cadastraOrcamento?c_fil={param}" PATH "cadastraOrcamento"

END WSRESTFUL


//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} POST
Metodo para receber dados e criar orcamento
@author		.iNi Sistemas
@since     	01/04/2022
@version  	P.12
@param 		Nenhum
@return    	Nenhum
@obs        Serviço REST para ambiente WEB
Alterações Realizadas desde a Estruturação Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//----------------------------------------------------------------------------------------------
/*WSMETHOD POST WSRECEIVE cgc, cgcUser WSSERVICE cadastraOrcamento

	Local lRet 		:= .T.
	Local oResponse	:= JsonObject():New()
	Local oParseJSON:= Nil
	Local cJson     := ""
	Local cNumOrc   := ""
	Local cErros    := ""
	Local cCgcEmp	:= self:cgc //"03662136000236"
	Local nX        := 0
	Local cOperad 	:= getnewPar("PI_FFOPER","000006") // OPERADOR FRONT FLOW
	Local cCodVend	:= ''

	cBody := ::GetContent()
	::SetContentType('application/json;charset=UTF-8')
	
	//--Verifica se recebeu parametros
	If cBody <> Nil
		FWJsonDeserialize(cBody, @oParseJSON)
	Else
		SetRestFault(403, "Parametros vazios.")
		lRet := .F.
	EndIf

	//--Verifica se todos os parametros estao preenchidos
	If Empty(oParseJSON:CODIGOTRANSP) .OR. Empty(oParseJSON:CODIGOCLIENTE) .OR. Empty(oParseJSON:CODIGOCOND) .OR. Empty(oParseJSON:produtos) .OR. EMPTY(oParseJSON:CODIGOTAB)
		SetRestFault(403, "Parametro obrigatorio vazio.")
		lRet := .F.
	Else
		For nX:= 1 to Len(oParseJSON:produtos)
			If Empty(oParseJSON:produtos[nX]:CODIGOPROD) .OR. Empty(oParseJSON:produtos[nX]:QUANTIDADEPROD) .OR. Empty(oParseJSON:produtos[nX]:VALORPROD)
				SetRestFault(403, "Parametro obrigatorio vazio nos produtos.")
				lRet := .F.
			EndIf
		Next nX
	EndIf


	//--Realiza cadastro do orcamento e verifica criacao
	If lRet
		
		lRet:= U_fCadOrcamento(@oResponse, @oParseJSON, @cErros, @cCgcEmp,cOperad, @cNumOrc, cCodVend)
		If !lRet
			SetRestFault(403, StrTran( cErros, CHR(13)+CHR(10), " " ))
		EndIf
	EndIf


	//--Verifica se foi criado e retorna dados
	If lRet
		//cDoc := fBusCop(oParseJSON:CODIGOCLIENTE,oParseJSON:LOJACLIENTE,cOperad)
		If !Empty(cNumOrc)
			cJson += '"'+Alltrim(cNumOrc)+'"'
		Else
			SetRestFault(403, "Nao foi possivel encontrar os dados do cadastro.")
			lRet := .F.
		EndIf
	EndIf
	//--Retorno ao json
	::SetResponse(cJson)

	//RpcClearEnv()

Return(lRet)*/
//--------------------------------------------------------------------------------------
/*/
{Protheus.doc} fCadOrcamento
Funcao para realizar o cadastro do Orcamento
@author		.iNi Sistemas
@since     	01/04/2022
@version  	P.12
@param 		oResponse 	- Objeto Json para armazenar
@param 		oParseJSON 	- Dados recebidos por meio de Json
@param 		cDoc 		- Codigo do cliente
@param 		cErros 		- Erros caso existam
@return    	Nenhum
@obs        Nenhum
Alterações Realizadas desde a Estruturação Inicial
------------+-----------------+---------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+---------------------------------------------------------
/*/
//---------------------------------------------------------------------------------------
/*User Function fCadOrcamento(oResponse, oParseJSON, cErros, cCgcEmp,cOperad, cNumOrc, cCodVend)

	//Local aLog 		:= {}
	Local aCabec 	:= {}
	Local aItens 	:= {}
	Local aLinha 	:= {}
	//Local nY 		:= 0
	Local nX 		:= 0
	Local lRet 		:= .T.	
	Local aFiliais  := FWLoadSM0()
	//Local cFilAux := cFilAnt
	Local cVend 	:= getnewPar("PI_FFVEND","0036") // vendedor FRONT FLOW
	Local cOper 	:= getnewPar("PI_FFOP","2") // OPER FRONT FLOW
	Local cTMK 		:= getnewPar("PI_FFTMK","2") // TMK FRONT FLOW
	//Local cTab 		:= getnewPar("PI_FFTAB","001")
	Local cTes 		:= getnewPar("PI_FFTES","501")
	Local cOpTGV 	:= getnewPar("PI_FFOTGV","01")
	Local nVlrTot	:= 0
	Local aAreaOld	:= {SA3->(GetArea())}
	Local cCodEmp	:= ''
	Local cFili		:= ''
	Local cFilAux	:= cFilAnt
	Local cEmpAux	:= cEmpAnt
	Local cCodClie	:= ''
	Local cCodLoja	:= ''	

	//Private lMsErroAuto 	:= .F.
	//Private lAutoErrNoFile:= .T.
	//Private lMSHelpAuto 	:= .T.

	SA3->(dbSetOrder(1))
	//--Verifica se usuario é um vendedor
	If SA3->(DbSeek(xFilial("SA3") + AvKey(cCodVend,'A3_COD')))
		__CUSERID:= SA3->A3_CODUSR
		//--Busca operador
		cOperad:= TKOPERADOR()
	EndIf

	//--Identifica filial do orçamento
	If !Empty(aFiliais)
		For nX:= 1 to Len(aFiliais)
			If aFiliais[nX][18] == cCgcEmp
				cFili	:= aFiliais[nX][2]
				cCodEmp := aFiliais[nX][3]
			EndIf
		Next nX
	EndIf
	
	If !Empty(cFili) .And. !Empty(cCodEmp)
		cFilAnt := cFili
		cFilEmp	:= cCodEmp
		SM0->(dbSetOrder(1))
		SM0->(DbSeek(cCodEmp+cFili))
	EndIf

	aCabec   := {}
	aItens   := {}
	aLinha   := {}
	
	//--Cliente
	cCodClie:= Left(oParseJSON:CODIGOCLIENTE,6)
	//--Loja
	cCodLoja:= Right(oParseJSON:CODIGOCLIENTE,4)

	SA1->(DbSetOrder(1))
	SA1->(DbSeek(xFilial("SA1")+cCodClie+cCodLoja))

	If SA1->A1_PESSOA == 'J' .And. AllTrim(SA1->A1_INSCR) <> 'ISENTO'
		cFilAnt:="0501" //MATRIZ
	Else
		cFilAnt:="0502" //FILIAL
	EndIf

	cNumOrc:= GETSX8NUM('SUA')

	AADD(aCabec,{"UA_FILIAL"    ,cFilAnt          			,Nil})
	AADD(aCabec,{"UA_NUM"    	,cNumOrc          			,Nil})
	AADD(aCabec,{"UA_CLIENTE"   ,cCodClie   				,Nil})
	AADD(aCabec,{"UA_LOJA"      ,cCodLoja				    ,Nil})
	AADD(aCabec,{"UA_OPERADO"   ,cOperad     				,Nil})  //Codigo do Operador
	AADD(aCabec,{"UA_OPER"      ,cOper           			,Nil}) 
	//--Vendedor
	If !Empty(cCodVend)
		AADD(aCabec,{"UA_VEND"      ,cCodVend				,Nil}) 
	Else
		AADD(aCabec,{"UA_VEND"      ,cVend					,Nil}) 
	EndIf	
	AADD(aCabec,{"UA_TMK"       ,cTMK          				,Nil})  //1-Ativo 2-Receptivo
	AADD(aCabec,{"UA_CONDPG"    ,oParseJSON:CODIGOCOND      ,Nil})  //Condicao de Pagamento
	AADD(aCabec,{"UA_TABELA"    ,oParseJSON:CODIGOTAB		,Nil}) 
	AADD(aCabec,{"UA_TRANSP"    ,oParseJSON:CODIGOTRANSP    ,Nil})  //Transportadora
	AADD(aCabec,{"UA_EMISSAO"   ,DDATABASE   				,Nil})  //Transportadora	

	//--Grava Dados na tabela SUA
	GRecLock(aCabec,.T.,"SUA")

	//--Adiciona itens do orçamento.
	For nX := 1 To Len(oParseJSON:produtos)
		cItem 	:= StrZero(nX,2)
		aLinha 	:= {}
		aadd(aLinha,{"UB_FILIAL"    ,cFilAnt 									,Nil})
		aadd(aLinha,{"UB_ITEM"      ,cItem 										,Nil})
		aadd(aLinha,{"UB_NUM"	    ,cNumOrc 									,Nil})		
		aadd(aLinha,{"UB_PRODUTO"   ,oParseJSON:produtos[nX]:CODIGOPROD   		,Nil})
		aadd(aLinha,{"UB_QUANT"     ,VAL(oParseJSON:produtos[nX]:QUANTIDADEPROD),Nil})
		aadd(aLinha,{"UB_VRUNIT"    ,VAL(oParseJSON:produtos[nX]:VALORPROD)     ,Nil})
		nVlrTot:= VAL(oParseJSON:produtos[nX]:QUANTIDADEPROD) * VAL(oParseJSON:produtos[nX]:VALORPROD)
		aadd(aLinha,{"UB_VLRITEM"   ,nVlrTot       								,Nil})
		aadd(aLinha,{"UB_TES"       ,cTes       								,Nil})
		aadd(aLinha,{"UB_ZOPTGV"    ,cOpTGV    									,Nil})
		aadd(aLinha,{"UB_DTENTRE"   ,DDATABASE 									,Nil})
				
		GRecLock(aLinha,.T.,"SUB")
		//aadd(aItens,aLinha)
	Next nX
	//TMKA271(aCabec,aItens,3,"2")
	CONFIRMSX8()
	//--Retorna filial	
	cFilAnt:= cFilAux
	//--Retorna empresa
	cEmpAnt:= cEmpAux
	//--Restuara area
	Aeval(aAreaOld,{|x| RestArea(x)})
	
Return(lRet)*/


//-----------------------------------------------------------------------------
/*/{Protheus.doc} GET
Metodo de retorno de todos os clientes
          
@author 	.iNi Sistemas
@since 		01/04/2022
@version 	P12
@obs  		
Projeto 	Portal do Cliente
Alteracoes Realizadas desde a Estruturacao Inicial 
Data       Programador     Motivo 
/*/ 
//----------------------------------------------------------------------------
/*WSMETHOD GET WSRECEIVE cgc, cgcUser, codigoCliente WSSERVICE listVendas

	Local cNextAlias:= GetNextAlias()
	Local cQuery 	:= ""
	Local lRet 		:= .T.
	Local cCodVend	:= ''
	Local cFilAux	:= ''
	Local cCodNum	:= ''
	Private oJson 	:= JsonObject():New()
	Private oJsonPrd:= JsonObject():New()
	
	//--Os dois campos vazio, voltar null
	If EMPTY(self:cgc) .And. EMPTY(self:codigoCliente)
		oJson['status'] 		:= "204"
		oJson['quantidade'] 	:= "0"
		oJson['conteudo'] 		:= {}
		::SetResponse(oJson:toJSON())
		Return(.T.)
	EndIf	

	SA3->(dbSetOrder(3))
	//--Verifica se usuario é um vendedor
	If SA3->(DbSeek(xFilial("SA3") + AvKey(self:cgcUser,'A3_CGC')))
		cCodVend:= SA3->A3_COD
		cTipVend:= SA3->A3_TIPO
	EndIf
	
	::SetContentType("application/json;charset=UTF-8")
	//Query dos dados
	cQuery:= Chr(13)+Chr(10)+" SELECT TOP 5 UA_FILIAL, UA_NUM, UA_EMISSAO, UA_CLIENTE, UA_LOJA, A1_NOME, A1_CGC, A1_END, "
	cQuery+= Chr(13)+Chr(10)+" A1_BAIRRO, A1_MUN, A1_EST, UA_CONDPG, A1_COD_MUN, E4_DESCRI, UA_TRANSP, A4_NOME, UA_TABELA "
	cQuery+= Chr(13)+Chr(10)+" A4_NOME, E4_DESCRI, DA0_DESCRI, UA.R_E_C_N_O_ AS REC "
	cQuery+= Chr(13)+Chr(10)+" FROM "+RetSqlName('SUA')+" UA WITH (NOLOCK) "
	cQuery+= Chr(13)+Chr(10)+" INNER JOIN "+RetSqlName('SA1')+" A1 WITH (NOLOCK) ON (A1.D_E_L_E_T_ = '' AND A1_COD = UA_CLIENTE AND A1_LOJA = UA_LOJA ) "
	cQuery+= Chr(13)+Chr(10)+" INNER JOIN "+RetSqlName('SE4')+" E4 WITH (NOLOCK) ON (E4.D_E_L_E_T_ = '' AND E4_FILIAL = '"+xFilial('SE4')+"' AND UA_CONDPG = E4_CODIGO ) "
	cQuery+= Chr(13)+Chr(10)+" INNER JOIN "+RetSqlName('SA4')+" A4 WITH (NOLOCK) ON (A4.D_E_L_E_T_ = '' AND A4_FILIAL = '"+xFilial('SA4')+"' AND UA_TRANSP = A4_COD ) "
	cQuery+= Chr(13)+Chr(10)+" INNER JOIN "+RetSqlName('DA0')+" A0 WITH (NOLOCK) ON (A0.D_E_L_E_T_ = '' AND DA0_FILIAL = '"+xFilial('DA0')+"' AND DA0_CODTAB = UA_TABELA ) "
	cQuery+= Chr(13)+Chr(10)+" WHERE UA.D_E_L_E_T_ = '' "
	//--Busca pelo codigo do cliente
	If !Empty(self:codigoCliente)
		cQuery+= " AND UA_CLIENTE LIKE '"+self:codigoCliente+"' "
	EndIf
	
	cQuery+= Chr(13)+Chr(10)+" ORDER BY UA.R_E_C_N_O_ DESC "
		
	
	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cNextAlias,.F.,.T.)

	(cNextAlias)->(dbGoTop())
	If (cNextAlias)->(!Eof())
		oJson['conteudo'] 		:= {}
		oJson['quantidade'] 	:= Alltrim(STR(10))
		oJson['status'] 		:= "200"	

		Do While (cNextAlias)->(!Eof())
			oJsonCliente 						:= JsonObject():New()
			oJsonCliente['id'] 					:= Alltrim(STR((cNextAlias)->REC))
			oJsonCliente['codigoPedido'] 		:= (cNextAlias)->UA_NUM
			oJsonCliente['codigoConsumidor']	:= AllTrim((cNextAlias)->UA_CLIENTE+(cNextAlias)->UA_LOJA)
			oJsonCliente['nomeConsumidor'] 		:= AllTrim((cNextAlias)->A1_NOME)
			oJsonCliente['data'] 				:= (cNextAlias)->UA_EMISSAO
			oJsonCliente['cgcConsumidor'] 		:= (cNextAlias)->A1_CGC
			oJsonCliente['enderecoConsumidor'] 	:= Upper(zLimpaEsp(AllTrim((cNextAlias)->A1_END)))
			oJsonCliente['bairroConsumidor'] 	:= Alltrim(Upper(zLimpaEsp((cNextAlias)->A1_BAIRRO)))
			oJsonCliente['codigoMunicipio'] 	:= AllTrim((cNextAlias)->A1_COD_MUN)
			oJsonCliente['municipioConsumidor'] := AllTrim((cNextAlias)->A1_MUN)
			oJsonCliente['estadoConsumidor'] 	:= AllTrim((cNextAlias)->A1_EST)
			oJsonCliente['codigoCondicao'] 		:= AllTrim((cNextAlias)->UA_CONDPG)
			oJsonCliente['descricaoCondicao'] 	:= AllTrim((cNextAlias)->E4_DESCRI)
			oJsonCliente['formaCondicao'] 		:= ''
			oJsonCliente['codigoTransportadora']:= AllTrim((cNextAlias)->UA_TRANSP)
			oJsonCliente['nomeTransportadora'] 	:= AllTrim((cNextAlias)->A4_NOME)
			oJsonCliente['codigoTab'] 			:= AllTrim((cNextAlias)->UA_CONDPG)
			oJsonCliente['descricaoTab'] 		:= AllTrim((cNextAlias)->DA0_DESCRI)
			oJsonCliente['produtos'] 			:= {}

			//oJsonPrd['produtos'] := {}
			cFilAux:= (cNextAlias)->UA_FILIAL
			cCodNum:= (cNextAlias)->UA_NUM
			SUB->(DbSetOrder(01))
			SB1->(DbSetOrder(01))
			SUB->(DbSeek(cFilAux+cCodNum))
			Do While SUB->(!Eof()) .And. cFilAux == SUB->UB_FILIAL .And. cCodNum == SUB->UB_NUM
				
				SB1->(DbSeek(xFilial('SB1')+Avkey(SUB->UB_PRODUTO,'B1_COD')))
				oJsonProdutos 						:= JsonObject():New()
				oJsonProdutos['id'] 				:= CValToChar(SB1->(Recno()))
				oJsonProdutos['codigo'] 			:= AllTrim(SB1->B1_COD)
				oJsonProdutos['descricao'] 			:= AllTrim(SB1->B1_DESC)
				oJsonProdutos['tipo'] 				:= AllTrim(SB1->B1_TIPO)
				oJsonProdutos['unidadeMedida'] 		:= AllTrim(SB1->B1_UM)
				oJsonProdutos['armazem'] 			:= ''
				oJsonProdutos['valor'] 				:= CValToChar(SUB->UB_VRUNIT)
				oJsonProdutos['quantidade'] 		:= CValToChar(SUB->UB_QUANT)
				oJsonProdutos['valorVenda'] 		:= CValToChar(SUB->UB_VRUNIT)
				oJsonProdutos['valorFinal'] 		:= CValToChar(SUB->UB_QUANT * SUB->UB_VRUNIT)
								
				Aadd(oJsonCliente['produtos'],oJsonProdutos)
								
			SUB->(DbSkip())
			cCodNum:= SUB->UB_NUM
			EndDo			
			//--Produtos
			aadd(oJson['conteudo'],oJsonCliente)
			//--Add Array com os dados			
			(cNextAlias)->(dbSkip())
		EndDo
	Else
		oJson['status'] 		:= "204"
		oJson['quantidade'] 	:= "0"
		oJson['conteudo'] 		:= {}
	EndIf
	//--Fecha tabela temporaria
	(cNextAlias)->(dbCloseArea())
	//--Resposta ao Json
	::SetResponse(oJson:toJSON())

Return(lRet)


//--Função de reclock.
Static Function GRecLock(aVetor,lModo,cAlias)

	Local aAreaAll	:= {(cAlias)->(GetArea())}
	Local xI		:= 0

	dbSelectArea(cAlias)
	If RecLock(cAlias,lModo)
		For xI:=1 To Len(aVetor)
			&(cAlias + "->" + aVetor[xI][1]) := aVetor[xI][2]
		Next xI
		MsUnlock()
	EndIf
	//--Restaura Area
	AEval(aAreaAll,{|x|RestArea(x)})

Return( Nil )

Static Function zLimpaEsp(cCampo)

    Local cConteudo   := cCampo
    Local nTamOrig    := Len(cConteudo)
    Default lEndereco := .F.
     
    //Retirando caracteres
    cConteudo := StrTran(cConteudo, "'", "")
    cConteudo := StrTran(cConteudo, "#", "")
    cConteudo := StrTran(cConteudo, "%", "")
    cConteudo := StrTran(cConteudo, "*", "")
    cConteudo := StrTran(cConteudo, "&", "E")
    cConteudo := StrTran(cConteudo, ">", "")
    cConteudo := StrTran(cConteudo, "<", "")
    cConteudo := StrTran(cConteudo, "!", "")
    cConteudo := StrTran(cConteudo, "@", "")
    cConteudo := StrTran(cConteudo, "$", "")
    cConteudo := StrTran(cConteudo, "(", "")
    cConteudo := StrTran(cConteudo, ")", "")
    cConteudo := StrTran(cConteudo, "_", "")
    cConteudo := StrTran(cConteudo, "=", "")
    cConteudo := StrTran(cConteudo, "+", "")
    cConteudo := StrTran(cConteudo, "{", "")
    cConteudo := StrTran(cConteudo, "}", "")
    cConteudo := StrTran(cConteudo, "[", "")
    cConteudo := StrTran(cConteudo, "]", "")
    cConteudo := StrTran(cConteudo, "/", "")
    cConteudo := StrTran(cConteudo, "?", "")
    cConteudo := StrTran(cConteudo, ".", "")
    cConteudo := StrTran(cConteudo, "\", "")
    cConteudo := StrTran(cConteudo, "|", "")
    cConteudo := StrTran(cConteudo, ":", "")
    cConteudo := StrTran(cConteudo, ";", "")
    cConteudo := StrTran(cConteudo, '"', '')
    cConteudo := StrTran(cConteudo, '°', '')	
	cConteudo := StrTran(cConteudo, "º", "")
    cConteudo := StrTran(cConteudo, 'ª', '')
     
    //Se não for endereço, retira também o - e a ,
    If !lEndereco
        cConteudo := StrTran(cConteudo, ",", "")
        cConteudo := StrTran(cConteudo, "-", "")
    EndIf
     
    //Adicionando os espaços a direita
    cConteudo := Alltrim(cConteudo)
    cConteudo += Space(nTamOrig - Len(cConteudo))
	cConteudo := FwNoAccent(cConteudo)

Return(cConteudo)*/


WSMETHOD POST WSRECEIVE c_fil WSSERVICE cadastraOrcamento
//User Function fTestCot()

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
	Local lAlt := .F.
	Local aRet := {}
    Private lMsErroAuto := .F.
	Private aTELA[0][0],aGETS[0]

	RpcSetEnv("01","010001")

	cBody := '{ '
	cBody += '"ZC_CODIGO" : "002345051",'
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
	cBody += '		"ZD_PRODUTO": "",'
	cBody += '		"ZD_PREPROD": "15779",'
	cBody += '		"ZD_UMPAD": "KG",'
	cBody += '		"ZD_QUANT1": "2",'
	cBody += '		"ZD_QUANT2": "0",'
	cBody += '		"ZD_CUSTUSU": "65"'
	cBody += '	},'
	cBody += '	{'
	cBody += '		"ZD_PRODUTO": "",'
	cBody += '		"ZD_PREPROD": "115000",'
	cBody += '		"ZD_UMPAD": "KG",'
	cBody += '		"ZD_QUANT1": "0",'
	cBody += '		"ZD_QUANT2": "120.00",'
	cBody += '		"ZD_CUSTUSU": "120.00"'
	cBody += '    }'
	cBody += ']'
	cBody += '}'

	aArea     := FWGetArea()

	cRet := oJson:FromJson(cBody)
	
	If ValType(cRet) == "C"
		SetRestFault(403, "Falha ao transformar texto em objeto json. Erro: " + cRet)
		lRet := .F.
	endif

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
					//Se for passado o campo código é alteração.
					If AllTrim(GetSx3Cache(aFields[nX],"X3_CAMPO")) == "ZC_CODIGO"
						lAlt := .T.
					EndIf
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
		aadd(aItens, aItAux)
		aItAux := {}
	Next nX

	//Chama Execauto da cotação de vendas. Par1=Cabeçalho; Par2=Itens; par3=Campos da tabela para validar; par4=Opçoes: 3-inclusão; 4-Alteração
	aRet := U_F_ExCotV(aCabec,aItens,aCPOS,iif(lAlt,4,3))

	If aRet[1]
		//--Retorno Erro
		SetRestFault(403, StrTran( aRet[2], CHR(13)+CHR(10), " " ))
		lRet := .F.
	Else
		//--Retorno ao json
		::SetResponse(aRet[3])
		lRet := .T.
	EndIf

Return(lRet)


User Function F_ExCotV(aCabec,aItens,aCPOS,nOpc)

    Local cTabela   := "SZC"
	Local nXz := 0
	Local nXi := 0
	Local lAchou
	Local cMsgErro 	:= ""
	Local aRet := {}
	Local nFilial := 0
	Local aDadAux := {}
	Local nPosIte := 0
	Local cTransact := ""
    Local nRetorno  := 0
	Local lRet := .T.
	Private oJson1 := JsonObject():New()
	Private oJsonCot := JsonObject():New()
	Private oJsonPrd := JsonObject():New()

    //--Inicializa a transação
    Begin Transaction

		//--Validação da alteração, O da função EnchAuto retorna um erro que não indica o motivo correto.
		If nOpc == 4
			SZC->(dbSetOrder(1))
			If !SZC->(dbSeek(xFilial("SZC")+ACABEC[aScan(aCabec,{ |x| ALLTRIM(x[1]) == "ZC_CODIGO" })][2]))
				cMsgErro += "Cotação não encontrada "+"Filial: "+xFilial("SZC")+"Cotação: "+ACABEC[aScan(aCabec,{ |x| ALLTRIM(x[1]) == "ZC_CODIGO" })][2]
				lRet := .F.
			EndIf
		EndIf

		If lRet

			//Joga a tabela para a memória (M->)
			RegToMemory(;
				cTabela,; // cAlias - Alias da Tabela
				iif(nOpc==4,.F.,.T.),;     // lInc   - Define se é uma operação de inclusão ou atualização
				.F.;      // lDic   - Define se irá inicilizar os campos conforme o dicionário
			)
			
		
			//--Se conseguir fazer a execução automática - Validação do cabeçalho.
			If EnchAuto(;
				cTabela,; // cAlias  - Alias da Tabela
				aCabec,;  // aField  - Array com os campos e valores
				{ || Obrigatorio( aGets, aTela ) },; // uTUDOOK - Validação do botão confirmar
				nOpc,;        // nOPC    - Operação do Menu (3=inclusão, 4=alteração, 5=exclusão)
				aCPOS;
			)

				//--Validação dos itens.
				aRet :=  FValidIt(aItens,@aDadAux)
				If aRet[1]

					//--Aciona a efetivação da gravação do cabeçalho.
					nRetorno := AxIncluiAuto(;
						cTabela,;   // cAlias     - Alias da Tabela
						,;          // cTudoOk    - Operação do TudoOk (se usado no EnchAuto não precisa usar aqui)
						cTransact,; // cTransact  - Operação acionada após a gravação mas dentro da transação
						nOpc,;          // nOpcaoAuto - Operação do Menu (3=inclusão, 4=alteração, 5=exclusão)
						SZC->(recno());
					)

					//--Aciona a efetivação da gravação dos itens.						
					dbSelectArea("SZD")
					nFilial := aScan(dbStruct(), {|x| "_FILIAL" $ x[1]})	//-- Procura no array a filial

					For nXi := 1 to Len(aDadAux)                  			//-- FOR de 1 ateh a quantidade do numero do aDadAux

						nPosIte := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})

						SZD->(dbSetOrder(1))
						SZD->(dbGoTop())
						lAchou := SZD->(dbSeek(xFilial("SZD")+M->ZC_CODIGO+aDadAux[nXi][nPosIte][2]))

						/*If aDadAux[nXi][Len(aDadAux[nXi])][2] 	//-- Se for registro deletado
							If lAchou							//-- Se achar o registro tem que deletar!!!
								RecLock("SZD",.F.)           //-- Trava a tabela
								dbDelete()
								SZD->(MsUnlock())
							EndIf
							Loop         									//-- Loop da condicao For
						EndIf*/

						//-- Se achou o registro altera os dados se não inclui.
						If lAchou
							RecLock("SZD",.F.)
						Else
							RecLock("SZD",.T.)
						EndIf

						//--Grava os campos da SZD
						For nXz := 1 to Len(aDadAux[nXi])
							If (nFieldPos := FieldPos(aDadAux[nXi][nXz][1])) > 0
								FieldPut(nFieldPos, aDadAux[nXi][nXz][2])
							Endif
						Next nXz

						//--Grava o conteudo da filial
						If nFilial > 0
							FieldPut(nFilial, xFilial("SZD"))
						Endif

						SZD->(MsUnlock())

					Next nXi
				Else
					lRet := .F.
					cMsgErro := aRet[2]
				EndIf
			Else            
				//MostraErro()
				cMsgErro := MemoRead(NomeAutoLog())
				Ferase(NomeAutoLog())
				DisarmTransaction()
			EndIf
		EndIf
    End Transaction  

	If lRet
		SZC->(dbSetOrder(1))
		If SZC->(dbSeek(xFilial("SZC")+ACABEC[aScan(aCabec,{ |x| ALLTRIM(x[1]) == "ZC_CODIGO" })][2]))

			oJson1['status'] 		:= "200"
			oJson1['mensagem'] 		:= "Sucesso!"	
			oJson1['conteudo'] 		:= {}			
			
			oJsonCot['ZC_FILIAL'] 	= SZC->ZC_FILIAL
			oJsonCot['ZC_CODIGO'] 	:= SZC->ZC_CODIGO
			oJsonCot['ZC_CLIENTE'] 	:= SZC->ZC_CLIENTE
			oJsonCot['ZC_LOJACLI'] 	:= SZC->ZC_LOJACLI
			oJsonCot['ZC_TIPFRET'] 	:= SZC->ZC_TIPFRET
			oJsonCot['ZC_DTVALID'] 	:= SZC->ZC_DTVALID
			oJsonCot['ZC_DTINIFO'] 	:= SZC->ZC_DTINIFO
			oJsonCot['ZC_DTFIMFO'] 	:= SZC->ZC_DTFIMFO
			oJsonCot['ZC_CONDPAG'] 	:= SZC->ZC_CONDPAG
			oJsonCot['ZC_VEND1'] 	:= SZC->ZC_VEND1
			oJsonCot['ZC_VEND2'] 	:= SZC->ZC_VEND2
			oJsonCot['itens'] 		:= {}		

			SZD->(dbSetOrder(1))
			If SZD->(dbSeek(xFilial("SZD")+SZC->ZC_CODIGO))

				While !SZD->(Eof()) .and. SZD->ZD_FILIAL = SZC->ZC_FILIAL .and. SZC->ZD_COTACAO == SZC->ZC_CODIGO

					oJsonPrd := JsonObject():New()
					oJsonPrd['ZD_ITEM'] 	:= SZD->ZD_ITEM
					oJsonPrd['ZD_PRODUTO'] 	:= SZD->ZD_PRODUTO
					oJsonPrd['ZD_PV1RUSU'] 	:= SZD->ZD_PV1RUSU

					Aadd(oJsonCot['itens'],oJsonPrd)

					SZD->(dbSkip())
				EndDo
			EndIf

			Aadd(oJson1['conteudo'],oJsonCot)

		EndIf
	Else
		lErro := .T.		
	EndIf


    FWRestArea(aArea)

	RpcClearEnv()

Return({lErro,cMsgErro,oJson1})



Static Function FValidIt(aItens,aDadAux)

Local cProd 	:= ""
Local cPrePr 	:= ""
Local cUM 	  	:= ""
Local nQtd1 	:= ""
Local nQtd2 	:= ""
Local cCusUsu 	:= ""
Local nPPrd 	:= 0
Local nPPrePr 	:= 0
Local nPUm 		:= 0
Local nPQtd1 	:= 0
Local nPQtd2 	:= 0
Local nPCusUs 	:= 0
Local nX	  	:= 0
Local cMsgErro 	:= ""
Local lRet 		:= .T.
Local cUm1P 	:= "" //-- 1º unidade de medida no cadastro do produto ou pré-produto
Local cUm2P 	:= "" //-- 2º unidade de medida no cadastro do produto ou pré-produto

Private lBscImp 	:= .T.
Private lDesUsuCst	:= .F.
Private cCodPrd 	:= ""
Private cPrePrd 	:= ""
Private cUMPad 	  	:= ""

//-- Array
Private	aIteUM		:= {"",""}
Private	aCabec1		:= {}
Private	aDadIt1		:= {}
Private aUsados		:= {}
Private aImpostos	:= {}
Private aImposDef	:= {}
Private aImposUsu	:= {}	
//--Numérico
Private nQtdUM1 := CriaVar("ZD_QUANT1")
Private nQtdUM2 := CriaVar("ZD_QUANT2")
Private nDefCst := CriaVar("ZD_CUSTDEF")
Private nDeDCst := CriaVar("ZD_CUSDDEF")
Private nDeDFre := CriaVar("ZD_FREDDEF")
Private nDefMrg := CriaVar("ZD_MARGDEF")
Private nDefAut := CriaVar("ZD_AUTDDEF")
Private nUsuAut := CriaVar("ZD_AUTDUSU")
Private nDefCom := CriaVar("ZD_PCMSDEF")
Private nDefCHi := CriaVar("ZD_PCMSDHI")
Private nDefCMi := CriaVar("ZD_PCMSDMI")
Private nDefDes := CriaVar("ZD_MARGDEF")
Private nDefFre := CriaVar("ZD_FRETDEF")
Private nDefImp := CriaVar("ZD_MARGDEF")
Private nDefPRE := CriaVar("ZD_PV1RDEF")
Private nDefPUS := CriaVar("ZD_PV1DDEF")
Private nDeDMBR := CriaVar("ZD_MABDDEF")
Private nDEDMLQ := CriaVar("ZD_MALDDEF")
Private nDefPRM := CriaVar("ZD_PV1RDEM")
Private nDeDPRM := CriaVar("ZD_PV1DDEM")
Private nDefMBM := CriaVar("ZD_MABRDEM")
Private nDeDMBM := CriaVar("ZD_MABDDEM")
Private nDefMLM := CriaVar("ZD_MALQDEM")
Private nDeDMLM := CriaVar("ZD_MALDDEM")
Private nDefTRE := CriaVar("ZD_TO1RDEF")
Private nDefTUS := CriaVar("ZD_TO1DDEF")
Private nUsuCst := CriaVar("ZD_CUSTUSU")
Private nUsuMrg := CriaVar("ZD_MARGUSU")
Private nUsuCom := CriaVar("ZD_PCMSUSU")
Private nUsuCHi := CriaVar("ZD_PCMSUHI")
Private nUsuCMi := CriaVar("ZD_PCMSUMI")
Private nUsuCPd := CriaVar("ZD_PCOMPAD")
Private cClcCRN := "NAO"
Private nUsuDes := CriaVar("ZD_MARGUSU")
Private nUsuFre := CriaVar("ZD_FRETUSU")
Private nUsuImp := CriaVar("ZD_MARGUSU")
Private nUsuPRE := CriaVar("ZD_PV1RUSU")
Private nUsuPUS := CriaVar("ZD_PV1DUSU")
Private nUsDMBR := CriaVar("ZD_MABRDUS")
Private nUsDMLQ := CriaVar("ZD_MALQDUS")
Private nUsuPTb := CriaVar("ZD_PV1RUSU")
Private nDUsPTb := CriaVar("ZD_PV1RUSU")
Private nDUsDsc := CriaVar("ZD_PV1RUSU")
Private nUsuTRE := CriaVar("ZD_TO1RUSU")
Private nUsuTUS := CriaVar("ZD_TO1DUSU")
Private nDef2PRE := CriaVar("ZD_PV1RDEF")
Private nUsu2PRE := CriaVar("ZD_PV1RDEF")
Private nDef2PUS := CriaVar("ZD_PV1RDEF")
Private nUsu2PUS := CriaVar("ZD_PV1RDEF")
Private nQtdAte := CriaVar("ZD_QTD1ATE")
Private nDefMBR := CriaVar("ZD_MABRDEF")
Private nDefMLQ := CriaVar("ZD_MALQDEF")
Private nUsuMBR := CriaVar("ZD_MABRUSU")
Private nUsuMLQ := CriaVar("ZD_MALQUSU")
Private nDUsCst := CriaVar("ZD_CUSTUSU")
Private nDUsFre := CriaVar("ZD_FRETUSU")
Private nDUsTRE := CriaVar("ZD_TO1RUSU")
Private nDUsTUS := CriaVar("ZD_TO1DUSU")
Private nUsuPRM := CriaVar("ZD_PV1RUSM")
Private nUsDPRM := CriaVar("ZD_PV1DUSM")
Private nUsuMBM := CriaVar("ZD_MABRUSM")
Private nUsDMBM := CriaVar("ZD_MABDUSM")
Private nUsuMLM := CriaVar("ZD_MALQUSM")
Private nUsDMLM := CriaVar("ZD_MALDUSM")
Private cProcess:= CriaVar("ZD_PROCESS")//--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cotação de Venda
Private cProcApv:= CriaVar("ZD_PROCAPV")//--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cotação de Venda
Private cBloDir := CriaVar("ZD_BLODIR")//--AS - Aleluia - Bloqueio Diretoria
Private cMsgDir := CriaVar("ZD_MSGDIR")//--AS - Aleluia - Msg. de Bloqueio Dir
Private nDeDPRM2 := CriaVar("ZD_PV2DDEM") // -- Preco Minimo Default Dolar UM2
Private nUsDPRM2 := CriaVar("ZD_PV2DUSM") // -- Preco Minimo Usuario Dolar UM2
Private nDefPRM2 := CriaVar("ZD_PV2RDEM") // -- Preco Minimo Default Real UM2
Private nUsuPRM2 := CriaVar("ZD_PV2RUSM") // -- Preco Minimo Usuario Real UM2
Private cCodTabCot := CriaVar("ZD_CODTABC") // -- Codigo Tabela Comissao
Private cMotivo := CriaVar("ZD_MOTIVO")
Private cObserv := CriaVar("ZD_OBSERV")
Private cCodCon	:= CriaVar("ZD_CODCON")
Private cStatus := "I"


	For nX := 1 To Len(aItens)

		cProd 		:= ""	
		cPrePr 	:= ""
		cUM 	  	:= ""
		cQtdUm1 	:= ""
		cQtdUm2 	:= ""
		cCusUsu 	:= ""

		nPPrd 	:= aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_PRODUTO" })
		nPPrePr := aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_PREPROD" })
		nPUm 	:= aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_UMPAD" })
		nPQtd1 	:= aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_QUANT1" })
		nPQtd2 	:= aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_QUANT2" })
		nPCusUs := aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_CUSTUSU" })

		If !Empty(nPPrd)
			cProd := aItens[nX][nPPrd][2]
		EndIf
		If !Empty(nPPrePr)
			cPrePr := aItens[nX][nPPrePr][2]
		EndIf
		If !Empty(nPUm)
			cUM := aItens[nX][nPUm][2]
		EndIf
		If !Empty(nPQtd1)
			nQtd1 := Val(aItens[nX][nPQtd1][2])
		EndIf
		If !Empty(nPQtd2)
			nQtd2 := Val(aItens[nX][nPQtd2][2])
		EndIf
		If !Empty(nPCusUs)
			cCusUsu := aItens[nX][nPCusUs][2]
		EndIf

		If EMPTY(cProd) .AND. Empty(cPrePr)
			cMsgErro += "Obrigatorio informar pre produto ou produto. Verifique o item "+AllTrim(str(nX))+" "+CRLF
			lRet := .F.
		ElseIf !EMPTY(cProd) .AND. !Empty(cPrePr)
			cMsgErro += "Deve ser informado pré produto ou produto. Nunca os dois juntos. Verifique o item "+AllTrim(str(nX))+" "+CRLF
			lRet := .F.
		ElseIf !Empty(cPrePr)
			//-- Avaliar se pre-produto existe
			SZA->(dbSetOrder(1))
			If SZA->(dbSeek(xFilial("SZA")+AvKey(cPrePr,"ZA_CODIGO")))
				If !(SZA->ZA_UM == 'KG' .Or. SZA->ZA_SEGUM == 'KG')
					cMsgErro += "Não é permitido cotar pré-produto que a 1ª ou 2º unidade de medida não seja KG. Verifique o item "+AllTrim(str(nX))+" "+CRLF
					lRet := .F.
				EndIf
			Else
				cMsgErro += "Pré produto "+AllTrim(cPrePr)+" não encontrado. Verifique o item "+AllTrim(str(nX))+" "+CRLF
				lRet := .F.
			EndIf
		ElseIf !Empty(cProd)
			//-- Avaliar se produto existe
			SB1->(dbSetOrder(1))
			If SB1->(dbSeek(xFilial("SB1")+AvKey(cProd,"B1_COD")))
				//if !RetCodUsr() $ SuperGetMv("V_USCOTPLI", .F., "000887")
					//Valida se o Produto é customizado ou Materia-Prima
					if !( SB1->B1_ZCTMIZA $ "C/P" .OR. SB1->B1_TIPO == "MP" )						
						cMsgErro += "Não é permitido produto de linha na cotação. Verifique o item "+AllTrim(str(nX))+" "+CRLF
						lRet := .F.	
					endif
				//EndIf
			Else
				cMsgErro += "Produto "+AllTrim(cProd)+" não encontrado. Verifique o item "+AllTrim(str(nX))+" "+CRLF
				lRet := .F.		
			EndIf
		EndIf
		If lRet

			If !Empty(cProd)
				cUm1P := SB1->B1_UM
				cUm2P := SB1->B1_SEGUM
			Else
				cUm1P := SZA->ZA_UM
				cUm2P := SZA->ZA_SEGUM
			EndIf
			
			If Empty(cUM)
				cMsgErro += "Obrigatório informar Unidade de Medida. Verifique o item "+AllTrim(str(nX))+" "+CRLF
				lRet := .F.
			EndIf

			If lRet 

				If EMPTY(nQtd1) .AND. Empty(nQtd2)
					cMsgErro += "Obrigatorio informar quantidade. Verifique o item "+AllTrim(str(nX))+" "+CRLF
					lRet := .F.
				ElseIf !Empty(nQtd1) .AND. !Empty(nQtd2)
					cMsgErro += "Deve ser informado apenas um campo de quantidade. Nunca os dois juntos. Verifique o item "+AllTrim(str(nX))+" "+CRLF
					lRet := .F.
				EndIf
				
				If lRet

					//--Se unidade de medida enviada for a mesma da 1º unidade de medida obrigatório informar quantidade 1.
					If cUm == cUm1P .and. Empty(nQtd1) 
						cMsgErro += "Obrigatorio informar quantidade 1. Verifique o item "+AllTrim(str(nX))+" "+CRLF
						lRet := .F.
					//--Se unidade de medida enviada for a diferente da 1º unidade de medida obrigatório informar quantidade 2.
					ElseIf cUm != cUm1P .and. Empty(nQtd2) 
						cMsgErro += "Obrigatorio informar quantidade 2. Verifique o item "+AllTrim(str(nX))+" "+CRLF
						lRet := .F.					
					EndIf

				EndIf

				If lRet 
					If Empty(cCusUsu)
						cMsgErro += "Obrigatório informar o custo. Verifique o item "+AllTrim(str(nX))+" "+CRLF
						lRet := .F.
					EndIf
				EndIf
			EndIf
		EndIf
	Next nX

	//--Monta array de gravação para posteriormente atualizar com os calculos.
	If lRet
		FMonRegIt(aItens,@aDadAux)
	EndIf

	//Realiza calculo com base no array dos campos de itens.
	If !Empty(aDadAux)
		fCalcCot(@aDadAux,"ZD_PREPROD")
		fCalcCot(@aDadAux,"ZD_QUANT1")
		fCalcCot(@aDadAux,"ZD_QUANT2")
		fCalcCot(@aDadAux,"ZD_CUSTUSU")
	EndIf

Return({lRet,cMsgErro})




Static Function FMonRegIt(aItens,aDadAux)
	
Local nQtdUm1 	:= 0
Local nQtdUm2 	:= 0
Local nPPrd 	:= 0
Local nPPrePr 	:= 0
Local nPUm 		:= 0
Local nPQtd1 	:= 0
Local nPQtd2 	:= 0
Local nPCusUs 	:= 0
Local nX := 0

For nX := 1 to Len(aItens)

	nPPrd 	:= aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_PRODUTO" })
	nPPrePr := aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_PREPROD" })
	nPUm 	:= aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_UMPAD" })
	nPQtd1 	:= aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_QUANT1" })
	nPQtd2 	:= aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_QUANT2" })
	nPCusUs := aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_CUSTUSU" })

	cCodPrd := aItens[nX][nPPrd][2]
	cPrePrd := aItens[nX][nPPrePr][2]
	cUMPad := aItens[nX][nPUm][2]
	nQtdUm1 := Val(aItens[nX][nPQtd1][2])
	nQtdUm2 := Val(aItens[nX][nPQtd2][2])
	nUsuCst := Val(aItens[nX][nPCusUs][2])

	//-- Inclui novo item no array auxiliar.
	aAdd(aDadAux,{	{"ZD_ITEM   ", strzero(nx,3)},; 	//-- 01
		{"ZD_PRODUTO", cCodPrd},;						//-- 02
		{"ZD_PREPROD", cPrePrd},;						//-- 03
		{"ZD_QUANT1 ", nQtdUm1},; 						//-- 04
		{"ZD_QUANT2 ", nQtdUm2},; 						//-- 05
		{"ZD_CUSTDEF", nDefCst},; 						//-- 06
		{"ZD_CUSTUSU", nUsuCst},; 						//-- 07
		{"ZD_MARGDEF", nDefMrg},; 						//-- 08
		{"ZD_MARGUSU", nUsuMrg},; 						//-- 09
		{"ZD_PERCDES", nDefDes},;	 					//-- 10
		{"ZD_PCMSDEF", nDefCom},; 						//-- 11
		{"ZD_PCMSUSU", nUsuCom},; 						//-- 12
		{"ZD_FRETDEF", nDefFre},; 						//-- 13
		{"ZD_FRETUSU", nUsuFre},; 						//-- 14
		{"ZD_PPISDEF", iIf(Len(aImposDef)>0,aImposDef[1],0)},; 					//-- 15 - PIS
		{"ZD_PPISUSU", iIf(Len(aImposUsu)>0,aImposUsu[1],0)},; 					//-- 16 - PIS
		{"ZD_PCOFDEF", iIf(Len(aImposDef)>0,aImposDef[2],0)},; 					//-- 17 - COFINS
		{"ZD_PCOFUSU", iIf(Len(aImposUsu)>0,aImposUsu[2],0)},; 					//-- 18 - COFINS
		{"ZD_PICMDEF", iIf(Len(aImposDef)>0,aImposDef[3],0)},; 					//-- 19 - ICMS
		{"ZD_PICMUSU", iIf(Len(aImposUsu)>0,aImposUsu[3],0)},; 					//-- 20 - ICMS
		{"ZD_PIPIDEF", iIf(Len(aImposDef)>0,aImposDef[4],0)},; 					//-- 21 - IPI
		{"ZD_PIPIUSU", iIf(Len(aImposUsu)>0,aImposUsu[4],0)},; 					//-- 22 - IPI
		{"ZD_PV1RDEF", nDefPRE},; 						//-- 23
		{"ZD_PV1RUSU", nUsuPRE},; 						//-- 24
		{"ZD_PV2RDEF", nDef2PRE},; 						//-- 25
		{"ZD_PV2RUSU", nUsu2PRE},; 						//-- 26
		{"ZD_PV1DDEF", nDefPUS},; 						//-- 27
		{"ZD_PV1DUSU", nUsuPUS},; 						//-- 28
		{"ZD_PV2DDEF", nDef2PUS},; 						//-- 29
		{"ZD_PV2DUSU", nUsu2PUS},;		 				//-- 30
		{"ZD_TO1RDEF", nDefTRE},; 						//-- 31
		{"ZD_TO1RUSU", nUsuTRE},; 						//-- 32
		{"ZD_TO1DDEF", nDefTUS},; 						//-- 33
		{"ZD_TO1DUSU", nUsuTUS},; 						//-- 34
		{"ZD_OBSERV ", cObserv},;						//-- 35
		{"ZD_MOTIVO ", cMotivo},;						//-- 36
		{"ZD_QTD1ATE", nQtdAte},;						//-- 37
		{"ZD_STATUS ", cStatus},;						//-- 38
		{"ZD_DTRENEG", sTod("")},;						//-- 39
		{"ZD_COTACAO", M->ZC_CODIGO},;					//-- 40
		{"ZD_MABRDEF", nDefMBR},;						//-- 41
		{"ZD_MALQDEF", nDefMLQ},;						//-- 42
		{"ZD_MABRUSU", nUsuMBR},;						//-- 43
		{"ZD_MALQUSU", nUsuMLQ},;						//-- 44
		{"ZD_CUSTDUS", nDUsCst},;						//-- 45
		{"ZD_FRETDUS", nDUsFre},;						//-- 46
		{"ZD_MABRDUS", nUsDMBR},;						//-- 47
		{"ZD_MALQDUS", nUsDMLQ},;						//-- 48
		{"ZD_UMPAD"  , cUMPad},;						//-- 49
		{"ZD_CODCON" , cCodCon},;						//-- 50
		{"ZD_AUTDDEF", nDefAut},;						//-- 51
		{"ZD_AUTDUSU", nUsuAut},;						//-- 52
		{"ZD_PCMSDHI", nDefCHi},;						//-- 53
		{"ZD_PCMSDMI", nDefCMi},;						//-- 54
		{"ZD_PCMSUHI", nUsuCHi},;						//-- 55
		{"ZD_PCMSUMI", nUsuCMi},;						//-- 56
		{"ZD_PV1RDEM", nDefPRM},;						//-- 57
		{"ZD_PV1DDEM", nDeDPRM},;						//-- 58
		{"ZD_MABRDEM", nDefMBM},;						//-- 60
		{"ZD_MABDDEM", nDeDMBM},;						//-- 61
		{"ZD_MALQDEM", nDefMLM},;						//-- 62
		{"ZD_MALDDEM", nDeDMLM},;						//-- 63
		{"ZD_MABDDEF", nDeDMBR},;						//-- 64
		{"ZD_MALDDEF", nDEDMLQ},;						//-- 65
		{"ZD_PV1RUSM", nUsuPRM},;						//-- 66
		{"ZD_PV1DUSM", nUsDPRM},;						//-- 67
		{"ZD_MABRUSM", nUsuMBM},;						//-- 68
		{"ZD_MABDUSM", nUsDMBM},;						//-- 69
		{"ZD_MALQUSM", nUsuMLM},;						//-- 70
		{"ZD_MALDUSM", nUsDMLM},;						//-- 71
		{"ZD_CUSDDEF", nDeDCst},;						//-- 72
		{"ZD_FREDDEF", nDeDFre},; 						//-- 73
		{"ZD_PCOMPAD", nUsuCPd},; 						//-- 74
		{"ZD_CALCMRC", cClcCRN},; 						//-- 75
		{"ZD_PROCESS", cProcess},; 						//-- 76 //--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cotação de Venda
		{"ZD_PROCAPV", cProcApv},; 						//-- 77 //--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cotação de Venda
		{"ZD_BLODIR" , cBloDir},; 						//-- 78 //--AS - Aleluia - Bloqueio diretoria
		{"ZD_MSGDIR" , cMsgDir},; 						//-- 79 //--AS - Aleluia - Msg. de Bloqueio Dir
		{"ZD_PV2DDEM" , nDeDPRM2},; 					//-- 80 //-- Preco Minimo Default Dolar UM2
		{"ZD_PV2DUSM" , nUsDPRM2},; 					//-- 81 //-- Preco Minimo Usuario Dolar UM2
		{"ZD_PV2RDEM" , nDefPRM2},; 					//-- 82 //-- Preco Minimo Default Real UM2
		{"ZD_PV2RUSM" , nUsuPRM2},; 					//-- 83 //-- Preco Minimo Usuario Real UM2
		{"ZD_CODTABC" , cCodTabCot}})	                //-- 84 //-- Codigo tabela Comissao
		//{"DELETE"	 , .F.}})							//-- 85 //-- Sempre manter esse campo como o ultimo.

Next nX

Return()


Static Function fCalcCot(aDadAux,cCampo)

Local nPrcRea := 0
Local nPrcDol := 0
Local nXi := 0
Local nX := 1
Local nPProd := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PRODUTO")})
Local nPPreP := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PREPROD")})
Local nPUmPad := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_UMPAD")})
Local nPCusUs := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSTUSU")})
Local nPQtUm1 := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT1")})
Local nPQtUm2 := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT2")})
/*Local nPv1rus := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RUSM")})
Local nPv1dus := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DUSM")})
Local nPv2rus := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSM")})
Local nPv2dus := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSM")})
Local nPUsuPRE := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RUSU")})
Local nPUsuPUS := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DUSU")})
Local nPUsuTRE := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1RUSU")})
Local nPUsuTUS := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1DUSU")})
Local nPUsDPRM2 := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSM")}) 
Local nPUsuPRM2 := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSM")}) // -- Preco Minimo Usuario Real UM2	
Local nPUsu2PRE := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSU")}) //--Preço Sugerido Usuario Real UM2
Local nPUsu2PUS := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSU")}) //--Preço Sugerido Usuario Dolar UM2*/
	
If cCampo == "ZD_PRODUTO"

	For nX := 1 to Len(aDadAux)

		//--Reseta variavel para buscar imposto por item.
		lBscImp := .T.
		//nImposto := 0

		//Carrega variáveis que sao necessárias para o recalculo.
		FCarVar(nX,@aDadAux)

		cCodPrd := aDadAux[nX][nPProd][2]
		cUMPad := aDadAux[nX][nPUmPad][2]
		nUsuCst := aDadAux[nX][nPCusUs][2]
		
		SB1->(dbSetOrder(1))
		SB1->(dbSeek(xFilial("SB1")+AvKey(cCodPrd,"B1_COD")))

		//-- Busca Descrição
		cDscPrd := SB1->B1_DESC
		cQtdUM1 := SB1->B1_UM
		cQtdUM2 := SB1->B1_SEGUM

		if cQtdUM1 == 'KG'
			aIteUM	:= {cQtdUM1,cQtdUM2}
		else
			aIteUM	:= {cQtdUM2,cQtdUM1}
		endif

		//-- Busca o custo
		nDefCst := nUsuCst
		nDefCst := nUsuCst
		if SB1->B1_TIPO == "MP"

			SBZ->(dbSetOrder(1))
			//Busca Carga Tributaria de entrada no Indicador do Produto.
			If SBZ->(dbSeek(xFilial("SBZ") + SB1->B1_COD))
				nCTirbEIcm := SBZ->BZ_ZCARTRB
			endif
			FsBscImp(cCodPrd,nDefCst,@cCodSTrib)
			//Valida se Embuti no custo da Materia Prima o Gross Up.
			if nCTirbEIcm > (aImpostos[3]/100) .And. cCodSTrib $ '20/40'
				nBCustPiCo := ( nDefCst / (1 -(((aImpostos[1]/100)+(aImpostos[2]/100)) + nCTirbEIcm) ))
				nDefCst  := nDefCst + (nBCustPiCo * (nCTirbEIcm - (aImpostos[3]/100)))
			endif
		EndIf

		nDeDCst := FsCnvDol(nDefCst)
		//nUsuCst := iif(SB1->B1_TIPO == "PA",0,nDefCst) //--03/10/2022 -- .iNi Wemerson -- Não é necessáio, devido a nova regra para pesquisa do csuto de produtos PA.
		nUsuCst := nDefCst
		nDUsCst := FsCnvDol(nUsuCst)

		//-- Busca a Margem
		nDefMrg := FsBscMrg(cCodPrd,1)
		nUsuMrg := nDefMrg

		//-- Busca a Comissão
		aPerCms := FsBscCom(cCodPrd,1)
		nDefCMi := aPerCms[1]
		nDefCom := aPerCms[2]
		nDefCHi := aPerCms[3]

		cCodTabCot := aPerCms[4]

		nUsuCMi := nDefCMi
		nUsuCom := nDefCom
		nUsuCPd := nUsuCom
		nUsuCHi := nDefCHi

		//-- Busca a Despesa
		nDefDes := FsBscDes(cCodPrd,1)
		nUsuDes := nDefDes

		//-- Busca Autonomia de Desconto
		nDefAut := FsBscAut(cCodPrd,1)
		nUsuAut := nDefAut

		FAtuArr(nX,@aDadAux)

	Next nX

EndIf

If cCampo == "ZD_PREPROD"

	For nX := 1 to Len(aDadAux)

		//--Reseta variavel para buscar imposto por item.
		lBscImp := .T.
		//nImposto := 0

		//Carrega variáveis que sao necessárias para o recalculo.
		FCarVar(nX,@aDadAux)

		cPrePrd := aDadAux[nX][nPPreP][2]
		cUMPad := aDadAux[nX][nPUmPad][2]
		nUsuCst := aDadAux[nX][nPCusUs][2]

		SZA->(dbSetOrder(1))
		SZA->(dbSeek(xFilial("SZA")+AvKey(cPrePrd,"ZA_CODIGO")))
		
		//-- Busca Descrição
		cDscPrd := SZA->ZA_DESCRIC
		cQtdUM1 := SZA->ZA_UM
		cQtdUM2 := SZA->ZA_SEGUM
		aIteUM	:= {cQtdUM1,cQtdUM2}

		If cQtdUM1 == 'KG'
			aIteUM	:= {cQtdUM1,cQtdUM2}	
		Else
			aIteUM	:= {cQtdUM2,cQtdUM1}
		Endif

		//-- Busca o custo
		nDefCst := nUsuCst//FsBscCst(cPrePrd,2) //Custo defalt real
		nDeDCst := FsCnvDol(nDefCst) //Custo default dolar
		nUsuCst := nDefCst //Custo usuário real
		nDUsCst := FsCnvDol(nUsuCst) //Custo Usuario Dolar.

		//-- Busca a Margem
		nDefMrg := FsBscMrg(cPrePrd,2)
		nUsuMrg := nDefMrg

		//-- Busca a Comissão
		aPerCms := FsBscCom(cPrePrd,2)
		nDefCMi := aPerCms[1]
		nDefCom := aPerCms[2]
		nDefCHi := aPerCms[3]

		cCodTabCot := aPerCms[4]

		nUsuCMi := nDefCMi
		nUsuCom := nDefCom
		nUsuCPd := nUsuCom
		nUsuCHi := nDefCHi

		//-- Busca a Despesa
		nDefDes := FsBscDes(cPrePrd,2)
		nUsuDes := nDefDes

		//-- Busca Autonomia de Desconto
		nDefAut := FsBscAut(cPrePrd,2)
		nUsuAut := nDefAut

		//--Função que atualiza array com as variaveis já recalculadas.
		FAtuArr(nX,@aDadAux)

	Next nX

EndIf

If cCampo == "ZD_QUANT1" //.And. AllTrim(cUMPad) == AllTrim(cQtdUM1)

	For nX := 1 to Len(aDadAux)
		
		//--Reseta variavel para buscar imposto por item.
		lBscImp := .T.
		//nImposto := 0

		//Carrega variáveis que sao necessárias para o recalculo.
		FCarVar(nX,@aDadAux)

		cCodPrd := aDadAux[nX][nPProd][2]
		cPrePrd := aDadAux[nX][nPPreP][2]
		cUMPad 	:= aDadAux[nX][nPUmPad][2]
		nUsuCst := aDadAux[nX][nPCusUs][2]
		nQtdUM1 := aDadAux[nX][nPQtUm1][2]
		nQtdUM2 := aDadAux[nX][nPQtUm2][2]

		If nQtdUM1 > 0 .and. Empty(nQtdUM2)		
			If !Empty(cCodPrd)
				SB1->(dbSetOrder(1))
				SB1->(dbSeek(xFilial("SB1")+AvKey(cCodPrd,"B1_COD")))
				If SB1->B1_UM == SB1->B1_SEGUM
					nQtdUM2 := nQtdUM1
				ElseIf SB1->B1_TIPCONV == 'D'
					nQtdUM2 := (nQtdUM1 / SB1->B1_CONV)
				Else
					nQtdUM2 := (nQtdUM1 * SB1->B1_CONV)
				EndIf

				//-- Calcula o Frete
				nDefFre := FsBscFrt(cCodPrd,cUMPad,1)
				nDeDFre := FsCnvDol(nDefFre)
				nUsuFre := nDefFre
				nDUsFre := FsCnvDol(nUsuFre)
			Else
				SZA->(dbSetOrder(1))
				SZA->(dbSeek(xFilial("SZA")+AvKey(cPrePrd,"ZA_CODIGO")))
				If SZA->ZA_UM == SZA->ZA_SEGUM
					nQtdUM2 := nQtdUM1
				ElseIf SZA->ZA_TIPCONV == 'D'
					nQtdUM2 := (nQtdUM1 / SZA->ZA_CONV)
				Else
					nQtdUM2 := (nQtdUM1 * SZA->ZA_CONV)
				EndIf

				//-- Calcula o Frete
				nDefFre := FsBscFrt(cPrePrd,cUMPad,2)
				nDeDFre := FsCnvDol(nDefFre)
				nUsuFre := nDefFre
				nDUsFre := FsCnvDol(nUsuFre)
			EndIf

			//-- Calcula o Preço de Venda Default
			FsClcPrc(1,@nPrcRea,@nPrcDol,1,nDefCst) //-- Preço Mínimo Default		

			aImposDef	:= aImpostos
			nImposto := 0
			For nXi := 1 To Len(aImposDef)
				nImposto += aImpostos[nXi]
			Next nXi
			nDefImp := nImposto

			nDefPRM := nPrcRea //-- Preco Minimo Real
			nDeDPRM := nPrcDol //-- Preco Minimo Dolar

			FsClcPrc(1,@nPrcRea,@nPrcDol,2,nDefCst) //-- Preço Sugerido Default

			nDefPRE := nPrcRea //-- Preço Sugerido Real
			nDefPUS := nPrcDol //-- Preço Sugerido Dolar

			nDefTRE := nQtdUM1 * nDefPRE
			nDefTUS := nQtdUM1 * nDefPUS

			//-- Calcula o Preço de Venda Minimo Usuario
			FsClcPrc(2,@nPrcRea,@nPrcDol,1,nUsuCst)

			aImposUsu	:= aImpostos
			nImposto := 0
			For nXi := 1 To Len(aImposUsu)
				nImposto += aImpostos[nXi]
			Next nXi
			nUsuImp := nImposto

			nUsuPRM := nPrcRea //-- Preco Minimo Real
			nUsDPRM := nPrcDol //-- Preco Minimo Dolar

			//-- Calcula o Preço de Venda Sugerido Usuario
			FsClcPrc(2,@nPrcRea,@nPrcDol,2,nUsuCst)

			nUsuPRE := nPrcRea //-- Preço Sugerido Real
			nUsuPUS := nPrcDol //-- Preço Sugerido Dolar

			nUsuTRE := nQtdUM1 * nUsuPRE
			nUsuTUS := nQtdUM1 * nUsuPUS

			FClcMGS(1) //-- Calcula Margem (bruta e liquida) Default e de Usuário
			
			//--Função que atualiza array com as variaveis já recalculadas.
			FAtuArr(nX,@aDadAux)

		EndIf
	Next nX
EndIf


If cCampo == "ZD_QUANT2" //.And. AllTrim(cUMPad) == AllTrim(cQtdUM2)

	For nX := 1 to Len(aDadAux)

		//--Reseta variavel para buscar imposto por item.
		lBscImp := .T.
		//nImposto := 0

		//Carrega variáveis que sao necessárias para o recalculo.
		FCarVar(nX,@aDadAux)

		cCodPrd := aDadAux[nX][nPProd][2]
		cPrePrd := aDadAux[nX][nPPreP][2]
		cUMPad 	:= aDadAux[nX][nPUmPad][2]
		nUsuCst := aDadAux[nX][nPCusUs][2]
		nQtdUM1 := aDadAux[nX][nPQtUm1][2]
		nQtdUM2 := aDadAux[nX][nPQtUm2][2]

		If nQtdUM2 > 0 .and. Empty(nQtdUM1)		
			If !Empty(cCodPrd)
				SB1->(dbSetOrder(1))
				SB1->(dbSeek(xFilial("SB1")+AvKey(cCodPrd,"B1_COD")))
				If SB1->B1_UM == SB1->B1_SEGUM
					nQtdUM1 := nQtdUM2
				ElseIf SB1->B1_TIPCONV == 'D'
					nQtdUM1 := (nQtdUM2 * SB1->B1_CONV)
				Else
					nQtdUM1 := (nQtdUM2 / SB1->B1_CONV)
				EndIf

				//-- Calcula o Frete
				nDefFre := FsBscFrt(cCodPrd,cUMPad,1)
				nDeDFre := FsCnvDol(nDefFre)
				nUsuFre := nDefFre
				nDUsFre := FsCnvDol(nUsuFre)
			Else
				SZA->(dbSetOrder(1))
				SZA->(dbSeek(xFilial("SZA")+AvKey(cPrePrd,"ZA_CODIGO")))
				If SZA->ZA_UM == SZA->ZA_SEGUM
					nQtdUM1 := nQtdUM2
				ElseIf SZA->ZA_TIPCONV == 'D'
					nQtdUM1 := (nQtdUM2 * SZA->ZA_CONV)
				Else
					nQtdUM1 := (nQtdUM2 / SZA->ZA_CONV)
				EndIf

				//-- Calcula o Frete
				nDefFre := FsBscFrt(cPrePrd,cUMPad,2)
				nDeDFre := FsCnvDol(nDefFre)
				nUsuFre := nDefFre
				nDUsFre := FsCnvDol(nUsuFre)
			EndIf

			//-- Calcula o Preço de Venda Default
			FsClcPrc(1,@nPrcRea,@nPrcDol,1,nDefCst) //-- Preço Mínimo Default

			aImposDef	:= aImpostos
			nImposto := 0
			For nXi := 1 To Len(aImposDef)
				nImposto += aImpostos[nXi]
			Next nXi
			nDefImp := nImposto

			nDefPRM2 := nPrcRea //-- Preco Minimo Real
			nDeDPRM2 := nPrcDol //-- Preco Minimo Dolar

			FsClcPrc(1,@nPrcRea,@nPrcDol,2,nDefCst) //-- Preço Sugerido Default

			nDef2PRE := nPrcRea //-- Preço Sugerido Real
			nDef2PUS := nPrcDol //-- Preço Sugerido Dolar

			nDefTRE := nQtdUM2 * nPrcRea
			nDefTUS := nQtdUM2 * nPrcDol

			//-- Calcula o Preço de Venda Usuario
			FsClcPrc(2,@nPrcRea,@nPrcDol,1,nUsuCst)

			aImposUsu	:= aImpostos
			nImposto := 0
			For nXi := 1 To Len(aImposUsu)
				nImposto += aImpostos[nXi]
			Next nXi
			nUsuImp := nImposto

			nUsuPRM2 := nPrcRea //-- Preco Minimo Real
			nUsDPRM2 := nPrcDol //-- Preco Minimo Dolar

			//-- Calcula o Preço de Venda Sugerido Usuario
			FsClcPrc(2,@nPrcRea,@nPrcDol,2,nUsuCst)

			nUsu2PRE := nPrcRea
			nUsu2PUS := nPrcDol

			nUsuTRE := nQtdUM2 * nUsu2PRE
			nUsuTUS := nQtdUM2 * nUsu2PUS

			FClcMGS(1) //-- Calcula Margem (bruta e liquida) Default e de Usuário

			//--Função que atualiza array com as variaveis já recalculadas.
			FAtuArr(nX,@aDadAux)
		EndIf
	Next nX
EndIf


If cCampo $ "ZD_CUSTUSU"

	For nX := 1 to Len(aDadAux)

		//--Reseta variavel para buscar imposto por item.
		lBscImp := .T.
		//nImposto := 0

		//Carrega variáveis que sao necessárias para o recalculo.
		FCarVar(nX,@aDadAux)

		cCodPrd := aDadAux[nX][nPProd][2]
		cPrePrd := aDadAux[nX][nPPreP][2]
		cUMPad := aDadAux[nX][nPUmPad][2]
		nUsuCst := aDadAux[nX][nPCusUs][2]
		nQtdUM2 := aDadAux[nX][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT2")})][2]

		//Atualiza campos de custo;
		nDefCst := nUsuCst //Custo defalt real
		nDeDCst := FsCnvDol(nDefCst) //Custo default dolar
		nDUsCst := FsCnvDol(nUsuCst) //Custo Usuario Dolar

		If !Empty(cCodPrd)
			SB1->(dbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+AvKey(cCodPrd,"B1_COD")))
			nFatorConver := SB1->B1_CONV
			cQtdUM1 := SB1->B1_UM
		Elseif !Empty(cPrePrd)
			SZA->(dbSetOrder(1))
			SZA->(dbSeek(xFilial("SZA")+AvKey(cPrePrd,"ZA_CODIGO")))
			nFatorConver := SZA->ZA_CONV
			cQtdUM1 := SZA->ZA_UM
		Endif 

		If AllTrim(cUMPad) == AllTrim(cQtdUM1)			
				
			//-- Calcula o Preço de Venda Default
			FsClcPrc(1,@nPrcRea,@nPrcDol,1,nDefCst) //-- Preço Mínimo Default

			aImposDef	:= aImpostos
			nImposto := 0
			For nXi := 1 To Len(aImposDef)
				nImposto += aImpostos[nXi]
			Next nXi
			nDefImp := nImposto

			nDefPRM2 := nPrcRea //-- Preco Minimo Real
			nDeDPRM2 := nPrcDol //-- Preco Minimo Dolar

			FsClcPrc(1,@nPrcRea,@nPrcDol,2,nDefCst) //-- Preço Sugerido Default

			nDef2PRE := nPrcRea //-- Preço Sugerido Real
			nDef2PUS := nPrcDol //-- Preço Sugerido Dolar

			nDefTRE := nQtdUM2 * nPrcRea
			nDefTUS := nQtdUM2 * nPrcDol

			//-- Calcula o Preço de Venda Usuario UM1
			FsClcPrc(2,@nPrcRea,@nPrcDol,1,nUsuCst)

			aImposUsu	:= aImpostos
			nImposto := 0
			For nXi := 1 To Len(aImposUsu)
				nImposto += aImpostos[nXi]
			Next nXi
			nUsuImp := nImposto

			nUsuPRM := nPrcRea //-- Preco Minimo Real UM1
			nUsDPRM := nPrcDol //-- Preco Minimo Dolar UM1

			//aDadAux[nX][nPv1rus][2] := nUsuPRM
			//aDadAux[nX][nPv1dus][2] := nUsDPRM
					
			//-- Calcula o Preço de Venda Sugerido Usuario
			FsClcPrc(2,@nPrcRea,@nPrcDol,2,nUsuCst)

			nUsuPRE := nPrcRea  //--Preço Sugerido Real UM1
			nUsuPUS := nPrcDol	//--Preço Sugerido Dolar UM1
			nUsuTRE := nQtdUM1 * nUsuPRE
			nUsuTUS := nQtdUM1 * nUsuPUS

			//aDadAux[nX][nPUsuPRE][2] := nUsuPRE
			//aDadAux[nX][nPUsuPUS][2] := nUsuPUS
			//aDadAux[nX][nPUsuTRE][2] := nUsuTRE
			//aDadAux[nX][nPUsuTUS][2] := nUsuTUS
							
			If nUsuCst > 0
				//-- Calcula o Preço de Venda Usuario UM2
				FsClcPrc(3,@nPrcRea,@nPrcDol,1,iif(cUMPad == 'KG',(nUsuCst * nFatorConver),(nUsuCst / nFatorConver)))

				nUsuPRM2 := nPrcRea //-- Preco Minimo Real UM2
				nUsDPRM2 := nPrcDol //-- Preco Minimo Dolar UM2

				//aDadAux[nX][nPUsuPRM2][2] := nUsuPRM2
				//aDadAux[nX][nPUsDPRM2][2] := nUsDPRM2

				//-- Calcula o Preço de Venda Sugerido Usuario
				FsClcPrc(3,@nPrcRea,@nPrcDol,2,iif(cUMPad == 'KG',(nUsuCst * nFatorConver),(nUsuCst / nFatorConver)))

				nUsu2PRE := nPrcRea //--Preço Sugerido Real UM2
				nUsu2PUS := nPrcDol //--Preço Sugerido Dolar UM2

				//aDadAux[nX][nPUsu2PRE][2] := nUsu2PRE
				//aDadAux[nX][nPUsu2PUS][2] := nUsu2PUS

			Endif

		Else
			//-- Calcula o Preço de Venda Default
			FsClcPrc(1,@nPrcRea,@nPrcDol,1,nDefCst) //-- Preço Mínimo Default

			aImposDef	:= aImpostos
			nImposto := 0
			For nXi := 1 To Len(aImposDef)
				nImposto += aImpostos[nXi]
			Next nXi
			nDefImp := nImposto

			nDefPRM2 := nPrcRea //-- Preco Minimo Real
			nDeDPRM2 := nPrcDol //-- Preco Minimo Dolar

			FsClcPrc(1,@nPrcRea,@nPrcDol,2,nDefCst) //-- Preço Sugerido Default

			nDef2PRE := nPrcRea //-- Preço Sugerido Real
			nDef2PUS := nPrcDol //-- Preço Sugerido Dolar

			nDefTRE := nQtdUM2 * nPrcRea
			nDefTUS := nQtdUM2 * nPrcDol

			//-- Calcula o Preço de Venda Usuario UM2
			FsClcPrc(2,@nPrcRea,@nPrcDol,1,nUsuCst)

			aImposUsu := aImpostos
			nImposto := 0
			For nXi := 1 To Len(aImposUsu)
				nImposto += aImpostos[nXi]
			Next nXi
			nUsuImp := nImposto

			nUsuPRM2 := nPrcRea //-- Preco Minimo Real UM2
			nUsDPRM2 := nPrcDol //-- Preco Minimo Dolar UM2

			//aDadAux[nX][nPv2rus][2] := nUsuPRM2//-- Preco Minimo Real UM2
			//aDadAux[nX][nPv2dus][2] := nUsDPRM2//-- Preco Minimo Dolar UM2

			//-- Calcula o Preço de Venda Sugerido Usuario
			FsClcPrc(2,@nPrcRea,@nPrcDol,2,nUsuCst)

			nUsu2PRE := nPrcRea //--Preço Sugerido Real UM2
			nUsu2PUS := nPrcDol //--Preço Sugerido Dolar UM2
			nUsuTRE := nQtdUM2 * nUsu2PRE
			nUsuTUS := nQtdUM2 * nUsu2PUS

			//aDadAux[nX][nPUsu2PRE][2] := nUsu2PRE
			//aDadAux[nX][nPUsu2PUS][2] := nUsu2PUS
			//aDadAux[nX][nPUsuTRE][2] := nUsuTRE
			//aDadAux[nX][nPUsuTUS][2] := nUsuTUS

			If nUsuCst > 0 
					
				//-- Calcula o Preço de Venda Usuario UM1
				FsClcPrc(3,@nPrcRea,@nPrcDol,1,iif(cUMPad == 'KG',(nUsuCst * nFatorConver),(nUsuCst / nFatorConver)))

				nUsuPRM := nPrcRea //-- Preco Minimo Real UM1
				nUsDPRM := nPrcDol //-- Preco Minimo Dolar UM1

				//aDadAux[nX][nPv1rus][2] := nUsuPRM
				//aDadAux[nX][nPv1dus][2] := nUsDPRM

				//-- Calcula o Preço de Venda Sugerido Usuario
				FsClcPrc(3,@nPrcRea,@nPrcDol,2,iif(cUMPad == 'KG',(nUsuCst * nFatorConver),(nUsuCst / nFatorConver)))

				nUsuPRE := nPrcRea  //--Preço Sugerido Real UM1
				nUsuPUS := nPrcDol	//--Preço Sugerido Dolar UM1

				//aDadAux[nX][nPUsuPRE][2] := nUsuPRE
				//aDadAux[nX][nPUsuPUS][2] := nUsuPUS

			Endif
		Endif

		//--Função que atualiza array com as variaveis já recalculadas.
		FAtuArr(nX,@aDadAux)

		//nPosReg := nX
		//-- Incluo o registro no array do grid da tela.
		//nXi := 1 //-- Começa com 1 pois o primeiro registro é o status.
		//aEval(aUsados,{|a| cCampo:=a, nXi++, iIf(aScan(aDadAux[nPosReg],{|b| AllTrim(b[1]) == AllTrim(cCampo)})>0,aDadIt1[nPosReg][nXi] := aDadAux[nPosReg][aScan(aDadAux[Len(aDadAux)],{|b| AllTrim(b[1]) == AllTrim(cCampo)})][2],Nil)})

	Next nX

EndIf

Return()



//-------------------------------------------------------------------
/*/{Protheus.doc} FCarVar
Função que carrega variaveis necessárias para recalcular tela.

@type function
@author		Lutchen Oliveira
@since		22/02/2023
@version	P12
/*/
//-------------------------------------------------------------------
Static Function FCarVar(n_REG,aDadAux)

Local nXi := 0

	//-- Carrega produto
	cIteAtu := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})][2]
	cCodPrd := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PRODUTO")})][2]
	cPrePrd := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PREPROD")})][2]
	If !Empty(cCodPrd)
		cDscPrd := POSICIONE("SB1",1,xFilial("SB1")+AvKey(cCodPrd,"B1_COD"),"B1_DESC")
		cQtdUM1 := POSICIONE("SB1",1,xFilial("SB1")+AvKey(cCodPrd,"B1_COD"),"B1_UM")
		cQtdUM2 := POSICIONE("SB1",1,xFilial("SB1")+AvKey(cCodPrd,"B1_COD"),"B1_SEGUM")
	Else
		cDscPrd := POSICIONE("SZA",1,xFilial("SZA")+AvKey(cPrePrd,"B1_COD"),"ZA_DESCRIC")
		cQtdUM1 := POSICIONE("SZA",1,xFilial("SZA")+AvKey(cPrePrd,"B1_COD"),"ZA_UM")
		cQtdUM2 := POSICIONE("SZA",1,xFilial("SZA")+AvKey(cPrePrd,"B1_COD"),"ZA_SEGUM")
	EndIf
	nQtdUM1 := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT1")})][2]
	nQtdUM2 := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT2")})][2]
	cUMPad	:= aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_UMPAD")})][2]
	aIteUM	:= {cQtdUM1,cQtdUM2}

	//-- Carrega variaveis de formação de preço default
	nDefAut := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_AUTDDEF")})][2]
	nDefCst := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSTDEF")})][2]
	nDeDCst := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSDDEF")})][2]
	nDeDFre := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_FREDDEF")})][2]
	nDefMrg := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MARGDEF")})][2]
	nDefCHi := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSDHI")})][2]
	nDefCMi := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSDMI")})][2]
	nDefCom := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSDEF")})][2]
	nDefDes := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PERCDES")})][2]
	nDefFre := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_FRETDEF")})][2]
	nDefPRE := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RDEF")})][2]
	nDefPUS := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DDEF")})][2]
	nDefTRE := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1RDEF")})][2]
	nDefTUS := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1DDEF")})][2]
	nDefMBR := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRDEF")})][2]
	nDefMLQ := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQDEF")})][2]
	nDefPRM := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RDEM")})][2]
	nDeDPRM := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DDEM")})][2]
	nDefMBM := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRDEM")})][2]
	nDeDMBM := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABDDEM")})][2]
	nDefMLM := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQDEM")})][2]
	nDeDMLM := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALDDEM")})][2]
	nDeDMBR := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABDDEF")})][2]
	nDEDMLQ := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALDDEF")})][2]

	//-- Carrega variaveis de formação de preço de usuário
	nUsuAut := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_AUTDUSU")})][2]
	nUsuCst := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSTUSU")})][2]
	nUsuMrg := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MARGUSU")})][2]
	nUsuCHi := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSUHI")})][2]
	nUsuCMi := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSUMI")})][2]
	nUsuCPd := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCOMPAD")})][2]
	nUsuCom := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSUSU")})][2]
	nUsuDes := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PERCDES")})][2]
	nUsuFre := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_FRETUSU")})][2]
	nUsuPRE := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RUSU")})][2]
	nUsuPUS := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DUSU")})][2]
	nUsuTRE := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1RUSU")})][2]
	nUsuTUS := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1DUSU")})][2]
	nUsuMBR := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRUSU")})][2]
	nUsuMLQ := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQUSU")})][2]
	nDUsCst := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSTDUS")})][2]
	nDUsFre := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_FRETDUS")})][2]
	nUsuPUS := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DUSU")})][2]
	nUsuTUS := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1DUSU")})][2]
	nUsDMBR := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRDUS")})][2]
	nUsDMLQ := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQDUS")})][2]
	nUsuPRM := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RUSM")})][2]
	nUsDPRM := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DUSM")})][2]
	nUsuMBM := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRUSM")})][2]
	nUsDMBM := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABDUSM")})][2]
	nUsuMLM := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQUSM")})][2]
	nUsDMLM := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALDUSM")})][2]

	cClcCRN := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CALCMRC")})][2]

	cProcess:= aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCESS")})][2]//--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cotação de Venda
	cProcApv:= aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCAPV")})][2]//--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cotação de Venda
	cBloDir := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_BLODIR")})][2]//--AS - Aleluia - Bloqueio Diretoria
	cBloDir := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MSGDIR")})][2]//--AS - Aleluia - Msg. de Bloqueio Dir

	nDef2PRE := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RDEF")})][2] //--Preço Sugerido Defaut Real UM2
	nUsu2PRE := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSU")})][2] //--Preço Sugerido Usuario Real UM2
	nDef2PUS := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DDEF")})][2] //--Preço Sugerido Defaut Dolar UM2
	nUsu2PUS := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSU")})][2] //--Preço Sugerido Usuario Dolar UM2
	
	nDeDPRM2 := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DDEM")})][2] // -- Preco Minimo Default Dolar UM2
	nUsDPRM2 := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSM")})][2] // -- Preco Minimo Usuario Dolar UM2
	nDefPRM2 := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RDEM")})][2] // -- Preco Minimo Default Real UM2	
	nUsuPRM2 := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSM")})][2] // -- Preco Minimo Usuario Real UM2	

	cCodTabCot := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CODTABC")})][2] // -- Codigo Tabela Comissao
	
	aImposDef	:= {}
	aAdd(aImposDef,aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PPISDEF")})][2])
	aAdd(aImposDef,aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCOFDEF")})][2])
	aAdd(aImposDef,aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PICMDEF")})][2])
	aAdd(aImposDef,aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PIPIDEF")})][2])

	For nXi := 1 To Len(aImposDef)
		nDefImp += aImposDef[nXi]
	Next nXi

	aImposUsu	:= {}
	aAdd(aImposUsu,aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PPISUSU")})][2])
	aAdd(aImposUsu,aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCOFUSU")})][2])
	aAdd(aImposUsu,aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PICMUSU")})][2])
	aAdd(aImposUsu,aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PIPIUSU")})][2])

	For nXi := 1 To Len(aImposUsu)
		nUsuImp += aImposUsu[nXi]
	Next nXi

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} FAtuArr
Função que atualiza array com as variaveis já recalculadas.

@type function
@author		Lutchen Oliveira
@since		23/02/2023
@version	P12
/*/
//-------------------------------------------------------------------
Static Function FAtuArr(n_REG,aDadAux)


	//-- Atualiza variáveis de quantidade
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT1")})][2] := nQtdUM1 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT2")})][2] := nQtdUM2 

	//-- Atualiza variaveis de formação de preço default
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_AUTDDEF")})][2] := nDefAut  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSTDEF")})][2] := nDefCst  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSDDEF")})][2] := nDeDCst  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_FREDDEF")})][2] := nDeDFre  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MARGDEF")})][2] := nDefMrg  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSDHI")})][2] := nDefCHi  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSDMI")})][2] := nDefCMi  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSDEF")})][2] := nDefCom  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PERCDES")})][2] := nDefDes  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_FRETDEF")})][2] := nDefFre  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RDEF")})][2] := nDefPRE  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DDEF")})][2] := nDefPUS  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1RDEF")})][2] := nDefTRE  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1DDEF")})][2] := nDefTUS  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRDEF")})][2] := nDefMBR  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQDEF")})][2] := nDefMLQ  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RDEM")})][2] := nDefPRM  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DDEM")})][2] := nDeDPRM  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRDEM")})][2] := nDefMBM  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABDDEM")})][2] := nDeDMBM  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQDEM")})][2] := nDefMLM  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALDDEM")})][2] := nDeDMLM  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABDDEF")})][2] := nDeDMBR  
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALDDEF")})][2] := nDEDMLQ  

	//-- Atualiza variaveis de formação de preço de usuário
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_AUTDUSU")})][2] := nUsuAut 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSTUSU")})][2] := nUsuCst 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MARGUSU")})][2] := nUsuMrg 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSUHI")})][2] := nUsuCHi 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSUMI")})][2] := nUsuCMi 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCOMPAD")})][2] := nUsuCPd 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSUSU")})][2] := nUsuCom 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PERCDES")})][2] := nUsuDes 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_FRETUSU")})][2] := nUsuFre 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RUSU")})][2] := nUsuPRE 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DUSU")})][2] := nUsuPUS 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1RUSU")})][2] := nUsuTRE 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1DUSU")})][2] := nUsuTUS 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRUSU")})][2] := nUsuMBR 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQUSU")})][2] := nUsuMLQ 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSTDUS")})][2] := nDUsCst 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_FRETDUS")})][2] := nDUsFre 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DUSU")})][2] := nUsuPUS 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1DUSU")})][2] := nUsuTUS 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRDUS")})][2] := nUsDMBR 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQDUS")})][2] := nUsDMLQ 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RUSM")})][2] := nUsuPRM 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DUSM")})][2] := nUsDPRM 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRUSM")})][2] := nUsuMBM 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABDUSM")})][2] := nUsDMBM 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQUSM")})][2] := nUsuMLM 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALDUSM")})][2] := nUsDMLM 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CALCMRC")})][2] := cClcCRN 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCESS")})][2] := cProcess //--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cotação de Venda
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCAPV")})][2] := cProcApv //--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cotação de Venda
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_BLODIR")})][2] := cBloDir //--AS - Aleluia - Bloqueio Diretoria
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MSGDIR")})][2] := cBloDir //--AS - Aleluia - Msg. de Bloqueio Dir
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RDEF")})][2] := nDef2PRE //--Preço Sugerido Defaut Real UM2
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSU")})][2] := nUsu2PRE //--Preço Sugerido Usuario Real UM2
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DDEF")})][2] := nDef2PUS //--Preço Sugerido Defaut Dolar UM2
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSU")})][2] := nUsu2PUS //--Preço Sugerido Usuario Dolar UM2
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DDEM")})][2] := nDeDPRM2 // -- Preco Minimo Default Dolar UM2
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSM")})][2] := nUsDPRM2 // -- Preco Minimo Usuario Dolar UM2
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RDEM")})][2] := nDefPRM2 // -- Preco Minimo Default Real UM2	
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSM")})][2] := nUsuPRM2 // -- Preco Minimo Usuario Real UM2	
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CODTABC")})][2] := cCodTabCot // -- Codigo Tabela Comissao
	

	/*For nXi := 1 To Len(aImposDef)
		nDefImp += aImposDef[nXi]
	Next nXi

	For nXi := 1 To Len(aImposUsu)
		nUsuImp += aImposUsu[nXi]
	Next nXi */

	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PPISDEF")})][2] := aImposDef[1] 				//-- 15 - PIS
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PPISUSU")})][2] := aImposUsu[1] 				//-- 16 - PIS
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCOFDEF")})][2] := aImposDef[2] 				//-- 17 - COFINS
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCOFUSU")})][2] := aImposUsu[2] 				//-- 18 - COFINS
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PICMDEF")})][2] := aImposDef[3] 				//-- 19 - ICMS
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PICMUSU")})][2] := aImposUsu[3] 				//-- 20 - ICMS
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PIPIDEF")})][2] := aImposDef[4] 				//-- 21 - IPI
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PIPIUSU")})][2] := aImposUsu[4] 				//-- 22 - IPI

Return()




//-------------------------------------------------------------------
/*/{Protheus.doc} FsClcPrc
Função para calcular preço de venda do produto e ou pre-produto
@type function 
@author		Igor Rabelo
@since		16/03/2018
@version	P11
@history 09/02/2022, Dayvid Nogueira, Inserida validação para buscar o Peso de conversão para calculo do frete do Pre-Produto.
/*/
//-------------------------------------------------------------------
Static Function FsClcPrc(nTipo,nPrcRea,nPrcDol,nTpPrc,nCusto)

	Local nFatorSeg  := GetMv("TIV_FTRSEG",,0)
	Local nFatorAjus := GetMv("TIV_FTRAJU",,0)
	Local cCodigo 	 := ""
	Local nResulFat  := 0
	//Local nCusto 	 := 0
	Local nMargem    := 0
	Local nComisao   := 0
	Local nDespesa   := 0
	Local nFrete     := 0
	Local nImposto   := 0
	Local nTotLiq	 := 0
	Local nPrcVen	 := 0
	Local nAutDsc	 := 0
	Local cAliasCota := GetNextAlias()
	Local aStruct	 := {}
	Local nPesPrd    := 0
	Local nXi := 0
	Local nFatorCota:= 0

	nPrcRea := 0
	nPrcDol := 0

	TIVCOTACAO(cAliasCota,@aStruct)
	nFatorCota := (cAliasCota)->M2_MOEDA2
	(cAliasCota)->(dbCloseArea())


	If !Empty(cPrePrd) //-- Se for para Pré-Produto, usa produto similar
		cCodigo := Posicione("SZA",1,xFilial("SZA")+cPrePrd,"ZA_PRDSIMI")
	Else
		cCodigo := cCodPrd
	EndIf

	SB1->(dbSetOrder(1))
	SB1->(dbSeek(xFilial("SB1")+cCodigo))
	nFatorSeg := iIf(SB1->B1_TIPO == "MP",0,nFatorSeg)
	nFatorAjus := iIf(SB1->B1_TIPO $ "MP/RV",0,nFatorAjus)
	if !Empty(cPrePrd)
		nPesPrd := 	 Posicione("SZA",1,xFilial("SZA")+cPrePrd,"ZA_CONV")
	else
		nPesPrd := SB1->B1_CONV
	endif
	If nTipo == 1 //-- Default
		//nCusto 	  := nDefCst
		nMargem   := nDefMrg
		//-- .iNi Retirado Percentual de Comissão Sugerido do Cálculo de Preço
		/*
		If nTpPrc == 1 //-- Calcular preço mínimo
			nComisao  := nDefCMi + nDefCHi
		Else
			nComisao  := nDefCom + nDefCHi
		EndIf
		*/
				nComisao  := nDefCMi + nDefCHi
				//-- .iNi Retirado Percentual de Comissão Sugerido do Cálculo de Preço
				nDespesa  := nDefDes
				nFrete    := nDefFre
				//nImposto  := nDefImp
				aImpostos := aImposDef
				nAutDsc   := nDefAut
			ElseIf nTipo == 2 //-- Usuário
				//nCusto 	  := nUsuCst
				nMargem   := nUsuMrg
				//-- .iNi Retirado Percentual de Comissão Sugerido do Cálculo de Preço
		/*
		If nTpPrc == 1 //-- Calcular preço mínimo
			nComisao  := nUsuCMi + nUsuCHi
		Else
			nComisao  := nUsuCom + nUsuCHi
		EndIf
		*/
				nComisao  := nUsuCMi + nUsuCHi
				//-- .iNi Retirado Percentual de Comissão Sugerido do Cálculo de Preço
				nDespesa  := nUsuDes
				nFrete    := nUsuFre
				//nImposto  := nUsuImp
				aImpostos := aImposUsu
				nAutDsc   := nUsuAut
			ElseIf nTipo == 3 //-- Outra Unidade de Medida do Usuario
				nMargem   := nUsuMrg
				nComisao  := nUsuCMi + nUsuCHi
				nDespesa  := nUsuDes
				nFrete    :=  iif(AllTrim(cUMPad) == 'KG',nUsuFre * nPesPrd,nUsuFre) //FsBscFrt(cCodigo,iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),cQtdUM2,cQtdUM1),1)
				//nImposto  := nUsuImp
				aImpostos := aImposUsu
				nAutDsc   := nUsuAut
			EndIf

			//-- Retirado a pedido do Leo. Verificar se será necessário posteriormente.
	/*
	nResulFat := (nCusto +; //Custo Brill
				   ((nCusto / (1 - (IIF(AllTrim(SB1->B1_ZCTMIZA) == "S",0,nFatorSeg) / 100))) - nCusto) +; //Calculo do Fator de Segurança
				   ((nCusto / (1 - (nFatorAjus / 100))) - nCusto); //Calculo do Fator de Ajuste
				   )
	*/
			nResulFat := nCusto

			nCalcMarg := (nResulFat / (1 - (nMargem / 100)))

			nTotLiq := (nCalcMarg +; // Custo Brill, com os Fatores de Segurança e Ajuste, e Margem
			nFrete +; // Frete
			((nCalcMarg / (1 - ((nComisao + nDespesa) / 100))) - nCalcMarg); //Calculo do Percentual de Comissao
			)
			If nImposto == 0 .And. lBscImp
				nImposto := 0
				FsBscImp(cCodigo,nTotLiq)

				For nXi := 1 To Len(aImpostos)
					nImposto += aImpostos[nXi]
				Next nXi
				//-- Se busca o imposto igual a .T. e for preço de usuário, marca para não buscar mais o imposto.
				If lBscImp .And. nTipo == 2
					lBscImp := .F.
				EndIf
			EndIf

			//-- Se for preço sugerido então aplica autonomia de desconto.
			If nTpPrc == 2
				nTotLiq := (nTotLiq / (1 - (nAutDsc / 100)))
			EndIf

			nTotLiq := (nTotLiq / (1 - (nImposto / 100))) //-- Aplica o imposto

			nTxEnca := (1 - (iIf(M->ZC_ENCARGO>0,M->ZC_ENCARGO,0)/100)) //-- Acha o encargo
			nTotLiq := (nTotLiq / nTxEnca) //-- Aplica o encargo.

			nPrcRea := Round(nTotLiq,3)
			nPrcDol := Round((nTotLiq / nFatorCota),3)

Return(Nil)

/*------------------------------------------------------------------------------*\
|Função: TIVCOTACAO
|Descrição: Função que verifica a moeda padrão do produto p fazer o calculo de
|custo
|Data: 25/02/2016
|Responsavel:
|Parametro:	cAliasCota	Variavel contendo a alias disponivel naquele momento
|Parametro:	aStruct		Array passado como referencia que recebera o nome dos campos da query
|Retorno:	lOk			Variavel de controle que indica se a rotina deve ou não prosseguir
\*------------------------------------------------------------------------------*/
Static Function TIVCOTACAO(cAliasCota,aStruct)
	Local cQuery := ""
	Local nTotal := 0
	Local lOk	 := .F.
	cQuery := "SELECT M2_MOEDA1, M2_MOEDA2, M2_MOEDA3, M2_MOEDA4, M2_MOEDA5" + Chr(13) + Chr(10)
	cQuery += "FROM " + RetSqlName("SM2") + "" + Chr(13) + Chr(10)
	if Empty(M->ZC_EMISSAO)
		cQuery += "WHERE D_E_L_E_T_ <> '*' AND M2_DATA = TO_CHAR(SYSDATE,'YYYYMMDD')" + Chr(13) + Chr(10)
	else
		cQuery += "WHERE D_E_L_E_T_ <> '*' AND M2_DATA = '"+DtoS(M->ZC_EMISSAO)+"' " + Chr(13) + Chr(10)
	endif
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasCota,.F.,.T.) //Cria uma tabela temporária com as informações trazidas na query
	dbSelectArea(cAliasCota)
	(cAliasCota)->(dbGoTop())
	(cAliasCota)->(dbEval({|| nTotal++}))
	If nTotal > 0
		(cAliasCota)->(dbGoTop())
		aStruct := (cAliasCota)->(dbStruct())
		lOk := .T.
	EndIf
Return(lOk)


//-------------------------------------------------------------------
/*/{Protheus.doc} FsBscImp
Função para buscar impostos do produto e ou pre-produto

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11

@history 22/05/2018, Marlon Costa, Desconsiderar aliquota do Pis/Cofins quando campo F4_PISCRED igual a 4-Aliquota zero
@history 04/06/2019, Rodrigo Prates, Foi criada a variavel nICM, pois o calculo de ICMS sofreu um aumento no nivel de tratamento passando a, quando existir valor de percentual de ICMS diferido e o campo F4_ICMSDIF == "3", deduzir esse percentual da aliquota ICMS
/*/
//-------------------------------------------------------------------
Static Function FsBscImp(cCodigo,nValor,cCodSTrib)
	Local cTes	   := ""
	Local cCliente := ""
	Local cLojaCli := ""
	Local nICM	   := 0

	default cCodSTrib := ''

	//--Limpa array de impostos.
	aImpostos := {}
	SB1->(dbSetOrder(1))
	SB1->(dbSeek(xFilial("SB1") + cCodigo))
	If !Empty(M->ZC_CLIENTE) //--Se for cotação para cliente
		cCliente := M->ZC_CLIENTE
		cLojaCli := M->ZC_LOJACLI
	ElseIf !Empty(M->ZC_PROSPEC) //--Se for cotação para prospect
		FsBscCli(@cCliente,@cLojaCli,M->ZC_PROSPEC,M->ZC_LOJAPRO) //--Busca cliente semelhante ao Prospesct
	EndIf
	//--Posiciona no cliente.
	SA1->(dbSetOrder(1))
	SA1->(dbSeek(xFilial("SA1") + cCliente + cLojaCli))
	cTes := MaTesInt(2,IIF(xFilial("SBZ") == "010055","31",;
		IIF((SB1->B1_TIPO $ "MP/RV" .Or. SB1->B1_TIPO $ "PA/TR" .And. xFilial("SBZ") == "010025"),;
		"02",;
		"01")),SA1->A1_COD,SA1->A1_LOJA,"C",SB1->B1_COD)
	If Empty(cTes) //Caso nao encontre registro de TES inteligente...
		cTes := "504" //...tratamento necessario para que os impostos continuem sendo calculados corretamente de acordo com a região, com bases cheias
	EndIf
	//--Posiciono novamente caso tenha desposicionado no MATESINT
	SA1->(dbSetOrder(1))
	SA1->(dbSeek(xFilial("SA1") + cCliente + cLojaCli))
	MaFisIni(SA1->A1_COD,; //1 - Codigo Cliente/Fornecedor
	SA1->A1_LOJA,; //2 - Loja do Cliente/Fornecedor
	"C",; //3 - C: Cliente, F: Fornecedor
	"N",; //4 - Tipo da NF
	SA1->A1_TIPO,; //5 - Tipo do Cliente/Fornecedor
	,; //6 - Relacao de Impostos que suportados no arquivo
	,; //7 - Tipo de complemento
	,; //8 - Permite Incluir Impostos no Rodape .T./.F.
	"SB1",; //9 - Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
	"MATA410") //10 - Nome da rotina que esta utilizando a funcao
	MaFisAdd(SB1->B1_COD,; //1 - Codigo do Produto (Obrigatorio)
	cTes,; //2 - Codigo do TES (Opcional)
	1,; //3 - Quantidade (Obrigatorio)
	nValor,; //4 - Preco Unitario (Obrigatorio)
	0,; //5 - Valor do Desconto (Opcional)
	"",; //6 - Numero da NF Original (Devolucao/Benef)
	"",; //7 - Serie da NF Original (Devolucao/Benef)
	0,; //8 - RecNo da NF Original no arq SD1/SD2
	0,; //9 - Valor do Frete do Item (Opcional)
	0,; //10 - Valor da Despesa do item (Opcional)
	0,; //11 - Valor do Seguro do item (Opcional)
	0,; //12 - Valor do Frete Autonomo (Opcional)
	nValor,; //13 - Valor da Mercadoria (Obrigatorio)
	0,; //14 - Valor da Embalagem (Opcional)
	0,; //15 - RecNo do SB1
	0) //16 - RecNo do SF4
	AADD(aImpostos,IIF(AllTrim(SF4->F4_PISCOF) $ "1/3" .And. AllTrim(SF4->F4_PISCRED) <> "4",MaFisRet(1,"IT_ALIQPIS"),0))
	AADD(aImpostos,IIF(AllTrim(SF4->F4_PISCOF) $ "2/3" .And. AllTrim(SF4->F4_PISCRED) <> "4",MaFisRet(1,"IT_ALIQCOF"),0))
	nICM := IIF(!Empty(SF4->F4_BASEICM),((MaFisRet(1,"IT_ALIQICM")) * SF4->F4_BASEICM) / 100,MaFisRet(1,"IT_ALIQICM"))
	nICM := Round(IIF(!Empty(SF4->F4_PICMDIF) .And. SF4->F4_ICMSDIF == "3",nICM * (1 - (SF4->F4_PICMDIF / 100)),nICM),2)

	//Valida se Zera a Aliquota do ICMS para Regra
	If SF4->F4_ICM == "S" .And. SF4->F4_LFICM == 'I' .And. SF4->F4_AGREG == 'D' .And.  SF4->F4_SITTRIB == '40' .And.  MaFisRet(1,"LF_VALICM") == 0 //.And. maFisRet(1, "IT_BASEICM") > 0
		nICM := 0
	Endif


	AADD(aImpostos,nICM)
	AADD(aImpostos,IIF(!Empty(MaFisRet(1,"IT_BASEIPI")),MaFisRet(1,"IT_ALIQIPI"),0))

	cCodSTrib := SF4->F4_SITTRIB

	MaFisEnd() //Encerra as MaFis daquele pedido e daqueles itens
Return(Nil)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsBscCli
Função para buscar cliente semelhante ao prospect

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsBscCli(cCliente,cLojaCli,cProspect,cLojaPros)

	Local cQuery := ""
	Local cCndW1 := GetMv("PI_ZCMPPR1")
	Local cCndW2 := GetMv("PI_ZCMPPR2")

	If Select("QRYTMP")>0
		QRYTMP->(DbCloseArea())
	EndIf

	cQuery := " SELECT A1_COD, A1_LOJA "
	cQuery += " FROM "+RetSqlName("SA1")+" SA1"
	cQuery += " WHERE SA1.D_E_L_E_T_ <> '*' "
	cQuery += " AND rownum <= 1 " //-- Pega o primeiro registro
	cQuery += " AND NOT EXISTS (SELECT 1 FROM "+RetSqlName("SFM")+" SFM WHERE FM_FILIAL = '"+xFilial("SFM")+"' AND FM_CLIENTE = A1_COD AND FM_LOJACLI = A1_LOJA AND SFM.D_E_L_E_T_ <> '*') "
	cQuery += " AND EXISTS (SELECT * FROM "+RetSqlName("SUS")+" SUS WHERE US_FILIAL = '"+xFilial("SUS")+"' AND SUS.D_E_L_E_T_ <> '*' AND US_COD = '"+cProspect+"' AND US_LOJA = '"+cLojaPros+"' "
	cQuery += AllTrim(cCndW1)
	cQuery += AllTrim(cCndW2)
	cQuery += ")"

	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "QRYTMP", .T., .T.)

	If !QRYTMP->(Eof())
		cCliente := QRYTMP->A1_COD
		cLojaCli := QRYTMP->A1_LOJA
	EndIf

	QRYTMP->(dbCloseArea())

Return(Nil)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsBscAut
Busca Autonomia de Desconto Produto ou Pré-Produto

@type function
@author		Igor Rabelo
@since		12/07/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsBscAut(cCodigo,nTipo)

	Local nPAutDsc := 0

	If nTipo == 2 //-- Se for para Pré-Produto, usa produto similar
		cCodigo := Posicione("SZA",1,xFilial("SZA")+cCodigo,"ZA_PRDSIMI")
	EndIf

	if !Empty(cCodTabCot) .And. cClcCRN == 'SIM' .And. Posicione("SB1",1,xFilial("SB1")+AvKey(cCodigo,"B1_COD"),"B1_TIPO") <> 'MP'
		nPAutDsc := FsAltAutoDesc()
	else
		If Select("QRYTMP")>0
			QRYTMP->(DbCloseArea())
		EndIf

		cQuery := " SELECT BM_ZAUTDES "
		cQuery += " FROM " + RetSqlName("SB1") + " B1 "
		cQuery += " INNER JOIN " + RetSqlName("SBM") + " BM "
		cQuery += " 	ON BM.D_E_L_E_T_ <> '*' "
		cQuery += " 	AND BM_FILIAL = '"+xFilial("SBM")+"' "
		cQuery += " 	AND BM_GRUPO = B1_GRUPO "
		cQuery += " WHERE B1.D_E_L_E_T_ <> '*' "
		cQuery += " 	AND B1_FILIAL = '"+xFilial("SB1")+"' "
		cQuery += " 	AND B1_COD = '"+cCodigo+"' "

		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "QRYTMP", .T., .T.)

		If !QRYTMP->(Eof())
			nPAutDsc := QRYTMP->BM_ZAUTDES
		EndIf

		QRYTMP->(dbCloseArea())
	endif

Return(nPAutDsc)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsBscMrg
Função para buscar a Margem do produto e ou pre-produto

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsBscMrg(cCodigo,nTipo)

	Local nMrgPrd := 0
	Local cQuery := ""

	If nTipo == 2 //-- Se for para Pré-Produto, usa produto similar
		cCodigo := Posicione("SZA",1,xFilial("SZA")+cCodigo,"ZA_PRDSIMI")
	EndIf

	If Select("QRYTMP")>0
		QRYTMP->(DbCloseArea())
	EndIf

	cQuery := " SELECT CASE WHEN BZ_ZPERMAR = 0 "
	cQuery += " 			THEN BM_ZPERMAR "
	cQuery += " 			ELSE BZ_ZPERMAR "
	cQuery += "				END AS PERCEN_MARG "
	cQuery += " FROM " + RetSqlName("SBZ") + " BZ "
	cQuery += " INNER JOIN " + RetSqlName("SB1") + " B1 "
	cQuery += " 	ON B1.D_E_L_E_T_ <> '*' "
	cQuery += " 	AND B1_FILIAL = '"+xFilial("SB1")+"' "
	cQuery += " 	AND B1_COD = BZ_COD "
	cQuery += " INNER JOIN " + RetSqlName("SBM") + " BM "
	cQuery += " 	ON BM.D_E_L_E_T_ <> '*' "
	cQuery += " 	AND BM_FILIAL = '"+xFilial("SBM")+"' "
	cQuery += " 	AND BM_GRUPO = B1_GRUPO "
	cQuery += " WHERE BZ.D_E_L_E_T_ <> '*' "
	cQuery += " AND BZ_FILIAL IN '"+xFilial("SBZ")+"' "
	cQuery += " AND BZ_COD = '"+cCodigo+"' "

	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "QRYTMP", .T., .T.)

	If !QRYTMP->(Eof())
		nMrgPrd := QRYTMP->PERCEN_MARG
	EndIf

	QRYTMP->(dbCloseArea())

Return(nMrgPrd)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsCnvDol
Converte valor em Real par Dolar

@type function
@author		Igor Rabelo
@since		04/06/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsCnvDol(nVlrRea)

	Local nPrcDol	 := 0
	Local cAliasCota := GetNextAlias()
	Local aStruct	 := {}

	TIVCOTACAO(cAliasCota,@aStruct)
	nFatorCota := (cAliasCota)->M2_MOEDA2
	(cAliasCota)->(dbCloseArea())

	nPrcDol := Round((nVlrRea / nFatorCota),4)

Return(nPrcDol)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsBscCom
Função para buscar a comissao do produto e ou pre-produto

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsBscCom(cCodigo,nTipo)

	Local aPercComis := {}
	Local nComPrd := 0
	Local cQuery := ""
	Local cLog := ""
	Local aRegraComis := {}
	Local cCrgRep := GetMv("PI_ZCRCREP",,"000010") //-- Parametro que define cargos de representantes
	Local nCRpMin := 0 //-- Comissao Minima do Representante
	Local nCRpMax := 0 //-- Comissao Maxima do Representante
	Local nComHie := 0 //-- Comissao Hierarquia
	Local lEncRgr := .F.
	Local cCodTabCom := ''
	

	If nTipo == 2 //-- Se for para Pré-Produto, usa produto similar
		cCodigo := Posicione("SZA",1,xFilial("SZA")+cCodigo,"ZA_PRDSIMI")
	EndIf

	//Função busca a Tabela de Comissão Padrão das Cotações, percentual Minimo e Maximo da tabela
	FBscTabComi(cCodigo,@cCodTabCom)
	if !Empty(cCodTabCom)
		lEncRgr := .T.
		cQuery := " SELECT NVL(MIN(P15_COMISS),0) AS PERCOMIN, NVL(MAX(P15_COMISS),0) AS PERCOMAX "
		cQuery += " FROM " + RetSqlName("P15") + " P15 "
		cQuery += " WHERE P15.D_E_L_E_T_ <> '*' "
		cQuery += " AND P15_FILIAL = '"+xFilial("P15")+"' "
		cQuery += " AND P15_CODIGO = '"+cCodTabCom+"' "

		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "QRYTMP", .T., .T.)

		If !QRYTMP->(Eof())
			nCRpMin := QRYTMP->PERCOMIN
			nCRpMax := QRYTMP->PERCOMAX
		endif

		QRYTMP->(dbCloseArea())

	endif

	//-- Primeiramente tenta encontrar o percentual de comissão de acordo com a regra de comissão
	/*If !Empty(M->ZC_CLIENTE)
		//-- Busca o Centro de Custo da Linha de Produto
		SB1->(dbSetOrder(1))
		SB1->(dbSeek(xFilial("SB1")+cCodigo))
		cLinCC := iIf(SB1->B1_ZCCINDE == "N", SB1->B1_CC, AvKey(" ","C6_ZLNCC"))

		aRegraComis := U_FMelhorRegr(xFilial("SC5"),@cLog,dDataBase,M->ZC_CLIENTE,M->ZC_LOJACLI,cLinCC,cCodigo,Nil,Nil,"","",0)
		For xY := 1 To Len(aRegraComis)
			If U_PIVlGerCom(aRegraComis[xY][2],dDataBase)
				lEncRgr := .T.
				If aRegraComis[xY][3] $ cCrgRep //-- Verifica se é do cargo representante.
					If aRegraComis[xY][4] > 0 //-- Se tiver preenchido o percentual fixo, então é o minimo e máximo do representante.
						nCRpMin := aRegraComis[xY][4]
						nCRpMax := aRegraComis[xY][4]						
					ElseIf !Empty(aRegraComis[xY][5][7])
						nCRpMax := aRegraComis[xY][5][7]
						nCRpMin := POSICIONE("P15",1,xFilial("P15")+AVKEY(aRegraComis[xY][5][1],"P15_CODIGO")+"001","P15_COMISS")						
					EndIf
				Else
					nComHie += aRegraComis[xY][4]
					nComHie += IIF(Empty(aRegraComis[xY][5][7]),0,aRegraComis[xY][5][7])
				EndIf
			EndIf
		Next xY
	EndIf*/

	//-- Se não encontrou regra de comissão, então pega o percentual padrão.
	If !lEncRgr
		If Select("QRYTMP")>0
			QRYTMP->(DbCloseArea())
		EndIf

		cQuery := " SELECT BM_ZPERCOM "
		cQuery += " FROM " + RetSqlName("SB1") + " B1 "
		cQuery += " INNER JOIN " + RetSqlName("SBM") + " BM "
		cQuery += " 	ON BM.D_E_L_E_T_ <> '*' "
		cQuery += " 	AND BM_FILIAL = '"+xFilial("SBM")+"' "
		cQuery += " 	AND BM_GRUPO = B1_GRUPO "
		cQuery += " WHERE B1.D_E_L_E_T_ <> '*' "
		cQuery += " 	AND B1_FILIAL = '"+xFilial("SB1")+"' "
		cQuery += " 	AND B1_COD = '"+cCodigo+"' "

		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "QRYTMP", .T., .T.)

		If !QRYTMP->(Eof())

			aPercComis := IIF(!Empty(AllTrim(QRYTMP->BM_ZPERCOM)),StrTokArr2(QRYTMP->BM_ZPERCOM,"/"),{})
			If aScan(aPercComis,{|a| SubStr(a,1,Len(xFilial("SBZ"))) == xFilial("SBZ")}) > 0
				nComPrd := IIF(Len(aPercComis) > 0,Val(SubStr(aPercComis[aScan(aPercComis,{|a| SubStr(a,1,Len(xFilial("SBZ"))) == xFilial("SBZ")})],9,Len(aPercComis[aScan(aPercComis,{|a| SubStr(a,1,Len(xFilial("SBZ"))) == xFilial("SBZ")})]))),1)
			EndIf

		EndIf

		QRYTMP->(dbCloseArea())

		nCRpMin := nComPrd
		nCRpMax := nComPrd

	EndIf
	//Solicitado por Aline Cupertino para que a Comissão Hierarquia seja sempre o valor setado.
	nComHie := 0.5
	

Return({nCRpMin,nCRpMax,nComHie,cCodTabCom})

/*/{Protheus.doc} FBscTabComi
Função busca a Tabela de Comissão Padrão das Cotações, percentual Minimo e Maximo da tabela. 
@type function
@version 1.0  
@author dayvid.nogueira
@since 30/12/2021
@param cCodigo, character, Codigo do Produto
@param cCodTabCom, character, Codigo da Tabela Escalonada.
/*/
static function FBscTabComi(cCodigo as character,cCodTabCom as character)
	Local aAreaSB1 := {SB1->(GetArea()),GetArea()}
	Local cGrpProdRacoes := SuperGetMv("V_GRPRACOE", .F., "1201/1207/1209/1214/1216/1301/1314/1327/1337/1401/")
	
	SB1->(dbSetOrder(1))
	if SB1->(dbSeek(xFilial("SB1")+cCodigo))
		if SB1->B1_TIPO <> 'MP'
			if SB1->B1_GRUPO $ cGrpProdRacoes
				cCodTabCom := SuperGetMv("V_TABCOTRA", .F., "")		
			else
				cCodTabCom := SuperGetMv("V_TABCOTNU", .F., "")	
			endif
		endif
	endif

	aEval(aAreaSB1, {|xAux| RestArea(xAux)})

return

//-------------------------------------------------------------------
/*/{Protheus.doc} FsBscDes
Função para buscar a despesa do produto e ou pre-produto

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsBscDes(cCodigo,nTipo)

	Local aPercDespe := {}
	Local nDesPrd := 0
	Local cQuery := ""

	If nTipo == 2 //-- Se for para Pré-Produto, usa produto similar
		cCodigo := Posicione("SZA",1,xFilial("SZA")+cCodigo,"ZA_PRDSIMI")
	EndIf

	If Select("QRYTMP")>0
		QRYTMP->(DbCloseArea())
	EndIf

	cQuery := " SELECT BM_ZPERDES "
	cQuery += " FROM " + RetSqlName("SB1") + " B1 "
	cQuery += " INNER JOIN " + RetSqlName("SBM") + " BM "
	cQuery += " 	ON BM.D_E_L_E_T_ <> '*' "
	cQuery += " 	AND BM_FILIAL = '"+xFilial("SBM")+"' "
	cQuery += " 	AND BM_GRUPO = B1_GRUPO "
	cQuery += " WHERE B1.D_E_L_E_T_ <> '*' "
	cQuery += " 	AND B1_FILIAL = '"+xFilial("SB1")+"' "
	cQuery += " 	AND B1_COD = '"+cCodigo+"' "

	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "QRYTMP", .T., .T.)

	If !QRYTMP->(Eof())

		aPercDespe := IIF(!Empty(AllTrim(QRYTMP->BM_ZPERDES)),StrTokArr2(QRYTMP->BM_ZPERDES,"/"),{})
		If aScan(aPercDespe,{|a| SubStr(a,1,Len(xFilial("SBZ"))) == xFilial("SBZ")}) > 0
			nDesPrd := IIF(Len(aPercDespe) > 0,Val(SubStr(aPercDespe[aScan(aPercDespe,{|a| SubStr(a,1,Len(xFilial("SBZ"))) == xFilial("SBZ")})],9,Len(aPercDespe[aScan(aPercDespe,{|a| SubStr(a,1,Len(xFilial("SBZ"))) == xFilial("SBZ")})]))),0)
		EndIf
	EndIf

	QRYTMP->(dbCloseArea())

Return(nDesPrd)

//-------------------------------------------------------------------
/*/{Protheus.doc} FClcMGS
Calcula Margem Liquida e Bruta de acordo com parâmetros.

@type function
@author		Igor Rabelo
@since		04/06/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FClcMGS(nTipo)

	Local nPreDefMin  := iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nDefPRM,nDefPRM2)
	Local nPrecDefSug := iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nDefPRE,nDef2PRE) 
	Local nPrecUsuMin := iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nUsuPRM,nUsuPRM2) 
	Local nPrecUsuSug := iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nUsuPRE,nUsu2PRE) 

	If nTipo == 1 //-- Se tipo igual a 1 então calcula Default e Usuário
		nTxEnca := (1 - (iIf(M->ZC_ENCARGO>0,M->ZC_ENCARGO,0)/100)) //-- Acha o encargo

		//-- Acha Margem Bruta Default e de Usuário
		//-- Formúla: (1 - CUSTO / (PRCVEN - ENCARGOS)) * 100

		//-- Margem Bruta Preço Minimo - Default e Usuário
		nDefMBM := Round((1 - (nDefCst / (nPreDefMin * nTxEnca))) * 100,3) 
		nDeDMBM := nDefMBM //-- FsCnvDol(nDefMBM)
		nUsuMBM := Round((1 - (nUsuCst / (nPrecUsuMin * nTxEnca))) * 100,3)
		nUsDMBM := nUsuMBM //-- FsCnvDol(nUsuMBM)

		//-- Margem Bruta Preço Sugerido - Default e Usuário
		nDefMBR := Round((1 - (nDefCst / (nPrecDefSug * nTxEnca))) * 100,3)
		nDeDMBR	:= nDefMBR //-- FsCnvDol(nDefMBR)
		nUsuMBR := Round((1 - (nUsuCst / (nPrecUsuSug * nTxEnca))) * 100,3)
		nUsDMBR := nUsuMBR //-- FsCnvDol(nUsuMBR)

		//-- Acha Margem Liquida Default e de Usuário
		//-- Formúla: (1 - CUSTO / ((PRCVEN - ENCARGOS) - FRETE - IMPOSTOS - (DESPESA+COMISSAO))) * 100
		//-- Nova Formúla: (1 - ((CUSTO + IMPOSTOS + FRETE + COMISSAO + DESPESA) / (PRCVEN - ENCARGOS)))

		//-- Margem Liquida Preço Minimo - Default e Usuário
		nDefMLM := Round((1 - ((nDefCst + nDefFre + ((nPreDefMin * nDefImp)/100) + (nPreDefMin * ((nDefCMi + nDefCHi + nDefDes)/100))) / (nPreDefMin * nTxEnca))) * 100,3)
		nDeDMLM := nDefMLM //-- FsCnvDol(nDefMLM)
		nUsuMLM := Round((1 - ((nUsuCst + nUsuFre + ((nPrecUsuMin * nUsuImp)/100) + (nPrecUsuMin * ((nUsuCMi + nUsuCHi + nDefDes)/100))) / (nPrecUsuMin * nTxEnca))) * 100,3)
		nUsDMLM := nUsuMLM //-- FsCnvDol(nUsuMLM)

		//-- Margem Liquida Preço Sugerido - Default e Usuário
		nDefMLQ := Round((1 - ((nDefCst + nDefFre + ((nPrecDefSug * nDefImp)/100) + (nPrecDefSug * ((nDefCom + nDefCHi + nDefDes)/100))) / (nPrecDefSug * nTxEnca))) * 100,3)
		nDEDMLQ := nDefMLQ //-- FsCnvDol(nDefMLQ)
		nUsuMLQ := Round((1 - ((nUsuCst + nUsuFre + ((nPrecUsuSug * nUsuImp)/100) + (nPrecUsuSug * ((nUsuCPd + nUsuCHi + nUsuDes)/100))) / (nPrecUsuSug * nTxEnca))) * 100,3)
		nUsDMLQ := nUsuMLQ //-- FsCnvDol(nUsuMLQ)

	ElseIf nTipo == 2 //-- Se tipo igual a 2 então calcula Usuário
		nTxEnca := (1 - (iIf(M->ZC_ENCARGO>0,M->ZC_ENCARGO,0)/100)) //-- Acha o encargo

		//-- Acha Margem Bruta Usuário
		//-- Formúla: (1 - CUSTO / (PRCVEN - ENCARGOS)) * 100

		//-- Margem Bruta Preço Minimo - Usuário
		nUsuMBM := Round((1 - (nUsuCst / (nPrecUsuMin * nTxEnca))) * 100,3)
		nUsDMBM := nUsuMBM //-- FsCnvDol(nUsuMBM)

		//-- Margem Bruta Preço Sugerido - Usuário
		nUsuMBR := Round((1 - (nUsuCst / (nPrecUsuSug * nTxEnca))) * 100,3)
		nUsDMBR := nUsuMBR //-- FsCnvDol(nUsuMBR)

		//-- Acha Margem Liquida Usuário
		//-- Formúla: (1 - CUSTO / ((PRCVEN - ENCARGOS) - FRETE - IMPOSTOS - (DESPESA+COMISSAO))) * 100
		//-- Nova Formúla: (1 - ((CUSTO + IMPOSTOS + FRETE + COMISSAO + DESPESA) / (PRCVEN - ENCARGOS)))

		//-- Margem Liquida Preço Minimo - Usuário
		nUsuMLM := Round((1 - ((nUsuCst + nUsuFre + ((nPrecUsuMin * nUsuImp)/100) + (nPrecUsuMin * ((nUsuCMi + nUsuCHi + nDefDes)/100))) / (nPrecUsuMin * nTxEnca))) * 100,3)
		nUsDMLM := nUsuMLM //-- FsCnvDol(nUsuMLM)

		//-- Margem Liquida Preço Sugerido - Usuário
		nUsuMLQ := Round((1 - ((nUsuCst + nUsuFre + ((nPrecUsuSug * nUsuImp)/100) + (nPrecUsuSug * ((nUsuCPd + nUsuCHi + nUsuDes)/100))) / (nPrecUsuSug * nTxEnca))) * 100,3)
		nUsDMLQ := nUsuMLQ //-- FsCnvDol(nUsuMLQ)

	ElseIf nTipo == 3 //-- Se tipo igual a 3 então calcula Default
		nTxEnca := (1 - (iIf(M->ZC_ENCARGO>0,M->ZC_ENCARGO,0)/100)) //-- Acha o encargo

		//-- Acha Margem Bruta Default
		//-- Formúla: (1 - CUSTO / (PRCVEN - ENCARGOS)) * 100

		//-- Margem Bruta Preço Minimo - Default
		nDefMBM := Round((1 - (nDefCst / (nPreDefMin * nTxEnca))) * 100,3)
		nDeDMBM := nDefMBM //-- FsCnvDol(nDefMBM)

		//-- Margem Bruta Preço Sugerido - Default
		nDefMBR := Round((1 - (nDefCst / (nPrecDefSug * nTxEnca))) * 100,3)
		nDeDMBR	:= nDefMBR //-- FsCnvDol(nDefMBR)

		//-- Acha Margem Liquida Default
		//-- Formúla: (1 - CUSTO / ((PRCVEN - ENCARGOS) - FRETE - IMPOSTOS - (DESPESA+COMISSAO))) * 100
		//-- Nova Formúla: (1 - ((CUSTO + IMPOSTOS + FRETE + COMISSAO + DESPESA) / (PRCVEN - ENCARGOS)))

		//-- Margem Liquida Preço Minimo - Default
		nDefMLM := Round((1 - ((nDefCst + nDefFre + ((nPreDefMin * nDefImp)/100) + (nPreDefMin * ((nDefCMi + nDefCHi + nDefDes)/100))) / (nPreDefMin * nTxEnca))) * 100,3)
		nDeDMLM := nDefMLM //-- FsCnvDol(nDefMLM)

		//-- Margem Liquida Preço Sugerido - Default
		nDefMLQ := Round((1 - ((nDefCst + nDefFre + ((nPrecDefSug * nDefImp)/100) + (nPrecDefSug * ((nDefCom + nDefCHi + nDefDes)/100))) / (nPrecDefSug * nTxEnca))) * 100,3)
		nDEDMLQ := nDefMLQ //-- FsCnvDol(nDefMLQ)
	EndIf

Return()


//-------------------------------------------------------------------
/*/{Protheus.doc} FsBscFrt
Função para buscar o frete do produto e ou pre-produto

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11

@history 29/06/2018, Igor Rabelo, Alteração de Busca de Peso Bruto para pegar de acordo com a conversão do pré-produto e não no produto similar.
@history 18/11/2020, Andre Mendonca, Alterar a metodologia para calculo do frete utilizando a classe TIVCL008.
/*/
//-------------------------------------------------------------------
Static Function FsBscFrt(cCodigo,cUMCalc,nTipo)

	Local nPesPrd := 0
	Local nVlrFrt := 0
	Local cUF2Calc := ""
	Local oFreteXUF := NIL

	//-- Se frete for FOB retorna frete zerado.
	If M->ZC_TIPFRET == 'F'
		Return(nVlrFrt)
	EndIf

	//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
	//->18/11/2020 - Andre Mendonca - Nova metodologia de calculo do frete											 |
	//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|

	//-- Calculo de Peso Bruto * Quantidade 1UM
	If nTipo == 2 //-- Se for para Pré-Produto, usa produto similar
		SZA->(dbSetOrder(1))
		SZA->(dbSeek(xFilial("SZA")+cCodigo))
		//-- Se Unidade de Medida da Cotação é KG
		If cUMCalc == 'KG'
			nPesPrd := 1
		Else
			//-- Se não for KG, pega o CONV.
			nPesPrd := SZA->ZA_CONV
		EndIf
	Else
		SB1->(dbSetOrder(1))
		SB1->(dbSeek(xFilial("SB1")+AvKey(cCodigo,"B1_COD")))
		//-- Se Unidade de Medida da Cotação é KG
		If cUMCalc == 'KG'
			nPesPrd := 1
		Else
			//-- Se não for KG, pega o CONV.
			nPesPrd := SB1->B1_CONV
		EndIf
	EndIf

	If !Empty(M->ZC_CLIENTE)
		cUF2Calc := Posicione("SA1", 1, xFilial("SA1") + M->ZC_CLIENTE + M->ZC_LOJACLI, "A1_EST")
	ElseIf !Empty(M->ZC_PROSPEC)
		cUF2Calc := Posicione("SUS", 1, xFilial("SUS") + M->ZC_PROSPEC + M->ZC_LOJAPRO, "US_EST")
	EndIf

	if !Empty(cUF2Calc) .And. nPesPrd <> 0
		oFreteXUF := TIVCL008():new(cFilAnt)

		nVlrFrt := oFreteXUF:getValorDoFreteParaAQuantidadeEmKGDoProdutoParaUF(cUF2Calc, nPesPrd)

		freeObj(oFreteXUF)
	endif
	//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
	//<-18/11/2020 - Andre Mendonca - Nova metodologia de calculo do frete											 |
	//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
Return(nVlrFrt)
