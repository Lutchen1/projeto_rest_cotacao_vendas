#INCLUDE "TOTVS.CH"

/********************************************************************************\
|					    VACCINAR NUTRICAO E SAUDE ANIMAL				 		 |
\********************************************************************************>
|Programa: TIVRO061  | Dt. Criação: 16/11/2016 | Responsavel: Leonardo Perrella	 |
|--------------------------------------------------------------------------------|
|Resumo: Sequencial do código de produtos							 	         |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 01/12/2016 | Responsavel: Leonardo Perrella						 |
|--------------------------------------------------------------------------------|
|Motivo: Alteração na funcão TIVEXSB1 utilizando dbseek ao invés de query.		 |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 21/09/2021 | Responsavel: Lucas - MAIS							 |
|--------------------------------------------------------------------------------|
|Motivo: Criação de tratativa para verificar se a execução vem da FOX para obede |
|cer o sequencial retornado pela empresa 01(Vaccinar)                            |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 03/07/2023 | Responsavel: Lutchen Oliveira						 |
|--------------------------------------------------------------------------------|
|Motivo: incluindo parametro de grupo. Estamos passando no rest de efetivação de |
|pré-produto para calcular de acordo com o grupo o código do produto.            |
|--------------------------------------------------------------------------------|
/********************************************************************************>
|					    VACCINAR NUTRICAO E SAUDE ANIMAL				 		 |
\********************************************************************************/
/*------------------------------------------------------------------------------*\
|Função: TIVRO061
|Descrição: Sequencia de Código de Produtos
|Data: 16/11/2016
|Responsavel: Leonardo Perrella
|Parametro:	cAlias		Variavel que recebe o nome da tabela em questão
|Parametro:	cCampo		Variavel que recebe o campo que será validado
|Parametro:	nIndice		Variavel que recebe o numero do indice que será levado em consideração para posicionamento
|Parametro:	lStrZero	Variavel logica que recebe .T. caso queira que o codigo seja completado com 0 a esquerda ou .F. caso queira que não
|Retorno:	cCod		Variavel contendo o codigo que será utilizado
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

	If "09" $ cFilAnt // Lucas - MAIS :: 21/09/2021 - Se a empresa for a 09, retorna o sequencial como se estivesse na 01, pois os cadastros sao replicados e a principal é a 01.
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
	
	Processa({|| cCod := TIVBUSCOD(cAlias,nTamPad) }, "Buscando Código...")
	If Len(AllTrim(cCod)) <= 1
    	Alert("A busca não encontrou um código automático, pois não existe cadastro para o grupo informado. Favor, criar manualmente.")
    Else
    	MSGALERT("Código sequencial gerado " + cCod)
    EndIf
    
	If !Empty(cFilBus)
		cFilAnt := cFilBus
	End If

Return cCod
	 
	
/*------------------------------------------------------------------------------*\
|Função: TIVBUSCOD
|Descrição: Faz a busca do código do produto de acordo com a tabela cAlias
|Data: 16/11/2016
|Responsavel: Leonardo Perrella
|Parametro:	cAlias		Alias da Tabela
|Retorno:	cCod		Código do produto não cadastrado
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
|Função: TIVEXSB1
|Descrição: Função criada para verificar se o código do produto já está cadastrado
|Data: 16/11/2016
|Responsavel: Leonardo Perrella 
|Alteração: 01/12/2016  Responsavel: Leonardo Perrella
|Motivo: Estava aparecendo erro de alias quando fechava a tabela temporária utilizando a 
|funcao FSCLOSEAREA antes do return da funcao.
|Parametro:	cCod		Código do produto
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
