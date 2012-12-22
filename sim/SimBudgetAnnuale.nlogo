;;DEFINIZIONE VARIABILI GLOBALI DEL MODELLO
globals [ wacc m2Kwp  count_tick scala_dim_impianto time anno number durata_impianti 
  count_pf count_pf2012 count_pf2013 count_pf2014 count_pf2015 count_pf2016  prezzi_minimi_gsef1 prezzi_minimi_gsef2 prezzi_minimi_gsef3  
  random_bgt random_m2 random_ostinazione random_consumo kW2012 kW2013 kW2014 kW2015 kW2016 kWTOT NAgentiFINAL  
  INCENTIVO_INST2012 INCENTIVO_INST2013 INCENTIVO_INST2014 INCENTIVO_INST2015 INCENTIVO_INST2016 INCENTIVO_INSTOT 
  INCENTIVO_PRO2012 INCENTIVO_PRO2013 INCENTIVO_PRO2014 INCENTIVO_PRO2015 INCENTIVO_PRO2016 INCENTIVO_PROTOT 
  Budget2012 Budget2013 Budget2014 Budget2015 Budget2016 ;per tenere traccia del budget annuale, spese più ricavi
  TOT_SPESA2012 TOT_SPESA2013 TOT_SPESA2014 TOT_SPESA2015 TOT_SPESA2016 TOT_SPESA 
  r2012 r2013 r2014 r2015 r2016 ;percentuale agenti che non sono morti
  BudgetCorrente;quanto è rimasto del budget iniziale
  totreg;quanti hanno usufruito degli incentivi regionali   
  percreg; percentuale di chi ha usufruito   
  totdied;quanti scelgono di non investire
  totnegsoldi;quanti non fanno investimento a causa di fattori economici
  perctotnegsoldi; percentuale di quello sopra
  percneg2012 percneg2013 percneg2014 percneg2015 percneg2016
  totneg2012 totneg2013 totneg2014 totneg2015 totneg2016
  percnegativa;percentuale di quante hanno rifutato l'investimento
  percpositive;di quanti hanno investito
]

;; DEFINIZIONE AGENTI E ATTRIBUTI AGENTI
breed [pf]

pf-own [id consumo_medio_annuale budget %cop_cosumi M2disposizione dimensione_impianto tipologia_impianto potenza_impianto fascia_potenza kw_annui_impianto costo_impianto %ostinazione influenza
  ridimensionamento prestito importo_prestito interessi_prestito rata_annuale_prestito  kw_autoconsumo kw_immessi kw_prelevati  
  anno_realizzazione semestre_realizzazione vita_impianto Data_termine_incentivi tariffa_incentivante tariffa_autoconsumo tariffa_omnicomprensiva 
  ricavi_autoconsumo ricavi_vendita ricavi_incentivi costi_energia_prelevata  costi_tot_energia_prelevata 
  flusso_cassa flusso_cassa_attualizzato flusso_cassa_cumulato  flusso_cassa_attualizzato_cumulato
  van PBT roi% roe% incentivo_installazione 
  freg;finanziamento regionale, se si fa finanziare o no dalle regione
  pfin;ercentuale finanziamento
  ifin;incentivo finanziamtno(quanto risparmio, solo con modalità asta)
  intRegione; quanto pago di interessi alla regione(solo se rotazione)  
  iregg;quanto la regione paga di interessi alla banca    (caso di conto interessi) 
  rataReg;rata da dare allla regione in caso di rotazione
  rataBanca
  ratepagate; quante rate ha pagato alla regione in caso di rotazione
  guadagnobanca; quanto ci guadagna la banca con gli interessi
  fallito;se non riesce a pagare il mututo
  morto
  initbudget;budget di partenza
  initosti;ostinaz iniziale
  valutaincentivi
  mortoxm2
  
]


;;PROCEDURA SETUP INIZIALIZZA VARIABILI GLOBALI, GRAFICO roe E GENERA IL PRIMO SET DI AGENTI
to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)  
  __clear-all-and-reset-ticks
  ;set BudgetCorrente BudgetRegione * 1000000
  ;tick
  set costo_kwh_fascia1 0.278
  set costo_kwh_fascia2 0.162
  set costo_kwh_fascia3 0.194
  set costo_kwh_fascia4 0.246
  set costo_kwh_fascia5 0.276
  output-print (word "---------------------------------------------------------------------------------")
  output-print (word "-----------------------------------INIZIO SIMULAZIONE----------------------------")
  set_global
  output-print (word "NUMERO AGENTI PER SEMESTRE: "NAgentiFINAL)
  output-print (word "PREVISTA VARIAZIONE TARIFFE INCENTIVANTI SULLA PRODUZIONE: " Varia_Tariffe_Incetivanti )
  output-print (word "PREVISTI INCENTIVI INSTALLAZIONE: " Incentivi_Installazione )
  if (Varia_Tariffe_Incetivanti)
  [
    output-print (word "PERCENTUALE VARIAZIONE: "  %_Variazione_Tariffe "%" )
  ]
  if (Incentivi_Installazione)
  [
    output-print (word "PERCENTUALE INCENTIVI INSTALLAZIONE: "  %_Incentivi_Installazione"%" )
  ]
  output-print (word "IRRADIAZIONE MEDIA ANNUA: " Irradiazione_media_annua_kwh_kwp" kWH_per_kWp" )
  output-print (word "LETTURA DA SERIE STORICHE: " LeggiSerieStoriche  )
  output-print (word "RIDUZIONE ANNUA COSTO PANNELLO: " Riduzione_anno_%costo_pannello "%")
  output-print (word "VARIAZIONE ANNUALE PREZZI ELETTICITA': "variazione_annuale_prezzi_elettricita  "%") 
  output-print (word "----------------------------------------------------------------------------------")
  set BudgetCorrente BudgetRegione * 1000000;inizializzo quantità finanziamenti rimasti
  setup_plot_PBT
  create_pf
end

;; PROCEDURA STEP ESECUTIVO AGGIORNA IL TEMPO SIMULATO, GLI IMPIANTI, I CONSUMI, I RICAVI, IL GRAFICO pbt,  CREA GLI ALTRI SET DI AGENTI SINO AL SECONDO SEMESTRE 2016, DETERMINA CONDIZIONE DI STOP
to go
  tick
  set count_tick count_tick + 1
  set time time + 1 
  aggiorna_impianti
  aggiorna_consumi
  aggiorna_ricavi
  update_plot_PBT 
  ;; LA SIMULAZIONE SI INTERROMPE PER PERMETTERE ALL'UTENTE DI SETTARE EVENTUALI STRUMENTI INCENTIVANTI 
  if (anno <= 2016 );creo altri agenti
  [
    if (Incentivi_Dinamici)
    [
      output-print    (word "--------------------------------------------------------------------------------------------------------------------------------------------------------")
      output-print (word "ANNO " anno " SEMESTRE " time" ----------------------------SETTA INCENTIVI : " Incentivi_Installazione "--------------------------------------------")
      user-message (word "HAI 10 SECONDI DA QUANDO PREMI OK PER SETTERA GLI STRUMENTI INCENTIVANTI ANNO: " anno " SEMESTRE " time)
      wait 10
      if(Incentivi_Installazione)
      [
        output-print (word "PERCENTUALE INCENTIVI INSTALLAZIONE: "  %_Incentivi_Installazione"%" )
      ]
      if (Varia_Tariffe_Incetivanti)
      [
        output-print (word "PERCENTUALE VARIAZIONE INCENTIVI: "  %_Variazione_Tariffe "%" )
      ]
      output-print (word "--------------------------------------------------------------------------------------------------------------------------------------------------------")
    ]
    create_pf
  ]
  if (anno = 2017);ora non creo più nulla faccio solo evolvere
  [
    calcola_rapporto
    set percreg precision ((totreg / count_pf) * 100) 2
  ]
  if (anno = 2016 + durata_impianti + 1   and time = 2 );fine simulazione
  [ 
    update_plot_roe
    aggiorna_incentivi_prod
    aggiorna_incentivi_tot
    stampa_agenti
    stampa_resoconto
    output-print (word "--------------------------------------------------------------------------------------------------------------------------------------------------------")
    output-print (word "---------------------------------------------------------------------FINE SIMULAZIONE-------------------------------------------------------------------")
    output-print (word "--------------------------------------------------------------------------------------------------------------------------------------------------------")
    export-output (word "Output/Simulazione "random 10000 " con agenti " NumeroAgenti" Variazione Incentivi produzione "Varia_Tariffe_Incetivanti " Percentuale " %_Variazione_Tariffe" Incentivi_Installazione " Incentivi_Installazione".txt")
    
    ;;produco file utile per l'ottimizzatore
    write_pl_file
    
    stop 
  ]
  if ( time = 2 );secondo semestre
  [
    set time 0
    set anno anno + 1
    aggiorna_prezzi;tutto cambia di anno in anno
  ]
end

;; PROCEDURA PER RIPRISTINARE AL VALORE DI "DEFAULT" VARIABILI GLOBALI MODIFICABILI DA INTERFACCIA
to default
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  ;; Costi prezzi energia al Kwh (dati del 2011)
  set costo_kwh_fascia1 0.278
  set costo_kwh_fascia2 0.162
  set costo_kwh_fascia3 0.194
  set costo_kwh_fascia4 0.246
  set costo_kwh_fascia5 0.276
  set Irradiazione_media_annua_kwh_kwp 1350 
  set Tecnologia_Pannello  "Monocristallini" 
  set Costo_Medio_kwP 4300 
  set Tasso_lordo_rendimento_BOT 2.147
  set variazione_annuale_prezzi_elettricita 1.8 
  set prezzi_minimi_gsef1 0.103 
  set prezzi_minimi_gsef2 0.086
  set prezzi_minimi_gsef3 0.076
  set Riduzione_anno_%costo_pannello 3
  set Perdita_efficienza_annuale_pannello 0.5
  set kW2012 0
  set kW2013 0
  set kW2014 0
  set kW2015 0
  set kW2016 0
  set kWTOT 0
  set INCENTIVO_INST2012 0
  set INCENTIVO_INST2013 0
  set INCENTIVO_INST2014 0
  set INCENTIVO_INST2015 0
  set INCENTIVO_INST2016 0 
  set INCENTIVO_INSTOT 0
  set INCENTIVO_PRO2012 0
  set INCENTIVO_PRO2013 0 
  set INCENTIVO_PRO2014  0 
  set INCENTIVO_PRO2015 0
  set INCENTIVO_PRO2016 0 
  set INCENTIVO_PROTOT 0
  set TOT_SPESA2012 0
  set TOT_SPESA2013 0
  set TOT_SPESA2014 0 
  set TOT_SPESA2015 0 
  set TOT_SPESA2016 0 
  set TOT_SPESA 0
  set Budget2012 0
  set Budget2013 0
  set Budget2014 0
  set Budget2015 0
  set Budget2016 0
  set Incentivi_Installazione false
  set %_Incentivi_Installazione 10
  set Varia_Tariffe_Incetivanti false
  set %_Variazione_Tariffe 0
  set count_pf2012 0
  set  count_pf2013 0
  set count_pf2014 0
  set  count_pf2015 0
  set count_pf2016 0
  set r2012 0
  set r2013 0
  set r2014 0
  set r2015 0
  set r2016 0
  set LeggiSerieStoriche true
  set fr "Nessuno"
  clear-output
end


;; SETUP A RUN TIME DI VARIABILI GLOBALI CHE NON VENGONO VARIANO DURANTE L'ESECUZIONE
to set_global
  set totneg2012 0
  set totneg2013 0
  set totneg2014 0
  set totneg2015 0
  set totneg2016 0
  set totnegsoldi 0
  set totdied 0
  set totreg 0
  set durata_impianti 20
  set count_tick 0
  set time 1;si parte dal primo semestre 2012
  set anno 2012
  set count_pf 0;non ho ancroa creato nuessuno
  set WACC Tasso_lordo_rendimento_BOT 
  set scala_dim_impianto 0.5
  set NAgentiFINAL NumeroAgenti;quanti crearne per semestre
  ifelse (Tecnologia_Pannello = "Monocristallini"  )
  [
    set m2Kwp  8;migliore tecnologia
  ]
  [
    ifelse ( Tecnologia_Pannello = "Policristallini" )
    [
      set m2Kwp 10
    ]
    [
      set m2Kwp 13
    ]
  ]  
  set Costo_Medio_kwP 3500
  genera_random
end

;; PROCEDURA CHE SI SOSTITUISCE ALLA LETTURA DA SERIE STORICHE E GENERA NUMERI PSEUDO CASUALI  DA ATTIBUIRE AGLI AGENTI E LI INSERISCE IN APPOSITE LISTE
to genera_random
  let c 0
  set random_ostinazione [];liste vuote
  set random_m2 []
  set random_bgt []
  set random_consumo []
  while [ c <  ( NAgentiFINAL - 1 ) ];riempio le liste
  [
    set c c + 1 
    set number 1 + random 100  
    set random_ostinazione lput  number random_ostinazione ;lista ostinazione
    set number 1 + random-float 9   
    set random_m2 lput number random_m2;lista metri quadri
    set number 1 + random-float 9   
    set random_bgt lput number random_bgt;lista badget
    set number 1 + random-float 9  
    set random_consumo lput number random_consumo;lista consumo 
    
    ; versione nuova per combaciare con le modifiche sul primo simulatore --> così nell'analisi dei risultati non occorre ricalcolare un nuovo fattore di scala
;        set number round random-normal 75 20
;        if (number < 1 ) [set number 1 ]   
;        if (number > 100 ) [set number 100 ]   
;        set random_ostinazione lput  number random_ostinazione 
;        set number random-normal 7 3
;        if (number < 1 ) [set number 1]
;        set random_m2 lput number random_m2
;        set number random-normal 5 4
;        if (number < 1 )[ set number 1 ]
;        set random_bgt lput number random_bgt
;        set number random-normal 5 4
;        if (number < 1 ) [set number 1]
;        set random_consumo lput number random_consumo
  ]
