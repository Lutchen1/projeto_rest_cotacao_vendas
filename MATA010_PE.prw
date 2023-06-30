#INCLUDE "TOTVS.CH"

/********************************************************************************\
|					    VACCINAR NUTRICAO E SAUDE ANIMAL				 		 |
\********************************************************************************>
|Programa: ITEM		 | Dt. Cria��o: 31/01/2019 | Responsavel: Rodrigo Prates	 |
|--------------------------------------------------------------------------------|
|Resumo: Ponto de entrada em MVC na rotina de Cadastro de Produtos (MATA010).	 |
|Esse ponto de entrada � chamado em v�rios momentos da fun��o padr�o MATA010,	 |
|tendo que ser analisado pelo PARAMIXB[2]. O P.E. MT010INC e MT010ALT foram		 |
|descontinuados. A documenta��o do P.E. MT010INC (o MT010ALT era um resumo do INC|
|e por isso sua documenta��o n�o teve necessidade de transposi��o) foi mantida no|
|fonte a titulo de hist�rico.													 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 13/11/2012 | Responsavel: Rodrigo Prates						 |
|--------------------------------------------------------------------------------|
|Motivo: Ponto de Entrada ap�s a inclus�o de produto na tabela SB1. Insere		 |
|registro daquele produto na tabela SBZ (Indicadores de Produto) para todas as	 |
|filiais cadastradas.															 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 06/08/2013 | Responsavel: Helder Santos							 |
|--------------------------------------------------------------------------------|
|Motivo: No momento da inclusao do produto e caso o campo B1_RASTRO = 'L'		 |
|ser� criado o complemento para o mesmo em todas as filiais do sistema			 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 19/08/2015 | Responsavel: Leonardo Perrella						 |
|--------------------------------------------------------------------------------|
|Motivo: Adicionado parametro TIV_SIGAQTY para considerar apenas as filias que   |
|ser�o gravados o Tipo CQ = "Q"		                                             |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 20/09/2017 | Responsavel: Leonardo Perrella						 |
|--------------------------------------------------------------------------------|
|Motivo: Adiconado grava��o do campo B1_ZPRODPI no campo BZ_ZPRODPI.             |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 29/09/2017 | Responsavel: Leonardo Perrella						 |
|--------------------------------------------------------------------------------|
|Motivo: Adicinonado informa��es padroes nos campos B5_SERVENT,B5_ENDENT e 		 |
|B5_ZMULPL de preenchimento na SB5 na fun��o FsCComPro.        					 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 22/05/2018 | Responsavel: Rodrigo Prates						 |
|--------------------------------------------------------------------------------|
|Motivo: As fun��es de mensagem ApMsgAlert() tiveram o 2o parametro (t�tulo da	 |
|janela) alterado para se encaixar no padr�o desenvolvido pela T.I. Vaccinar:	 |
|"<Fun��o Principal> - " + AllTrim(Str(ProcLine(0))) + " - <Nome no Menu>"		 |
|Na fun��o FsCComPro() foi criada a variavel cFilErro para receber o c�digo das	 |
|que apresentaram problema no execauto											 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 15/11/2018 | Responsavel: Rodrigo Prates						 |
|--------------------------------------------------------------------------------|
|Motivo: A fun��o MT010INC() foi alterada passando a criar os registros da SBZ	 |
|(Indicador de Produtos) e SB5 (Complemento de Produtos) somente se o produto que|
|esta sendo inclu�do estiver com a libera��o de tela == Sim. A valida��o da SB5	 |
|somente ser criada se o produto controlar rastro ainda permanece. Foi adicionada|
|a fun��o TIVZB1() que insere um registro na ZB1 (Campos Customizados de Produtos|
|A fun��o FsCComPro() teve seu nome alterado para TIVINCB5() para ficar mais	 |
|did�tica e padr�o com o resto das fun��es do fonte e seu modificador de acesso	 |
|passou a ser User, pois ela passou a ser chamada pelo P.E. MT010ALT. A inclus�o |
|de registros na SBZ foi transformada numa fun��o especifica, chamada de TIVINCBZ|
|com modificador de acesso User, pois tamb�m � chamada pelo P.E. MT010ALT. Todas |
|as variaveis que recebiam os campos da SB1 e que compunham a escrita do comando |
|INSERT foram exclu�das por n�o serem mais necess�rias, uma vez que os campos que|
|elas recebiam podem ser diretamente utilizados. Tratamentos feitos para atender |
|os chamados 2019010207000116 e 2019021807000728.								 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 25/02/2019 | Responsavel: Rodrigo Prates						 |
|--------------------------------------------------------------------------------|
|Motivo: A fun��o TIVINCZB1() foi alterada, pois o calculo do novo R_E_C_N_O_	 |
|levava em considera��o a filial, mas esse numero � unico por tabela. A sigla de |
|minuto foi alterada para MI, pois a anterior, MM, � de m�s. As fun��es			 |
|TIVINCLUSAO() e TIVALTERACAO() foram alteradas, pois a chamada da fun��o		 |
|TIVZB1() n�o considerava a altera��o do campo B1_ZSTATUS e, com isso, gravava	 |
|log para qualquer altera��o de qualquer usu�rio								 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 13/03/2019 | Responsavel: Rodrigo Prates						 |
|--------------------------------------------------------------------------------|
|Motivo: Foi adicionado o Ponto de Entrada MTA010INC para que sejam definidos os |
|campos que, no momento da c�pia de um produto, tenham seus conte�dos apagados	 |
|Chamado: 2019031307000235														 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 11/07/2019 | Responsavel: Claudio Silva 						 |
|--------------------------------------------------------------------------------|
|Motivo: Mudan�a da chamada do TIVALTERACAO para ap�s grava��o da tabela e		 |
|removido a chamada de antes da grava��o. Alterado na User function ITEM		 |
|Altera��o no static function TIVALTERACAO: Alterado a regra para incluir os     |
|dados na SB5 devido ao processo de libera��o. O mesmo n�o estava inclu�ndo 	 |
|no momento da libera��o Ticket: 2019062707000445								 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 16/07/2019 | Responsavel: Claudio Silva							 |
|--------------------------------------------------------------------------------|
|Motivo: N�o estava inclu�do o indicador de produto devido a altera��o da chamada|
|do TIVALTERA��O para antes da grava��o para depois de gravado. Foi retirado a   |
|valida��o se estava bloqueado para n�o bloqueado. 								 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 25/06/2020 | Responsavel: Antonio Mateus						 |
|--------------------------------------------------------------------------------|
|Motivo: Adicionado o campo ZB1_PRDCUS � query de inser��o de registros na tabela|
|ZB1 e cria��o da chamada opcional ao programa TIVRO103 visando a manuten��o de  |
|registros na tabela de dados customizados do produto (ZB1) ap�s a inclus�o do   |
|produto na SB1.																 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o:  08/07/2020 | Responsavel: Dayvid Nogueira 	     				 |
|--------------------------------------------------------------------------------|
|Motivo: Adicionado valida��o na grava��o do codigo Produto no cadastro          |
|do Pre-produto para seja gravado somente se o campo estiver vazio.              |
|--------------------------------------------------------------------------------|
|Dt. Altera��o:   27/11/2020 | Responsavel: Dayvid Nogueira						 |
|--------------------------------------------------------------------------------|
|Motivo: Inserido os campos definidos na Express�o SQL para n�o ocorrer erro	 |
|com Inclus�o de novos campos na tabela ZB1, para atender o chamado              |
|Ticket#2020112507000758                                                         |
|--------------------------------------------------------------------------------|
|Dt. Altera��o:   17/03/2021 | Responsavel: Lucas - MAIS   						 |
|--------------------------------------------------------------------------------|
|Motivo: Inclui tratativa para verificar se a execu��o � via rotina autom�tica   |
|tratando a exibi��o de mensagem gr�fica na tela.								 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o:   09/08/2021 | Responsavel: Lucas - MAIS    					 |
|--------------------------------------------------------------------------------|
|Motivo: Adicionada tratativa para replica��o de cadastro entre FOX e Fabrica	 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o:   02/09/2021 | Responsavel: Lucas - MAIS    					 |
|--------------------------------------------------------------------------------|
|Motivo: Adicionada tratativa para exibir mensagem de alerta se ocorrer erros	 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 21/09/2021     | Responsavel: Lucas - MAIS		        		 |
|--------------------------------------------------------------------------------|
|Motivo: Adicionada tratativa para validar se codigo ja existe entre empresas	 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 21/12/2021 | Responsavel: Ponto Ini - Wemerson					 |
|--------------------------------------------------------------------------------|
|Motivo: Inclui valida��o no preenchimento dos campos Rastro e Controla Endere�o | 
|para produtos do tipo PA e MP.													 |
|--------------------------------------------------------------------------------|
|Dt. Altera��o: 12/01/2022 | Responsavel: Lucas - MAIS							 |
|--------------------------------------------------------------------------------|
|Motivo: Grava��o da aliquota da linha de produtos na inclusao de um novo produto| 
|--------------------------------------------------------------------------------|
|Dt. Altera��o:   /  /     | Responsavel: 										 |
|--------------------------------------------------------------------------------|
|Motivo:												 						 |
/********************************************************************************>
|					    VACCINAR NUTRICAO E SAUDE ANIMAL				 		 |
\********************************************************************************/
/*------------------------------------------------------------------------------*\
|Fun��o: ITEM
|Descri��o: Fun��o principal do ponto de entrada que faz as valida��es dos
|momentos de execu��o do P.E. e dispara suas particularidades.
|Data: 31/01/2019
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:	xRet	Variavel de controle, de tipagem variavel de acordo com o momento 
|em que o P.E. esta sendo chamado
|-------------------------------------------------------------------------------->
|Alterado por: Cl�udio Silva		Data: 11/07/2019
|Descri��o: Mudan�a da chamada do TIVALTERA��O para ap�s grava��o da tabela e
|removido a chamada de antes da grava��o.
|-------------------------------------------------------------------------------->
|Alterado por: Antonio Mateus		Data: 25/06/2020
|Descri��o: Criada a chamada opcional do programa TIVRO103 para inclus�o de  
|registros na tabela de dados customizados de produto (ZB1)				
|-------------------------------------------------------------------------------->
|Alterado por: Lucas - MAIS			Data: 17/03/2021
|Descri��o: Inclui tratativa para verificar se a execu��o � via rotina autom�tica
|tratando a exibi��o de mensagem gr�fica na tela.		
|-------------------------------------------------------------------------------->
|Alterado por: Lucas - MAIS			Data: 09/08/2021
|Descri��o: Adicionada tratativa para replica��o de cadastro entre FOX e Fabrica
|-------------------------------------------------------------------------------->
|Alterado por: Lucas - MAIS			Data: 02/09/2021 
|Descri��o: Adicionada tratativa para exibir mensagem de alerta se ocorrer erros
|-------------------------------------------------------------------------------->
|Alterado por: Lucas - MAIS			Data: 21/09/2021 
|Descri��o: Adicionada tratativa para validar se codigo ja existe entre empresas
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira		Data: 29/12/2022
|Descri��o: Torna o preenchimento obrigat�rio da tabela ZB1 quando o produto for 
|			PA ou BN.
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira		Data: 30/12/2022
|Descri��o: Incluir valida��o no cadastro de produto para controle obrigat�rio de 
|			Rastro e Endere�amento quanto tipo do produto igual a MP, PA, RV, BN.
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira		Data: 21/03/2023
|Descri��o: Inclu� codigo de beneficio para o produto automaticamente para as 
|			filiais de pinhais e toledo.
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira		Data: 12/04/2023 
|Descri��o: Ao alterar o cadastro do produto alterar tamb�m o campo B5_CONVDIP.
|		    Este deve ter o peso do produto de acordo com a convers�o em KG.
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
	
	//If PARAMIXB[2] == "FORMCOMMITTTSPRE" //Antes da grava��o da tabela do formul�rio. //Tratamento TIVALTERACAO foi transferido para o ponto FORMCOMMITTTSPOS  - 11-07-19 CLAUDIO.SILVA
	If PARAMIXB[2] == "FORMCOMMITTTSPOS" //Chamada ap�s a grava��o da tabela do formul�rio.
		aFiliais := FWAllFilial(FWCodEmp(),,,.F.) //->Rodrigo Prates - Momento em que o s�o obtidos os codigos das filiais cadastradas na tabela SM0 (Empresas)
		If INCLUI
			TIVINCLUSAO(aFiliais)
			// Atualiza BZ_ZCARTRB, conforme aliquota encontrada para linha. // LUCAS - MAIS :: 12/01/22
			FAtuCarT() 
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			//>-Antonio Mateus - Chamada do programa para inclus�o de informa��es complementares do produto na tabela ZB1.			 |
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			// -->Lucas :: 17/03/21 - Verifica se a execu��o � via rotina automatica, se sim nao apresenta mensagem.
			//Lutchen - 29/12/2022 - Colocando no bot�o confirmar pois vai ser obrigat�rio para alguns tipos de produtos e n�o pode ser ap�s a incluls�o.
			/*If !l010Auto 
				If MsgYesNo(OemToAnsi("Deseja Incluir Informa��es Complementares do Produto? S/N? "),OemToAnsi("MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Manuten��o de Produtos!"))
					U_TIVRO103()
				EndIf
			End If*/
			// <--Lucas :: 17/03/21 - Verifica se a execu��o � via rotina automatica, se sim nao apresenta mensagem.
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			//<-Antonio Mateus - Chamada do programa para inclus�o de informa��es complementares do produto na tabela ZB1.			 |
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
		EndIf
		If ALTERA
			TIVALTERACAO(aFiliais)
		EndIf

		//-- Ltn - 21/03/2023 - Inclu� codigo de beneficio para o produto automaticamente para as filiais de pinhais e toledo.
		If Inclui .And. AllTrim(M->B1_TIPO) == 'PA'
			
			If  (substr(M->B1_GRUPO,1,2) == '12') .OR. ; //--Aves
				(substr(M->B1_GRUPO,1,2) == '14') .OR. ; //--Su�nos
				(M->B1_GRUPO >= '1501' .AND. M->B1_GRUPO <= '1504') .OR. ; //--Peixes
				(substr(M->B1_GRUPO,1,2) == '13')       //--Ruminantes


				StartJob("U_PIFIS140",GetEnvServer(),.T.,"01","010020",M->B1_COD) //--Inclu� c�digo de benef�cio pinhais
				StartJob("U_PIFIS140",GetEnvServer(),.T.,"01","010025",M->B1_COD) //--Inclu� c�digo de benef�cio toledo.

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
					MsgStop("N�o foi possivel incluir o registro entre filiais!")
				End If
			End IF
			If nOpc == 4 
				lRet := U_MCESTP01('A')	
				If lRet
					MsgStop("N�o foi possivel alterar o registro entre filiais!")
				End If	
			End If
			If nOpc == 5 
				lRet := U_MCESTP01('E')		
				If lRet
					MsgStop("N�o foi possivel excluir o registro na filial correspondente pois o mesmo j� possui movimenta��o!")
				End If
			End 

		Else

			//--Lutchen - 30/06/2023 - Ajuste para incluir registro entre filiais.
			oObj 	 	:= aParam[1]
			nOpc 		:= oObj:GetOperation()

			If nOpc == 3
				lRet := U_MCESTP01('I')
				If lRet
					//MsgStop("N�o foi possivel incluir o registro entre filiais!")
				End If
			End IF
		
		End If
	End If

			// Lucas - MAIS :: 16/09/2021 - Valida no TOK, se o codigo+loja nao existem na outra filial...
		If ParamIXB[2] == "FORMPOS"

			If INCLUI .OR. ALTERA
				
				//Lutchen Oliveira - 30/12/2022 - Incluir valida��o no cadastro de produto para controle obrigat�rio de Rastro e Endere�amento quanto tipo do produto igual a MP, PA, RV, BN.
				If M->B1_TIPO $ "MP/PA/RV/BN"
					If (M->B1_LOCALIZ != 'S' .or. (M->B1_RASTRO != 'S'.and. M->B1_RASTRO != 'L')) 
						//MsgStop("Controle obrigat�rio de Rastro e Endere�amento quanto tipo do produto igual a MP, PA, RV, BN.")
						Help(NIL, NIL, "RASTRO/ENDE", NIL, "Controle Rastro/endere�amento", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Controle obrigat�rio de Rastro e Endere�amento quanto tipo do produto igual a MP, PA, RV, BN."})
						Return(.F.)
					EndIf
				EndIf
				
			EndIf

			If INCLUI// Se for inclus�o
				If !l010Auto // Nao � rotina automatica
					If !FVldCod() // Se ja existir o codigo+loja na filial fabrica ou fox, aborta
						//MsgStop("Aten��o! Codigo ja existe na filial "+IIf("09"$cFilAnt,"FOX","Vaccinar")+" n�o � posssivel confirmar a inclus�o!")
						Help(NIL, NIL, "REGEXIST", NIL, "Erro registro existente", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Aten��o! Codigo ja existe na filial "+IIf("09"$cFilAnt,"FOX","Vaccinar")+" n�o � posssivel confirmar a inclus�o!"})
						Return .F.
					End If
				End If
				If !fVldLotRas() //- -17/12/2021 - Wemerson Souza -- Valida Obrigatoriedade de controel de Lote e Endere�o para produtos tipo PA e MP
					Return(.F.)
				EndIf

				If !l010Auto

					//-- LUtchen Oliveira - 29/12/2022 - torna o preenchimento obrigat�rio da tabela ZB1 quando o produto for PA ou BN.
					ZB1->(dbSetOrder(1))
					If !ZB1->(dbSeek(xFilial("ZB1")+M->B1_COD))
						If MsgYesNo(OemToAnsi("Deseja Incluir Informa��es Complementares do Produto? S/N? "),OemToAnsi("MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Manuten��o de Produtos!"))
							U_TIVRO103()							
							//--Verifico se realmente foi inclu�do.
							ZB1->(dbSetOrder(1))
							If !ZB1->(dbSeek(xFilial("ZB1")+M->B1_COD))
								If M->B1_TIPO $ "BN/PA"
									//MsgStop("Obrigat�rio preenchimento das informa��es complementares do produto para os produtos do tipo PA e BN!")
									Help(NIL, NIL, "CAD_COMPL", NIL, "Erro cadastro complementar", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Obrigat�rio preenchimento das informa��es complementares do produto para os produtos do tipo PA e BN!"})
									Return(.F.)
								EndIf
							EndIf
						Else
							If M->B1_TIPO $ "BN/PA"
								//MsgStop("Obrigat�rio preenchimento das informa��es complementares do produto para os produtos do tipo PA e BN!")
								Help(NIL, NIL, "CAD_COMPL", NIL, "Erro cadastro complementar", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Obrigat�rio preenchimento das informa��es complementares do produto para os produtos do tipo PA e BN!"})
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
|Fun��o: TIVINCLUSAO
|Descri��o: Fun��o que substituiu a MT010INC() e faz os tratamentos de inclus�o
|de produtos
|Data: 31/01/2019
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:
|-------------------------------------------------------------------------------->
|Alterado por: Rodrigo Prates		Data: 13/11/2012
|Descri��o: Fun��o que insere registro daquele produto na tabela SBZ (Indicadores
|de Produto) para todas as filiais cadastradas.
|-------------------------------------------------------------------------------->
|Alterado por: Leonardo Perrella	Data: 20/09/2017
|Descri��o: Adicionado tratamento na query para o campo BZ_ZPRODPI receber a
|informa��o do B1_ZPRODPI
|-------------------------------------------------------------------------------->
|Alterado por: Rodrigo Prates		Data: 22/05/2018
|Descri��o: A fun��o ApMsgAlert() teve o 2o parametro (t�tulo da janela) alterado
|para se encaixar no padr�o desenvolvido pela T.I. Vaccinar:
|"<Fun��o Principal> - " + AllTrim(Str(ProcLine(0))) + " - <Nome no Menu>"
|-------------------------------------------------------------------------------->
|Alterado por: Igor Rabelo			Data: 30/05/2018
|Descri��o: Criado processo de efetiva�a�d e Pr�-Produto gravando dados na SZA.
|-------------------------------------------------------------------------------->
|Alterado por: Rodrigo Prates		Data: 15/11/2018
|Descri��o: A cria��o do indicador de produtos (SBZ) e complemento de produtos
|(SB5) agora s�o executados somente se o produto que esta sendo inclu�do estiver
|com a libera��o de tela == Sim (a SB5 ainda tem a valida��o de controle de
|rastro do produto). Foi inserida a chamada da fun��o TIVZB1() que gerencia a
|cria��o/altera��o de registros na tabela ZB1 (Campos Customizados de Produto).
|Toda a cria��o de registros na SBZ foi excluido da MT010INC() e viraram a fun��o
|TIVINCBZ() com modificador de acesso User, pois ela tamb�m � chamada do P.E.
|MT010ALT.
|-------------------------------------------------------------------------------->
|Alterado por: Rodrigo Prates		Data: 25/02/2019
|Descri��o: O calculo do novo R_E_C_N_O_ levava em considera��o a filial, mas
|esse numero � unico por tabela.
|-------------------------------------------------------------------------------->
|Alterado por: Dayvid Nogueira		Data: 08/07/2020
|Descri��o: Adicionado valida��o na grava��o do codigo Produto no cadastro    
|do Pre-produto para seja gravado somente se o campo estiver vazio.      
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira 	Data: 02/12/2022
|Descri��o: Alterado para incluir ZB1 quando status for liberado.
|-------------------------------------------------------------------------------->
|Alterado por:		Data:   /  /
|Descri��o:
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
		If SB1->B1_RASTRO == "L" //->Helder Santos - criado fun��o que, ap�s incluir produto sistema deve criar o complemento do produto em todas as filiais
			TIVINCB5(aFiliais)
		EndIf
	EndIf
	If !Empty(SB1->B1_ZPREPRD) //-- IR -- Se tiver Pr�-produto amarrado. Grava efetiva��o na SZA (Pr�-Produto)
		SZA->(dbSetOrder(1))
		If SZA->(dbSeek(xFilial("SZA") + SB1->B1_ZPREPRD))
			If Empty(SZA->ZA_PRDEFET) //Dayvid Nogueira - 08/07/2020 Inclus�o da Valida��o para incluir o Codigo do produto somente se o campo estiver vazio.
				Reclock("SZA",.F.)
				Replace SZA->ZA_PRDEFET With SB1->B1_COD
				Replace SZA->ZA_DTEFETI With dDataBase
				SZA->(MsUnLock())
			EndIF
		EndIf
	EndIf
Return()

/*------------------------------------------------------------------------------*\
|Fun��o: TIVLOGINC
|Descri��o: Fun��o grava a data e a hora da altera��o do produto
|Data: 22/11/2012
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:
|-------------------------------------------------------------------------------->
|Alterado por:		Data:   /  /
|Descri��o:
\*------------------------------------------------------------------------------*/
Static Function TIVLOGINC()
	If RecLock("SB1",.F.)
		Replace SB1->B1_ZDTINC	With dDataBase
		Replace SB1->B1_ZHRINC	With Time()
		MsUnlock()
	EndIf
Return()

/*------------------------------------------------------------------------------*\
|Fun��o: TIVZB1
|Descri��o: Fun��o que gerencia a cria��o (TIVINCZB1())/altera��o (TIVALTZB1())
|de registros da ZB1
|Data: 15/11/2018
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira 	Data: 02/12/2022
|Descri��o: Se for altera��o verifica se status j� n�o foi preenchido.
|			Caso esteja vazio altera ZB1 preenchendo os campos de status.
|-------------------------------------------------------------------------------->
|Alterado por:		Data:   /  /
|Descri��o:
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
|Fun��o: TIVINCZB1
|Descri��o: Fun��o que faz a cria��o de um registro relacionado ao produto que
|esta sendo incluido/alterado (via MT010ALT) naquele momento, na ZB1 (Campos
|Customizados de Produto), referente ao log do status de libera��o/bloqueio/
|pendencia
|Data: 15/11/2018
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:
|-------------------------------------------------------------------------------->
|Alterado por: Rodrigo Prates		Data: 25/02/2019
|Descri��o: O calculo do novo R_E_C_N_O_ levava em considera��o a filial, mas
|esse numero � unico por tabela. Na convers�o de SYSDATE, a sigla de minutos foi
|alterada de MM (M�s) para MI (Minuto)
|-------------------------------------------------------------------------------->
|Alterado por: Antonio Mateus		Data: 25/06/2020
|Descri��o: Adicionado o campo ZB1_PRDCUS � query de inser��o de registros na 
|tabela ZB1. 
|-------------------------------------------------------------------------------->
|Alterado por: Dayvid Nogueira		Data:  27/11/2020
|Descri��o: Inserido os campos definidos na Express�o SQL para n�o ocorrer erro 
|com Inclus�o de novos campos na tabela ZB1, para atender o chamado 
|Ticket#2020112507000758.
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira		Data:  01/12/2022
|Descri��o: Adicionada tratativa para replica��o de cadastro entre FOX e Fabrica
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira		Data:  24/04/2023
|Descri��o: Retirando tratativa para replica��o de cadastro entre FOX e Fabrica,
|pois ja esta fazendo no fonte MCESTP01 chama esse execauto de produto novamente.
|Colocando campos dinamicamente para n�o precisar alterar a fun��o caso insira
|mais campos na tabela.
@history 09/06/2023, Antonio Daniel, MC02 - verifica o tipo do campo para diferenciar entre tipo num�rico dos demais.

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
	//--Se n�o for Fox ou Fabrica s� cria na empresa corrente.
	//If !(substr(cFilAnt,1,2) $ "01|09")
		a_Emp := {substr(cFilAnt,1,2)}
	//EndIf

	For nX := 1 to Len(a_Emp)

		cQuery := "INSERT INTO " + RetSqlName("ZB1") + Chr(13) + Chr(10)
		//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
		//>-Dayvid Nogueira - Inserido os campos definidos na Express�o SQL para n�o ocorrer erro com Inclus�o de novos campos na tabela ZB1.|
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
		//>-Dayvid Nogueira - Inserido os campos definidos na Express�o SQL para n�o ocorrer erro com Inclus�o de novos campos na tabela ZB1.|
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
		If ZB1->(dbseek(AVKEY(SUBSTR(cFilPar,1,2),"ZB1_FILIAL")+SB1->B1_COD )) //Se encontar na outra filial busca as informa��es dos campos e replica.
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
		nRet := TcSqlExec(cQuery) //Executa a query de interven��o no banco
		If nRet < 0 //Valores abaixo de 0 indicam erro na execu��o da query
			cFilErro += a_Emp[nX] + ", "
		EndIf
	Next nX

	If !Empty(cFilErro) //Caso tenha ocorrido algum erro...
		cFilErro := SubStr(cFilErro,1,Len(cFilErro) - 2)

		ApMsgStop(OemToAnsi("N�o foi possivel criar registro do produto " + AllTrim(SB1->B1_COD) + " - " + AllTrim(SB1->B1_DESC) + " na tabela 'Campos Customizados de Produto' nas empresas" + cFilErro + ". " +;
				"Favor entrar em contato com o T.I."),OemToAnsi("MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Manuten��o de Produtos!"))
	EndIf

Return()

/*------------------------------------------------------------------------------*\
|Fun��o: ALTZB1
|Descri��o: Fun��o que faz a altera��o de um registro relacionado ao produto que
|esta sendo alterado (via MT010ALT) naquele momento, na ZB1 (Campos
|Customizados de Produto), referente ao log do status de libera��o/bloqueio/
|pendencia
|Data: 15/11/2018
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:
@history 07/06/2023, Antonio Daniel, MC01 - verifica o tipo do campo para diferenciar entre tipo num�rico dos demais.
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
			nRet := TcSqlExec(cQuery) //Executa a query de interven��o no banco
			If nRet < 0 //Valores abaixo de 0 indicam erro na execu��o da query
				cFilErro += a_Emp[nX] + ", "
			EndIf

		EndIf
	Next nX

	If !Empty(cFilErro) //Caso tenha ocorrido algum erro...
		cFilErro := SubStr(cFilErro,1,Len(cFilErro) - 2)

		ApMsgStop(OemToAnsi("N�o foi possivel alterar registro do produto " + AllTrim(SB1->B1_COD) + " - " + AllTrim(SB1->B1_DESC) + " na tabela 'Campos Customizados de Produto' nas empresas "+cFilErro+". "+;
							"Favor entrar em contato com o T.I."),OemToAnsi("MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Manuten��o de Produtos!"))
	EndIf

	RestArea(aArea)
	
Return()

/*------------------------------------------------------------------------------*\
|Fun��o: TIVALTZB1
|Descri��o: Fun��o que faz a altera��o de um registro relacionado ao produto que
|esta sendo incluido/alterado (via MT010ALT) naquele momento, na ZB1 ((Campos
|Customizados de Produto), referente ao log do status de libera��o/bloqueio/
|pendencia
|Data: 15/11/2018
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:
|-------------------------------------------------------------------------------->
|Alterado por: Rodrigo Prates		Data: 25/02/2019
|Descri��o: Na convers�o de SYSDATE, a sigla de minutos foi alterada de MM (M�s)
|para MI (Minuto)
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira		Data:  01/12/2022
|Descri��o: Adicionada tratativa para replica��o de cadastro entre FOX e Fabrica
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira		Data:  24/04/2023
|Descri��o: Retirando tratativa para replica��o de cadastro entre FOX e Fabrica,
|pois ja esta fazendo no fonte MCESTP01 chama esse execauto de produto novamente.
\*------------------------------------------------------------------------------*/
Static Function TIVALTZB1()
	Local cQuery := ""
	Local nRet	 := 0
	Local nx 	 := 0
	Local cFilErro := ""
	Local a_Emp := {}//{"01","09"}

	//--Se n�o for Fox ou Fabrica s� cria na empresa corrente.
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
		nRet := TcSqlExec(cQuery) //Executa a query de interven��o no banco
		If nRet < 0 //Valores abaixo de 0 indicam erro na execu��o da query
			cFilErro += a_Emp[nX] + ", "
		EndIf
	Next nX

	If !Empty(cFilErro) //Caso tenha ocorrido algum erro...
		cFilErro := SubStr(cFilErro,1,Len(cFilErro) - 2)

		ApMsgStop(OemToAnsi("N�o foi possivel alterar registro do produto " + AllTrim(SB1->B1_COD) + " - " + AllTrim(SB1->B1_DESC) + " na tabela 'Campos Customizados de Produto' nas empresas "+cFilErro+". "+;
							"Favor entrar em contato com o T.I."),OemToAnsi("MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Manuten��o de Produtos!"))
	EndIf
Return()

/*------------------------------------------------------------------------------*\
|Fun��o: TIVINCBZ
|Descri��o: Fun��o criada com o INSERT da SBZ, que antes fazia parte da MT010INC
|inserindo em todas as filiais daquela empresa, os indicadores do produto que
|esta sendo cadastrado naquele momento
|Data: 15/11/2018
|Responsavel: Rodrigo Prates
|Parametro:	aFiliais	Array contendo as filiais que dever�o ter a SBZ criada para o produto cadastrado
|Retorno:
|-------------------------------------------------------------------------------->
|Alterado por:		Data:   /  /
|Descri��o:
\*------------------------------------------------------------------------------*/
Static Function TIVINCBZ(aFiliais)
	Local cQuery   := ""
    Local cFilErro := ""
	Local xI	   := 0
	Local nReg	   := 0 //Variavel que recebe o retorno da execu��o da query de INSERT
	//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
	//->Rodrigo Prates - Momento em que � incluido o registro em todas as filiais cadastradas								 |
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
			cQuery += "'" + SB1->B1_LOCPAD + "'," + Chr(13) + Chr(10) //Codigo do armazem padr�o
			cQuery += "'" + SB1->B1_DESC + "'," + Chr(13) + Chr(10) //Descri��o do produto
			cQuery += "'" + SB1->B1_TE + "'," + Chr(13) + Chr(10) //Codigo da TES de entrada padr�o daquele produto
			cQuery += "'" + SB1->B1_TS + "'," + Chr(13) + Chr(10) //Codigo da TES de saida padr�o daquele produto
			cQuery += "" + AllTrim(Str(SB1->B1_QE)) + "," + Chr(13) + Chr(10) //Quantidade por embalagem
			cQuery += "" + AllTrim(Str(SB1->B1_EMIN)) + "," + Chr(13) + Chr(10) //Ponto de pedido
			cQuery += "" + AllTrim(Str(SB1->B1_CUSTD)) + "," + Chr(13) + Chr(10) //Custo Standard
			cQuery += "'" + DtoS(SB1->B1_UCALSTD) + "'," + Chr(13) + Chr(10) //Data do ultimo calculo do Custo Standard
			cQuery += "'" + SB1->B1_MCUSTD + "'," + Chr(13) + Chr(10) //Moeda do Custo Standard
			cQuery += "'" + DtoS(SB1->B1_UCOM) + "'," + Chr(13) + Chr(10) //Data da ultima compra
			cQuery += "" + AllTrim(Str(SB1->B1_ESTSEG)) + "," + Chr(13) + Chr(10) //Estoque de seguran�a
			cQuery += "'" + SB1->B1_ESTFOR + "'," + Chr(13) + Chr(10) //Formula do estoque de seguran�a
			cQuery += "'" + SB1->B1_FORPRZ + "'," + Chr(13) + Chr(10) //Formula de calculo do prazo de entrega
			cQuery += "" + AllTrim(Str(SB1->B1_PE)) + "," + Chr(13) + Chr(10) //Prazo de entrega
			cQuery += "'" + SB1->B1_TIPE + "'," + Chr(13) + Chr(10) //Tipo do prazo de entrega
			cQuery += "" + AllTrim(Str(SB1->B1_LE)) + "," + Chr(13) + Chr(10) //Lote economico
			cQuery += "" + AllTrim(Str(SB1->B1_LM)) + "," + Chr(13) + Chr(10) //Lote minimo
			cQuery += "" + AllTrim(Str(SB1->B1_TOLER)) + "," + Chr(13) + Chr(10) //Tolerancia
			cQuery += "'" + SB1->B1_ORIGEM + "'," + Chr(13) + Chr(10) //Origem do produto
			cQuery += "'" + SB1->B1_GRTRIB + "'," + Chr(13) + Chr(10) //Grupo de tributa��o
			cQuery += "'" + SB1->B1_MRP + "'," + Chr(13) + Chr(10) //Indica se o produto entra para o calculo do MRP
			cQuery += "'" + SubStr(SB1->B1_CODISS,1,8) + "'," + Chr(13) + Chr(10) //Codigo de servi�o do ISS
			cQuery += "'" + SB1->B1_FANTASM + "'," + Chr(13) + Chr(10) //Informa "S" se � fantasma
			If SB1->B1_TIPO == "MP" .And. aFiliais[xI] $ GetMV("TIV_SIGAQTY") //->Leonardo Perrella - Adicionado parametro TIV_SIGAQTY para considerar apenas as filias que ser�o gravados o Tipo CQ = "Q"
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
			//conversao preenchido, cantrolar lote e endere�o.																		 |
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
			//conversao preenchido, cantrolar lote e endere�o.																		 |
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			cQuery += "'" + SB1->B1_ZPRODPI + "'," + Chr(13) + Chr(10) //Campo com informa�ao de comprado ou produzido //->Leonardo Perrella - Preenche o campo que define se o produto foi comprado ou produzido.
			cQuery += "'" + SB1->B1_LOCALIZ + "'," + Chr(13) + Chr(10) //Controle de Endere�o
			cQuery += "(SELECT MAX(R_E_C_N_O_) + 1 FROM " + RetSqlName("SBZ") + " BZ))" + Chr(13) + Chr(10)
			nReg := TcSqlExec(cQuery) //Executa a query de interven��o no banco
			If nReg < 0 //Valores abaixo de 0 indicam erro na execu��o da query
				cFilErro += aFiliais[xI] + ", "
			EndIf
		Next xI
		If !Empty(cFilErro) //Caso tenha ocorrido algum erro...
			cFilErro := SubStr(cFilErro,1,Len(cFilErro) - 2)
			ApMsgAlert(OemToAnsi("Problema durante a cria��o dos Indicadores de Produto para o produto '" + AllTrim(SB1->B1_COD) + "' nas filiais " + cFilErro + ". " +;
								 "Favor entrar em contato com o Setor de TI."),;
					   OemToAnsi("MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Manuten��o de Produtos!"))
			DisarmTransaction() //Da rollback em todas as inclus�es ja feitas durante aquela execu��o
			Return()
		EndIf
	EndTran()
	//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
	//<-Rodrigo Prates - Momento em que � incluido o registro em todas as filiais cadastradas								 |
	//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
Return()

//------------------------------------------------------------------
/*/{Protheus.doc} TIVINCB5

Fun��o utilizada incluir complemento do produto, tabela SB5

@author 	Helder Santos
@since 		06/08/2013
@version 	P11
@obs
Projeto

Alteracoes Realizadas desde a Estruturacao Inicial
Data		Programador			Motivo
29/09/2017	Leonardo Perrella	Adicinonado informa��es padroes nos campos B5_SERVENT, B5_ENDENT e B5_ZMULPL de preenchimento na SB5 quando o
								produto de mat�ria prima � cadastrado nas filias contidas no parametro DE_FILWMS1.
22/05/2018	Rodrigo Prates		A fun��o ApMsgAlert() teve o 2o parametro (t�tulo da janela) alterado para se encaixar no padr�o desenvolvido pela T.I.
								Vaccinar: OemToAnsi("<Nome da Fun��o Principal> - " + AllTrim(Str(ProcLine(0))) + " - <Nome da Fun��o no Menu>").
								A variavel cFilErro foi criada para receber o c�digo das filiais que apresentaram problema no execauto. A cFilErro foi
								inserida na mensagem para o usu�rio
15/11/2018	Rodrigo Prates		O modificador de acesso da fun��o passou a ser User, pois agora ela tamb�m � chamada pela MT010ALT(). Uma vez que o produto
								� criado bloqueado, a SBZ e a SB5 n�o s�o criadas automaticamente. Somente numa altera��o para o desbloqueio desse produto.
								Fun��o mudou de nome (antes era FsCComPro()) pq eu quis. As variaveis cCodProd, cTipo e cDesProd foram excluidas, pois
								simplesmente continham os valores dos campos da SB1, que foram utilizados diretamente na query, e n�o eram necess�rias.
12/04/2023  Lutchen Oliveira    Ao alterar o cadastro do produto alterar tamb�m o campo B5_CONVDIP.
							    Este deve ter o peso do produto de acordo com a convers�o em KG.
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
    Private lMsHelpAuto	   := .T. //For�a a grava��o das informa��es de erro em array ao inv�s de gravar direto no arquivo tempor�rio
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
			//->Leonardo Perrella - Preenchimento autom�tico campo customizado para filiais que utilizam WMS e tipo MP e que iniciem |
			//com 000 (padr�o Vaccinar para materia prima de consumo), para preenchimento padr�o do servi�o e endere�� de entrada e  |
			//para regra de um palet por endere�o com o conte�do 1 no campo B5_ZMULPL.												 |
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			If cFilAnt $ GetMv("DE_FILWMS1") .And. SB1->B1_TIPO $ "MP" .And. SubStr(SB1->B1_COD,1,3) == "000"
				AADD(aCab,{"B5_SERVENT","102" ,Nil})
				AADD(aCab,{"B5_ENDENT" ,"DOCA",Nil})
				AADD(aCab,{"B5_ZMULPL" ,"1"	  ,Nil})
			EndIf
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			//<-Leonardo Perrella - Preenchimento autom�tico campo customizado para filiais que utilizam WMS e tipo MP e que iniciem |
			//com 000 (padr�o Vaccinar para materia prima de consumo), para preenchimento padr�o do servi�o e endere�� de entrada e  |
			//para regra de um palet por endere�o com o conte�do 1 no campo B5_ZMULPL.												 |
			//--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
			/*Atualiza variavel de erro*/

			//-- LTN - 12/04/2023 - Ao alterar o cadastro do produto alterar tamb�m o campo B5_CONVDIP.
			//                      Este deve ter o peso do produto de acordo com a convers�o em KG.
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
		ApMsgAlert(OemToAnsi("Problema durante a cria��o do Complemento do produto '" + AllTrim(SB1->B1_COD) + "' na(s) filial(ais) " + cFilErro + ". " +;
							 "Favor entrar em contato com o Setor de TI."),;
				   OemToAnsi("MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Manuten��o de Produtos!"))
	ElseIf ALTERA
		cFilOk := SubStr(cFilOk,1,Len(cFilOk) - 2)
		ApMsgInfo(OemToAnsi("Complemento do produto '" + AllTrim(SB1->B1_COD) + "' inclu�do nas filiais:" + Chr(13) + Chr(10) + cFilOk + "!"),OemToAnsi("MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Manuten��o de Produtos!"))
	EndIf
Return(Nil)

/*------------------------------------------------------------------------------*\
|Fun��o: TIVINCLUSAO
|Descri��o: Fun��o que substituiu a MT010ALT() e faz os tratamentos de altera��o
|de produtos
|Data: 31/01/2019
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:
|-------------------------------------------------------------------------------->
|Alterado por: Rodrigo Prates		Data: 25/02/2019
|Descri��o: A chamada da fun��o de inclus�o/altera��o da tabela ZB1 n�o
|considerava a altera��o do campo B1_ZSTATUS e, com isso, gravava log para
|qualquer altera��o de qualquer usu�rio
|-------------------------------------------------------------------------------->
|Alterado por: Claudio Silva		Data: 11/07/2019
|Descri��o: Alterado a regra para incluir os dados na SB5 devido ao processo de
|libera��o. O mesmo n�o estava inclu�ndo no momento da libera��o
|Ticket: 2019062707000445
|-------------------------------------------------------------------------------->
|Alterado por: Claudio Silva		Data: 16/07/2019
|Descri��o: O sistema n�o estava incluindo o indicador pois a chamada foi mudado
|para quando o mesmo j� estava gravado no banco. Foi retirado a valida��o do bloqueio
|de antes com depois
|-------------------------------------------------------------------------------->
|Alterado por: Lutchen Oliveira 	Data: 02/12/2022
|Descri��o: Alterado para incluir ZB1 quando status for liberado.
|-------------------------------------------------------------------------------->
|Alterado por: 		Data:   /  /
|Descri��o:
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
|Fun��o: TIVFILSSBZ
|Descri��o: Fun��o que verifica na SBZ (Indicadores de Produto) quais as filiais
|ainda n�o possuem registro do produto que esta sendo alterado naquele momento
|Data: 31/01/2019
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:
|-------------------------------------------------------------------------------->
|Alterado por:		Data:   /  /
|Descri��o:
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
	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlias,.F.,.T.) //Cria uma tabela tempor�ria com as informa��es trazidas na query
	(cAlias)->(dbEval({|| AADD(aFilSBZ,AllTrim((cAlias)->FILIAIS))}))
	If !Empty(aFilSBZ)
		TIVINCBZ(aFilSBZ)
	EndIf
	U_FCLOSEAREA(cAlias)
Return()

/*------------------------------------------------------------------------------*\
|Fun��o: MTA010NC
|Descri��o: Ponto de Entrada que permite informar quais campos do cadastro de
|produto n�o ser�o levados preenchidos no momento da c�pia.
|Data: 13/03/2019
|Responsavel: Rodrigo Prates
|Parametro:
|Retorno:	aNoCopy	Array contendo os campos que, no momento da c�pia de um produto, ter�o seus conte�dos apagados
|-------------------------------------------------------------------------------->
|Alterado por:		Data:   /  /
|Descri��o:
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
@return logical, Informa de pode prosseguir ou n�o
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
Fun��o para validar preenchimento dos campos Rastro e 
Controla Endere�o para produtos do tipo PA e MP.
@type function
@version  12.1.27
@author Wemerson Souza
@since 17/12/2021
@return variant, .T. - Todas informa��es est�o corretas/ .F. - Necess�rio avaliar conte�do dos campos rasto ou contr.endere�o
/*/
Static Function fVldLotRas()

Local lRet := .T.

If M->B1_TIPO $ "PA|MP"
	If M->B1_RASTRO <> "L"
		Help(NIL, NIL, "RASTRO", NIL, "MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Inclus�o de Produto!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Campo RASTRO dever� ser preenchido obrigat�riamente com LOTE para produto do tipo "+AllTrim(M->B1_TIPO)+"."})
		lRet := .F.
	ElseIf M->B1_LOCALIZ <> "S"
		Help(NIL, NIL, "CONTR.ENDERE", NIL, "MATA010_PE - " + AllTrim(Str(ProcLine(0))) + " - Inclus�o de Produto!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Campo CONTR.ENDERE dever� ser preenchido obrigat�riamente com SIM para produto do tipo "+AllTrim(M->B1_TIPO)+"."})
		lRet := .F.
	EndIf
EndIf

Return(lRet)



/*/{Protheus.doc} FAtuCarT
Fun��o para atualizar a carga tribut�ria do produto, ap�s a inclus�o para considerar a o valor calculado a partir de algum
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
Fun��o para localizar a aliquota da linha de produtos.
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
