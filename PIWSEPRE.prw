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
	
	WSDATA c_CodPre 		AS STRING OPTIONAL

	WSMETHOD POST DESCRIPTION "Recebe dados e efetiva pre-produtos incluindo produto." WSSYNTAX "/PIWSEPRE?c_CodPre={param}" //PATH "incluiCotacao" 
	

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
WSMETHOD POST WSRECEIVE c_CodPre WSSERVICE PIWSEPRE
//User Function fIncPre()

	Local aArea     := {}
    Local cTabela   := "SB1"
    Local aCabec    := {}
	Local aFields := {}
	Local nX := 0
	Local oJson := JsonObject():New()
	Local cRet := ""
	Local lRet := .T.
	Local aRet := {}
    Private lMsErroAuto := .F.

	//RpcSetEnv("01","010001")

    cBody := '{ '
    cBody += '"B1_COD    " : "000000052",'
    cBody += '"B1_CONTA" : "000000052",'
    cBody += '"B1_DESC" : "000000052",'   
    cBody += '"B1_GARANT" : "000000052",' 
    cBody += '"B1_GRUPO" : "000000052",'  
    cBody += '"B1_LOCALIZ" : "000000052",'
    cBody += '"B1_LOCPAD" : "000000052",' 
    cBody += '"B1_ORIGEM" : "000000052",' 
    cBody += '"B1_POSIPI" : "000000052",' 
    cBody += '"B1_RASTRO" : "000000052",'
    cBody += '"B1_TIPO" : "000000052",'   
    cBody += '"B1_UM" : "000000052",'     
    cBody += '"B1_ZCCINDE" : "000000052",'
    cBody += '"B1_ZSEGRE" : "000000052",' 
    cBody += '}

	aArea     := FWGetArea()

	cBody := ::GetContent()
	::SetContentType('application/json;charset=UTF-8')

	cRet := oJson:FromJson(cBody)
	
	If ValType(cRet) == "C"
		SetRestFault(403, "Falha ao transformar texto em objeto json. Erro: " + cRet)
		lRet := .F.
	endif
	If lRet 
		If Empty(self:c_CodPre)
			SetRestFault(403, "Parametro obrigatorio vazio. (Codigo pre-produto)")
			lRet := .F.
		EndIf
	EndIf

	If lRet 

		cFilAnt := "010001"
		cEmpAnt	:= substr(cFilAnt,1,2)
		SM0->(dbSetOrder(1))
		SM0->(DbSeek(cEmpAnt+cFilAnt))

		//--Monta Array com todos os campos da SZC (CABEÇALHO)
		aFields := FWSX3Util():GetAllFields( cTabela , .F. ) //-- Retornará todos os campos presentes na SX3 de contexto real do alias.
		For nX := 1 to Len(aFields)
			If X3Uso(GetSx3Cache(aFields[nX],"X3_USADO"))


			//Adiciona os campos para o ExecAuto de acordo com json passado.
			IF VALTYPE(oJson[aFields[nX]]) != "U"
				If GetSx3Cache(aFields[nX],"X3_TIPO") == "D"
					aAdd(aCabec, {aFields[nX], ctod(oJson[aFields[nX]]), Nil})
				Else
					aAdd(aCabec, {aFields[nX], oJson[aFields[nX]], Nil})
					//Não é permitido informar o campo código na inclusão.
					//If AllTrim(GetSx3Cache(aFields[nX],"X3_CAMPO")) == "B1_COD"
					//	lRet := .F.
					//EndIf
				EndIf
			EndIf

			EndIf
		Next nX


        aCabec := FWVetByDic( aCabec, 'SB1' )

        //Chamando a inclusão - Modelo 1
        lMsErroAuto := .F.
 
        FWMVCRotAuto( oModel,"SB1",3,{{"SB1MASTER", aCabec}})
    
        //Se houve erro no ExecAuto, mostra mensagem
        If lMsErroAuto
            aErroExec := GetAutoGRLog() //Buscar o erro reportado pelo execauto
            For nX := 1 To Len(aErroExec)
                cLogMsg += aErroExec[nX]+ Chr(13) + Chr(10)
            Next xI
            lRet := .T.
        Else

        // Verifico se o grupo de produtos pertence ao parametro de grupos onde o produto deve nascer bloqueado:
            If SB1->B1_GRUPO $ cGrpBlq
                Reclock("SB1",.F.)
                Replace B1_ZLIBERA With '2'
                Replace B1_MSBLQL With '1'
                MSUnlock()
            End If
        End If


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
