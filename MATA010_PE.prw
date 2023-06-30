#INCLUDE "TOTVS.CH"

/********************************************************************************\
|					    VACCINAR NUTRICAO E SAUDE ANIMAL				 		 |
\********************************************************************************>
|Programa: ITEM		 | Dt. Criação: 31/01/2019 | Responsavel: Rodrigo Prates	 |
|--------------------------------------------------------------------------------|
|Resumo: Ponto de entrada em MVC na rotina de Cadastro de Produtos (MATA010).	 |
|Esse ponto de entrada é chamado em vários momentos da função padrão MATA010,	 |
|tendo que ser analisado pelo PARAMIXB[2]. O P.E. MT010INC e MT010ALT foram		 |
|descontinuados. A documentação do P.E. MT010INC (o MT010ALT era um resumo do INC|
|e por isso sua documentação não teve necessidade de transposição) foi mantida no|
|fonte a titulo de histórico.													 |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 13/11/2012 | Responsavel: Rodrigo Prates						 |
|--------------------------------------------------------------------------------|
|Motivo: Ponto de Entrada após a inclusão de produto na tabela SB1. Insere		 |
|registro daquele produto na tabela SBZ (Indicadores de Produto) para todas as	 |
|filiais cadastradas.															 |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 06/08/2013 | Responsavel: Helder Santos							 |
|--------------------------------------------------------------------------------|
|Motivo: No momento da inclusao do produto e caso o campo B1_RASTRO = 'L'		 |
|será criado o complemento para o mesmo em todas as filiais do sistema			 |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 19/08/2015 | Responsavel: Leonardo Perrella						 |
|--------------------------------------------------------------------------------|
|Motivo: Adicionado parametro TIV_SIGAQTY para considerar apenas as filias que   |
|serão gravados o Tipo CQ = "Q"		                                             |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 20/09/2017 | Responsavel: Leonardo Perrella						 |
|--------------------------------------------------------------------------------|
|Motivo: Adiconado gravação do campo B1_ZPRODPI no campo BZ_ZPRODPI.             |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 29/09/2017 | Responsavel: Leonardo Perrella						 |
|--------------------------------------------------------------------------------|
|Motivo: Adicinonado informações padroes nos campos B5_SERVENT,B5_ENDENT e 		 |
|B5_ZMULPL de preenchimento na SB5 na função FsCComPro.        					 |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 22/05/2018 | Responsavel: Rodrigo Prates						 |
|--------------------------------------------------------------------------------|
|Motivo: As funções de mensagem ApMsgAlert() tiveram o 2o parametro (título da	 |
|janela) alterado para se encaixar no padrão desenvolvido pela T.I. Vaccinar:	 |
|"<Função Principal> - " + AllTrim(Str(ProcLine(0))) + " - <Nome no Menu>"		 |
|Na função FsCComPro() foi criada a variavel cFilErro para receber o código das	 |
|que apresentaram problema no execauto											 |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 15/11/2018 | Responsavel: Rodrigo Prates						 |
|--------------------------------------------------------------------------------|
|Motivo: A função MT010INC() foi alterada passando a criar os registros da SBZ	 |
|(Indicador de Produtos) e SB5 (Complemento de Produtos) somente se o produto que|
|esta sendo incluído estiver com a liberação de tela == Sim. A validação da SB5	 |
|somente ser criada se o produto controlar rastro ainda permanece. Foi adicionada|
|a função TIVZB1() que insere um registro na ZB1 (Campos Customizados de Produtos|
|A função FsCComPro() teve seu nome alterado para TIVINCB5() para ficar mais	 |
|didática e padrão com o resto das funções do fonte e seu modificador de acesso	 |
|passou a ser User, pois ela passou a ser chamada pelo P.E. MT010ALT. A inclusão |
|de registros na SBZ foi transformada numa função especifica, chamada de TIVINCBZ|
|com modificador de acesso User, pois também é chamada pelo P.E. MT010ALT. Todas |
|as variaveis que recebiam os campos da SB1 e que compunham a escrita do comando |
|INSERT foram excluídas por não serem mais necessárias, uma vez que os campos que|
|elas recebiam podem ser diretamente utilizados. Tratamentos feitos para atender |
|os chamados 2019010207000116 e 2019021807000728.								 |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 25/02/2019 | Responsavel: Rodrigo Prates						 |
|--------------------------------------------------------------------------------|
|Motivo: A função TIVINCZB1() foi alterada, pois o calculo do novo R_E_C_N_O_	 |
|levava em consideração a filial, mas esse numero é unico por tabela. A sigla de |
|minuto foi alterada para MI, pois a anterior, MM, é de mês. As funções			 |
|TIVINCLUSAO() e TIVALTERACAO() foram alteradas, pois a chamada da função		 |
|TIVZB1() não considerava a alteração do campo B1_ZSTATUS e, com isso, gravava	 |
|log para qualquer alteração de qualquer usuário								 |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 13/03/2019 | Responsavel: Rodrigo Prates						 |
|--------------------------------------------------------------------------------|
|Motivo: Foi adicionado o Ponto de Entrada MTA010INC para que sejam definidos os |
|campos que, no momento da cópia de um produto, tenham seus conteúdos apagados	 |
|Chamado: 2019031307000235														 |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 11/07/2019 | Responsavel: Claudio Silva 						 |
|--------------------------------------------------------------------------------|
|Motivo: Mudança da chamada do TIVALTERACAO para após gravação da tabela e		 |
|removido a chamada de antes da gravação. Alterado na User function ITEM		 |
|Alteração no static function TIVALTERACAO: Alterado a regra para incluir os     |
|dados na SB5 devido ao processo de liberação. O mesmo não estava incluíndo 	 |
|no momento da liberação Ticket: 2019062707000445								 |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 16/07/2019 | Responsavel: Claudio Silva							 |
|--------------------------------------------------------------------------------|
|Motivo: Não estava incluído o indicador de produto devido a alteração da chamada|
|do TIVALTERAÇÃO para antes da gravação para depois de gravado. Foi retirado a   |
|validação se estava bloqueado para não bloqueado. 								 |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 25/06/2020 | Responsavel: Antonio Mateus						 |
|--------------------------------------------------------------------------------|
|Motivo: Adicionado o campo ZB1_PRDCUS à query de inserção de registros na tabela|
|ZB1 e criação da chamada opcional ao programa TIVRO103 visando a manutenção de  |
|registros na tabela de dados customizados do produto (ZB1) após a inclusão do   |
|produto na SB1.																 |
|--------------------------------------------------------------------------------|
|Dt. Alteração:  08/07/2020 | Responsavel: Dayvid Nogueira 	     				 |
|--------------------------------------------------------------------------------|
|Motivo: Adicionado validação na gravação do codigo Produto no cadastro          |
|do Pre-produto para seja gravado somente se o campo estiver vazio.              |
|--------------------------------------------------------------------------------|
|Dt. Alteração:   27/11/2020 | Responsavel: Dayvid Nogueira						 |
|--------------------------------------------------------------------------------|
|Motivo: Inserido os campos definidos na Expressão SQL para não ocorrer erro	 |
|com Inclusão de novos campos na tabela ZB1, para atender o chamado              |
|Ticket#2020112507000758                                                         |
|--------------------------------------------------------------------------------|
|Dt. Alteração:   17/03/2021 | Responsavel: Lucas - MAIS   						 |
|--------------------------------------------------------------------------------|
|Motivo: Inclui tratativa para verificar se a execução é via rotina automática   |
|tratando a exibição de mensagem gráfica na tela.								 |
|--------------------------------------------------------------------------------|
|Dt. Alteração:   09/08/2021 | Responsavel: Lucas - MAIS    					 |
|--------------------------------------------------------------------------------|
|Motivo: Adicionada tratativa para replicação de cadastro entre FOX e Fabrica	 |
|--------------------------------------------------------------------------------|
|Dt. Alteração:   02/09/2021 | Responsavel: Lucas - MAIS    					 |
|--------------------------------------------------------------------------------|
|Motivo: Adicionada tratativa para exibir mensagem de alerta se ocorrer erros	 |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 21/09/2021     | Responsavel: Lucas - MAIS		        		 |
|--------------------------------------------------------------------------------|
|Motivo: Adicionada tratativa para validar se codigo ja existe entre empresas	 |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 21/12/2021 | Responsavel: Ponto Ini - Wemerson					 |
|--------------------------------------------------------------------------------|
|Motivo: Inclui validação no preenchimento dos campos Rastro e Controla Endereço | 
|para produtos do tipo PA e MP.													 |
|--------------------------------------------------------------------------------|
|Dt. Alteração: 12/01/2022 | Responsavel: Lucas - MAIS							 |
|--------------------------------------------------------------------------------|
|Motivo: Gravação da aliquota da linha de produtos na inclusao de um novo produto| 
|--------------------------------------------------------------------------------|
|Dt. Alteração:   /  /     | Responsavel: 										 |
|--------------------------------------------------------------------------------|
|Motivo:												 						 |
/********************************************************************************>
|					    VACCINAR NUTRICAO E SAUDE ANIMAL				 		 |
\********************************************************************************/
/*------------------------------------------------------------------------------*\
|Função: ITEM
|Descrição: Função principal do ponto de entrada que faz as validações dos
|momentos de execução do P.E. e dispara suas particularidades.
|Data: 31/01/2019
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:	xRet	Variavel de controle, de tipagem variavel de acordo com o momento 
|em que o P.E. esta sendo chamado
|-------------------------------------------------------------------------------->
|Alterado por: Cláudio Silva		Data: 11/07/2019
|Descrição: Mudança da chamada do TIVALTERAÇÃO para após gravação da tabela e
|removido a chamada de antes da gravação.
|-------------------------------------------------------------------------------->
|Alterado por: Antonio Mateus		Data: 25/06/2020
|Descrição: Criada a chamada opcional do programa TIVRO103 para inclusão de  
|registros na tabela de dados customizados de produto (ZB1)				
|-------------------------------------------------------------------------------->
|Alterado por: Lucas - MAIS			Data: 17/03/2021
|Descrição: Inclui tratativa para verificar se a execução é via rotina automática
|tratando a exibição de mensagem gráfica na tela.		
|-------------------------------------------------------------------------------->
|Alterado por: Lucas - MAIS			Data: 09/08/2021
|Descrição: Adicionada tratativa para replicação de cadastro entre FOX e Fabrica
|-------------------------------------------------------------------------------->
|Alterado por: Lucas - MAIS			Data: 02/09/2021 
|Descrição: Adicionada tratativa para exibir mensagem de alerta se ocorrer erros
|-------------------------------------------------------------------------------->
|Alterado por: Lucas - MAIS			Data: 21/09/2021 
|Descrição: Adicionada tratativa para validar se codigo ja existe entre empresas
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira		Data: 29/12/2022
|Descrição: Torna o preenchimento obrigatório da tabela ZB1 quando o produto for 
|			PA ou BN.
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira		Data: 30/12/2022
|Descrição: Incluir validação no cadastro de produto para controle obrigatório de 
|			Rastro e Endereçamento quanto tipo do produto igual a MP, PA, RV, BN.
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira		Data: 21/03/2023
|Descrição: Incluí codigo de beneficio para o produto automaticamente para as 
|			filiais de pinhais e toledo.
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira		Data: 12/04/2023 
|Descrição: Ao alterar o cadastro do produto alterar também o campo B5_CONVDIP.
|		    Este deve ter o peso do produto de acordo com a conversão em KG.
|			No campo B5_UMDIPI deve conter 'KG'.	
\*------------------------------------------------------------------------------*/
User Function ITEM()
	Local aFiliais := {} //Array que recebera o codigo das filiais cadastradas na SM0 (Empresas)
	Local xRet	   := .T.
	Local aArea	   := GetArea()
	Local lRet     := .F.
	Local oObj     
	Local nOpc 
	Local aParam   := PARAMIXB
	
	//If PARAMIXB[2] == "FORMCOMMITTTSPRE" //Antes da gravação da tabela do formulário. //Tratamento TIVALTERACAO foi transferido para o ponto FORMCOMMITTTSPOS  - 11-07-19 CLAUDIO.SILVA
	If PARAMIXB[2] == "FORMCOMMITTTSPOS" //Chamada após a gravação da tabela do formulário.
		aFiliais := FWAllFilial(FWCodEmp(),,,.F.) //->Rodrigo Prates - Momento em que o são obtidos os codigos das filiais cadastradas na tabela SM0 (Empresas)
		If INCLUI
			TIVINCLUSAO(aFiliais)
			// Atualiza BZ_ZCARTRB, conforme aliquota encontrada para linha. // LUCAS - MAIS :: 12/01/22
			FAtuCarT() 
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			//>-Antonio Mateus - Chamada do programa para inclusão de informações complementares do produto na tabela ZB1.			 |
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			// -->Lucas :: 17/03/21 - Verifica se a execução é via rotina automatica, se sim nao apresenta mensagem.
			//Lutchen - 29/12/2022 - Colocando no botão confirmar pois vai ser obrigatório para alguns tipos de produtos e não pode ser após a inclulsão.
			/*If !l010Auto 
				If MsgYesNo(OemToAnsi("Deseja Incluir Informações Complementares do Produto? S/N? "),OemToAnsi("MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Manutenção de Produtos!"))
					U_TIVRO103()
				EndIf
			End If*/
			// <--Lucas :: 17/03/21 - Verifica se a execução é via rotina automatica, se sim nao apresenta mensagem.
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			//<-Antonio Mateus - Chamada do programa para inclusão de informações complementares do produto na tabela ZB1.			 |
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
		EndIf
		If ALTERA
			TIVALTERACAO(aFiliais)
		EndIf

		//-- Ltn - 21/03/2023 - Incluí codigo de beneficio para o produto automaticamente para as filiais de pinhais e toledo.
		If Inclui .And. AllTrim(M->B1_TIPO) == 'PA'
			
			If  (substr(M->B1_GRUPO,1,2) == '12') .OR. ; //--Aves
				(substr(M->B1_GRUPO,1,2) == '14') .OR. ; //--Suínos
				(M->B1_GRUPO >= '1501' .AND. M->B1_GRUPO <= '1504') .OR. ; //--Peixes
				(substr(M->B1_GRUPO,1,2) == '13')       //--Ruminantes


				StartJob("U_PIFIS140",GetEnvServer(),.T.,"01","010020",M->B1_COD) //--Incluí código de benefício pinhais
				StartJob("U_PIFIS140",GetEnvServer(),.T.,"01","010025",M->B1_COD) //--Incluí código de benefício toledo.

			EndIf
		EndIf

	EndIf
	If ParamIXB[2] == "MODELCOMMITNTTS"
	    If !l010Auto 

			oObj 	 	:= aParam[1]
			nOpc 		:= oObj:GetOperation()
			
			Public lRep_Altzb1 := .T.

			If nOpc == 3
				lRet := U_MCESTP01('I')
				If lRet
					MsgStop("Não foi possivel incluir o registro entre filiais!")
				End If
			End IF
			If nOpc == 4 
				lRet := U_MCESTP01('A')	
				If lRet
					MsgStop("Não foi possivel alterar o registro entre filiais!")
				End If	
			End If
			If nOpc == 5 
				lRet := U_MCESTP01('E')		
				If lRet
					MsgStop("Não foi possivel excluir o registro na filial correspondente pois o mesmo já possui movimentação!")
				End If
			End 

		Else

			//--Lutchen - 30/06/2023 - Ajuste para incluir registro entre filiais.
			oObj 	 	:= aParam[1]
			nOpc 		:= oObj:GetOperation()

			If nOpc == 3
				lRet := U_MCESTP01('I')
				If lRet
					//MsgStop("Não foi possivel incluir o registro entre filiais!")
				End If
			End IF
		
		End If
	End If

			// Lucas - MAIS :: 16/09/2021 - Valida no TOK, se o codigo+loja nao existem na outra filial...
		If ParamIXB[2] == "FORMPOS"

			If INCLUI .OR. ALTERA
				
				//Lutchen Oliveira - 30/12/2022 - Incluir validação no cadastro de produto para controle obrigatório de Rastro e Endereçamento quanto tipo do produto igual a MP, PA, RV, BN.
				If M->B1_TIPO $ "MP/PA/RV/BN"
					If (M->B1_LOCALIZ != 'S' .or. (M->B1_RASTRO != 'S'.and. M->B1_RASTRO != 'L')) 
						//MsgStop("Controle obrigatório de Rastro e Endereçamento quanto tipo do produto igual a MP, PA, RV, BN.")
						Help(NIL, NIL, "RASTRO/ENDE", NIL, "Controle Rastro/endereçamento", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Controle obrigatório de Rastro e Endereçamento quanto tipo do produto igual a MP, PA, RV, BN."})
						Return(.F.)
					EndIf
				EndIf
				
			EndIf

			If INCLUI// Se for inclusão
				If !l010Auto // Nao é rotina automatica
					If !FVldCod() // Se ja existir o codigo+loja na filial fabrica ou fox, aborta
						//MsgStop("Atenção! Codigo ja existe na filial "+IIf("09"$cFilAnt,"FOX","Vaccinar")+" não é posssivel confirmar a inclusão!")
						Help(NIL, NIL, "REGEXIST", NIL, "Erro registro existente", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Atenção! Codigo ja existe na filial "+IIf("09"$cFilAnt,"FOX","Vaccinar")+" não é posssivel confirmar a inclusão!"})
						Return .F.
					End If
				End If
				If !fVldLotRas() //- -17/12/2021 - Wemerson Souza -- Valida Obrigatoriedade de controel de Lote e Endereço para produtos tipo PA e MP
					Return(.F.)
				EndIf

				If !l010Auto

					//-- LUtchen Oliveira - 29/12/2022 - torna o preenchimento obrigatório da tabela ZB1 quando o produto for PA ou BN.
					ZB1->(dbSetOrder(1))
					If !ZB1->(dbSeek(xFilial("ZB1")+M->B1_COD))
						If MsgYesNo(OemToAnsi("Deseja Incluir Informações Complementares do Produto? S/N? "),OemToAnsi("MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Manutenção de Produtos!"))
							U_TIVRO103()							
							//--Verifico se realmente foi incluído.
							ZB1->(dbSetOrder(1))
							If !ZB1->(dbSeek(xFilial("ZB1")+M->B1_COD))
								If M->B1_TIPO $ "BN/PA"
									//MsgStop("Obrigatório preenchimento das informações complementares do produto para os produtos do tipo PA e BN!")
									Help(NIL, NIL, "CAD_COMPL", NIL, "Erro cadastro complementar", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Obrigatório preenchimento das informações complementares do produto para os produtos do tipo PA e BN!"})
									Return(.F.)
								EndIf
							EndIf
						Else
							If M->B1_TIPO $ "BN/PA"
								//MsgStop("Obrigatório preenchimento das informações complementares do produto para os produtos do tipo PA e BN!")
								Help(NIL, NIL, "CAD_COMPL", NIL, "Erro cadastro complementar", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Obrigatório preenchimento das informações complementares do produto para os produtos do tipo PA e BN!"})
								Return(.F.)
							EndIf
						EndIf
					EndIf

				EndIf

			EndIf


		EndIf
	
	RestArea(aArea)
Return(xRet)

/*------------------------------------------------------------------------------*\
|Função: TIVINCLUSAO
|Descrição: Função que substituiu a MT010INC() e faz os tratamentos de inclusão
|de produtos
|Data: 31/01/2019
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:
|-------------------------------------------------------------------------------->
|Alterado por: Rodrigo Prates		Data: 13/11/2012
|Descrição: Função que insere registro daquele produto na tabela SBZ (Indicadores
|de Produto) para todas as filiais cadastradas.
|-------------------------------------------------------------------------------->
|Alterado por: Leonardo Perrella	Data: 20/09/2017
|Descrição: Adicionado tratamento na query para o campo BZ_ZPRODPI receber a
|informação do B1_ZPRODPI
|-------------------------------------------------------------------------------->
|Alterado por: Rodrigo Prates		Data: 22/05/2018
|Descrição: A função ApMsgAlert() teve o 2o parametro (título da janela) alterado
|para se encaixar no padrão desenvolvido pela T.I. Vaccinar:
|"<Função Principal> - " + AllTrim(Str(ProcLine(0))) + " - <Nome no Menu>"
|-------------------------------------------------------------------------------->
|Alterado por: Igor Rabelo			Data: 30/05/2018
|Descrição: Criado processo de efetivaçaõd e Pré-Produto gravando dados na SZA.
|-------------------------------------------------------------------------------->
|Alterado por: Rodrigo Prates		Data: 15/11/2018
|Descrição: A criação do indicador de produtos (SBZ) e complemento de produtos
|(SB5) agora são executados somente se o produto que esta sendo incluído estiver
|com a liberação de tela == Sim (a SB5 ainda tem a validação de controle de
|rastro do produto). Foi inserida a chamada da função TIVZB1() que gerencia a
|criação/alteração de registros na tabela ZB1 (Campos Customizados de Produto).
|Toda a criação de registros na SBZ foi excluido da MT010INC() e viraram a função
|TIVINCBZ() com modificador de acesso User, pois ela também é chamada do P.E.
|MT010ALT.
|-------------------------------------------------------------------------------->
|Alterado por: Rodrigo Prates		Data: 25/02/2019
|Descrição: O calculo do novo R_E_C_N_O_ levava em consideração a filial, mas
|esse numero é unico por tabela.
|-------------------------------------------------------------------------------->
|Alterado por: Dayvid Nogueira		Data: 08/07/2020
|Descrição: Adicionado validação na gravação do codigo Produto no cadastro    
|do Pre-produto para seja gravado somente se o campo estiver vazio.      
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira 	Data: 02/12/2022
|Descrição: Alterado para incluir ZB1 quando status for liberado.
|-------------------------------------------------------------------------------->
|Alterado por:		Data:   /  /
|Descrição:
\*------------------------------------------------------------------------------*/
Static Function TIVINCLUSAO(aFiliais)
	TIVLOGINC()
	//If !Empty(SB1->B1_ZSTATUS) .And. SB1->B1_ZSTATUS <> "1"
	If !Empty(SB1->B1_ZSTATUS) .And. SB1->B1_ZSTATUS == "3"
		TIVZB1()
	Else
		If type("lRep_Altzb1") <> 'U'
			lRep_Altzb1 := .F.
		EndIf
	EndIf
	If SB1->B1_MSBLQL == "2"
		TIVINCBZ(aFiliais)
		If SB1->B1_RASTRO == "L" //->Helder Santos - criado função que, após incluir produto sistema deve criar o complemento do produto em todas as filiais
			TIVINCB5(aFiliais)
		EndIf
	EndIf
	If !Empty(SB1->B1_ZPREPRD) //-- IR -- Se tiver Pré-produto amarrado. Grava efetivação na SZA (Pré-Produto)
		SZA->(dbSetOrder(1))
		If SZA->(dbSeek(xFilial("SZA") + SB1->B1_ZPREPRD))
			If Empty(SZA->ZA_PRDEFET) //Dayvid Nogueira - 08/07/2020 Inclusão da Validação para incluir o Codigo do produto somente se o campo estiver vazio.
				Reclock("SZA",.F.)
				Replace SZA->ZA_PRDEFET With SB1->B1_COD
				Replace SZA->ZA_DTEFETI With dDataBase
				SZA->(MsUnLock())
			EndIF
		EndIf
	EndIf
Return()

/*------------------------------------------------------------------------------*\
|Função: TIVLOGINC
|Descrição: Função grava a data e a hora da alteração do produto
|Data: 22/11/2012
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:
|-------------------------------------------------------------------------------->
|Alterado por:		Data:   /  /
|Descrição:
\*------------------------------------------------------------------------------*/
Static Function TIVLOGINC()
	If RecLock("SB1",.F.)
		Replace SB1->B1_ZDTINC	With dDataBase
		Replace SB1->B1_ZHRINC	With Time()
		MsUnlock()
	EndIf
Return()

/*------------------------------------------------------------------------------*\
|Função: TIVZB1
|Descrição: Função que gerencia a criação (TIVINCZB1())/alteração (TIVALTZB1())
|de registros da ZB1
|Data: 15/11/2018
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira 	Data: 02/12/2022
|Descrição: Se for alteração verifica se status já não foi preenchido.
|			Caso esteja vazio altera ZB1 preenchendo os campos de status.
|-------------------------------------------------------------------------------->
|Alterado por:		Data:   /  /
|Descrição:
\*------------------------------------------------------------------------------*/
Static Function TIVZB1()
	If Empty(Posicione("ZB1",1,xFilial("ZB1") + SB1->B1_COD,"ZB1_COD"))
		TIVINCZB1()
	Else
		If type("lRep_Altzb1") <> 'U'
			If lRep_Altzb1 
				ALTZB1()
				lRep_Altzb1 := .F.
			EndIf
		EndIf
	EndIf

	//ElseIf SB1->B1_ZSTATUS <> M->B1_ZSTATUS
	If Empty(ZB1->ZB1_USSTAT)
		TIVALTZB1()
	EndIf
Return()

/*------------------------------------------------------------------------------*\
|Função: TIVINCZB1
|Descrição: Função que faz a criação de um registro relacionado ao produto que
|esta sendo incluido/alterado (via MT010ALT) naquele momento, na ZB1 (Campos
|Customizados de Produto), referente ao log do status de liberação/bloqueio/
|pendencia
|Data: 15/11/2018
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:
|-------------------------------------------------------------------------------->
|Alterado por: Rodrigo Prates		Data: 25/02/2019
|Descrição: O calculo do novo R_E_C_N_O_ levava em consideração a filial, mas
|esse numero é unico por tabela. Na conversão de SYSDATE, a sigla de minutos foi
|alterada de MM (Mês) para MI (Minuto)
|-------------------------------------------------------------------------------->
|Alterado por: Antonio Mateus		Data: 25/06/2020
|Descrição: Adicionado o campo ZB1_PRDCUS à query de inserção de registros na 
|tabela ZB1. 
|-------------------------------------------------------------------------------->
|Alterado por: Dayvid Nogueira		Data:  27/11/2020
|Descrição: Inserido os campos definidos na Expressão SQL para não ocorrer erro 
|com Inclusão de novos campos na tabela ZB1, para atender o chamado 
|Ticket#2020112507000758.
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira		Data:  01/12/2022
|Descrição: Adicionada tratativa para replicação de cadastro entre FOX e Fabrica
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira		Data:  24/04/2023
|Descrição: Retirando tratativa para replicação de cadastro entre FOX e Fabrica,
|pois ja esta fazendo no fonte MCESTP01 chama esse execauto de produto novamente.
|Colocando campos dinamicamente para não precisar alterar a função caso insira
|mais campos na tabela.
@history 09/06/2023, Antonio Daniel, MC02 - verifica o tipo do campo para diferenciar entre tipo numérico dos demais.

\*------------------------------------------------------------------------------*/
Static Function TIVINCZB1()
	Local cQuery 	:= ""
	Local nRet	 	:= 0
	Local nX 		:= 0 
	Local NY 		:= 0
	Local cFilErro 	:= ""
	Local a_Emp 	:= {}//{"01","09"}
	Local cFilPar	:= SuperGetMv("MC_FCADFAB",.F.,"")
	Local ASTRU 	:= ZB1->(DBSTRUCT())
	Local cDescon 	:= "ZB1_FILIAL|ZB1_COD|ZB1_DTSTAT|ZB1_HRSTAT|ZB1_USSTAT|D_E_L_E_T_|R_E_C_N_O_|R_E_C_D_E_L_"
	//--Se não for Fox ou Fabrica só cria na empresa corrente.
	//If !(substr(cFilAnt,1,2) $ "01|09")
		a_Emp := {substr(cFilAnt,1,2)}
	//EndIf

	For nX := 1 to Len(a_Emp)

		cQuery := "INSERT INTO " + RetSqlName("ZB1") + Chr(13) + Chr(10)
		//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
		//>-Dayvid Nogueira - Inserido os campos definidos na Expressão SQL para não ocorrer erro com Inclusão de novos campos na tabela ZB1.|
		//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
		cQuery += "(ZB1_FILIAL," + Chr(13) + Chr(10)
		cQuery += "ZB1_COD," + Chr(13) + Chr(10)
		cQuery += "ZB1_DTSTAT," + Chr(13) + Chr(10)
		cQuery += "ZB1_HRSTAT," + Chr(13) + Chr(10)
		cQuery += "ZB1_USSTAT," + Chr(13) + Chr(10)
		cQuery += "D_E_L_E_T_," + Chr(13) + Chr(10)
		cQuery += "R_E_C_N_O_," + Chr(13) + Chr(10)
		cQuery += "R_E_C_D_E_L_," + Chr(13) + Chr(10)
		//cQuery += "ZB1_PRDCUS"
		For NY := 1 to Len(aStru)
			If !(aStru[NY][1] $ cDescon )
				cQuery += aStru[NY][1]+","
			EndIf
		Next NY
		cQuery := Substr(cQuery,1,len(cQuery)-1)
		cQuery += ")" + Chr(13) + Chr(10)
		//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
		//>-Dayvid Nogueira - Inserido os campos definidos na Expressão SQL para não ocorrer erro com Inclusão de novos campos na tabela ZB1.|
		//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|	
		cQuery += "VALUES" + Chr(13) + Chr(10)
		//cQuery += "('" + xFilial("ZB1") + "'," + Chr(13) + Chr(10) //ZB1_FILIAL
		cQuery += "('" + a_Emp[nX] + "'," + Chr(13) + Chr(10) //ZB1_FILIAL
		cQuery += "'" + SB1->B1_COD + "'," + Chr(13) + Chr(10) //ZB1_COD
		cQuery += "TO_CHAR(SYSDATE,'YYYYMMDD')," + Chr(13) + Chr(10) //ZB1_DTSTAT
		cQuery += "TO_CHAR(SYSDATE,'HH24:MI:SS')," + Chr(13) + Chr(10) //ZB1_HRSTAT
		cQuery += "'" + StrTran(AllTrim(UsrFullName(RetCodUsr())),".","") + "'," + Chr(13) + Chr(10) //ZB1_USSTAT
		cQuery += "' '," + Chr(13) + Chr(10) //D_E_L_E_T_
		cQuery += "(SELECT NVL(MAX(R_E_C_N_O_),0) + 1 FROM " + RetSqlName("ZB1") + ")," + Chr(13) + Chr(10) //R_E_C_N_O_
		cQuery += "0," + Chr(13) + Chr(10) //R_E_C_D_E_L_
		//cQuery += "' '"
		ZB1->(dbSetOrder(1))		
		If ZB1->(dbseek(AVKEY(SUBSTR(cFilPar,1,2),"ZB1_FILIAL")+SB1->B1_COD )) //Se encontar na outra filial busca as informações dos campos e replica.
			For NY := 1 to Len(aStru)
				If !(aStru[NY][1] $ cDescon ) .And. GetSx3Cache(aStru[NY][1],"X3_TIPO") == 'N' //MC02
					cQuery += "'"+cValToChar(ZB1->&(aStru[NY][1]))+"'," //MC02
				ElseIf !(aStru[NY][1] $ cDescon )
					cQuery += "'"+ZB1->&(aStru[NY][1])+"',"					
				EndIf
			Next NY
		Else
			For NY := 1 to Len(aStru)
				If !(aStru[NY][1] $ cDescon ) .And. GetSx3Cache(aStru[NY][1],"X3_TIPO") == 'N' //MC02
					cQuery += "'"+cValToChar(CriaVar(aStru[NY][1]))+"'," //MC02
				ElseIf !(aStru[NY][1] $ cDescon )
					cQuery += "'"+CriaVar(aStru[NY][1])+"',"
				EndIf
			Next NY
		EndIf
		cQuery := Substr(cQuery,1,len(cQuery)-1)
		cQuery += ")" + Chr(13) + Chr(10) 
		nRet := TcSqlExec(cQuery) //Executa a query de intervenção no banco
		If nRet < 0 //Valores abaixo de 0 indicam erro na execução da query
			cFilErro += a_Emp[nX] + ", "
		EndIf
	Next nX

	If !Empty(cFilErro) //Caso tenha ocorrido algum erro...
		cFilErro := SubStr(cFilErro,1,Len(cFilErro) - 2)

		ApMsgStop(OemToAnsi("Não foi possivel criar registro do produto " + AllTrim(SB1->B1_COD) + " - " + AllTrim(SB1->B1_DESC) + " na tabela 'Campos Customizados de Produto' nas empresas" + cFilErro + ". " +;
				"Favor entrar em contato com o T.I."),OemToAnsi("MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Manutenção de Produtos!"))
	EndIf

Return()

/*------------------------------------------------------------------------------*\
|Função: ALTZB1
|Descrição: Função que faz a alteração de um registro relacionado ao produto que
|esta sendo alterado (via MT010ALT) naquele momento, na ZB1 (Campos
|Customizados de Produto), referente ao log do status de liberação/bloqueio/
|pendencia
|Data: 15/11/2018
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:
@history 07/06/2023, Antonio Daniel, MC01 - verifica o tipo do campo para diferenciar entre tipo numérico dos demais.
|--------------------------------------------------------------------------------*/
Static Function ALTZB1()

	Local aArea := ZB1->(GETAREA())
	Local cQuery 	:= ""
	Local nRet	 	:= 0
	Local nx 	 	:= 0
	Local nY 		:= 0
	Local cFilErro := ""
	Local a_Emp 	:= {}//{"01","09"}
	Local cDescon 	:= "ZB1_FILIAL|ZB1_COD|ZB1_DTSTAT|ZB1_HRSTAT|ZB1_USSTAT|D_E_L_E_T_|R_E_C_N_O_|R_E_C_D_E_L_"
	Local cFilPar	:= SuperGetMv("MC_FCADFAB",.F.,"")
	Local ASTRU 	:= ZB1->(DBSTRUCT())
	

	a_Emp := {substr(cFilAnt,1,2)}


	For nX := 1 to Len(a_Emp)


		ZB1->(dbSetOrder(1))		
		If ZB1->(dbseek(AVKEY(SUBSTR(cFilPar,1,2),"ZB1_FILIAL")+SB1->B1_COD )) 

			cQuery := "UPDATE " + RetSqlName("ZB1") + Chr(13) + Chr(10)
			cQuery += "SET "

			For NY := 1 to Len(aStru)
				If !(aStru[NY][1] $ cDescon )
					// MC01 - Verifica o tipo do campo
					If GetSx3Cache(aStru[NY][1],"X3_TIPO") == 'N'
						cQuery += aStru[NY][1]+" = "+Transform(ZB1->&(aStru[NY][1]),'@9')+","					
					Else
						cQuery += aStru[NY][1]+" = '"+ZB1->&(aStru[NY][1])+"',"					
					EndIf
				EndIf
			Next NY
			cQuery := Substr(cQuery,1,len(cQuery)-1)

			/*" ZB1_DTSTAT = TO_CHAR(SYSDATE,'YYYYMMDD')," + Chr(13) + Chr(10)
			cQuery += "ZB1_HRSTAT = TO_CHAR(SYSDATE,'HH24:MI:SS')," + Chr(13) + Chr(10)
			cQuery += "ZB1_USSTAT = '" + StrTran(AllTrim(UsrFullName(RetCodUsr())),".","") + "'" + Chr(13) + Chr(10)*/
			//cQuery += "WHERE D_E_L_E_T_ <> '*' AND ZB1_FILIAL = '" + xFilial("ZB1") + "'" + Chr(13) + Chr(10)
			cQuery += "WHERE D_E_L_E_T_ <> '*' AND ZB1_FILIAL = '" + a_Emp[nX] + "'" + Chr(13) + Chr(10)
			cQuery += "AND ZB1_COD = '" + SB1->B1_COD + "'" + Chr(13) + Chr(10)
			nRet := TcSqlExec(cQuery) //Executa a query de intervenção no banco
			If nRet < 0 //Valores abaixo de 0 indicam erro na execução da query
				cFilErro += a_Emp[nX] + ", "
			EndIf

		EndIf
	Next nX

	If !Empty(cFilErro) //Caso tenha ocorrido algum erro...
		cFilErro := SubStr(cFilErro,1,Len(cFilErro) - 2)

		ApMsgStop(OemToAnsi("Não foi possivel alterar registro do produto " + AllTrim(SB1->B1_COD) + " - " + AllTrim(SB1->B1_DESC) + " na tabela 'Campos Customizados de Produto' nas empresas "+cFilErro+". "+;
							"Favor entrar em contato com o T.I."),OemToAnsi("MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Manutenção de Produtos!"))
	EndIf

	RestArea(aArea)
	
Return()

/*------------------------------------------------------------------------------*\
|Função: TIVALTZB1
|Descrição: Função que faz a alteração de um registro relacionado ao produto que
|esta sendo incluido/alterado (via MT010ALT) naquele momento, na ZB1 ((Campos
|Customizados de Produto), referente ao log do status de liberação/bloqueio/
|pendencia
|Data: 15/11/2018
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:
|-------------------------------------------------------------------------------->
|Alterado por: Rodrigo Prates		Data: 25/02/2019
|Descrição: Na conversão de SYSDATE, a sigla de minutos foi alterada de MM (Mês)
|para MI (Minuto)
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira		Data:  01/12/2022
|Descrição: Adicionada tratativa para replicação de cadastro entre FOX e Fabrica
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira		Data:  24/04/2023
|Descrição: Retirando tratativa para replicação de cadastro entre FOX e Fabrica,
|pois ja esta fazendo no fonte MCESTP01 chama esse execauto de produto novamente.
\*------------------------------------------------------------------------------*/
Static Function TIVALTZB1()
	Local cQuery := ""
	Local nRet	 := 0
	Local nx 	 := 0
	Local cFilErro := ""
	Local a_Emp := {}//{"01","09"}

	//--Se não for Fox ou Fabrica só cria na empresa corrente.
	//If !(substr(cFilAnt,1,2) $ "01|09")
		a_Emp := {substr(cFilAnt,1,2)}
	//EndIf

	For nX := 1 to Len(a_Emp)

		cQuery := "UPDATE " + RetSqlName("ZB1") + Chr(13) + Chr(10)
		cQuery += "SET ZB1_DTSTAT = TO_CHAR(SYSDATE,'YYYYMMDD')," + Chr(13) + Chr(10)
		cQuery += "ZB1_HRSTAT = TO_CHAR(SYSDATE,'HH24:MI:SS')," + Chr(13) + Chr(10)
		cQuery += "ZB1_USSTAT = '" + StrTran(AllTrim(UsrFullName(RetCodUsr())),".","") + "'" + Chr(13) + Chr(10)
		//cQuery += "WHERE D_E_L_E_T_ <> '*' AND ZB1_FILIAL = '" + xFilial("ZB1") + "'" + Chr(13) + Chr(10)
		cQuery += "WHERE D_E_L_E_T_ <> '*' AND ZB1_FILIAL = '" + a_Emp[nX] + "'" + Chr(13) + Chr(10)
		cQuery += "AND ZB1_COD = '" + SB1->B1_COD + "'" + Chr(13) + Chr(10)
		nRet := TcSqlExec(cQuery) //Executa a query de intervenção no banco
		If nRet < 0 //Valores abaixo de 0 indicam erro na execução da query
			cFilErro += a_Emp[nX] + ", "
		EndIf
	Next nX

	If !Empty(cFilErro) //Caso tenha ocorrido algum erro...
		cFilErro := SubStr(cFilErro,1,Len(cFilErro) - 2)

		ApMsgStop(OemToAnsi("Não foi possivel alterar registro do produto " + AllTrim(SB1->B1_COD) + " - " + AllTrim(SB1->B1_DESC) + " na tabela 'Campos Customizados de Produto' nas empresas "+cFilErro+". "+;
							"Favor entrar em contato com o T.I."),OemToAnsi("MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Manutenção de Produtos!"))
	EndIf
Return()

/*------------------------------------------------------------------------------*\
|Função: TIVINCBZ
|Descrição: Função criada com o INSERT da SBZ, que antes fazia parte da MT010INC
|inserindo em todas as filiais daquela empresa, os indicadores do produto que
|esta sendo cadastrado naquele momento
|Data: 15/11/2018
|Responsavel: Rodrigo Prates
|Parametro:	aFiliais	Array contendo as filiais que deverão ter a SBZ criada para o produto cadastrado
|Retorno:
|-------------------------------------------------------------------------------->
|Alterado por:		Data:   /  /
|Descrição:
\*------------------------------------------------------------------------------*/
Static Function TIVINCBZ(aFiliais)
	Local cQuery   := ""
    Local cFilErro := ""
	Local xI	   := 0
	Local nReg	   := 0 //Variavel que recebe o retorno da execução da query de INSERT
	//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
	//->Rodrigo Prates - Momento em que é incluido o registro em todas as filiais cadastradas								 |
	//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
	BeginTran()
		For xI := 1 To Len(aFiliais)
			cQuery := "INSERT INTO " + RetSqlName("SBZ") + "" + Chr(13) + Chr(10)
			cQuery += "(BZ_FILIAL," + Chr(13) + Chr(10)
			cQuery += "BZ_COD," + Chr(13) + Chr(10)
			cQuery += "BZ_LOCPAD," + Chr(13) + Chr(10)
			cQuery += "BZ_ZDESC," + Chr(13) + Chr(10)
			cQuery += "BZ_TE," + Chr(13) + Chr(10)
			cQuery += "BZ_TS," + Chr(13) + Chr(10)
			cQuery += "BZ_QE," + Chr(13) + Chr(10)
			cQuery += "BZ_EMIN," + Chr(13) + Chr(10)
			cQuery += "BZ_CUSTD," + Chr(13) + Chr(10)
			cQuery += "BZ_UCALSTD," + Chr(13) + Chr(10)
			cQuery += "BZ_MCUSTD," + Chr(13) + Chr(10)
			cQuery += "BZ_UCOM," + Chr(13) + Chr(10)
			cQuery += "BZ_ESTSEG," + Chr(13) + Chr(10)
			cQuery += "BZ_ESTFOR," + Chr(13) + Chr(10)
			cQuery += "BZ_FORPRZ," + Chr(13) + Chr(10)
			cQuery += "BZ_PE," + Chr(13) + Chr(10)
			cQuery += "BZ_TIPE," + Chr(13) + Chr(10)
			cQuery += "BZ_LE," + Chr(13) + Chr(10)
			cQuery += "BZ_LM," + Chr(13) + Chr(10)
			cQuery += "BZ_TOLER," + Chr(13) + Chr(10)
			cQuery += "BZ_ORIGEM," + Chr(13) + Chr(10)
			cQuery += "BZ_GRTRIB," + Chr(13) + Chr(10)
			cQuery += "BZ_MRP," + Chr(13) + Chr(10)
			cQuery += "BZ_CODISS," + Chr(13) + Chr(10)
			cQuery += "BZ_FANTASM," + Chr(13) + Chr(10)
			cQuery += "BZ_TIPOCQ," + Chr(13) + Chr(10)
			cQuery += "BZ_PIS," + Chr(13) + Chr(10)
			cQuery += "BZ_COFINS," + Chr(13) + Chr(10)
			cQuery += "BZ_CSLL," + Chr(13) + Chr(10)
			cQuery += "BZ_ZGRUP," + Chr(13) + Chr(10)
			cQuery += "BZ_ZTMIST," + Chr(13) + Chr(10)
			cQuery += "BZ_ZBLQCAL," + Chr(13) + Chr(10)
			cQuery += "BZ_ZPESOSC," + Chr(13) + Chr(10)
			cQuery += "BZ_ZPRODPI," + Chr(13) + Chr(10)
			cQuery += "BZ_LOCALIZ," + Chr(13) + Chr(10)
			cQuery += "R_E_C_N_O_)" + Chr(13) + Chr(10)
			cQuery += "VALUES" + Chr(13) + Chr(10)
			cQuery += "('" + aFiliais[xI] + "'," + Chr(13) + Chr(10)
			cQuery += "'" + SB1->B1_COD + "'," + Chr(13) + Chr(10) //Codigo do produto
			cQuery += "'" + SB1->B1_LOCPAD + "'," + Chr(13) + Chr(10) //Codigo do armazem padrão
			cQuery += "'" + SB1->B1_DESC + "'," + Chr(13) + Chr(10) //Descrição do produto
			cQuery += "'" + SB1->B1_TE + "'," + Chr(13) + Chr(10) //Codigo da TES de entrada padrão daquele produto
			cQuery += "'" + SB1->B1_TS + "'," + Chr(13) + Chr(10) //Codigo da TES de saida padrão daquele produto
			cQuery += "" + AllTrim(Str(SB1->B1_QE)) + "," + Chr(13) + Chr(10) //Quantidade por embalagem
			cQuery += "" + AllTrim(Str(SB1->B1_EMIN)) + "," + Chr(13) + Chr(10) //Ponto de pedido
			cQuery += "" + AllTrim(Str(SB1->B1_CUSTD)) + "," + Chr(13) + Chr(10) //Custo Standard
			cQuery += "'" + DtoS(SB1->B1_UCALSTD) + "'," + Chr(13) + Chr(10) //Data do ultimo calculo do Custo Standard
			cQuery += "'" + SB1->B1_MCUSTD + "'," + Chr(13) + Chr(10) //Moeda do Custo Standard
			cQuery += "'" + DtoS(SB1->B1_UCOM) + "'," + Chr(13) + Chr(10) //Data da ultima compra
			cQuery += "" + AllTrim(Str(SB1->B1_ESTSEG)) + "," + Chr(13) + Chr(10) //Estoque de segurança
			cQuery += "'" + SB1->B1_ESTFOR + "'," + Chr(13) + Chr(10) //Formula do estoque de segurança
			cQuery += "'" + SB1->B1_FORPRZ + "'," + Chr(13) + Chr(10) //Formula de calculo do prazo de entrega
			cQuery += "" + AllTrim(Str(SB1->B1_PE)) + "," + Chr(13) + Chr(10) //Prazo de entrega
			cQuery += "'" + SB1->B1_TIPE + "'," + Chr(13) + Chr(10) //Tipo do prazo de entrega
			cQuery += "" + AllTrim(Str(SB1->B1_LE)) + "," + Chr(13) + Chr(10) //Lote economico
			cQuery += "" + AllTrim(Str(SB1->B1_LM)) + "," + Chr(13) + Chr(10) //Lote minimo
			cQuery += "" + AllTrim(Str(SB1->B1_TOLER)) + "," + Chr(13) + Chr(10) //Tolerancia
			cQuery += "'" + SB1->B1_ORIGEM + "'," + Chr(13) + Chr(10) //Origem do produto
			cQuery += "'" + SB1->B1_GRTRIB + "'," + Chr(13) + Chr(10) //Grupo de tributação
			cQuery += "'" + SB1->B1_MRP + "'," + Chr(13) + Chr(10) //Indica se o produto entra para o calculo do MRP
			cQuery += "'" + SubStr(SB1->B1_CODISS,1,8) + "'," + Chr(13) + Chr(10) //Codigo de serviço do ISS
			cQuery += "'" + SB1->B1_FANTASM + "'," + Chr(13) + Chr(10) //Informa "S" se é fantasma
			If SB1->B1_TIPO == "MP" .And. aFiliais[xI] $ GetMV("TIV_SIGAQTY") //->Leonardo Perrella - Adicionado parametro TIV_SIGAQTY para considerar apenas as filias que serão gravados o Tipo CQ = "Q"
				cQuery += "'Q'," + Chr(13) + Chr(10)
			Else
				cQuery += "'M'," + Chr(13) + Chr(10)
			EndIf
			cQuery += "'2'," + Chr(13) + Chr(10)
			cQuery += "'2'," + Chr(13) + Chr(10)
			cQuery += "'2'," + Chr(13) + Chr(10)
			If SubStr(SB1->B1_COD,1,1) == "0"
				cQuery += "'001'," + Chr(13) + Chr(10)
			Else
				cQuery += "'000'," + Chr(13) + Chr(10)
			EndIf
			cQuery += "'" + AllTrim(Posicione("SX3",2,"BZ_ZTMIST","X3_RELACAO")) + "'," + Chr(13) + Chr(10)
			cQuery += "'1'," + Chr(13) + Chr(10)
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			//->Leonardo Perrella - Preenche o campo sacaria caso no cadastro o produto contiver a 1 UM KG a SEGUM SC o fator de	 |
			//conversao preenchido, cantrolar lote e endereço.																		 |
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			
			//-- Lutchen- preenche o campo sacaria quando primeira ou segunda UM tiver preenchida com SC.
			//If SB1->B1_UM == "KG" .And. SB1->B1_SEGUM == "SC" .And. SB1->B1_RASTRO == "L" .And. SB1->B1_LOCALIZ == "S"			
			If ((SB1->B1_UM == "KG" .And. SB1->B1_SEGUM == "SC") .or. (SB1->B1_UM == "SC" .And. SB1->B1_SEGUM == "KG")) .And. SB1->B1_RASTRO == "L" .And. SB1->B1_LOCALIZ == "S"
				cQuery += "'" + Str(SB1->B1_CONV) + "'," + Chr(13) + Chr(10) //Fator de Conversao
			Else
				cQuery += "0," + Chr(13) + Chr(10)
			EndIf
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			//<-Leonardo Perrella - Preenche o campo sacaria caso no cadastro o produto contiver a 1 UM KG a SEGUM SC o fator de	 |
			//conversao preenchido, cantrolar lote e endereço.																		 |
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			cQuery += "'" + SB1->B1_ZPRODPI + "'," + Chr(13) + Chr(10) //Campo com informaçao de comprado ou produzido //->Leonardo Perrella - Preenche o campo que define se o produto foi comprado ou produzido.
			cQuery += "'" + SB1->B1_LOCALIZ + "'," + Chr(13) + Chr(10) //Controle de Endereço
			cQuery += "(SELECT MAX(R_E_C_N_O_) + 1 FROM " + RetSqlName("SBZ") + " BZ))" + Chr(13) + Chr(10)
			nReg := TcSqlExec(cQuery) //Executa a query de intervenção no banco
			If nReg < 0 //Valores abaixo de 0 indicam erro na execução da query
				cFilErro += aFiliais[xI] + ", "
			EndIf
		Next xI
		If !Empty(cFilErro) //Caso tenha ocorrido algum erro...
			cFilErro := SubStr(cFilErro,1,Len(cFilErro) - 2)
			ApMsgAlert(OemToAnsi("Problema durante a criação dos Indicadores de Produto para o produto '" + AllTrim(SB1->B1_COD) + "' nas filiais " + cFilErro + ". " +;
								 "Favor entrar em contato com o Setor de TI."),;
					   OemToAnsi("MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Manutenção de Produtos!"))
			DisarmTransaction() //Da rollback em todas as inclusões ja feitas durante aquela execução
			Return()
		EndIf
	EndTran()
	//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
	//<-Rodrigo Prates - Momento em que é incluido o registro em todas as filiais cadastradas								 |
	//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
Return()

//------------------------------------------------------------------
/*/{Protheus.doc} TIVINCB5

Função utilizada incluir complemento do produto, tabela SB5

@author 	Helder Santos
@since 		06/08/2013
@version 	P11
@obs
Projeto

Alteracoes Realizadas desde a Estruturacao Inicial
Data		Programador			Motivo
29/09/2017	Leonardo Perrella	Adicinonado informações padroes nos campos B5_SERVENT, B5_ENDENT e B5_ZMULPL de preenchimento na SB5 quando o
								produto de matéria prima é cadastrado nas filias contidas no parametro DE_FILWMS1.
22/05/2018	Rodrigo Prates		A função ApMsgAlert() teve o 2o parametro (título da janela) alterado para se encaixar no padrão desenvolvido pela T.I.
								Vaccinar: OemToAnsi("<Nome da Função Principal> - " + AllTrim(Str(ProcLine(0))) + " - <Nome da Função no Menu>").
								A variavel cFilErro foi criada para receber o código das filiais que apresentaram problema no execauto. A cFilErro foi
								inserida na mensagem para o usuário
15/11/2018	Rodrigo Prates		O modificador de acesso da função passou a ser User, pois agora ela também é chamada pela MT010ALT(). Uma vez que o produto
								é criado bloqueado, a SBZ e a SB5 não são criadas automaticamente. Somente numa alteração para o desbloqueio desse produto.
								Função mudou de nome (antes era FsCComPro()) pq eu quis. As variaveis cCodProd, cTipo e cDesProd foram excluidas, pois
								simplesmente continham os valores dos campos da SB1, que foram utilizados diretamente na query, e não eram necessárias.
12/04/2023  Lutchen Oliveira    Ao alterar o cadastro do produto alterar também o campo B5_CONVDIP.
							    Este deve ter o peso do produto de acordo com a conversão em KG.
								No campo B5_UMDIPI deve conter 'KG'.								
/*/
//------------------------------------------------------------------
Static Function TIVINCB5(aFiliais)
	Local cFilOk   := ""
    Local cFilErro := ""
    Local xI	   := 0
	Local aCab	   := {}
    Local lRet	   := .T.
    Local cFilAux  := cFilAnt
 	Local aAreaAll := {SB5->(GetArea()),GetArea()}
	Local nPesoKG := 0
    Private lMsErroAuto	   := .F.
    Private lMsHelpAuto	   := .T. //Força a gravação das informações de erro em array ao invés de gravar direto no arquivo temporário
	Private lAutoErrNoFile := .T.
   	Begin Transaction
	    For xI := 1 To Len(aFiliais)
			/*Atualiza variavel global cFilAnt para criar registro na filial correta*/
			cFilAnt := aFiliais[xI]
			/*Verifica se existe complemento para este produto na filial corrente*/
			SB5->(dbSetOrder(1))
			lOpIncAlt := SB5->(dbSeek(cFilAnt + SB1->B1_COD))
			nOpca := IIF(lOpIncAlt,4,3)
			/*Monta estrutura para incluir complemento de produto*/
			aCab := {{"B5_FILIAL",cFilAnt	  ,Nil},;
					 {"B5_COD"	 ,SB1->B1_COD ,Nil},;
					 {"B5_CEME"	 ,SB1->B1_DESC,Nil}}
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			//->Leonardo Perrella - Preenchimento automático campo customizado para filiais que utilizam WMS e tipo MP e que iniciem |
			//com 000 (padrão Vaccinar para materia prima de consumo), para preenchimento padrão do serviço e endereçõ de entrada e  |
			//para regra de um palet por endereço com o conteúdo 1 no campo B5_ZMULPL.												 |
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			If cFilAnt $ GetMv("DE_FILWMS1") .And. SB1->B1_TIPO $ "MP" .And. SubStr(SB1->B1_COD,1,3) == "000"
				AADD(aCab,{"B5_SERVENT","102" ,Nil})
				AADD(aCab,{"B5_ENDENT" ,"DOCA",Nil})
				AADD(aCab,{"B5_ZMULPL" ,"1"	  ,Nil})
			EndIf
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			//<-Leonardo Perrella - Preenchimento automático campo customizado para filiais que utilizam WMS e tipo MP e que iniciem |
			//com 000 (padrão Vaccinar para materia prima de consumo), para preenchimento padrão do serviço e endereçõ de entrada e  |
			//para regra de um palet por endereço com o conteúdo 1 no campo B5_ZMULPL.												 |
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			/*Atualiza variavel de erro*/

			//-- LTN - 12/04/2023 - Ao alterar o cadastro do produto alterar também o campo B5_CONVDIP.
			//                      Este deve ter o peso do produto de acordo com a conversão em KG.
			//                      No campo B5_UMDIPI deve conter 'KG'.
			If SB1->B1_UM == 'KG' .or. SB1->B1_SEGUM == 'KG'
				If SB1->B1_UM == 'KG' 
					nPesoKG := 1
				ElseIf SB1->B1_SEGUM == 'KG'
					nPesoKG := SB1->B1_CONV
				EndIf		
				AADD(aCab,{"B5_CONVDIP" ,nPesoKG	  ,Nil})
				AADD(aCab,{"B5_UMDIPI" ,"KG"	  ,Nil})
			EndIf

			lMsErroAuto := .F.
			/*Executa Execauto rotina complemento de produto*/
			MsExecAuto({|x,y| MATA180(x,y)},aCab,nOpca)
			If lMsErroAuto
 				lRet := .F.
 				cFilErro += cFilAnt + ", "
 			Else
 				cFilOk += cFilAnt + ", "
			EndIf
		Next xI
	End Transaction
	aEval(aAreaAll,{|nLem| RestArea(nLem)}) //Restaura area
	cFilAnt := cFilAux //Atualiza variavel cFilAnt com a filial inicial
	If !lRet
		cFilErro := SubStr(cFilErro,1,Len(cFilErro) - 2)
		ApMsgAlert(OemToAnsi("Problema durante a criação do Complemento do produto '" + AllTrim(SB1->B1_COD) + "' na(s) filial(ais) " + cFilErro + ". " +;
							 "Favor entrar em contato com o Setor de TI."),;
				   OemToAnsi("MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Manutenção de Produtos!"))
	ElseIf ALTERA
		cFilOk := SubStr(cFilOk,1,Len(cFilOk) - 2)
		ApMsgInfo(OemToAnsi("Complemento do produto '" + AllTrim(SB1->B1_COD) + "' incluído nas filiais:" + Chr(13) + Chr(10) + cFilOk + "!"),OemToAnsi("MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Manutenção de Produtos!"))
	EndIf
Return(Nil)

/*------------------------------------------------------------------------------*\
|Função: TIVINCLUSAO
|Descrição: Função que substituiu a MT010ALT() e faz os tratamentos de alteração
|de produtos
|Data: 31/01/2019
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:
|-------------------------------------------------------------------------------->
|Alterado por: Rodrigo Prates		Data: 25/02/2019
|Descrição: A chamada da função de inclusão/alteração da tabela ZB1 não
|considerava a alteração do campo B1_ZSTATUS e, com isso, gravava log para
|qualquer alteração de qualquer usuário
|-------------------------------------------------------------------------------->
|Alterado por: Claudio Silva		Data: 11/07/2019
|Descrição: Alterado a regra para incluir os dados na SB5 devido ao processo de
|liberação. O mesmo não estava incluíndo no momento da liberação
|Ticket: 2019062707000445
|-------------------------------------------------------------------------------->
|Alterado por: Claudio Silva		Data: 16/07/2019
|Descrição: O sistema não estava incluindo o indicador pois a chamada foi mudado
|para quando o mesmo já estava gravado no banco. Foi retirado a validação do bloqueio
|de antes com depois
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira 	Data: 02/12/2022
|Descrição: Alterado para incluir ZB1 quando status for liberado.
|-------------------------------------------------------------------------------->
|Alterado por: 		Data:   /  /
|Descrição:
\*------------------------------------------------------------------------------*/
Static Function TIVALTERACAO(aFiliais)
	//If M->B1_ZSTATUS <> SB1->B1_ZSTATUS
	If !Empty(SB1->B1_ZSTATUS) .And. SB1->B1_ZSTATUS == "3"
		TIVZB1()
	else
		If type("lRep_Altzb1") <> 'U'
			lRep_Altzb1 := .F.
		EndIf
	EndIf
	If M->B1_MSBLQL == "2"
		TIVFILSSBZ(aFiliais)
	EndIf
	If M->B1_MSBLQL == "2".And. M->B1_RASTRO == "L"
		TIVINCB5(aFiliais)
	EndIf
Return()

/*------------------------------------------------------------------------------*\
|Função: TIVFILSSBZ
|Descrição: Função que verifica na SBZ (Indicadores de Produto) quais as filiais
|ainda não possuem registro do produto que esta sendo alterado naquele momento
|Data: 31/01/2019
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:
|-------------------------------------------------------------------------------->
|Alterado por:		Data:   /  /
|Descrição:
\*------------------------------------------------------------------------------*/
Static Function TIVFILSSBZ(aFiliais)
	Local cQuery   := ""
	Local aFilSBZ  := {}
	Local cAlias   := GetNextAlias()
	Local cFiliais := "'" + StrTran(ArrTokStr(aFiliais,"/"),"/",",") + "'"
	cQuery := "SELECT FILIAIS" + Chr(13) + Chr(10)
	cQuery += "FROM (SELECT REGEXP_SUBSTR(" + cFiliais + ",'[^,]+',1,LEVEL) AS FILIAIS" + Chr(13) + Chr(10)
	cQuery += "      FROM DUAL" + Chr(13) + Chr(10)
	cQuery += "      CONNECT BY REGEXP_SUBSTR(" + cFiliais + ",'[^,]+',1,LEVEL) IS NOT NULL)" + Chr(13) + Chr(10)
	cQuery += "WHERE FILIAIS NOT IN (SELECT BZ_FILIAL" + Chr(13) + Chr(10)
	cQuery += "                      FROM " + RetSqlName("SBZ") + Chr(13) + Chr(10)
	cQuery += "                      WHERE D_E_L_E_T_ <> '*' AND SUBSTR(BZ_FILIAL,1,2) = '" + FWCodEmp() + "'" + Chr(13) + Chr(10)
	cQuery += "                      AND BZ_COD = '" + SB1->B1_COD + "')" + Chr(13) + Chr(10)
	cQuery += "ORDER BY FILIAIS" + Chr(13) + Chr(10)
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlias,.F.,.T.) //Cria uma tabela temporária com as informações trazidas na query
	(cAlias)->(dbEval({|| AADD(aFilSBZ,AllTrim((cAlias)->FILIAIS))}))
	If !Empty(aFilSBZ)
		TIVINCBZ(aFilSBZ)
	EndIf
	U_FCLOSEAREA(cAlias)
Return()

/*------------------------------------------------------------------------------*\
|Função: MTA010NC
|Descrição: Ponto de Entrada que permite informar quais campos do cadastro de
|produto não serão levados preenchidos no momento da cópia.
|Data: 13/03/2019
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:	aNoCopy	Array contendo os campos que, no momento da cópia de um produto, terão seus conteúdos apagados
|-------------------------------------------------------------------------------->
|Alterado por:		Data:   /  /
|Descrição:
\*------------------------------------------------------------------------------*/
User Function MTA010NC()
	Local aNoCopy := {}
	AADD(aNoCopy,"B1_TIPO")
	AADD(aNoCopy,"B1_MSBLQL")
	AADD(aNoCopy,"B1_ZSTATUS")
	AADD(aNoCopy,"B1_ATIVO")
	AADD(aNoCopy,"B1_GRUPO")
Return(aNoCopy)



/*/{Protheus.doc} FVldCod
Valida se o codigo ja existe na filial Fox ou Fabrica
@type function
@version P12.1.27
@author Lucas - MAIS
@since 16/09/2021
@return logical, Informa de pode prosseguir ou não
/*/
Static Function FVldCod

Local cQuery  := ""
Local cAlias  := "ALIPRD"
Local cFilPar := SuperGetMv("MC_FCADFAB",.F.,"")
Local cFilBkp := ""
Local lRet    := .T.

If Empty(cFilPar) // Nao possui parametro informado...
    Return lRet
End If

cFilBkp := cFilAnt
cFilAnt := cFilPar

cQuery := " SELECT B1_COD FROM "+RetSqlName("SB1")+CRLF
cQuery += " WHERE D_E_L_E_T_ <> '*'"+CRLF
cQuery += " AND B1_FILIAL = '"+xFilial("SB1")+"'"+CRLF
cQuery += " AND B1_COD = '"+M->B1_COD+"'"+CRLF

If Select(cAlias) > 0
	(cAlias)->(dbCloseArea())
End If

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlias,.F.,.T.)

If !(cAlias)->(Eof()) // Ja existe o mesmo codigo na outra filial, entao retorna .F.
	lRet := .F.
End If


If Select(cAlias) > 0
	(cAlias)->(dbCloseArea())
End If

cFilAnt := cFilBkp

Return lRet

/*/{Protheus.doc} fVldLotRas
Função para validar preenchimento dos campos Rastro e 
Controla Endereço para produtos do tipo PA e MP.
@type function
@version  12.1.27
@author Wemerson Souza
@since 17/12/2021
@return variant, .T. - Todas informações estão corretas/ .F. - Necessário avaliar conteúdo dos campos rasto ou contr.endereço
/*/
Static Function fVldLotRas()

Local lRet := .T.

If M->B1_TIPO $ "PA|MP"
	If M->B1_RASTRO <> "L"
		Help(NIL, NIL, "RASTRO", NIL, "MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Inclusão de Produto!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Campo RASTRO deverá ser preenchido obrigatóriamente com LOTE para produto do tipo "+AllTrim(M->B1_TIPO)+"."})
		lRet := .F.
	ElseIf M->B1_LOCALIZ <> "S"
		Help(NIL, NIL, "CONTR.ENDERE", NIL, "MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Inclusão de Produto!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Campo CONTR.ENDERE deverá ser preenchido obrigatóriamente com SIM para produto do tipo "+AllTrim(M->B1_TIPO)+"."})
		lRet := .F.
	EndIf