end

;; PROCEDURA CHE "SETTA" IL GRAFICO PBT
to setup_plot_PBT
  set-current-plot "Pay Back Time"
  set-current-plot-pen "axis"
  auto-plot-off
  plotxy 0 0
  plotxy 1000000000 0
  auto-plot-on  
  set-plot-x-range 0 durata_impianti
end

;; CREAZIONE, COLLOCAMENTO NELL'AMBIENTE VIRTUALE, RICHIAMO PROCEDURA GENERAZIONE AGENTI E VALUTA FATTIBILITA' 
to create_pf
  set-default-shape pf "house";forma di una casa
  ask n-of NAgentiFINAL patches;genera NAgentiFINAL pf
    [
      sprout-pf 1 ;ne genero uno
      [ 
        set influenza 0
        elimina_sovrapposizioni;im modo che le case non siano una sopra laltra
        set count_pf count_pf + 1;contatore investitori
        set id who; chi sono? sono io.
        genera_pf;legge da file o da lista le variabili dell'agente
        set valutaincentivi true
        valuta_fattibilita_impianto;se farà l'impianto con gli incentivi regionali o no??
        if morto = true;se la valitazione con gli incentivi non mi conviene provo senza incentivi
        [         
          ripristina
          set valutaincentivi false
          valuta_fattibilita_impianto;valuto di fare l'inpianto senza considerare gli incentivi 
        ]         
      ]    
    ] 
end

;ripristino stato precedente
to ripristina
  set rataReg 0
  set rataBanca 0
  set iregg 0
  set intRegione 0
  set freg false         
  set ifin 0
  set ratepagate 0
  set fallito false 
  set %ostinazione initosti
end

;; PROCEDURA CHE GENERA IL SET DI AGENTI: RICORDIAMO IL PRIMO AGENTE DI OGNI SET ASSUME I VALORI INDICATI TRAMITE INTERFACCIA GLI ALTRI AGENTI PRELEVANO I DATI O DAL FILE "SerieStoriche.txt" OPPURE PRELEVANDOLI DALLE LISTE E CALCOLA LE DIMENSIONI E I COSTI DELL'IMPIANTO
to genera_pf
  set mortoxm2 false
  set morto false
  set prestito false;al momento
  set ridimensionamento false 
  set incentivo_installazione 0
  ifelse (id = 0 or id = (NAgentiFINAL * count_tick ) );per tutti gli agenti zero, uno ogni semsestre  
    ;;GENERAZIONE AGENTE ZERO
    [
      set %ostinazione  100;;parte da ostinazione massima
      set consumo_medio_annuale  Consumo_medio_annuale_KWh
      set budget Budget_Medio_MiliaiaEuro * 1000
      set M2disposizione M2_Disposizione
      set %cop_cosumi Media%_copertura_consumi_richiesta
    ]
    [
      ;;PROCEDURA LETTURA DA FILE
      ;legge:  ostinazione    consumo_medio_annuale   budget    M2disposizione
      ifelse ( LeggiSerieStoriche and file-exists? "SerieStoriche.txt" )
      [     
        let finish false
        let count_t 0
        file-open "SerieStoriche.txt"
        while [ not file-at-end? and not finish]
        [      
          let letto file-read
          set count_t count_t + 1
          if (count_t = ((id * 4) + 1) );+1 perchè parte da 1
          [
            set  %ostinazione  letto
            set letto file-read
            set consumo_medio_annuale letto
            set letto file-read
            set budget letto
            set letto file-read
            set M2disposizione letto        
            set %cop_cosumi  Media%_copertura_consumi_richiesta
            set finish true;
          ]
        ]
        file-close
      ]
      [;else random, li prendo dalle liste
       ;;PROCEDURA SERIE CASUALI PRELEVANDO DA LISTE
        set %ostinazione item  (id - ( NAgentiFINAL * count_tick ) - 1 ) random_ostinazione 
        set consumo_medio_annuale round  (item  (id - ( NAgentiFINAL * count_tick ) - 1 ) random_consumo ) * Consumo_medio_annuale_KWh
        set budget round (item  (id - ( NAgentiFINAL * count_tick ) - 1 ) random_bgt )  * Budget_Medio_MiliaiaEuro * 1000
        set M2disposizione round (item  (id - ( NAgentiFINAL * count_tick ) - 1 ) random_m2 )  * M2_Disposizione
        set %cop_cosumi  Media%_copertura_consumi_richiesta
        
        
      ]
    ]
  calcola_dimensione;dopo ho dimensione impianto i m2
  calcola_costi_impianto;dopo ho costo impianto in euro
  ;gestione incentivi regionali                          
  set initosti %ostinazione
  set rataReg 0
  set rataBanca 0
  set iregg 0
  set intRegione 0
  set freg false         
  set ifin 0
  set ratepagate 0
  set fallito false 
  let p random 101;vorrà essere finanziato??
  if p < ProbFinanz;mi faccio finanziare
    [       
      ifelse fr = "Asta";la regione paga una percentuale a chi la chiede finchè ha dei soldi
        [                     
          ;calcolo percentuale
          set pfin PercMin + random (PercMax - PercMin + 1);percentuale richiesta da 10 a 50
          set ifin (costo_impianto * pfin) / 100;quanto risparmio
          ifelse BudgetCorrente - ifin > 0
          [
            set BudgetCorrente BudgetCorrente - ifin;aggiorno budget
            set totreg totreg + 1
            set freg true
          ]
          [
          set ifin 0  
          ]
        ]
        [
          let ra random 101;per vedere se la banca accetta
          ifelse fr = "Conto interessi" and ra < Accettato;la regione paga gli interessi dei mutui, l'agente paga la stessa cifra, ma a rate
          [            
            set %ostinazione %ostinazione +  InfluenzaRate ;se pago a rate sono più interessato
            set iregg (costo_impianto * InterBanca / 100 );quanto sborsa la regione
            ifelse BudgetCorrente - iregg > 0
            [
              set BudgetCorrente BudgetCorrente - iregg
              ;if BudgetCorrente < 0 [set BudgetCorrente 0]  
              set totreg totreg + 1
              set freg true
            ]
            [
              set iregg 0 
              set %ostinazione initosti
            ]
          ]
          [ 
            ifelse fr ="Rotazione";il mututo lo fa la regione, ma con tassi di interesse più leggeri.
            [             
              
              set %ostinazione %ostinazione +  InfluenzaRate ;se pago a rate sono più interessato              
              set intRegione (costo_impianto * InterRegione / 100  );quanto pago di interessi alla regione  
              ifelse BudgetCorrente - costo_impianto > 0 
              [            
                set BudgetCorrente BudgetCorrente - costo_impianto;la regione presta i soldi per l'impianto
                ;if BudgetCorrente < 0 [set BudgetCorrente 0]  
                calcola_rata_regione;calcola rateReg->quanto versare ogni anno
                set freg true
                set totreg totreg + 1
              ]
              [
                set intRegione 0
                set %ostinazione initosti                
              ]
            ]
            [ 
              if fr = "Garanzia";la regione da la garanzia alle banche sugli agenti, sicchè la banca non esclude dal mutuo nessun agente
              [                
                set %ostinazione %ostinazione +  InfluenzaRate;se pago a rate sono più interessato                
                set ifin (costo_impianto * InterBanca / 100 )*( -1);quanto pago di interessi alla banca
                calcola_rata_banca
                ifelse BudgetCorrente - costo_impianto - guadagnobanca > 0
                [
                  let rra random 101
                  if rra < FallimentoMutuo;con una certa probabilità fallisco
                  [
                    set fallito true
                    set BudgetCorrente BudgetCorrente - costo_impianto - guadagnobanca;
                    set totdied  totdied + 1            
                    die                 
                  ] 
                  set freg true
                  set totreg totreg + 1 
                ]
                [
                  set ifin 0
                  set %ostinazione initosti
                  set rataBanca 0
                  set guadagnobanca 0
                ]
              ]              
            ]            
          ]          
        ]
    ]        
  set ricavi_vendita []
  set ricavi_autoconsumo []
  set ricavi_incentivi []
  set costi_energia_prelevata []
  set flusso_cassa []
  set flusso_cassa_attualizzato []
  set van []
  set PBT  "non rilevato"
  ;calcolo interfernza
  set influenza (count pf in-radius raggio) - 1
  ;set label influenza ;se si vuole visualizzare il numero di vicin1
  if intorno [ask patches in-radius raggio[set pcolor 89]]  
end

;; PROCEDURA CHE CALCOLA LE DIMENSIONI DELL'IMPIANTO A PARTIRE DAI DATI AGENTE
to calcola_dimensione
  ;; calcolo della potenza dell ' impianto : CONSUMO_MEDIO_ANNUALE *  %Obbiettivo copertura consumi energetici 
  set kw_annui_impianto round ((consumo_medio_annuale *  %cop_cosumi) / 100 );formuline note
  ;; calcolo dimensione M2 impianto
  set dimensione_impianto (round  (kw_annui_impianto / Irradiazione_media_annua_kwh_kwp) * m2kwp )
end

;; PROCEDURA VALUTAZIONE FATTIBILITA' INVESTIMENTO (V. FLOW CHART)
to valuta_fattibilita_impianto
  ifelse (dimensione_impianto <=  M2disposizione ) and (costo_impianto - ifin + intRegione <=  budget );tutto perfetto
    [
      set color green
      aumenta_impianto;guardo se riesco ad aumentare la dim dell'mipianto
      calcola_fascia_potenza
      calcola_tariffa_gse
      aggiorna_kW
      aggiorna_incentivi_installazione
      aggiorna_budget_annuale
      aggiorna_pf
      stampa
    ]
    [
      ifelse (dimensione_impianto >  M2disposizione ) and (costo_impianto - ifin + intRegione >  budget );muoio
        [
          ifelse valutaincentivi = false
          [
            output-print   ("*************************************************************************************************")
            output-print  (word   "************** AGENTE " id  "realizzazione impianto impossibile : Eccedenza dimensionamento e costi") 
            output-print  (word   "DIE")
            output-print   ("*************************************************************************************************")
            set count_pf count_pf - 1
            ;show "realizzazione impianto impossibile : Eccedenza dimensionamento e costi"
            ;show word costo_impianto word "   " word (costo_impianto - ifin + intRegione) word "    "  word budget word "  " morto
            if mortoxm2 = false;se con gli incentivi è morto per questioni di dimensioni, non è corretto mettere l'agente tra chi non fa l'investimento per 
            [;motivi economici
              set  totnegsoldi totnegsoldi + 1
              ;show "realizzazione impianto impossibile : Eccedenza dimensionamento e costi"
              ;show word costo_impianto word "   " word (costo_impianto - ifin + intRegione) word "    "  word budget word "  " morto
              ifelse anno = 2012
              [
                set totneg2012 totneg2012 + 1
              ]
              [
                ifelse anno = 2013
                [
                  set totneg2013 totneg2013 + 1
                ]
                [
                  ifelse anno = 2014
                  [
                    set totneg2014 totneg2014 + 1
                  ]
                  [
                    ifelse anno = 2015
                    [
                      set totneg2015 totneg2015 + 1
                    ]
                    [
                      ifelse anno = 2016
                      [
                        set totneg2016 totneg2016 + 1
                      ]
                      [
                        
                      ]
                    ]
                  ]
                ]
              ] 
            ]   
          ]  
          [
            ;show "realizzazione impianto impossibile : Eccedenza dimensionamento e costi"
            ;show word costo_impianto word "   " word (costo_impianto - ifin + intRegione) word "    " word budget word "  "morto
          ]    
          muori
        ]
        [          
          ifelse ( dimensione_impianto >  M2disposizione ) 
          [ accetta_ridimensionamento  ];ci sto coi soldi  ma non con l'impianto
          [ accetta_prestito ];ci sto con le dimensioni, ma non coi soldi
        ]
    ]
end

;se muore annulla il prestito dalla regione
to muori
  if freg = true and valutaincentivi = true
    [     
      ifelse fr = "Asta"
        [
          set BudgetCorrente BudgetCorrente + ifin;ripristino situazione precedente
        ]
        [
          ifelse fr = "Conto interessi"
            [
              set BudgetCorrente BudgetCorrente + iregg
            ]     
            [
              ifelse fr = "Rotazione"
                [
                  set BudgetCorrente BudgetCorrente + costo_impianto  
                ]
                [
                  if fr ="Garanzia" and fallito
                  [
                    set BudgetCorrente BudgetCorrente + costo_impianto + guadagnobanca;
                  ]
                ]
            ]         
        ]            
    ]  
  ifelse valutaincentivi = false
  [
    set totdied  totdied + 1  
    die
  ]
  [
    set morto true
    if freg = true
    [set totreg totreg - 1]
  ]   
