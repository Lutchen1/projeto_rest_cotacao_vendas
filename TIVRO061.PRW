#INCLUDE "TOTVS.CH"

/********************************************************************************\
|					    VACCINAR NUTRICAO E SAUDE ANIMAL				 		 |
\********************************************************************************>
|Programa: TIVRO061  | Dt. Cria��o: 16/11/2016 | Responsavel: Leonardo Perrella	 |
|--------------------------------------------------------------------------------|
|Resumo: Sequencial do c�digo de produtos							 	         |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 01/12/2016 | Responsavel: Leonardo Perrella						 |
|--------------------------------------------------------------------------------|
|Motivo: Altera��o na func�o TIVEXSB1 utilizando dbseek ao inv�s de query.		 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 21/09/2021 | Responsavel: Lucas - MAIS							 |
|--------------------------------------------------------------------------------|
|Motivo: Cria��o de tratativa para verificar se a execu��o vem da FOX para obede |
|cer o sequencial retornado pela empresa 01(Vaccinar)                            |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 03/07/2023 | Responsavel: Lutchen Oliveira						 |
|--------------------------------------------------------------------------------|
|Motivo: incluindo parametro de grupo. Estamos passando no rest de efetiva��o de |
|pr�-produto para calcular de acordo com o grupo o c�digo do produto.            |
|--------------------------------------------------------------------------------|
/********************************************************************************>
|					    VACCINAR NUTRICAO E SAUDE ANIMAL				 		 |
\********************************************************************************/
/*------------------------------------------------------------------------------*\
|Fun��o: TIVRO061
|Descri��o: Sequencia de C�digo de Produtos
|Data: 16/11/2016
|Responsavel: Leonardo Perrella
|Parametro:	cAlias		Variavel que recebe o nome da tabela em quest�o
|Parametro:	cCampo		Variavel que recebe o campo que ser� validado
|Parametro:	nIndice		Variavel que recebe o numero do indice que ser� levado em considera��o para posicionamento
|Parametro:	lStrZero	Variavel logica que recebe .T. caso queira que o codigo seja completado com 0 a esquerda ou .F. caso queira que n�o
|Retorno:	cCod		Variavel contendo o codigo que ser� utilizado
\*------------------------------------------------------------------------------*/
User Function TIVRO061(cAlias,cCampo,nIndice,nTamPad,cGrupo)
    Local cFilBus := ""
	Local cFilPad := SuperGetMv("MC_FILSEQF",.F.,"010001") // Lucas - MAIS : 21/09/2021 - Define a filial que sera assumida, caso o cadastro venha da empresa FOX.
	Private cCod	  := ""
	Private cCodAux   := ""
	Private nCod	  := ""
	Private nTam	  := TamSX3(cCampo)[1]
	Private cCamp	  := cAlias + "->" + cCampo
	default cGrupo    := M->B1_GRUPO
	Default nIndice	  := 4
	Default nTamPad   := 7 

	If "09" $ cFilAnt // Lucas - MAIS :: 21/09/2021 - Se a empresa for a 09, retorna o sequencial como se estivesse na 01, pois os cadastros sao replicados e a principal � a 01.
		cFilBus := cFilAnt
		cFilAnt := cFilPad
	End iF

	HelpInDark(.T.)
	dbSelectArea(cAlias)
	(cAlias)->(dbSetOrder(nIndice))
	(cAlias)->(dbGoTop())
	ProcRegua(RecCount())
	If Empty(Posicione("SBM",1,xFilial("SBM")+cGrupo,"BM_ZCHAVE"))
		(cAlias)->(dbSeek(xFilial(cAlias)+cGrupo))
	Else
		(cAlias)->(dbSeek(xFilial(cAlias)+cGrupo+AllTrim(SBM->BM_ZCHAVE)),.T.)
	EndIf		
	nCod := Val(AllTrim(&(cCamp)))
	cCod := AllTrim(Str(nCod + 1))
	
	Processa({|| cCod := TIVBUSCOD(cAlias,nTamPad) }, "Buscando C�digo...")
	If Len(AllTrim(cCod)) <= 1
    	Alert("A busca n�o encontrou um c�digo autom�tico, pois n�o existe cadastro para o grupo informado. Favor, criar manualmente.")
    Else
    	MSGALERT("C�digo sequencial gerado " + cCod)
    EndIf
    
	If !Empty(cFilBus)
		cFilAnt := cFilBus
	End If

Return cCod
	 
	
/*------------------------------------------------------------------------------*\
|Fun��o: TIVBUSCOD
|Descri��o: Faz a busca do c�digo do produto de acordo com a tabela cAlias
|Data: 16/11/2016
|Responsavel: Leonardo Perrella
|Parametro:	cAlias		Alias da Tabela
|Retorno:	cCod		C�digo do produto n�o cadastrado
\*------------------------------------------------------------------------------*/ 
Static Function TIVBUSCOD(cAlias,nTamPad)	
	While !(cAlias)->(EoF()) .AND. /*cGrupo == SB1->B1_GRUPO .And. */&(cAlias + "->" + IIF(SubStr(cAlias,1,1) == "S",SubStr(cAlias,2,2),cAlias) + "_FILIAL") == xFilial(cAlias)
		IncProc()	
		If AllTrim(cCod) == AllTrim(&(cCamp)) .Or. Len(AllTrim(cCod)) < nTamPad .Or. TIVEXSB1(cCod,cAlias)
			If Len(AllTrim(cCod)) < nTamPad
				(cAlias)->(dbSkip())
				nCod := Val(AllTrim(&(cCamp)))
				nCod++ 
				cCod := AllTrim(Str(nCod))
			Else
				nCod++
				cCod := AllTrim(Str(nCod))
				(cAlias)->(dbSkip())
			EndIf	
		Else
			Exit
		EndIf	
	EndDo
	HelpInDark(.F.)
Return(cCod)

/*------------------------------------------------------------------------------*\
|Fun��o: TIVEXSB1
|Descri��o: Fun��o criada para verificar se o c�digo do produto j� est� cadastrado
|Data: 16/11/2016
|Responsavel: Leonardo Perrella 
|Altera��o: 01/12/2016  Responsavel: Leonardo Perrella
|Motivo: Estava aparecendo erro de alias quando fechava a tabela tempor�ria utilizando a 
|funcao FSCLOSEAREA antes do return da funcao.
|Parametro:	cCod		C�digo do produto
|Retorno:	lOk	   		Variavel retorna .T. caso exista o produto no cadastro por empresa
\*------------------------------------------------------------------------------*/

Static Function TIVEXSB1(cCod,cAlias)
Local lOk := .F.
Local aAreaAll	:= {SB1->(GetArea()),GetArea()}

	DbSetOrder(1)
	(cAlias)->(dbGoTop())
	IF dbSeek(xFilial("SB1")+cCod+Space(nTam-Len(cCod)))
		lOk := .T.
	EndIf	
	
	AEval(aAreaAll,{|x|RestArea(x)})
Return lOk
