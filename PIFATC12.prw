#INCLUDE "TOTVS.CH"
#INCLUDE "PROTHEUS.CH"
// #INCLUDE "PARMTYPE.CH"
#INCLUDE "APWEBSRV.CH"
#INCLUDE "rwmake.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} PIFATC12
Cadastro de Cota��o de Vendas
@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
@history 18/05/2018, Marlon Costa, Alterado para considerar o peso por unidade de venda no calculo do frete por dist�ncia.
@history 22/05/2018, Marlon Costa, Desconsiderar aliquota do Pis/Cofins quando campo F4_PISCRED igual a 4-Aliquota zero
@history 14/09/2018, Rodrigo Prates, Foi alterada a fun��o FsBscCst(), trazendo agora o novo campo da SBZ, BZ_ZESTICM, para que, caso tenha valor, esse percentual seja acrescido no custo do produto. O ORDER BY foi retirado por ser desnecess�rio
@history 22/02/2019, Rodrigo Prates, Como solicitado no chamado 2019021907000637, a fun��o FsBscCst() precisou ser alterada para que o custo do pre-produto agora tenha como origem o campo ZA_ZCUSBRI
@history 23/04/2019, Leonardo Perrella, Adicionado a vari�vel cKeyApi na fun��o FsRetDis() que recebe o c�digo chave credencial, utilizada para consulta na API da Google.
@history 04/06/2019, Rodrigo Prates, A fun��o FsBscImp() foi alterada passando a, quando existir valor de percentual de ICMS diferido e o campo F4_ICMSDIF == "3", deduzir esse percentual da aliquota ICMS
@history 27/11/2019, Lucas - MAIS, Ajustes nas coordenadas dos objetos na fun��o FsMntIte , ap�s virada para 12.1.23
@history 17/04/2020, Wemerson Souza, Inclus�o de Processo de Cota��o de Venda. Quando incluir pr�-produto ser� necess�rio informar o n�mero do processo que ser� vinculado ao item.
@history 08/10/2020, Lucas - MAIS, Modifica��o na fun��o FsBscCst, para que o valor do custo seja buscado da tabela SZT, se for do tipo RV/MP, sen�o o custo � zero
@history 18/11/2020, Andre Mendonca, Alterar a metodologia para calculo do frete utilizando a classe TIVCL008.
@history 11/05/2021, Lucas - MAIS, Adicionada chamada via tecla F4, para retornar o saldo do produto
@history 25/08/2021, Dayvid Nogueira, Alterada a Fun��o de Bloqueio da Cota��o de venda da FSFATP01 para TIVRO130, pois foi separada dos bloqueios do pedido de venda. Alterada local da valida��o do produto de linha.
@history 01/11/2021, Dayvid Nogueira, Inserido tratamento para gerar o Pre�o Sugerido na Primeira e Segunda unidade do produto.
@history 11/11/2021, Dayvid Nogueira, Inserida fun��o para buscar a Autonomia de Desconto de acordo com a Tabela Escalonada de Comiss�o e Desconto.
@history 07/01/2022, Dayvid Nogueira, Agregado ao Custo da Materia prima, o calculo do Gross Up de estorno de ICMS.
@history 11/01/2022, Dayvid Nogueira, Corre��o no calculo do custo da Materia prima, considerando o Gross Up de estorno de ICMS.
@history 09/02/2022, Dayvid Nogueira, Inserida na FsClcPrc() a valida��o para buscar o Peso de convers�o para calculo do frete do Pre-Produto.
@history 25/02/2022, Dayvid Nogueira, Comentada chamada da fun��o FsRetDis() para retorna a distancia pela APi da Google, pois o frete � calculado pela classe TIVCL008.
@history 25/02/2022, Dayvid Nogueira, Altera��o para deixar a unidade padr�o do produto como KG, conforme chamado 2022022307000248.
@history 15/03/2022, Dayvid Nogueira, Corre��o para buscar o custo do produto Defaut de acordo com a unidade de medida em KG, para acompanhar a corre��o solicitada no chamado 2022022307000248. 
@history  03/05/2022, Wemerson Souza, Inclus�o de valida��es ao incluir novo produto na cota��o de venda.
@history  09/02/2023, Lutchen Oliveira, Ajuste coordenadas bot�es da tela de cota��o de vendas.
@history  31/03/2023, Lutchen Oliveira, Imprementando rotina automatica de cota��o de vendas. Fun��o ExeCotV.
/*/
//-------------------------------------------------------------------
User Function PIFATC12(aCabec,aItens,aCPOS,nOpc)
	
	Local xRet
	//--Vari�veis Private
	//--Arrays
	Private aCores	  := {}
	Private aRotina   := {}
	//--Logica
	Private lCopia	  := .F.
	//--String
	Private cCadastro := "Cadastro de Cota��o de Vendas"
	Private cFiltro := ""
	PRIVATE lC12Auto	:= (aCabec <> Nil)

	//Verifica se � rotina autom�tica.
	If !lC12Auto

		dbSelectArea("SZC")
		aRotina := {{"Pesquisar"	,"AxPesqui"	 ,0,1},;
					{"Visualizar"	,"U_PIFAT12A",0,2},;
					{"Incluir"		,"U_PIFAT12A",0,3},;
					{"Alterar"		,"U_PIFAT12A",0,4},;
					{"Excluir"		,"U_PIFAT12A",0,5},;
					{"Legenda"		,"U_PIFAT12A",0,6},;
					{"Copiar "		,"U_PIFAT12A",0,7},;
					{"Ger. Proposta","U_PIFAT12A",0,8}}
		aCores := {{"((SZC->ZC_STATUS = 'P' .OR. SZC->ZC_STATUS = 'I' .OR. SZC->ZC_STATUS = 'A') .AND. SZC->ZC_DTVALID < DDATABASE)","BR_PRETO"},;
				{"(SZC->ZC_STATUS = 'I')","BR_VERDE"	  },;
				{"(SZC->ZC_STATUS = 'P')","BR_AMARELO" },;
				{"(SZC->ZC_STATUS = 'A')","BR_AZUL"	  },;
				{"(SZC->ZC_STATUS = 'S')","BR_LARANJA" },;
				{"(SZC->ZC_STATUS = 'E')","BR_VERMELHO"},;
				{"(SZC->ZC_STATUS = 'B')","BR_MARROM"}}		// AS - Aleluia

		//fMntFil() //-- Monta Filtro

		mBrowse(6,1,22,75,"SZC",,,,,,aCores,,,,,,,,cFiltro)

	Else

		//Rotina autim�tica.
		xRet := {}
		xRet := ExeCotV(aCabec,aItens,aCPOS,nOpc)

	EndIf

Return(xRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} fMntFil
Monta express�o de filtro.

@type function
@author		Igor Rabelo
@since		26/07/2019
@version	P11
/*/
//-------------------------------------------------------------------
Static Function fMntFil()

	//-- Verifica se o c�digo do usu�rio est� no ZC_USERLGI ( Se sim, exibe a cota��o)
	cFiltro := " ( "
	cFiltro += "  (RTRIM(SubStr(ZC_USERLGI, 11, 1) || SubStr(ZC_USERLGI, 15, 1) || "
	cFiltro += "   SubStr(ZC_USERLGI, 2, 1)  || SubStr(ZC_USERLGI, 6, 1)  || "
	cFiltro += "   SubStr(ZC_USERLGI, 10, 1) || SubStr(ZC_USERLGI, 14, 1) || "
	cFiltro += "   SubStr(ZC_USERLGI, 1, 1)  || SubStr(ZC_USERLGI, 5, 1)  || "
	cFiltro += "   SubStr(ZC_USERLGI, 9, 1)  || SubStr(ZC_USERLGI, 13, 1) || "
	cFiltro += "   SubStr(ZC_USERLGI, 17, 1) || SubStr(ZC_USERLGI, 4, 1)  || "
	cFiltro += "   SubStr(ZC_USERLGI, 8, 1)) = '"+RetCodUsr()+"') "

	cFiltro += " OR "

	//-- Verifica no campo ZC_VEND1 e ZC_VEND2 o c�digo de vendedor e procura na tabela SA3 o c�digo do usu�rio do Protheus (campo A3_CODUSR) ( Se encontrar, exibe a cota��o).
	cFiltro += " ('"+RetCodUsr()+"' IN (SELECT RTRIM(A3_CODUSR) FROM "+RetSqlName("SA3")+" U1A3 WHERE U1A3.D_E_L_E_T_ <> '*' AND (U1A3.A3_COD = ZC_VEND1 OR U1A3.A3_COD = ZC_VEND2))) "

	cFiltro += " OR "

	//-- Se n�o atender o item 1 e 2 acima, verifica na tabela de itens da cota��o, quais s�o os grupos de produtos e/ou pre-produtos (B1_GRUPO) . Para pr� produto, a busca do grupo pode ser feita pelo produto similar ZA_PRDSIMI.
	//-- Depois de ver quais s�o os grupos, faz um DISTINCT da tabela SZE, com ZE_GRUPO, ZE_NIVEL1, ZE_NIVEL2, ZE_NIVEL3, ZE_NIVEL4, ZE_NIVEL5, ZE_NIVEL6, ZE_NIVEL7. ( Nesses campos estar�o o c�digo do vendedor. Se em alguns desses estiver o c�digo do vendedor, a busca tamb�m pelo c�digo do usu�rio no campo A3_CODUSR. ( Se encontrar, exibe a cota��o).

	cFiltro += " (EXISTS (SELECT DISTINCT 1 "
	cFiltro += " FROM "+RetSqlName("SZD")+" U1ZD "
	cFiltro += " INNER JOIN "+RetSqlName("SB1")+" U1B1 "
	cFiltro += " 	ON U1B1.D_E_L_E_T_ <> '*' "
	cFiltro += " 	AND U1ZD.ZD_PRODUTO = U1B1.B1_COD "
	cFiltro += " INNER JOIN "+RetSqlName("SZE")+" U1ZE "
	cFiltro += " 	ON U1ZE.D_E_L_E_T_ <> '*' "
	cFiltro += " 	AND U1ZE.ZE_GRUPO = B1_GRUPO "
	cFiltro += " INNER JOIN "+RetSqlName("SA3")+" U2A3 "
	cFiltro += " 	ON U2A3.D_E_L_E_T_ <> '*' "
	cFiltro += " 	AND (U2A3.A3_COD = U1ZE.ZE_NIVEL1 "
	cFiltro += " 		OR U2A3.A3_COD = U1ZE.ZE_NIVEL2 "
	cFiltro += "		OR U2A3.A3_COD = U1ZE.ZE_NIVEL3 "
	cFiltro += " 		OR U2A3.A3_COD = U1ZE.ZE_NIVEL4 "
	cFiltro += " 		OR U2A3.A3_COD = U1ZE.ZE_NIVEL5 "
	cFiltro += " 		OR U2A3.A3_COD = U1ZE.ZE_NIVEL6 "
	cFiltro += " 		OR U2A3.A3_COD = U1ZE.ZE_NIVEL7) "
	cFiltro += " 		AND RTRIM(A3_CODUSR) = '"+RetCodUsr()+"' "
	cFiltro += " WHERE U1ZD.D_E_L_E_T_ <> '*' AND U1ZD.ZD_PRODUTO <> '' AND U1ZD.ZD_COTACAO = ZC_CODIGO AND U1ZD.ZD_FILIAL = ZC_FILIAL)) "

	cFiltro += " OR "

	cFiltro += " (EXISTS (SELECT DISTINCT 1 "
	cFiltro += " FROM "+RetSqlName("SZD")+" U1ZD "
	cFiltro += " INNER JOIN "+RetSqlName("SZA")+" U1ZA "
	cFiltro += " 	ON U1ZA.D_E_L_E_T_ <> '*' "
	cFiltro += " 	AND U1ZD.ZD_PREPROD = U1ZA.ZA_CODIGO "
	cFiltro += " INNER JOIN "+RetSqlName("SB1")+" U1B1 "
	cFiltro += " 	ON U1B1.D_E_L_E_T_ <> '*' "
	cFiltro += " 	AND U1ZA.ZA_PRDSIMI = U1B1.B1_COD "
	cFiltro += " INNER JOIN "+RetSqlName("SZE")+" U1ZE "
	cFiltro += " 	ON U1ZE.D_E_L_E_T_ <> '*' "
	cFiltro += " 	AND U1ZE.ZE_GRUPO = B1_GRUPO "
	cFiltro += " INNER JOIN "+RetSqlName("SA3")+" U2A3 "
	cFiltro += " 	ON U2A3.D_E_L_E_T_ <> '*' "
	cFiltro += " 	AND (U2A3.A3_COD = U1ZE.ZE_NIVEL1 "
	cFiltro += " 		OR U2A3.A3_COD = U1ZE.ZE_NIVEL2 "
	cFiltro += "		OR U2A3.A3_COD = U1ZE.ZE_NIVEL3 "
	cFiltro += " 		OR U2A3.A3_COD = U1ZE.ZE_NIVEL4 "
	cFiltro += " 		OR U2A3.A3_COD = U1ZE.ZE_NIVEL5 "
	cFiltro += " 		OR U2A3.A3_COD = U1ZE.ZE_NIVEL6 "
	cFiltro += " 		OR U2A3.A3_COD = U1ZE.ZE_NIVEL7) "
	cFiltro += " 		AND RTRIM(A3_CODUSR) = '"+RetCodUsr()+"' "
	cFiltro += " WHERE U1ZD.D_E_L_E_T_ <> '*' AND U1ZD.ZD_PREPROD <> '' AND U1ZD.ZD_COTACAO = ZC_CODIGO AND U1ZD.ZD_FILIAL = ZC_FILIAL)) "
	cFiltro += " ) "

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} PIFAT12A
Rotinas Add do Cadastro de Cota��o de Vendas

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
User Function PIFAT12A(cAlias,nRecno,nOpc)

Local lContinua := .T.
Local cStsIte := "Todos"
Local cCntMa1 := Space(150)
Local cCntMa2 := Space(150)
Local cNomCm1 := Space(150)
Local cNomCm2 := Space(150)
Local cStaBlAlt := 'I,P,A,S'	// Status bloqueio de altera��o de cota��o
Private INCLUI	 	:= (nOpc == 3)
Private ALTERA	 	:= (nOpc == 4)
Private EXCLUI      := (nOpc == 5)
// ->> Bloqueia altera��o de cota��o com bloqueio de margem e desconto
if SuperGetMv("AS_BLALTCT", .F., "N") == "N"
	cStaBlAlt := 'I,P,A,S,B'
else
	cStaBlAlt := 'I,P,A,S'
endif
// <<- Bloqueia altera��o de cota��o com bloqueio de margem e desconto

// If nOpc == 4 .And. !(SZC->ZC_STATUS $ 'I,P,A,S')
If nOpc == 4 .And. !(SZC->ZC_STATUS $ cStaBlAlt)
	Alert("N�o � permitida a altera��o da cota��o para o status atual.")
	lContinua := .F.
EndIf

If nOpc == 5 .And. !(SZC->ZC_STATUS == 'I') .And. !(SZC->ZC_STATUS == 'B')
	Alert("N�o � permitida a exclus�o da cota��o para o status atual.")
	lContinua := .F.
EndIf

If nOpc == 8 .And. !(SZC->ZC_STATUS $ 'I,P,A')
	Alert("N�o � permitida emiss�o de proposta para o status atual.")
	lContinua := .F.
EndIf

If lContinua
	If nOpc == 6 //-- Legenda
		BrwLegenda(cCadastro,"Legenda", {	{"BR_VERDE"		,OemToAnsi("INCLUIDA")},;
			{"BR_AMARELO"	,OemToAnsi("PROPOSTA ENVIADA")},;
			{"BR_PRETO"		,OemToAnsi("VENCIDA")},;
			{"BR_AZUL"		,OemToAnsi("ATENDIDA PARCIALMENTE")},;
			{"BR_LARANJA"	,OemToAnsi("SALDO PENDENTE")},;
			{"BR_VERMELHO"		,OemToAnsi("ENCERRADA")},;
			{"BR_MARROM"		,OemToAnsi("BLOQUEADA")}})	// AS - Aleluia
	ElseIf nOpc == 8 //-- Enviar Proposta
		nRetImp := FsTelPro(@cStsIte,@cCntMa1,@cCntMa2,@cNomCm1,@cNomCm2)
		If nRetImp <> 0
			If nRetImp == 3
				MsgRun("Gerando Proposta...","Aguarde...",{|| U_PIFATR02(cStsIte,cCntMa1,cCntMa2,cNomCm1,cNomCm2,nRetImp)})
			Else
				//-- Emiss�o de Relat�rio
				MsgRun("Gerando Proposta...","Aguarde...",{|| U_PIFATR01(cStsIte,cCntMa1,cCntMa2,cNomCm1,cNomCm2,nRetImp)})
			EndIf

			Reclock("SZC",.F.)
			SZC->ZC_STATUS := "P"
			SZC->(MsUnLock())

			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			//->23/04/2020 - Wemerson Souza - Atualiza��o de status do Processo de Cota��o de Venda									 |
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			FsGrvProc(2)
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			//<-23/04/2020 - Wemerson Souza - Atualiza��o de status do Processo de Cota��o de Venda									 |
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
		EndIf
	Else

		If nOpc == 7 //-- Se for c�pia altera para inclus�o.
			lCopia := .T.
			nOpc := 3
		EndIf

		FsTelCot(cAlias,nRecno,nOpc) //-- Chama tela de manuten��o da cota��o

		If lCopia
			nOpc := 7
			lCopia := .F.
		EndIf
	EndIf
EndIf

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} FsTelCot
Tela de Manuten��o de Cota��o de Venda

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11

@history 17/04/2020, Wemerson Souza, Inclus�o de Processo de Cota��o de Venda. Quando incluir pr�-produto ser� necess�rio informar o n�mero do processo que ser� vinculado ao item.
@history 27/09/2022, .iNi Wemerson, Inclus�o de vari�vel lDesUsuCst para determinar se edi��o dos campos custo do usu�rio sera� desabilitados
@history 09/02/2023, Lutchen Oliveira, Ajuste coordenadas bot�es da tela de cota��o de vendas.
/*/
//-------------------------------------------------------------------
Static Function FsTelCot(cAlias,nRecno,nOpc)

//-- Vari�veis Locais
//-- String
Local 	cCadastro	:= "Cota��o de Vendas"
Local	cSubMen		:= ""
//-- Array
Local 	aSize 		:= {}
Local 	aFldEnch 	:= {}
Local   aButEnc		:= {}
Local  	aStru			:= {}
//-- Num�rico
Local 	nTop       	:= oMainWnd:nTop+35
Local 	nLeft      	:= oMainWnd:nLeft+10
Local 	nBottom    	:= oMainWnd:nBottom-12
Local 	nRight     	:= oMainWnd:nRight-10
Local 	nOpca
Local   nXi         := 0
//-- Objeto
Local	oFont11		:= TFont():New( "MS Sans Serif",0,-11,,.F.,0,,700,.F.,.F.,,,,,, )
Local	oFont11N	:= TFont():New( "MS Sans Serif",0,-11,,.T.,0,,700,.F.,.F.,,,,,, )
Local 	oFont13 	:= TFont():New( "MS Sans Serif",0,-13,,.F.,0,,400,.F.,.F.,,,,,, )
Local 	oFont13N	:= TFont():New( "MS Sans Serif",0,-13,,.T.,0,,700,.F.,.F.,,,,,, )
Local 	oFont17N	:= TFont():New( "MS Sans Serif",0,-18,,.T.,0,,700,.F.,.F.,,,,,, )
Local 	oFont19N	:= TFont():New( "MS Sans Serif",0,-19,,.T.,0,,700,.F.,.F.,,,,,, )
Local 	oFont22N	:= TFont():New( "MS Sans Serif",0,-22,,.T.,0,,700,.F.,.F.,,,,,, )
Local 	oFont24N	:= TFont():New( "MS Sans Serif",0,-24,,.T.,0,,700,.F.,.F.,,,,,, )

Local cCSS := "QPushButton { background-color: #6699FF }"

//-- Vari�veis Private
//-- String
Private	cTotRea := "Total R$: "
Private	cTotDol := "Total US$: "
Private cCodPrd := CriaVar("ZD_PRODUTO")
Private cPrePrd := CriaVar("ZD_PREPROD")
Private cDscPrd := CriaVar("B1_DESC")
Private cQtdUM1 := " "
Private cQtdUM2 := " "
Private cUMPad	:= ""
Private cIteAtu := ""
Private cMotivo := CriaVar("ZD_MOTIVO")
Private cObserv := CriaVar("ZD_OBSERV")
Private cCodCon	:= CriaVar("ZD_CODCON")
Private cStatus := ""
//-- Objeto
Private	oDlg
Private	oDlg01
Private	oDlg02
Private	oDlg03
Private	oPan01
Private	oPan02
Private	oPan03
Private oDlgMnt
Private oBrowse1
Private	oLayer 		:= Nil
Private oSVerde  	:= LoadBitmap(GetResources(),"BR_VERDE")
Private oSVerme   	:= LoadBitmap(GetResources(),"BR_VERMELHO")
Private oSLaran   	:= LoadBitmap(GetResources(),"BR_LARANJA")
Private oSAmare   	:= LoadBitmap(GetResources(),"BR_AMARELO")
Private oSMarro   	:= LoadBitmap(GetResources(),"BR_MARROM")
Private oSPreto   	:= LoadBitmap(GetResources(),"BR_PRETO")
Private oSPink   	:= LoadBitmap(GetResources(),"BR_PINK")
Private oSEclui		:= LoadBitmap(GetResources(),"XCLOSE")
//-- L�gico
Private INCLUI	 	:= (nOpc == 3)
Private ALTERA	 	:= (nOpc == 4)
Private lBscImp 	:= .T.
Private lDesUsuCst	:= .F.
//-- Array
Private	aIteUM		:= {"",""}
Private	aCabec1		:= {}
Private	aDadIt1		:= {}
Private aDadAux		:= {}
Private aUsados		:= {}
Private aImpostos	:= {}
Private aImposDef	:= {}
Private aImposUsu	:= {}
Private aTela[0][0],aGets[0]
//--Num�rico
Private nHBrows1 := 0
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
Private nUsuCPd := CriaVar("ZD_PCMSUSU")
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
Private cProcess:= CriaVar("ZD_PROCESS")//--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
Private cProcApv:= CriaVar("ZD_PROCAPV")//--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
Private cBloDir := CriaVar("ZD_BLODIR")//--AS - Aleluia - Bloqueio Diretoria
Private cMsgDir := CriaVar("ZD_MSGDIR")//--AS - Aleluia - Msg. de Bloqueio Dir
Private nDeDPRM2 := CriaVar("ZD_PV2DDEM") // -- Preco Minimo Default Dolar UM2
Private nUsDPRM2 := CriaVar("ZD_PV2DUSM") // -- Preco Minimo Usuario Dolar UM2
Private nDefPRM2 := CriaVar("ZD_PV2RDEM") // -- Preco Minimo Default Real UM2
Private nUsuPRM2 := CriaVar("ZD_PV2RUSM") // -- Preco Minimo Usuario Real UM2
Private cCodTabCot := CriaVar("ZD_CODTABC") // -- Codigo Tabela Comissao
	
Private nOpcMnt := nOpc
Private lObrigaRM := SuperGetMv( "FS_OBRIREM", .F., .F. )	// AS - Aleluia - Par�metro, obriga ou n�o preenchimento de remessa para os itens da cota��o

private oBtnSalvar := Nil
private oBtnCancel := Nil
private oBtnLeg    := Nil
private oBtnAprov  := Nil 

PUBLIC N := 1

zCriaEPopulaVariavelPublica()

//-- Recalcula posicao dos objetos
aSize := MsAdvSize()

//-- Inicio Montagem da tela
oDlg := MSDialog():New(aSize[7],aSize[1],aSize[6],aSize[5],cCadastro,,,.F.,DS_MODALFRAME,,,,oMainWnd,.T.,,,.T.)

//oDlg:nClrPane 	:= RGB(240,240,240) //-- Define cor da tela.
oDlg:lMaximized := .T.   			//-- Ocupa tela inteira
oDlg:LEscClose 	:= .F.   			//-- Nao Permitir fechar a janela pelo ESC do teclado

oLayer:= FWLayer():New() 			//-- Cria painel.
oLayer:Init(oDlg,.F.,.T.) 			//-- Inicializa painel.

//-- Adiciona 2 linhas separando a tela no meio.
oLayer:addLine("Lin01",45,.F.)
oLayer:addLine("Lin02",55,.F.)

//-- Adiciona as colunas de cada janela.
oLayer:addCollumn("Col01",100,.F.,"Lin01")
oLayer:addCollumn("Col02",100,.F.,"Lin02")

//-- Cria Janela dos Pedidos
oLayer:addWindow("Col01","Jan01","Dados Gerais da Cota��o",100,.F.,.T.,,"Lin01",)

//-- Retorna o objeto da Janela Dados Gerais da Cota��o
oDlg01:= oLayer:getWinPanel("Col01","Jan01","Lin01")

//-- Cria Painel da Janela Itens da Cota��o
oPan01:= TPanel():New(oDlg01:nTop,oDlg01:nBottom,,oDlg01,,,,,/*RGB(245,245,245)*/,oDlg01:nRight,oDlg01:nLeft,.T.,.T.)
oPan01:Align := CONTROL_ALIGN_ALLCLIENT

//-- Monta o array de campos do cabe�alho
aStru := FWSX3Util():GetListFieldsStruct( "SZC" , .T. )

For nXi := 1 To Len(aStru)
	If X3Uso(GETSX3CACHE(aStru[nXi][1], "X3_Usado")) .And. cNivel >= GETSX3CACHE(aStru[nXi][1],"X3_NIVEL")
		If Empty(GETSX3CACHE(aStru[nXi][1], "X3_RELACAO"))
			&("M->"+GETSX3CACHE(aStru[nXi][1], "X3_CAMPO")) := CriaVar(GETSX3CACHE(aStru[nXi][1], "X3_CAMPO"))
		EndIf
		aAdd(aFldEnch,GETSX3CACHE(aStru[nXi][1], "X3_CAMPO"))
	EndIf
Next nXi

//-- Cria vari�veis de mem�ria.
RegToMemory(cAlias, If(nOpc==3 .And. !lCopia,.T.,.F.))

If lCopia
	M->ZC_CODIGO := GETSXENUM("SZC","ZC_CODIGO")
	M->ZC_EMISSAO := DDATABASE //Adicionado
EndIf

//-- Enchoice com os campos do cabe�alho.
oEnch := MsMGet():New("SZC",SZC->(RECNO()),nOpc,,,,aFldEnch,/*aPosEnch*/{oPan01:nTop,oPan01:nLeft,oPan01:nBottom,oPan01:nRight-(oPan01:nRight*0.65)},,,,,,oPan01,,,.F.)
oEnch:oBox:Align := CONTROL_ALIGN_ALLCLIENT

//-- Cria Janela dos Itens da Cota��o
oLayer:addWindow("Col02","Jan02","Itens da Cota��o",100,.F.,.T.,,"Lin02",)

//-- Retorna o objeto da Janela Itens da Cota��o
oDlg02:= oLayer:getWinPanel("Col02","Jan02","Lin02")
//oLayer:winChgState("Col02","Jan02","Lin02")

//-- Cria Painel da Janela Itens da Cota��o
oPan02:= TPanel():New(oDlg02:nTop,oDlg02:nBottom,,oDlg02,,,,,/*RGB(245,245,245)*/,oDlg02:nRight,oDlg02:nLeft,.T.,.T.)
oPan02:Align := CONTROL_ALIGN_ALLCLIENT

//-- Cria barra de bot�es na tela de manute��o de itens da cota��o
oTMenuBar := TMenuBar():New(oPan02)
oTMenuBar:SetCss("QMenuBar{background-color:#4d6094;color:#ffffff;}")
oTMenuBar:Align     := CONTROL_ALIGN_TOP
oTMenuBar:nClrPane  := RGB(77,96,148)
oTMenuBar:bRClicked := {||}
//oTMenuBar:SetDefaultUp(.T.) //-- Joga as op��es do menu pra cima

//-- Cria itens do menu Manut Itens.
oTMenu1 := TMenu():New(0,0,0,0,.T.,,oTMenuBar)
oTMenu1:Add(TMenuItem():New(oTMenu1,"Novo <F2>"      ,,,,{|| (FsBtnMnt(1,'N'))},,"SDUNEW",,,,,,,.T.))
oTMenu1:Add(TMenuItem():New(oTMenu1,"Cons.Prev.Rem",,,,{|| U_ASFATR05('I')},,"BMPTABLE",,,,,,,.T.))
oTMenu1:Add(TMenuItem():New(oTMenu1,"Excluir"   ,,,,{|| (FsBtnMnt(3))},,"SDUDELETE",,,,,,,.T.))
oTMenuBar:AddItem('Manut. Itens', oTMenu1, .T.)
//-- Cria itens do menu Follow Up
oTMenu2 := TMenu():New(0,0,0,0,.T.,,oTMenuBar)
oTMenu2:Add(TMenuItem():New(oTMenu2,"Perdeu Cota��o"  ,,,,{|| (cSubMen := "P"  , FsBtnMnt(4,cSubMen))},,"BR_MARROM",,,,,,,.T.))
oTMenu2:Add(TMenuItem():New(oTMenu2,"Cancelar"        ,,,,{|| (cSubMen := "C"  , FsBtnMnt(4,cSubMen))},,"BR_PRETO",,,,,,,.T.))
oTMenu2:Add(TMenuItem():New(oTMenu2,"Eliminar Residuo",,,,{|| (cSubMen := "E"  , FsBtnMnt(4,cSubMen))},,"BR_PINK",,,,,,,.T.))
oTMenuBar:AddItem('Follow Up'   , oTMenu2, .T.)
//-- Cria itens do menu Outras A��es
oTMenu3 := TMenu():New(0,0,0,0,.T.,,oTMenuBar)
oTMenu3:Add(TMenuItem():New(oTMenu3,"Legenda"   ,,,,{|| (FsBtnMnt(5))},,"COLOR",,,,,,,.T.))
oTMenuBar:AddItem('Outras A��es', oTMenu3, .T.)
//-- Cria itens do menu Processo
oTMenu4 := TMenu():New(0,0,0,0,.T.,,oTMenuBar)
oTMenu4:Add(TMenuItem():New(oTMenu3,"Vincular Processo"   ,,,,{|| (FsProCot(1))},,/*"COLOR"*/,,,,,,,.T.))
oTMenu4:Add(TMenuItem():New(oTMenu3,"Aprovar"   ,,,,{|| (FsProCot(2))},,/*"COLOR"*/,,,,,,,.T.))
oTMenuBar:AddItem('Processo Cota��o', oTMenu4, .T.)

SetKey(VK_F2,{|| FsBtnMnt(1,'N')}) //-- Novo - Atalho F2

//-- Cordenad. Objetos Vertical
aPosHei := MsObjGetPos(oPan02:nHeight,12,{{011.0,087.0,;	//-- 1  ,  2
	101.0,101.0,;	//-- 3  ,  4
	020.0,020.0,;	//-- 5  ,  6
	120.0,120.0}})  //-- 7  ,  8
//-- Cordenad. Objetos Horizontal
aPosWid := MsObjGetPos(oPan02:nWidth,1322,{{000.0,330.0,;	//-- 1  ,  2
	010.0,160.0,;	//-- 3  ,  4
	150.0,150.0,;  //-- 5  ,  6
	210.0,240.0,;  //-- 7  ,  8
	270.0,300.0}})  //-- 9  ,  10

//-- Cria array com itens da cota��o
aCabec1 := {}
aDadIt1 := {}

//-- Add primeiro campo de status
Aadd(aCabec1,{"",,"LEFT",10})
Aadd(aDadIt1,{""})

//-- Add demais campos marcados como usado
aStru  := FWSX3Util():GetListFieldsStruct( "SZD" , .T. )

For nXi := 1 To Len(aStru)
	If X3Uso(GETSX3CACHE(aStru[nXi][1], "X3_Usado")) .And. cNivel >= GETSX3CACHE(aStru[nXi][1], "X3_NIVEL")
		If GETSX3CACHE(aStru[nXi][1], "X3_TIPO") == 'N'
			Aadd(aCabec1,{GETSX3CACHE(aStru[nXi][1], "X3_TITULO"),GETSX3CACHE(aStru[nXi][1], "X3_PICTURE"),"RIGTH",GETSX3CACHE(aStru[nXi][1], "X3_TAMANHO")})
		ElseIf GETSX3CACHE(aStru[nXi][1], "X3_TIPO") == 'C'
			Aadd(aCabec1,{GETSX3CACHE(aStru[nXi][1], "X3_TITULO"),"@!","LEFT" ,GETSX3CACHE(aStru[nXi][1], "X3_TAMANHO")})
		ElseIf GETSX3CACHE(aStru[nXi][1], "X3_TIPO") == 'D'
			Aadd(aCabec1,{GETSX3CACHE(aStru[nXi][1], "X3_TITULO"),"@D","LEFT" ,GETSX3CACHE(aStru[nXi][1], "X3_TAMANHO")})
		Else
			Aadd(aCabec1,{GETSX3CACHE(aStru[nXi][1], "X3_TITULO"),,"LEFT" ,GETSX3CACHE(aStru[nXi][1], "X3_TAMANHO")})
		EndIf
		Aadd(aUsados,GETSX3CACHE(aStru[nXi][1], "X3_CAMPO"))
		Aadd(aDadIt1[1],CriaVar(GETSX3CACHE(aStru[nXi][1], "X3_CAMPO")))
	EndIf
Next nXi

Aadd(aDadIt1[1],.F.)

//-- Cria browse de itens de cota��o
oBrowse1 := MsBrGetDBase():New(aPosHei[1,1],aPosWid[1,1],aPosWid[1,2],aPosHei[1,2],,,,oPan02,,,,,,,,,,,,.F.,"",.T.,,.F.,,,)

//-- Cria coluna de legenda do browse
bColumn :=  &("{ || FsDefCor(aDadIt1,oBrowse1:nAt) }")
oBrowse1:AddColumn(TCColumn():New(aCabec1[1,1],bColumn,aCabec1[1,2],,,aCabec1[1,3],aCabec1[1,4],.T.,.F.,,,,.F.,))

//-- Cria demais colunas do browse
For nXi:= 2 to Len(aCabec1)
	bColumn :=  &("{ || aDadIt1[oBrowse1:nAt,"+cValToChar(nXi)+"] }")
	oBrowse1:AddColumn(TCColumn():New(aCabec1[nXi,1],bColumn,aCabec1[nXi,2],,,aCabec1[nXi,3],/*aCabec1[nXi,4]*/,.F.,.F.,,,,.F.,))
Next nXi

oBrowse1:nScrollType:= 1 //-- Define a barra de rolagem VCR

//oBrowse1:bChange := {|x| FSCrgMnt()}
oBrowse1:bLDblClick	:= {|| MsgRun("Carregando Item...","Aguarde...",{|| FSCrgMnt()})}
//-- Define cores do registro deletado.
bColor := &("{|| if(aDadIt1[oBrowse1:nAt,Len(aDadIt1[oBrowse1:nAt])],"+Str(CLR_WHITE)+","+Str(CLR_BLACK)+")}")
oBrowse1:SetBlkColor(bColor)
bColor := &("{|| if(aDadIt1[oBrowse1:nAt,Len(aDadIt1[oBrowse1:nAt])],"+Str(CLR_LIGHTGRAY)+","+Str(CLR_WHITE)+")}")
oBrowse1:SetBlkBackColor(bColor)

oBrowse1:SetArray(aDadIt1)
oBrowse1:SetFocus()
nHBrows1 := GetFocus()

//-- Total em R$
oSayTo1	:= TSay():New(aPosHei[1,3],aPosWid[1,3],{||cTotRea},oPan02,,oFont19N,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,5],aPosHei[1,5],,,,,,.T.)
//-- Total em US$
oSayTo2	:= TSay():New(aPosHei[1,4],aPosWid[1,4],{||cTotDol},oPan02,,oFont19N,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,6],aPosHei[1,6],,,,,,.T.)

//Cria os bot�es da Tela 
oBtnSalvar := tButton():New(aPosHei[1,7] ,aPosWid[1,10],OemToAnsi("Salvar"),oPan02,{|| iIf(!obrigatorio(aGets,aTela),nOpca := 0,iIf(!FsVldCad(),nOpca := 0,(nOpca:=1, oDlg:End())))  },040,015,,,.T.,.T.,,OemToAnsi("Salvar"))
oBtnSalvar:SetCSS(cCSS) 
oBtnSalvar:SetColor(CLR_WHITE)
oBtnCancel := tButton():New(aPosHei[1,7] ,aPosWid[1,9],OemToAnsi("Cancelar"),oPan02,{|| nOpca := 2, oDlg:End() },040,015,,,.T.,.T.,,OemToAnsi("Cancelar"))
oBtnLeg    := tButton():New(aPosHei[1,7] ,aPosWid[1,8],OemToAnsi("Legenda"),oPan02,{|| FsBtnMnt(5) },040,015,,,.T.,.T.,,OemToAnsi("Legenda"))
oBtnAprov  := tButton():New(aPosHei[1,7] ,aPosWid[1,7],OemToAnsi("Contr.Aprov"),oPan02,{|| U_telaZ0E() },040,015,,,.T.,.T.,,OemToAnsi("Contr.Aprov"))


iIf(ALTERA .OR. lCopia .Or. nOpc == 2 .Or. nOpc == 5,MsgRun("Carregando Itens...","Aguarde...",{|| FsCarReg(nOpc)}),Nil)

ACTIVATE MSDIALOG oDlg CENTERED
//Aadd(aButEnc, {"COLOR", {|| FsBtnMnt(5)}, "Legenda Itens", "Legenda Itens" , {|| .T.}} )
//Aadd(aButEnc, {"COLOR", {|| u_telaZ0E()}, "Contr.Aprov.", "Controle Aprova��o" , {|| .T.}} )		// AS - Aleluia

//ACTIVATE MSDIALOG oDlg CENTERED ON INIT (EnchoiceBar(oDlg,{|| iIf(!obrigatorio(aGets,aTela),nOpca := 0,iIf(!FsVldCad(),nOpca := 0,(nOpca:=1, oDlg:End()))) },{|| (nOpca := 2, oDlg:End())},,aButEnc),;
	//iIf(ALTERA .OR. lCopia .Or. nOpc == 2 .Or. nOpc == 5,MsgRun("Carregando Itens...","Aguarde...",{|| FsCarReg(nOpc)}),Nil))

If nOpca == 1

	Begin Transaction

		If nOpc == 3 .Or. nOpc == 4 .Or. nOpc == 5
			FsSlvOrc()
			ConfirmSX8()
			// ->> AS - Aleluia - Processa os bloqueios nas cota��es de venda
			U_TIVRO130( FWxFilial("SZC"), SZC->ZC_CODIGO)
			// <<- AS - Aleluia - Processa os bloqueios nas cota��es de venda
		EndIf

	End Transaction
ElseIf nOpca == 2
	RollBackSx8()
EndIf

//-- Fim Montagem da Tela

// ->> AS - 020421 - Inutiliza a vari�vel p�blica
If type("aXaColsPublicaTelaCotacaoVenda") <> "U"
	aXaColsPublicaTelaCotacaoVenda := Nil
EndIf
// ->> AS - 020421 - Inutiliza a vari�vel p�blica

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} FsVldCad
Fun��o para validar cadastro de cota��o

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsVldCad()

Local lOk := .T.
Local cTexto := ""
Local nX := 0
Local nY := 0

If Empty(M->ZC_CLIENTE) .And. Empty(M->ZC_PROSPEC)
	lOk := .F.
	Alert("Necess�rio informar pelo menos um cliente e ou prospect para cota��o de venda.")
EndIf

If lOk
	If Empty(aDadAux)
		lOk := .F.
		Alert("Necess�rio cadastrar pelo menos um item para cota��o de venda.")
	EndIf
EndIf

// ->> AS - Aleluia - 11042021
if lOk .AND. lObrigaRM .AND. type("aXaColsPublicaTelaCotacaoVenda") <> "U" .AND. len(aXaColsPublicaTelaCotacaoVenda) == 0
	cTexto := "Quando o par�metro FS_OBRIREM estiver ligado � obrigat�rio o preenchimento da Remessa para o item."
	ApMsgAlert( cTexto, "PIFATC12 - " + AllTrim(Str(ProcLine(0))) + " - Aten��o!")
	lOk := .F.
endif
// <<- AS - Aleluia - 11042021

// ->> Valida se existe distribui��o de remessa para os itens
if lOk .AND. type("aXaColsPublicaTelaCotacaoVenda") <> "U"

	// ----> Lucas :: 22/06/21 :: Aqui tenho que conferir se todas as previsoes estao cadastradas para todos os itens com as quantidades corretas...
	If INCLUI .Or. ALTERA 
		If !FVldPrv()
			Return .F.
		End If
	End If
	
endif
// <<- Valida se existe distribui��o de remessa para os itens

Return(lOk)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsBtnMnt
Rotinas do Menu de Manuten�a� de Itens

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11

@history  03/05/2022, Wemerson Souza, Inclus�o de valida��es ao incluir novo produto na cota��o de venda.
@history 27/09/2022, .iNi Wemerson, Inclus�o de regra consulta do custo pricing/brill para produtos/pre-produtos tipo PA.
/*/
//-------------------------------------------------------------------
Static Function FsBtnMnt(nOpcMnu,cSubMen)

Local aAreaB1 := SB1->( GetArea() )

Default cSubMen := ""

If nOpcMnu == 1 //-- Novo
	aImpostos	:= {}
	aImposDef	:= {}
	aImposUsu	:= {}
	cIteAtu		:= ""
	cMotivo := ""
	cObserv := ""
	nQtdAte := 0
	cStatus	:= ""
	cUMPad	:= ""
	cQtdUM1 := " "
	cQtdUM2 := " "
	aIteUM	:= {"",""}
	cCodPrd := CriaVar("ZD_PRODUTO")
	cPrePrd := CriaVar("ZD_PREPROD")
	cDscPrd := CriaVar("B1_DESC")
	nQtdUM1 := CriaVar("ZD_QUANT1")
	nQtdUM2 := CriaVar("ZD_QUANT2")
	nDefCst := CriaVar("ZD_CUSTDEF")
	nDeDCst := CriaVar("ZD_CUSDDEF")
	nDeDFre := CriaVar("ZD_FREDDEF")
	nDefAut := CriaVar("ZD_AUTDDEF")
	nUsuAut := CriaVar("ZD_AUTDUSU")
	nDefMrg := CriaVar("ZD_MARGDEF")
	nDefCHi := CriaVar("ZD_PCMSDHI")
	nDefCMi := CriaVar("ZD_PCMSDMI")
	nDefCom := CriaVar("ZD_PCMSDEF")
	nDefDes := CriaVar("ZD_MARGDEF")
	nDefFre := CriaVar("ZD_FRETDEF")
	nDefImp := CriaVar("ZD_MARGDEF")
	nDefPRE := CriaVar("ZD_PV1RDEF")
	nDefPUS := CriaVar("ZD_PV1DDEF")
	nDefTRE := CriaVar("ZD_TO1RDEF")
	nDefTUS := CriaVar("ZD_TO1DDEF")
	nUsuCst := CriaVar("ZD_CUSTUSU")
	nUsuMrg := CriaVar("ZD_MARGUSU")
	nUsuCom := CriaVar("ZD_PCMSUSU")
	nUsuCPd := CriaVar("ZD_PCMSUSU")
	nUsuCHi := CriaVar("ZD_PCMSUHI")
	nUsuCMi := CriaVar("ZD_PCMSUMI")
	nUsuCPd := CriaVar("ZD_PCOMPAD")
	nUsuDes := CriaVar("ZD_MARGUSU")
	nUsuFre := CriaVar("ZD_FRETUSU")
	nUsuImp := CriaVar("ZD_MARGUSU")
	nUsuPRE := CriaVar("ZD_PV1RUSU")
	nUsuPUS := CriaVar("ZD_PV1DUSU")
	nUsuTRE := CriaVar("ZD_TO1RUSU")
	nUsuTUS := CriaVar("ZD_TO1DUSU")
	nDefMBR := CriaVar("ZD_MABRDEF")
	nDefMLQ := CriaVar("ZD_MALQDEF")
	nUsuMBR := CriaVar("ZD_MABRUSU")
	nUsuMLQ := CriaVar("ZD_MALQUSU")
	nDUsCst := CriaVar("ZD_CUSTUSU")
	nDUsFre := CriaVar("ZD_FRETUSU")
	nDUsTRE := CriaVar("ZD_TO1RUSU")
	nDUsTUS := CriaVar("ZD_TO1DUSU")
	nDUsMLQ := CriaVar("ZD_MALQUSU")
	nDefPRM := CriaVar("ZD_PV1RDEM")
	nDeDPRM := CriaVar("ZD_PV1DDEM")
	nDefMBM := CriaVar("ZD_MABRDEM")
	nDeDMBM := CriaVar("ZD_MABDDEM")
	nDefMLM := CriaVar("ZD_MALQDEM")
	nDeDMLM := CriaVar("ZD_MALDDEM")
	nDeDMBR := CriaVar("ZD_MABDDEF")
	nDEDMLQ := CriaVar("ZD_MALDDEF")
	nUsuPRM := CriaVar("ZD_PV1RUSM")
	nUsDPRM := CriaVar("ZD_PV1DUSM")
	nUsuMBM := CriaVar("ZD_MABRUSM")
	nUsDMBM := CriaVar("ZD_MABDUSM")
	nUsuMLM := CriaVar("ZD_MALQUSM")
	nUsDMLM := CriaVar("ZD_MALDUSM")
	nUsDMBR := CriaVar("ZD_MALDUSM")
	nUsDMLQ := CriaVar("ZD_MALDUSM")
	cProcess:= CriaVar("ZD_PROCESS")//--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
	cProcApv:= CriaVar("ZD_PROCAPV")//--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
	cBloDir := CriaVar("ZD_BLODIR")//--AS - Bloqueio Diretoria
	cBloDir := CriaVar("ZD_MSGDIR")//--AS - Msg. de Bloqueio Dir
	nDeDPRM2 := CriaVar("ZD_PV2DDEM") // -- Preco Minimo Default Dolar UM2
	nUsDPRM2 := CriaVar("ZD_PV2DUSM") // -- Preco Minimo Usuario Dolar UM2
	nDefPRM2 := CriaVar("ZD_PV2RDEM") // -- Preco Minimo Default Real UM2
	nUsuPRM2 := CriaVar("ZD_PV2RUSM") // -- Preco Minimo Usuario Real UM2

	cCodTabCot := CriaVar("ZD_CODTABC") //--Codigo Tabela Comissao

	lBscImp := .T.

		lDesUsuCst := .F.

		If cSubMen == 'N'
			If (Empty(M->ZC_CLIENTE) .And. Empty(M->ZC_PROSPEC)) .Or. (Empty(M->ZC_LOJACLI) .And. Empty(M->ZC_LOJAPRO)) .Or. !obrigatorio(aGets,aTela)
				Alert("Informe os dados do cabe�alho primeiramente!")
			Else
				FsMntIte() //-- Chama tela de manuten��o de item.
			EndIf
		EndIf

ElseIf nOpcMnu == 2 //-- Salvar

	If (Empty(cCodPrd) .And. Empty(cPrePrd)) .Or. Empty(nQtdUM1)
		Alert("Informe os dados da forma��o de pre�o para salvar o registro.")
		RestArea(aAreaB1)
		Return()
	EndIf
	
	If !Empty(cCodPrd)
		If SB1->B1_ZSTATUS <> '3'
			Alert("ATEN��O! O produto encontra-se n�o liberado em sistema, caso a venda seja realizada � importante que seja solicitada a reativa��o antes da inser��o do pedido.")
		EndIf
		If SB1->B1_MSBLQL  == '1'
			Alert("ATEN��O! O produto encontra-se inativo em sistema, caso a venda seja realizada � importante que seja solicitada a reativa��o antes da inser��o do pedido.")
		EndIf
	EndIf

	// 29/06/21 :: Lucas - MAIS - Fecha janela
	nXOpc := 1
	oDlgMnt:End()

	FsSlvIte()

ElseIf nOpcMnu == 3 //-- Excluir
	FsExcIte()
ElseIf nOpcMnu == 4 //-- FollowUp
	If cSubMen == "C" //-- Cancelar
		FsCanIte()
	ElseIf cSubMen == "P" //-- Perdeu Cota��o
		FsPrdIte()
	ElseIf cSubMen == "E" //-- Eliminar Res�duo
		FsEReIte()
	EndIf
ElseIf nOpcMnu == 5	//-- Legenda
	BrwLegenda(cCadastro,"Legenda", {	{"BR_VERDE"		,OemToAnsi("Incluido")},;
										{"BR_AMARELO"	,OemToAnsi("Renegociado")},;
										{"BR_LARANJA"	,OemToAnsi("Parcialmente Atendido")},;
										{"BR_VERMELHO"	,OemToAnsi("Atendido")},;
										{"BR_MARROM"	,OemToAnsi("Perdeu Cota��o")},;
										{"BR_PRETO"		,OemToAnsi("Cancelado")},;
										{"BR_PINK"		,OemToAnsi("Residuo Eliminado")}})
ElseIf nOpcMnu == 6 //-- Alterar Imposto
	If (!Empty(cCodPrd) .Or. !Empty(cPrePrd)) .And. !Empty(nQtdUM1)
		FsAltImp()
		FsVldCmp("GERAL")
	Else
		Alert("Nenhuma simula��o de pre�o carregada para altera��o de impostos!")
	EndIf
ElseIf nOpcMnu == 7 //-- Hist�rico
	If (!Empty(cCodPrd) .Or. !Empty(cPrePrd))
		FsTelHis()
	Else
		Alert("Nenhum produto ou pr�-produto selecionado para carregar hist�rico!")
	EndIf
EndIf

RestArea(aAreaB1)

Return(Nil)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsDefCor
Define legenda dos itens

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsDefCor(aDadIt1,nLin)

Local oLegend

If (aDadIt1[nLin,Len(aDadIt1[nLin])]) //-- Excluido
	oLegend := oSEclui
ElseIf (aDadIt1[nLin,1]) == 'I' //-- Incluido
	oLegend := oSVerde
ElseIf (aDadIt1[nLin,1]) == 'R' //-- Renegociado
	oLegend := oSAmare
ElseIf (aDadIt1[nLin,1]) == 'P' //-- Parcialmente Atendido
	oLegend := oSLaran
ElseIf (aDadIt1[nLin,1]) == 'A' //-- Atendido
	oLegend := oSVerme
ElseIf (aDadIt1[nLin,1]) == 'D' //-- Perdeu Cota��o
	oLegend := oSMarro
ElseIf (aDadIt1[nLin,1]) == 'C' //-- Cancelado
	oLegend := oSPreto
ElseIf (aDadIt1[nLin,1]) == 'E' //-- Residuo Eliminado
	oLegend := oSPink
EndIf

Return oLegend

//-------------------------------------------------------------------
/*/{Protheus.doc} PIFAT12B
Fun��o colocada no WHEN da SX3 para validar edi��o de campo.

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
User Function PIFAT12B(cCampo)

Local lPode := .F.
Local cAliasCota := ""

If INCLUI
	lPode := .T.
ElseIf ALTERA
	If SZC->ZC_STATUS == 'I' //-- Se Incluida
		lPode := .T.
	ElseIf SZC->ZC_STATUS == 'P' //-- Se Porposta
		If AllTrim(cCampo) $ 'ZC_CONDPAG,ZC_DTVALID'
			lPode := .T.
		EndIf
	ElseIf SZC->ZC_STATUS == 'A' //-- Se Parcialmente Atendida
		If AllTrim(cCampo) $ 'ZC_DTVALID'
			lPode := .T.
		EndIf
	EndIf
EndIf

Return(lPode)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsVldCmp
Fun��o para validar preenchimento dos campos dos itens

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11

@history 29/06/2018, Igor Rabelo, Valida informa��es de UM para pr�-produto
/*/
//-------------------------------------------------------------------
Static Function FsVldCmp(cCampo)

Local lOK := .T.
Local nPrcRea := 0
Local nPrcDol := 0
Local nFatorConver := 0
Local cCodSTrib := ''
Local nCTirbEIcm  := 0
Local nBCustPiCo  := 0
Local nXi := 0
If cCampo == "ZD_PRODUTO"
	//-- Primeira coisa � avaliar se informou o Cliente e ou Prospect
	If (Empty(M->ZC_CLIENTE) .And. Empty(M->ZC_PROSPEC)) .Or. (Empty(M->ZC_LOJACLI) .And. Empty(M->ZC_LOJAPRO)) .Or. !obrigatorio(aGets,aTela)
		If !Empty(cCodPrd)
			Alert("Informe os dados do cabe�alho primeiramente!")
			cCodPrd := CriaVar("ZD_PRODUTO")
			lOk := .F.
		EndIf
	Else
		//-- Avaliar se produto existe
		SB1->(dbSetOrder(1))
		If SB1->(dbSeek(xFilial("SB1")+AvKey(cCodPrd,"B1_COD")))
			if !RetCodUsr() $ SuperGetMv("V_USCOTPLI", .F., "000887")
				//Valida se o Produto � customizado ou Materia-Prima
				if !( SB1->B1_ZCTMIZA $ "C/P" .OR. SB1->B1_TIPO == "MP" )
					Alert("N�o � permitido produto de linha na cota��o.")
					Return .F.	
				endif
			endif
			//-- Primeira coisa e garantir que a tela ta limpa
			cCodAux := cCodPrd
			FsBtnMnt(1)
			cCodPrd := cCodAux

			//-- Busca Descri��o
			cDscPrd := SB1->B1_DESC

			cQtdUM1 := SB1->B1_UM
			cQtdUM2 := SB1->B1_SEGUM
			//aIteUM	:= {cQtdUM1,cQtdUM2}
			if cQtdUM1 == 'KG'
				aIteUM	:= {cQtdUM1,cQtdUM2}	
			else
				aIteUM	:= {cQtdUM2,cQtdUM1}
			endif

			If procname(1) <> 'FSCRGCPY'
				oGetUm:SetItems(aIteUM)
				oGetUm:ReFresh()
			EndIf

			//-- Altera descri��o das UMs
			//cUMPad	:= SB1->B1_UM
			If procname(1) <> 'FSCRGCPY'
				oGetUm:Select(1)
				oGetUm:ReFresh()
			EndIf
			
			//-- Zera quantidades
			If nQtdUM1 <> 0 .Or. nQtdUM2 <> 0
				nQtdUM1 := 0
				nQtdUM2 := 0
				FsVldCmp("ZD_QUANT1")
			EndIf

			//-- Limpa o c�digo do Pre-Produto
			cPrePrd := CriaVar("ZD_PREPROD")

			//-- Busca o custo
			nDefCst := FsBscCst(cCodPrd,1)
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
			endif
			nDeDCst := FsCnvDol(nDefCst)
			//nUsuCst := iif(SB1->B1_TIPO == "PA",0,nDefCst) //--03/10/2022 -- .iNi Wemerson -- N�o � necess�io, devido a nova regra para pesquisa do csuto de produtos PA.
			nUsuCst := nDefCst
			nDUsCst := FsCnvDol(nUsuCst)

			//-- Busca a Margem
			nDefMrg := FsBscMrg(cCodPrd,1)
			nUsuMrg := nDefMrg

			//-- Busca a Comiss�o
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
		Else
			If !Empty(cCodPrd)
				lOk := .F.
			EndIf
		EndIf
	EndIf
ElseIf cCampo == "ZD_PREPROD"
	//-- Primeira coisa � avaliar se informou o Cliente e ou Prospect
	If Empty(M->ZC_CLIENTE) .And. Empty(M->ZC_PROSPEC)
		If !Empty(cPrePrd)
			Alert("Informe os dados do cabe�alho primeiramente!")
			cPrePrd := CriaVar("ZD_PREPROD")
			lOk := .F.
		EndIf
	Else
		//-- Avaliar se pre-produto existe
		SZA->(dbSetOrder(1))
		If SZA->(dbSeek(xFilial("SZA")+AvKey(cPrePrd,"ZA_CODIGO")))
			//-- N�o permie cotar pr�-produto que a 1� ou 2� unidade de medida n�o seja KG
			If SZA->ZA_UM == 'KG' .Or. SZA->ZA_SEGUM == 'KG'
				//-- Primeira coisa e garantir que a tela ta limpa
				cCodAux := cPrePrd
				FsBtnMnt(1)
				cPrePrd := cCodAux

				//-- Busca Descri��o
				cDscPrd := SZA->ZA_DESCRIC

				cQtdUM1 := SZA->ZA_UM
				cQtdUM2 := SZA->ZA_SEGUM
				//aIteUM	:= {cQtdUM1,cQtdUM2}

				if cQtdUM1 == 'KG'
					aIteUM	:= {cQtdUM1,cQtdUM2}	
				else
					aIteUM	:= {cQtdUM2,cQtdUM1}
				endif

				If procname(1) <> 'FSCRGCPY'
					oGetUm:SetItems(aIteUM)
					oGetUm:ReFresh()
				EndIf

				//-- Altera descri��o das UMs
				//cUMPad	:= SZA->ZA_UM
				If procname(1) <> 'FSCRGCPY'
					oGetUm:Select(1)
					oGetUm:ReFresh()
				EndIf

				//-- Zera quantidades
				If nQtdUM1 <> 0 .Or. nQtdUM2 <> 0
					nQtdUM1 := 0
					nQtdUM2 := 0
					FsVldCmp("ZD_QUANT1")
				EndIf

				//-- Limpa o c�digo do Produto
				cCodPrd := CriaVar("ZD_PRODUTO")

				//-- Busca o custo
				nDefCst := FsBscCst(cPrePrd,2)
				nDeDCst := FsCnvDol(nDefCst)
				nUsuCst := nDefCst
				nDUsCst := FsCnvDol(nUsuCst)

				//-- Busca a Margem
				nDefMrg := FsBscMrg(cPrePrd,2)
				nUsuMrg := nDefMrg

				//-- Busca a Comiss�o
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
			Else
				Alert("Somente � permitido utiliza��o de pr�-produto com unidade de medida em KG. (Verficar informa��o de 1� ou 2� UM).")
				lOk := .F.
			EndIf
		Else
			If !Empty(cPrePrd)
				lOk := .F.
			EndIf
		EndIf
	EndIf
ElseIf cCampo == "ZD_QUANT1" .And. AllTrim(cUMPad) == AllTrim(cQtdUM1)
	//-- Se n�o informou produto n�o deixa informar a quantidade
	If Empty(cPrePrd) .And. Empty(cCodPrd)
		If nQtdUM1 > 0
			Alert("Informe os dados de produto ou pr�-produto primeiramente!")
			nQtdUM1 := CriaVar("ZD_QUANT1")
			lOk := .F.
		Else
			lOk := .T.
		EndIf
	Else
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

		//-- Calcula o Pre�o de Venda Default
		CURSORWAIT()
		FsClcPrc(1,@nPrcRea,@nPrcDol,1,nDefCst) //-- Pre�o M�nimo Default
		CURSORARROW()

		aImposDef	:= aImpostos
		nImposto := 0
		For nXi := 1 To Len(aImposDef)
			nImposto += aImpostos[nXi]
		Next nXi
		nDefImp := nImposto

		nDefPRM := nPrcRea //-- Preco Minimo Real
		nDeDPRM := nPrcDol //-- Preco Minimo Dolar

		CURSORWAIT()
		FsClcPrc(1,@nPrcRea,@nPrcDol,2,nDefCst) //-- Pre�o Sugerido Default
		CURSORARROW()

		nDefPRE := nPrcRea //-- Pre�o Sugerido Real
		nDefPUS := nPrcDol //-- Pre�o Sugerido Dolar

		nDefTRE := nQtdUM1 * nDefPRE
		nDefTUS := nQtdUM1 * nDefPUS

		//-- Calcula o Pre�o de Venda Minimo Usuario
		CURSORWAIT( )
		FsClcPrc(2,@nPrcRea,@nPrcDol,1,nUsuCst)
		CURSORARROW()

		aImposUsu	:= aImpostos
		nImposto := 0
		For nXi := 1 To Len(aImposUsu)
			nImposto += aImpostos[nXi]
		Next nXi
		nUsuImp := nImposto

		nUsuPRM := nPrcRea //-- Preco Minimo Real
		nUsDPRM := nPrcDol //-- Preco Minimo Dolar

		//-- Calcula o Pre�o de Venda Sugerido Usuario
		CURSORWAIT( )
		FsClcPrc(2,@nPrcRea,@nPrcDol,2,nUsuCst)
		CURSORARROW()

		nUsuPRE := nPrcRea //-- Pre�o Sugerido Real
		nUsuPUS := nPrcDol //-- Pre�o Sugerido Dolar

		nUsuTRE := nQtdUM1 * nUsuPRE
		nUsuTUS := nQtdUM1 * nUsuPUS

		FClcMGS(1) //-- Calcula Margem (bruta e liquida) Default e de Usu�rio
	EndIf
ElseIf cCampo == "ZD_QUANT2" .And. AllTrim(cUMPad) == AllTrim(cQtdUM2)
	//-- Se n�o informou produto n�o deixa informar a quantidade
	If Empty(cPrePrd) .And. Empty(cCodPrd)
		If nQtdUM2 > 0
			Alert("Informe os dados de produto ou pr�-produto primeiramente!")
			nQtdUM2 := CriaVar("ZD_QUANT2")
			lOk := .F.
		Else
			lOk := .T.
		EndIf
	Else
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

		//-- Calcula o Pre�o de Venda Default
		CURSORWAIT()
		FsClcPrc(1,@nPrcRea,@nPrcDol,1,nDefCst) //-- Pre�o M�nimo Default
		CURSORARROW()

		aImposDef	:= aImpostos
		nImposto := 0
		For nXi := 1 To Len(aImposDef)
			nImposto += aImpostos[nXi]
		Next nXi
		nDefImp := nImposto

		nDefPRM2 := nPrcRea //-- Preco Minimo Real
		nDeDPRM2 := nPrcDol //-- Preco Minimo Dolar

		CURSORWAIT()
		FsClcPrc(1,@nPrcRea,@nPrcDol,2,nDefCst) //-- Pre�o Sugerido Default
		CURSORARROW()

		nDef2PRE := nPrcRea //-- Pre�o Sugerido Real
		nDef2PUS := nPrcDol //-- Pre�o Sugerido Dolar

		nDefTRE := nQtdUM2 * nPrcRea
		nDefTUS := nQtdUM2 * nPrcDol

		//-- Calcula o Pre�o de Venda Usuario
		CURSORWAIT()
		FsClcPrc(2,@nPrcRea,@nPrcDol,1,nUsuCst)
		CURSORARROW()

		aImposUsu	:= aImpostos
		nImposto := 0
		For nXi := 1 To Len(aImposUsu)
			nImposto += aImpostos[nXi]
		Next nXi
		nUsuImp := nImposto

		nUsuPRM2 := nPrcRea //-- Preco Minimo Real
		nUsDPRM2 := nPrcDol //-- Preco Minimo Dolar

		//-- Calcula o Pre�o de Venda Sugerido Usuario
		CURSORWAIT( )
		FsClcPrc(2,@nPrcRea,@nPrcDol,2,nUsuCst)
		CURSORARROW()

		nUsu2PRE := nPrcRea
		nUsu2PUS := nPrcDol

		nUsuTRE := nQtdUM2 * nUsu2PRE
		nUsuTUS := nQtdUM2 * nUsu2PUS

		FClcMGS(1) //-- Calcula Margem (bruta e liquida) Default e de Usu�rio
	EndIf
ElseIf cCampo == "ZD_CALCMRC"
	//-- Atualiza a Margem Usuario com a Margem Defaut
	nUsuMrg := nDefMrg

	//-- Atualiza a Comiss�o Usuario Com a Comiss�o Defaut
	nUsuCom := nDefCom
	nUsuCPd := nUsuCom
	nUsuCHi := nDefCHi
	
	//-- Atualiza a Despesa Usuario Com a Despesa Defaut
	nUsuDes := nDefDes

	//-- Atualiza a Autonomia de Desconto Usuario Com a a Autonomia de Desconto Defaut
	If !Empty(cCodPrd)
		nUsuAut := FsBscAut(cCodPrd,1)
	elseif !Empty(cPrePrd)
		nUsuAut := FsBscAut(cPrePrd,2)	
	else
		nUsuAut := FsAltAutoDesc()	
	endif

	FsVldCmp("GERAL")
	
ElseIf cCampo == "ZD_PCMSUMI"
	/*if !Empty(cCodTabCot) .And. cClcCRN == 'SIM' 
		nUsuAut := FsAltAutoDesc()			
	endif*/
	//-- Atualiza a Autonomia de Desconto Usuario Com a a Autonomia de Desconto Defaut
	If !Empty(cCodPrd)
		nUsuAut := FsBscAut(cCodPrd,1)
	elseif !Empty(cPrePrd)
		nUsuAut := FsBscAut(cPrePrd,2)	
	else
		nUsuAut := FsAltAutoDesc()	
	endif

ElseIf cCampo $ ("ZD_CUSTUSU,ZD_FRETUSU,GERAL")

	if !Empty(cCodPrd)
		SB1->(dbSetOrder(1))
		SB1->(dbSeek(xFilial("SB1")+AvKey(cCodPrd,"B1_COD")))
		nFatorConver := SB1->B1_CONV
	elseif !Empty(cPrePrd)
		SZA->(dbSetOrder(1))
		SZA->(dbSeek(xFilial("SZA")+AvKey(cPrePrd,"ZA_CODIGO")))
		nFatorConver := SZA->ZA_CONV
	endif 

	If cCampo == "ZD_CUSTUSU"
			nDUsCst := FsCnvDol(nUsuCst)
	ElseIf cCampo == "ZD_FRETUSU"
			nDUsFre := FsCnvDol(nUsuFre)
	EndIf	

	if AllTrim(cUMPad) == AllTrim(cQtdUM1)			
		
		//-- Calcula o Pre�o de Venda Usuario UM1
		CURSORWAIT()
		FsClcPrc(2,@nPrcRea,@nPrcDol,1,nUsuCst)
		CURSORARROW()

		aImposUsu	:= aImpostos
		nImposto := 0
		For nXi := 1 To Len(aImposUsu)
			nImposto += aImpostos[nXi]
		Next nXi
		nUsuImp := nImposto

		nUsuPRM := nPrcRea //-- Preco Minimo Real UM1
		nUsDPRM := nPrcDol //-- Preco Minimo Dolar UM1
			
		//-- Calcula o Pre�o de Venda Sugerido Usuario
		CURSORWAIT( )
		FsClcPrc(2,@nPrcRea,@nPrcDol,2,nUsuCst)
		CURSORARROW()

		nUsuPRE := nPrcRea  //--Pre�o Sugerido Real UM1
		nUsuPUS := nPrcDol	//--Pre�o Sugerido Dolar UM1
		nUsuTRE := nQtdUM1 * nUsuPRE
		nUsuTUS := nQtdUM1 * nUsuPUS
					
		if nUsuCst > 0
			//-- Calcula o Pre�o de Venda Usuario UM2
			CURSORWAIT()
			FsClcPrc(3,@nPrcRea,@nPrcDol,1,iif(cUMPad == 'KG',(nUsuCst * nFatorConver),(nUsuCst / nFatorConver)))
			CURSORARROW()

			nUsuPRM2 := nPrcRea //-- Preco Minimo Real UM2
			nUsDPRM2 := nPrcDol //-- Preco Minimo Dolar UM2

			//-- Calcula o Pre�o de Venda Sugerido Usuario
			CURSORWAIT( )
			FsClcPrc(3,@nPrcRea,@nPrcDol,2,iif(cUMPad == 'KG',(nUsuCst * nFatorConver),(nUsuCst / nFatorConver)))
			CURSORARROW()	

			nUsu2PRE := nPrcRea //--Pre�o Sugerido Real UM2
			nUsu2PUS := nPrcDol //--Pre�o Sugerido Dolar UM2
		Endif

	else

		//-- Calcula o Pre�o de Venda Usuario UM2
		CURSORWAIT()
		FsClcPrc(2,@nPrcRea,@nPrcDol,1,nUsuCst)
		CURSORARROW()

		aImposUsu := aImpostos
		nImposto := 0
		For nXi := 1 To Len(aImposUsu)
			nImposto += aImpostos[nXi]
		Next nXi
		nUsuImp := nImposto

		nUsuPRM2 := nPrcRea //-- Preco Minimo Real UM2
		nUsDPRM2 := nPrcDol //-- Preco Minimo Dolar UM2

		//-- Calcula o Pre�o de Venda Sugerido Usuario
		CURSORWAIT( )
		FsClcPrc(2,@nPrcRea,@nPrcDol,2,nUsuCst)
		CURSORARROW()

		nUsu2PRE := nPrcRea //--Pre�o Sugerido Real UM2
		nUsu2PUS := nPrcDol //--Pre�o Sugerido Dolar UM2
		nUsuTRE := nQtdUM2 * nUsu2PRE
		nUsuTUS := nQtdUM2 * nUsu2PUS

		if nUsuCst > 0 
			
			//-- Calcula o Pre�o de Venda Usuario UM1
			CURSORWAIT()
			FsClcPrc(3,@nPrcRea,@nPrcDol,1,iif(cUMPad == 'KG',(nUsuCst * nFatorConver),(nUsuCst / nFatorConver)))
			CURSORARROW()

			nUsuPRM := nPrcRea //-- Preco Minimo Real UM1
			nUsDPRM := nPrcDol //-- Preco Minimo Dolar UM1
				
			//-- Calcula o Pre�o de Venda Sugerido Usuario
			CURSORWAIT( )
			FsClcPrc(3,@nPrcRea,@nPrcDol,2,iif(cUMPad == 'KG',(nUsuCst * nFatorConver),(nUsuCst / nFatorConver)))
			CURSORARROW()

			nUsuPRE := nPrcRea  //--Pre�o Sugerido Real UM1
			nUsuPUS := nPrcDol	//--Pre�o Sugerido Dolar UM1
		endif
	endif


	If AllTrim(cUMPad) == AllTrim(cQtdUM1) .And. !Empty(cQtdUM1)
		If nQtdUM1 > 0			
			FsVldCmp("ZD_QUANT1")
		EndIf
	ElseIf AllTrim(cUMPad) == AllTrim(cQtdUM2) .And. !Empty(cQtdUM2)
		If nQtdUM2 > 0
			FsVldCmp("ZD_QUANT2")
		EndIf
	EndIf

	
	FClcMGS(2) //-- Calcula Margem (bruta e liquida) de Usu�rio
ElseIf cCampo $ ("ZD_CUSTDUS,ZD_FRETDUS")

	If cCampo == "ZD_CUSTDUS"
		nUsuCst := FsCnvRea(nDUsCst)
		FsVldCmp("ZD_CUSTUSU")
	ElseIf cCampo == "ZD_FRETDUS"
		nUsuFre := FsCnvRea(nDUsFre)
		FsVldCmp("ZD_FRETUSU")
	EndIf

ElseIf cCampo == "ZD_PV1RUSM" //-- Pre�o Minimo Real
	if AllTrim(cUMPad) == AllTrim(cQtdUM1)
		//-- Encontra a nova Margem
		nUsuMrg := FsClcMrg(nUsuPRM,1)			
	else
		nUsuMrg := FsClcMrg(nUsuPRM2,1)			
	endif
	FsVldCmp("GERAL")
ElseIf cCampo == "ZD_PV1DUSM" //-- Pre�o Minimo Dolar
	if AllTrim(cUMPad) == AllTrim(cQtdUM1)
		//-- Encontra o Pre�o em Real
		nUsuPRM := FsCnvRea(nUsDPRM)
		//-- Encontra a nova Margem
		nUsuMrg := FsClcMrg(nUsuPRM,1)
	else
		//-- Encontra o Pre�o em Real
		nUsuPRM2 := FsCnvRea(nUsDPRM2)
		//-- Encontra a nova Margem
		nUsuMrg := FsClcMrg(nUsuPRM2,1)
	endif
	FsVldCmp("GERAL")
ElseIf cCampo == "ZD_PV1RUSU" //-- Pre�o Sugerido Real
	if AllTrim(cUMPad) == AllTrim(cQtdUM1)
		//-- Encontra a nova Margem
		nUsuMrg := FsClcMrg(nUsuPRE,2)
		FsVldCmp("GERAL")
	else
		//-- Encontra a nova Margem
		nUsuMrg := FsClcMrg(nUsu2PRE,2)
		FsVldCmp("GERAL")
	endif

ElseIf cCampo == "ZD_PV1DUSU" //-- Pre�o Sugerido Dolar
	if AllTrim(cUMPad) == AllTrim(cQtdUM1)
		//-- Encontra o Pre�o em Real
		nUsuPRE := FsCnvRea(nUsuPUS)
		//-- Encontra a nova Margem
		nUsuMrg := FsClcMrg(nUsuPRE,2)
	else
		//-- Encontra o Pre�o em Real
		nUsu2PRE := FsCnvRea(nUsu2PUS)
		//-- Encontra a nova Margem
		nUsuMrg := FsClcMrg(nUsu2PRE,2)
	endif
	FsVldCmp("GERAL")

ElseIf cCampo $ ("ZD_MABRUSM,ZD_MABDUSM") //-- Margem Bruta Prc. Minimo

	//-- Iguala percentuais em Real e Dolar
	If cCampo == "ZD_MABRUSM"
		nUsDMBM := nUsuMBM
	ElseIf cCampo == "ZD_MABDUSM"
		nUsuMBM := nUsDMBM
	EndIf

	nTxEnca := (1 - (iIf(M->ZC_ENCARGO>0,M->ZC_ENCARGO,0)/100)) //-- Acha o encargo
	if AllTrim(cUMPad) == AllTrim(cQtdUM1)
		//-- Ao alterar a Margem Bruta, recalcula o pre�o minimo.
		//-- Formula: (([CUSTO]/(1-[MARGEM BRUTA]))/(1-[ENCARGOS]))
		nUsuPRM := Round(((nUsuCst / (1 - (nUsuMBM/100)))/nTxEnca),4)
	else
		//-- Ao alterar a Margem Bruta, recalcula o pre�o minimo.
		//-- Formula: (([CUSTO]/(1-[MARGEM BRUTA]))/(1-[ENCARGOS]))
		nUsuPRM2 := Round(((nUsuCst / (1 - (nUsuMBM/100)))/nTxEnca),4)
	endif
	FsVldCmp("ZD_PV1RUSM")

ElseIf cCampo $ ("ZD_MABRUSU,ZD_MABRDUS") //-- Margem Bruta Prc. Sugerido

	//-- Iguala percentuais em Real e Dolar
	If cCampo == "ZD_MABRUSU"
		nUsDMBR := nUsuMBR
	ElseIf cCampo == "ZD_MABRDUS"
		nUsuMBR := nUsDMBR
	EndIf

	nTxEnca := (1 - (iIf(M->ZC_ENCARGO>0,M->ZC_ENCARGO,0)/100)) //-- Acha o encargo
	if AllTrim(cUMPad) == AllTrim(cQtdUM1)
		//-- Ao alterar a Margem Bruta, recalcula o pre�o sugerido.
		//-- Formula: (([CUSTO]/(1-[MARGEM BRUTA]))/(1-[ENCARGOS]))
		nUsuPRE := Round(((nUsuCst / (1 - (nUsuMBR/100)))/nTxEnca),4)
	else	
		//-- Ao alterar a Margem Bruta, recalcula o pre�o sugerido.
		//-- Formula: (([CUSTO]/(1-[MARGEM BRUTA]))/(1-[ENCARGOS]))
		nUsu2PRE := Round(((nUsuCst / (1 - (nUsuMBR/100)))/nTxEnca),4)
	endif
	FsVldCmp("ZD_PV1RUSU")

ElseIf cCampo $ ("ZD_MALQUSM,ZD_MALDUSM") //-- Margem Liquida Prc. Minimo

	//-- Iguala percentuais em Real e Dolar
	If cCampo == "ZD_MALQUSM"
		nUsDMLM := nUsuMLM
	ElseIf cCampo == "ZD_MALDUSM"
		nUsuMLM := nUsDMLM
	EndIf

	nTxEnca := (1 - (iIf(M->ZC_ENCARGO>0,M->ZC_ENCARGO,0)/100)) //-- Acha o encargo
	if AllTrim(cUMPad) == AllTrim(cQtdUM1)
		//-- Ao alterar a Margem Liquida, recalcula o pre�o minimo.
		//-- Formula: (([CUSTO]+[FRETE])/((1-[MARGEM])-(([COMISSAO HIERARQUIA]+[COMISSAO RC]+[DESPESAS]+[IMPOSTOS])/(1-[ENCARGOS]))))/(1-[ENCARGOS])
		nUsuPRM := Round((((nUsuCst + nUsuFre) / ((1 - (nUsuMLM/100)) - (((nUsuImp + (nUsuCMi + nUsuCHi) + nUsuDes)/100)/nTxEnca)))/nTxEnca),4)
	else
			//-- Ao alterar a Margem Liquida, recalcula o pre�o minimo.
		//-- Formula: (([CUSTO]+[FRETE])/((1-[MARGEM])-(([COMISSAO HIERARQUIA]+[COMISSAO RC]+[DESPESAS]+[IMPOSTOS])/(1-[ENCARGOS]))))/(1-[ENCARGOS])
		nUsuPRM2 := Round((((nUsuCst + nUsuFre) / ((1 - (nUsuMLM/100)) - (((nUsuImp + (nUsuCMi + nUsuCHi) + nUsuDes)/100)/nTxEnca)))/nTxEnca),4)
	endif
	FsVldCmp("ZD_PV1RUSM")

ElseIf cCampo $ ("ZD_MALQUSU,ZD_MALQDUS") //-- Margem Liquida Prc. Sugerido

	//-- Iguala percentuais em Real e Dolar
	If cCampo == "ZD_MALQUSU"
		nUsDMLQ := nUsuMLQ
	ElseIf cCampo == "ZD_MALQDUS"
		nUsuMLQ := nUsDMLQ
	EndIf

	nTxEnca := (1 - (iIf(M->ZC_ENCARGO>0,M->ZC_ENCARGO,0)/100)) //-- Acha o encargo
	if AllTrim(cUMPad) == AllTrim(cQtdUM1)
		//-- Ao alterar a Margem Bruta, recalcula o pre�o sugerido.
		//-- Formula: (([CUSTO]+[FRETE])/((1-[MARGEM])-(([COMISSAO HIERARQUIA]+[COMISSAO RC]+[DESPESAS]+[IMPOSTOS])/(1-[ENCARGOS]))))/(1-[ENCARGOS])
		nUsuPRE := Round((((nUsuCst + nUsuFre) / ((1 - (nUsuMLQ/100)) - (((nUsuImp + (nUsuCPd + nUsuCHi) + nUsuDes)/100)/nTxEnca)))/nTxEnca),4)
	else
		//-- Ao alterar a Margem Bruta, recalcula o pre�o sugerido.
		//-- Formula: (([CUSTO]+[FRETE])/((1-[MARGEM])-(([COMISSAO HIERARQUIA]+[COMISSAO RC]+[DESPESAS]+[IMPOSTOS])/(1-[ENCARGOS]))))/(1-[ENCARGOS])
		nUsu2PRE := Round((((nUsuCst + nUsuFre) / ((1 - (nUsuMLQ/100)) - (((nUsuImp + (nUsuCPd + nUsuCHi) + nUsuDes)/100)/nTxEnca)))/nTxEnca),4)
	endif
	FsVldCmp("ZD_PV1RUSU")

ElseIf cCampo $ ("UMPAD") //-- Unidade de Medida Padr�o
	If cQtdUM1 <> cQtdUM2
		If !Empty(cCodPrd)
			SB1->(dbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+AvKey(cCodPrd,"B1_COD")))
			If AllTrim(cUMPad) == AllTrim(cQtdUM1) .And. !Empty(cQtdUM1)
				//If nUsuCst <> 0
					If SB1->B1_TIPCONV == 'D'
						If nUsuCst <> 0
							nUsuCst  := (nUsuCst / SB1->B1_CONV)
							nDUsCst := FsCnvDol(nUsuCst)
						endif
						nDefCst := (nDefCst / SB1->B1_CONV)
						nDeDCst := FsCnvDol(nDefCst)
					Else
						If nUsuCst <> 0
							nUsuCst := (nUsuCst * SB1->B1_CONV)
						endif
						nDefCst := (nDefCst * SB1->B1_CONV)
						nDeDCst := FsCnvDol(nDefCst)
					EndIf
				//EndIf
				If nQtdUM1 > 0
					nUsuFre := FsBscFrt(cCodPrd,cUMPad,1)
				EndIf
			ElseIf AllTrim(cUMPad) == AllTrim(cQtdUM2) .And. !Empty(cQtdUM2)
				//If nUsuCst <> 0
					If SB1->B1_TIPCONV == 'D'
						if nUsuCst <> 0
							nUsuCst  := (nUsuCst * SB1->B1_CONV)
						endif
						nDefCst := (nDefCst * SB1->B1_CONV)
						nDeDCst := FsCnvDol(nDefCst)
					Else
						if nUsuCst <> 0
							nUsuCst := (nUsuCst / SB1->B1_CONV)
						endif
						nDefCst := (nDefCst / SB1->B1_CONV)
						nDeDCst := FsCnvDol(nDefCst)
					EndIf
				//EndIf
				If nQtdUM2 > 0
					nUsuFre := FsBscFrt(cCodPrd,cUMPad,1)
				EndIf
			EndIf
		Else
			SZA->(dbSetOrder(1))
			SZA->(dbSeek(xFilial("SZA")+AvKey(cPrePrd,"ZA_CODIGO")))
			If AllTrim(cUMPad) == AllTrim(cQtdUM1) .And. !Empty(cQtdUM1)
				//If nUsuCst <> 0
					If SZA->ZA_TIPCONV == 'D'
						nUsuCst  := (nUsuCst / SZA->ZA_CONV)

						nDefCst := (nDefCst / SZA->ZA_CONV)
						nDeDCst := FsCnvDol(nDefCst)
					Else
						nUsuCst := (nUsuCst * SZA->ZA_CONV)

						nDefCst := (nDefCst * SZA->ZA_CONV)
						nDeDCst := FsCnvDol(nDefCst)
					EndIf
				//EndIf
				If nQtdUM1 > 0
					nUsuFre := FsBscFrt(cPrePrd,cUMPad,2)
				EndIf
			ElseIf AllTrim(cUMPad) == AllTrim(cQtdUM2) .And. !Empty(cQtdUM2)
				//If nUsuCst <> 0
					If SZA->ZA_TIPCONV == 'D'
						nUsuCst  := (nUsuCst * SZA->ZA_CONV)

						nDefCst := (nDefCst * SZA->ZA_CONV)
						nDeDCst := FsCnvDol(nDefCst)
					Else
						nUsuCst := (nUsuCst / SZA->ZA_CONV)

						nDefCst := (nDefCst / SZA->ZA_CONV)
						nDeDCst := FsCnvDol(nDefCst)
					EndIf
				//EndIf
				If nQtdUM2 > 0
					nUsuFre := FsBscFrt(cPrePrd,cUMPad,2)
				EndIf
			EndIf
		EndIf

		If AllTrim(cUMPad) == AllTrim(cQtdUM1) .And. !Empty(cQtdUM1)
			FsVldCmp("ZD_CUSTUSU")
			If nQtdUM1 > 0
				FsVldCmp("ZD_QUANT1")
			EndIf
		ElseIf AllTrim(cUMPad) == AllTrim(cQtdUM2) .And. !Empty(cQtdUM2)
			FsVldCmp("ZD_CUSTUSU")
			If nQtdUM2 > 0
				FsVldCmp("ZD_QUANT2")
			EndIf
		EndIf
	EndIf
EndIf

//--Desabilita campo custo quando n�o for MP.
If !Empty(cCodPrd)

	SB1->(dbSetOrder(1))
	SB1->(dbSeek(xFilial("SB1")+AvKey(cCodPrd,"B1_COD")))

	//--Desabilita campo custo quando n�o for MP.
	If SB1->B1_TIPO != "MP"
		lDesUsuCst := .T.
		oGetUsCstR:Disable()
		oGetUsCstD:Disable()
	EndIf

elseif !Empty(cPrePrd)

	//-- Avaliar se pre-produto existe
	SZA->(dbSetOrder(1))
	If SZA->(dbSeek(xFilial("SZA")+AvKey(cPrePrd,"ZA_CODIGO")))

		SB1->(dbSetOrder(1))
		if SB1->(DBSEEK(xFilial("SB1")+SZA->ZA_PRDSIMI))
			//--Desabilita campo custo quando n�o for MP.
			If SB1->B1_TIPO != "MP"
				lDesUsuCst := .T.
				oGetUsCstR:Disable()
				oGetUsCstD:Disable()
			EndIf
		EndIf
	EndIf

EndIf

//-- Executa refresh de todos objetos
FsExeRef()

Return(lOK)

//-------------------------------------------------------------------
/*/{Protheus.doc} PIFAT12C
Fun��o para gatilhos relacionados a cota��o de venda.
@type    function 
@author	 Igor Rabelo
@since	 16/03/2018
@version P11
@history 25/02/2022, Dayvid Nogueira, Comentada chamada da fun��o FsRetDis() para retorna a distancia pela APi da Google, pois o frete � calculado pela classe TIVCL008.
/*/
//-------------------------------------------------------------------
User Function PIFAT12C(cCampo)

	Local xReturn

	If AllTrim(cCampo) $ 'ZC_DISTANC'
		If !Empty(M->ZC_CLIENTE)
			P11->(dbSetOrder(2))
			If P11->(dbSeek(xFilial("P11")+M->ZC_CLIENTE+M->ZC_LOJACLI+xFilial("SZC")))
				xReturn := P11->P11_DISTKM
			Else
				xReturn := 0
				/*SA1->(dbSetOrder(1))
				If SA1->(dbSeek(xFilial("SA1")+M->ZC_CLIENTE+M->ZC_LOJACLI))
					
					MsgRun("Buscando Dist�ncia...","Aguarde...",{|| xReturn := FsRetDis(SA1->A1_MUN,SA1->A1_EST)})
				EndIf*/
			EndIf
		ElseIf !Empty(M->ZC_PROSPEC)
			xReturn := 0
			/*SUS->(dbSetOrder(1))
			If SUS->(dbSeek(xFilial("SUS")+M->ZC_PROSPEC+M->ZC_LOJAPRO))
				MsgRun("Buscando Dist�ncia...","Aguarde...",{|| xReturn := FsRetDis(SUS->US_MUN,SUS->US_EST)})
			EndIf*/
		EndIf
	ElseIf AllTrim(cCampo) $ 'ZC_CONDPAG'
		SE4->(dbSetOrder(1))
		SE4->(dbSeek(xFilial("SE4")+M->ZC_CONDPAG))
		xReturn := (iIf(!Empty(M->ZC_CONDPAG),iIf(SE4->E4_TIPO<>"9",SE4->E4_ZPRZME,0),0) * iIf(!Empty(M->ZC_CONDPAG),iIf(SE4->E4_TIPO<>"9",SE4->E4_ZTXADIA,0),0))
	EndIf

Return(xReturn)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsRetDis
Fun��o para retornar a dist�ncia do cliente ou prospect at� a filial
Copia de fun��o existente na Vaccinar.

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11

@history 23/04/2019, Leonardo Perrella,Adicionado a var�avel cKeyApi e adicionado na cURl para consulta Google. Retirado a vari�vel cQuery por nao ser tulizada no fonte.
/*/
//-------------------------------------------------------------------
Static Function FsRetDis(cCidade,cEstado)

	Local cUrl		 := ""
	Local cAviso	 := ""
	Local cErro		 := ""
	Local cDestino	 := StrTran(AllTrim(cCidade)," ","+") + "+" + AllTrim(cEstado)
	Local cKeyApi	 := "AIzaSyBeQQkytSPRuSBclHpbjN2Rp14yA-CGci0"
	Local aFiliais	 := {}
	Local nDistKM	 := 0
	Private oXml

	AADD(aFiliais,{AllTrim(SM0->M0_CODFIL),StrTran(StrTran(AllTrim(SM0->M0_ENDENT)," ","+"),",",""),StrTran(AllTrim(SM0->M0_CIDCOB)," ","+"),AllTrim(SM0->M0_ESTCOB)})

	//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
	//->Leonardo Perrella - 23/04/2019 - Concatenado na string cUrl a string cKeyApi.										 |
	//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
	cUrl := "https://maps.googleapis.com/maps/api/distancematrix/xml?origins=" + aFiliais[1][2] + "+" + aFiliais[1][3] + "+" + aFiliais[1][4] + "&destinations=" + cDestino + "&key=" + cKeyApi +"&language=pt-BR&sensor=false"
	//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
	//<-Leonardo Perrella - 23/04/2019 - Concatenado na string cUrl a string cKeyApi.										 |
	//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
	MemoWrite("\google\UrlGoogle.txt",cUrl)
	oXml := XmlParser(IIF(ValType(HttpGet(cUrl)) <> "C","",HttpGet(cUrl)),"_",@cAviso,@cErro)
	If ValType(oXml) == "O"
		If Type("oXml:_DistanceMatrixResponse:_ROW") == "O" //Verifica se ocorreu algum problema na verifica��o, como limite de uso no google excedido
			If AllTrim(oXml:_DistanceMatrixResponse:_ROW:_ELEMENT:_STATUS:TEXT) <> "NOT_FOUND" .And. AllTrim(oXml:_DistanceMatrixResponse:_ROW:_ELEMENT:_STATUS:TEXT) <> "ZERO_RESULTS" //Verifica se o endere�o foi encontrado
				nDistKM := AllTrim(oXml:_DistanceMatrixResponse:_ROW:_ELEMENT:_DISTANCE:_TEXT:TEXT)
				nDistKM := StrTran(nDistKM,"km","")
				nDistKM := Val(StrTran(StrTran(nDistKM,".",""),",","."))
			Else
				nDistKM := 0
			EndIf
		Else
			nDistKM := 0
		EndIf
	Else
		nDistKM := 0
	EndIf

	If Empty(nDistKM)
		Alert("N�o foi poss�vel calcular a dist�ncia para entrega no cliente. O frete dever� ser informado manualmente.")
	EndIf

Return(nDistKM)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsBscCst
Fun��o para buscar o custo do produto e ou pre-produto
@type function 
@author		Igor Rabelo
@since		16/03/2018
@version	P11
@history 14/09/2018, Rodrigo Prates, Como solicitado no chamado 2018091307000299, foi criado um campo na SBZ (BZ_ZESTICM) que recebe o percentual de estorno de ICMS que dever� ser acrescido ao custo do produto, quando existir. O ORDER BY foi retirado por ser desnecess�rio
@history 22/02/2019, Rodrigo Prates, Como solicitado no chamado 2019021907000637, o custo do pre-produto agora tem como origem o campo ZA_ZCUSBRI, preenchido pela TIVRO086() chamada, como bot�o, na tela de manuten��o de pre-produto PIFATC10
@history 08/10/2020, Lucas MAIS, Tratativa soliciada por Marlon, se o tipo do produto for MP ou RV, busca os dados da SZT, (Anteriormente era SZV), se o tipo nao for RV ou MP, o custo � zero.
@history 15/03/2022, Dayvid Nogueira, Corre��o para buscar o custo do produto Defaut de acordo com a unidade de medida em KG, para acompanhar a corre��o solicitada no chamado 2022022307000248. 
@history 27/09/2022, .iNi Wemerson, Inclus�o de regra consulta do custo pricing/brill para produtos/pre-produtos tipo PA.
/*/
//-------------------------------------------------------------------
Static Function FsBscCst(cCodigo,nTipo)
	Local cQuery  := ""
	Local nCstPrd := 0
	Local aCstPrd := {}
	Local aAreaB1 := SB1->(GetArea())
	Local cTpPrd  := ""
	Local cGrpOleo:= GetMv("PI_GRPECUS",,"3101")
	Local cGrpPrd := ''
	Local dDtValid:= CTOD("//")
	Local aCusFil := {}

	// ---- > Lucas - MAIS : 08/10/2020 - Posiciona no cadastro do produto para avaliar o tipo.
	SB1->(dbSetOrder(1))
	SB1->(dbSeek(xFilial("SB1")+cCodigo))

	cTpPrd := SB1->B1_TIPO

	RestArea(aAreaB1)
	// <---- Lucas - MAIS : 08/10/2020 - Posiciona no cadastro do produto para avaliar o tipo.
	If nTipo == 1 //--Custo para Produto
		U_FCLOSEAREA("QRYTMP")
		// ---- > Lucas - MAIS : 08/10/2020 - Conforme o tipo do produto, assume determinado valor de custo:
		If cTpPrd $ "MP/RV" // Se tipo for MP ou RV, busca custo da SZT, aplicando o percentual do campo BZ_ZESTICM
			cQuery := "SELECT ZT_CUSTO CUSTO," + Chr(13) + Chr(10)
			cQuery += "BZ_ZESTICM" + Chr(13) + Chr(10)
			cQuery += "FROM " + RetSqlName("SZT") + " ZT" + Chr(13) + Chr(10)
			cQuery += "INNER JOIN " + RetSqlName("SBZ") + " BZ ON BZ.D_E_L_E_T_ <> '*' AND BZ_FILIAL = ZT_FILIAL AND BZ_COD = ZT_PRODUTO" + Chr(13) + Chr(10)
			cQuery += "WHERE ZT.D_E_L_E_T_ <> '*' AND ZT_FILIAL = '" + xFilial("SZT") + "'" + Chr(13) + Chr(10) //percentual de estorno de ICMS nao tributado na entrada
			cQuery += "AND ZT_PRODUTO = '" + cCodigo + "'" + Chr(13) + Chr(10)
			cQuery += "AND ZT_DATA = TO_CHAR(SYSDATE,'YYYYMMDD')" + Chr(13) + Chr(10)

		else
			//Lucas - MAIS : 08/10/20 - Query/ tratativa anterior:
			cQuery := "SELECT ZV_CUSTO CUSTO," + Chr(13) + Chr(10)
			cQuery += "BZ_ZESTICM" + Chr(13) + Chr(10)
			cQuery += "FROM " + RetSqlName("SZV") + " ZV" + Chr(13) + Chr(10)
			cQuery += "INNER JOIN " + RetSqlName("SBZ") + " BZ ON BZ.D_E_L_E_T_ <> '*' AND BZ_FILIAL = ZV_FILIAL AND BZ_COD = ZV_PRODUTO" + Chr(13) + Chr(10)
			cQuery += "WHERE ZV.D_E_L_E_T_ <> '*' AND ZV_FILIAL = '" + xFilial("SZT") + "'" + Chr(13) + Chr(10) //percentual de estorno de ICMS nao tributado na entrada
			cQuery += "AND ZV_PRODUTO = '" + cCodigo + "'" + Chr(13) + Chr(10)
			cQuery += "AND ZV_DATA = '"+ DtoS(dDataBase) +"'" + Chr(13) + Chr(10)
			//cQuery += "AND ZV_DATA = TO_CHAR(SYSDATE,'YYYYMMDD')" + Chr(13) + Chr(10)

		Endif

		dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),"QRYTMP",.T.,.T.)
		If !QRYTMP->(EoF())
			if cUMPad == SB1->B1_UM
				nCstPrd := QRYTMP->CUSTO
			else
				nCstPrd := QRYTMP->CUSTO / SB1->B1_CONV 		
			endif
			/*If Right(AllTrim(FWArrFilAtu()[22]),2) == Posicione("SA1",1,xFilial("SA1") + M->ZC_CLIENTE,"A1_EST") .And. !Empty(QRYTMP->BZ_ZESTICM)
				nCstPrd := nCstPrd / (1 - (QRYTMP->BZ_ZESTICM / 100))
			EndIf*/
		EndIf
		U_FCLOSEAREA("QRYTMP")
		//Else
			//nCstPrd := 0
		//End If
		// < ----- Lucas - MAIS : 08/10/2020 - Conforme o tipo do produto, assume determinado valor de custo:
	ElseIf nTipo == 2 //--Custo para Pr�-Produto
		aCstPrd := StrTokArr2(Posicione("SZA",1,xFilial("SZA") + cCodigo,"ZA_ZCUSBRI"),"/")
		If Len(aCstPrd) > 0 .and. aScan(aCstPrd,{|a| SubStr(a,1,6) == cFilAnt}) > 0
			nCstPrd := Val(SubStr(aCstPrd[aScan(aCstPrd,{|a| SubStr(a,1,6) == cFilAnt})],9))
			aCusFil := StrTokArr2(aCstPrd[aScan(aCstPrd,{|a| SubStr(a,1,6) == cFilAnt})],"-")
			If Len(aCusFil) == 3
				dDtValid := IIF(!Empty(aCusFil[3]),STOD(AllTrim(aCusFil[3])),CTOD("//"))
			EndIf
		EndIf
	EndIf

	aAreaB1 := GetArea()

	SB1->(dbSetOrder(1))
	lDesUsuCst := .F.

	If nTipo == 1
		SB1->(dbSeek(xFilial("SB1")+cCodigo))
		cTpPrd := SB1->B1_TIPO
		cGrpPrd:= SB1->B1_GRUPO
		If cTpPrd == "PA" .And. !(cGrpPrd $ cGrpOleo)
			SBZ->(dbSetOrder(1))
			If SBZ->(dbSeek(xFilial("SBZ")+cCodigo))
				lDesUsuCst := .T.
				nCstPrd := 0
				If SBZ->BZ_ZCUSPRI > 0 .And. (!Empty(SBZ->BZ_ZDTCUSP) .And. ( DDATABASE <= SBZ->BZ_ZDTCUSP ))
					nCstPrd := SBZ->BZ_ZCUSPRI
				ElseIf SBZ->BZ_ZCUSBRI > 0
					nCstPrd := SBZ->BZ_ZCUSBRI
				Else
					MsgAlert("Produto "+AllTrim(cCodigo)+" sem Custo Price e Custo Brill validos, favor acionar a equipe da Nutri��o.")
				EndIf
			EndIf
		EndIf
	Else
		SB1->(dbSeek(xFilial("SB1")+Posicione("SZA",1,xFilial("SZA")+cCodigo,"ZA_PRDSIMI")))
		cTpPrd := SB1->B1_TIPO
		cGrpPrd:= SB1->B1_GRUPO
		If cTpPrd == "PA" .And. !(cGrpPrd $ cGrpOleo)
			lDesUsuCst := .T.
			If Empty(dDtValid) .Or. DDATABASE > dDtValid
				nCstPrd := 0
				MsgAlert("Pr�-produto "+AllTrim(cCodigo)+" sem Custo Brill v�lido, favor acionar a equipe da Nutri��o.")
			EndIf
		EndIf
	EndIf

	RestArea(aAreaB1)

Return(nCstPrd)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsBscMrg
Fun��o para buscar a Margem do produto e ou pre-produto

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsBscMrg(cCodigo,nTipo)

	Local nMrgPrd := 0
	Local cQuery := ""

	If nTipo == 2 //-- Se for para Pr�-Produto, usa produto similar
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
/*/{Protheus.doc} FsBscCom
Fun��o para buscar a comissao do produto e ou pre-produto

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
	

	If nTipo == 2 //-- Se for para Pr�-Produto, usa produto similar
		cCodigo := Posicione("SZA",1,xFilial("SZA")+cCodigo,"ZA_PRDSIMI")
	EndIf

	//Fun��o busca a Tabela de Comiss�o Padr�o das Cota��es, percentual Minimo e Maximo da tabela
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

	//-- Primeiramente tenta encontrar o percentual de comiss�o de acordo com a regra de comiss�o
	/*If !Empty(M->ZC_CLIENTE)
		//-- Busca o Centro de Custo da Linha de Produto
		SB1->(dbSetOrder(1))
		SB1->(dbSeek(xFilial("SB1")+cCodigo))
		cLinCC := iIf(SB1->B1_ZCCINDE == "N", SB1->B1_CC, AvKey(" ","C6_ZLNCC"))

		aRegraComis := U_FMelhorRegr(xFilial("SC5"),@cLog,dDataBase,M->ZC_CLIENTE,M->ZC_LOJACLI,cLinCC,cCodigo,Nil,Nil,"","",0)
		For xY := 1 To Len(aRegraComis)
			If U_PIVlGerCom(aRegraComis[xY][2],dDataBase)
				lEncRgr := .T.
				If aRegraComis[xY][3] $ cCrgRep //-- Verifica se � do cargo representante.
					If aRegraComis[xY][4] > 0 //-- Se tiver preenchido o percentual fixo, ent�o � o minimo e m�ximo do representante.
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

	//-- Se n�o encontrou regra de comiss�o, ent�o pega o percentual padr�o.
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
	//Solicitado por Aline Cupertino para que a Comiss�o Hierarquia seja sempre o valor setado.
	nComHie := 0.5
	

Return({nCRpMin,nCRpMax,nComHie,cCodTabCom})

//-------------------------------------------------------------------
/*/{Protheus.doc} FsBscDes
Fun��o para buscar a despesa do produto e ou pre-produto

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

	If nTipo == 2 //-- Se for para Pr�-Produto, usa produto similar
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
/*/{Protheus.doc} FsBscFrt
Fun��o para buscar o frete do produto e ou pre-produto

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11

@history 29/06/2018, Igor Rabelo, Altera��o de Busca de Peso Bruto para pegar de acordo com a convers�o do pr�-produto e n�o no produto similar.
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
	If nTipo == 2 //-- Se for para Pr�-Produto, usa produto similar
		SZA->(dbSetOrder(1))
		SZA->(dbSeek(xFilial("SZA")+cCodigo))
		//-- Se Unidade de Medida da Cota��o � KG
		If cUMCalc == 'KG'
			nPesPrd := 1
		Else
			//-- Se n�o for KG, pega o CONV.
			nPesPrd := SZA->ZA_CONV
		EndIf
	Else
		SB1->(dbSetOrder(1))
		SB1->(dbSeek(xFilial("SB1")+AvKey(cCodigo,"B1_COD")))
		//-- Se Unidade de Medida da Cota��o � KG
		If cUMCalc == 'KG'
			nPesPrd := 1
		Else
			//-- Se n�o for KG, pega o CONV.
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

//-------------------------------------------------------------------
/*/{Protheus.doc} FsClcPrc
Fun��o para calcular pre�o de venda do produto e ou pre-produto
@type function 
@author		Igor Rabelo
@since		16/03/2018
@version	P11
@history 09/02/2022, Dayvid Nogueira, Inserida valida��o para buscar o Peso de convers�o para calculo do frete do Pre-Produto.
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

	If !Empty(cPrePrd) //-- Se for para Pr�-Produto, usa produto similar
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
		//-- .iNi Retirado Percentual de Comiss�o Sugerido do C�lculo de Pre�o
		/*
		If nTpPrc == 1 //-- Calcular pre�o m�nimo
			nComisao  := nDefCMi + nDefCHi
		Else
			nComisao  := nDefCom + nDefCHi
		EndIf
		*/
		nComisao  := nDefCMi + nDefCHi
		//-- .iNi Retirado Percentual de Comiss�o Sugerido do C�lculo de Pre�o
		nDespesa  := nDefDes
		nFrete    := nDefFre
		nImposto  := nDefImp
		aImpostos := aImposDef
		nAutDsc   := nDefAut
	ElseIf nTipo == 2 //-- Usu�rio
		//nCusto 	  := nUsuCst
		nMargem   := nUsuMrg
		//-- .iNi Retirado Percentual de Comiss�o Sugerido do C�lculo de Pre�o
		/*
		If nTpPrc == 1 //-- Calcular pre�o m�nimo
			nComisao  := nUsuCMi + nUsuCHi
		Else
			nComisao  := nUsuCom + nUsuCHi
		EndIf
		*/
		nComisao  := nUsuCMi + nUsuCHi
		//-- .iNi Retirado Percentual de Comiss�o Sugerido do C�lculo de Pre�o
		nDespesa  := nUsuDes
		nFrete    := nUsuFre
		nImposto  := nUsuImp
		aImpostos := aImposUsu
		nAutDsc   := nUsuAut
	ElseIf nTipo == 3 //-- Outra Unidade de Medida do Usuario
		nMargem   := nUsuMrg
		nComisao  := nUsuCMi + nUsuCHi
		nDespesa  := nUsuDes
		nFrete    :=  iif(AllTrim(cUMPad) == 'KG',nUsuFre * nPesPrd,nUsuFre) //FsBscFrt(cCodigo,iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),cQtdUM2,cQtdUM1),1)
		nImposto  := nUsuImp
		aImpostos := aImposUsu
		nAutDsc   := nUsuAut	
	EndIf

	//-- Retirado a pedido do Leo. Verificar se ser� necess�rio posteriormente.
	/*
	nResulFat := (nCusto +; //Custo Brill
				   ((nCusto / (1 - (IIF(AllTrim(SB1->B1_ZCTMIZA) == "S",0,nFatorSeg) / 100))) - nCusto) +; //Calculo do Fator de Seguran�a
				   ((nCusto / (1 - (nFatorAjus / 100))) - nCusto); //Calculo do Fator de Ajuste
				   )
	*/
	nResulFat := nCusto

	nCalcMarg := (nResulFat / (1 - (nMargem / 100)))

	nTotLiq := (nCalcMarg +; // Custo Brill, com os Fatores de Seguran�a e Ajuste, e Margem
		nFrete +; // Frete
		((nCalcMarg / (1 - ((nComisao + nDespesa) / 100))) - nCalcMarg); //Calculo do Percentual de Comissao
		)
	If nImposto == 0 .And. lBscImp
		nImposto := 0
		FsBscImp(cCodigo,nTotLiq)

		For nXi := 1 To Len(aImpostos)
			nImposto += aImpostos[nXi]
		Next nXi
		//-- Se busca o imposto igual a .T. e for pre�o de usu�rio, marca para n�o buscar mais o imposto.
		If lBscImp .And. nTipo == 2
			lBscImp := .F.
		EndIf
	EndIf

	//-- Se for pre�o sugerido ent�o aplica autonomia de desconto.
	If nTpPrc == 2
		nTotLiq := (nTotLiq / (1 - (nAutDsc / 100)))
	EndIf

	nTotLiq := (nTotLiq / (1 - (nImposto / 100))) //-- Aplica o imposto

	nTxEnca := (1 - (iIf(M->ZC_ENCARGO>0,M->ZC_ENCARGO,0)/100)) //-- Acha o encargo
	nTotLiq := (nTotLiq / nTxEnca) //-- Aplica o encargo.

	nPrcRea := Round(nTotLiq,3)
	nPrcDol := Round((nTotLiq / nFatorCota),3)

Return(Nil)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsBscImp
Fun��o para buscar impostos do produto e ou pre-produto

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
	If !Empty(M->ZC_CLIENTE) //--Se for cota��o para cliente
		cCliente := M->ZC_CLIENTE
		cLojaCli := M->ZC_LOJACLI
	ElseIf !Empty(M->ZC_PROSPEC) //--Se for cota��o para prospect
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
		cTes := "504" //...tratamento necessario para que os impostos continuem sendo calculados corretamente de acordo com a regi�o, com bases cheias
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
Fun��o para buscar cliente semelhante ao prospect

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

/*------------------------------------------------------------------------------*\
|Fun��o: TIVCOTACAO
|Descri��o: Fun��o que verifica a moeda padr�o do produto p fazer o calculo de
|custo
|Data: 25/02/2016
|Responsavel:
|Parametro:	cAliasCota	Variavel contendo a alias disponivel naquele momento
|Parametro:	aStruct		Array passado como referencia que recebera o nome dos campos da query
|Retorno:	lOk			Variavel de controle que indica se a rotina deve ou n�o prosseguir
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
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasCota,.F.,.T.) //Cria uma tabela tempor�ria com as informa��es trazidas na query
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
/*/{Protheus.doc} FsClcMrg
Fun��o para calcular margem do produto e ou pre-produto

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsClcMrg(nPreco,nTpPrc)

	Local nTotLiq := 0
	Local nMargRet := 0
	Local nPrecoAux := 0
	Local nFatorSeg  := GetMv("TIV_FTRSEG",,0)
	Local nFatorAjus := GetMv("TIV_FTRAJU",,0)
	Local cCodigo := ""

	If !Empty(cPrePrd) //-- Se for para Pr�-Produto, usa produto similar
		cCodigo := Posicione("SZA",1,xFilial("SZA")+cPrePrd,"ZA_PRDSIMI")
	Else
		cCodigo := cCodPrd
	EndIf

	SB1->(dbSetOrder(1))
	SB1->(dbSeek(xFilial("SB1")+cCodigo))

	nFatorSeg := iIf(SB1->B1_TIPO == "MP",0,nFatorSeg)
	nFatorAjus := iIf(SB1->B1_TIPO $ "MP/RV",0,nFatorAjus)

	//-- Retiro o encargo.
	nPreco := (nPreco / (Round(((M->ZC_ENCARGO / (100 - M->ZC_ENCARGO)) * 100),2) + 100) * 100)

	//-- Retiro os impostos do valor informado pelo usu�rio.
	nTotLiq := (nPreco / (((nUsuImp / (100 - nUsuImp)) * 100) + 100)) * 100

	//-- Se for pre�o sugerido ent�o retira autonomia de desconto.
	If nTpPrc == 2
		nTotLiq := (nTotLiq / (((nUsuAut / (100 - nUsuAut)) * 100) + 100)) * 100
	EndIf

	//-- Retiro o frete do valor do resultado acima.
	nTotLiq := nTotLiq - nUsuFre

	//-- Retiro o frete e percentuais de comiss�o e despesa do resultado acima.
	//-- .iNi Retirado Percentual de Comiss�o Sugerido do C�lculo de Pre�o
	/*
If nTpPrc == 1 //-- Pre�o m�nimo
	nTotLiq := nTotLiq - (nTotLiq - (nTotLiq / (Round(((nUsuDes + (nUsuCMi + nUsuCHi)) / (100 - nUsuDes - (nUsuCMi + nUsuCHi)) * 100),2) + 100)  * 100))
ElseIf nTpPrc == 2 //-- Pre�o sugerido
	nTotLiq := nTotLiq - (nTotLiq - (nTotLiq / (Round(((nUsuDes + (nUsuCom + nUsuCHi)) / (100 - nUsuDes - (nUsuCom + nUsuCHi)) * 100),2) + 100)  * 100))
EndIf
	*/
	nTotLiq := nTotLiq - (nTotLiq - (nTotLiq / (Round(((nUsuDes + (nUsuCMi + nUsuCHi)) / (100 - nUsuDes - (nUsuCMi + nUsuCHi)) * 100),2) + 100)  * 100))
	//-- .iNi Retirado Percentual de Comiss�o Sugerido do C�lculo de Pre�o

	nPrecoAux :=  nUsuCst
	/*
nPrecoAux :=  (nUsuCst +; //Custo Brill
				   ((nUsuCst / (1 - (IIF(AllTrim(SB1->B1_ZCTMIZA) == "S",0,nFatorSeg) / 100))) - nUsuCst) +; //Calculo do Fator de Seguran�a
				   ((nUsuCst / (1 - (nFatorAjus / 100))) - nUsuCst); //Calculo do Fator de Ajuste
				   )
	*/

	nMargRet := Round(((nTotLiq - nPrecoAux) / nTotLiq) * 100,2)

Return(nMargRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsClcAut
Fun��o para calcular Autonomia de Desconto a partir do pre�o

@type function
@author		Igor Rabelo
@since		19/07/2019
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsClcAut(nPreco)

	Local nAutRet := 0
	Local nTotCAut := 0
	Local nCalcMarg := 0
	Local nTotLiq := 0

	//-- Retiro o encargo.
	nPreco := (nPreco / (Round(((M->ZC_ENCARGO / (100 - M->ZC_ENCARGO)) * 100),2) + 100) * 100)

	//-- Retiro os impostos do valor informado pelo usu�rio.
	nToCAut := (nPreco / (((nUsuImp / (100 - nUsuImp)) * 100) + 100)) * 100

	nCalcMarg := (nUsuCst / (1 - (nUsuMrg / 100)))

	//-- .iNi Retirado Percentual de Comiss�o Sugerido do C�lculo de Pre�o
	/*
nTotLiq := (nCalcMarg +; // Custo Brill, com os Fatores de Seguran�a e Ajuste, e Margem
				 nUsuFre +; // Frete
				 ((nCalcMarg / (1 - ((nUsuCom + nUsuCHi + nUsuDes) / 100))) - nCalcMarg); //Calculo do Percentual de Comissao
				 )
	*/
	nTotLiq := (nCalcMarg +; // Custo Brill, com os Fatores de Seguran�a e Ajuste, e Margem
		nUsuFre +; // Frete
		((nCalcMarg / (1 - ((nUsuCMi + nUsuCHi + nUsuDes) / 100))) - nCalcMarg); //Calculo do Percentual de Comissao
		)
	//-- .iNi Retirado Percentual de Comiss�o Sugerido do C�lculo de Pre�o

	nAutRet := Round((1 - (nTotLiq / nToCAut)),4)*100

Return(nAutRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsAltImp
Fun��o para alterar o imposto do usu�rio

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsAltImp()

	Local oDlgImp := Nil
	Local nImp1	:= iIf(Empty(aImposUsu[1]),0.00,aImposUsu[1])
	Local nImp2	:= iIf(Empty(aImposUsu[2]),0.00,aImposUsu[2])
	Local nImp3	:= iIf(Empty(aImposUsu[3]),0.00,aImposUsu[3])
	Local nImp4	:= iIf(Empty(aImposUsu[4]),0.00,aImposUsu[4])

	DEFINE MSDIALOG oDlgImp TITLE "Altera��o de Impostos" FROM 000,000 TO 160,220 PIXEL

	/*PIS,COFINS,ICMS,IPI*/

	@ 05,10 SAY "PIS: " SIZE 50,10 PIXEL OF oDlgImp
	cPicture := PesqPict("SZD","ZD_PPISDEF")
	@ 05,50 MSGET nImp1 SIZE 50,10 PIXEL OF oDlgImp PICTURE cPicture

	@ 20,10 SAY "COFINS: " SIZE 50,10 PIXEL OF oDlgImp
	cPicture := PesqPict("SZD","ZD_PCOFDEF")
	@ 20,50 MSGET nImp2 SIZE 50,10 PIXEL OF oDlgImp PICTURE cPicture

	@ 35,10 SAY "ICMS: " SIZE 50,10 PIXEL OF oDlgImp
	cPicture := PesqPict("SZD","ZD_PICMDEF")
	@ 35,50 MSGET nImp3 SIZE 50,10 PIXEL OF oDlgImp PICTURE cPicture

	@ 50,10 SAY "IPI: " SIZE 50,10 PIXEL OF oDlgImp
	cPicture := PesqPict("SZD","ZD_PIPIDEF")
	@ 50,50 MSGET nImp4 SIZE 50,10 PIXEL OF oDlgImp PICTURE cPicture

	oBtnOk	:= TButton():New( 65, 010, "Salvar",oDlgImp,{|| aImposUsu := {nImp1,nImp2,nImp3,nImp4} , nUsuImp := (nImp1+nImp2+nImp3+nImp4), FsVldCmp("ZD_MARGUSU"), oDlgImp:End()},40,12,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnEsc	:= TButton():New( 65, 060, "Cancelar",oDlgImp,{|| oDlgImp:End() },40,12,,,.F.,.T.,.F.,,.F.,,,.F. )

	ACTIVATE MSDIALOG oDlgImp CENTERED

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} FsCrgCpy
Fun��o para carregar itens do grid quando c�pia.

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
@obs
/*/
//-------------------------------------------------------------------
Static Function FsCrgCpy(nOpc)

	SZD->(dbSetOrder(1))
	SZD->(dbSeek(xFilial("SZD")+SZC->ZC_CODIGO))
	Do While (SZD->ZD_COTACAO == SZC->ZC_CODIGO) .And. !SZD->(Eof())

		//-- No caso da c�pia deve refazer o pre�o de venda de todos os itens, ent�o s� reaproveita produto e quantidade.
		cCodPrd := SZD->ZD_PRODUTO
		cPrePrd := SZD->ZD_PREPROD
		If !Empty(cCodPrd)
			FsVldCmp("ZD_PRODUTO")
		Else
			FsVldCmp("ZD_PREPROD")
		EndIf
		nQtdUM1 := SZD->ZD_QUANT1
		FsVldCmp("ZD_QUANT1")

		FsSlvIte()

		SZD->(dbSkip())
	EndDo

	//-- Depois de incluir todos os itens, limpa a tela
	FsBtnMnt(1)

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} FsCrgIte
Fun��o para carregar itens do grid

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsCrgIte(nOpc)

	Local nXi := 0

	If nOpc <> 3 //-- Somente carrega o array se n�o for inclus�o
		SZD->(dbSetOrder(1))
		SZD->(dbSeek(xFilial("SZD")+SZC->ZC_CODIGO))
		Do While (SZD->ZD_COTACAO == SZC->ZC_CODIGO) .And. !SZD->(Eof())
			//--Limpa a tela
			FsBtnMnt(1)

			//-- Carreta produto
			cStatus := SZD->ZD_STATUS
			cIteAtu := SZD->ZD_ITEM
			cCodPrd := SZD->ZD_PRODUTO
			cPrePrd := SZD->ZD_PREPROD
			If !Empty(cCodPrd)
				cDscPrd := POSICIONE("SB1",1,xFilial("SB1")+AvKey(cCodPrd,"B1_COD"),"B1_DESC")
				cQtdUM1 := POSICIONE("SB1",1,xFilial("SB1")+AvKey(cCodPrd,"B1_COD"),"B1_UM")
				cQtdUM2 := POSICIONE("SB1",1,xFilial("SB1")+AvKey(cCodPrd,"B1_COD"),"B1_SEGUM")
			Else
				cDscPrd := POSICIONE("SZA",1,xFilial("SZA")+AvKey(cPrePrd,"B1_COD"),"ZA_DESCRIC")
				cQtdUM1 := POSICIONE("SZA",1,xFilial("SZA")+AvKey(cPrePrd,"B1_COD"),"ZA_UM")
				cQtdUM2 := POSICIONE("SZA",1,xFilial("SZA")+AvKey(cPrePrd,"B1_COD"),"ZA_SEGUM")
			EndIf
			nQtdUM1 := SZD->ZD_QUANT1
			nQtdUM2 := SZD->ZD_QUANT2
			cUMPad	:= SZD->ZD_UMPAD
			aIteUM	:= {cQtdUM1,cQtdUM2}

			//-- Carrega variaveis de forma��o de pre�o Default
			nDefCst := SZD->ZD_CUSTDEF
			nDeDCst := SZD->ZD_CUSDDEF
			nDeDFre := SZD->ZD_FREDDEF
			nDefAut := SZD->ZD_AUTDDEF
			nDefMrg := SZD->ZD_MARGDEF
			nDefCHi := SZD->ZD_PCMSDHI
			nDefCMi := SZD->ZD_PCMSDMI
			nDefCom := SZD->ZD_PCMSDEF
			nDefDes := SZD->ZD_PERCDES
			nDefFre := SZD->ZD_FRETDEF
			nDefPRE := SZD->ZD_PV1RDEF
			nDefPUS := SZD->ZD_PV1DDEF
			nDefTRE := SZD->ZD_TO1RDEF
			nDefTUS := SZD->ZD_TO1DDEF
			nDefMBR := SZD->ZD_MABRDEF
			nDefMLQ := SZD->ZD_MALQDEF
			nDefPRM := SZD->ZD_PV1RDEM
			nDeDPRM := SZD->ZD_PV1DDEM
			nDefMBM := SZD->ZD_MABRDEM
			nDeDMBM := SZD->ZD_MABDDEM
			nDefMLM := SZD->ZD_MALQDEM
			nDeDMLM := SZD->ZD_MALDDEM
			nDeDMBR := SZD->ZD_MABDDEF
			nDEDMLQ := SZD->ZD_MALDDEF

			//-- Carrega variaveis de forma��o de pre�o de usu�rio
			cClcCRN := SZD->ZD_CALCMRC
			nUsuCst := SZD->ZD_CUSTUSU
			nUsuAut := SZD->ZD_AUTDUSU
			nUsuMrg := SZD->ZD_MARGUSU
			nUsuCom := SZD->ZD_PCMSUSU
			nUsuCHi := SZD->ZD_PCMSUHI
			nUsuCMi := SZD->ZD_PCMSUMI
			nUsuCPd := SZD->ZD_PCOMPAD
			nUsuDes := SZD->ZD_PERCDES
			nUsuFre := SZD->ZD_FRETUSU
			nUsuPRE := SZD->ZD_PV1RUSU
			nUsuTRE := SZD->ZD_TO1RUSU
			nUsuMBR := SZD->ZD_MABRUSU
			nUsuMLQ := SZD->ZD_MALQUSU
			nUsuPRM := SZD->ZD_PV1RUSM
			nUsDPRM := SZD->ZD_PV1DUSM
			nUsuMBM := SZD->ZD_MABRUSM
			nUsDMBM := SZD->ZD_MABDUSM
			nUsuMLM := SZD->ZD_MALQUSM
			nUsDMLM := SZD->ZD_MALDUSM
			nDUsCst := SZD->ZD_CUSTDUS
			nDUsFre := SZD->ZD_FRETDUS
			nUsuPUS := SZD->ZD_PV1DUSU
			nUsuTUS := SZD->ZD_TO1DUSU
			nUsDMBR := SZD->ZD_MABRDUS
			nUsDMLQ := SZD->ZD_MALQDUS
			cProcess:= SZD->ZD_PROCESS//--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
			cProcApv:= SZD->ZD_PROCAPV//--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
			cBloDir := SZD->ZD_BLODIR//--AS - Aleluia - Bloqueio Diretoria
			cMsgDir := SZD->ZD_MSGDIR//--AS - Aleluia - Msg. de Bloqueio Dir

			nDef2PRE := SZD->ZD_PV2RDEF //Pre�o Sugerido Default Real UM2
			nUsu2PRE := SZD->ZD_PV2RUSU //Pre�o Sugerido Usuario Real UM2
			nDef2PUS := SZD->ZD_PV2DDEF //Pre�o Sugerido Default Dolar UM2
			nUsu2PUS := SZD->ZD_PV2DUSU //Pre�o Sugerido Usuario Dolar UM2

			nDeDPRM2 := SZD->ZD_PV2DDEM // -- Preco Minimo Default Dolar UM2
			nUsDPRM2 := SZD->ZD_PV2DUSM // -- Preco Minimo Usuario Dolar UM2
	    	nDefPRM2 := SZD->ZD_PV2RDEM // -- Preco Minimo Default Real UM2
	    	nUsuPRM2 := SZD->ZD_PV2RUSM // -- Preco Minimo Usuario Real UM2

			cCodTabCot := SZD->ZD_CODTABC //Codigo Tabela Comissao

			aImposDef	:= {}
			aAdd(aImposDef,SZD->ZD_PPISDEF)
			aAdd(aImposDef,SZD->ZD_PCOFDEF)
			aAdd(aImposDef,SZD->ZD_PICMDEF)
			aAdd(aImposDef,SZD->ZD_PIPIDEF)

			For nXi := 1 To Len(aImposDef)
				nDefImp += aImposDef[nXi]
			Next nXi

			aImposUsu	:= {}
			aAdd(aImposUsu,SZD->ZD_PPISUSU)
			aAdd(aImposUsu,SZD->ZD_PCOFUSU)
			aAdd(aImposUsu,SZD->ZD_PICMUSU)
			aAdd(aImposUsu,SZD->ZD_PIPIUSU)

			For nXi := 1 To Len(aImposUsu)
				nUsuImp += aImposUsu[nXi]
			Next nXi

			lBscImp := .F.

			cMotivo := SZD->ZD_MOTIVO
			cObserv := SZD->ZD_OBSERV
			cCodCon := SZD->ZD_CODCON
			nQtdAte := SZD->ZD_QTD1ATE

			FsSlvIte(.T.)

			SZD->(dbSkip())
		EndDo
		//-- Depois de incluir todos os itens, limpa a tela
		FsBtnMnt(1)
	EndIf

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} FsSlvIte
Fun��o para salvar itens no grid

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
@obs		Se houver necessidade de incluir nova campo na tabela e na tela ser� necess�rio alterar essa fun��o.
/*/
//-------------------------------------------------------------------
Static Function FsSlvIte(lCarrega)

	Local nPos := 0
	Local nPosPrd := 0
	Local nPosPPr := 0
	Local nPosIte := 0
	Local nPosReg := 0
	Local nPosSts := 0
	Local cCodIte := ""

	Default lCarrega := .F.

	//-- Valida se produto j� foi incluido na cota��o e n�o permite incluir novamente.
	If !Empty(aDadIt1[1][1]) .And. Empty(cIteAtu) .And. !lCarrega
		nPosPrd := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PRODUTO")})
		nPosPPr := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PREPROD")})
		If ((aScan(aDadAux,{|b| AllTrim(b[nPosPrd][2]) == AllTrim(cCodPrd)})>0) .And. !Empty(cCodPrd)) .Or. ((aScan(aDadAux,{|b| AllTrim(b[nPosPPr][2]) == AllTrim(cPrePrd)})>0) .And. !Empty(cPrePrd))
			Alert(iIf(!Empty(cCodPrd),"Produto ","Pr�-Produto ")+"j� incluido na cota��o. A��o n�o permitida.")
			Return()
		EndIf

		//-- Valida se existe pr�-produto vinculado ao produto e n�o permite misturar.
		If !Empty(cCodPrd)
			cPreAux := POSICIONE("SZA",2,xFilial("SZA")+AvKey(cCodPrd,"ZA_PRDEFET"),"ZA_CODIGO")
			If ((aScan(aDadAux,{|b| AllTrim(b[nPosPPr][2]) == AllTrim(cPreAux)})>0) .And. !Empty(cPreAux))
				Alert("Pr�-Produto "+cPreAux+" vinculado a este produto e j� incluido na cota��o. A��o n�o permitida.")
				Return()
			EndIf
		EndIf
	EndIf

	If Empty(cIteAtu) .Or. lCarrega //-- Se item atual est� vazio ent�o � um novo registro ou � para carregar registro.

		If !lCarrega //-- Se for s� para carregar itens n�o recalcula.
			FsCnvVal() //-- Converte valores para 2 Unidade de Medida
		EndIf

		If !lCarrega
			If Empty(aDadAux)
				cCodIte := StrZero(1,3)
			Else
				nPosIte := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})
				cCodIte := StrZero(Val(aDadAux[Len(aDadAux)][nPosIte][2])+1,3)
			EndIf
			cStatus := "I"
		Else
			cCodIte := cIteAtu //-- Se for s� para carregar registros, ent�o usa o cIteAtu
		EndIf

		//-- Inclui novo item no array auxiliar.
		aAdd(aDadAux,{	{"ZD_ITEM   ", cCodIte},; 						//-- 01
			{"ZD_PRODUTO", cCodPrd},;						//-- 02
			{"ZD_PREPROD", cPrePrd},;						//-- 03
			{"ZD_QUANT1 ", nQtdUM1},; 						//-- 04
			{"ZD_QUANT2 ", nQtdUM2},; 						//-- 05
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
			{"ZD_PROCESS", cProcess},; 						//-- 76 //--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
			{"ZD_PROCAPV", cProcApv},; 						//-- 77 //--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
			{"ZD_BLODIR" , cBloDir},; 						//-- 78 //--AS - Aleluia - Bloqueio diretoria
			{"ZD_MSGDIR" , cMsgDir},; 						//-- 79 //--AS - Aleluia - Msg. de Bloqueio Dir
			{"ZD_PV2DDEM" , nDeDPRM2},; 					//-- 80 //-- Preco Minimo Default Dolar UM2	
			{"ZD_PV2DUSM" , nUsDPRM2},; 					//-- 81 //-- Preco Minimo Usuario Dolar UM2	
			{"ZD_PV2RDEM" , nDefPRM2},; 					//-- 82 //-- Preco Minimo Default Real UM2
			{"ZD_PV2RUSM" , nUsuPRM2},; 					//-- 83 //-- Preco Minimo Usuario Real UM2	
			{"ZD_CODTABC" , cCodTabCot},;                   //-- 84 //-- Codigo tabela Comissao	
			{"DELETE"	 , .F.}})							//-- 85 //-- Sempre manter esse campo como o ultimo.

		If Empty(aDadIt1[1][1]) //-- Verifica se � primeiro item.
			aDadIt1:={}
		EndIf

		//-- Add novo Item com status INCLUIDO
		Aadd(aDadIt1,{cStatus})
		nPos := Len(aDadIt1)

		//-- Incluo o registro no array do grid da tela.
		aEval(aUsados,{|a| cCampo:=a, iIf(aScan(aDadAux[Len(aDadAux)],{|b| AllTrim(b[1]) == AllTrim(cCampo)})>0,Aadd(aDadIt1[nPos],aDadAux[Len(aDadAux)][aScan(aDadAux[Len(aDadAux)],{|b| AllTrim(b[1]) == AllTrim(cCampo)})][2]),Nil)})

		//-- Inclui campo de controle de deletados.
		Aadd(aDadIt1[nPos],.F.)

		//-- Atualizo o Browse
		oBrowse1:SetArray(aDadIt1)
		// oBrowse1:nAt := Len(aDadIt1)
		oBrowse1:Refresh()
		oDlg02:Refresh()

		//-- Limpo a tela de manuten��o de itens
		FsBtnMnt(1)

		oBrowse1:SetFocus()
	Else

		nPosSts := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_STATUS")})
		nPosIte := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})
		nPosReg := aScan(aDadAux,{|b| AllTrim(b[nPosIte][2]) == AllTrim(cIteAtu)})

		If !(aDadAux[nPosReg][nPosSts][2] $ 'I,R')
			Alert("A��o n�o permitida para status do item.")
			Return()
		EndIf

		FsCnvVal() //-- Converte valores para 2 Unidade de Medida

		//-- Inclui novo item no array auxiliar.
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM   ")})][2] := cIteAtu 						//-- 01
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PRODUTO")})][2] := cCodPrd						//-- 02
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PREPROD")})][2] := cPrePrd						//-- 03
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT1 ")})][2] := nQtdUM1 						//-- 04
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT2 ")})][2] := nQtdUM2 						//-- 05
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSTDEF")})][2] := nDefCst 						//-- 06
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSTUSU")})][2] := nUsuCst 						//-- 07
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MARGDEF")})][2] := nDefMrg 						//-- 08
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MARGUSU")})][2] := nUsuMrg 						//-- 09
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PERCDES")})][2] := nDefDes	 					//-- 10
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSDEF")})][2] := nDefCom 						//-- 11
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSUSU")})][2] := nUsuCom 						//-- 12
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_FRETDEF")})][2] := nDefFre 						//-- 13
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_FRETUSU")})][2] := nUsuFre 						//-- 14
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PPISDEF")})][2] := aImposDef[1] 				//-- 15 - PIS
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PPISUSU")})][2] := aImposUsu[1] 				//-- 16 - PIS
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCOFDEF")})][2] := aImposDef[2] 				//-- 17 - COFINS
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCOFUSU")})][2] := aImposUsu[2] 				//-- 18 - COFINS
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PICMDEF")})][2] := aImposDef[3] 				//-- 19 - ICMS
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PICMUSU")})][2] := aImposUsu[3] 				//-- 20 - ICMS
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PIPIDEF")})][2] := aImposDef[4] 				//-- 21 - IPI
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PIPIUSU")})][2] := aImposUsu[4] 				//-- 22 - IPI
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RDEF")})][2] := nDefPRE 						//-- 23
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RUSU")})][2] := nUsuPRE 						//-- 24
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RDEF")})][2] := nDef2PRE 					//-- 25
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSU")})][2] := nUsu2PRE 					//-- 26
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DDEF")})][2] := nDefPUS 						//-- 27
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DUSU")})][2] := nUsuPUS 						//-- 28
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DDEF")})][2] := nDef2PUS 					//-- 29
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSU")})][2] := nUsu2PUS		 				//-- 30
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1RDEF")})][2] := nDefTRE 						//-- 31
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1RUSU")})][2] := nUsuTRE 						//-- 32
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1DDEF")})][2] := nDefTUS 						//-- 33
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1DUSU")})][2] := nUsuTUS 						//-- 34
		//aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_OBSERV ")})][2] := ""							//-- 35
		//aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MOTIVO ")})][2] := ""							//-- 36
		//aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QTD1ATE")})][2] := 0 							//-- 37
		If ALTERA
			If (SZC->ZC_STATUS == 'P')
				aDadIt1[nPosReg][1] := "R"
				aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_STATUS ")})][2] := "R"					//-- 38
				aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_DTRENEG")})][2] := dDataBase			//-- 39
			Else
				aDadIt1[nPosReg][1] := "I"
				aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_STATUS ")})][2] := "I"					//-- 38
			EndIf
		Else
			aDadIt1[nPosReg][1] := "I"
			aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_STATUS ")})][2] := "I"						//-- 38
		EndIf
		//aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_COTACAO")})][2] := M->ZC_CODIGO}})				//-- 40

		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRDEF")})][2] := nDefMBR 						//-- 41
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQDEF")})][2] := nDefMLQ 						//-- 42
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRUSU")})][2] := nUsuMBR 						//-- 43
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQUSU")})][2] := nUsuMLQ 						//-- 44
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSTDUS")})][2] := nDUsCst						//-- 45
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_FRETDUS")})][2] := nDUsFre						//-- 46
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRDUS")})][2] := nUsDMBR						//-- 47
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQDUS")})][2] := nUsDMLQ 						//-- 48
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_UMPAD")})][2] 	:= cUMPad 						//-- 49
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_AUTDDEF")})][2] := nDefAut	 					//-- 50
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_AUTDUSU")})][2] := nUsuAut	 					//-- 51
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSDHI")})][2] := nDefCHi 	 					//-- 52
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSDMI")})][2] := nDefCMi 	 					//-- 53
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSUHI")})][2] := nUsuCHi 	 					//-- 52
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSUMI")})][2] := nUsuCMi 	 					//-- 53
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RDEM")})][2] := nDefPRM
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DDEM")})][2] := nDeDPRM
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRDEM")})][2] := nDefMBM
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABDDEM")})][2] := nDeDMBM
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQDEM")})][2] := nDefMLM
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALDDEM")})][2] := nDeDMLM
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABDDEF")})][2] := nDeDMBR
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALDDEF")})][2] := nDEDMLQ
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RUSM")})][2] := nUsuPRM
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DUSM")})][2] := nUsDPRM
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRUSM")})][2] := nUsuMBM
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABDUSM")})][2] := nUsDMBM
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQUSM")})][2] := nUsuMLM
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALDUSM")})][2] := nUsDMLM
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSDDEF")})][2] := nDeDCst
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_FREDDEF")})][2] := nDeDFre
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCOMPAD")})][2] := nUsuCPd
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CALCMRC")})][2] := cClcCRN
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCESS")})][2] := cProcess //--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCAPV")})][2] := cProcApv //--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_BLODIR")})][2]  := cBloDir //--AS - Aleluia - Bloqueio Diretoria
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MSGDIR")})][2]  := cMsgDir //--AS - Aleluia - Msg. de Bloqueio Dir


		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DDEM")})][2]  := nDeDPRM2 // -- Preco Minimo Default Dolar UM2
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSM")})][2]  := nUsDPRM2 // -- Preco Minimo Usuario Dolar UM2
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RDEM")})][2]  := nDefPRM2 // -- Preco Minimo Default Real UM2
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSM")})][2]  := nUsuPRM2 // -- Preco Minimo Usuario Real UM2
		aDadAux[nPosReg][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CODTABC")})][2]  := cCodTabCot // -- Codigo Tabela Comissao

		//-- Incluo o registro no array do grid da tela.
		nXi := 1 //-- Come�a com 1 pois o primeiro registro � o status.
		aEval(aUsados,{|a| cCampo:=a, nXi++, iIf(aScan(aDadAux[nPosReg],{|b| AllTrim(b[1]) == AllTrim(cCampo)})>0,aDadIt1[nPosReg][nXi] := aDadAux[nPosReg][aScan(aDadAux[Len(aDadAux)],{|b| AllTrim(b[1]) == AllTrim(cCampo)})][2],Nil)})

		//-- Atualizo o Browse
		oBrowse1:SetArray(aDadIt1)
		//oBrowse1:nAt := Len(aDadIt1)
		oBrowse1:Refresh()
		oDlg02:Refresh()

		//-- Limpo a tela de manuten��o de itens
		FsBtnMnt(1)

		oBrowse1:SetFocus()

	EndIf

	//-- Atualiza o total da cota��o
	FsSayTot()

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} FsCnvVal
Fun��o para converter valores para 2UM

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
@obs		Se houver necessidade de incluir nova campo na tabela e tela ser� necess�rio alterar essa fun��o.
/*/
//-------------------------------------------------------------------
Static Function FsCnvVal()

	nDef2PRE := 0
	nUsu2PRE := 0
	nDef2PUS := 0
	nUsu2PUS := 0

	//-- Converto os valores para 2UM
	If !Empty(cCodPrd)
		SB1->(dbSetOrder(1))
		SB1->(dbSeek(xFilial("SB1")+AvKey(cCodPrd,"B1_COD")))
		If SB1->B1_UM == SB1->B1_SEGUM
			nDef2PRE := nDefPRE
			nUsu2PRE := nUsuPRE
			nDef2PUS := nDefPUS
			nUsu2PUS := nUsuPUS
		ElseIf SB1->B1_TIPCONV == 'D'
			nDef2PRE := Round(nDefPRE * SB1->B1_CONV,4)
			nUsu2PRE := Round(nUsuPRE * SB1->B1_CONV,4)
			nDef2PUS := Round(nDefPUS * SB1->B1_CONV,4)
			nUsu2PUS := Round(nUsuPUS * SB1->B1_CONV,4)
		Else
			nDef2PRE := Round(nDefPRE / SB1->B1_CONV,4)
			nUsu2PRE := Round(nUsuPRE / SB1->B1_CONV,4)
			nDef2PUS := Round(nDefPUS / SB1->B1_CONV,4)
			nUsu2PUS := Round(nUsuPUS / SB1->B1_CONV,4)
		EndIf
	Else
		SZA->(dbSetOrder(1))
		SZA->(dbSeek(xFilial("SZA")+AvKey(cPrePrd,"ZA_CODIGO")))
		If SZA->ZA_UM == SZA->ZA_SEGUM
			nDef2PRE := nDefPRE
			nUsu2PRE := nUsuPRE
			nDef2PUS := nDefPUS
			nUsu2PUS := nUsuPUS
		ElseIf SZA->ZA_TIPCONV == 'D'
			nDef2PRE := Round(nDefPRE * SZA->ZA_CONV,4)
			nUsu2PRE := Round(nUsuPRE * SZA->ZA_CONV,4)
			nDef2PUS := Round(nDefPUS * SZA->ZA_CONV,4)
			nUsu2PUS := Round(nUsuPUS * SZA->ZA_CONV,4)
		Else
			nDef2PRE := Round(nDefPRE / SZA->ZA_CONV,4)
			nUsu2PRE := Round(nUsuPRE / SZA->ZA_CONV,4)
			nDef2PUS := Round(nDefPUS / SZA->ZA_CONV,4)
			nUsu2PUS := Round(nUsuPUS / SZA->ZA_CONV,4)
		EndIf
	EndIf

Return(Nil)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsSayTot
Fun��o para atualizar Say do total da cota��o.

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsSayTot()

	Local nTotRea := 0
	Local nTotDol := 0
	Local nPosSts := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_STATUS")})
	Local nPosTRe := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1RUSU")})
	Local nPosTDo := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1DUSU")})

	//-- Desconsidera registros cancelados.
	aEval(aDadAux,{|a| iIf(((!a[nPosSts][2]$"C") .And. (!a[Len(a)][2])),(nTotRea += a[nPosTRe][2], nTotDol += a[nPosTDo][2]),Nil)})

	cTotRea := "Total R$: "+Transform(Round(nTotRea,4),PesqPict("SZD","ZD_TO1RUSU"))
	cTotDol := "Total US$: "+Transform(Round(nTotDol,4),PesqPict("SZD","ZD_TO1DUSU"))

	oSayTo1:Refresh()
	oSayTo2:Refresh()

Return(Nil)

//-------------------------------------------------------------------------------------------
/*/{Protheus.doc} FSCrgMnt
Fun��o para carregar tela de manuten��o de itens.

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
@history 23/02/2023, .iNi Lutchen, Comparo custo da cota��o com o custo do item, se o custo 
								   Tiver sido alterado sobreponho o custo na cota��o.
@history 02/03/2023, .iNi Lutchen, Conver��o do custo de acordo com a UM e preencho a variavel 
								   nUsuCstA para compara��o caso a cota��o tenha gravado em outra UM.								  						   
/*/
//-------------------------------------------------------------------------------------------
Static Function FSCrgMnt()
	Local nXi := 0
	Local nRecCus := 0
	Local nUsuCstA := 0 //-- custo auxiliar para compara��o.
	Private lAtuDef := .F.

	//-- Se vazio.
	If Empty(aDadAux)
		Return()
	EndIf

	//-- Se o registro est� deletado n�o faz nada.
	If aDadAux[oBrowse1:nAt][Len(aDadAux[oBrowse1:nAt])][2]
		Return()
	EndIf

	//--Limpa a tela
	FsBtnMnt(1)

	//-- Carrega produto
	cIteAtu := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})][2]
	cCodPrd := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PRODUTO")})][2]
	cPrePrd := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PREPROD")})][2]
	If !Empty(cCodPrd)
		cDscPrd := POSICIONE("SB1",1,xFilial("SB1")+AvKey(cCodPrd,"B1_COD"),"B1_DESC")
		cQtdUM1 := POSICIONE("SB1",1,xFilial("SB1")+AvKey(cCodPrd,"B1_COD"),"B1_UM")
		cQtdUM2 := POSICIONE("SB1",1,xFilial("SB1")+AvKey(cCodPrd,"B1_COD"),"B1_SEGUM")
	Else
		cDscPrd := POSICIONE("SZA",1,xFilial("SZA")+AvKey(cPrePrd,"B1_COD"),"ZA_DESCRIC")
		cQtdUM1 := POSICIONE("SZA",1,xFilial("SZA")+AvKey(cPrePrd,"B1_COD"),"ZA_UM")
		cQtdUM2 := POSICIONE("SZA",1,xFilial("SZA")+AvKey(cPrePrd,"B1_COD"),"ZA_SEGUM")
	EndIf
	nQtdUM1 := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT1")})][2]
	nQtdUM2 := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT2")})][2]
	cUMPad	:= aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_UMPAD")})][2]
	aIteUM	:= {cQtdUM1,cQtdUM2}

	//-- Carrega variaveis de forma��o de pre�o default
	nDefAut := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_AUTDDEF")})][2]
	nDefCst := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSTDEF")})][2]
	nDeDCst := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSDDEF")})][2]
	nDeDFre := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_FREDDEF")})][2]
	nDefMrg := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MARGDEF")})][2]
	nDefCHi := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSDHI")})][2]
	nDefCMi := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSDMI")})][2]
	nDefCom := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSDEF")})][2]
	nDefDes := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PERCDES")})][2]
	nDefFre := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_FRETDEF")})][2]
	nDefPRE := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RDEF")})][2]
	nDefPUS := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DDEF")})][2]
	nDefTRE := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1RDEF")})][2]
	nDefTUS := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1DDEF")})][2]
	nDefMBR := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRDEF")})][2]
	nDefMLQ := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQDEF")})][2]
	nDefPRM := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RDEM")})][2]
	nDeDPRM := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DDEM")})][2]
	nDefMBM := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRDEM")})][2]
	nDeDMBM := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABDDEM")})][2]
	nDefMLM := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQDEM")})][2]
	nDeDMLM := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALDDEM")})][2]
	nDeDMBR := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABDDEF")})][2]
	nDEDMLQ := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALDDEF")})][2]

	//-- Carrega variaveis de forma��o de pre�o de usu�rio
	nUsuAut := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_AUTDUSU")})][2]
	nUsuCst := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSTUSU")})][2]
	nUsuMrg := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MARGUSU")})][2]
	nUsuCHi := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSUHI")})][2]
	nUsuCMi := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSUMI")})][2]
	nUsuCPd := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCOMPAD")})][2]
	nUsuCom := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCMSUSU")})][2]
	nUsuDes := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PERCDES")})][2]
	nUsuFre := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_FRETUSU")})][2]
	nUsuPRE := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RUSU")})][2]
	nUsuPUS := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DUSU")})][2]
	nUsuTRE := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1RUSU")})][2]
	nUsuTUS := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1DUSU")})][2]
	nUsuMBR := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRUSU")})][2]
	nUsuMLQ := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQUSU")})][2]
	nDUsCst := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSTDUS")})][2]
	nDUsFre := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_FRETDUS")})][2]
	nUsuPUS := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DUSU")})][2]
	nUsuTUS := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1DUSU")})][2]
	nUsDMBR := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRDUS")})][2]
	nUsDMLQ := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQDUS")})][2]
	nUsuPRM := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RUSM")})][2]
	nUsDPRM := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DUSM")})][2]
	nUsuMBM := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABRUSM")})][2]
	nUsDMBM := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MABDUSM")})][2]
	nUsuMLM := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALQUSM")})][2]
	nUsDMLM := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MALDUSM")})][2]

	cClcCRN := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CALCMRC")})][2]

	cProcess:= aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCESS")})][2]//--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
	cProcApv:= aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCAPV")})][2]//--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
	cBloDir := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_BLODIR")})][2]//--AS - Aleluia - Bloqueio Diretoria
	cBloDir := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MSGDIR")})][2]//--AS - Aleluia - Msg. de Bloqueio Dir

	nDef2PRE := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RDEF")})][2] //--Pre�o Sugerido Defaut Real UM2
	nUsu2PRE := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSU")})][2] //--Pre�o Sugerido Usuario Real UM2
	nDef2PUS := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DDEF")})][2] //--Pre�o Sugerido Defaut Dolar UM2
	nUsu2PUS := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSU")})][2] //--Pre�o Sugerido Usuario Dolar UM2
	
	nDeDPRM2 := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DDEM")})][2] // -- Preco Minimo Default Dolar UM2
	nUsDPRM2 := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSM")})][2] // -- Preco Minimo Usuario Dolar UM2
	nDefPRM2 := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RDEM")})][2] // -- Preco Minimo Default Real UM2	
	nUsuPRM2 := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSM")})][2] // -- Preco Minimo Usuario Real UM2	

	cCodTabCot := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CODTABC")})][2] // -- Codigo Tabela Comissao
	
	aImposDef	:= {}
	aAdd(aImposDef,aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PPISDEF")})][2])
	aAdd(aImposDef,aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCOFDEF")})][2])
	aAdd(aImposDef,aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PICMDEF")})][2])
	aAdd(aImposDef,aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PIPIDEF")})][2])

	For nXi := 1 To Len(aImposDef)
		nDefImp += aImposDef[nXi]
	Next nXi

	aImposUsu	:= {}
	aAdd(aImposUsu,aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PPISUSU")})][2])
	aAdd(aImposUsu,aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCOFUSU")})][2])
	aAdd(aImposUsu,aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PICMUSU")})][2])
	aAdd(aImposUsu,aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PIPIUSU")})][2])

	For nXi := 1 To Len(aImposUsu)
		nUsuImp += aImposUsu[nXi]
	Next nXi

	//--LTN - 23/02/2023 - Comparando custo definido com o custo da cota��o.	
	If !Empty(nUsuCst)
		
		nUsuCstA := nUsuCst

		nDUsCst := FsCnvDol(nUsuCst)

		If !Empty(cCodPrd)
			nRecCus := FsBscCst(cCodPrd,1)
		ElseIf !Empty(cPrePrd)
			nRecCus := FsBscCst(cPrePrd,2)
		EndIf

		if nUsuCst != nRecCus
			//--LTN - 02/03/2023 - Converto custo de acordo com a UM e preencho a variavel nUsuCstA para compara��o caso a cota��o tenha gravado em outra UM.
			If !Empty(cCodPrd) //--Produto
				SB1->(dbSetOrder(1))
				SB1->(dbSeek(xFilial("SB1")+AvKey(cCodPrd,"B1_COD")))
				If AllTrim(cUMPad) != AllTrim(cQtdUM2) .And. !Empty(cQtdUM2)
					If SB1->B1_TIPCONV == 'D'
						nUsuCstA  := (nUsuCst * SB1->B1_CONV)
					Else
						nUsuCstA  := (nUsuCst / SB1->B1_CONV)
					EndIf
				Else
					
				EndIf
			Else //--Pr� produto
				SZA->(dbSetOrder(1))
				SZA->(dbSeek(xFilial("SZA")+AvKey(cPrePrd,"ZA_CODIGO")))
				If AllTrim(cUMPad) != AllTrim(cQtdUM2) .And. !Empty(cQtdUM2)
					If SZA->ZA_TIPCONV == 'D'
						nUsuCstA  := (nUsuCst * SZA->ZA_CONV)
					Else
						nUsuCstA  := (nUsuCst / SZA->ZA_CONV)
					EndIf			
				EndIf			
			EndIf

			If nRecCus != nUsuCstA
				Aviso("Aten��o","Custo do item mudou! Cota��o ser� recalculada de acordo com novo custo!",{"ok"})
				nUsuCst := nRecCus
				nDefCst := nRecCus 
				nDUsCst := FsCnvDol(nUsuCst)
				lAtuDef := .T.
			EndIf

		EndIf
	EndIf

	lBscImp := .F.

	FsMntIte(aDadIt1[oBrowse1:nAt][1]) //-- Carrega tela de itens

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} FsExeRef
Fun��o para fazer REFRESH em todos objetos.

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
@history 23/02/2023, .iNi Lutchen, Ao criar os campos estavam sendo criados todos com o objeto oGet o que atrapalhava no momento 
								   de dar o refresh nos campos,
								   mudando para oGet1,oGet2,oGet3... para os campos do usu�rio 
								   mudando para oGetD1,oGetD2,oGetD3... para os campos default.
								   Incluindo na fun��o de refresh todos os objetos dos campos.
/*/
//-------------------------------------------------------------------
Static Function FsExeRef()
	Local nXi := 0
	//Local aObjects := { "oSay","oGet","oGetUM","oPan03","oDlg03"}
	//Local aObjects := { "oSay","oGet","oGetUM","oPan03","oDlg03","oGetUsCstR","oGetUsCstD"}
	Local aObjects := { "oSay","oGet","oGetUM","oPan03","oDlg03","oGetUsCstR","oGetUsCstD","oGDefRe","oGDefDo",;
	"oGetD1","oGetD2","oGetD3","oGetD4","oGetD5","oGetD6","oGetD7","oGetD8","oGetD9","oGetD10","oGetD11","oGetD12","oGetD13","oGetD14",;
	"oGetD15","oGetD16","oGetD17","oGetD18","oGetD19","oGetD20","oGetD21","oGetD22","oGetD23",;
	"oGet1","oGet2","oGet3","oGet4","oGet5","oGet6","oGet7","oGet8","oGet9","oGet10","oGet11","oGet12","oGet13","oGet14",;
	"oGet15","oGet16","oGet17","oGet18","oGet19","oGet20","oGet21"}

	For nXi := 1 To Len(aObjects)
		If U_ValAtrib(aObjects[nXi]) <> 'U'
			&(aObjects[nXi]+":Refresh()")
		EndIf
	Next nXi

Return(Nil)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsExcIte
Fun��o para Excluir Item

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsExcIte()

	Local nPosSts := 0
	Local nPosReg := 0
	Local nPosIte := 0
	// Local nQtdIte := Len(aDadIt1)
	Local aHeaderZ0G := {}	// Aleluia
	Local aFields           := {"NOUSER"}	// Aleluia
	Local nX := 1	// Aleluia

	//If (Empty(cCodPrd) .And. Empty(cPrePrd)) .Or. Empty(nQtdUM1) .Or. Empty(cIteAtu)
	//	Alert("A��o n�o permitida. Escolha um item para ser excluido.")
	//	Return()
	//EndIf

	If ALTERA
		If (SZC->ZC_STATUS <> 'I')
			Alert("A��o n�o permitida para o status da cota��o de venda!")
			Return()
		EndIf
	EndIf

	cIteAtu := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})][2]

	nPosIte := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})
	nPosSts := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_STATUS")})
	nPosReg := aScan(aDadAux,{|b| AllTrim(b[nPosIte][2]) == AllTrim(cIteAtu)})

	If !(aDadAux[nPosReg][nPosSts][2] == 'I')
		Alert("A��o n�o permitida para status do item.")
		Return()
	EndIf

	If aDadIt1[nPosReg][Len(aUsados)+2]
		Alert("Item j� deletado.")
		Return()
	EndIf

	If MsgYesNo("Tem certeza que deseja excluir o item "+AllTrim(aDadAux[nPosReg][nPosIte][2])+"?")
		//-- Marco registro como deletado.
		aDadIt1[nPosReg][Len(aUsados)+2] := .T.
		aDadAux[nPosReg][Len(aDadAux[nPosReg])][2] := .T.

		// ->> AS - Aleluia - 050421 - Procura o item no array p�blico e deleta a remessa referente
		If type("aXaColsPublicaTelaCotacaoVenda") <> "U" .AND. ValType( aXaColsPublicaTelaCotacaoVenda ) == "A" .AND. Len(aXaColsPublicaTelaCotacaoVenda) > 0

			// Isso aqui � pra poder usar a fun��o gdFieldGet pra pegar o conte�do dos campos do getdados
			u_zMontaCabecalhoTabelaZ0G( @aHeaderZ0G, @aFields )

			For nX := 1 to Len(aXaColsPublicaTelaCotacaoVenda)
				If Left( gdFieldGet( "Z0G_CHAVE", nX, Nil, aHeaderZ0G, aXaColsPublicaTelaCotacaoVenda ), TAMSX3("ZD_ITEM")[01] ) ==;
						Alltrim( aDadAux[nPosReg][nPosIte][2] )
					// Deleta a remessa relativa ao item
					aXaColsPublicaTelaCotacaoVenda[nX][len(aHeaderZ0G)+1] := .T.
				EndIf
			Next nX

		EndIf
		// <<- AS - Aleluia - 050421 - Procura o item no array p�blico e deleta a remessa referente

		//-- Atualizo o Browse
		oBrowse1:SetArray(aDadIt1)
		oBrowse1:Refresh()
		oDlg02:Refresh()

		//-- Limpo a tela de manuten��o de itens
		//FsBtnMnt(1)

		//-- Atualiza o total da cota��o
		FsSayTot()

		//FsExeRef() //-- Refresh em todos objetos.
		oBrowse1:SetFocus()
	EndIf

Return(Nil)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsCanIte
Fun��o para Cancelar Item

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsCanIte()
	Local nXi := 0
	Local lTodos := .F.

	cIteAtu := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})][2]

	If MsgYesNo("Deseja cancelar todos os itens com status INCLU�DO e RENEGOCIADO?.")
		lTodos := .T.
	ElseIf !MsgYesNo("Deseja cancelar o item "+cIteAtu+"?")
		Return()
	EndIf

	nPosIte := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})
	nPosSts := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_STATUS")})

	If lTodos
		For nXi := 1 To Len(aDadAux)
			If (aDadAux[nXi][nPosSts][2] $ 'I,R') .And. !aDadAux[nXi][Len(aDadAux[nXi])][2]
				aDadIt1[nXi][1] := "C"
				aDadAux[nXi][nPosSts][2] := "C"
			EndIf
		Next nXi
	Else
		nPosReg := aScan(aDadAux,{|b| AllTrim(b[nPosIte][2]) == AllTrim(cIteAtu)})
		If (aDadAux[nPosReg][Len(aDadAux[nPosReg])][2])
			Alert("Item deletado n�o pode ser alterado.")
			Return()
		EndIf
		If !(aDadAux[nPosReg][nPosSts][2] $ 'I,R')
			Alert("A��o n�o permitida para status do item.")
			Return()
		EndIf

		//-- Atualizo o Status.
		aDadIt1[nPosReg][1] := "C"
		aDadAux[nPosReg][nPosSts][2] := "C"
	EndIf

	//-- Atualizo o Browse
	oBrowse1:SetArray(aDadIt1)
	oBrowse1:Refresh()
	oDlg02:Refresh()

	//-- Limpo a tela de manuten��o de itens
	FsBtnMnt(1)

	//-- Atualiza o total da cota��o
	FsSayTot()

	//FsExeRef() //-- Refresh em todos objetos.
	oBrowse1:SetFocus()

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} FsPrdIte
Fun��o para Alterar o status do Item para Perdeu Cota��o

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsPrdIte()
	Local nXi := 0
	Local lTodos := .F.
	Local cObser := ""
	Local cCConc := Space(6)

	cIteAtu := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})][2]

	If MsgYesNo("Deseja alterar o status para PERDEU COTA��O de todos os itens com status INCLU�DO e RENEGOCIADO?.")
		lTodos := .T.
	ElseIf !MsgYesNo("Deseja alterar o status para PERDEU COTA��O no item "+cIteAtu+"?.")
		Return()
	EndIf

	cMotPer := FsTelMot(@cObser,@cCConc)
	If Empty(cMotPer)
		Alert("Obrigat�rio informar o motivo de perda da cota��o.")
		Return()
	EndIf

	nPosMtv := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MOTIVO ")})
	nPosObs := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_OBSERV ")})
	nPosIte := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})
	nPosSts := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_STATUS")})
	nPosCon := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CODCON")})

	If lTodos
		For nXi := 1 To Len(aDadAux)
			If (aDadAux[nXi][nPosSts][2] $ 'I,R') .And. !aDadAux[nXi][Len(aDadAux[nXi])][2]
				aDadIt1[nXi][1] := 'D'
				If aScan(aUsados,{|b| AllTrim(b) == AllTrim("ZD_MOTIVO")}) > 0
					aDadIt1[nXi][aScan(aUsados,{|b| AllTrim(b) == AllTrim("ZD_MOTIVO")})+1] := cMotPer
				EndIf
				If aScan(aUsados,{|b| AllTrim(b) == AllTrim("ZD_OBSERV")}) > 0
					aDadIt1[nXi][aScan(aUsados,{|b| AllTrim(b) == AllTrim("ZD_OBSERV")})+1] := cObser
				EndIf
				If aScan(aUsados,{|b| AllTrim(b) == AllTrim("ZD_CODCON")}) > 0
					aDadIt1[nXi][aScan(aUsados,{|b| AllTrim(b) == AllTrim("ZD_CODCON")})+1] := cCConc
				EndIf
				aDadAux[nXi][nPosSts][2] := 'D'
				aDadAux[nXi][nPosMtv][2] := cMotPer
				aDadAux[nXi][nPosObs][2] := cObser
				aDadAux[nXi][nPosCon][2] := cCConc
			EndIf
		Next nXi
	Else
		nPosReg := aScan(aDadAux,{|b| AllTrim(b[nPosIte][2]) == AllTrim(cIteAtu)})

		If aDadAux[nPosReg][Len(aDadAux[nPosReg])][2]
			Alert("Item deletado n�o pode ser alterado.")
			Return()
		EndIf

		If !(aDadAux[nPosReg][nPosSts][2] $ 'I,R')
			Alert("A��o n�o permitida para status do item.")
			Return()
		EndIf

		//-- Atualizo o Status.
		aDadIt1[nPosReg][1] := 'D'
		If aScan(aUsados,{|b| AllTrim(b) == AllTrim("ZD_MOTIVO")}) > 0
			aDadIt1[nPosReg][aScan(aUsados,{|b| AllTrim(b) == AllTrim("ZD_MOTIVO")})+1] := cMotPer
		EndIf

		If aScan(aUsados,{|b| AllTrim(b) == AllTrim("ZD_OBSERV")}) > 0
			aDadIt1[nPosReg][aScan(aUsados,{|b| AllTrim(b) == AllTrim("ZD_OBSERV")})+1] := cObser
		EndIf

		If aScan(aUsados,{|b| AllTrim(b) == AllTrim("ZD_CODCON")}) > 0
			//aDadIt1[nPosReg][aScan(aUsados,{|b| AllTrim(b) == AllTrim("ZD_OBSERV")})+1] := cCConc
			aDadIt1[nPosReg][aScan(aUsados,{|b| AllTrim(b) == AllTrim("ZD_CODCON")})+1] := cCConc
		EndIf

		aDadAux[nPosReg][nPosSts][2] := 'D'
		aDadAux[nPosReg][nPosMtv][2] := cMotPer
		aDadAux[nPosReg][nPosObs][2] := cObser
		aDadAux[nPosReg][nPosCon][2] := cCConc

	EndIf

	//-- Atualizo o Browse
	oBrowse1:SetArray(aDadIt1)
	oBrowse1:Refresh()
	oDlg02:Refresh()

	//-- Limpo a tela de manuten��o de itens
	FsBtnMnt(1)

	//-- Atualiza o total da cota��o
	FsSayTot()

	//FsExeRef() //-- Refresh em todos objetos.
	oBrowse1:SetFocus()

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} FsTelMot
Fun��o para criar tela para informar motivo de perda da cota��o.

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsTelMot(cObser,cCConc)

	Local oDlgMot := Nil
	Local cCodMot := Space(5)
	Local cDesMot := Space(250)
	Local cConcor := Space(40)
	Local cMotivo := Space(300)
	Local cF3	  := "X5Z0"

	Default cObser := ""

	DEFINE MSDIALOG oDlgMot TITLE "Perdeu Cota��o - Motivo" FROM 000,000 TO 190,420 PIXEL

	@ 05,10 SAY "Codigo: " SIZE 50,10 PIXEL OF oDlgMot
	@ 05,50 MSGET cCodMot SIZE 50,10 PIXEL OF oDlgMot F3 cF3 VALID FsVldMot(@cDesMot,@oDlgMot,cCodMot)

	@ 20,10 SAY "Descri��o: " SIZE 50,10 PIXEL OF oDlgMot
	@ 20,50 MSGET cDesMot SIZE 150,10 PIXEL OF oDlgMot WHEN .F.

	@ 35,10 SAY "Cod Concor.: " SIZE 50,10 PIXEL OF oDlgMot
	@ 35,50 MSGET cCConc SIZE 50,10 PIXEL OF oDlgMot F3 "AC3"

	@ 50,10 SAY "Concorrente: " SIZE 50,10 PIXEL OF oDlgMot
	@ 50,50 MSGET cConcor SIZE 150,10 PIXEL OF oDlgMot WHEN .F.

	@ 65,10 SAY "Observa��o: " SIZE 50,10 PIXEL OF oDlgMot
	@ 65,50 MSGET cMotivo SIZE 150,10 PIXEL OF oDlgMot
	//@ 35,50 GET oMemo VAR cMotivo MEMO SIZE 150,40  OF oDlgMot PIXEL

	oBtnOk	:= TButton():New( 80, 010, "Confirmar",oDlgMot,{|| (cObser:= AllTrim(cMotivo), oDlgMot:End())},40,12,,,.F.,.T.,.F.,,.F.,,,.F. )

	ACTIVATE MSDIALOG oDlgMot CENTERED

Return(cCodMot)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsVldMot
Fun��o preencher a descricao do motivo de perda da cota��o.

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsVldMot(cDesMot,oDlgMot,cCodMot)

	cDesMot := POSICIONE("SX5",1,xFilial("SX5")+"Z0"+cCodMot,"X5_DESCRI")
	oDlgMot:Refresh()

Return(.T.)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsEReIte
Fun��o para Eliminar Residuo do Item

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsEReIte()
	Local nXi := 0
	Local lTodos := .F.

	cIteAtu := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})][2]

	If MsgYesNo("Deseja eliminar res�duo de todos os itens com status PARCIALMENTE ATENDIDOS?.")
		lTodos := .T.
	ElseIf MsgYesNo("Deseja eliminar res�duo de do item "+cIteAtu+"?.")
		Return()
	EndIf

	nPosIte := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})
	nPosSts := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_STATUS")})

	If lTodos
		For nXi := 1 To Len(aDadAux)
			If (aDadAux[nXi][nPosSts][2] $ 'P') .And. !aDadAux[nXi][Len(aDadAux[nXi])][2]
				aDadIt1[nXi][1] := "E"
				aDadAux[nXi][nPosSts][2] := "E"
			EndIf
		Next nXi
	Else
		nPosReg := aScan(aDadAux,{|b| AllTrim(b[nPosIte][2]) == AllTrim(cIteAtu)})

		If aDadAux[nPosReg][Len(aDadAux[nPosReg])][2]
			Alert("Item deletado n�o pode ser alterado.")
			Return()
		EndIf

		If !(aDadAux[nPosReg][nPosSts][2] $ 'P')
			Alert("A��o n�o permitida para status do item.")
			Return()
		EndIf

		//-- Atualizo o Status.
		aDadIt1[nPosReg][1] := "E"
		aDadAux[nPosReg][nPosSts][2] := "E"
	EndIf

	//-- Atualizo o Browse
	oBrowse1:SetArray(aDadIt1)
	oBrowse1:Refresh()
	oDlg02:Refresh()

	//-- Limpo a tela de manuten��o de itens
	FsBtnMnt(1)

	//-- Atualiza o total da cota��o
	FsSayTot()

	//FsExeRef() //-- Refresh em todos objetos.
	oBrowse1:SetFocus()

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} FsSlvOrc
Fun��o para Salvar o Or�amento

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsSlvOrc()
	Local nXz := 0
	Local nFilial := 0     							   // Variavel utilizada para receber a filial
	Local cAuxMem := ''
	Local nXi := 0    //  Declara��o de variaveis locais
	Local nPosIte := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})

	Local nX                := 1
	Local aHeaderZ0G        := {}
	Local aFields			:= {"NOUSER"}


	If INCLUI .Or. ALTERA
		//-- GRAVA OS DADOS DO CABE�ALHO - SZC

		dbSelectArea("SZC")
		nFilial := aScan(dbStruct(), {|x| "_FILIAL" $ x[1]})	//-- Procura no array a filial
		nStatus := aScan(dbStruct(), {|x| "_STATUS" $ x[1]})	//-- Procura no array a filial

		RecLock("SZC",INCLUI)
		For nXi := 1 To FCount()                      //-- For de 1 ateh o numero de campos que sao utilizados na tabela SZC(FCount())
			cAuxMem := Alltrim("M->"+FieldName(nXi))  //-- Armazena o conteudo do campo da tabela em uma variavel auxiliar.
			If U_ValAtrib(cAuxMem) <> "U"
				FieldPut(nXi,&(cAuxMem))                  //-- Grava o conteudo do campo armazenado na auxilar no Banco de Dados.
			EndIf
		Next

		If nFilial > 0                                //-- Se Filial for Maior que Zero, ou seja, se ele localizou no aScan a filial
			FieldPut(nFilial, xFilial("SZC"))         //-- Grava-se o conteudo da filial no registro do campo que estah ativo no FOR
		Endif

		If nStatus > 0                    //-- Se Status for Maior que Zero, ou seja, se ele localizou no aScan o status
			FieldPut(nStatus,FsRetStC())  //-- Grava-se o conteudo do status no registro do campo que estah ativo no FOR
		Endif

		SZC->(MsUnlock())  								  //-- Destrava a tabela da gravacao

		//-- GRAVA DADOS DOS ITENS - SZD
		dbSelectArea("SZD")
		nFilial := aScan(dbStruct(), {|x| "_FILIAL" $ x[1]})	//-- Procura no array a filial

		For nXi := 1 to Len(aDadAux)                  			//-- FOR de 1 ateh a quantidade do numero do aDadAux

			SZD->(dbSetOrder(1))
			SZD->(dbGoTop())
			lAchou := SZD->(dbSeek(xFilial("SZD")+M->ZC_CODIGO+aDadAux[nXi][nPosIte][2]))

			If aDadAux[nXi][Len(aDadAux[nXi])][2] 	//-- Se for registro deletado
				If lAchou							//-- Se achar o registro tem que deletar!!!
					RecLock("SZD",.F.)           //-- Trava a tabela
					dbDelete()
					SZD->(MsUnlock())
				EndIf
				Loop         									//-- Loop da condicao For
			EndIf

			//-- Se achou o registro altera os dados se n�o inclui.
			If lAchou
				RecLock("SZD",.F.)
			Else
				RecLock("SZD",.T.)
			EndIf

			//-- Grava os campos da SZD
			For nXz := 1 to Len(aDadAux[nXi])
				If (nFieldPos := FieldPos(aDadAux[nXi][nXz][1])) > 0
					FieldPut(nFieldPos, aDadAux[nXi][nXz][2])
				Endif
			Next nXz

			//-- Grava o conteudo da filial
			If nFilial > 0
				FieldPut(nFilial, xFilial("SZD"))
			Endif

			SZD->(MsUnlock())

			// ->> AS - Aleluia - Grava os dados da previs�o de remessa do item da cota��o
			If U_ValAtrib("aXaColsPublicaTelaCotacaoVenda") <> "U";
					.AND. valtype(aXaColsPublicaTelaCotacaoVenda) == "A";
					.AND. len(aXaColsPublicaTelaCotacaoVenda) > 0

				// Isso aqui � pra poder usar a fun��o gdFieldGet pra pegar o conte�do dos campos do getdados
				u_zMontaCabecalhoTabelaZ0G( @aHeaderZ0G, @aFields )

				Z0G->( DBSetOrder(1) )      // Z0G_FILIAL+Z0G_CHAVE+Z0G_DOC+Z0G_ITEM

				for nX := 1 to len(aXaColsPublicaTelaCotacaoVenda)

					if ! gdDeleted(nX, aHeaderZ0G, aXaColsPublicaTelaCotacaoVenda)

						lAchou := Z0G->( MsSeek(;
							FWxFilial("Z0G") +;
							avkey( gdFieldGet( "Z0G_CHAVE", nX, Nil, aHeaderZ0G, aXaColsPublicaTelaCotacaoVenda ), "Z0G_CHAVE") +;
							avkey(SZC->ZC_CODIGO, "Z0G_DOC") +;
							gdFieldGet( "Z0G_ITEM", nX, Nil, aHeaderZ0G, aXaColsPublicaTelaCotacaoVenda ) ) )

						Reclock( "Z0G", !lAchou )
						Z0G_FILIAL  := FWxFilial("Z0G")
						Z0G_CHAVE   := gdFieldGet( "Z0G_CHAVE", nX, Nil, aHeaderZ0G, aXaColsPublicaTelaCotacaoVenda )
						Z0G_DOC     := SZC->ZC_CODIGO
						Z0G_ITEM    := gdFieldGet( "Z0G_ITEM", nX, Nil, aHeaderZ0G, aXaColsPublicaTelaCotacaoVenda )
						Z0G_QTDPRE  := gdFieldGet( "Z0G_QTDPRE", nX, Nil, aHeaderZ0G, aXaColsPublicaTelaCotacaoVenda )
						Z0G_PERREM  := gdFieldGet( "Z0G_PERREM", nX, Nil, aHeaderZ0G, aXaColsPublicaTelaCotacaoVenda )
						Z0G_UMPAD  := gdFieldGet( "Z0G_UMPAD", nX, Nil, aHeaderZ0G, aXaColsPublicaTelaCotacaoVenda )
						Z0G_ORIGEM  := "CT"  // Cota��o
						Z0G->( MsUnlock() )

					else
						if Z0G->(MsSeek( FWxFilial("Z0G") +;
										 avkey( gdFieldGet( "Z0G_CHAVE", nX, Nil, aHeaderZ0G, aXaColsPublicaTelaCotacaoVenda ), "Z0G_CHAVE") +;
							             avkey(SZC->ZC_CODIGO, "Z0G_DOC") +;
							             gdFieldGet( "Z0G_ITEM", nX, Nil, aHeaderZ0G, aXaColsPublicaTelaCotacaoVenda ) ))
							if Reclock("Z0G",.F.)
								Z0G->(dbDelete())
								Z0G->(MSUnlock())
							endif	
						endif
					endif

				next nX

				// Anulo a vari�vel publica que foi criada l� no ponto de entrada FT400BAR
				aXaColsPublicaTelaCotacaoVenda := Nil

			EndIf
			// <<- AS - Aleluia - Grava os dados da previs�o de remessa do item da cota��o


			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			//->23/04/2020 - Wemerson Souza - Atualiza Status do Processo de Cota��o do Pr�-produto									 |
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			If !Empty(aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PREPROD")})][2]) .And. !Empty(aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCESS")})][2]) .And. aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCAPV")})][2] <> "S" .And. !(aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_STATUS")})][2] $ ("D|C"))
				FsGrvProc(1, aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCESS")})][2], aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_COTACAO")})][2])
			Elseif !Empty(aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PREPROD")})][2]) .And. !Empty(aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCESS")})][2]) .And. aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCAPV")})][2] == "S"
				FsGrvProc(3, aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCESS")})][2], aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_COTACAO")})][2])
			Elseif !Empty(aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PREPROD")})][2]) .And. !Empty(aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCESS")})][2]) .And. aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCAPV")})][2] <> "S" .AND. aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_STATUS")})][2] == "D"
				FsGrvProc(4, aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCESS")})][2], aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_COTACAO")})][2], aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MOTIVO")})][2], aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CODCON")})][2], aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_OBSERV")})][2] )
			Elseif !Empty(aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PREPROD")})][2]) .And. !Empty(aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCESS")})][2]) .And. aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCAPV")})][2] <> "S" .AND. aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_STATUS")})][2] == "C"
				FsGrvProc(5, aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCESS")})][2], aDadAux[nXi][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_COTACAO")})][2])
			EndIf
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			//<-23/04/2020 - Wemerson Souza - Atualiza Status do Processo de Cota��o do Pr�-produto									 |
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|

		Next nXi
	Elseif EXCLUI

		SZD->(dbSetOrder(1))
		SZD->(dbSeek(xFilial("SZD")+SZC->ZC_CODIGO))
		Do While (SZD->ZD_COTACAO == SZC->ZC_CODIGO) .And. !SZD->(Eof())
			RecLock("SZD",.F.) //-- Trava a tabela
			SZD->(dbDelete())
			SZD->(MsUnlock())
			SZD->(dbSkip())
		EndDo

		// ->> AS - Aleluia - Apaga a al�ada customizada
		Z0E->( dbSetOrder(1) )		// Z0E_FILIAL+Z0E_TIPO+Z0E_DOC+Z0E_ITDOC+Z0E_APROV
		if Z0E->( MsSeek( FWxFilial("Z0E") + "CT" + SZC->ZC_CODIGO ) )
			while ! Z0E->( EOF() ) .AND. FWxFilial("Z0E") + "CT" + SZC->ZC_CODIGO == Z0E->( Z0E_FILIAL + Z0E_TIPO + Z0E_DOC )
				RecLock( "Z0E", .F. )
				Z0E->( dbDelete() )
				Z0E->( MsUnlock() )
				Z0E->( dbSkip() )
			enddo
		endif
		// <<- AS - Aleluia - Apaga a al�ada customizada

		dbSelectArea("SZC")
		RecLock("SZC",.F.) //-- Trava a tabela
		SZC->(dbDelete())
		SZC->(MsUnlock())

	EndIf

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} FsRetStC
Fun��o para avaliar e retornar o status da cota��o.

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsRetStC()

	Local cStatus := ""
	Local nPosSts := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_STATUS")})
	Local nQtdAbr := 0
	Local nQtdPar := 0

	If INCLUI
		cStatus := "I" //-- Se for inclus�o sempre ser� I
	Else

		//-- Desconsidera registros cancelados.
		aEval(aDadAux,{|a| iIf(((a[nPosSts][2]$"I,R") .And. !a[Len(a)][2]),nQtdAbr++,Nil)})
		aEval(aDadAux,{|a| iIf(((a[nPosSts][2]$"P") .And. !a[Len(a)][2]),nQtdPar++,Nil)})

		If nQtdAbr > 0 .And. nQtdPar == 0
			cStatus := SZC->ZC_STATUS //-- Se quantidade de itens em aberto maior que zero e quantidade parcial igual a zero, mant�m o status.
		ElseIf nQtdAbr > 0 .And. nQtdPar > 0
			cStatus := "A" //-- Se quantidade de itens em aberto maior que zero e quantidade parcial maior que zero, atendido parcial.
		ElseIf nQtdAbr == 0 .And. nQtdPar > 0
			cStatus := "S" //-- Se quantidade de itens em aberto igual a zero e quantidade parcial maior que zero, saldo pendente.
		ElseIf nQtdAbr == 0 .And. nQtdPar == 0
			cStatus := "E" //-- Se quantidade de itens em aberto igual a zero e quantidade parcial igual a zero zero, encerrada.
		EndIf

	EndIf

Return(cStatus)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsCarReg
Fun��o para definir carregamento de registros.

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsCarReg(nOpc)

	If lCopia //-- Se for c�pia refaz o calculo do pre�o de venda de todos os itens.
		//-- Carrega itens do grid
		FsCrgCpy(nOpc)
	Else
		//-- Carrega itens do grid
		FsCrgIte(nOpc)
	EndIf

Return(Nil)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsTelPro
Tela para envio de proposta de cota��o

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsTelPro(cStsIte,cCntMa1,cCntMa2,cNomCm1,cNomCm2)

	Local oDlgPro := Nil
	Local aStsIte := {"Todos","Iniciado e Renegociado"}
	Local nOpcao := 0

	Default cStsIte := "Todos"
	Default cCntMa1 := Space(150)
	Default cCntMa2 := Space(150)
	Default cNomCm1 := Space(150)
	Default cNomCm2 := Space(150)

	DEFINE MSDIALOG oDlgPro TITLE "Enviar Proposta de Cota��o" FROM 000,000 TO 160,620 PIXEL

	@ 06,10 SAY "Enviar Itens: " SIZE 50,10 PIXEL OF oDlgPro
	@ 05,50 MSCOMBOBOX oDlgMot VAR cStsIte ITEMS aStsIte SIZE 90,09 PIXEL OF oDlgPro

	@ 21,10 SAY "Comprador: " SIZE 50,10 PIXEL OF oDlgPro
	@ 20,60 MSGET cNomCm1 SIZE 240,10 PIXEL OF oDlgPro

	@ 36,10 SAY "E-mail Comprador: " SIZE 50,10 PIXEL OF oDlgPro
	@ 35,60 MSGET cCntMa1 SIZE 240,10 PIXEL OF oDlgPro

	//@ 51,10 SAY "Comprador 2: " SIZE 50,10 PIXEL OF oDlgPro
	//@ 50,50 MSGET cNomCm2 SIZE 250,10 PIXEL OF oDlgPro

	@ 51,10 SAY "E-mail Comercial: " SIZE 50,10 PIXEL OF oDlgPro
	@ 50,60 MSGET cCntMa2 SIZE 240,10 PIXEL OF oDlgPro

	oBtnImp	:= TButton():New( 66, 010, "Imp. PDF",oDlgPro,{|| iIf(!Empty(cCntMa2),(nOpcao := 1, oDlgPro:End()),Alert("Campo obrigat�rio n�o preenchido!"))},40,12,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnImp	:= TButton():New( 66, 060, "Imp. WORD",oDlgPro,{|| iIf(!Empty(cCntMa2),(nOpcao := 3, oDlgPro:End()),Alert("Campo obrigat�rio n�o preenchido!"))},40,12,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnEma	:= TButton():New( 66, 110, "Enviar E-mail",oDlgPro,{|| iIf(!Empty(cCntMa2),(nOpcao := 2, oDlgPro:End()),Alert("Campo obrigat�rio n�o preenchido!"))},40,12,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnEsc	:= TButton():New( 66, 160, "Cancelar",oDlgPro,{|| (oDlgPro:End()) },40,12,,,.F.,.T.,.F.,,.F.,,,.F. )

	ACTIVATE MSDIALOG oDlgPro CENTERED

Return(nOpcao)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsInvWin
Inverte abertura da janela

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsInvWin(nOpc)

	oLayer:winChgState("Col02","Jan02","Lin02")

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} FClcMGS
Calcula Margem Liquida e Bruta de acordo com par�metros.

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

	If nTipo == 1 //-- Se tipo igual a 1 ent�o calcula Default e Usu�rio
		nTxEnca := (1 - (iIf(M->ZC_ENCARGO>0,M->ZC_ENCARGO,0)/100)) //-- Acha o encargo

		//-- Acha Margem Bruta Default e de Usu�rio
		//-- Form�la: (1 - CUSTO / (PRCVEN - ENCARGOS)) * 100

		//-- Margem Bruta Pre�o Minimo - Default e Usu�rio
		nDefMBM := Round((1 - (nDefCst / (nPreDefMin * nTxEnca))) * 100,3) 
		nDeDMBM := nDefMBM //-- FsCnvDol(nDefMBM)
		nUsuMBM := Round((1 - (nUsuCst / (nPrecUsuMin * nTxEnca))) * 100,3)
		nUsDMBM := nUsuMBM //-- FsCnvDol(nUsuMBM)

		//-- Margem Bruta Pre�o Sugerido - Default e Usu�rio
		nDefMBR := Round((1 - (nDefCst / (nPrecDefSug * nTxEnca))) * 100,3)
		nDeDMBR	:= nDefMBR //-- FsCnvDol(nDefMBR)
		nUsuMBR := Round((1 - (nUsuCst / (nPrecUsuSug * nTxEnca))) * 100,3)
		nUsDMBR := nUsuMBR //-- FsCnvDol(nUsuMBR)

		//-- Acha Margem Liquida Default e de Usu�rio
		//-- Form�la: (1 - CUSTO / ((PRCVEN - ENCARGOS) - FRETE - IMPOSTOS - (DESPESA+COMISSAO))) * 100
		//-- Nova Form�la: (1 - ((CUSTO + IMPOSTOS + FRETE + COMISSAO + DESPESA) / (PRCVEN - ENCARGOS)))

		//-- Margem Liquida Pre�o Minimo - Default e Usu�rio
		nDefMLM := Round((1 - ((nDefCst + nDefFre + ((nPreDefMin * nDefImp)/100) + (nPreDefMin * ((nDefCMi + nDefCHi + nDefDes)/100))) / (nPreDefMin * nTxEnca))) * 100,3)
		nDeDMLM := nDefMLM //-- FsCnvDol(nDefMLM)
		nUsuMLM := Round((1 - ((nUsuCst + nUsuFre + ((nPrecUsuMin * nUsuImp)/100) + (nPrecUsuMin * ((nUsuCMi + nUsuCHi + nDefDes)/100))) / (nPrecUsuMin * nTxEnca))) * 100,3)
		nUsDMLM := nUsuMLM //-- FsCnvDol(nUsuMLM)

		//-- Margem Liquida Pre�o Sugerido - Default e Usu�rio
		nDefMLQ := Round((1 - ((nDefCst + nDefFre + ((nPrecDefSug * nDefImp)/100) + (nPrecDefSug * ((nDefCom + nDefCHi + nDefDes)/100))) / (nPrecDefSug * nTxEnca))) * 100,3)
		nDEDMLQ := nDefMLQ //-- FsCnvDol(nDefMLQ)
		nUsuMLQ := Round((1 - ((nUsuCst + nUsuFre + ((nPrecUsuSug * nUsuImp)/100) + (nPrecUsuSug * ((nUsuCPd + nUsuCHi + nUsuDes)/100))) / (nPrecUsuSug * nTxEnca))) * 100,3)
		nUsDMLQ := nUsuMLQ //-- FsCnvDol(nUsuMLQ)

	ElseIf nTipo == 2 //-- Se tipo igual a 2 ent�o calcula Usu�rio
		nTxEnca := (1 - (iIf(M->ZC_ENCARGO>0,M->ZC_ENCARGO,0)/100)) //-- Acha o encargo

		//-- Acha Margem Bruta Usu�rio
		//-- Form�la: (1 - CUSTO / (PRCVEN - ENCARGOS)) * 100

		//-- Margem Bruta Pre�o Minimo - Usu�rio
		nUsuMBM := Round((1 - (nUsuCst / (nPrecUsuMin * nTxEnca))) * 100,3)
		nUsDMBM := nUsuMBM //-- FsCnvDol(nUsuMBM)

		//-- Margem Bruta Pre�o Sugerido - Usu�rio
		nUsuMBR := Round((1 - (nUsuCst / (nPrecUsuSug * nTxEnca))) * 100,3)
		nUsDMBR := nUsuMBR //-- FsCnvDol(nUsuMBR)

		//-- Acha Margem Liquida Usu�rio
		//-- Form�la: (1 - CUSTO / ((PRCVEN - ENCARGOS) - FRETE - IMPOSTOS - (DESPESA+COMISSAO))) * 100
		//-- Nova Form�la: (1 - ((CUSTO + IMPOSTOS + FRETE + COMISSAO + DESPESA) / (PRCVEN - ENCARGOS)))

		//-- Margem Liquida Pre�o Minimo - Usu�rio
		nUsuMLM := Round((1 - ((nUsuCst + nUsuFre + ((nPrecUsuMin * nUsuImp)/100) + (nPrecUsuMin * ((nUsuCMi + nUsuCHi + nDefDes)/100))) / (nPrecUsuMin * nTxEnca))) * 100,3)
		nUsDMLM := nUsuMLM //-- FsCnvDol(nUsuMLM)

		//-- Margem Liquida Pre�o Sugerido - Usu�rio
		nUsuMLQ := Round((1 - ((nUsuCst + nUsuFre + ((nPrecUsuSug * nUsuImp)/100) + (nPrecUsuSug * ((nUsuCPd + nUsuCHi + nUsuDes)/100))) / (nPrecUsuSug * nTxEnca))) * 100,3)
		nUsDMLQ := nUsuMLQ //-- FsCnvDol(nUsuMLQ)

	ElseIf nTipo == 3 //-- Se tipo igual a 3 ent�o calcula Default
		nTxEnca := (1 - (iIf(M->ZC_ENCARGO>0,M->ZC_ENCARGO,0)/100)) //-- Acha o encargo

		//-- Acha Margem Bruta Default
		//-- Form�la: (1 - CUSTO / (PRCVEN - ENCARGOS)) * 100

		//-- Margem Bruta Pre�o Minimo - Default
		nDefMBM := Round((1 - (nDefCst / (nPreDefMin * nTxEnca))) * 100,3)
		nDeDMBM := nDefMBM //-- FsCnvDol(nDefMBM)

		//-- Margem Bruta Pre�o Sugerido - Default
		nDefMBR := Round((1 - (nDefCst / (nPrecDefSug * nTxEnca))) * 100,3)
		nDeDMBR	:= nDefMBR //-- FsCnvDol(nDefMBR)

		//-- Acha Margem Liquida Default
		//-- Form�la: (1 - CUSTO / ((PRCVEN - ENCARGOS) - FRETE - IMPOSTOS - (DESPESA+COMISSAO))) * 100
		//-- Nova Form�la: (1 - ((CUSTO + IMPOSTOS + FRETE + COMISSAO + DESPESA) / (PRCVEN - ENCARGOS)))

		//-- Margem Liquida Pre�o Minimo - Default
		nDefMLM := Round((1 - ((nDefCst + nDefFre + ((nPreDefMin * nDefImp)/100) + (nPreDefMin * ((nDefCMi + nDefCHi + nDefDes)/100))) / (nPreDefMin * nTxEnca))) * 100,3)
		nDeDMLM := nDefMLM //-- FsCnvDol(nDefMLM)

		//-- Margem Liquida Pre�o Sugerido - Default
		nDefMLQ := Round((1 - ((nDefCst + nDefFre + ((nPrecDefSug * nDefImp)/100) + (nPrecDefSug * ((nDefCom + nDefCHi + nDefDes)/100))) / (nPrecDefSug * nTxEnca))) * 100,3)
		nDEDMLQ := nDefMLQ //-- FsCnvDol(nDefMLQ)
	EndIf

Return()

///-------------------------------------------------------------------
/*/{Protheus.doc} FsMntIte
Tela de Manuten��o de Itens (Inclus�o, Altera��o e Visualiza��o)

@type function
@author		Igor Rabelo
@since		04/06/2018
@version	P11 
@history 27/11/2019, Lucas - MAIS, Ajustes nas coordenadas dos objetos ap�s virada para 12.1.23 pesquisar por "27/11/19" para verificar as linhas alteradas
@history 11/05/2021, Lucas - MAIS, Adicionada chamada via tecla F4, para retornar o saldo do produto
@history 27/09/2022, .iNi Wemerson, Inclus�o de regra consulta do custo pricing/brill para produtos/pre-produtos tipo PA.
@history 23/02/2023, .iNi Lutchen, Ao criar os campos estavam sendo criados todos com o objeto oGet o que atrapalhava no momento de dar o refresh nos campos,
								   mudando para oGet1,oGet2,oGet3... para os campos do usu�rio e mudando para oGetD1, oGetD2, oGetD3... para os campos default.
/*/
//-------------------------------------------------------------------
Static Function FsMntIte(cStaIte)

	//-- Vari�veis Locais
	//-- String
	Local 	cCadastro	:= "Cota��o de Vendas"
	Local	cSubMen		:= ""
	//-- Array
	Local 	aSize 		:= {}
	Local 	aFldEnch 	:= {}
	Local   aButEnc		:= {}
	Local	aClcCRN		:= {"SIM","NAO"}
	//-- Num�rico
	Local 	nTop       	:= oMainWnd:nTop+35
	Local 	nLeft      	:= oMainWnd:nLeft+10
	Local 	nBottom    	:= oMainWnd:nBottom-12
	Local 	nRight     	:= oMainWnd:nRight-10
	Local 	nOpca
	//-- Objeto
	Local	oFont11		:= TFont():New( "MS Sans Serif",0,-11,,.F.,0,,700,.F.,.F.,,,,,, )
	Local	oFont11N	:= TFont():New( "MS Sans Serif",0,-11,,.T.,0,,700,.F.,.F.,,,,,, )
	Local 	oFont13 	:= TFont():New( "MS Sans Serif",0,-13,,.F.,0,,400,.F.,.F.,,,,,, )
	Local 	oFont13N	:= TFont():New( "MS Sans Serif",0,-13,,.T.,0,,700,.F.,.F.,,,,,, )
	Local 	oFont17N	:= TFont():New( "MS Sans Serif",0,-18,,.T.,0,,700,.F.,.F.,,,,,, )
	Local 	oFont19N	:= TFont():New( "MS Sans Serif",0,-19,,.T.,0,,700,.F.,.F.,,,,,, )
	Local 	oFont22N	:= TFont():New( "MS Sans Serif",0,-22,,.T.,0,,700,.F.,.F.,,,,,, )
	Local 	oFont24N	:= TFont():New( "MS Sans Serif",0,-24,,.T.,0,,700,.F.,.F.,,,,,, )
	Local	oLayer 		:= Nil
	Local	nAltTel		:= 0
	Local	nLarTel		:= 0
	//-- Logico
	Local 	lDesabil	:= .F.
	Local   lDesCpoAlter := IIf(cClcCRN == 'SIM',.F.,.T.)

	Private nXOpc := 0
	Private oGetUsCstR	:= Nil
	Private oGetUsCstD	:= Nil
	Default cStaIte		:= ''

	lDesabil := nOpcMnt == 2 .Or. nOpcMnt == 5 .Or. (cStaIte $ 'P/A/D/C/E')

	//-- Recalcula posicao dos objetos
	aSize := MsAdvSize()

	nAltTel := aSize[6] //- (aSize[6]*(0.05)) //-- Reduzir em % a tela na altura
	nLarTel := aSize[5] //- (aSize[5]*(0.05)) //-- Reduzir em % a tela na largura

	//-- Inicio Montagem da tela
	oDlgMnt := MSDialog():New(aSize[7],aSize[1],nAltTel,nLarTel,cCadastro,,,.F.,iIf(lDesabil,Nil,DS_MODALFRAME),,,,oMainWnd,.T.,,,.T.)

	//oDlgMnt:nClrPane 	:= RGB(240,240,240) //-- Define cor da tela.
	//oDlgMnt:lMaximized := .T.   			//-- Ocupa tela inteira
	If !lDesabil
		oDlgMnt:LEscClose 	:= .F.   			//-- Nao Permitir fechar a janela pelo ESC do teclado
	EndIf

	oLayer:= FWLayer():New() 			//-- Cria painel.
	oLayer:Init(oDlgMnt,.F.,.T.) 			//-- Inicializa painel.

	//-- Adiciona 1 Linhas
	oLayer:addLine("Lin01",100,.F.)

	//-- Adiciona as colunas de cada janela.
	oLayer:addCollumn("Col03",100,.F.,"Lin01")

	//-- Cria Janela Manuten��o Itens da Cota��o
	oLayer:addWindow("Col03","Jan01","Manuten��o de Itens",100,.F.,.T.,,"Lin01",)

	//-- Retorna o objeto da Janela Manuten��o Itens da Cota��o
	oDlg03:= oLayer:getWinPanel("Col03","Jan01","Lin01")
	//oLayer:winChgState("Col03","Jan02","Lin02")

	//-- Cria Painel da Janela Manuten��o Itens da Cota��o
	oPan03:= TPanel():New(oDlg03:nTop,oDlg03:nBottom,,oDlg03,,,,,/*RGB(245,245,245)*/,oDlg03:nRight,oDlg03:nLeft,.T.,.T.)
	oPan03:Align := CONTROL_ALIGN_ALLCLIENT

	//-- Cria barra de bot�es na tela de manute��o de itens da cota��o
	oTMenuBar := TMenuBar():New(oPan03)
	oTMenuBar:SetCss("QMenuBar{background-color:#4d6094;color:#ffffff;}")
	oTMenuBar:Align     := CONTROL_ALIGN_TOP
	oTMenuBar:nClrPane  := RGB(77,96,148)
	oTMenuBar:bRClicked := {||}
	//oTMenuBar:SetDefaultUp(.T.) //-- Joga as op��es do menu pra cima

	//-- Cria itens do menu Manut Itens.
	oTMenu1 := TMenu():New(0,0,0,0,.T.,,oTMenuBar)
	oTMenu1:Add(TMenuItem():New(oTMenu1,"Salvar <F5>"    ,,,,{|| ( FsBtnMnt(2))},,"SDUAPPEND",,,,,,,.T.))
	oTMenu1:Add(TMenuItem():New(oTMenu1,"Alt. Imposto <F6>",,,,{|| (FsBtnMnt(6))},,"SIMULACAO",,,,,,,.T.))
	oTMenu1:Add(TMenuItem():New(oTMenu1,"Hist�rico <F7> "   ,,,,{|| (FsBtnMnt(7)) },,"BMPVISUAL",,,,,,,.T.))
	oTMenu1:Add(TMenuItem():New(oTMenu1,"Sair <F8> "   ,,,,{|| (oDlgMnt:End()) },,"FINAL",,,,,,,.T.))
	oTMenuBar:AddItem('Outras A��es', oTMenu1, .T.)

	SetKey(VK_F2,{|| })
	SetKey(VK_F4,{|| FConPrd(cCodPrd)}) // Lucas - MAIS :: 11/05/21 :: Adicionar chamada a tecla F4, Saldo de Produto
	SetKey(VK_F5,{|| (FsBtnMnt(2))}) //-- Salvar - Atalho F5
	SetKey(VK_F6,{|| FsBtnMnt(6)}) //-- Alterar Imposto - Atalho F6
	SetKey(VK_F7,{|| FsBtnMnt(7)}) //-- Hist�rico - Atalho F7
	SetKey(VK_F8,{|| oDlgMnt:End()}) //-- Sair - Atalho F8

	//-- Cordenad. Objetos Vertical
	aPosHei := MsObjGetPos(oPan03:nHeight,11,{{033.0,030.0,;	//-- 1  ,  2   // Lucas - MAIS 27/11/19 Linha anterior : MsObjGetPos(oPan03:nHeight,12,{{030.0,030.0,;
		250.0,220.0,;	//-- 3  ,  4
		020.0,020.0,;	//-- 5  ,  6
		016.0,013.0,;	//-- 7  ,  8   // Lucas - MAIS 27/11/19 Linha anterior : 012.0,013.0,;
		024.0,016.0,;	//-- 9  ,  10  // Lucas - MAIS 27/11/19 Linha anterior : 019.0,012.0,;
		013.0,024.0,;	//-- 11  , 12  // Lucas - MAIS 27/11/19 Linha anterior : 013.0,019.0,;
		008.0,008.0,;    //-- 13  , 14
		016.0,013.0,;    //-- 15  , 16  // Lucas - MAIS 27/11/19 Linha anterior : 012.0,013.0,;
		024.0,008.0,;	//-- 17  , 18  // Lucas - MAIS 27/11/19 Linha anterior : 019.0,008.0,;
		016.0,013.0,;    //-- 19  , 20  // Lucas - MAIS 27/11/19 Linha anterior : 012.0,013.0,;
		024.0,008.0,;	//-- 21  , 22  // Lucas - MAIS 27/11/19 Linha anterior : 019.0,008.0,;
		016.0,013.0,;    //-- 23  , 24  // Lucas - MAIS 27/11/19 Linha anterior : 012.0,013.0,;
		024.0,008.0,;	//-- 25  , 26  // Lucas - MAIS 27/11/19 Linha anterior : 019.0,008.0,;
		040.0,053.0,;	//-- 27  , 28
		066.0,079.0,;	//-- 29  , 30
		092.0,140.0,;	//-- 31  , 32
		153.0,166.0,;	//-- 33  , 34
		179.0,192.0,;	//-- 35  , 36
		205.0,218.0,;    //-- 37  , 38
		016.0,024.0,;	//-- 39  , 40  // Lucas - MAIS 27/11/19 Linha anterior : 012.0,019.0,;
		130.0,245.0,;	//-- 41  , 42
		231.0,104.0,;	//-- 43  , 44
		117.0}})			//-- 45
	//-- Cordenad. Objetos Horizontal
	aPosWid := MsObjGetPos(oPan03:nWidth,1322,{{002.0,165.0,;	//-- 1  ,  2
		160.0,244.6,;	//-- 3  ,  4
		150.0,150.0,;   //-- 5  ,  6
		005.0,070.0,;	//-- 7  ,  8
		005.0,050.0,;	//-- 9  ,  10
		070.0,050.0,;	//-- 11 ,  12
		040.0,040.0,;	//-- 13 ,  14
		095.0,065.0,;	//-- 15 ,  16
		095.0,100.0,;	//-- 17 ,  18
		200.0,065.0,;	//-- 19 ,  20
		200.0,030.0,;	//-- 21 ,  22
		235.0,070.0,;	//-- 23 ,  24
		235.0,030.0,;	//-- 25 ,  26
		009.0,047.0,;	//-- 27 ,  28  // Lucas - MAIS 27/11/19 Linha anterior : 012.0,047.0,;
		050.0,050.0,;	//-- 29 ,  30
		172.0,210.0,;	//-- 31 ,  32  // Lucas - MAIS 27/11/19 Linha anterior : 175.0,210.0,;
		050.0,050.0,;	//-- 33 ,  34
		246.0,324.0,;	//-- 35 ,  36
		249.0,287.0,;   //-- 37 ,  38  // Lucas - MAIS 27/11/19 Linha anterior : 252.0,287.0,;
		030.0,270.0,;	//-- 39 ,  40
		007.0,081.6,;	//-- 41 ,  42
		170.0,320.6,;	//-- 43 ,  44
		083.0,157.6,;	//-- 45 ,  46
		086.0,124.0}})	//-- 47 ,  48  // Lucas - MAIS 27/11/19 Linha anterior : 089.0,124.0}})

	oSay := TSay():New(aPosHei[1,7],aPosWid[1,7],{||"Produto: "},oPan03,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,8],aPosHei[1,8],,,,,,.T.)
	oGet := TGet():New(aPosHei[1,9],aPosWid[1,9],{ | u | If( PCount() == 0, cCodPrd, cCodPrd:= u ) },oPan03,aPosWid[1,13],aPosHei[1,13],,{|| FsVldCmp("ZD_PRODUTO") },,,, .F.,, .T.,, .F.,{|| Empty(cIteAtu) }, .F., .F.,, .F., .F. ,"SB1","cCodPrd")

	oSay := TSay():New(aPosHei[1,10],aPosWid[1,10],{||"Pr�-Produto: "},oPan03,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,11],aPosHei[1,11],,,,,,.T.)
	oGet := TGet():New(aPosHei[1,12],aPosWid[1,12],{ | u | If( PCount() == 0, cPrePrd, cPrePrd:= u ) },oPan03,aPosWid[1,14],aPosHei[1,14],,{|| FsVldCmp("ZD_PREPROD") },,,, .F.,, .T.,, .F.,{|| Empty(cIteAtu) }, .F., .F.,, .F., .F. ,"SZA","cPrePrd")

	oSay := TSay():New(aPosHei[1,15],aPosWid[1,15],{||"Descri��o: "},oPan03,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,16],aPosHei[1,16],,,,,,.T.)
	oGet := TGet():New(aPosHei[1,17],aPosWid[1,17],{ | u | If(	 PCount() == 0, cDscPrd, cDscPrd:= u ) },oPan03,aPosWid[1,18],aPosHei[1,18],,{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .T., .F.,, .F., .F. ,,"cDscPrd")

	oSay := TSay():New(aPosHei[1,39],aPosWid[1,19],{||"Unid. Med. Padr�o: "},oPan03,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,16],aPosHei[1,16],,,,,,.T.)
	oGetUm := TComboBox():New(aPosHei[1,40],aPosWid[1,21],{ | u | If(PCount()>0,cUMPad:=u,cUMPad)},aIteUM,aPosWid[1,39],aPosHei[1,18],oPan03,,{|| FsVldCmp("UMPAD") },{|| FsExeRef()},,,.T.,,,,,,,,,'cUMPad')

	oSay := TSay():New(aPosHei[1,19],aPosWid[1,23],{|| "Qtd UM 1:"},oPan03,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,20],aPosHei[1,20],,,,,,.T.)
	oGet := TGet():New(aPosHei[1,21],aPosWid[1,25],{ | u | If( PCount() == 0, nQtdUM1, nQtdUM1:= u ) },oPan03,aPosWid[1,22],aPosHei[1,22],X3Picture("ZD_QUANT1"),{|| .T.},,,, .F.,, .T.,, .F.,{|| FsDefUM(1)}, .F., .F.,{|| FsVldCmp("ZD_QUANT1")}, .F., .F. ,,"nQtdUM1")

	oSay := TSay():New(aPosHei[1,23],aPosWid[1,40],{|| "Qtd UM 2:"},oPan03,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet := TGet():New(aPosHei[1,25],aPosWid[1,40],{ | u | If( PCount() == 0, nQtdUM2, nQtdUM2:= u ) },oPan03,aPosWid[1,22],aPosHei[1,22],X3Picture("ZD_QUANT2"),{|| .T.},,,, .F.,, .T.,, .F.,{|| FsDefUM(2)}, .F., .F.,{|| FsVldCmp("ZD_QUANT2")}, .F., .F. ,,"nQtdUM2")

	//-- Grupo para Configura��o Default
	oGrpDef	:= TGroup():New(aPosHei[1,1],aPosWid[1,1],aPosHei[1,3],aPosWid[1,3],"Default:",oPan03,,,.T.)

	oSay := TSay():New(aPosHei[1,27],aPosWid[1,27],{|| "Autonomia Desc.:"},oGrpDef,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD1 := TGet():New(aPosHei[1,27],aPosWid[1,28],{ | u | If( PCount() == 0, nDefAut , nDefAut := u ) },oGrpDef,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_AUTDDEF"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDefAut")

	oSay := TSay():New(aPosHei[1,28],aPosWid[1,27],{|| "Margem Corporativa:"},oGrpDef,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD2 := TGet():New(aPosHei[1,28],aPosWid[1,28],{ | u | If( PCount() == 0, nDefMrg , nDefMrg := u ) },oGrpDef,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MARGDEF"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDefMrg")

	oSay := TSay():New(aPosHei[1,29],aPosWid[1,27],{|| "Comiss�o Hierarquia:"},oGrpDef,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD3 := TGet():New(aPosHei[1,29],aPosWid[1,28],{ | u | If( PCount() == 0, nDefCHi , nDefCHi := u ) },oGrpDef,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_PCMSDHI"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDefCHi")

	//-- .iNi Retirado Percentual de Comiss�o Sugerido do C�lculo de Pre�o
	//oSay := TSay():New(aPosHei[1,30],aPosWid[1,27],{|| "Comiss�o RC % Sugerido:"},oGrpDef,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	//-- .iNi Retirado Percentual de Comiss�o Sugerido do C�lculo de Pre�o
	oSay := TSay():New(aPosHei[1,30],aPosWid[1,27],{|| "Comiss�o Padr�o RC %:"},oGrpDef,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD4 := TGet():New(aPosHei[1,30],aPosWid[1,28],{ | u | If( PCount() == 0, nDefCom , nDefCom := u ) },oGrpDef,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_PCMSDEF"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDefCom")


	oSay := TSay():New(aPosHei[1,31],aPosWid[1,27],{|| "Comiss�o RC % Minimo:"},oGrpDef,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD5 := TGet():New(aPosHei[1,31],aPosWid[1,28],{ | u | If( PCount() == 0, nDefCMi , nDefCMi := u ) },oGrpDef,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_PCMSDMI"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDefCMi")

	oSay := TSay():New(aPosHei[1,44],aPosWid[1,27],{|| "Despesas:"},oGrpDef,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD6 := TGet():New(aPosHei[1,44],aPosWid[1,28],{ | u | If( PCount() == 0, nDefDes , nDefDes := u ) },oGrpDef,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MARGDEF"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDefDes")

	oSay := TSay():New(aPosHei[1,45],aPosWid[1,27],{|| "Impostos:"},oGrpDef,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD7 := TGet():New(aPosHei[1,45],aPosWid[1,28],{ | u | If( PCount() == 0, nDefImp, nDefImp:= u ) },oGrpDef,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MARGDEF"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDefImp")

	oGDefRe	:= TGroup():New(aPosHei[1,41],aPosWid[1,41],aPosHei[1,42],aPosWid[1,42],"Real (R$):",oPan03,,,.T.)

	oSay := TSay():New(aPosHei[1,32],aPosWid[1,27],{|| "Custo:"},oGDefRe,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD8 := TGet():New(aPosHei[1,32],aPosWid[1,28],{ | u | If( PCount() == 0, nDefCst , nDefCst := u ) },oGDefRe,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_CUSTDEF"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDefCst")

	oSay := TSay():New(aPosHei[1,33],aPosWid[1,27],{|| "Frete:"},oGDefRe,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD9 := TGet():New(aPosHei[1,33],aPosWid[1,28],{ | u | If( PCount() == 0, nDefFre, nDefFre:= u ) },oGDefRe,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_FRETDEF"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDefFre")

	oSay := TSay():New(aPosHei[1,34],aPosWid[1,27],{|| "Pre�o M�nimo:"},oGDefRe,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD10 := TGet():New(aPosHei[1,34],aPosWid[1,28],{ | u | If( PCount() == 0, iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nDefPRM,nDefPRM2), iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nDefPRM:= u,nDefPRM:= u)) },oGDefRe,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_PV1RDEM"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),"nDefPRM","nDefPRM2"))
		
	oSay := TSay():New(aPosHei[1,35],aPosWid[1,27],{|| "Margem Bruta Prc Min:"},oGDefRe,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD11 := TGet():New(aPosHei[1,35],aPosWid[1,28],{ | u | If( PCount() == 0, nDefMBM, nDefMBM:= u ) },oGDefRe,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MABRDEM"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDefMBM")

	oSay := TSay():New(aPosHei[1,36],aPosWid[1,27],{|| "Margem Liquida Prc Min:"},oGDefRe,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD12 := TGet():New(aPosHei[1,36],aPosWid[1,28],{ | u | If( PCount() == 0, nDefMLM, nDefMLM:= u ) },oGDefRe,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MALQDEM"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDefMLM")
	
	oSay := TSay():New(aPosHei[1,37],aPosWid[1,27],{|| "Pre�o Sugerido:"},oGDefRe,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD13 := TGet():New(aPosHei[1,37],aPosWid[1,28],{ | u | If( PCount() == 0, iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nDefPRE,nDef2PRE), iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nDefPRE := u,nDef2PRE := u)) },oGDefRe,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_PV1RDEF"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),"nDefPRE","nDef2PRE"))

	oSay := TSay():New(aPosHei[1,38],aPosWid[1,27],{|| "Margem Bruta Prc Sug:"},oGDefRe,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD14 := TGet():New(aPosHei[1,38],aPosWid[1,28],{ | u | If( PCount() == 0, nDefMBR, nDefMBR:= u ) },oGDefRe,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MABRDEF"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDefMBR")

	oSay := TSay():New(aPosHei[1,43],aPosWid[1,27],{|| "Margem Liquida Prc Sug:"},oGDefRe,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD15 := TGet():New(aPosHei[1,43],aPosWid[1,28],{ | u | If( PCount() == 0, nDefMLQ, nDefMLQ:= u ) },oGDefRe,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MALQDEF"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDefMLQ")

	oGDefDo	:= TGroup():New(aPosHei[1,41],aPosWid[1,45],aPosHei[1,42],aPosWid[1,46],"Dolar (US$):",oPan03,,,.T.)

	oSay := TSay():New(aPosHei[1,32],aPosWid[1,47],{|| "Custo:"},oGDefDo,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD16 := TGet():New(aPosHei[1,32],aPosWid[1,48],{ | u | If( PCount() == 0, nDeDCst , nDeDCst := u ) },oGDefDo,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_CUSDDEF"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDeDCst")

	oSay := TSay():New(aPosHei[1,33],aPosWid[1,47],{|| "Frete:"},oGDefDo,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD17 := TGet():New(aPosHei[1,33],aPosWid[1,48],{ | u | If( PCount() == 0, nDeDFre, nDeDFre:= u ) },oGDefDo,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_FREDDEF"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDeDFre")

	oSay := TSay():New(aPosHei[1,34],aPosWid[1,47],{|| "Pre�o M�nimo:"},oGDefDo,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD18 := TGet():New(aPosHei[1,34],aPosWid[1,48],{ | u | If( PCount() == 0, iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nDeDPRM,nDeDPRM2), iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nDeDPRM := u ,nDeDPRM2 := u ) ) },oGDefDo,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_PV1DDEM"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),"nDeDPRM","nDeDPRM2") )

	oSay := TSay():New(aPosHei[1,35],aPosWid[1,47],{|| "Margem Bruta Prc Min:"},oGDefDo,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD19 := TGet():New(aPosHei[1,35],aPosWid[1,48],{ | u | If( PCount() == 0, nDeDMBM, nDeDMBM:= u ) },oGDefDo,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MABDDEM"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDeDMBM")

	oSay := TSay():New(aPosHei[1,36],aPosWid[1,47],{|| "Margem Liquida Prc Min:"},oGDefDo,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD20 := TGet():New(aPosHei[1,36],aPosWid[1,48],{ | u | If( PCount() == 0, nDeDMLM, nDeDMLM:= u ) },oGDefDo,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MALDDEM"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDeDMLM")

	oSay := TSay():New(aPosHei[1,37],aPosWid[1,47],{|| "Pre�o Sugerido:"},oGDefDo,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD21 := TGet():New(aPosHei[1,37],aPosWid[1,48],{ | u | If( PCount() == 0, iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nDefPUS,nDef2PUS), iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nDefPUS := u,nDef2PUS := u ) ) },oGDefDo,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_PV1DDEF"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),"nDefPUS","nDef2PUS") )

	oSay := TSay():New(aPosHei[1,38],aPosWid[1,47],{|| "Margem Bruta Prc Sug:"},oGDefDo,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD22 := TGet():New(aPosHei[1,38],aPosWid[1,48],{ | u | If( PCount() == 0, nDeDMBR, nDeDMBR:= u ) },oGDefDo,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MABDDE"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDeDMBR")

	oSay := TSay():New(aPosHei[1,43],aPosWid[1,47],{|| "Margem Liquida Prc Sug:"},oGDefDo,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGetD23 := TGet():New(aPosHei[1,43],aPosWid[1,48],{ | u | If( PCount() == 0, nDEDMLQ, nDEDMLQ:= u ) },oGDefDo,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MALDDEF"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nDEDMLQ")

	//-- Grupo para Configura��o de Usu�rio
	oGrpUsu	:= TGroup():New(aPosHei[1,1],aPosWid[1,2],aPosHei[1,3],aPosWid[1,36],"Usu�rio:",oPan03,,,.T.)

	oSay := TSay():New(aPosHei[1,27],aPosWid[1,31],{|| "Autonomia Desc.:"},oGrpUsu,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet1 := TGet():New(aPosHei[1,27],aPosWid[1,32],{ | u | If( PCount() == 0, nUsuAut , nUsuAut := u ) },oGrpUsu,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_AUTDUSU"),{|| .T.},,,, .F.,, .T.,, .F.,{|| lDesCpoAlter }, .F., .F.,{|| FsVldCmp("GERAL")}, .F., .F. ,,"nUsuAut")
	
	oSay := TSay():New(aPosHei[1,28],aPosWid[1,31],{|| "Margem Corporativa:"},oGrpUsu,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet2 := TGet():New(aPosHei[1,28],aPosWid[1,32],{ | u | If( PCount() == 0, nUsuMrg , nUsuMrg := u ) },oGrpUsu,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MARGUSU"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nUsuMrg")

	oSay := TSay():New(aPosHei[1,29],aPosWid[1,31],{|| "Comiss�o Hierarquia:"},oGrpUsu,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet3 := TGet():New(aPosHei[1,29],aPosWid[1,32],{ | u | If( PCount() == 0, nUsuCHi , nUsuCHi := u ) },oGrpUsu,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_PCMSUHI"),{|| .T.},,,, .F.,, .T.,, .F.,{|| lDesCpoAlter }, .F., .F.,{|| FsVldCmp("GERAL")}, .F., .F. ,,"nUsuCHi")

	//-- .iNi Retirado Percentual de Comiss�o Sugerido do C�lculo de Pre�o
	//oSay := TSay():New(aPosHei[1,30],aPosWid[1,31],{|| "Comiss�o RC % Sugerido:"},oGrpUsu,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	//oGet := TGet():New(aPosHei[1,30],aPosWid[1,32],{ | u | If( PCount() == 0, nUsuCom , nUsuCom := u ) },oGrpUsu,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_PCMSUSU"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .T.}, .F., .F.,{|| FsVldCmp("GERAL")}, .F., .F. ,,"nUsuCom")

	oSay := TSay():New(aPosHei[1,30],aPosWid[1,31],{|| "Comiss�o Padr�o RC %:"},oGrpUsu,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet4 := TGet():New(aPosHei[1,30],aPosWid[1,32],{ | u | If( PCount() == 0, nUsuCPd , nUsuCPd := u ) },oGrpUsu,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_PCOMPAD"),{|| .T.},,,, .F.,, .T.,, .F.,{|| lDesCpoAlter }, .F., .F.,{|| FsVldCmp("GERAL")}, .F., .F. ,,"nUsuCPd")

	oSay := TSay():New(aPosHei[1,31],aPosWid[1,31],{|| "Comiss�o RC % Minimo:"},oGrpUsu,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet5 := TGet():New(aPosHei[1,31],aPosWid[1,32],{ | u | If( PCount() == 0, nUsuCMi , nUsuCMi := u ) },oGrpUsu,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_PCMSUMI"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .T. }, .F., .F.,{|| FsVldCmp("ZD_PCMSUMI") /*FsVldCmp("GERAL")*/}, .F., .F. ,,"nUsuCMi")

	oSay := TSay():New(aPosHei[1,44],aPosWid[1,31],{|| "Despesas:"},oGrpUsu,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet6 := TGet():New(aPosHei[1,44],aPosWid[1,32],{ | u | If( PCount() == 0, nUsuDes , nUsuDes := u ) },oGrpUsu,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MARGUSU"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nUsuDes")

	oSay := TSay():New(aPosHei[1,45],aPosWid[1,31],{|| "Impostos:"},oGrpUsu,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet7 := TGet():New(aPosHei[1,45],aPosWid[1,32],{ | u | If( PCount() == 0, nUsuImp, nUsuImp:= u ) },oGrpUsu,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MARGUSU"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .F.}, .F., .F.,, .F., .F. ,,"nUsuImp")

	oSay := TSay():New(aPosHei[1,27],aPosWid[1,37],{|| "Calc. Comis. RC Neg. %:"},oGrpUsu,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oCombo := TComboBox():New(aPosHei[1,27],aPosWid[1,38],{ | u | If(PCount()>0,cClcCRN:=u,cClcCRN)},aClcCRN,aPosWid[1,39],aPosHei[1,18],oGrpUsu,,{|| lDesCpoAlter := FsDesaAlte(cCodPrd,cPrePrd,cClcCRN) },,,,.T.,,,,{|| FsVldCmp("GERAL")},,,,,"cClcCRN")

	//-- .iNi Mudan�a de posi��o deste campo.
	//oSay := TSay():New(aPosHei[1,30],aPosWid[1,37],{|| "Comiss�o Padr�o RC %:"},oGrpUsu,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	//oGet := TGet():New(aPosHei[1,30],aPosWid[1,38],{ | u | If( PCount() == 0, nUsuCPd , nUsuCPd := u ) },oGrpUsu,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_PCOMPAD"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .T.}, .F., .F.,{|| FsVldCmp("GERAL")}, .F., .F. ,,"nUsuCPd")

	//-- Grupo para Configura��o de Usu�rio - Real (R$)
	oGrpRUs	:= TGroup():New(aPosHei[1,41],aPosWid[1,43],aPosHei[1,42],aPosWid[1,4],"Real (R$):",oPan03,,,.T.)

	oSay := TSay():New(aPosHei[1,32],aPosWid[1,31],{|| "Custo:"},oGrpRUs,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	//oGet := TGet():New(aPosHei[1,32],aPosWid[1,32],{ | u | If( PCount() == 0, nUsuCst , nUsuCst := u ) },oGrpRUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_CUSTUSU"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .T.}, .F., .F.,{|| FsVldCmp("ZD_CUSTUSU")}, .F., .F. ,,"nUsuCst")
	oGetUsCstR := TGet():New(aPosHei[1,32],aPosWid[1,32],{ | u | If( PCount() == 0, nUsuCst , nUsuCst := u ) },oGrpRUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_CUSTUSU"),{|| .T.},,,, .F.,, .T.,, .F.,{|| IIF(lDesUsuCst,.F.,.T.)}, .F., .F.,{|| FsVldCmp("ZD_CUSTUSU")}, .F., .F. ,,"nUsuCst")	

	oSay := TSay():New(aPosHei[1,33],aPosWid[1,31],{|| "Frete:"},oGrpRUs,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet8 := TGet():New(aPosHei[1,33],aPosWid[1,32],{ | u | If( PCount() == 0, nUsuFre, nUsuFre:= u ) },oGrpRUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_FRETUSU"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .T.}, .F., .F.,{|| FsVldCmp("ZD_FRETUSU")}, .F., .F. ,,"nUsuFre")

	oSay := TSay():New(aPosHei[1,34],aPosWid[1,31],{|| "Pre�o M�nimo:"},oGrpRUs,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet9 := TGet():New(aPosHei[1,34],aPosWid[1,32],{ | u | If( PCount() == 0, iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nUsuPRM,nUsuPRM2), iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nUsuPRM:= u,nUsuPRM2:= u)) },oGrpRUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_PV1RUSM"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .T.}, .F., .F.,{|| FsVldCmp("ZD_PV1RUSM")}, .F., .F. ,,iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),"nUsuPRM","nUsuPRM2") )

	oSay := TSay():New(aPosHei[1,35],aPosWid[1,31],{|| "Margem Bruta Prc Min:"},oGrpRUs,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet10 := TGet():New(aPosHei[1,35],aPosWid[1,32],{ | u | If( PCount() == 0, nUsuMBM, nUsuMBM:= u ) },oGrpRUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MABRUSM"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .T.}, .F., .F.,{|| FsVldCmp("ZD_MABRUSM")}, .F., .F. ,,"nUsuMBM")

	oSay := TSay():New(aPosHei[1,36],aPosWid[1,31],{|| "Margem Liquida Prc Min:"},oGrpRUs,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet11 := TGet():New(aPosHei[1,36],aPosWid[1,32],{ | u | If( PCount() == 0, nUsuMLM, nUsuMLM:= u ) },oGrpRUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MALQUSM"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .T.}, .F., .F.,{|| FsVldCmp("ZD_MALQUSM")}, .F., .F. ,,"nUsuMLM")

	oSay := TSay():New(aPosHei[1,37],aPosWid[1,31],{|| "Pre�o Sugerido:"},oGrpRUs,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet12 := TGet():New(aPosHei[1,37],aPosWid[1,32],{ | u | If( PCount() == 0, iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nUsuPRE,nUsu2PRE), iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nUsuPRE:= u,nUsu2PRE:= u) ) },oGrpRUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_PV1RUSU"),{|| .T.},,,, .F.,, .T.,, .F.,{|| lDesCpoAlter }, .F., .F.,{|| FsVldCmp("ZD_PV1RUSU")}, .F., .F. ,,iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),"nUsuPRE","nUsu2PRE") )

	oSay := TSay():New(aPosHei[1,38],aPosWid[1,31],{|| "Margem Bruta Prc Sug:"},oGrpRUs,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet13 := TGet():New(aPosHei[1,38],aPosWid[1,32],{ | u | If( PCount() == 0, nUsuMBR, nUsuMBR:= u ) },oGrpRUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MABRUSU"),{|| .T.},,,, .F.,, .T.,, .F.,{|| lDesCpoAlter}, .F., .F.,{|| FsVldCmp("ZD_MABRUSU")}, .F., .F. ,,"nUsuMBR")

	oSay := TSay():New(aPosHei[1,43],aPosWid[1,31],{|| "Margem Liquida Prc Sug:"},oGrpRUs,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet14 := TGet():New(aPosHei[1,43],aPosWid[1,32],{ | u | If( PCount() == 0, nUsuMLQ, nUsuMLQ:= u ) },oGrpRUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MALQUSU"),{|| .T.},,,, .F.,, .T.,, .F.,{|| lDesCpoAlter }, .F., .F.,{|| FsVldCmp("ZD_MALQUSU")}, .F., .F. ,,"nUsuMLQ")

	//-- Grupo para Configura��o de Usu�rio - Dolar (R$)
	oGrpDUs	:= TGroup():New(aPosHei[1,41],aPosWid[1,35],aPosHei[1,42],aPosWid[1,44],"Dolar (US$):",oPan03,,,.T.)

	oSay := TSay():New(aPosHei[1,32],aPosWid[1,37],{|| "Custo:"},oGrpDUs,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	//oGet := TGet():New(aPosHei[1,32],aPosWid[1,38],{ | u | If( PCount() == 0, nDUsCst , nDUsCst := u ) },oGrpDUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_CUSTDUS"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .T.}, .F., .F.,{|| FsVldCmp("ZD_CUSTDUS")}, .F., .F. ,,"nDUsCst")
	oGetUsCstD  := TGet():New(aPosHei[1,32],aPosWid[1,38],{ | u | If( PCount() == 0, nDUsCst , nDUsCst := u ) },oGrpDUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_CUSTDUS"),{|| .T.},,,, .F.,, .T.,, .F.,{|| IIF(lDesUsuCst,.F.,.T.)}, .F., .F.,{|| FsVldCmp("ZD_CUSTDUS")}, .F., .F. ,,"nDUsCst")

	oSay := TSay():New(aPosHei[1,33],aPosWid[1,37],{|| "Frete:"},oGrpDUs,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet15 := TGet():New(aPosHei[1,33],aPosWid[1,38],{ | u | If( PCount() == 0, nDUsFre, nDUsFre:= u ) },oGrpDUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_FRETDUS"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .T.}, .F., .F.,{|| FsVldCmp("ZD_FRETDUS")}, .F., .F. ,,"nDUsFre")

	oSay := TSay():New(aPosHei[1,34],aPosWid[1,37],{|| "Pre�o M�nimo:"},oGrpDUs,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet16 := TGet():New(aPosHei[1,34],aPosWid[1,38],{ | u | If( PCount() == 0, iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nUsDPRM,nUsDPRM2), iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nUsDPRM:= u,nUsDPRM2:= u)) },oGrpDUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_PV1DUSM"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .T.}, .F., .F.,{|| FsVldCmp("ZD_PV1DUSM")}, .F., .F. ,,iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),"nUsDPRM","nUsDPRM2") )

	oSay := TSay():New(aPosHei[1,35],aPosWid[1,37],{|| "Margem Bruta Prc Min:"},oGrpDUs,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet17 := TGet():New(aPosHei[1,35],aPosWid[1,38],{ | u | If( PCount() == 0, nUsDMBM, nUsDMBM:= u ) },oGrpDUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MABDUSM"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .T.}, .F., .F.,{|| FsVldCmp("ZD_MABDUSM")}, .F., .F. ,,"nUsDMBM")

	oSay := TSay():New(aPosHei[1,36],aPosWid[1,37],{|| "Margem Liquida Prc Min:"},oGrpDUs,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet18 := TGet():New(aPosHei[1,36],aPosWid[1,38],{ | u | If( PCount() == 0, nUsDMLM, nUsDMLM:= u ) },oGrpDUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MALDUSM"),{|| .T.},,,, .F.,, .T.,, .F.,{|| .T.}, .F., .F.,{|| FsVldCmp("ZD_MALDUSM")}, .F., .F. ,,"nUsDMLM")

	oSay := TSay():New(aPosHei[1,37],aPosWid[1,37],{|| "Pre�o Sugerido:"},oGrpDUs,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet19 := TGet():New(aPosHei[1,37],aPosWid[1,38],{ | u | If( PCount() == 0, iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nUsuPUS,nUsu2PUS), iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),nUsuPUS:= u,nUsu2PUS:= u)) },oGrpDUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_PV1DUSU"),{|| .T.},,,, .F.,, .T.,, .F.,{|| lDesCpoAlter }, .F., .F.,{|| FsVldCmp("ZD_PV1DUSU")}, .F., .F. ,,iif(AllTrim(cUMPad) == AllTrim(cQtdUM1),"nUsuPUS","nUsu2PUS") )

	oSay := TSay():New(aPosHei[1,38],aPosWid[1,37],{|| "Margem Bruta Prc Sug:"},oGrpDUs,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet20 := TGet():New(aPosHei[1,38],aPosWid[1,38],{ | u | If( PCount() == 0, nUsDMBR, nUsDMBR:= u ) },oGrpDUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MABRDUS"),{|| .T.},,,, .F.,, .T.,, .F.,{|| lDesCpoAlter }, .F., .F.,{|| FsVldCmp("ZD_MABRDUS")}, .F., .F. ,,"nUsDMBR")

	oSay := TSay():New(aPosHei[1,43],aPosWid[1,37],{|| "Margem Liquida Prc Sug:"},oGrpDUs,,oFont11,.F.,.F.,.F.,.T.,CLR_BLACK,,aPosWid[1,24],aPosHei[1,24],,,,,,.T.)
	oGet21 := TGet():New(aPosHei[1,43],aPosWid[1,38],{ | u | If( PCount() == 0, nUsDMLQ, nUsDMLQ:= u ) },oGrpDUs,aPosWid[1,26],aPosHei[1,26],X3Picture("ZD_MALQDUS"),{|| .T.},,,, .F.,, .T.,, .F.,{|| lDesCpoAlter }, .F., .F.,{|| FsVldCmp("ZD_MALQDUS")}, .F., .F. ,,"nUsDMLQ")

	//-- Se Visualiza��o ou Exclus�o ou Status igual a (Parcialmente Atendido, Atendido, Perdeu Cota��o, Cancelado, Residuo Eliminado) desativa altera��o da tela.
	If lDesabil
		oPan03:Disable()
	EndIf

	ACTIVATE MSDIALOG oDlgMnt CENTERED

	// AS - Aleluia - 040421
	if nXOpc == 1 .And. (nOpcMnt == 4 .Or. nOpcMnt == 3)
		u_ASFATR05(cStaIte)
	endif
	nXOpc := 0

Return(FsClsTel())

//-------------------------------------------------------------------
/*/{Protheus.doc} FsClsTel
Fecha tela e limpa dados.

@type function
@author		Igor Rabelo
@since		04/06/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsClsTel(nOpc)

	SetKey(VK_F5,{|| })
	SetKey(VK_F6,{|| })
	SetKey(VK_F7,{|| })
	SetKey(VK_F8,{|| })
	SetKey(VK_F2,{|| FsBtnMnt(1,'N')}) //-- Novo - Atalho F2

	FsBtnMnt(1)

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} FsDefUM
Define unidade de medida padr�o.

@type function
@author		Igor Rabelo
@since		04/06/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsDefUM(nOpc)

	If AllTrim(cUMPad) == AllTrim(cQtdUM1) .And. !Empty(cQtdUM1)
		If nOpc == 1
			Return(.T.)
		Else
			Return(.F.)
		EndIf
	ElseIf AllTrim(cUMPad) == AllTrim(cQtdUM2) .And. !Empty(cQtdUM2)
		If nOpc == 1
			Return(.F.)
		Else
			Return(.T.)
		EndIf
	EndIf

Return(.F.)

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
/*/{Protheus.doc} FsCnvRea
Converte valor em Dolar para Real

@type function
@author		Igor Rabelo
@since		04/06/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsCnvRea(nVlrDol)

	Local nPrcRea	 := 0
	Local cAliasCota := GetNextAlias()
	Local aStruct	 := {}

	TIVCOTACAO(cAliasCota,@aStruct)
	nFatorCota := (cAliasCota)->M2_MOEDA2
	(cAliasCota)->(dbCloseArea())

	nPrcRea := Round((nVlrDol * nFatorCota),4)

Return(nPrcRea)

//-------------------------------------------------------------------
/*/{Protheus.doc} FsTelHis
Carrega tela de hist�rico para o produto.

@type function
@author		Igor Rabelo
@since		05/07/2019
@version	P12
/*/
//-------------------------------------------------------------------
Static Function FsTelHis()

	Local cQuery 	:= ""
	Local aArrHis	:= {}
	Local oDlgHis
	Local oBoxHis

	If Empty(M->ZC_VEND1)
		Alert("A��o n�o permitida. Escolha um vendedor da cota��o para consulta.")
		Return()
	EndIf

	If Select("QRYTMP")>0
		QRYTMP->(DbCloseArea())
	EndIf

	cQuery := " SELECT ZD_STATUS, ZD_COTACAO, ZD_ITEM, ZD_PRODUTO, ZD_PREPROD, ZD_QUANT1, ZD_QUANT2, ZD_PV1RUSU, ZD_PV1DUSU, "
	cQuery += " (ZD_PPISUSU+ZD_PCOFUSU+ZD_PICMUSU+ZD_PIPIUSU) AS ZD_IMPOSTO, ZD_MABRUSU, ZD_MALQUSU, ZD_PCMSUSU, ZD_FRETUSU, ZD_FRETDUS "
	cQuery += " FROM "+RetSqlName("SZD")+" SZD "
	cQuery += " INNER JOIN "+RetSqlName("SZC")+" SZC "
	cQuery += " 	ON SZD.ZD_FILIAL = SZC.ZC_FILIAL "
	cQuery += " 	AND SZD.ZD_COTACAO = SZC.ZC_CODIGO "
	cQuery += " 	AND SZC.D_E_L_E_T_ <> '*' "
	cQuery += " 	AND SZC.ZC_VEND1 = '"+M->ZC_VEND1+"'"
	cQuery += " WHERE SZD.D_E_L_E_T_ <> '*' "
	cQuery += " 	AND ZD_FILIAL = '"+xFilial("SZD")+"' "
	If !Empty(cCodPrd)
		cQuery += " AND ZD_PRODUTO = '"+cCodPrd+"'"
	ElseIf !Empty(cPrePrd)
		cQuery += " AND ZD_PREPROD = '"+cPrePrd+"'"
	EndIf

	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "QRYTMP", .T., .T.)

	Do While !QRYTMP->(Eof())

		Aadd(aArrHis,{QRYTMP->ZD_STATUS,;
			AllTrim(QRYTMP->ZD_COTACAO),;
			AllTrim(QRYTMP->ZD_ITEM),;
			AllTrim(QRYTMP->ZD_PRODUTO),;
			AllTrim(QRYTMP->ZD_PREPROD),;
			QRYTMP->ZD_PV1RUSU,;
			QRYTMP->ZD_PV1DUSU,;
			QRYTMP->ZD_IMPOSTO,;
			QRYTMP->ZD_MABRUSU,;
			QRYTMP->ZD_MALQUSU,;
			QRYTMP->ZD_PCMSUSU,;
			QRYTMP->ZD_FRETUSU,;
			QRYTMP->ZD_FRETDUS})

		QRYTMP->(dbSkip())
	EndDo

	QRYTMP->(dbCloseArea())

	If Len(aArrHis) > 0
		@ 000,000 To 220,620 Dialog oDlgHis Title "Hist�rico de Cota��o"

		@ 005,005 ListBox oBoxHis Fields Headers ;
			" ","Cotacao","Item","Produto","Pre-Produto","Preco R$","Preco US$","Per. Imposto","Margem R$", "Margem US$", "Per. Comissao", "Frete R$", "Frete US$" ;
			Size 305,085  Pixel Of oDlgHis

		oBoxHis:SetArray(aArrHis)

		oBoxHis:bLine := {|| {fRetLeg(aArrHis[oBoxHis:nAt,1]),;
			aArrHis[oBoxHis:nAt,2],;
			aArrHis[oBoxHis:nAt,3],;
			aArrHis[oBoxHis:nAt,4],;
			aArrHis[oBoxHis:nAt,5],;
			aArrHis[oBoxHis:nAt,6],;
			aArrHis[oBoxHis:nAt,7],;
			aArrHis[oBoxHis:nAt,8],;
			aArrHis[oBoxHis:nAt,9],;
			aArrHis[oBoxHis:nAt,10],;
			aArrHis[oBoxHis:nAt,11],;
			aArrHis[oBoxHis:nAt,12],;
			aArrHis[oBoxHis:nAt,13] }}

		//oBoxHis:bLDblClick := {|| aArrLic[oBoxTit:nAt,1] := !aArrLic[oBoxTit:nAt,1],oBoxTit:Refresh(),oBoxTit:DrawSelect()}

		oBoxHis:Refresh()

		oSButton1     := TButton():New( 95,255	,"Legenda" ,oDlgHis,{|| FsBtnMnt(5) },025,012,,,,.T.,,"",,,,.F. )
		oSButton2     := TButton():New( 95,285	,"Sair"	   ,oDlgHis,{||Close(oDlgHis) },025,012,,,,.T.,,"",,,,.F. )

		Activate Dialog oDlgHis Centered
	Else
		Alert("N�o encontrato hist�rico de cota��o para o item.")
	EndIf

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} FsDefCor
Define legenda dos itens

@type function
@author		Igor Rabelo
@since		16/03/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function fRetLeg(cStatus)

	Local oLegend

	If cStatus == 'I' //-- Incluido
		oLegend := oSVerde
	ElseIf cStatus == 'R' //-- Renegociado
		oLegend := oSAmare
	ElseIf cStatus == 'P' //-- Parcialmente Atendido
		oLegend := oSLaran
	ElseIf cStatus == 'A' //-- Atendido
		oLegend := oSVerme
	ElseIf cStatus == 'D' //-- Perdeu Cota��o
		oLegend := oSMarro
	ElseIf cStatus == 'C' //-- Cancelado
		oLegend := oSPreto
	ElseIf cStatus == 'E' //-- Residuo Eliminado
		oLegend := oSPink
	EndIf

Return oLegend

//-------------------------------------------------------------------
/*/{Protheus.doc} FsBscAut
Busca Autonomia de Desconto Produto ou Pr�-Produto

@type function
@author		Igor Rabelo
@since		12/07/2018
@version	P11
/*/
//-------------------------------------------------------------------
Static Function FsBscAut(cCodigo,nTipo)

	Local nPAutDsc := 0

	If nTipo == 2 //-- Se for para Pr�-Produto, usa produto similar
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
/*/{Protheus.doc} FsProCot
Rotinas do Menu de Manuten��o de Processo de cota��o de venda

@type function
@author		Wemerson Souza
@since		18/04/2020
@version	P12
/*/
//-------------------------------------------------------------------
Static Function FsProCot(nOpcao)

	Local aAreas 	:= {}
	Local nPosProc  := {}
	Local nPosApv	:= {}
	Local cIteAtu	:= {}
	Local nPosIte 	:= {}
	Local nPosReg 	:= {}
	Local cCodPPro	:= {}

	//--Somente se houver itens
	If Len(aDadAux) > 0

		aAreas 	:= {Z03->(GetArea()),GetArea()}
		nPosProc:= aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCESS")})
		nPosApv := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCAPV")})
		cIteAtu := aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})][2]
		nPosIte := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})
		nPosReg := aScan(aDadAux,{|b| AllTrim(b[nPosIte][2]) == AllTrim(cIteAtu)})
		cCodPPro:= aDadAux[oBrowse1:nAt][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PREPROD")})][2]

		If nOpcao == 1
			If !Empty(cCodPPro)
				//--Consulta se Processo est� aprovado
				Z03->(dbSetOrder(2))
				If Z03->(dbSeek(xFilial("Z03")+cCodPPro))
					If Z03->Z03_STATUS == "4"
						If MsgYesNo("Deseja Vincular Processo N� "+Z03->Z03_CODIGO+" ao Pr�-produto "+AllTrim(cCodPPro)+" da Cota��o de Venda?")
							aDadIt1[nPosReg][aScan(aUsados,{|b| AllTrim(b) == AllTrim("ZD_PROCESS")})+1] := Z03->Z03_CODIGO
							aDadAux[nPosReg][nPosProc][2] := Z03->Z03_CODIGO
						EndIf
					Else
						MsgAlert("Status do Processo n�o permite vincular Pr�-produto "+cCodPPro+" a uma cota��o de venda.")
					EndIf
				Else
					MsgAlert("N�o existe Processo relacionado ao Pr�-produto "+cCodPPro+" .")
				EndIf
			Else
				MsgAlert("Item "+cIteAtu+" n�o � pr�-produto.","Aten��o")
			EndIf
		ElseIf nOpcao == 2

			Z03->(dbSetOrder(2))
			If Z03->(dbSeek(xFilial("Z03")+cCodPPro))//--Consulta se Processo est� aprovado
				If Z03->Z03_STATUS == "6"
					If MsgYesNo("Deseja Aprovar Pr�-produto "+AllTrim(cCodPPro)+" da Cota��o de Venda?")
						aDadIt1[nPosReg][aScan(aUsados,{|b| AllTrim(b) == AllTrim("ZD_PROCAPV")})+1] := "S"
						aDadAux[nPosReg][nPosApv][2] := "S"
					EndIf
				Else
					MsgAlert("Processo com status diferente de COTA��O DE VENDA EM ANDAMENTO n�o pode ser Aprovado.","Aten��o")
				EndIf
			Else
				aDadIt1[nPosReg][aScan(aUsados,{|b| AllTrim(b) == AllTrim("ZD_PROCAPV")})+1] := "S"
				aDadAux[nPosReg][nPosApv][2] := "S"
			EndIf
		EndIf

		aEval(aAreas, {|x|RestArea(x)})

		//-- Atualizo o Browse
		oBrowse1:SetArray(aDadIt1)
		oBrowse1:Refresh()
		oDlg02:Refresh()

	EndIf

Return()


//-------------------------------------------------------------------
/*/{Protheus.doc} FsGrvProc
Atualiza��o de status no Processo de cota��o de venda

@type function
@author		Wemerson Souza
@since		23/04/2020
@version	P12

@history 01/07/2020, Dayvid Nogueira, Retirado o e-mial do PCP (Z04_EMLPCP) no envio da Aprova��o da Cota��o.
/*/
//-------------------------------------------------------------------
Static Function FsGrvProc(nOpc, cCodProc,cCodCot, cMotivo, cCodCon, cObs)

	Local aAreas 	:= {Z03->(GetArea()),GetArea()}
	Local cSubject	:= ""
	Local cMsgMail 	:= ""
	Local cTo		:= ""
	Local cJust		:= ""
	Local cDesCon	:= ""
	Local cNomCon	:= ""
	Local cEmlMkt	:= ""
	Local cEmlPCP	:= ""
	Local cEmlNut	:= ""
	Local cEmlSup	:= ""
	Local cEmlReg	:= ""

	Default cCodProc:= ""
	Default cCodCot := ""
	Default cMotivo	:= ""
	Default cCodCon := ""
	Default cObs	:= ""

	Z03->(dbSetOrder(1))

	If nOpc == 1 //--Atualiza status para Processo de cota��o de venda
		If Z03->(dbSeek(xFilial("Z03")+cCodProc))
			If Z03->Z03_STATUS == '4' //--Se status estiver Liberado para precifica��o
				RecLock("Z03",.F.)
				Z03->Z03_STATUS := '5' //--Atuliza para Pr�-produto precificado
				Z03->Z03_USRPRC	:= UsrRetName(__cUserID)
				Z03->Z03_DTPRC 	:= DDATABASE
				Z03->Z03_HRPRC 	:= SubStr(Time(),1,5)
				Z03->Z03_FILCOT := xFilial("SZD")
				Z03->Z03_CODCOT := cCodCot
				Z03->(MsUnlock())
			EndIf
		EndIf
	ElseIf nOpc == 2 //-- Atualiza status do Processo de cota��o de venda
		SZD->(dbSetOrder(1))
		SZD->(dbSeek(xFilial("SZD")+SZC->ZC_CODIGO))
		Do While (SZD->ZD_COTACAO == SZC->ZC_CODIGO) .And. !SZD->(Eof())
			If Z03->(dbSeek(xFilial("Z03")+SZD->ZD_PROCESS))
				If Z03->Z03_STATUS == '5' //--Se status estiver Pr�-produto Precificado
					RecLock("Z03",.F.)
					Z03->Z03_STATUS := '6' //--Atuliza para Cota��o de Venda em Andamento
					Z03->Z03_USENVC	:= UsrRetName(__cUserID)
					Z03->Z03_DTENVC := DDATABASE
					Z03->Z03_HRENVC := SubStr(Time(),1,5)
					Z03->(MsUnlock())
				EndIf
			EndIf
			SZD->(dbSkip())
		EndDo
	ElseIf nOpc == 3 //-- Atualiza status do Processo de cota��o de venda
		If Z03->(dbSeek(xFilial("Z03")+cCodProc))
			If Z03->Z03_STATUS == '6' //--Se status estiver Cota��o de Venda em Andamento
				cSubject	:= "Cota��o de Venda Aprovada"
				cMsgMail 	:= "Cota��o N� "+xFilial("SZD")+"-"+cCodCot+" vinculada ao Processo N� "+cCodProc+" aprovada pelo cliente."
				cEmlNut	:= AllTrim(Posicione("Z04",1,xFilial("Z04")+Z03->Z03_GRPANI,"Z04_EMLNUT"))
				cEmlSup	:= AllTrim(Posicione("Z04",1,xFilial("Z04")+Z03->Z03_GRPANI,"Z04_EMLSUP"))
				cEmlReg	:= AllTrim(Posicione("Z04",1,xFilial("Z04")+Z03->Z03_GRPANI,"Z04_EMLREG"))
				cEmlMkt	:= AllTrim(Posicione("Z04",1,xFilial("Z04")+Z03->Z03_GRPANI,"Z04_EMLMKT"))
				//cEmlPCP	:= AllTrim(Posicione("Z04",1,xFilial("Z04")+Z03->Z03_GRPANI,"Z04_EMLPCP")) //Dayvid Nogueira - 01/07/2020 - Retirado o e-mial do PCP (Z04_EMLPCP) no envio da Aprova��o da Cota��o.
				cTo		:= cEmlNut+";"+cEmlReg+";"+cEmlSup+";"+cEmlMkt//+";"+cEmlPCP
				U_PIFATR03(cSubject, cMsgMail, cTo)
				RecLock("Z03",.F.)
				Z03->Z03_STATUS := '7' //--Atulizo para Cota��o de Venda aprovada
				Z03->Z03_USRACO	:= UsrRetName(__cUserID)
				Z03->Z03_DTACO	:= DDATABASE
				Z03->Z03_HRACO 	:= SubStr(Time(),1,5)
				Z03->(MsUnlock())
			EndIf
		EndIf
	ElseIf nOpc == 4 //--Perda de Cota��o
		If Z03->(dbSeek(xFilial("Z03")+cCodProc))
			If Z03->Z03_STATUS == '6' //--Se status estiver Cota��o de Venda em Andamento
				cSubject	:= "Cota��o de Venda Perdida"
				cMsgMail 	:= "Cota��o N� "+xFilial("SZD")+"-"+cCodCot+" vinculada ao Processo N� "+cCodProc+" foi perdida."
				cTo			:= AllTrim(Posicione("Z04",1,xFilial("Z04")+Z03->Z03_GRPANI,"Z04_EMLNUT"))
				cDesCon		:= Alltrim(Posicione("SX5",1,xFilial("SX5")+PadR("Z0",Tamsx3("X5_TABELA")[1])+PadR(cMotivo,Tamsx3("X5_CHAVE")[1]),"X5_DESCRI"))
				cNomCon		:= Iif(!Empty(cCodCon),"Nome Concorrente:" + Posicione("AC3",1,xFilial("AC3")+cCodCon,"AC3_NOME"),'')
				cJust		:= "Justificativa Perda: " +CRLF+ cDesCon  + CRLF + cNomCon  + CRLF + cObs
				U_PIFATR03(cSubject, cMsgMail, cTo)
				RecLock("Z03",.F.)
				Z03->Z03_STATUS := 'C' //--Atuliza para Perda de Cota��o de Venda
				Z03->Z03_USRPER	:= UsrRetName(__cUserID)
				Z03->Z03_DTPER	:= DDATABASE
				Z03->Z03_HRPER 	:= SubStr(Time(),1,5)
				Z03->Z03_OBSCOM := Z03->Z03_OBSCOM +CRLF+ cJust
				Z03->(MsUnlock())
			EndIf
		EndIf
	ElseIf nOpc == 5 //-- Cancelamento de Cota��o
		If Z03->(dbSeek(xFilial("Z03")+cCodProc))
			If Z03->Z03_STATUS == '6' //--Se status estiver Cota��o de Venda em Andamento
				cSubject	:= "Cota��o de Venda Cencelada"
				cMsgMail 	:= "Cota��o N� "+xFilial("SZD")+"-"+cCodCot+" vinculada ao Processo N� "+cCodProc+" foi cancelada."
				cTo			:= AllTrim(Posicione("Z04",1,xFilial("Z04")+Z03->Z03_GRPANI,"Z04_EMLNUT"))
				U_PIFATR03(cSubject, cMsgMail, cTo)
				RecLock("Z03",.F.)
				Z03->Z03_STATUS := 'D' //--Atuliza para Cota��o de Venda Cancelada
				Z03->Z03_USRCAN	:= UsrRetName(__cUserID)
				Z03->Z03_DTCAN	:= DDATABASE
				Z03->Z03_HRCAN 	:= SubStr(Time(),1,5)
				Z03->(MsUnlock())
			EndIf
		EndIf
	EndIf

	aEval(aAreas, {|x|RestArea(x)})

Return()

//-------------------------------------------------------------------
/*/{Protheus.doc} FConPrd
Fun��o de abertura da tecla F4, para exibir os saldos do produto

@type function
@author		Lucas - MAIS
@since		11/05/21
@version	P12 
/*/
//-------------------------------------------------------------------
Static Function FConPrd(cCodPrd)

Local aAreaB1 := SB1->(GetArea())

If !Empty(cCodPrd)
	SB1->(dbSetOrder(1))
	If SB1->(dbSeek(xFilial("SB1")+cCodPrd))
		MaViewSB2(cCodPrd)
	End If
End If

RestArea(aAreaB1)

Return

/*/{Protheus.doc} telaZ0E
Mostra a tela com os hist�rico de aprova��es
@type function
@version 12
@author Marcos Aleluia
@since 11/05/2021
/*/
User Function telaZ0E()

	Local aButtons  := {}

	Private cBkpcCad := cCadastro

	Static oDlgTelZ0E     := Nil

	cCadastro := "Controle de Aprova��o"

	if select("SM0") == 0
		rpcsettype(3)
		rpcsetenv("01","010085" )
	endif

	DEFINE MSDIALOG oDlgTelZ0E TITLE "Controle Aprova��o" FROM 000, 000  TO 400, 590 COLORS 0, 16777215 PIXEL

	fMSNewGe1()

	EnchoiceBar(oDlgTelZ0E, {|| oDlgTelZ0E:End() }, {|| oDlgTelZ0E:End() },,aButtons)

	ACTIVATE MSDIALOG oDlgTelZ0E CENTERED

	cCadastro := cBkpcCad

Return



/*/{Protheus.doc} fMSNewGe1
Fun��o respons�vel por montar
o grid com os registros da tabela
Z0E - CONTROLE AL�ADA CUSTOMIZADA
@type function
@version 12
@author Marcos Aleluia
@since 20/05/2021
/*/
Static Function fMSNewGe1()
	Local nX            := 0
	Local nLinha		:= 0
	Local aHeaderEx     := {}
	Local aColsEx       := {}
	Local aFieldFill    := {}
	Local aFields       := {"NOUSER"}
	Local aAlterFields  := {}
	Local cItem			:= ""
	Local cSeek := ""

	Static oMSNewGe1    := Nil

	// Get fields from Z0E
	aEval( ApBuildHeader( "Z0E", Nil ), { |x| Aadd( aFields, x[2] ) } )

	aAlterFields := {}//aClone( aFields )

	// Define field properties
	For nX := 1 to Len( aFields )
		If GETSX3CACHE(aFields[nX],"X3_CAMPO") != "" .And. aFields[nX] != "NOUSER"
			Aadd( aHeaderEx, {;
				AllTrim(GETSX3CACHE(aFields[nX],"X3_TITULO")),;
				GETSX3CACHE(aFields[nX],"X3_CAMPO"),;
				GETSX3CACHE(aFields[nX],"X3_PICTURE"),;
				GETSX3CACHE(aFields[nX],"X3_TAMANHO"),;
				GETSX3CACHE(aFields[nX],"X3_DECIMAL"),;
				GETSX3CACHE(aFields[nX],"X3_VALID"),;
				GETSX3CACHE(aFields[nX],"X3_USADO"),;
				GETSX3CACHE(aFields[nX],"X3_TIPO"),;
				GETSX3CACHE(aFields[nX],"X3_F3"),;
				GETSX3CACHE(aFields[nX],"X3_CONTEXT"),;
				GETSX3CACHE(aFields[nX],"X3_CBOX"),;
				GETSX3CACHE(aFields[nX],"X3_RELACAO");
				})
		Endif
	Next nX

	aColsEx := {}

	Z0E->( DbSetorder(1) )	// Z0E_FILIAL+Z0E_TIPO+Z0E_DOC+Z0E_ITDOC+Z0E_APROV

	nLinha := oBrowse1:nAt
	cItem := oBrowse1:aArray[nLinha,02]

	if Z0E->( MsSeek( cSeek := FWxFilial("Z0E") + "CT" + avkey(SZC->ZC_CODIGO, "Z0E_DOC") + cItem ) )

		while ! Z0E->( EOF() ) .AND. cSeek == Z0E->( Z0E_FILIAL+Z0E_TIPO+Z0E_DOC+Z0E_ITDOC )

			aFieldFill := {}

			// Preencha as c�lulas da linha atual do aCols
			for nX := 1 to len(aHeaderEx)
				aAdd( aFieldFill, &( "Z0E->"+aHeaderEx[nX,02] ) )
			next nX

			// Torna a linha do aCols n�o deletada
			Aadd( aFieldFill, .F. )
			Aadd( aColsEx, aFieldFill )

			Z0E->( DbSkip() )

		enddo

	endif

	oMSNewGe1 := MsNewGetDados():New(;
		035,;
		006,;
		180,;
		294,;
		Nil/*GD_INSERT+GD_DELETE+GD_UPDATE*/,;
		"AllwaysTrue",;
		"AllwaysTrue",;
		"+Field1+Field2",;
		aAlterFields,;
		Nil,;
		999,;
		"AllwaysTrue",;
		"",;
		"AllwaysTrue",;
		oDlgTelZ0E,;
		aHeaderEx,;
		aColsEx;
		)

Return(Nil)

/*/{Protheus.doc} zCriaEPopulaVariavelPublica
    Cria e popula vari�vel p�blica
    @type Function
    @author Aleluia
    @since 30/03/2021
    @version 12
/*/
Static Function zCriaEPopulaVariavelPublica()

    Local aRegistro := {}
    Local cSeek     := ""
    Local aArea     := { SZD->( GetArea()), SZC->( GetArea()),Z0G->( GetArea() )  }
    Local cCodCont  := ""

	// ->> AS - Aleluia - 020421
	if type("aXaColsPublicaTelaCotacaoVenda") == "U"
		Public aXaColsPublicaTelaCotacaoVenda := {}
	else
		aXaColsPublicaTelaCotacaoVenda := {}
	endif
	// <<- AS - Aleluia - 020421


    SZD->( DBSetOrder(1) )  // ZD_FILIAL+ZD_COTACAO+ZD_ITEM
    Z0G->( DBSetOrder(1) )  // Z0G_FILIAL+Z0G_CHAVE+Z0G_DOC+Z0G_ITEM    -   Z0G_CHAVE � composto por item(ADB_ITEM) + codigo do produto(ADB_CODPRO) do contrato

    If !INCLUI // Lucas - MAIS :: 02/06/2021 - Criada variavel para receber o codigo do contrato, se for inclusao ou se for outra operacao.. Estava pegando o ADA posicionado durante a inclusao...
        cCodCont := SZC->ZC_CODIGO
    End If

    If SZD->( MsSeek( FWxFilial("SZD")+ cCodCont)) 

        while ! SZD->( EOF() ) .AND.  SZD->( ZD_FILIAL+ZD_COTACAO) == FWxFilial("SZD")+ cCodCont

            If Z0G->( MsSeek( cSeek := ;
                    FWxFilial("Z0G") +;
                    AvKey(AllTrim(SZD->ZD_ITEM)+AllTrim(SZD->ZD_PRODUTO), "Z0G_CHAVE") +;
                    AvKey(cCodCont, "Z0G_DOC");
                    ) )

                While ! Z0G->( EOF() ) .AND. cSeek == Z0G->( Z0G_FILIAL+Z0G_CHAVE+Z0G_DOC )


                    aRegistro := {}

                    AAdd(aRegistro, Z0G->Z0G_ITEM)
                    AAdd(aRegistro, Z0G->Z0G_CHAVE)
                    AAdd(aRegistro, Z0G->Z0G_QTDPRE)
                    AAdd(aRegistro, Z0G->Z0G_QTDREA)
                    AAdd(aRegistro, Z0G->Z0G_PERREM)
					AAdd(aRegistro, Z0G->Z0G_UMPAD)
                    AAdd(aRegistro, .F.)

                    AAdd(aXaColsPublicaTelaCotacaoVenda, aRegistro)

                    Z0G->( dbSkip() )

                Enddo

            EndIf

            SZD->( dbSkip() )

        enddo

    EndIf

    // Restaura a �rea
    aEval( aArea, {|x| RestArea(x) } )

Return(Nil)

/*/{Protheus.doc} FVldPrv
Fun��o para validar as previs�es de remessas.
@type function
@version 1.0  
@author dayvid.nogueira
@since 11/11/2021
@return logical, Retorna Verdadeiro se as remessas foram validadas.
/*/
Static Function FVldPrv

Local lRet    := .T.
Local nX      := 0
Local nY      := 0
Local nPosPrd :=  aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PRODUTO")})
Local nPosIte :=  aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})
Local nPosQtd :=  aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT1")})
Local nPosQtd2 :=  aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT2")})
Local nPosDel :=  aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("DELETE")})
Local nQtdGrd := 0


Local nPosLoc := 0
Local lFalhou := .F.
Local nTotQtd := 0

Local cCodPrd := ""
Local cPrePrd := ""
Local cUMPadrao := ""
Local cQtdUM1 := ""
Local cQtdUM2 := ""
Local nConv := ""
Local cTipConv := ""

// Varrer o acols para avaliar se todos os itens digitados, est�o no array da previs�o de remessa.
For nX := 1 To Len(aDadAux)
    nPosLoc := 0
    If !aDadAux[nX][nPosDel][2]
        nPosLoc := aScan(aXaColsPublicaTelaCotacaoVenda,{|x|AllTrim(x[2])==AllTrim(aDadAux[nX][nPosIte][2])+AllTrim(aDadAux[nX][nPosPrd][2])})
        If nPosLoc == 0
            lFalhou := .T.
        End If
    End If
Next nX


// Situa��o 1 : Nao possui previs�o de remessas...
If lFalhou
	nOpc := AVISO("Aten��o!","N�o foram cadastradas previs�es de remessa! Deseja continuar sem preencher as previs�es de remessa?",{"Sim","N�o"})
	if nOpc == 1
		Return .T.
	Else
		lRet := .F.
	EndIf
//    MsgInfo("N�o foram cadastradas previs�es de remessa! � necessario preencher antes de confirmar!","Aten��o")
//    lRet := .F.
End If

// Situacao 2 : Para cada item do aCols, devo verificar se existem previsoes de venda, e quantidade correspondente
// como valida��o extra.
If lRet
    lFalhou := .F.
    For nX := 1 To Len(aDadAux)
      	If !aDadAux[nX][nPosDel][2]

			//LTN - 17/02/2023 - Tratativa unidade de medida padr�o na tela de previs�o
			cCodPrd := aDadAux[nX][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PRODUTO")})][2]
			cPrePrd := aDadAux[nX][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PREPROD")})][2]
			
			If !Empty(cCodPrd)		
				cQtdUM1 := POSICIONE("SB1",1,xFilial("SB1")+AvKey(cCodPrd,"B1_COD"),"B1_UM")
				cQtdUM2 := POSICIONE("SB1",1,xFilial("SB1")+AvKey(cCodPrd,"B1_COD"),"B1_SEGUM")
				nConv := POSICIONE("SB1",1,xFilial("SB1")+AvKey(cCodPrd,"B1_COD"),"B1_CONV")
				cTipConv := POSICIONE("SB1",1,xFilial("SB1")+AvKey(cCodPrd,"B1_COD"),"B1_TIPCONV")
			Else
				cQtdUM1 := POSICIONE("SZA",1,xFilial("SZA")+AvKey(cPrePrd,"B1_COD"),"ZA_UM")
				cQtdUM2 := POSICIONE("SZA",1,xFilial("SZA")+AvKey(cPrePrd,"B1_COD"),"ZA_SEGUM")
				nConv := POSICIONE("SZA",1,xFilial("SZA")+AvKey(cPrePrd,"B1_COD"),"ZA_CONV")
				cTipConv := POSICIONE("SZA",1,xFilial("SZA")+AvKey(cPrePrd,"B1_COD"),"ZA_TIPCONV")
			EndIf

			nTotQtd := 0
            If !lFalhou
                For nY := 1 To Len(aXaColsPublicaTelaCotacaoVenda)
                        If AllTrim(aXaColsPublicaTelaCotacaoVenda[nY,2]) == AllTrim(aDadAux[nX][nPosIte][2])+AllTrim(aDadAux[nX][nPosPrd][2]) .And. !aXaColsPublicaTelaCotacaoVenda[nY,7]
							cUMPadrao := aXaColsPublicaTelaCotacaoVenda[nY][6]
                            nTotQtd += aXaColsPublicaTelaCotacaoVenda[nY,3]
                        End If
                Next nY

				If cUMPadrao == cQtdUM1
					nQtdGrd := aDadAux[nX][nPosQtd][2]
				ElseIf cUMPadrao == cQtdUM2
					nQtdGrd := aDadAux[nX][nPosQtd2][2]
				EndIf				

                If nTotQtd <> nQtdGrd
                    lFalhou := .T.
					If !Empty(cCodPrd)
                    	MsgInfo("Existem itens com quantidades diferentes entre previs�o de remessa, e a quantidade informada. Verifique!"+CRLF+"Item:"+AllTrim(aDadAux[nX][nPosIte][2])+" Produto:"+AllTrim(aDadAux[nX][nPosPrd][2]),"Aten��o")
					Else
						MsgInfo("Existem itens com quantidades diferentes entre previs�o de remessa, e a quantidade informada. Verifique!"+CRLF+"Item:"+AllTrim(aDadAux[nX][nPosIte][2])+" Pr�-Produto:"+AllTrim(cPrePrd),"Aten��o")
					EndIf
                    lRet := .F.
                    Exit
				Else
					//--LTN - 17/02/2023 - Sempre gravo na primeira unidade de medida.
				    For nY := 1 To Len(aXaColsPublicaTelaCotacaoVenda)
                        If AllTrim(aXaColsPublicaTelaCotacaoVenda[nY,2]) == AllTrim(aDadAux[nX][nPosIte][2])+AllTrim(aDadAux[nX][nPosPrd][2]) .And. !aXaColsPublicaTelaCotacaoVenda[nY,7]
							If cQtdUM1 != cUMPadrao

								If cTipConv == "D" // converto para a primeira unidade de medida, por isso a opera��o � ao contrario.
						    		aXaColsPublicaTelaCotacaoVenda[nY,3] := aXaColsPublicaTelaCotacaoVenda[nY,3] * nConv
								Else
									aXaColsPublicaTelaCotacaoVenda[nY,3] := aXaColsPublicaTelaCotacaoVenda[nY,3] / nConv
								EndIf
								aXaColsPublicaTelaCotacaoVenda[nY,6] := cQtdUM1

							EndIf
                        End If
                	Next nY
                EndIf
				

            End If
        End If
    Next nX
End If

// Situacao 3: Se houverem itens deletados no aCols, devo eliminar do array das previsoes tambem, para evitar de gravar informacoes inconsistentes...
If lRet
    For nX := 1 To Len(aDadAux)
        If aDadAux[nX][nPosDel][2]
            For nY := 1 To Len(aXaColsPublicaTelaPrevisaoRemessa)
                        If AllTrim(aXaColsPublicaTelaPrevisaoRemessa[nY,2]) == AllTrim(aDadAux[nX][nPosIte][2])+AllTrim(aDadAux[nX][nPosPrd][2]) .And. !aXaColsPublicaTelaPrevisaoRemessa[nY,7]
                            aXaColsPublicaTelaPrevisaoRemessa[nY,7] := .T. // Marca como DELETADO do array evitando inconsistencias...
                        End If
            Next nY
        End If
    Next nX
End If


Return lRet
/*/{Protheus.doc} FsDesaAlte
Fun��o para Validar se desabilita campo na tela de manuten��o de item.
@type function
@version 1.0 
@author dayvid.nogueira
@since 11/11/2021
@param cCodPrd, character, Codido Do Produto
@param cPrePrd, character, Codigo Pre-Produto
@param cClcCRN, character, Calculo de Comiss�o Renegociada.
@return logical, Retorna verdadeiro se o campo n�o for desabilitado.
/*/
Static Function FsDesaAlte(cCodPrd,cPrePrd,cClcCRN)

	if !Empty(cCodPrd)
		if cClcCRN == 'SIM' .And. Posicione("SB1",1,xFilial("SB1")+AvKey(cCodPrd,"B1_COD"),"B1_TIPO") <> 'MP'
			FsVldCmp("ZD_CALCMRC")
			return .F.			
		else
			FsVldCmp("ZD_CALCMRC")
			return .T.	
		endif
	endif

	if !Empty(cPrePrd)
		if cClcCRN == 'SIM' .And. Posicione("SB1",1,xFilial("SB1")+AvKey(Posicione("SZA",1,xFilial("SZA")+cPrePrd,"ZA_PRDSIMI"),"B1_COD"),"B1_TIPO") <> 'MP' 
			FsVldCmp("ZD_CALCMRC")
			return .F.			
		else
			FsVldCmp("ZD_CALCMRC")
			return .T.	
		endif	
	endif

return .F.
/*/{Protheus.doc} FsAltAutoDesc
Fun��o para buscar a Autonomia de Desconto de acordo com a Tabela Escalonada de Comiss�o e Desconto.
@type function
@version 1.0 
@author dayvid.nogueira
@since 11/11/2021
@return numerico, Retorna percentual de Autonomia de Desconto.
/*/
static function FsAltAutoDesc()
	Local cQuery := ''
	Local cAliasP15 := GetNextAlias()
	Local nComissAnt := 0
	Local nAutoDesc := 0
	
	cQuery := "SELECT * FROM " + RetSqlName("P15") + " P15 " + CRLF
	cQuery += "WHERE P15_FILIAL = '"+xFilial("P15")+"' " + CRLF
	cQuery += "AND P15_CODIGO = '"+cCodTabCot+"' " + CRLF
	cQuery += "AND P15.D_E_L_E_T_ = ' ' " + CRLF

	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cAliasP15, .T., .T.)

	Do While (cAliasP15)->(!Eof())
		if nUsuCMi == 0 .And. nUsuCMi == (cAliasP15)->P15_FXDE
			nAutoDesc := Round((100 - (cAliasP15)->P15_FXATE) + 1,0)
		elseif nUsuCMi > nComissAnt .And. nUsuCMi <= (cAliasP15)->P15_COMISS
			if (cAliasP15)->P15_FXDE == 0
				 nAutoDesc := Round((100 - (cAliasP15)->P15_FXATE) + 1,0)	
			else
				 nAutoDesc := (100 - (cAliasP15)->P15_FXDE)	
			endif
		endif 
		nComissAnt := (cAliasP15)->P15_COMISS
		(cAliasP15)->(dbSkip())
	EndDo

	(cAliasP15)->(dbCloseArea())

return nAutoDesc

/*/{Protheus.doc} FBscTabComi
Fun��o busca a Tabela de Comiss�o Padr�o das Cota��es, percentual Minimo e Maximo da tabela. 
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
/*/{Protheus.doc} FCarVar
Fun��o que faz o recalculo da tela a partir do gatilho da condi��o
de pagamento

@type function
@author		Lutchen Oliveira
@since		22/02/2023
@version	P12
/*/
//-------------------------------------------------------------------
User Function fRecTel()

Local aAreaX := GetArea()
Local nRet := M->ZC_ENCARGO
Local nX := 0
Local nXi := 0
Local nPosReg := 0
Local cCodPrd := ""
Local cPrePrd := ""
Local cUMPad := ""
Local cQtdUM1 := ""
Local nUsuCst := 0
Local nUsuPRM := 0 //-- Preco Minimo Real UM1
Local nUsDPRM := 0 //-- Preco Minimo Dolar UM1
Local nUsuPRE := 0
Local nUsuPUS := 0
Local nUsuTRE := 0
Local nUsuTUS := 0
Local nFatorConver := 0
Local nPrcRea := 0
Local nPrcDol := 0
Local nQtdUM2 := 0

Local nPProd := 0
Local nPPreP := 0
Local nPUmPad := 0
Local nPCusUs := 0
Local nPv1rus := 0
Local nPv1dus := 0
Local nPv2rus := 0
Local nPv2dus := 0
Local nPUsuPRE := 0
Local nPUsuPUS := 0
Local nPUsuTRE := 0
Local nPUsuTUS := 0
Local nPUsDPRM2 := 0
Local nPUsuPRM2 := 0	
Local nPUsu2PRE := 0
Local nPUsu2PUS := 0

If !Empty(aDadAux)

	Aviso("Aten��o!","Alterada condi��o de pagamento! Recalculo da cota��o ser� realizado!",{"ok"})

	nPProd := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PRODUTO")})
	nPPreP := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PREPROD")})
	nPUmPad := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_UMPAD")})
	nPCusUs := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSTUSU")})
	nPv1rus := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RUSM")})
	nPv1dus := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DUSM")})
	nPv2rus := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSM")})
	nPv2dus := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSM")})
	nPUsuPRE := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1RUSU")})
	nPUsuPUS := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV1DUSU")})
	nPUsuTRE := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1RUSU")})
	nPUsuTUS := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_TO1DUSU")})
	nPUsDPRM2 := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSM")}) 
	nPUsuPRM2 := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSM")}) // -- Preco Minimo Usuario Real UM2	
	nPUsu2PRE := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSU")}) //--Pre�o Sugerido Usuario Real UM2
	nPUsu2PUS := aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSU")}) //--Pre�o Sugerido Usuario Dolar UM2

	For nX := 1 to Len(aDadAux)

		//Carrega vari�veis que sao necess�rias para o recalculo.
		FCarVar(nX)

		cCodPrd := aDadAux[nX][nPProd][2]
		cPrePrd := aDadAux[nX][nPPreP][2]
		cUMPad := aDadAux[nX][nPUmPad][2]
		nUsuCst := aDadAux[nX][nPCusUs][2]
		nQtdUM2 := aDadAux[nX][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT2")})][2]

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
			
			//-- Calcula o Pre�o de Venda Usuario UM1
			CURSORWAIT()
			FsClcPrc(2,@nPrcRea,@nPrcDol,1,nUsuCst)
			CURSORARROW()

			aImposUsu	:= aImpostos
			nImposto := 0
			For nXi := 1 To Len(aImposUsu)
				nImposto += aImpostos[nXi]
			Next nXi
			nUsuImp := nImposto

			nUsuPRM := nPrcRea //-- Preco Minimo Real UM1
			nUsDPRM := nPrcDol //-- Preco Minimo Dolar UM1

			aDadAux[nX][nPv1rus][2] := nUsuPRM
			aDadAux[nX][nPv1dus][2] := nUsDPRM
				
			//-- Calcula o Pre�o de Venda Sugerido Usuario
			CURSORWAIT( )
			FsClcPrc(2,@nPrcRea,@nPrcDol,2,nUsuCst)
			CURSORARROW()

			nUsuPRE := nPrcRea  //--Pre�o Sugerido Real UM1
			nUsuPUS := nPrcDol	//--Pre�o Sugerido Dolar UM1
			nUsuTRE := nQtdUM1 * nUsuPRE
			nUsuTUS := nQtdUM1 * nUsuPUS

			aDadAux[nX][nPUsuPRE][2] := nUsuPRE
			aDadAux[nX][nPUsuPUS][2] := nUsuPUS
			aDadAux[nX][nPUsuTRE][2] := nUsuTRE
			aDadAux[nX][nPUsuTUS][2] := nUsuTUS
						
			If nUsuCst > 0
				//-- Calcula o Pre�o de Venda Usuario UM2
				CURSORWAIT()
				FsClcPrc(3,@nPrcRea,@nPrcDol,1,iif(cUMPad == 'KG',(nUsuCst * nFatorConver),(nUsuCst / nFatorConver)))
				CURSORARROW()

				nUsuPRM2 := nPrcRea //-- Preco Minimo Real UM2
				nUsDPRM2 := nPrcDol //-- Preco Minimo Dolar UM2

				aDadAux[nX][nPUsuPRM2][2] := nUsuPRM2
				aDadAux[nX][nPUsDPRM2][2] := nUsDPRM2

				//-- Calcula o Pre�o de Venda Sugerido UsuarioFsClcPrc
				CURSORWAIT( )
				FsClcPrc(3,@nPrcRea,@nPrcDol,2,iif(cUMPad == 'KG',(nUsuCst * nFatorConver),(nUsuCst / nFatorConver)))
				CURSORARROW()	

				nUsu2PRE := nPrcRea //--Pre�o Sugerido Real UM2
				nUsu2PUS := nPrcDol //--Pre�o Sugerido Dolar UM2

				aDadAux[nX][nPUsu2PRE][2] := nUsu2PRE
				aDadAux[nX][nPUsu2PUS][2] := nUsu2PUS

			Endif

		Else

			//-- Calcula o Pre�o de Venda Usuario UM2
			CURSORWAIT()
			FsClcPrc(2,@nPrcRea,@nPrcDol,1,nUsuCst)
			CURSORARROW()

			aImposUsu := aImpostos
			nImposto := 0
			For nXi := 1 To Len(aImposUsu)
				nImposto += aImpostos[nXi]
			Next nXi
			nUsuImp := nImposto

			nUsuPRM2 := nPrcRea //-- Preco Minimo Real UM2
			nUsDPRM2 := nPrcDol //-- Preco Minimo Dolar UM2

			aDadAux[nX][nPv2rus][2] := nUsuPRM2//-- Preco Minimo Real UM2
			aDadAux[nX][nPv2dus][2] := nUsDPRM2//-- Preco Minimo Dolar UM2

			//-- Calcula o Pre�o de Venda Sugerido Usuario
			CURSORWAIT( )
			FsClcPrc(2,@nPrcRea,@nPrcDol,2,nUsuCst)
			CURSORARROW()

			nUsu2PRE := nPrcRea //--Pre�o Sugerido Real UM2
			nUsu2PUS := nPrcDol //--Pre�o Sugerido Dolar UM2
			nUsuTRE := nQtdUM2 * nUsu2PRE
			nUsuTUS := nQtdUM2 * nUsu2PUS

			aDadAux[nX][nPUsu2PRE][2] := nUsu2PRE
			aDadAux[nX][nPUsu2PUS][2] := nUsu2PUS
			aDadAux[nX][nPUsuTRE][2] := nUsuTRE
			aDadAux[nX][nPUsuTUS][2] := nUsuTUS

			If nUsuCst > 0 
				
				//-- Calcula o Pre�o de Venda Usuario UM1
				CURSORWAIT()
				FsClcPrc(3,@nPrcRea,@nPrcDol,1,iif(cUMPad == 'KG',(nUsuCst * nFatorConver),(nUsuCst / nFatorConver)))
				CURSORARROW()

				nUsuPRM := nPrcRea //-- Preco Minimo Real UM1
				nUsDPRM := nPrcDol //-- Preco Minimo Dolar UM1

				aDadAux[nX][nPv1rus][2] := nUsuPRM
				aDadAux[nX][nPv1dus][2] := nUsDPRM

				//-- Calcula o Pre�o de Venda Sugerido Usuario
				CURSORWAIT( )
				FsClcPrc(3,@nPrcRea,@nPrcDol,2,iif(cUMPad == 'KG',(nUsuCst * nFatorConver),(nUsuCst / nFatorConver)))
				CURSORARROW()

				nUsuPRE := nPrcRea  //--Pre�o Sugerido Real UM1
				nUsuPUS := nPrcDol	//--Pre�o Sugerido Dolar UM1

				aDadAux[nX][nPUsuPRE][2] := nUsuPRE
				aDadAux[nX][nPUsuPUS][2] := nUsuPUS

			Endif
		Endif

		nPosReg := nX

		//-- Incluo o registro no array do grid da tela.
		nXi := 1 //-- Come�a com 1 pois o primeiro registro � o status.
		aEval(aUsados,{|a| cCampo:=a, nXi++, iIf(aScan(aDadAux[nPosReg],{|b| AllTrim(b[1]) == AllTrim(cCampo)})>0,aDadIt1[nPosReg][nXi] := aDadAux[nPosReg][aScan(aDadAux[Len(aDadAux)],{|b| AllTrim(b[1]) == AllTrim(cCampo)})][2],Nil)})

	Next nX

	//-- Atualizo o Browse
	oBrowse1:SetArray(aDadIt1)
	oBrowse1:Refresh()
	oDlg02:Refresh()

	//-- Atualiza o total da cota��o
	FsSayTot()

EndIf

RestArea(aAreax)

Return(nRet)


//-------------------------------------------------------------------
/*/{Protheus.doc} FCarVar
Fun��o que carrega variaveis necess�rias para recalcular tela.

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

	//-- Carrega variaveis de forma��o de pre�o default
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

	//-- Carrega variaveis de forma��o de pre�o de usu�rio
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

	cProcess:= aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCESS")})][2]//--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
	cProcApv:= aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCAPV")})][2]//--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
	cBloDir := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_BLODIR")})][2]//--AS - Aleluia - Bloqueio Diretoria
	cBloDir := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MSGDIR")})][2]//--AS - Aleluia - Msg. de Bloqueio Dir

	nDef2PRE := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RDEF")})][2] //--Pre�o Sugerido Defaut Real UM2
	nUsu2PRE := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSU")})][2] //--Pre�o Sugerido Usuario Real UM2
	nDef2PUS := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DDEF")})][2] //--Pre�o Sugerido Defaut Dolar UM2
	nUsu2PUS := aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSU")})][2] //--Pre�o Sugerido Usuario Dolar UM2
	
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



//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} ExeCotV
Fun��o execauto da cota��o. 
@author		.iNi Sistemas
@since     	27/03/2023
@version  	P.12
@param 		aCabec - Cabe�alho da cota��o.
@param 		aItens - Itens da cota��o
@param 		aCPOS - campos a serem validados no Enchauto
@param 		nOpc - Op��o 3=Incluir; 4=Alterar
@return    	array[1] lErro - Se deu erro ou n�o de execu��o do execauto.
@return    	array[2] cMsgErro - Mensagem de erro caso tenha ocorrido erro de execu��o.
@return    	array[3] oJson1 - Objeto json gerado em caso de sucesso.
@obs        
Altera��es Realizadas desde a Estrutura��o Inicial
------------+-----------------+--------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+--------------------------------------------------------------
/*/
//----------------------------------------------------------------------------------------------
Static Function ExeCotV(aCabec,aItens,aCPOS,nOpc)
    Local cTabela   := "SZC"
	Local nXz 		:= 0
	Local nXi 		:= 0
	Local lAchou	:= .F.
	Local cMsgErro 	:= ""
	Local aRet 		:= {}
	Local nFilial 	:= 0
	Local aDadEAut 	:= {}
	Local nPosIte 	:= 0
	Local cTransact := ""
    Local nRetorno  := 0
	Local lRet 		:= .T.
	Local lErro 	:= .F.
	Local nPDelIt 	:= 0
	Local cStaBlAlt := 'I,P,A,S'	// Status bloqueio de altera��o de cota��o
	Private oJson1 	:= JsonObject():New()
	Private oJsonCot:= JsonObject():New()
	Private oJsonPrd:= JsonObject():New()
	Private lMsErroAuto := .F.
	Private aTELA[0][0],aGETS[0]

    //--Inicializa a transa��o
    Begin Transaction

		//--Valida��o da altera��o/exclus�o, A da fun��o EnchAuto retorna um erro que n�o indica o motivo correto.
		If nOpc == 4 .OR. nOpc == 5

			SZC->(dbSetOrder(1))
			If !SZC->(dbSeek(xFilial("SZC")+ACABEC[aScan(aCabec,{ |x| ALLTRIM(x[1]) == "ZC_CODIGO" })][2]))
				
				cMsgErro += "Cotacao nao encontrada! Filial: "+AllTrim(xFilial("SZC"))+" Cotacao: "+Alltrim(ACABEC[aScan(aCabec,{ |x| ALLTRIM(x[1]) == "ZC_CODIGO" })][2])
				lRet := .F.

			Else

				//--Valida��o de altera��o do registro.
				If nOpc == 4 .And. !(SZC->ZC_STATUS $ cStaBlAlt)
					cMsgErro += "Nao e permitida a altera��o da cota��o para o status atual."
					lRet := .F.
				EndIf

				//--Valida��o de exclus�o do registro.
				If nOpc == 5 .And. !(SZC->ZC_STATUS == 'I') .And. !(SZC->ZC_STATUS == 'B')
					cMsgErro += "Nao e permitida a exclusao da cotacao para o status atual."
					lRet := .F.
				EndIf

			EndIf

		Else
			
			If aScan(aCabec,{ |x| ALLTRIM(x[1]) == "ZC_CODIGO" }) > 0
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
					//--Valida��o dos itens.
					if (nOpc == 4 .And. !Empty(aItens)) .or. nOpc == 3
						aRet :=  FValidIt(aItens,@aDadEAut,nOpc)
					Else
						aRet := {.T.,""} //--Permite altera��o somente do cabe�alho.
					EndIf
				Else
					aRet := {.T.,""} //--Permite exclus�o pois j� passou pela valida��o de exclus�o.
				EndIf

				If aRet[1]

					If nOpc != 5

						//--Aciona a efetiva��o da grava��o do cabe�alho.
						nRetorno := AxIncluiAuto(;
							cTabela,;   // cAlias     - Alias da Tabela
							,;          // cTudoOk    - Opera��o do TudoOk (se usado no EnchAuto n�o precisa usar aqui)
							cTransact,; // cTransact  - Opera��o acionada ap�s a grava��o mas dentro da transa��o
							nOpc,;          // nOpcaoAuto - Opera��o do Menu (3=inclus�o, 4=altera��o, 5=exclus�o)
							SZC->(recno());
						)					

						If !Empty(aItens)
							//--Aciona a efetiva��o da grava��o dos itens.						
							dbSelectArea("SZD")
							nFilial := aScan(dbStruct(), {|x| "_FILIAL" $ x[1]})	//-- Procura no array a filial
							nPDelIt := aScan(aDadEAut[1],{|b| AllTrim(b[1]) == AllTrim("DELETE")}) //--Verifica se � exclus�o de item.

							For nXi := 1 to Len(aDadEAut)                  			//-- FOR de 1 ateh a quantidade do numero do aDadEAut

								nPosIte := aScan(aDadEAut[1],{|b| AllTrim(b[1]) == AllTrim("ZD_ITEM")})

								SZD->(dbSetOrder(1))
								SZD->(dbGoTop())
								lAchou := SZD->(dbSeek(xFilial("SZD")+M->ZC_CODIGO+aDadEAut[nXi][nPosIte][2]))						

								If aDadEAut[nXi][nPDelIt][2] 	//-- Se for registro deletado
									If lAchou					//-- Se achar o registro tem que deletar!!!
										RecLock("SZD",.F.)      //-- Trava a tabela
										dbDelete()
										SZD->(MsUnlock())
									EndIf
									Loop         									//-- Loop da condicao For
								EndIf

								//-- Se achou o registro altera os dados se n�o inclui.
								If lAchou
									RecLock("SZD",.F.)
								Else
									RecLock("SZD",.T.)
								EndIf

								//--Grava os campos da SZD
								For nXz := 1 to Len(aDadEAut[nXi])
									If (nFieldPos := FieldPos(aDadEAut[nXi][nXz][1])) > 0
										FieldPut(nFieldPos, aDadEAut[nXi][nXz][2])
									Endif
								Next nXz

								//--Grava o conteudo da filial
								If nFilial > 0
									FieldPut(nFilial, xFilial("SZD"))
								Endif

								SZD->(MsUnlock())

							Next nXi
						EndIf
					Else

						//--Realiza exclus�o da cota��o.
						SZC->(dbSetOrder(1))
						If SZC->(dbSeek(xFilial("SZC")+M->ZC_CODIGO))	

							RecLock("SZC",.F.)
								SZC->(dbDelete())
							SZC->(MsUnlock())

							SZD->(dbSetOrder(1))
							If SZD->(dbSeek(xFilial("SZD")+M->ZC_CODIGO))	
								While SZD->ZD_FILIAL == xFilial("SZD") .And. SZD->ZD_COTACAO == M->ZC_CODIGO
									RecLock("SZD",.F.)
										SZD->(dbDelete())
									SZD->(MsUnlock())
									SZD->(dbSkip())
								EndDo
							EndIf
						
						EndIf

					EndIf
				Else
					lRet := .F.
					cMsgErro := aRet[2]
				EndIf
			Else            
				//MostraErro()
				lRet := .F.
				cMsgErro := MemoRead(NomeAutoLog())
				Ferase(NomeAutoLog())
				DisarmTransaction()
			EndIf
		EndIf
    End Transaction  

	If lRet
		If nOpc != 5

			SZC->(dbSetOrder(1))
			If SZC->(dbSeek(xFilial("SZC")+M->ZC_CODIGO))

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

					While !SZD->(Eof()) .and. SZD->ZD_FILIAL = SZC->ZC_FILIAL .and. SZD->ZD_COTACAO == SZC->ZC_CODIGO

						oJsonPrd := JsonObject():New()
						oJsonPrd['ZD_ITEM'] 	:= SZD->ZD_ITEM
						oJsonPrd['ZD_PRODUTO'] 	:= SZD->ZD_PRODUTO
						oJsonPrd['ZD_PREPROD'] 	:= SZD->ZD_PREPROD
						oJsonPrd['ZD_QUANT1'] 	:= SZD->ZD_QUANT1
						oJsonPrd['ZD_QUANT2'] 	:= SZD->ZD_QUANT2
						oJsonPrd['ZD_QUANT2'] 	:= SZD->ZD_QUANT2
						oJsonPrd['ZD_CUSTUSU'] 	:= SZD->ZD_CUSTUSU
						oJsonPrd['ZD_MARGUSU'] 	:= SZD->ZD_MARGUSU
						oJsonPrd['ZD_PV1RUSU'] 	:= SZD->ZD_PV1RUSU
						oJsonPrd['ZD_PV2RUSU'] 	:= SZD->ZD_PV2RUSU
						oJsonPrd['ZD_MABRUSU'] 	:= SZD->ZD_MABRUSU
						oJsonPrd['ZD_MALQUSU'] 	:= SZD->ZD_MALQUSU
						oJsonPrd['ZD_CODTABC'] 	:= SZD->ZD_CODTABC
						Aadd(oJsonCot['itens'],oJsonPrd)

						SZD->(dbSkip())
					EndDo
				EndIf

				Aadd(oJson1['conteudo'],oJsonCot)

			EndIf
		Else
			oJson1['status'] 		:= "200"
			oJson1['mensagem'] 		:= "Sucesso na exclusao da cotacao!"	
		EndIf
	Else
		lErro := .T.		
	EndIf

Return({lErro,cMsgErro,oJson1})


//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} FValidIt
Fun��o de valida��o dos itens da cota��o. 
@author		.iNi Sistemas
@since     	27/03/2023
@version  	P.12
@param 		aItens - Itens da cota��o
@param 		aDadEAut - Array que ser� atualizado com as informa��es calculadas.
@param 		nOpc - Op��o 3=Incluir; 4=Alterar
@return    	array[1] lRet - Se apresenta erro ou n�o na valida��o dos itens.
@return    	array[2] cMsgErro - Mensagem de erro caso tenha ocorrido na valida��o dos itens.
@obs        
Altera��es Realizadas desde a Estrutura��o Inicial
------------+-----------------+------------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+------------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
Static Function FValidIt(aItens,aDadEAut,nOpc)

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
LOcal nPDelIt 	:= 0
Local lDelIt    := .F.
Local nX	  	:= 0
Local cMsgErro 	:= ""
Local lRet 		:= .T.
Local cUm1P 	:= "" //-- 1� unidade de medida no cadastro do produto ou pr�-produto
Local cUm2P 	:= "" //-- 2� unidade de medida no cadastro do produto ou pr�-produto

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
//--Num�rico
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
Private cProcess:= CriaVar("ZD_PROCESS")//--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
Private cProcApv:= CriaVar("ZD_PROCAPV")//--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
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
		nPDelIt := aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "D_E_L_E_T_" })

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
		If !Empty(nPDelIt)
			lDelIt := iif(aItens[nX][nPDelIt][2]=='*',.T.,.F.)
		Else
			lDelIt := .F.
		EndIf

		If lDelIt .and. nOpc == 3
			cMsgErro += "Nao e possivel deletar um item de uma cota��o que esta sendo incluida. Verifique o item "+AllTrim(str(nX))+" "+CRLF
			lRet := .F.
		EndIf

		//--N�o valida produtos que est�o sendo deletados.
		If lRet .and. !lDelIt
			If EMPTY(cProd) .AND. Empty(cPrePr)
				cMsgErro += "Obrigatorio informar pre produto ou produto. Verifique o item "+AllTrim(str(nX))+" "+CRLF
				lRet := .F.
			ElseIf !EMPTY(cProd) .AND. !Empty(cPrePr)
				cMsgErro += "Deve ser informado pre-produto ou produto. Nunca os dois juntos. Verifique o item "+AllTrim(str(nX))+" "+CRLF
				lRet := .F.
			ElseIf !Empty(cPrePr)
				//-- Avaliar se pre-produto existe
				SZA->(dbSetOrder(1))
				If SZA->(dbSeek(xFilial("SZA")+AvKey(cPrePr,"ZA_CODIGO")))
					If !(SZA->ZA_UM == 'KG' .Or. SZA->ZA_SEGUM == 'KG')
						cMsgErro += "Nao e permitido cotar pre-produto que a 1� ou 2� unidade de medida n�o seja KG. Verifique o item "+AllTrim(str(nX))+" "+CRLF
						lRet := .F.
					EndIf
				Else
					cMsgErro += "Pre-produto "+AllTrim(cPrePr)+" nao encontrado. Verifique o item "+AllTrim(str(nX))+" "+CRLF
					lRet := .F.
				EndIf
			ElseIf !Empty(cProd)
				//-- Avaliar se produto existe
				SB1->(dbSetOrder(1))
				If SB1->(dbSeek(xFilial("SB1")+AvKey(cProd,"B1_COD")))
					//if !RetCodUsr() $ SuperGetMv("V_USCOTPLI", .F., "000887")
						//Valida se o Produto � customizado ou Materia-Prima
						if !( SB1->B1_ZCTMIZA $ "C/P" .OR. SB1->B1_TIPO == "MP" )						
							cMsgErro += "Nao e permitido produto de linha na cotacao. Verifique o item "+AllTrim(str(nX))+" "+CRLF
							lRet := .F.	
						endif
					//EndIf
				Else
					cMsgErro += "Produto "+AllTrim(cProd)+" nao encontrado. Verifique o item "+AllTrim(str(nX))+" "+CRLF
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
					cMsgErro += "Obrigatorio informar Unidade de Medida. Verifique o item "+AllTrim(str(nX))+" "+CRLF
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

						//--Se unidade de medida enviada for a mesma da 1� unidade de medida obrigat�rio informar quantidade 1.
						If cUm == cUm1P .and. Empty(nQtd1) 
							cMsgErro += "Obrigatorio informar quantidade 1. Verifique o item "+AllTrim(str(nX))+" "+CRLF
							lRet := .F.
						//--Se unidade de medida enviada for a diferente da 1� unidade de medida obrigat�rio informar quantidade 2.
						ElseIf cUm != cUm1P .and. Empty(nQtd2) 
							cMsgErro += "Obrigatorio informar quantidade 2. Verifique o item "+AllTrim(str(nX))+" "+CRLF
							lRet := .F.					
						EndIf

					EndIf

					If lRet 
						If Empty(cCusUsu)
							cMsgErro += "Obrigatorio informar o custo. Verifique o item "+AllTrim(str(nX))+" "+CRLF
							lRet := .F.
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	Next nX

	//--Monta array de grava��o para posteriormente atualizar com os calculos.
	If lRet
		FMonRegIt(aItens,@aDadEAut)
	EndIf

	//--Realiza calculo com base no array dos campos de itens.
	If !Empty(aDadEAut)
		fCalcCot(@aDadEAut,"ZD_PREPROD")
		fCalcCot(@aDadEAut,"ZD_QUANT1")
		fCalcCot(@aDadEAut,"ZD_QUANT2")
		fCalcCot(@aDadEAut,"ZD_CUSTUSU")
	EndIf

	//--Atualiza custo do produto, pr�-produto.
	For nX := 1 to Len(aDadEAut)
		
		cCusUsu := aDadEAut[nX][aScan(aDadEAut[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSTUSU")})][2]
		cProd := aDadEAut[nX][aScan(aDadEAut[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PRODUTO")})][2]
		cPrePr := aDadEAut[nX][aScan(aDadEAut[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PREPROD")})][2]

		If !Empty(cProd)
			fsAtuCus(cProd,1,cCusUsu)
		Else
			fsAtuCus(cPrePr,2,cCusUsu)
		EndIf

	Next nX


Return({lRet,cMsgErro})


//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} FMonRegIt
Fun��o para montar aDadEAut para posteriormente atualiza-lo com os c�lculos.
@author		.iNi Sistemas
@since     	27/03/2023
@version  	P.12
@param 		aItens - Itens da cota��o
@param 		aDadEAut - Array que ser� atualizado com as informa��es calculadas.
@return    	null
@obs        
Altera��es Realizadas desde a Estrutura��o Inicial
------------+-----------------+------------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+------------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
Static Function FMonRegIt(aItens,aDadEAut)
	
/*Local nQtdUm1 	:= 0
Local nQtdUm2 	:= 0
Local nPPrd 	:= 0
Local nPPrePr 	:= 0
Local nPUm 		:= 0
Local nPQtd1 	:= 0
Local nPQtd2 	:= 0
Local nPCusUs 	:= 0
Local nPDelIt	:= 0*/
Local lDelIt    := .F.
Local nX 		:= 0

Local aFields := {}
Local nZ := 0

For nX := 1 to Len(aItens)

	/*nPPrd 	:= aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_PRODUTO" })
	nPPrePr := aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_PREPROD" })
	nPUm 	:= aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_UMPAD" })
	nPQtd1 	:= aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_QUANT1" })
	nPQtd2 	:= aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_QUANT2" })
	nPCusUs := aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "ZD_CUSTUSU" })*/
	nPDelIt := aScan(aItens[nX],{ |x| ALLTRIM(x[1]) == "D_E_L_E_T_" })

	/*If !Empty(nPPrd)
		cCodPrd := aItens[nX][nPPrd][2]
	EndIf
	if !Empty(nPPrePr)
		cPrePrd := aItens[nX][nPPrePr][2]
	EndIf
	cUMPad  := aItens[nX][nPUm][2]
	IF !Empty(nPQtd1)
		nQtdUm1 := Val(aItens[nX][nPQtd1][2])
	EndIf
	If !Empty(nPQtd2)
		nQtdUm2 := Val(aItens[nX][nPQtd2][2])
	EndIf
	nUsuCst := Val(aItens[nX][nPCusUs][2])*/


	If !Empty(nPDelIt)
		lDelIt := iif(aItens[nX][nPDelIt][2]=='*',.T.,.F.)
	Else
		lDelIt := .F.
	EndIf
	

	aFields := FWSX3Util():GetAllFields( "SZD" , .F. ) 	
	aadd( aDadEAut,{})
	For nZ := 1 To len(aFields)
		If aFields[nz] == "ZD_ITEM" //--Se for item incrementa com o nX
			aadd( aDadEAut[nX] ,{aFields[nz],strzero(nx,3)})
		ElseIf aFields[nz] == "ZD_COTACAO" 
			aadd( aDadEAut[nX] ,{aFields[nz], M->ZC_CODIGO})
		ElseIf aFields[nz] == "ZD_FILIAL" //--Se Filial n inclui no array... pois pega automatico na grava��o.
		ElseIf aFields[nz] == "ZD_STATUS"
			aadd( aDadEAut[nX] , IIF(aScan(aItens[nX],{|x|ALLTRIM(x[1])==aFields[nz]})> 0 , { aFields[nz],aItens[nX][aScan(aItens[nX],{|x|ALLTRIM(x[1])==aFields[nz]})][2] } , {aFields[nz] , cStatus}))
		Else		
			aadd( aDadEAut[nX] , IIF(aScan(aItens[nX],{|x|ALLTRIM(x[1])==aFields[nz]})> 0 , { aFields[nz],iif(FWSX3Util():GetFieldStruct( aFields[nz] )[2] == "N",Val(aItens[nX][aScan(aItens[nX],{|x|ALLTRIM(x[1])==aFields[nz]})][2]),aItens[nX][aScan(aItens[nX],{|x|ALLTRIM(x[1])==aFields[nz]})][2]) } , {aFields[nz] , CriaVar(aFields[nz])}))
		EndIf
	Next nZ	
	aadd(aDadEAut[nX],{"DELETE",lDelIt})

	//-- Inclui novo item no array auxiliar.
	/*aAdd(aDadEAut,{	{"ZD_ITEM   ", strzero(nx,3)},; 	//-- 01
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
		{"ZD_PROCESS", cProcess},; 						//-- 76 //--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
		{"ZD_PROCAPV", cProcApv},; 						//-- 77 //--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
		{"ZD_BLODIR" , cBloDir},; 						//-- 78 //--AS - Aleluia - Bloqueio diretoria
		{"ZD_MSGDIR" , cMsgDir},; 						//-- 79 //--AS - Aleluia - Msg. de Bloqueio Dir
		{"ZD_PV2DDEM" , nDeDPRM2},; 					//-- 80 //-- Preco Minimo Default Dolar UM2
		{"ZD_PV2DUSM" , nUsDPRM2},; 					//-- 81 //-- Preco Minimo Usuario Dolar UM2
		{"ZD_PV2RDEM" , nDefPRM2},; 					//-- 82 //-- Preco Minimo Default Real UM2
		{"ZD_PV2RUSM" , nUsuPRM2},; 					//-- 83 //-- Preco Minimo Usuario Real UM2
		{"ZD_CODTABC" , cCodTabCot},;	                //-- 84 //-- Codigo tabela Comissao
		{"DELETE"	  , lDelIt}})						//-- 85 //-- Sempre manter esse campo como o ultimo.*/

Next nX

Return()

//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} fCalcCot
Fun��o de c�lculo da cota��o de acordo com as informa��es passadas pelo usu�rio.
@author		.iNi Sistemas
@since     	27/03/2023
@version  	P.12
@param 		aDadEAut - Array que ser� atualizado com as informa��es calculadas.
@param 		cCampo - Campo utilizado para c�lculo.
@return    	null
@obs        
Altera��es Realizadas desde a Estrutura��o Inicial
------------+-----------------+------------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+------------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
Static Function fCalcCot(aDadEAut,cCampo)

Local nPrcRea := 0
Local nPrcDol := 0
Local nXi := 0
Local nX := 1
Local nPProd := aScan(aDadEAut[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PRODUTO")})
Local nPPreP := aScan(aDadEAut[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PREPROD")})
Local nPUmPad := aScan(aDadEAut[1],{|b| AllTrim(b[1]) == AllTrim("ZD_UMPAD")})
Local nPCusUs := aScan(aDadEAut[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CUSTUSU")})
Local nPQtUm1 := aScan(aDadEAut[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT1")})
Local nPQtUm2 := aScan(aDadEAut[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT2")})
Local nPDelIt := aScan(aDadEAut[1],{|b| AllTrim(b[1]) == AllTrim("DELETE")})
	
If cCampo == "ZD_PRODUTO"

	For nX := 1 to Len(aDadEAut)
		
		If !aDadEAut[nX][nPDelIt][2] //--Desconsidera item deletado

			//--Reseta variavel para buscar imposto por item.
			lBscImp := .T.
			nDefImp := 0
			nUsuImp := 0
			//nImposto := 0

			//Carrega vari�veis que sao necess�rias para o recalculo.
			FCarVar(nX,@aDadEAut)

			cCodPrd := aDadEAut[nX][nPProd][2]
			cUMPad := aDadEAut[nX][nPUmPad][2]
			nUsuCst := aDadEAut[nX][nPCusUs][2]
			
			SB1->(dbSetOrder(1))
			SB1->(dbSeek(xFilial("SB1")+AvKey(cCodPrd,"B1_COD")))

			//-- Busca Descri��o
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
			//nUsuCst := iif(SB1->B1_TIPO == "PA",0,nDefCst) //--03/10/2022 -- .iNi Wemerson -- N�o � necess�io, devido a nova regra para pesquisa do csuto de produtos PA.
			nUsuCst := nDefCst
			nDUsCst := FsCnvDol(nUsuCst)

			//-- Busca a Margem
			nDefMrg := FsBscMrg(cCodPrd,1)
			nUsuMrg := nDefMrg

			//-- Busca a Comiss�o
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

			FAtuArr(nX,@aDadEAut)

		EndIf

	Next nX

EndIf

If cCampo == "ZD_PREPROD"

	For nX := 1 to Len(aDadEAut)

		If !aDadEAut[nX][nPDelIt][2] //--Desconsidera item deletado
			//--Reseta variavel para buscar imposto por item.
			lBscImp := .T.
			nDefImp := 0
			nUsuImp := 0
			//nImposto := 0

			//Carrega vari�veis que sao necess�rias para o recalculo.
			FCarVar(nX,@aDadEAut)

			cPrePrd := aDadEAut[nX][nPPreP][2]
			cUMPad := aDadEAut[nX][nPUmPad][2]
			nUsuCst := aDadEAut[nX][nPCusUs][2]

			SZA->(dbSetOrder(1))
			SZA->(dbSeek(xFilial("SZA")+AvKey(cPrePrd,"ZA_CODIGO")))
			
			//-- Busca Descri��o
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
			nUsuCst := nDefCst //Custo usu�rio real
			nDUsCst := FsCnvDol(nUsuCst) //Custo Usuario Dolar.

			//-- Busca a Margem
			nDefMrg := FsBscMrg(cPrePrd,2)
			nUsuMrg := nDefMrg

			//-- Busca a Comiss�o
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

			//--Fun��o que atualiza array com as variaveis j� recalculadas.
			FAtuArr(nX,@aDadEAut)
		EndIf
	Next nX

EndIf

If cCampo == "ZD_QUANT1" //.And. AllTrim(cUMPad) == AllTrim(cQtdUM1)

	For nX := 1 to Len(aDadEAut)

		If !aDadEAut[nX][nPDelIt][2] //--Desconsidera item deletado
			//--Reseta variavel para buscar imposto por item.
			lBscImp := .T.
			nDefImp := 0
			nUsuImp := 0
			//nImposto := 0

			//Carrega vari�veis que sao necess�rias para o recalculo.
			FCarVar(nX,@aDadEAut)

			cCodPrd := aDadEAut[nX][nPProd][2]
			cPrePrd := aDadEAut[nX][nPPreP][2]
			cUMPad 	:= aDadEAut[nX][nPUmPad][2]
			nUsuCst := aDadEAut[nX][nPCusUs][2]
			nQtdUM1 := aDadEAut[nX][nPQtUm1][2]
			nQtdUM2 := aDadEAut[nX][nPQtUm2][2]

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

				//-- Calcula o Pre�o de Venda Default
				FsClcPrc(1,@nPrcRea,@nPrcDol,1,nDefCst) //-- Pre�o M�nimo Default		

				aImposDef	:= aImpostos
				nImposto := 0
				For nXi := 1 To Len(aImposDef)
					nImposto += aImpostos[nXi]
				Next nXi
				nDefImp := nImposto

				nDefPRM := nPrcRea //-- Preco Minimo Real
				nDeDPRM := nPrcDol //-- Preco Minimo Dolar

				FsClcPrc(1,@nPrcRea,@nPrcDol,2,nDefCst) //-- Pre�o Sugerido Default

				nDefPRE := nPrcRea //-- Pre�o Sugerido Real
				nDefPUS := nPrcDol //-- Pre�o Sugerido Dolar

				nDefTRE := nQtdUM1 * nDefPRE
				nDefTUS := nQtdUM1 * nDefPUS

				//-- Calcula o Pre�o de Venda Minimo Usuario
				FsClcPrc(2,@nPrcRea,@nPrcDol,1,nUsuCst)

				aImposUsu	:= aImpostos
				nImposto := 0
				For nXi := 1 To Len(aImposUsu)
					nImposto += aImpostos[nXi]
				Next nXi
				nUsuImp := nImposto

				nUsuPRM := nPrcRea //-- Preco Minimo Real
				nUsDPRM := nPrcDol //-- Preco Minimo Dolar

				//-- Calcula o Pre�o de Venda Sugerido Usuario
				FsClcPrc(2,@nPrcRea,@nPrcDol,2,nUsuCst)

				nUsuPRE := nPrcRea //-- Pre�o Sugerido Real
				nUsuPUS := nPrcDol //-- Pre�o Sugerido Dolar

				nUsuTRE := nQtdUM1 * nUsuPRE
				nUsuTUS := nQtdUM1 * nUsuPUS

				FClcMGS(1) //-- Calcula Margem (bruta e liquida) Default e de Usu�rio
				
				//--Fun��o que atualiza array com as variaveis j� recalculadas.
				FAtuArr(nX,@aDadEAut)

			EndIf
		EndIf
	Next nX
EndIf


If cCampo == "ZD_QUANT2" //.And. AllTrim(cUMPad) == AllTrim(cQtdUM2)

	For nX := 1 to Len(aDadEAut)
		If !aDadEAut[nX][nPDelIt][2] //--Desconsidera item deletado
			//--Reseta variavel para buscar imposto por item.
			lBscImp := .T.
			nDefImp := 0
			nUsuImp := 0			
			//nImposto := 0

			//Carrega vari�veis que sao necess�rias para o recalculo.
			FCarVar(nX,@aDadEAut)

			cCodPrd := aDadEAut[nX][nPProd][2]
			cPrePrd := aDadEAut[nX][nPPreP][2]
			cUMPad 	:= aDadEAut[nX][nPUmPad][2]
			nUsuCst := aDadEAut[nX][nPCusUs][2]
			nQtdUM1 := aDadEAut[nX][nPQtUm1][2]
			nQtdUM2 := aDadEAut[nX][nPQtUm2][2]

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

				//-- Calcula o Pre�o de Venda Default
				FsClcPrc(1,@nPrcRea,@nPrcDol,1,nDefCst) //-- Pre�o M�nimo Default

				aImposDef	:= aImpostos
				nImposto := 0
				For nXi := 1 To Len(aImposDef)
					nImposto += aImpostos[nXi]
				Next nXi
				nDefImp := nImposto

				nDefPRM2 := nPrcRea //-- Preco Minimo Real
				nDeDPRM2 := nPrcDol //-- Preco Minimo Dolar

				FsClcPrc(1,@nPrcRea,@nPrcDol,2,nDefCst) //-- Pre�o Sugerido Default

				nDef2PRE := nPrcRea //-- Pre�o Sugerido Real
				nDef2PUS := nPrcDol //-- Pre�o Sugerido Dolar

				nDefTRE := nQtdUM2 * nPrcRea
				nDefTUS := nQtdUM2 * nPrcDol

				//-- Calcula o Pre�o de Venda Usuario
				FsClcPrc(2,@nPrcRea,@nPrcDol,1,nUsuCst)

				aImposUsu	:= aImpostos
				nImposto := 0
				For nXi := 1 To Len(aImposUsu)
					nImposto += aImpostos[nXi]
				Next nXi
				nUsuImp := nImposto

				nUsuPRM2 := nPrcRea //-- Preco Minimo Real
				nUsDPRM2 := nPrcDol //-- Preco Minimo Dolar

				//-- Calcula o Pre�o de Venda Sugerido Usuario
				FsClcPrc(2,@nPrcRea,@nPrcDol,2,nUsuCst)

				nUsu2PRE := nPrcRea
				nUsu2PUS := nPrcDol

				nUsuTRE := nQtdUM2 * nUsu2PRE
				nUsuTUS := nQtdUM2 * nUsu2PUS

				FClcMGS(1) //-- Calcula Margem (bruta e liquida) Default e de Usu�rio

				//--Fun��o que atualiza array com as variaveis j� recalculadas.
				FAtuArr(nX,@aDadEAut)
			EndIf
		EndIf
	Next nX
EndIf


If cCampo $ "ZD_CUSTUSU"

	For nX := 1 to Len(aDadEAut)
		If !aDadEAut[nX][nPDelIt][2] //--Desconsidera item deletado
			//--Reseta variavel para buscar imposto por item.
			lBscImp := .T.
			nDefImp := 0
			nUsuImp := 0			
			//nImposto := 0

			//Carrega vari�veis que sao necess�rias para o recalculo.
			FCarVar(nX,@aDadEAut)

			cCodPrd := aDadEAut[nX][nPProd][2]
			cPrePrd := aDadEAut[nX][nPPreP][2]
			cUMPad := aDadEAut[nX][nPUmPad][2]
			nUsuCst := aDadEAut[nX][nPCusUs][2]
			nQtdUM2 := aDadEAut[nX][aScan(aDadEAut[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT2")})][2]

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
					
				//-- Calcula o Pre�o de Venda Default
				FsClcPrc(1,@nPrcRea,@nPrcDol,1,nDefCst) //-- Pre�o M�nimo Default

				aImposDef	:= aImpostos
				nImposto := 0
				For nXi := 1 To Len(aImposDef)
					nImposto += aImpostos[nXi]
				Next nXi
				nDefImp := nImposto

				nDefPRM2 := nPrcRea //-- Preco Minimo Real
				nDeDPRM2 := nPrcDol //-- Preco Minimo Dolar

				FsClcPrc(1,@nPrcRea,@nPrcDol,2,nDefCst) //-- Pre�o Sugerido Default

				nDef2PRE := nPrcRea //-- Pre�o Sugerido Real
				nDef2PUS := nPrcDol //-- Pre�o Sugerido Dolar

				nDefTRE := nQtdUM2 * nPrcRea
				nDefTUS := nQtdUM2 * nPrcDol

				//-- Calcula o Pre�o de Venda Usuario UM1
				FsClcPrc(2,@nPrcRea,@nPrcDol,1,nUsuCst)

				aImposUsu	:= aImpostos
				nImposto := 0
				For nXi := 1 To Len(aImposUsu)
					nImposto += aImpostos[nXi]
				Next nXi
				nUsuImp := nImposto

				nUsuPRM := nPrcRea //-- Preco Minimo Real UM1
				nUsDPRM := nPrcDol //-- Preco Minimo Dolar UM1
						
				//-- Calcula o Pre�o de Venda Sugerido Usuario
				FsClcPrc(2,@nPrcRea,@nPrcDol,2,nUsuCst)

				nUsuPRE := nPrcRea  //--Pre�o Sugerido Real UM1
				nUsuPUS := nPrcDol	//--Pre�o Sugerido Dolar UM1
				nUsuTRE := nQtdUM1 * nUsuPRE
				nUsuTUS := nQtdUM1 * nUsuPUS
								
				If nUsuCst > 0
					//-- Calcula o Pre�o de Venda Usuario UM2
					FsClcPrc(3,@nPrcRea,@nPrcDol,1,iif(cUMPad == 'KG',(nUsuCst * nFatorConver),(nUsuCst / nFatorConver)))

					nUsuPRM2 := nPrcRea //-- Preco Minimo Real UM2
					nUsDPRM2 := nPrcDol //-- Preco Minimo Dolar UM2

					//-- Calcula o Pre�o de Venda Sugerido Usuario
					FsClcPrc(3,@nPrcRea,@nPrcDol,2,iif(cUMPad == 'KG',(nUsuCst * nFatorConver),(nUsuCst / nFatorConver)))

					nUsu2PRE := nPrcRea //--Pre�o Sugerido Real UM2
					nUsu2PUS := nPrcDol //--Pre�o Sugerido Dolar UM2

				Endif

			Else
				//-- Calcula o Pre�o de Venda Default
				FsClcPrc(1,@nPrcRea,@nPrcDol,1,nDefCst) //-- Pre�o M�nimo Default

				aImposDef	:= aImpostos
				nImposto := 0
				For nXi := 1 To Len(aImposDef)
					nImposto += aImpostos[nXi]
				Next nXi
				nDefImp := nImposto

				nDefPRM2 := nPrcRea //-- Preco Minimo Real
				nDeDPRM2 := nPrcDol //-- Preco Minimo Dolar

				FsClcPrc(1,@nPrcRea,@nPrcDol,2,nDefCst) //-- Pre�o Sugerido Default

				nDef2PRE := nPrcRea //-- Pre�o Sugerido Real
				nDef2PUS := nPrcDol //-- Pre�o Sugerido Dolar

				nDefTRE := nQtdUM2 * nPrcRea
				nDefTUS := nQtdUM2 * nPrcDol

				//-- Calcula o Pre�o de Venda Usuario UM2
				FsClcPrc(2,@nPrcRea,@nPrcDol,1,nUsuCst)

				aImposUsu := aImpostos
				nImposto := 0
				For nXi := 1 To Len(aImposUsu)
					nImposto += aImpostos[nXi]
				Next nXi
				nUsuImp := nImposto

				nUsuPRM2 := nPrcRea //-- Preco Minimo Real UM2
				nUsDPRM2 := nPrcDol //-- Preco Minimo Dolar UM2

				//-- Calcula o Pre�o de Venda Sugerido Usuario
				FsClcPrc(2,@nPrcRea,@nPrcDol,2,nUsuCst)

				nUsu2PRE := nPrcRea //--Pre�o Sugerido Real UM2
				nUsu2PUS := nPrcDol //--Pre�o Sugerido Dolar UM2
				nUsuTRE := nQtdUM2 * nUsu2PRE
				nUsuTUS := nQtdUM2 * nUsu2PUS

				If nUsuCst > 0 
						
					//-- Calcula o Pre�o de Venda Usuario UM1
					FsClcPrc(3,@nPrcRea,@nPrcDol,1,iif(cUMPad == 'KG',(nUsuCst * nFatorConver),(nUsuCst / nFatorConver)))

					nUsuPRM := nPrcRea //-- Preco Minimo Real UM1
					nUsDPRM := nPrcDol //-- Preco Minimo Dolar UM1

					//-- Calcula o Pre�o de Venda Sugerido Usuario
					FsClcPrc(3,@nPrcRea,@nPrcDol,2,iif(cUMPad == 'KG',(nUsuCst * nFatorConver),(nUsuCst / nFatorConver)))

					nUsuPRE := nPrcRea  //--Pre�o Sugerido Real UM1
					nUsuPUS := nPrcDol	//--Pre�o Sugerido Dolar UM1

				Endif
			Endif

			//--Fun��o que atualiza array com as variaveis j� recalculadas.
			FAtuArr(nX,@aDadEAut)

		EndIf
	Next nX

EndIf

Return()

//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} FAtuArr
Fun��o que atualiza array com as variaveis j� recalculadas.
@author		.iNi Sistemas
@since     	27/03/2023
@version  	P.12
@param 		n_REG - Registros do array a ser calculado.
@param 		aDadAux - Array que ser� calculado.
@return    	null
@obs        
Altera��es Realizadas desde a Estrutura��o Inicial
------------+-----------------+------------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+------------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
Static Function FAtuArr(n_REG,aDadAux)


	//-- Atualiza vari�veis de quantidade
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT1")})][2] := nQtdUM1 
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_QUANT2")})][2] := nQtdUM2 

	//-- Atualiza variaveis de forma��o de pre�o default
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

	//-- Atualiza variaveis de forma��o de pre�o de usu�rio
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
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCESS")})][2] := cProcess //--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PROCAPV")})][2] := cProcApv //--23/04/2020 - Wemerson Souza - Variavel para tratar Processo de Cota��o de Venda
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_BLODIR")})][2] := cBloDir //--AS - Aleluia - Bloqueio Diretoria
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_MSGDIR")})][2] := cBloDir //--AS - Aleluia - Msg. de Bloqueio Dir
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RDEF")})][2] := nDef2PRE //--Pre�o Sugerido Defaut Real UM2
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSU")})][2] := nUsu2PRE //--Pre�o Sugerido Usuario Real UM2
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DDEF")})][2] := nDef2PUS //--Pre�o Sugerido Defaut Dolar UM2
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSU")})][2] := nUsu2PUS //--Pre�o Sugerido Usuario Dolar UM2
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DDEM")})][2] := nDeDPRM2 // -- Preco Minimo Default Dolar UM2
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2DUSM")})][2] := nUsDPRM2 // -- Preco Minimo Usuario Dolar UM2
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RDEM")})][2] := nDefPRM2 // -- Preco Minimo Default Real UM2	
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PV2RUSM")})][2] := nUsuPRM2 // -- Preco Minimo Usuario Real UM2	
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_CODTABC")})][2] := cCodTabCot // -- Codigo Tabela Comissao
	
	//--Impostos.
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PPISDEF")})][2] := aImposDef[1] 				//-- 15 - PIS
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PPISUSU")})][2] := aImposUsu[1] 				//-- 16 - PIS
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCOFDEF")})][2] := aImposDef[2] 				//-- 17 - COFINS
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PCOFUSU")})][2] := aImposUsu[2] 				//-- 18 - COFINS
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PICMDEF")})][2] := aImposDef[3] 				//-- 19 - ICMS
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PICMUSU")})][2] := aImposUsu[3] 				//-- 20 - ICMS
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PIPIDEF")})][2] := aImposDef[4] 				//-- 21 - IPI
	aDadAux[n_REG][aScan(aDadAux[1],{|b| AllTrim(b[1]) == AllTrim("ZD_PIPIUSU")})][2] := aImposUsu[4] 				//-- 22 - IPI

Return()



//-----------------------------------------------------------------------------------------------
/*/
{Protheus.doc} fsAtuCus
Fun��o que atualiza o custo do produto e pr�-produto.
@author		.iNi Sistemas
@since     	30/03/2023
@version  	P.12
@param 		cCodigo - Codigo do produto ou pr�-produto.
@param 		nTipo - 1=produto 2=pr�-produto.
@param 		nCusto - Valor de custo a atualizar.
@return    	null
@obs        
Altera��es Realizadas desde a Estrutura��o Inicial
------------+-----------------+------------------------------------------------------------------
Data       	|Desenvolvedor    |Motivo
------------+-----------------+------------------------------------------------------------------
/*/
//-----------------------------------------------------------------------------------------------
Static Function fsAtuCus(cCodigo,nTipo,nCusto)

	Local cQuery  := ""
	Local aAreaB1 := SB1->(GetArea())
	Local aAreaZA := SZA->(GetArea())
	Local cTpPrd  := ""
	Local cAlias  := GetNextAlias()
	LOcal nX 	  := 0
	Local cAtuCus := ""
	Local aCstPrd := {}

	If nTipo == 1 //--Custo para Produto

		SB1->(dbSetOrder(1))
		SB1->(dbSeek(xFilial("SB1")+cCodigo))
		cTpPrd := SB1->B1_TIPO

		If cTpPrd $ "MP/RV" // Se tipo for MP ou RV, busca custo da SZT, aplicando o percentual do campo BZ_ZESTICM
			cQuery := "SELECT R_E_C_N_O_ NREC " + Chr(13) + Chr(10)
			//cQuery += "BZ_ZESTICM" + Chr(13) + Chr(10)
			cQuery += "FROM " + RetSqlName("SZT") + " ZT" + Chr(13) + Chr(10)
			cQuery += "INNER JOIN " + RetSqlName("SBZ") + " BZ ON BZ.D_E_L_E_T_ <> '*' AND BZ_FILIAL = ZT_FILIAL AND BZ_COD = ZT_PRODUTO" + Chr(13) + Chr(10)
			cQuery += "WHERE ZT.D_E_L_E_T_ <> '*' AND ZT_FILIAL = '" + xFilial("SZT") + "'" + Chr(13) + Chr(10) //percentual de estorno de ICMS nao tributado na entrada
			cQuery += "AND ZT_PRODUTO = '" + cCodigo + "'" + Chr(13) + Chr(10)
			cQuery += "AND ZT_DATA = TO_CHAR(SYSDATE,'YYYYMMDD')" + Chr(13) + Chr(10)
		Else
			cQuery := "SELECT R_E_C_N_O_ NREC " + Chr(13) + Chr(10)
			//cQuery += "BZ_ZESTICM" + Chr(13) + Chr(10)
			cQuery += "FROM " + RetSqlName("SZV") + " ZV" + Chr(13) + Chr(10)
			cQuery += "INNER JOIN " + RetSqlName("SBZ") + " BZ ON BZ.D_E_L_E_T_ <> '*' AND BZ_FILIAL = ZV_FILIAL AND BZ_COD = ZV_PRODUTO" + Chr(13) + Chr(10)
			cQuery += "WHERE ZV.D_E_L_E_T_ <> '*' AND ZV_FILIAL = '" + xFilial("SZT") + "'" + Chr(13) + Chr(10) //percentual de estorno de ICMS nao tributado na entrada
			cQuery += "AND ZV_PRODUTO = '" + cCodigo + "'" + Chr(13) + Chr(10)
			cQuery += "AND ZV_DATA = '"+ DtoS(dDataBase) +"'" + Chr(13) + Chr(10)
		Endif

		dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),cAlias,.T.,.T.)
		If !(cAlias)->(EoF())

			If cTpPrd $ "MP/RV" 
				SZT->(Dbgoto((cAlias)->NREC))
					SZT->ZT_CUSTO := nCusto
				SZT->(MsUnLock())
			Else
				SZV->(Dbgoto((cAlias)->NREC))
					SZV->ZV_CUSTO := nCusto
				SZV->(MsUnLock())
			EndIf

		EndIf
		(cAlias)->(dbCloseArea())

	ElseIf nTipo == 2 //--Custo para Pr�-Produto

		SZA->(dbSetOrder(1))
		If SZA->(dbSeek(xFilial("SZA")+cCodigo))
			aCstPrd := StrTokArr2(SZA->ZA_ZCUSBRI,"/")		
			aCstPrd[ASCAN(aCstPrd ,{|a| SubStr(a,1,Len(xFilial("SBZ"))) == xFilial("SBZ")})] := xFIlial("SBZ")+" - "+AllTrim(Str(nCusto))+" - "+dtos(ddatabase)//REPLACE(dtoc(YearSum(ddatabase,1)),"/","")

			For nX := 1 to Len(aCstPrd)
				cAtuCus += aCstPrd[nX]+"/"
			Next nX

			RecLock("SZA",.F.)			
				SZA->ZA_ZCUSBRI := substring(cAtuCus,1,len(cAtuCus)-1)
			SZA->(MsUnLock())			
		EndIf

	EndIf

	RestArea(aAreaB1)
	RestArea(aAreaZA)

Return()