EndIf

Return(lRet)



/*/{Protheus.doc} FAtuCarT
Função para atualizar a carga tributária do produto, após a inclusão para considerar a o valor calculado a partir de algum
produto da linha
@type function
@version P12.1.27 
@author Lucas - MAIS
@since 12/01/2022
/*/
Static Function FAtuCarT

Local aAreaBZ := SBZ->(GetArea())
Local cGrpSup := ""

SBZ->(dbSetOrder(1))
If SBZ->(dbSeek(xFilial("SBZ")+SB1->B1_COD))
	If SBZ->BZ_ZCARTRB == 0
		SBM->(dbSetOrder(1))
		If SBM->(dbSeek(xFilial("SBM")+SB1->B1_GRUPO))
			cGrpSup := SBM->BM_ZGRUSUP 
			FRetAlq(cGrpSup,SB1->B1_COD)
		End If
	ENd If

End If

RestArea(aAreaBZ)

Return



/*/{Protheus.doc} FRetAlq
Função para localizar a aliquota da linha de produtos.
@type function
@version P12.1.27 
@author Lucas - MAIS
@since 12/01/2022
@param cGrpSup, character, Linha do Produto
@param cProduto, character, Produto Incluido
/*/
Static Function FRetAlq(cGrpSup,cProduto)