end

;; VALUTAZIONE AUMENTO DIMENSIONI E POTENZA IMPIANTO IN BASE A OSTINAZIONE
to aumenta_impianto
  let dim_imp dimensione_impianto
  if ( %ostinazione + influenza * sensibilita > 50);se non sono ostinato nemeno cerco di aumentare le dimensioni
  [
    set dimensione_impianto M2disposizione
    set kw_annui_impianto (round ( dimensione_impianto / m2Kwp )) * Irradiazione_media_annua_kwh_kwp
    calcola_costi_impianto
    if (costo_impianto - ifin + intRegione >= budget);se dopo l'aumento di dimensione non ci sto coi soldi
    [
      set dimensione_impianto dim_imp 
      set kw_annui_impianto (round ( dimensione_impianto / m2Kwp )) * Irradiazione_media_annua_kwh_kwp
      calcola_costi_impianto;rimetto come prima
    ]
  ]  
end

;; VALUTAZIONE RIDIMENSIONAMENTO POTENZA E DIMENSIONE IMPIANTO
to accetta_ridimensionamento
  let dimensione_eccedenza dimensione_impianto - M2disposizione
  ifelse (dimensione_eccedenza <= round ( ( M2disposizione * ( %ostinazione + influenza * sensibilita )) / 100 ) )
    [
      ;;set size dimensione_impianto / scala_dim_impianto
      set color blue
      set ridimensionamento true
      set dimensione_impianto  M2disposizione 
      set kw_annui_impianto (round ( dimensione_impianto / m2Kwp )) * Irradiazione_media_annua_kwh_kwp
      calcola_costi_impianto
      calcola_fascia_potenza
      calcola_tariffa_gse
      aggiorna_kW
      aggiorna_incentivi_installazione
      aggiorna_budget_annuale
      aggiorna_pf
      stampa
    ] 
    [
      if valutaincentivi = false 
      [
        output-print         ("*************************************************************************************************")
        output-print  (word   "************** AGENTE " id  "realizzazione impianto impossibile : Ridimensionamento non accettato") 
        output-print  (word   "DIE")
        output-print   ("*************************************************************************************************")
        set count_pf count_pf - 1
        ;show "realizzazione impianto impossibile : Ridimensionamento non accettato"
      ]
      set mortoxm2 true
      muori
    ]
end

;; VALUTAZIONE IPOTESI PRESTITO
to accetta_prestito
  let Sforo_Budget (costo_impianto - ifin + intRegione) - Budget
  ifelse (Sforo_Budget <= round ( ( Budget * ( %ostinazione + influenza * sensibilita )) / 100 ) )
    [
      ;;set size dimensione_impianto / scala_dim_impianto
      set color red
      set prestito true
      set importo_prestito  Sforo_Budget
      calcola_interessi
      calcola_costi_impianto
      calcola_fascia_potenza
      calcola_tariffa_gse
      aggiorna_kW
      aggiorna_incentivi_installazione
      aggiorna_budget_annuale
      aggiorna_pf 
      stampa      
    ] 
    [
      if valutaincentivi = false
      [
        output-print         ("*************************************************************************************************")
        output-print  (word   "************** AGENTE " id  "realizzazione impianto impossibile : Prestito non accettato**************") 
        output-print  (word   "DIE")
        output-print   ("")
        set count_pf count_pf - 1
        ;show "realizzazione impianto impossibile : Prestito non accettato**************"
        set  totnegsoldi totnegsoldi + 1
        ifelse anno = 2012
        [
          set totneg2012 totneg2012 + 1
        ]
        [
          ifelse anno = 2013
            [
              set totneg2013 totneg2013 + 1
            ]
            [
              ifelse anno = 2014
              [
                set totneg2014 totneg2014 + 1
              ]
              [
                ifelse anno = 2015
                [
                  set totneg2015 totneg2015 + 1
                ]
                [
                  ifelse anno = 2016
                  [
                    set totneg2016 totneg2016 + 1
                  ]
                  [
                    
                  ]
                ]
              ]
            ]
        ]    
      ]      
      muori
    ]
end  

;; PROCEDURA PER IL CALCOLO DEGLI INTERESSI LEGATI AL PRESTITO
;imposta la fascia di potenza da 1 a 6 d la dimensione della casetta
to calcola_interessi
  ;;calcolo rata alla francese
  set rata_annuale_prestito (round (( importo_prestito * (Percentuale_Interessi_Prestito / 100) ) / (1 - ( (1 + (Percentuale_Interessi_Prestito / 100) ) ^ (- Anni_Restituzione_Prestiti) ) ) ) )
  set interessi_prestito ( rata_annuale_prestito *  Anni_Restituzione_Prestiti ) - importo_prestito
end

;calcola la rata annuale da versare alla regione in caso l'incentivo sia a rotazione
to calcola_rata_regione
  ;;calcolo rata alla francese
  set rataReg (round (( costo_impianto * (InterRegione / 100) ) / (1 - ( (1 + (InterRegione / 100) ) ^ (- Anni_Restituzione_mutuo_regione) ) ) ) ) 
  ;show rataReg
end

;calcola la rata annuale per il mutuo da versare alla banca in caso l'incentivo sia a garanzia
to calcola_rata_banca
  ;;calcolo rata alla francese
  set rataBanca (round (( costo_impianto * (InterBanca / 100) ) / (1 - ( (1 + (InterBanca / 100) ) ^ (- Anni_Restituzione_mutuo_banca) ) ) ) )   
  set guadagnobanca ( rataBanca *  Anni_Restituzione_mutuo_banca ) - costo_impianto
end

;;PROCEDURA ASSEGNAZIONE FASCIA POTENZA da 1 a 6
to calcola_fascia_potenza
  set potenza_impianto dimensione_impianto / m2Kwp;caolcolo potenza impianto
  ifelse ( potenza_impianto > 1 and potenza_impianto <= 3 )
    [
      set fascia_potenza  1
      set size  (scala_dim_impianto + 0.4) * fascia_potenza
      set tipologia_impianto "Su edificio piccolo"
    ]
    [
      ifelse ( potenza_impianto > 3 and potenza_impianto <= 20 )
      [
        set fascia_potenza  2
        set size (scala_dim_impianto + 0.4) * fascia_potenza
        set tipologia_impianto "Su edificio piccolo"
      ]
      [
        ifelse ( potenza_impianto > 20 and potenza_impianto <= 200 )
        [
          set fascia_potenza  3
          set size (scala_dim_impianto + 0.4) * fascia_potenza
          set tipologia_impianto "Su edificio piccolo"
        ]
        [
          ifelse ( potenza_impianto > 200 and potenza_impianto <= 1000 )
          [
            set fascia_potenza  4
            set tipologia_impianto "Su edificio piccolo"
            set size (scala_dim_impianto + 0.4) * fascia_potenza
            
          ]
          [
            ifelse ( potenza_impianto > 1000 and potenza_impianto <= 5000 )
            [
              set fascia_potenza  5
              set tipologia_impianto "Su edificio grande"
              set size (scala_dim_impianto + 0.4) * fascia_potenza
              
            ]
            [
              set fascia_potenza  6
              set tipologia_impianto "Su edificio grande"
              set size (scala_dim_impianto + 0.4) * fascia_potenza
              
            ]
          ]
        ]
      ]
    ]
end  

;; STAMPA A VIDEO DETTAGLI IMPIANTO APPENA REALIZZATO
to stampa
  output-print           ("****************************************************************************************************")
  output-print  (word   "********************************* AGENTE " id  " realizzato impianto********************************** ")  
  output-print  (word   "*******************************************DATI IMPIANTO******************************************** ")
  output-print  (word   "Dimensione: " dimensione_impianto " m2")
  output-print  (word   "Costo: " costo_impianto " euro")
  output-print  (word   "Potenza: " potenza_impianto " kWp")
  output-print  (word   "Fascia Potenza: " fascia_potenza)
  output-print  (word   "Tipologia Impianto: "tipologia_impianto)
  ifelse( anno_realizzazione >= 2013)
    [output-show ( word    "Anno impianto "  anno_realizzazione " Semestre " semestre_realizzazione " Tariffa ominocompresiva "    tariffa_omnicomprensiva " Tariffa autoconsumo " tariffa_autoconsumo )]
    [output-show ( word   "Anno impianto "  anno_realizzazione " Semestre " semestre_realizzazione " Tariffa incentivante  " tariffa_incentivante )]  
  output-print  (word   "Incentivi Installazione: " incentivo_installazione "euro Ridimensionamento: " ridimensionamento " Prestito: " prestito )
  output-print     ("******************************************************************************************************")
end

;; OBSERVER AGGIORNA LA POTENZA INSTALLATA
to aggiorna_kW
  ifelse (anno_realizzazione = 2012)
  [
    ;;aggiornamento kW installati 2012
    set kW2012 kW2012 + potenza_impianto
  ]
  [
    ifelse (anno_realizzazione = 2013)
    [
      ;;aggiornamento kW installati 2013
      set kW2013 kW2013 + potenza_impianto
    ]
    [
      ifelse (anno_realizzazione = 2014)
      [
        ;;aggiornamento kW installati 2014
        set kW2014 kW2014 + potenza_impianto
      ]  
      [
        ifelse (anno_realizzazione = 2015)
        [
          ;;aggiornamento kW installati 2015
          set kW2015 kW2015 + potenza_impianto
        ]
        [
          ;;aggiornamento kW installati 2016
          set kW2016 kW2016 + potenza_impianto
        ]
      ]    
    ]
  ]
  ;; aggiornamento kWTOTALI
  set kWTOT kWTOT + potenza_impianto
end

;; OBSERVER AGGIORNA IL COUNT DEGLI AGENTI
to aggiorna_pf
  ifelse (anno_realizzazione = 2012)
  [
    ;;aggiornamento kW installati 2012
    set count_pf2012 count_pf2012 + 1
  ]
  [
    ifelse (anno_realizzazione = 2013)
    [
      ;;aggiornamento kW installati 2013
      set count_pf2013 count_pf2013 + 1
    ]
    [
      ifelse (anno_realizzazione = 2014)
      [
        ;;aggiornamento kW installati 2014
        set count_pf2014 count_pf2014 + 1
      ]  
      [
        ifelse (anno_realizzazione = 2015)
        [
          ;;aggiornamento kW installati 2015
          set count_pf2015 count_pf2015 + 1
        ]
        [
          ;;aggiornamento kW installati 2016
          set count_pf2016 count_pf2016 + 1
        ]
      ]    
    ]
  ]
end

;; OBSERVER AGGIORNA SPESA INCENTIVI INSTALLAZIONE
to aggiorna_incentivi_installazione
  
  ifelse (anno_realizzazione = 2012)
  [
    ;;aggiornamento incentivi installazione 2012
    set INCENTIVO_INST2012 INCENTIVO_INST2012 + incentivo_installazione 
  ]
  [
    ifelse (anno_realizzazione = 2013)
    [
      ;;aggiornamento incentivi installazione 2013
      set INCENTIVO_INST2013 INCENTIVO_INST2013 + incentivo_installazione 
    ]
    [
      ifelse (anno_realizzazione = 2014)
      [
        ;;aggiornamento incentivi installazione 2014
        set INCENTIVO_INST2014 INCENTIVO_INST2014 + incentivo_installazione 
      ]  
      [
        ifelse (anno_realizzazione = 2015)
        [
          ;;aggiornamento incentivi installazione 2015
          set INCENTIVO_INST2015 INCENTIVO_INST2015 + incentivo_installazione 
        ]
        [
          ;;aggiornamento incentivi installazione 2016
          set INCENTIVO_INST2016 INCENTIVO_INST2016 + incentivo_installazione 
        ]
      ]    
    ]
  ]
  ;;aggiornamento incentivi installazione TOTALI
  set INCENTIVO_INSTOT INCENTIVO_INSTOT + incentivo_installazione  
end

;;salva budget corrente alla fine di ogni anno
to aggiorna_budget_annuale
  
  ifelse (anno_realizzazione = 2012)
  [
    set Budget2012 BudgetCorrente
  ]
  [
    ifelse (anno_realizzazione = 2013)
    [
      set Budget2013 BudgetCorrente
    ]
    [
      ifelse (anno_realizzazione = 2014)
      [
        set Budget2014 BudgetCorrente
      ]  
      [
        ifelse (anno_realizzazione = 2015)
        [
          set Budget2015 BudgetCorrente
        ]
        [
          set Budget2016 BudgetCorrente
        ]
      ]    
    ]
  ]
end

;;aumenta il budget regionale all'inizio di ogni nuovo anno (della quantità specificata negli appositi slider)
to aggiorna_budget
  ;;a partire dal secondo anno: nel 2012 il budget è dato direttamente da BudgetRegione
  ifelse (anno_realizzazione = 2012)
  [
    ;;set BudgetCorrente BudgetCorrente
  ]
  [    
    ifelse (anno_realizzazione = 2013)
    [
      set  BudgetCorrente BudgetCorrente + (BudgetRegione2013 * 1000000)
    ]
    [
      ifelse (anno_realizzazione = 2014)
      [
       set  BudgetCorrente BudgetCorrente + (BudgetRegione2014 * 1000000)
      ]  
      [
        ifelse (anno_realizzazione = 2015)
        [
          set  BudgetCorrente BudgetCorrente + (BudgetRegione2015 * 1000000)
        ]
        [
         set  BudgetCorrente BudgetCorrente + (BudgetRegione2016 * 1000000)
        ]
      ]    
    ]
  ]
