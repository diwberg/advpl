#INCLUDE "PROTHEUS.CH"
//----------------------------------------------------------------------------------------------------------------// 
// Apos uma transacao, caso o saldo fique negativo, envia um WorkFlow para o aprovador.
// Ele pode aprovar ou nao esta transacao. A resposta (SIM ou NAO), sera gravada no campo Z2_APROV.
//----------------------------------------------------------------------------------------------------------------// 
User Function WFXXXX()

Local   oWF  
Local cNumero,cLoja,cNome
Local cEMail := "Herold.leite@totvs.com.br"
Local cContato := "TESTE"

Default cNumero := "000001"
Default cLoja   := "01"
Default cNome   := "NOME DO Usuario"

If select("SX6")==0
	RpcClearEnv() //LIMPA O AMBIENTE
	RpcSetType( 3 ) //Nao utiliza licenca
	RpcSetEnv("99","01",,,"FAT",,{"SA2","SA3"})
Endif

// Inicializa a classe TWFProcess (WorkFlow).
oWF := TWFProcess():New( "APROVA", "Aprova��o de cadastro" )

// Cria uma nova tarefa para o processo.
oWF:NewTask( "Cliente NOVO", "\workflow\WFCLIENTE.html" )

// Preenche as variaveis no html.
oWF:oHtml:ValByName("Usuario"  , "Herold"  )
oWF:oHtml:ValByName("Codigo"   , cNumero)
oWF:oHtml:ValByName("Loja"     , cLoja  )
oWF:oHtml:ValByName("Nome"     , cNome  )

// Destinat�rio do WorkFlow. DEVE SER O CAMINHO QUE VAI GRAVAR O HTML
oWF:cTo := "/WORKFLOW/"

// Assunto da mensagem.
oWF:cSubject := "Aprova��o do novo cliente" + cNome

// Fun��o a ser executada quando a resposta chegar.
oWF:bReturn  := "U_WFCliRet"

// Fun��o a ser executada quando expirar o tempo do TimeOut.
// Tempos limite de espera das respostas, em dias, horas e minutos.
//oWF:bTimeOut := {{"U_WFTmOut",0,0,10}}

// Gera os arquivos de controle deste processo e envia a mensagem e guarda ID para geracao do arquivo
cNumId := oWF:Start() 


//Processo manual do HTML
//caminho que ira gravar o arquivo
_xCaminho := "\workflow\emp"+cEmpant+"\temp\"+cNumID   


_cHTML :=  memoread("\workflow\WFCLIENTE.HTML")

 	_xcHTMLH := ' <input type=hidden name="WFMAILID" value="WF'+alltrim(cNumID)+'">'  
	_xcHTMLH += ' <input type=hidden name="WFRECNOTIMEOUT" value="{}">'
	_xcHTMLH += ' <input type=hidden name="WFEMPRESA" value="'+cEmpAnt+'">' 
	_xcHTMLH += ' <input type=hidden name="WFFILIAL" value="'+cFilAnt+'">' 

	//SALVA O HTML QUE VAI NO LINK 
	_xcHTML := strtran(_cHTML, "|WFQTH|", _xcHTMLH)
	
	//abastece variaveis e acordo com o objeto gerado 
	aADCont:= oWF:OHTML:ALISTVALUES[1]

	For h:=1 to Len(aADCont) 
		
		cCpo  := aADCont[H][1]   
		cCont := aADCont[H][2]   
		
		IF TYPE("cCont")=='D'
			cCont := DTOC(cCont)
		ElseIf TYPE("cCont")=='N'
			cCont := cValToChar(cCont)  
		Endif
		
		If cCont <> Nil
			_xcHTML := strtran(_xcHTML,'!'+cCpo+'!', cCont)	
		Endif
		
		_xcHTML := strtran(_xcHTML,'%'+cCpo+'%', cCpo)
			
	Next

//Gera o html para ser acessado via link
WFSaveFile(_xCaminho+".htm", _xcHTML ) 

//Gera os arquivos de controle deste processo e envia a mensagem. HTML COM O LINK
oWf:NewTask("WFAPROVAD","\workflow\wflink.htm")	

// Destinat�rio do WorkFlow PARA ENVIAR O LINK

oWF:cTo := cEMail 
// Link do worflow para o Usuario
cLinkHtml := "http://localhost:9090/emp"+cEmpant+"/temp/"+cNumID+".htm" //link para enviar no email

// Preenche as variaveis no html.
oWF:oHtml:ValByName("USUARIO"  , cNome  )
oWF:oHtml:ValByName("PROC_LINK" , cLinkHtml )

// Destinat�rio do WorkFlow.
oWF:cTo  := cEmail          

//Enviado o WorkFlow do LINK
oWF:start()                                                                                        
	
Return( NIL )	
//-----------------------------------------------------------------------------------------------------

User function WFCliRet(oWF)

Local cNumero
Local cLoja
Local cAprova     
Local cObserv     

cNumero := oWF:oHtml:RetByName("Codigo")         // Obtem o Nr.da Transacao.
cLoja   := oWF:oHtml:RetByName("Loja")           // Obtem o Nr.do Item.
cAprova := oWF:oHtml:RetByName("APROVA")         // Obtem a resposta do Aprovador.
cObserv := oWF:oHtml:RetByName("OBSERV")         // Obtem a resposta do Aprovador.
 

conout(APROVA) 
conout(OBSERV)                  

// Finaliza o processo.
oWF:Finish()

Return( NIL )	
//-----------------------------------------------------------------------------------------------------