Local cQryAlq := ""
Local cAliAlq := GetNextAlias()

cQryAlq := " SELECT MAX(BZ_ZCARTRB) AS BZ_ZCARTRB FROM "+RetSqlName("SBZ")+" BZ"+CRLF
cQryAlq += " INNER JOIN "+RetSqlName("SB1")+" B1"+CRLF
cQryAlq += " ON BZ.BZ_COD = B1.B1_COD"+CRLF
cQryAlq += " AND B1.B1_FILIAL = '"+xFilial("SB1")+"'"+CRLF
cQryAlq += " AND B1.D_E_L_E_T_ <> '*'"+CRLF
cQryAlq += " INNER JOIN "+RetSqlName("SBM")+" BM"+CRLF
cQryAlq += " ON BM.BM_GRUPO = B1.B1_GRUPO"+CRLF
cQryAlq += " AND BM.BM_ZGRUSUP = '"+cGrpSup+"'"+CRLF       
cQryAlq += " AND BM.D_E_L_E_T_ <> '*'"+CRLF
cQryAlq += " AND BM.BM_FILIAL = '"+xFilial("SBM")+"'"+CRLF
cQryAlq += " WHERE BZ_FILIAL = '"+xFilial("SBZ")+"'"+CRLF
cQryAlq += " AND BZ.D_E_L_E_T_ <> '*'"+CRLF

If Select(cAliAlq) > 0
	(cAliAlq)->(dbCloseArea())
End If

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQryAlq),cAliAlq,.F.,.T.)

If !(cAliAlq)->(Eof()) // Ja existe o mesmo codigo na outra filial, entao retorna .F.
	Reclock("SBZ",.F.)
	Replace BZ_ZCARTRB With (cAliAlq)->BZ_ZCARTRB
	MSUnlock()
End If


If Select(cAliAlq) > 0
	(cAliAlq)->(dbCloseArea())
End If

Return