end

;; CALCOLA LA PERCENTUALE DI AGENTI CHE DECIDONO DI EFFETTUARE L'IMPIANTO
to calcola_rapporto
  set perctotnegsoldi precision (totnegsoldi / (NAgentiFINAL * 10) * 100) 2
  set percneg2012 precision (totneg2012 / (NAgentiFINAL * 2)* 100 ) 2
  set percneg2013 precision (totneg2013 / (NAgentiFINAL * 2)* 100 ) 2
  set percneg2014 precision (totneg2014 / (NAgentiFINAL * 2)* 100 ) 2
  set percneg2015 precision (totneg2015 / (NAgentiFINAL * 2)* 100 ) 2
  set percneg2016 precision (totneg2016 / (NAgentiFINAL * 2)* 100 ) 2
  
  set r2012  precision ((count_pf2012 * 100) / (NAgentiFINAL * 2)) 2
  set r2013  precision ((count_pf2013 * 100) / (NAgentiFINAL * 2)) 2
  set r2014  precision ((count_pf2014 * 100) / (NAgentiFINAL * 2)) 2
  set r2015  precision ((count_pf2015 * 100) / (NAgentiFINAL * 2)) 2
  set r2016  precision ((count_pf2016 * 100) / (NAgentiFINAL * 2)) 2
  
  set percnegativa precision (totdied / (NAgentiFINAL * 10) * 100) 2
  set percpositive 100 - percnegativa
end

;; PROCEDURA PER LA LETTURA DELLA TARIFFA RICONOSCIUTA (dati prelevati da file in cartella di lancio)
;se 2012-> tariffa incentivante
;se >2012 tariffa autoconsumo e omnicomprensiva
to calcola_tariffa_gse  
  set anno_realizzazione anno
  set semestre_realizzazione time 
  ifelse (anno_realizzazione = 2012 and file-exists? "Incentivi2012.txt" )
  [
    set tariffa_autoconsumo "Non prevista"
    let count_t 0
    file-open "Incentivi2012.txt"
    while [ not file-at-end? ]
      [
        let letto file-read
        set count_t count_t + 1
        if (count_t = (( semestre_realizzazione - 1 ) * 6 )+ fascia_potenza )
        [
          set  tariffa_incentivante  letto
          if (Varia_Tariffe_Incetivanti )
            [
              set tariffa_incentivante (precision (tariffa_incentivante + (precision( (tariffa_incentivante * %_Variazione_Tariffe) / 100 ) 3) )3)
            ]
        ]
      ]
    file-close
  ]
  [
    ifelse (anno_realizzazione = 2013 and file-exists? "Autoconsumo2013.txt"  and file-exists? "Onnicomprensiva2013.txt" )   
    [
      set  tariffa_incentivante "Non prevista"
      let count_t 0
      file-open "Autoconsumo2013.txt"
      while [ not file-at-end? ]
      [
        let letto file-read
        set count_t count_t + 1
        if (count_t = (( semestre_realizzazione - 1 ) * 6 )+ fascia_potenza )
        [
          set  tariffa_autoconsumo  letto
          if (Varia_Tariffe_Incetivanti )
            [
              set tariffa_autoconsumo (precision (tariffa_autoconsumo + (precision( (tariffa_autoconsumo * %_Variazione_Tariffe) / 100 ) 3))3)
            ]
        ]
      ]
      file-close
      set count_t 0
      file-open "Onnicomprensiva2013.txt"
      while [ not file-at-end? ]
      [
        let letto file-read
        set count_t count_t + 1
        if (count_t = (( semestre_realizzazione - 1 ) * 6 )+ fascia_potenza )
        [
          set  tariffa_omnicomprensiva  letto
          if (Varia_Tariffe_Incetivanti )
            [
              set tariffa_omnicomprensiva (precision (tariffa_omnicomprensiva + (precision( (tariffa_omnicomprensiva * %_Variazione_Tariffe) / 100 ) 3))3)
            ]
        ]
      ] 
      file-close      
    ]
    [
      ifelse (anno_realizzazione = 2014 and file-exists? "Autoconsumo2014.txt"  and file-exists? "Onnicomprensiva2014.txt" )   
      [
        set  tariffa_incentivante "Non prevista"
        let count_t 0
        file-open "Autoconsumo2014.txt"
        while [ not file-at-end? ]
        [
          let letto file-read
          set count_t count_t + 1
          if (count_t = (( semestre_realizzazione - 1 ) * 6 )+ fascia_potenza )
          [
            set  tariffa_autoconsumo  letto
            if (Varia_Tariffe_Incetivanti )
              [
                set tariffa_autoconsumo (precision (tariffa_autoconsumo + (precision( (tariffa_autoconsumo * %_Variazione_Tariffe) / 100 ) 3))3)
              ]
          ]
        ]
        file-close
        set count_t 0
        file-open "Onnicomprensiva2014.txt"
        while [ not file-at-end? ]
        [
          let letto file-read
          set count_t count_t + 1
          if (count_t = (( semestre_realizzazione - 1 ) * 6 )+ fascia_potenza )
          [
            set  tariffa_omnicomprensiva letto
            if (Varia_Tariffe_Incetivanti )
              [
                set tariffa_omnicomprensiva (precision (tariffa_omnicomprensiva + (precision( (tariffa_omnicomprensiva * %_Variazione_Tariffe) / 100 ) 3))3)
              ]
          ]
        ] 
        file-close
      ]
      [
        ifelse (anno_realizzazione = 2015 and file-exists? "Autoconsumo2015.txt"  and file-exists? "Onnicomprensiva2015.txt" )   
        [
          set  tariffa_incentivante "Non prevista"
          let count_t 0
          file-open "Autoconsumo2015.txt"
          while [ not file-at-end? ]
          [
            let letto file-read
            set count_t count_t + 1
            if (count_t = (( semestre_realizzazione - 1 ) * 6 )+ fascia_potenza )
            [
              set  tariffa_autoconsumo  letto
              if (Varia_Tariffe_Incetivanti )
                [
                  set tariffa_autoconsumo (precision (tariffa_autoconsumo + (precision( (tariffa_autoconsumo * %_Variazione_Tariffe) / 100 ) 3))3)
                ]
            ]
          ]
          file-close
          set count_t 0
          file-open "Onnicomprensiva2015.txt"
          while [ not file-at-end? ]
          [
            let letto file-read
            set count_t count_t + 1
            if (count_t = (( semestre_realizzazione - 1 ) * 6 )+ fascia_potenza )
            [
              set  tariffa_omnicomprensiva letto
              if (Varia_Tariffe_Incetivanti )
                [
                  set tariffa_omnicomprensiva (precision (tariffa_omnicomprensiva + (precision( (tariffa_omnicomprensiva * %_Variazione_Tariffe) / 100 ) 3))3)
                ]
            ]
          ] 
          file-close
        ]
        [
          set  tariffa_incentivante "Non prevista"
          let count_t 0
          file-open "Autoconsumo2016.txt"
          while [ not file-at-end? ]
          [
            let letto file-read
            set count_t count_t + 1
            if (count_t = (( semestre_realizzazione - 1 ) * 6 )+ fascia_potenza )
            [
              set  tariffa_autoconsumo  letto
              if (Varia_Tariffe_Incetivanti )
                [
                  set tariffa_autoconsumo (precision (tariffa_autoconsumo + (precision( (tariffa_autoconsumo * %_Variazione_Tariffe) / 100 ) 3))3)
                ]
            ]
          ]
          file-close
          set count_t 0
          file-open "Onnicomprensiva2016.txt"
          while [ not file-at-end? ]
          [
            
            let letto file-read
            set count_t count_t + 1
            if (count_t = (( semestre_realizzazione - 1 ) * 6 )+ fascia_potenza )
            [
              set  tariffa_omnicomprensiva letto
              if (Varia_Tariffe_Incetivanti )
                [
                  set tariffa_omnicomprensiva (precision (tariffa_omnicomprensiva + (precision( (tariffa_omnicomprensiva * %_Variazione_Tariffe) / 100 ) 3))3)
                ]
            ]
          ] 
          file-close
        ]
      ]
    ]
  ]
end


;; PROCEDURA CHE AGGIORNA A RUN TIME I PREZZI DELL'ENERGIA E I PREZZI GARANTITI GSE
to aggiorna_prezzi
  set costo_kwh_fascia1  precision   (costo_kwh_fascia1 + ( (costo_kwh_fascia1  *  variazione_annuale_prezzi_elettricita ) / 100 ) ) 3
  set costo_kwh_fascia2  precision (costo_kwh_fascia2 +   ( (costo_kwh_fascia2  *  variazione_annuale_prezzi_elettricita ) / 100 ) ) 3
  set costo_kwh_fascia3  precision (costo_kwh_fascia3 + ( (costo_kwh_fascia3  *  variazione_annuale_prezzi_elettricita ) / 100) ) 3
  set costo_kwh_fascia4 precision (costo_kwh_fascia4 + ( (costo_kwh_fascia4  *  variazione_annuale_prezzi_elettricita ) / 100) ) 3
  set costo_kwh_fascia5 precision (costo_kwh_fascia5 + ( (costo_kwh_fascia5  *  variazione_annuale_prezzi_elettricita )  / 100) )3
  set prezzi_minimi_gsef1 precision  ( prezzi_minimi_gsef1 +  ( (prezzi_minimi_gsef1  *  variazione_annuale_prezzi_elettricita )  / 100 ) ) 3
  set prezzi_minimi_gsef2 precision  (prezzi_minimi_gsef2 +  ( (prezzi_minimi_gsef2  *  variazione_annuale_prezzi_elettricita )  / 100 ) )3
  set prezzi_minimi_gsef3 precision  (prezzi_minimi_gsef3 +  ( (prezzi_minimi_gsef3  *  variazione_annuale_prezzi_elettricita )  / 100 ) ) 3
  set Costo_Medio_kwP (Costo_Medio_kwP  -  round ( (Costo_Medio_kwP * Riduzione_anno_%costo_pannello ) / 100) )
end

;; AGGIORNAMENTO DATI IMPIANTO    
to aggiorna_impianti
  ask pf 
  [
    set vita_impianto (anno + time ) - ( anno_realizzazione  + semestre_realizzazione )
    if (vita_impianto = 21)
    [
      set Data_termine_incentivi  (word time " Semestre del " anno )
      calcola_roi_roe
    ] 
  ]
end

;; PROCEDURA CHE AGGIORNA A RUN TIME I CONSUMI DELL'AGENTE E LA PRODUZIONE DELL'IMPIANTO
to aggiorna_consumi
  ask pf with [ semestre_realizzazione = time and ( vita_impianto < anno and vita_impianto <= 20 ) ]
  [
    set consumo_medio_annuale round ( consumo_medio_annuale  +  (( consumo_medio_annuale * Aumento_%annuo_consumi ) / 100) );aumeta
    set kw_annui_impianto round ( kw_annui_impianto - (( kw_annui_impianto * Perdita_efficienza_annuale_pannello ) / 100 ) );cala
    ifelse ( consumo_medio_annuale <= kw_annui_impianto )
    [
      set kw_autoconsumo consumo_medio_annuale
      set kw_immessi  kw_annui_impianto - consumo_medio_annuale
      set kw_prelevati  0
    ]
    [
      set kw_autoconsumo   kw_annui_impianto
      set kw_immessi  0
      set kw_prelevati  consumo_medio_annuale - kw_annui_impianto 
    ]
  ]
end

;; PROCEDURA ORGANIZZA AGGIORNAMENTEO RICAVI
to aggiorna_ricavi
  ask pf
  [
    ;pago la regione
    if fr ="Rotazione" and ratepagate < Anni_Restituzione_mutuo_regione and  freg = true
    [
      set BudgetCorrente  BudgetCorrente + rataReg;restituisco soldi alla regione
      set ratepagate ratepagate + 1
    ]   
    if fr ="Garanzia" and ratepagate < Anni_Restituzione_mutuo_banca and  freg = true
    [    
      set ratepagate ratepagate + 1
    ]    
  ]  
  ask pf with [ semestre_realizzazione = time and ( vita_impianto >= 1 and vita_impianto <= 20 ) ];una volta all'anno per 20 anni
  [
    calcola_ricavi_da_autoconsumo;cosa ho risparmiato producendo da me l'energia
    calcola_costi_energia_prelevata
    ifelse ( anno_realizzazione = 2012 )
    [
      calcola_ricavi_impianti_2012
    ]
    [
      calcola_ricavi_impianti_non2012
    ]
    calcola_flusso_di_cassa
  ]
end

;; CALCLO DEI FLUSSI DI CASSA ATTUALIZZATI E COMULATI, E DEL VALORE ATTUALE NETTO DELL'IMPIANTO
to calcola_flusso_di_cassa
  let ric_incentivo last ricavi_incentivi
  let ric_autoconsumo last ricavi_autoconsumo
  let rata rata_annuale_prestito + rataReg + rataBanca;rata prestito, e mutui se presenti  
  ;show word rataReg word "  "  rataBanca;  
  let ric_vendita last ricavi_vendita
  let costi_annuali precision ((costo_impianto * Manutenzione_anno_%costo_totale)  / 100 ) 2
  let flusso_c precision ( (ric_incentivo + ric_autoconsumo + ric_vendita ) - (rata + costi_annuali) ) 2
  set flusso_cassa lput flusso_c flusso_cassa
  set flusso_cassa_cumulato precision (flusso_cassa_cumulato + flusso_c ) 2
  let flusso_c_attualizzato precision (flusso_c / (1 + ( WACC / 100 ) ) ^ vita_impianto ) 2
  set flusso_cassa_attualizzato lput flusso_c_attualizzato flusso_cassa_attualizzato
  set flusso_cassa_attualizzato_cumulato precision ( flusso_cassa_attualizzato_cumulato + flusso_c_attualizzato ) 2
  let van_ora precision ((- costo_impianto ) + flusso_cassa_attualizzato_cumulato) 2
  ;;calcolo pay back time
  if (vita_impianto > 1 )
    [
      let van_prec last van
      if(van_prec < 0 and van_ora > 0 )
      [
        set PBT vita_impianto
      ]
    ]
  set van lput van_ora van
end

;; PROCEDURA DI INDIVIDUAZIONE DEI RICAVI PER GLI IMPIANTI INSTALLATI DOPO IL 2012
to calcola_ricavi_impianti_2012
  let ricavo_incentivo precision ( kw_annui_impianto *  tariffa_incentivante ) 2
  set ricavi_incentivi lput ricavo_incentivo ricavi_incentivi
  if ( fascia_potenza  <= 6 )
  [
    ifelse ( kw_immessi < 500000 )
      [
        let ricavo_vendita precision ( kw_immessi * prezzi_minimi_gsef1 ) 2
        set ricavi_vendita lput ricavo_vendita ricavi_vendita
      ]
      [
        ifelse ( kw_immessi >= 500000 and kw_immessi < 1000000 )
        [
          let ricavo_vendita precision ( kw_immessi * prezzi_minimi_gsef2 ) 2
          set ricavi_vendita lput ricavo_vendita ricavi_vendita
        ]
        [
          let ricavo_vendita precision ( kw_immessi * prezzi_minimi_gsef3 ) 2
          set ricavi_vendita lput ricavo_vendita ricavi_vendita
        ]
      ]
  ]
  ;; da definire ricavi vendita per impianti grandi per il momento ho messo <= 6 ma dovrevve essere di 4 IN QUANTO I GRANDI IMPIANTI DEVONO SE NON EFFETTUARE UNA TIPOLOGIA DI RIVENDITA DI TIPO DIRETTO V.TESI
end

;; PROCEDURA INDIVIDUAZIONE RICAVI IMPIANTI INSTALLATI A PARTIRE DAL 2013
to calcola_ricavi_impianti_non2012
  let ricavo_incentivo precision ( kw_autoconsumo * tariffa_autoconsumo ) 2
  set ricavi_incentivi lput ricavo_incentivo ricavi_incentivi
  let ricavo_vendita precision ( kw_immessi * tariffa_omnicomprensiva ) 2
  set ricavi_vendita lput ricavo_vendita ricavi_vendita
end

;; INDIVIDUAZIONE RICAVI IMPLICITI DA AUTOCONSUMO in base alla fascia di consumo e quindi in relazione allo specifico prezzo praticato e attualizzato
to calcola_ricavi_da_autoconsumo
  ifelse ( consumo_medio_annuale  < 1000 )
    [
      let ricavo_autoconsumo   precision ( kw_autoconsumo * costo_kwh_fascia1 ) 2
      set ricavi_autoconsumo lput ricavo_autoconsumo ricavi_autoconsumo      
    ]
    [
      ifelse ( consumo_medio_annuale  >= 1000 and consumo_medio_annuale < 2500 )
        [
          let ricavo_autoconsumo   precision  ( kw_autoconsumo * costo_kwh_fascia2 ) 2 
          set ricavi_autoconsumo lput ricavo_autoconsumo ricavi_autoconsumo 
        ]
        [
          ifelse ( consumo_medio_annuale >= 2500 and consumo_medio_annuale < 5000 )
          [
            let ricavo_autoconsumo  precision  ( kw_autoconsumo * costo_kwh_fascia3 ) 2
            set ricavi_autoconsumo lput ricavo_autoconsumo ricavi_autoconsumo    
          ]
          [
            ifelse ( consumo_medio_annuale >= 5000 and consumo_medio_annuale < 15000 )
            [
              let ricavo_autoconsumo  precision  ( kw_autoconsumo * costo_kwh_fascia4 ) 2
              set ricavi_autoconsumo lput ricavo_autoconsumo ricavi_autoconsumo  
            ]
            
            [
              let ricavo_autoconsumo precision (  kw_autoconsumo * costo_kwh_fascia5 ) 2 
              set ricavi_autoconsumo lput ricavo_autoconsumo ricavi_autoconsumo
              
            ]
          ]
          
        ]
    ]
end

;; CALCOLO DEI COSTI SOSTENUTO PER L'ENERGIA EVENTUALMENTE PRELEVATA
to calcola_costi_energia_prelevata
  ifelse ( kw_prelevati   < 1000 )
    [
      let costo_energia_prelevata   precision ( kw_prelevati  * costo_kwh_fascia1 ) 2
      set costi_energia_prelevata lput costo_energia_prelevata costi_energia_prelevata
      set costi_tot_energia_prelevata precision (costi_tot_energia_prelevata + costo_energia_prelevata ) 2   
    ]
    [
      ifelse ( kw_prelevati >= 1000 and kw_prelevati < 2500 )
        [
          let costo_energia_prelevata   precision  ( kw_prelevati * costo_kwh_fascia2 ) 2 
          set costi_energia_prelevata lput costo_energia_prelevata costi_energia_prelevata
          set costi_tot_energia_prelevata precision (costi_tot_energia_prelevata + costo_energia_prelevata ) 2 
        ]
        [
          ifelse ( kw_prelevati >= 2500 and kw_prelevati < 5000 )
          [
            let costo_energia_prelevata  precision  (kw_prelevati * costo_kwh_fascia3 ) 2
            set costi_energia_prelevata lput costo_energia_prelevata costi_energia_prelevata
            set costi_tot_energia_prelevata precision (costi_tot_energia_prelevata + costo_energia_prelevata ) 2 
          ]
          [
            ifelse ( kw_prelevati >= 5000 and kw_prelevati < 15000 )
            [
              let costo_energia_prelevata  precision  (kw_prelevati * costo_kwh_fascia4 ) 2
              set costi_energia_prelevata lput costo_energia_prelevata costi_energia_prelevata
              set costi_tot_energia_prelevata precision (costi_tot_energia_prelevata + costo_energia_prelevata ) 2 
            ]
            [
              let costo_energia_prelevata precision (  kw_prelevati * costo_kwh_fascia5 ) 2 
              set costi_energia_prelevata lput costo_energia_prelevata costi_energia_prelevata
              set costi_tot_energia_prelevata precision (costi_tot_energia_prelevata + costo_energia_prelevata ) 2 
            ]
          ]
          
        ]
    ]
end

;; PROCEDURA PER INDIVIDUARE IL COSTO TOTALE DELL'INVESTIMENTO valutando eventualmente anche se Esistono incentivi sull'installazione ps. tiene conto di fattori di scala 
to calcola_costi_impianto  
  ifelse (dimensione_impianto <= 10000);10kw
    [
      ;; costo_impianto con pontenza inferiore a 10kw
      set costo_impianto round    ((kw_annui_impianto / Irradiazione_media_annua_kwh_kwp) * Costo_Medio_kwP)     
      ;; compreso di iva (costo impianto  x ( 1,1) ovvero 1  + iva al 10 % 
    ]
    [
      set costo_impianto round  ( ((kw_annui_impianto / Irradiazione_media_annua_kwh_kwp) * Costo_Medio_kwP ) * 0.9 )
    ]
  set costo_impianto round ( costo_impianto * 1.1 )  ;;iva
  if(Incentivi_Installazione)
    [
      set incentivo_installazione round ((costo_impianto * %_Incentivi_Installazione) / 100) 
      set costo_impianto costo_impianto - incentivo_installazione
    ]
  ask pf with [id = 0]
    [set_y_range_plot_PBT]
end  

;; CALCOLO INDICI ROE E ROI
to calcola_roi_roe
 ; (costo_impianto - ifin + intRegione)  
  set roi% precision ((((flusso_cassa_cumulato - ((costo_impianto - ifin + intRegione) - importo_prestito ))  / ( costo_impianto - ifin + intRegione + 0.01 ) ) * 100 ) / durata_impianti )  3
  set roe% precision ((((flusso_cassa_cumulato - ((costo_impianto - ifin + intRegione) - importo_prestito )) / ( (costo_impianto - ifin + intRegione + 0.01 ) - importo_prestito) ) * 100 ) / durata_impianti ) 3
end

;; SET UP GRAFICO PBT
to set_y_range_plot_PBT
  set-current-plot "Pay Back Time"
  let cmin (- costo_impianto + 0 ) 
  set-plot-y-range cmin costo_impianto
  set-plot-x-range 0 durata_impianti 
end

;; UPDATE GRAFICO PBT AGENTE ZERO
to update_plot_PBT
  ask pf with [ semestre_realizzazione = time and ( vita_impianto >= 1 and vita_impianto <= 20 ) ]
  [
    let i 0  
    while [ i <= 10 ]
    [
      if  (id = (NAgentiFINAL * i)  and vita_impianto >= 1 and vita_impianto <= 20 )  
      [ 
        set-current-plot "Pay Back Time"
        set-current-plot-pen (word "Van"( id / NAgentiFINAL ))
        plotxy (vita_impianto - 1.1 + (( id / NAgentiFINAL ) / 10 ) ) 0
        plot last van        
      ]
      set i i + 1
    ]
  ]
end

;; UPDATE FINALE GRAFICO ROE E ROI
to update_plot_roe
  let i 0
  let g 0
  let cry 0
  output-print      ("****************************************************************************************************")
  output-print ( word "***************************************************DATI ROE*****************************************") 
  while [i <= 4]
    [
      set g precision ( (sum [roe%] of pf with  [anno_realizzazione = 2012 + i ] ) / (NAgentiFINAL * 2 ) ) 3
      set-current-plot "Average_ROE"
      set cry 2012 + i 
      set-current-plot-pen (word cry)
      auto-plot-off
      plotxy ( cry - 1  ) 0
      plot g  
      set i i + 1
      output-print ( word "Media ROE anno  "cry " :  " g "%" )
    ]  
end

;; AGGIORNA I COSTI SOSTENUTI PER GLI INCENTIVI SULLA PRODUZIONE (una finezza incredibile!!)
to aggiorna_incentivi_prod
  ask pf 
  [
    ifelse (anno_realizzazione = 2012)
    [
      foreach ricavi_incentivi
      [
        set INCENTIVO_PRO2012 ROUND (INCENTIVO_PRO2012 + ?)
      ]
    ]
    [
      ifelse (anno_realizzazione = 2013)
      [
        foreach ricavi_incentivi
        [
          set INCENTIVO_PRO2013 ROUND (INCENTIVO_PRO2013 + ?)
        ]
        foreach ricavi_vendita
        [
          set INCENTIVO_PRO2013 ROUND (INCENTIVO_PRO2013 + ?)
        ]
      ]
      [
        ifelse (anno_realizzazione = 2014)
        [
          foreach ricavi_incentivi
          [
            set INCENTIVO_PRO2014 ROUND (INCENTIVO_PRO2014 + ?)
          ]
          foreach ricavi_vendita
          [
            set INCENTIVO_PRO2014 ROUND (INCENTIVO_PRO2014 + ?)
          ]
        ]
        
        [
          ifelse (anno_realizzazione = 2015)
          [
            foreach ricavi_incentivi
            [
              set INCENTIVO_PRO2015 ROUND (INCENTIVO_PRO2015 + ?)
            ]
            foreach ricavi_vendita
            [
              set INCENTIVO_PRO2015 ROUND (INCENTIVO_PRO2015 + ?)
            ]
          ]
          
          [
            foreach ricavi_incentivi
            [
              set INCENTIVO_PRO2016 ROUND (INCENTIVO_PRO2016 + ?)
            ]
            foreach ricavi_vendita
            [
              set INCENTIVO_PRO2016 ROUND (INCENTIVO_PRO2016 + ?)
            ]
          ]
        ]
      ]
    ]
  ]
end

;; AGGIORNA SPESA TOTALE INCENTIVI + INSTALLAZIONE
to aggiorna_incentivi_tot
  set INCENTIVO_PROTOT ROUND (INCENTIVO_PRO2012 + INCENTIVO_PRO2013 + INCENTIVO_PRO2014 + INCENTIVO_PRO2015 + INCENTIVO_PRO2016)
  set TOT_SPESA ROUND (INCENTIVO_PROTOT + INCENTIVO_INSTOT)
  set TOT_SPESA2012 (INCENTIVO_PRO2012 + INCENTIVO_INST2012)
  set TOT_SPESA2013 (INCENTIVO_PRO2013 + INCENTIVO_INST2013)
  set TOT_SPESA2014 (INCENTIVO_PRO2014 + INCENTIVO_INST2014)
  set TOT_SPESA2015 (INCENTIVO_PRO2015 + INCENTIVO_INST2015)
  set TOT_SPESA2016 (INCENTIVO_PRO2016 + INCENTIVO_INST2016)
end

;; STAMPA DEL RESOCONTO FINALE
to stampa_resoconto
  output-print      ("****************************************************************************************************")
  output-print (word    "**************************************RESOCONTO IMPIANTI*****************************************")
  output-print ( word   "IMPIANTI REALAZZATI NEL 2012 "  count_pf2012 " RAPPORTO 2012 "  r2012 "%")
  output-print (word    "IMPIANTI REALIZZATI NEL 2013 " count_pf2013 " RAPPORTO 2013 " r2013 "%")
  output-print (word    "IMPIANTI REALIZZATI NEL 2014 " count_pf2014 " RAPPORTO 2014 " r2014 "%")
  output-print (word    "IMPIANTI REALIZZATI NEL 2015 " count_pf2015 " RAPPORTO 2015 " r2015 "%")  
  output-print (word    "IMPIANTI REALIZZATI NEL 2016 " count_pf2016 " RAPPORTO 2016 " r2016 "%") 
  output-print      ("****************************************************************************************************")
  output-print      ("****************************************************************************************************")
  output-print (word "************************************RESOCONTO POTENZA INSTALLATA************************************")
  output-print (word "ANNO 2012: " kW2012 " KwP")
  output-print (word "ANNO 2013: " kW2013 " KwP")
  output-print (word "ANNO 2014: " kW2014 " KwP")
  output-print (word "ANNO 2015: " kW2015 " KwP")
  output-print (word "ANNO 2016: " kW2016 " KwP")
  output-print (word "TOTALE [2012..2016]: " kWTOT " KwP")
  output-print      ("****************************************************************************************************")
  output-print (word "************************************RESOCONTO INCENTIVI ALLA PRODUZIONE*****************************")
  output-print (word "ANNO 2012: " INCENTIVO_PRO2012 " euro")
  output-print (word "ANNO 2013: " INCENTIVO_PRO2013 " euro")
  output-print (word "ANNO 2014: " INCENTIVO_PRO2014 " euro")
  output-print (word "ANNO 2015: " INCENTIVO_PRO2015 " euro")
  output-print (word "ANNO 2016: " INCENTIVO_PRO2016 " euro")
  output-print (word "TOTALE [2012..2016]: " INCENTIVO_PROTOT " euro")
  output-print      ("****************************************************************************************************")
  output-print (word "************************************RESOCONTO INCENTIVI INSTALLAZIONE*******************************")
  output-print (word "ANNO 2012: " INCENTIVO_INST2012 " euro")
  output-print (word "ANNO 2013: " INCENTIVO_INST2013 " euro")
  output-print (word "ANNO 2014: " INCENTIVO_INST2014 " euro")
  output-print (word "ANNO 2015: " INCENTIVO_INST2015 " euro")
  output-print (word "ANNO 2016: " INCENTIVO_INST2016 " euro")
  output-print (word "TOTALE [2012..2016]: " INCENTIVO_INSTOT " euro")
  output-print   ("")
  output-print (word "************************************RESOCONTO TOTALE SPESA******************************************")
  output-print (word "ANNO 2012: " TOT_SPESA2012  " euro")
  output-print (word "ANNO 2013: " TOT_SPESA2013  " euro")
  output-print (word "ANNO 2014: " TOT_SPESA2014  " euro")
  output-print (word "ANNO 2015: " TOT_SPESA2015  " euro")
  output-print (word "ANNO 2016: " TOT_SPESA2016  " euro")
  output-print (word "TOTALE [2012..2016]: " TOT_SPESA " euro")
  output-print (word "************************************RESOCONTO BUDGET ANNUALE******************************************")
  output-print (word "ANNO 2012: " Budget2012  " euro")
  output-print (word "ANNO 2013: " Budget2013  " euro")
  output-print (word "ANNO 2014: " Budget2014  " euro")
  output-print (word "ANNO 2015: " Budget2015  " euro")
  output-print (word "ANNO 2016: " Budget2016  " euro")
end

;; STAMPA DATI DEGLI AGENTI....VARIARE IN BASE ALL'INTERESSE
to stampa_agenti
  ask pf[
    output-print      ("****************************************************************************************************")
    output-print ( word "************************************DATI FINALI IMPIANTO DELL'AGENTE " id "***************************")
    ;; output-print ( word " ricavi_incentivi          " ricavi_incentivi )
    ;; output-print ( word " ricavi_autoconsumo        " ricavi_autoconsumo )
    ;; output-print ( word  " ricavi_vendita            " ricavi_vendita )
    ;; output-print (word   " flusso_cassa              " flusso_cassa )
    ;;output-print (word   " van                       " van )
    output-print (word   " ROE                       " roe% )
    ;; output-print      ("****************************************************************************************************")
  ] 
end

;; ELIMINA SOVRAPPOSIZIONI NEL MONDO VIRTUALE DEGLI IMPIANTI.... 
to elimina_sovrapposizioni
  rt random-float 360
  fd random-float 1
  if any? other pf in-radius 1
    [elimina_sovrapposizioni ]
end

;;STAMPA RISULTATI SINTETICI IN FORMATO ADATTO ( .PL )
to write_pl_file
  ;;file-open "output/risultati_sintetici.pl"
  ;;file-open "/home/b0rgh/ECLiPSe/sourceTesi/risultati_sintetici.pl"
  ;;file-print (word "result(" INCENTIVO_INSTOT ", " %_Incentivi_Installazione ", " INCENTIVO_PROTOT ", " TOT_SPESA ", " kWTOT ").")
  ;;file-close
  file-open "/home/b0rgh/ECLiPSe/sourceTesi/risultati_sintetici_new.pl"
  
  ;;versione iniziale che produce risultati relativi principalmente a tipo di incentivo, buget PV, spesa per PV e produzione finale
  file-print (word "result_new('"fr"'," INCENTIVO_INSTOT ", " %_Incentivi_Installazione ", " TOT_SPESA ","BudgetRegione","BudgetCorrente"," kWTOT").")
  
  ;;seconda versione necessaria per considerare anche l'interazione sociale
  ;;file-print (word "result_new('"fr"'," INCENTIVO_INSTOT ", " %_Incentivi_Installazione ", " TOT_SPESA ","BudgetRegione","BudgetCorrente"," kWTOT"," Raggio","Sensibilita ").")
  file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
255
8
624
398
30
30
5.9
1
10
1
1
1
0
1
1
1
-30
30
-30
30
1
1
1
ticks
30.0

BUTTON
81
10
144
43
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
7
157
217
190
Consumo_medio_annuale_KWh
Consumo_medio_annuale_KWh
2500
30000
15200
10
1
KWh
HORIZONTAL

SLIDER
8
247
225
280
Budget_Medio_MiliaiaEuro
Budget_Medio_MiliaiaEuro
10
200
100
1
1
Mila
HORIZONTAL

SLIDER
8
120
217
153
M2_Disposizione
M2_Disposizione
8
200
100
1
1
m2
HORIZONTAL

SLIDER
8
287
250
320
Media%_copertura_consumi_richiesta
Media%_copertura_consumi_richiesta
0
100
92
1
1
%
HORIZONTAL

SLIDER
6
427
251
460
Irradiazione_media_annua_kwh_kwp
Irradiazione_media_annua_kwh_kwp
900
1900
1350
1
1
KWh
HORIZONTAL

SLIDER
5
471
249
504
Costo_Medio_kwP
Costo_Medio_kwP
3000
5000
3500
50
1
euro
HORIZONTAL

TEXTBOX
10
96
177
114
Parametri Agente Zero 
14
73.0
1

TEXTBOX
681
555
818
573
NIL
11
0.0
1

MONITOR
1531
18
1708
63
Numero Agenti scelta positiva
count_pf
17
1
11

TEXTBOX
853
519
1003
537
Prestiti\n
14
15.0
1

SLIDER
850
549
1085
582
Anni_Restituzione_Prestiti
Anni_Restituzione_Prestiti
1
20
20
1
1
anni
HORIZONTAL

SLIDER
849
590
1087
623
Percentuale_Interessi_Prestito
Percentuale_Interessi_Prestito
1
8
5.3
0.1
1
%
HORIZONTAL

BUTTON
147
10
210
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1458
17
1514
62
Anno
anno
17
1
11

MONITOR
1377
17
1442
62
Semestre
time 
17
1
11

TEXTBOX
435
407
568
425
Prezzi Energia al Kwh\n
14
16.0
1

TEXTBOX
292
414
427
665
		Consumo annuo in kWh	\n\ninferiori a  1.000\n	\n\nda 1.000 a  2.500\n\n\nda 2.500 a 5.000\n\n\nda 5.000 a 15.000\n\n\noltre 15.000	\n
12
0.0
1

SLIDER
396
434
617
467
costo_kwh_fascia1
costo_kwh_fascia1
0.250
0.299
0.278
0.001
1
euro\KWh
HORIZONTAL

SLIDER
396
478
618
511
costo_kwh_fascia2
costo_kwh_fascia2
0.140
0.189
0.162
0.001
1
euro\KWh
HORIZONTAL

SLIDER
395
524
620
557
costo_kwh_fascia3
costo_kwh_fascia3
0.170
0.219
0.194
0.001
1
euro\KWh
HORIZONTAL

SLIDER
396
570
621
603
costo_kwh_fascia4
costo_kwh_fascia4
0.220
0.269
0.246
0.001
1
euro\KWh
HORIZONTAL

SLIDER
395
621
620
654
costo_kwh_fascia5
costo_kwh_fascia5
0.250
0.299
0.276
0.001
1
euro\KWh
HORIZONTAL

CHOOSER
6
620
248
665
Perdita_efficienza_annuale_pannello
Perdita_efficienza_annuale_pannello
0.3 0.5 0.8 1
0

TEXTBOX
284
669
561
747
GSE Prezzi Minimi Garantiti Kw Immessi\ntariffe minime garantite dal gse 2011 per impianti piccoli\nFascia 1 (inferiori a 0.5 Mwh) 0.103 euro\\KWh \nFascia 2 (da 0.5 Mwh a 1 Mwh) 0.086 euro\\KWh\nFascia 3 (da 1 Mwh a 2 Mwh)   0.076 euro\\KWh
11
0.0
1

SLIDER
849
475
1083
508
variazione_annuale_prezzi_elettricita
variazione_annuale_prezzi_elettricita
-10
10
1.8
0.1
1
%
HORIZONTAL

CHOOSER
9
673
248
718
Manutenzione_anno_%costo_totale
Manutenzione_anno_%costo_totale
0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5
10

CHOOSER
7
568
248
613
Riduzione_anno_%costo_pannello
Riduzione_anno_%costo_pannello
0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4
29

TEXTBOX
11
405
244
439
Fotovoltaico Tecnologia e Costi
14
105.0
1

CHOOSER
8
196
217
241
Aumento_%annuo_consumi
Aumento_%annuo_consumi
-1 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9
19

BUTTON
7
10
78
43
NIL
default
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
6
514
248
559
Tecnologia_Pannello
Tecnologia_Pannello
"Monocristallini" "Policristallini" "Silicio_amorfo"
0

SLIDER
8
50
217
83
NumeroAgenti
NumeroAgenti
1
100
50
1
1
NIL
HORIZONTAL

SLIDER
848
430
1082
463
Tasso_lordo_rendimento_BOT
Tasso_lordo_rendimento_BOT
1
6
2.147
0.001
1
%
HORIZONTAL

OUTPUT
1562
443
2228
818
9

PLOT
638
10
1349
396
Pay Back Time
anni
Euro
0.0
20.0
-4000.0
4000.0
false
true
"" ""
PENS
"axis" 1.0 0 -16777216 false "" ""
"Van0" 0.1 1 -16777216 true "" ""
"Van1" 0.1 1 -8330359 true "" ""
"Van2" 0.1 1 -5825686 true "" ""
"Van3" 0.1 1 -6459832 true "" ""
"Van4" 0.1 1 -15637942 true "" ""
"Van5" 0.1 1 -1264960 true "" ""
"Van6" 0.1 1 -13360827 true "" ""
"Van7" 0.1 1 -955883 true "" ""
"Van8" 0.1 1 -7500403 true "" ""
"Van9" 0.1 1 -2674135 true "" ""

PLOT
1099
443
1551
704
Average_ROE
anni
Roe
2012.0
2017.0
0.0
10.0
true
true
"" ""
PENS
"2012" 1.0 1 -10899396 true "" ""
"2013" 1.0 1 -6459832 true "" ""
"2014" 1.0 1 -16777216 true "" ""
"2015" 1.0 1 -13345367 true "" ""
"2016" 1.0 1 -2674135 true "" ""

TEXTBOX
851
402
1108
436
Attualizzazione
14
15.0
1

MONITOR
1377
107
1506
152
kw INSTALLATI 2012
kW2012
17
1
11

MONITOR
1377
325
1506
370
kw INSTALLATI 2016
kW2016
17
1
11

MONITOR
1376
384
1508
429
kw INSTALLATI TOT
kWTOT
17
1
11

MONITOR
1377
157
1505
202
kw INSTALLATI 2013
kW2013\n
17
1
11

MONITOR
1378
213
1506
258
kw INSTALLATI 2014
kW2014
17
1
11

MONITOR
1378
271
1506
316
kw INSTALLATI 2015
kW2015
17
1
11

SWITCH
643
474
829
507
Incentivi_Installazione
Incentivi_Installazione
1
1
-1000

CHOOSER
643
520
829
565
%_Incentivi_Installazione
%_Incentivi_Installazione
1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
0

MONITOR
1520
214
1716
259
INCENTIVI INSTALLAZIONE 2014
INCENTIVO_INST2014
2
1
11

MONITOR
1519
107
1715
152
INCENTIVI INSTALLAZIONE 2012
INCENTIVO_INST2012
2
1
11

MONITOR
1520
160
1716
205
INCENTIVI INSTALLAZIONE 2013
INCENTIVO_INST2013
2
1
11

MONITOR
1520
271
1716
316
INCENTIVI INSTALLAZIONE 2015
INCENTIVO_INST2015
2
1
11

MONITOR
1518
327
1714
372
INCENTIVI INSTALLAZIONE 2016
INCENTIVO_INST2016
2
1
11

MONITOR
1517
381
1716
426
INCENTIVI INSTALLAZIONE TOTALI
INCENTIVO_INSTOT
200
1
11

MONITOR
1727
105
1869
150
INCENTIVI  2012
INCENTIVO_PRO2012
17
1
11

MONITOR
1728
162
1871
207
INCENTIVI 2013
INCENTIVO_PRO2013
17
1
11

MONITOR
1729
216
1869
261
INCENTIVI 2014
INCENTIVO_PRO2014
17
1
11

MONITOR
1729
274
1868
319
INCENTIVI 2015
INCENTIVO_PRO2015
17
1
11

MONITOR
1729
326
1870
371
INCENTIVI 2016
INCENTIVO_PRO2016
17
1
11

MONITOR
1730
384
1872
429
INCENTIVI 
INCENTIVO_PROTOT
200
1
11

MONITOR
1887
106
2013
151
TOTALE SPESA 2012
TOT_SPESA2012
17
1
11

MONITOR
1888
161
2013
206
TOTALE SPESA 2013
TOT_SPESA2013
17
1
11

MONITOR
1888
217
2013
262
TOTALE SPESA 2014
TOT_SPESA2014
17
1
11

MONITOR
1888
271
2012
316
TOTALE SPESA 2015
TOT_SPESA2015
17
1
11

MONITOR
1888
330
2016
375
TOTALE SPESA 2016
TOT_SPESA2016
17
1
11

MONITOR
1889
382
2015
427
SPESA TOTALE
TOT_SPESA
200
1
11

SWITCH
644
576
827
609
Varia_Tariffe_Incetivanti
Varia_Tariffe_Incetivanti
1
1
-1000

CHOOSER
645
618
829
663
%_Variazione_Tariffe
%_Variazione_Tariffe
-30 -29 -28 -27 -26 -25 -24 -23 -22 -21 -20 -19 -18 -17 -16 -15 -14 -13 -12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
30

TEXTBOX
646
404
796
422
Strumenti incentivi
14
105.0
1

SWITCH
8
332
195
365
LeggiSerieStoriche
LeggiSerieStoriche
0
1
-1000

TEXTBOX
1379
83
1529
101
POTENZA INSTALLATA
11
55.0
0

TEXTBOX
1522
84
1711
112
SPESA INCENTIVI INSTALLAZIONE
11
0.0
1

TEXTBOX
1729
85
1889
113
SPESA INCENTIVI PRODUZIONE
11
0.0
1

TEXTBOX
1894
84
2044
102
TOTALE SPESA
11
115.0
0

SWITCH
643
431
830
464
Incentivi_Dinamici
Incentivi_Dinamici
1
1
-1000

TEXTBOX
17
774
251
806
Incentivi regionali
14
105.0
1

CHOOSER
16
798
154
843
fr
fr
"Nessuno" "Asta" "Conto interessi" "Rotazione" "Garanzia"
1

SLIDER
17
850
219
883
BudgetRegione
BudgetRegione
0.1
15
1.5
0.1
1
milioni
HORIZONTAL

TEXTBOX
958
773
1108
791
Interazione sociale
14
105.0
1

SLIDER
958
804
1130
837
Raggio
Raggio
1
10
4
1
1
patches
HORIZONTAL

SWITCH
958
844
1061
877
Intorno
Intorno
1
1
-1000

SLIDER
17
890
189
923
Probfinanz
Probfinanz
0
100
90
1
1
%
HORIZONTAL

PLOT
450
801
853
991
Budget corrente
tempo
Fondi rimasti
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Budget Corrente" 1.0 0 -16777216 true "" "plot BudgetCorrente"

BUTTON
858
841
922
874
NIL
Setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
858
803
921
836
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
450
1003
684
1048
Quanti hanno usufruito degli incentivi regionali
totreg
17
1
11

MONITOR
691
1003
856
1048
Percentuale di chi ha usufruito
percreg
17
1
11

TEXTBOX
158
811
262
829
Tipologia di incentivi
11
0.0
1

TEXTBOX
224
859
357
877
Quantità di risorse allocate
11
0.0
1

TEXTBOX
197
894
347
922
Probabilità del singolo agente di richiedere il finanziamento
11
0.0
1

TEXTBOX
1070
848
1220
876
Visualizzare sulla mappa il raggio di influenza
11
0.0
1

TEXTBOX
1136
804
1286
832
Raggio dentro cui un agente genera influenza
11
0.0
1

TEXTBOX
451
768
601
796
Il plot mostra l'andamento del budget allocato dalla regione
11
0.0
1

SLIDER
19
932
191
965
InterBanca
InterBanca
1
20
5
1
1
%
HORIZONTAL

TEXTBOX
197
939
347
957
Interesi che applica la banca
11
0.0
1

TEXTBOX
199
1020
349
1038
Interessi che applica la regione
11
0.0
1

SLIDER
20
1014
192
1047
InterRegione
InterRegione
1
20
1
1
1
%
HORIZONTAL

SLIDER
20
972
192
1005
Accettato
Accettato
1
100
85
1
1
%
HORIZONTAL

TEXTBOX
199
975
349
1003
Probalibiltà di poter accedere al mutuo in banca
11
0.0
1

SLIDER
20
1055
259
1088
Anni_Restituzione_mutuo_regione
Anni_Restituzione_mutuo_regione
1
30
20
1
1
NIL
HORIZONTAL

TEXTBOX
267
1057
417
1085
Quante rate di pagamaneto impone la regione
11
0.0
1

SLIDER
22
1095
259
1128
Anni_Restituzione_mutuo_banca
Anni_Restituzione_mutuo_banca
1
30
20
1
1
NIL
HORIZONTAL

TEXTBOX
269
1099
419
1127
Quante rate di pagamento impone la banca
11
0.0
1

SLIDER
22
1137
194
1170
FallimentoMutuo
FallimentoMutuo
0
100
10
1
1
%
HORIZONTAL

TEXTBOX
202
1139
352
1167
Probabilità che un agente non riesca più a pagare il mutuo
11
0.0
1

MONITOR
451
1059
508
1104
NIL
r2012
17
1
11

MONITOR
517
1058
574
1103
NIL
r2013
17
1
11

MONITOR
582
1058
639
1103
NIL
r2014
17
1
11

MONITOR
649
1059
706
1104
NIL
r2015
17
1
11

MONITOR
714
1059
771
1104
NIL
r2016
17
1
11

TEXTBOX
452
1109
764
1129
Percentuali di quanti agenti hanno effettuato l'investimento
11
0.0
1

SLIDER
960
886
1132
919
Sensibilita
Sensibilita
0
5
2
0.1
1
NIL
HORIZONTAL

TEXTBOX
1141
884
1291
926
Quanto l'esempio dei vicini influenza l'agente che deve decidere sull'investimento
11
0.0
1

SLIDER
23
1178
195
1211
PercMin
PercMin
1
100
20
1
1
NIL
HORIZONTAL

SLIDER
24
1220
196
1253
PercMax
PercMax
10
100
80
1
1
NIL
HORIZONTAL

TEXTBOX
209
1221
448
1251
Percentuale massima dell'investimento che un agente può chiedere alla regione
11
0.0
1

TEXTBOX
207
1187
450
1215
Percentuale minima dell'investimento che un agente può chiedere alla regione
11
0.0
1

MONITOR
862
1004
960
1049
Scelta negativa
totdied
17
1
11

MONITOR
965
1004
1154
1049
Scelta negativa per fattori economici
totnegsoldi
17
1
11

MONITOR
968
1168
1230
1213
percentuale di scelte negative per fattori economici
perctotnegsoldi
17
1
11

MONITOR
497
1166
583
1211
NIL
percneg2012
17
1
11

MONITOR
591
1167
677
1212
NIL
percneg2013
17
1
11

MONITOR
685
1167
771
1212
NIL
percneg2014
17
1
11

MONITOR
780
1167
866
1212
NIL
percneg2015
17
1
11

MONITOR
874
1168
960
1213
NIL
percneg2016
17
1
11

TEXTBOX
499
1220
933
1239
Percentuale di quanti agenti nell'anno non hanno fatto l'investimento per motivi economici
11
0.0
1

BUTTON
859
880
925
913
NIL
default
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
25
1261
197
1294
InfluenzaRate
InfluenzaRate
1
100
40
1
1
NIL
HORIZONTAL

TEXTBOX
208
1264
358
1292
La presenza delle rate quanto influisce sulle scelte?
11
0.0
1

MONITOR
966
1058
1130
1103
Percentuale di scelte negative
percnegativa
17
1
11

MONITOR
967
1113
1130
1158
Percentuale di scelte positive
percpositive
17
1
11

SLIDER
1279
790
1537
823
BudgetRegione2013
BudgetRegione2013
0
10
0
0.1
1
milioni
HORIZONTAL

SLIDER
1279
833
1537
866
BudgetRegione2014
BudgetRegione2014
0
10
1.8
0.1
1
milioni
HORIZONTAL

SLIDER
1280
875
1538
908
BudgetRegione2015
BudgetRegione2015
0
10
0
0.1
1
milioni
HORIZONTAL

SLIDER
1278
921
1536
954
BudgetRegione2016
BudgetRegione2016
0
10
0
0.1
1
milioni
HORIZONTAL

@#$#@#$#@
## CREDITS AND REFERENCES

Croce Luca crocelu@libero.it

Andrea Borghesi ndr.borghesi@gmail.com
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

sun
false
0
Circle -7500403 true true 75 75 150
Polygon -7500403 true true 300 150 240 120 240 180
Polygon -7500403 true true 150 0 120 60 180 60
Polygon -7500403 true true 150 300 120 240 180 240
Polygon -7500403 true true 0 150 60 120 60 180
Polygon -7500403 true true 60 195 105 240 45 255
Polygon -7500403 true true 60 105 105 60 45 45
Polygon -7500403 true true 195 60 240 105 255 45
Polygon -7500403 true true 240 195 195 240 255 255

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="M2_Disposizione">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Manutenzione_anno_%costo_totale">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Irradiazione_media_annua_kwh_kwp">
      <value value="1350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterRegione">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Consumo_medio_annuale_KWh">
      <value value="15200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_banca">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BudgetRegione">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Perdita_efficienza_annuale_pannello">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media%_copertura_consumi_richiesta">
      <value value="92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FallimentoMutuo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMax">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Budget_Medio_MiliaiaEuro">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumeroAgenti">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia5">
      <value value="0.43"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Dinamici">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfluenzaRate">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fr">
      <value value="&quot;Nessuno&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tecnologia_Pannello">
      <value value="&quot;Monocristallini&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Accettato">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Incentivi_Installazione">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Aumento_%annuo_consumi">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variazione_annuale_prezzi_elettricita">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia2">
      <value value="0.251"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Costo_Medio_kwP">
      <value value="1633"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia1">
      <value value="0.434"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Variazione_Tariffe">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sensibilita">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raggio">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_Prestiti">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Probfinanz">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Varia_Tariffe_Incetivanti">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tasso_lordo_rendimento_BOT">
      <value value="2.147"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Riduzione_anno_%costo_pannello">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMin">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LeggiSerieStoriche">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Installazione">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_regione">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia4">
      <value value="0.385"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia3">
      <value value="0.303"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterBanca">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percentuale_Interessi_Prestito">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intorno">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment1" repetitions="70" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="M2_Disposizione">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Manutenzione_anno_%costo_totale">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Irradiazione_media_annua_kwh_kwp">
      <value value="1350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterRegione">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Consumo_medio_annuale_KWh">
      <value value="15200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_banca">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BudgetRegione">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Perdita_efficienza_annuale_pannello">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media%_copertura_consumi_richiesta">
      <value value="92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FallimentoMutuo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMax">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Budget_Medio_MiliaiaEuro">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumeroAgenti">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia5">
      <value value="0.43"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Dinamici">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfluenzaRate">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fr">
      <value value="&quot;Nessuno&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tecnologia_Pannello">
      <value value="&quot;Monocristallini&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Accettato">
      <value value="85"/>
    </enumeratedValueSet>
    <steppedValueSet variable="%_Incentivi_Installazione" first="2" step="2" last="30"/>
    <enumeratedValueSet variable="Aumento_%annuo_consumi">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variazione_annuale_prezzi_elettricita">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia2">
      <value value="0.251"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Costo_Medio_kwP">
      <value value="1633"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia1">
      <value value="0.434"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Variazione_Tariffe">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sensibilita">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raggio">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_Prestiti">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Probfinanz">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Varia_Tariffe_Incetivanti">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tasso_lordo_rendimento_BOT">
      <value value="2.147"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Riduzione_anno_%costo_pannello">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMin">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LeggiSerieStoriche">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Installazione">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_regione">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia4">
      <value value="0.385"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia3">
      <value value="0.303"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterBanca">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percentuale_Interessi_Prestito">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intorno">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment2" repetitions="400" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="Accettato">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfluenzaRate">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sensibilita">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raggio">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumeroAgenti">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tecnologia_Pannello">
      <value value="&quot;Monocristallini&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMax">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Budget_Medio_MiliaiaEuro">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_banca">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Probfinanz">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Dinamici">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percentuale_Interessi_Prestito">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia5">
      <value value="0.43"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Perdita_efficienza_annuale_pannello">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_Prestiti">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Aumento_%annuo_consumi">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tasso_lordo_rendimento_BOT">
      <value value="2.147"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Installazione">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FallimentoMutuo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_regione">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterRegione">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Consumo_medio_annuale_KWh">
      <value value="15200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fr">
      <value value="&quot;Asta&quot;"/>
      <value value="&quot;Conto interessi&quot;"/>
      <value value="&quot;Rotazione&quot;"/>
      <value value="&quot;Garanzia&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia2">
      <value value="0.251"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia1">
      <value value="0.434"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Riduzione_anno_%costo_pannello">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intorno">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Costo_Medio_kwP">
      <value value="1633"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Incentivi_Installazione">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Variazione_Tariffe">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Irradiazione_media_annua_kwh_kwp">
      <value value="1350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia4">
      <value value="0.385"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterBanca">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media%_copertura_consumi_richiesta">
      <value value="92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Manutenzione_anno_%costo_totale">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMin">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BudgetRegione">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia3">
      <value value="0.303"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M2_Disposizione">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Varia_Tariffe_Incetivanti">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LeggiSerieStoriche">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variazione_annuale_prezzi_elettricita">
      <value value="1.8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimentCI" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="M2_Disposizione">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfluenzaRate">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia5">
      <value value="0.43"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia2">
      <value value="0.251"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia3">
      <value value="0.303"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fr">
      <value value="&quot;Conto interessi&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tasso_lordo_rendimento_BOT">
      <value value="2.147"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterRegione">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Dinamici">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMin">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sensibilita">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LeggiSerieStoriche">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Perdita_efficienza_annuale_pannello">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Irradiazione_media_annua_kwh_kwp">
      <value value="1350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FallimentoMutuo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Probfinanz">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Varia_Tariffe_Incetivanti">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Variazione_Tariffe">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Budget_Medio_MiliaiaEuro">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raggio">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Costo_Medio_kwP">
      <value value="1633"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Consumo_medio_annuale_KWh">
      <value value="15200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterBanca">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Aumento_%annuo_consumi">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Installazione">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_banca">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Accettato">
      <value value="85"/>
    </enumeratedValueSet>
    <steppedValueSet variable="BudgetRegione" first="31" step="1" last="60"/>
    <enumeratedValueSet variable="Manutenzione_anno_%costo_totale">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Incentivi_Installazione">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intorno">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_regione">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Riduzione_anno_%costo_pannello">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumeroAgenti">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia1">
      <value value="0.434"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percentuale_Interessi_Prestito">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media%_copertura_consumi_richiesta">
      <value value="92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia4">
      <value value="0.385"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_Prestiti">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tecnologia_Pannello">
      <value value="&quot;Monocristallini&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variazione_annuale_prezzi_elettricita">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMax">
      <value value="80"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimentA" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="M2_Disposizione">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfluenzaRate">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia5">
      <value value="0.43"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia2">
      <value value="0.251"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia3">
      <value value="0.303"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fr">
      <value value="&quot;Asta&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tasso_lordo_rendimento_BOT">
      <value value="2.147"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterRegione">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Dinamici">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMin">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sensibilita">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LeggiSerieStoriche">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Perdita_efficienza_annuale_pannello">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Irradiazione_media_annua_kwh_kwp">
      <value value="1350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FallimentoMutuo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Probfinanz">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Varia_Tariffe_Incetivanti">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Variazione_Tariffe">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Budget_Medio_MiliaiaEuro">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raggio">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Costo_Medio_kwP">
      <value value="1633"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Consumo_medio_annuale_KWh">
      <value value="15200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterBanca">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Aumento_%annuo_consumi">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Installazione">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_banca">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Accettato">
      <value value="85"/>
    </enumeratedValueSet>
    <steppedValueSet variable="BudgetRegione" first="31" step="1" last="60"/>
    <enumeratedValueSet variable="Manutenzione_anno_%costo_totale">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Incentivi_Installazione">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intorno">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_regione">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Riduzione_anno_%costo_pannello">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumeroAgenti">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia1">
      <value value="0.434"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percentuale_Interessi_Prestito">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media%_copertura_consumi_richiesta">
      <value value="92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia4">
      <value value="0.385"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_Prestiti">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tecnologia_Pannello">
      <value value="&quot;Monocristallini&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variazione_annuale_prezzi_elettricita">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMax">
      <value value="80"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimentR" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="M2_Disposizione">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfluenzaRate">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia5">
      <value value="0.43"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia2">
      <value value="0.251"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia3">
      <value value="0.303"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fr">
      <value value="&quot;Rotazione&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tasso_lordo_rendimento_BOT">
      <value value="2.147"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterRegione">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Dinamici">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMin">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sensibilita">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LeggiSerieStoriche">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Perdita_efficienza_annuale_pannello">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Irradiazione_media_annua_kwh_kwp">
      <value value="1350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FallimentoMutuo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Probfinanz">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Varia_Tariffe_Incetivanti">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Variazione_Tariffe">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Budget_Medio_MiliaiaEuro">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raggio">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Costo_Medio_kwP">
      <value value="1633"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Consumo_medio_annuale_KWh">
      <value value="15200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterBanca">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Aumento_%annuo_consumi">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Installazione">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_banca">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Accettato">
      <value value="85"/>
    </enumeratedValueSet>
    <steppedValueSet variable="BudgetRegione" first="31" step="1" last="60"/>
    <enumeratedValueSet variable="Manutenzione_anno_%costo_totale">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Incentivi_Installazione">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intorno">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_regione">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Riduzione_anno_%costo_pannello">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumeroAgenti">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia1">
      <value value="0.434"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percentuale_Interessi_Prestito">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media%_copertura_consumi_richiesta">
      <value value="92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia4">
      <value value="0.385"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_Prestiti">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tecnologia_Pannello">
      <value value="&quot;Monocristallini&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variazione_annuale_prezzi_elettricita">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMax">
      <value value="80"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimentG" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="M2_Disposizione">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfluenzaRate">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia5">
      <value value="0.43"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia2">
      <value value="0.251"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia3">
      <value value="0.303"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fr">
      <value value="&quot;Garanzia&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tasso_lordo_rendimento_BOT">
      <value value="2.147"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterRegione">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Dinamici">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMin">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sensibilita">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LeggiSerieStoriche">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Perdita_efficienza_annuale_pannello">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Irradiazione_media_annua_kwh_kwp">
      <value value="1350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FallimentoMutuo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Probfinanz">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Varia_Tariffe_Incetivanti">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Variazione_Tariffe">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Budget_Medio_MiliaiaEuro">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raggio">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Costo_Medio_kwP">
      <value value="1633"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Consumo_medio_annuale_KWh">
      <value value="15200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterBanca">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Aumento_%annuo_consumi">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Installazione">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_banca">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Accettato">
      <value value="85"/>
    </enumeratedValueSet>
    <steppedValueSet variable="BudgetRegione" first="31" step="1" last="60"/>
    <enumeratedValueSet variable="Manutenzione_anno_%costo_totale">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Incentivi_Installazione">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intorno">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_regione">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Riduzione_anno_%costo_pannello">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumeroAgenti">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia1">
      <value value="0.434"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percentuale_Interessi_Prestito">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media%_copertura_consumi_richiesta">
      <value value="92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia4">
      <value value="0.385"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_Prestiti">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tecnologia_Pannello">
      <value value="&quot;Monocristallini&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variazione_annuale_prezzi_elettricita">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMax">
      <value value="80"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimentSociale" repetitions="80" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="Aumento_%annuo_consumi">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LeggiSerieStoriche">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Riduzione_anno_%costo_pannello">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia3">
      <value value="0.303"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia5">
      <value value="0.43"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Probfinanz">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_Prestiti">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMin">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media%_copertura_consumi_richiesta">
      <value value="92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variazione_annuale_prezzi_elettricita">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fr">
      <value value="&quot;Asta&quot;"/>
      <value value="&quot;Conto interessi&quot;"/>
      <value value="&quot;Rotazione&quot;"/>
      <value value="&quot;Garanzia&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumeroAgenti">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Variazione_Tariffe">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Perdita_efficienza_annuale_pannello">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia1">
      <value value="0.434"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tecnologia_Pannello">
      <value value="&quot;Monocristallini&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Installazione">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterRegione">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_banca">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intorno">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tasso_lordo_rendimento_BOT">
      <value value="2.147"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Sensibilita" first="5.5" step="0.5" last="20"/>
    <enumeratedValueSet variable="Manutenzione_anno_%costo_totale">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Costo_Medio_kwP">
      <value value="1633"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMax">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Consumo_medio_annuale_KWh">
      <value value="15200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Varia_Tariffe_Incetivanti">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfluenzaRate">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_regione">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BudgetRegione">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Dinamici">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raggio">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Incentivi_Installazione">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M2_Disposizione">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Accettato">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterBanca">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Budget_Medio_MiliaiaEuro">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia4">
      <value value="0.385"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia2">
      <value value="0.251"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Irradiazione_media_annua_kwh_kwp">
      <value value="1350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FallimentoMutuo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percentuale_Interessi_Prestito">
      <value value="5.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimentSocialeRaggio" repetitions="80" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="Aumento_%annuo_consumi">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LeggiSerieStoriche">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Riduzione_anno_%costo_pannello">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia3">
      <value value="0.303"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia5">
      <value value="0.43"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Probfinanz">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_Prestiti">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMin">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media%_copertura_consumi_richiesta">
      <value value="92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variazione_annuale_prezzi_elettricita">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fr">
      <value value="&quot;Asta&quot;"/>
      <value value="&quot;Conto interessi&quot;"/>
      <value value="&quot;Rotazione&quot;"/>
      <value value="&quot;Garanzia&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumeroAgenti">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Variazione_Tariffe">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Perdita_efficienza_annuale_pannello">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia1">
      <value value="0.434"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tecnologia_Pannello">
      <value value="&quot;Monocristallini&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Installazione">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterRegione">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_banca">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intorno">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tasso_lordo_rendimento_BOT">
      <value value="2.147"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sensibilita">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Manutenzione_anno_%costo_totale">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Costo_Medio_kwP">
      <value value="1633"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMax">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Consumo_medio_annuale_KWh">
      <value value="15200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Varia_Tariffe_Incetivanti">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfluenzaRate">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_regione">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BudgetRegione">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Dinamici">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Raggio" first="11" step="1" last="40"/>
    <enumeratedValueSet variable="%_Incentivi_Installazione">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M2_Disposizione">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Accettato">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterBanca">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Budget_Medio_MiliaiaEuro">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia4">
      <value value="0.385"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia2">
      <value value="0.251"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Irradiazione_media_annua_kwh_kwp">
      <value value="1350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FallimentoMutuo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percentuale_Interessi_Prestito">
      <value value="5.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimentN" repetitions="200" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="M2_Disposizione">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InfluenzaRate">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia5">
      <value value="0.43"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia2">
      <value value="0.251"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia3">
      <value value="0.303"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fr">
      <value value="&quot;Nessuno&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tasso_lordo_rendimento_BOT">
      <value value="2.147"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterRegione">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Dinamici">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMin">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sensibilita">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LeggiSerieStoriche">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Perdita_efficienza_annuale_pannello">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Irradiazione_media_annua_kwh_kwp">
      <value value="1350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FallimentoMutuo">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Probfinanz">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Varia_Tariffe_Incetivanti">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Variazione_Tariffe">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Budget_Medio_MiliaiaEuro">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Raggio">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Costo_Medio_kwP">
      <value value="1633"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Consumo_medio_annuale_KWh">
      <value value="15200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InterBanca">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Aumento_%annuo_consumi">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Installazione">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_banca">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Accettato">
      <value value="85"/>
    </enumeratedValueSet>
    <steppedValueSet variable="BudgetRegione" first="0" step="1" last="30"/>
    <enumeratedValueSet variable="Manutenzione_anno_%costo_totale">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Incentivi_Installazione">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Intorno">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_mutuo_regione">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Riduzione_anno_%costo_pannello">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumeroAgenti">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia1">
      <value value="0.434"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percentuale_Interessi_Prestito">
      <value value="5.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media%_copertura_consumi_richiesta">
      <value value="92"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia4">
      <value value="0.385"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_Prestiti">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tecnologia_Pannello">
      <value value="&quot;Monocristallini&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variazione_annuale_prezzi_elettricita">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PercMax">
      <value value="80"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
