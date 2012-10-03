;;DEFINIZIONE VARIABILI GLOBALI DEL MODELLO
globals [ wacc m2Kwp  count_tick scala_dim_impianto time anno number durata_impianti 
         count_pf count_pf2012 count_pf2013 count_pf2014 count_pf2015 count_pf2016  prezzi_minimi_gsef1 prezzi_minimi_gsef2 prezzi_minimi_gsef3  
         random_bgt random_m2 random_ostinazione random_consumo kW2012 kW2013 kW2014 kW2015 kW2016 kWTOT NAgentiFINAL  
         INCENTIVO_INST2012 INCENTIVO_INST2013 INCENTIVO_INST2014 INCENTIVO_INST2015 INCENTIVO_INST2016 INCENTIVO_INSTOT 
         INCENTIVO_PRO2012 INCENTIVO_PRO2013 INCENTIVO_PRO2014 INCENTIVO_PRO2015 INCENTIVO_PRO2016 INCENTIVO_PROTOT 
         TOT_SPESA2012 TOT_SPESA2013 TOT_SPESA2014 TOT_SPESA2015 TOT_SPESA2016 TOT_SPESA 
         r2012 r2013 r2014 r2015 r2016 ]

;; DEFINIZIONE AGENTI E ATTRIBUTI AGENTI
breed [pf]
breed [impianto ]

pf-own [id consumo_medio_annuale budget %cop_cosumi M2disposizione dimensione_impianto tipologia_impianto potenza_impianto fascia_potenza kw_annui_impianto costo_impianto %ostinazione 
       ridimensionamento prestito importo_prestito interessi_prestito rata_annuale_prestito  kw_autoconsumo kw_immessi kw_prelevati  
       anno_realizzazione semestre_realizzazione vita_impianto Data_termine_incentivi tariffa_incentivante tariffa_autoconsumo tariffa_omnicomprensiva 
       ricavi_autoconsumo ricavi_vendita ricavi_incentivi costi_energia_prelevata  costi_tot_energia_prelevata 
       flusso_cassa flusso_cassa_attualizzato flusso_cassa_cumulato  flusso_cassa_attualizzato_cumulato 
       van PBT roi% roe% incentivo_installazione]
impianto-own [anno_realizzazione semestre_realizzazione vita_impianto]

;;PROCEDURA SETUP INIZIALIZZA VARIABILI GLOBALI, GRAFICO roe E GENERA IL PRIMO SET DI AGENTI
to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  output-print (word "--------------------------------------------------------------------------------------------------------------------------------------------------------")
  output-print (word "-------------------------------------------------------------------INIZIO SIMULAZIONE-------------------------------------------------------------------")
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
  output-print (word "--------------------------------------------------------------------------------------------------------------------------------------------------------")
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
if (anno <= 2016 )
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
if (anno = 2017)
[
calcola_rapporto
]
 if (anno = 2016 + durata_impianti + 1   and time = 2 )
 [ 
   update_plot_roe  
   aggiorna_incentivi_prod
   aggiorna_incentivi_tot
   stampa_agenti
   stampa_resoconto
   output-print (word "--------------------------------------------------------------------------------------------------------------------------------------------------------")
   output-print (word "---------------------------------------------------------------------FINE SIMULAZIONE-------------------------------------------------------------------")
   output-print (word "--------------------------------------------------------------------------------------------------------------------------------------------------------")
   export-output (word "Output/Simulazione_"random 10000 "_con agenti_" NumeroAgenti"_Variazione_Incentivi_produzione_"Varia_Tariffe_Incetivanti "_Percentuale_" %_Variazione_Tariffe"_Incentivi_Installazione_" Incentivi_Installazione".txt")
   output-print (word "Totale incentivi installazione: " INCENTIVO_INSTOT " euro" )
   output-print (word "Totale incentivi produzione: " INCENTIVO_PROTOT " euro" )
   output-print (word "Totale spesa: " TOT_SPESA " euro" )
   output-print (word "Totale potenza installata: " kWTOT " KwP" )
   
   ;;producono file utili per ottimizatore
   write_to_file
   write_pl_file
   
   ;;resetta alcune variabili per non avere probemi con simulazioni successive
   reset_var
 
   stop 
   ]
 if ( time = 2 )
 [
    set time 0
    set anno anno + 1
    aggiorna_prezzi
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
clear-output
end


;;SETUP DI VARIABILI CHE VENGONO MODIFICATE IN 'GO' MA DEVONO ESSERE RIPRISTINATE AI VALORI INIZIALI NEL CASO DI ESECUZIONI SUCCESSIVE
to reset_var
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
end

;; SETUP A RUN TIME DI VARIABILI GLOBALI CHE NON VENGONO VARIANO DURANTE L'ESECUZIONE
to set_global
set durata_impianti 20
set count_tick 0
set time 1
set anno 2012
set count_pf 0
set WACC Tasso_lordo_rendimento_BOT 
set scala_dim_impianto 0.5
set NAgentiFINAL NumeroAgenti
ifelse (Tecnologia_Pannello = "Monocristallini"  )
[
 set m2Kwp  8
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
genera_random
end


;; PROCEDURA CHE SI SOSTITUISCE ALLA LETTURA DA SERIE STORICHE E GENERA NUMERI PSEUDO CASUALI  DA ATTIBUIRE AGLI AGENTI E LI INSERISCE IN APPOSITE LISTE
to genera_random
let c 0
set random_ostinazione []
set random_m2 []
set random_bgt []
set random_consumo []
while [ c <  ( NAgentiFINAL - 1 ) ]
[
   set c c + 1 
   set number random 100
   if (number < 1 ) [set number 1 ]   
   set random_ostinazione lput  number random_ostinazione 
   set number random-float 10
   if (number < 1 ) [set number 1]
   set random_m2 lput number random_m2
   set number random-float 10
   if (number < 1 )[ set number 1 ]
   set random_bgt lput number random_bgt
   set number random-float 10
   if (number < 1 ) [set number 1]
   set random_consumo lput number random_consumo
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
    set-default-shape pf "house"
     ask n-of NAgentiFINAL patches
    [
     sprout-pf 1 
     [ 
     elimina_sovrapposizioni 
     set count_pf count_pf + 1
     set id who
     genera_pf
     valuta_fattibilita_impianto
     ]    
    ] 
     
end


;; PROCEDURA CHE GENERA IL SET DI AGENTI: RICORDIAMO IL PRIMO AGENTE DI OGNI SET ASSUME I VALORI INDICATI TRAMITE INTERFACCIA GLI ALTRI AGENTI PRELEVANO I DATI O DAL FILE "SerieStoriche.txt" OPPURE PRELEVANDOLI DALLE LISTE E CALCOLA LE DIMENSIONI E I COSTI DELL'IMPIANTO
to genera_pf
 set prestito false
 set ridimensionamento false 
 set incentivo_installazione 0
 ifelse (id = 0 or id = (NAgentiFINAL * count_tick ) )
   
      ;;GENERAZIONE AGENTE ZERO
      [
       set %ostinazione  100;
       set consumo_medio_annuale  Consumo_medio_annuale_KWh
       set budget Budget_Medio_MiliaiaEuro * 1000
       set M2disposizione M2_Disposizione
       set %cop_cosumi Media%_copertura_consumi_richiesta
       ]
[
  ;;PROCEDURA LETTURA DA FILE
  ifelse ( LeggiSerieStoriche and file-exists? "SerieStoriche.txt" )
  [
     
     let finish false
     let count_t 0
     file-open "SerieStoriche.txt"
     while [ not file-at-end? and not finish]
     [
      
       let letto file-read
       set count_t count_t + 1
       if (count_t = ((id * 4) + 1) )
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
   [
    ;;PROCEDURA SERIE CASUALI PRELEVANDO DA LISTE
      set %ostinazione item  (id - ( NAgentiFINAL * count_tick ) - 1 ) random_ostinazione 
      set consumo_medio_annuale round  (item  (id - ( NAgentiFINAL * count_tick ) - 1 ) random_consumo ) * Consumo_medio_annuale_KWh
      set budget round (item  (id - ( NAgentiFINAL * count_tick ) - 1 ) random_bgt )  * Budget_Medio_MiliaiaEuro * 1000
      set M2disposizione round (item  (id - ( NAgentiFINAL * count_tick ) - 1 ) random_m2 )  * M2_Disposizione
      set %cop_cosumi  Media%_copertura_consumi_richiesta
    ]
]
   calcola_dimensione
   calcola_costi_impianto
   set ricavi_vendita []
   set ricavi_autoconsumo []
   set ricavi_incentivi []
   set costi_energia_prelevata []
   set flusso_cassa []
   set flusso_cassa_attualizzato []
   set van []
   set PBT  "non rilevato"
end

;; PROCEDURA CHE CALCOLA LE DIMENSIONI DELL'IMPIANTO A PARTIRE DAI DATI AGENTE
to calcola_dimensione
      ;; calcolo della potenza dell ' impianto : CONSUMO_MEDIO_ANNUALE *  %Obbiettivo copertura consumi energetici 
      set kw_annui_impianto round ((consumo_medio_annuale *  %cop_cosumi) / 100 )
      ;; calcolo dimensione M2 impianto
      set dimensione_impianto (round  (kw_annui_impianto / Irradiazione_media_annua_kwh_kwp) * m2kwp )
end

;; PROCEDURA VALUTAZIONE FATTIBILIT� INVESTIMENTO (V. FLOW CHART)
to valuta_fattibilita_impianto
  
    ifelse (dimensione_impianto <=  M2disposizione ) and (costo_impianto <=  budget )
      [
        ;;set size ( dimensione_impianto / scala_dim_impianto )
        set color green
        aumenta_impianto
        calcola_fascia_potenza
        calcola_tariffa_gse
        aggiorna_kW
        aggiorna_incentivi_installazione
        aggiorna_pf
        stampa
      ]
      [
        ifelse (dimensione_impianto >  M2disposizione ) and (costo_impianto >  budget )
        [
          
          output-print   ("*************************************************************************************************")
          output-print  (word   "************** AGENTE " id  "realizzazione impianto impossibile : Eccedenza dimensionamento e costi") 
          output-print  (word   "DIE")
          output-print   ("*************************************************************************************************")
          set count_pf count_pf - 1
          die 
        ]
        [
     
          ifelse (dimensione_impianto >  M2disposizione ) 
          [ accetta_ridimensionamento  ]
          [ accetta_prestito ]
      ]
    ]
end


;; VALUTAZIONE AUMENTO DIMENSIONI E POTENZA IMPIANTO IN BASE A OSTINAZIONE
to aumenta_impianto
let dim_imp dimensione_impianto
if ( %ostinazione > 50)
[
   set dimensione_impianto M2disposizione  
   set kw_annui_impianto (round ( dimensione_impianto / m2Kwp )) * Irradiazione_media_annua_kwh_kwp
   calcola_costi_impianto
   if (costo_impianto >= budget)
   [
   set dimensione_impianto dim_imp 
   set kw_annui_impianto (round ( dimensione_impianto / m2Kwp )) * Irradiazione_media_annua_kwh_kwp
   calcola_costi_impianto
   ]
]  
end

;; VALUTAZIONE RIDIMENSIONAMENTO POTENZA E DIMENSIONE IMPIANTO
to accetta_ridimensionamento
    let dimensione_eccedenza dimensione_impianto - M2disposizione
    ifelse (dimensione_eccedenza <= round ( ( M2disposizione * %ostinazione) / 100 ) )
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
    aggiorna_pf
    stampa
    ] 
    [
           output-print         ("*************************************************************************************************")
           output-print  (word   "************** AGENTE " id  "realizzazione impianto impossibile : Ridimensionamento non accettato") 
           output-print  (word   "DIE")
           output-print   ("*************************************************************************************************")
           set count_pf count_pf - 1
           die
     ]
end

;; VALUTAZIONE IPOTESI PRESTITO
to accetta_prestito
  let Sforo_Budget costo_impianto - Budget
  ifelse (Sforo_Budget <= round ( ( Budget * %ostinazione) / 100 ) )
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
    aggiorna_pf 
    stampa
        
    ] 
    [
             output-print         ("*************************************************************************************************")
             output-print  (word   "************** AGENTE " id  "realizzazione impianto impossibile : Prestito non accettato**************") 
             output-print  (word   "DIE")
             output-print   ("")
             set count_pf count_pf - 1
             die
    ]
end  


;; PROCEDURA PER IL CALCOLO DEGLI INTERESSI LEGATI AL PRESTITO
to calcola_interessi
;;calcolo rata alla francese
set rata_annuale_prestito (round (( importo_prestito * (Percentuale_Interessi_Prestito / 100) ) / (1 - ( (1 + (Percentuale_Interessi_Prestito / 100) ) ^ (- Anni_Restituzione_Prestiti) ) ) ) )
set interessi_prestito ( rata_annuale_prestito *  Anni_Restituzione_Prestiti ) - importo_prestito
end

;; PROCEDURA ASSEGNAZIONE FASCIA POTENZA
to calcola_fascia_potenza
  set potenza_impianto dimensione_impianto / m2Kwp
  ifelse ( potenza_impianto > 1 and potenza_impianto <= 3 )
   [
    set fascia_potenza  1
    set size  scala_dim_impianto * fascia_potenza
    set tipologia_impianto "Su edificio piccolo"
   ]
   [
   ifelse ( potenza_impianto > 3 and potenza_impianto <= 20 )
     [
       set fascia_potenza  2
       set size scala_dim_impianto * fascia_potenza
       set tipologia_impianto "Su edificio piccolo"
     ]
     [
   ifelse ( potenza_impianto > 20 and potenza_impianto <= 200 )
       [
         set fascia_potenza  3
         set size scala_dim_impianto * fascia_potenza
          set tipologia_impianto "Su edificio piccolo"
       ]
       [
         ifelse ( potenza_impianto > 200 and potenza_impianto <= 1000 )
         [
            set tipologia_impianto "Su edificio piccolo"
            set size scala_dim_impianto * fascia_potenza
           set fascia_potenza  4
         ]
         [
            ifelse ( potenza_impianto > 1000 and potenza_impianto <= 5000 )
            [
              set tipologia_impianto "Su edificio grande"
              set size scala_dim_impianto * fascia_potenza
              set fascia_potenza  5
            ]
            [
              set tipologia_impianto "Su edificio grande"
              set size scala_dim_impianto * fascia_potenza
              set fascia_potenza  6
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
        output-print  (word   "Costo: " costo_impianto " �")
        output-print  (word   "Potenza: " potenza_impianto " kWp")
        output-print  (word   "Fascia Potenza: " fascia_potenza)
        output-print  (word   "Tipologia Impianto: "tipologia_impianto)
        ifelse( anno_realizzazione >= 2013)
        [output-show ( word    "Anno impianto "  anno_realizzazione " Semestre " semestre_realizzazione " Tariffa ominocompresiva "    tariffa_omnicomprensiva " Tariffa autoconsumo " tariffa_autoconsumo )]
        [output-show ( word   "Anno impianto "  anno_realizzazione " Semestre " semestre_realizzazione " Tariffa incentivante  " tariffa_incentivante )]  
        output-print  (word   "Incentivi Installazione: " incentivo_installazione "� Ridimensionamento: " ridimensionamento " Prestito: " prestito )
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


;; CALCOLA LA PERCENTUALE DI AGENTI CHE DECIDONO DI EFFETTUARE L'IMPIANTO
to calcola_rapporto
  set r2012  precision ((count_pf2012 * 100) / (NAgentiFINAL * 2)) 2
  set r2013  precision ((count_pf2013 * 100) / (NAgentiFINAL * 2)) 2
  set r2014  precision ((count_pf2014 * 100) / (NAgentiFINAL * 2)) 2
  set r2015  precision ((count_pf2015 * 100) / (NAgentiFINAL * 2)) 2
  set r2016  precision ((count_pf2016 * 100) / (NAgentiFINAL * 2)) 2
end


;; PROCEDURA PER LA LETTURA DELLA TARIFFA RICONOSCIUTA (dati prelevati da file in cartella di lancio)
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
    set consumo_medio_annuale round ( consumo_medio_annuale  +  (( consumo_medio_annuale * Aumento_%annuo_consumi ) / 100) )
    set kw_annui_impianto round ( kw_annui_impianto - (( kw_annui_impianto * Perdita_efficienza_annuale_pannello ) / 100 ) )
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
ask pf with [ semestre_realizzazione = time and ( vita_impianto >= 1 and vita_impianto <= 20 ) ]
  [
   calcola_ricavi_da_autoconsumo
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
   let rata rata_annuale_prestito
   let ric_vendita last ricavi_vendita
   let costi_annuali precision ((costo_impianto * Manutenzione_anno_%costo_totale)  / 100 ) 2
   let flusso_c precision ( (ric_incentivo + ric_autoconsumo + ric_vendita ) - (rata + costi_annuali ) ) 2
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
  
  ifelse (dimensione_impianto <= 10000)
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
   set roi% precision ((((flusso_cassa_cumulato - (costo_impianto - importo_prestito ))  / costo_impianto) * 100 ) / durata_impianti )  3
   set roe% precision ((((flusso_cassa_cumulato - (costo_impianto - importo_prestito )) / (costo_impianto - importo_prestito)) * 100 ) / durata_impianti ) 3
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
output-print (word "ANNO 2012: " INCENTIVO_PRO2012 " �")
output-print (word "ANNO 2013: " INCENTIVO_PRO2013 " �")
output-print (word "ANNO 2014: " INCENTIVO_PRO2014 " �")
output-print (word "ANNO 2015: " INCENTIVO_PRO2015 " �")
output-print (word "ANNO 2016: " INCENTIVO_PRO2016 " �")
output-print (word "TOTALE [2012..2016]: " INCENTIVO_PROTOT " �")
output-print      ("****************************************************************************************************")
output-print (word "************************************RESOCONTO INCENTIVI INSTALLAZIONE*******************************")
output-print (word "ANNO 2012: " INCENTIVO_INST2012 " �")
output-print (word "ANNO 2013: " INCENTIVO_INST2013 " �")
output-print (word "ANNO 2014: " INCENTIVO_INST2014 " �")
output-print (word "ANNO 2015: " INCENTIVO_INST2015 " �")
output-print (word "ANNO 2016: " INCENTIVO_INST2016 " �")
output-print (word "TOTALE [2012..2016]: " INCENTIVO_INSTOT " �")
 output-print   ("")
output-print (word "************************************RESOCONTO TOTALE SPESA******************************************")
output-print (word "ANNO 2012: " TOT_SPESA2012  " �")
output-print (word "ANNO 2013: " TOT_SPESA2013  " �")
output-print (word "ANNO 2014: " TOT_SPESA2014  " �")
output-print (word "ANNO 2015: " TOT_SPESA2015  " �")
output-print (word "ANNO 2016: " TOT_SPESA2016  " �")
output-print (word "TOTALE [2012..2016]: " TOT_SPESA " �")
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

;; STAMPA DATI UTILI PER INTERAZIONE CON OTTIMIZZATORE GLOBALE
to write_to_file
  file-open "output/RisultatiSintetici.txt"
  file-print (word "Totale incentivi installazione: " INCENTIVO_INSTOT " euro" )
  file-print (word "Totale incentivi produzione: " INCENTIVO_PROTOT " euro" )
  file-print (word "Totale spesa: " TOT_SPESA " euro" )
  file-print (word "Totale potenza installata: " kWTOT " KwP" )
  file-print ""  ;; blank line
  file-close
end

;;STAMPA RISULTATI SINTETICI IN FORMATO ADATTO ( .PL )
to write_pl_file
  ;;file-open "output/risultati_sintetici.pl"
  file-open "/home/b0rgh/ECLiPSe/sourceTesi/risultati_sintetici.pl"
  file-print (word "result(" INCENTIVO_INSTOT ", " %_Incentivi_Installazione ", " INCENTIVO_PROTOT ", " TOT_SPESA ", " kWTOT ").")
  file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
250
4
598
373
30
30
5.541
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
0
0
1
ticks
30.0

BUTTON
79
29
142
62
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
5
178
215
211
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
6
268
215
301
Budget_Medio_MiliaiaEuro
Budget_Medio_MiliaiaEuro
10
200
100
1
1
Mila�
HORIZONTAL

SLIDER
6
141
215
174
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
6
308
248
341
Media%_copertura_consumi_richiesta
Media%_copertura_consumi_richiesta
0
100
100
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
4300
50
1
�
HORIZONTAL

TEXTBOX
8
81
226
121
Parametri Agente Zero 
14
73.0
1

TEXTBOX
628
602
765
620
NIL
11
0.0
1

MONITOR
1499
22
1613
67
Numero Agenti
count_pf
17
1
11

TEXTBOX
798
569
948
587
Prestiti\n
14
15.0
1

SLIDER
795
599
1030
632
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
794
640
1032
673
Percentuale_Interessi_Prestito
Percentuale_Interessi_Prestito
1
8
4.2
0.1
1
%
HORIZONTAL

BUTTON
145
29
208
62
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
1407
20
1478
65
Anno
anno
17
1
11

MONITOR
1326
20
1391
65
Semestre
time 
17
1
11

TEXTBOX
358
372
594
448
Prezzi Energia al Kwh\n
14
16.0
1

TEXTBOX
277
401
512
657
		Consumo annuo in kWh	\n\ninferiori a  1.000\n	\n\nda 1.000 a  2.500\n\n\nda 2.500 a 5.000\n\n\nda 5.000 a 15.000\n\n\noltre 15.000	\n
12
0.0
1

SLIDER
387
419
564
452
costo_kwh_fascia1
costo_kwh_fascia1
0.250
0.299
0.278
0.001
1
�\KWh
HORIZONTAL

SLIDER
386
463
565
496
costo_kwh_fascia2
costo_kwh_fascia2
0.140
0.189
0.162
0.001
1
�\KWh
HORIZONTAL

SLIDER
386
509
565
542
costo_kwh_fascia3
costo_kwh_fascia3
0.170
0.219
0.194
0.001
1
�\KWh
HORIZONTAL

SLIDER
387
555
566
588
costo_kwh_fascia4
costo_kwh_fascia4
0.220
0.269
0.246
0.001
1
�\KWh
HORIZONTAL

SLIDER
386
606
566
639
costo_kwh_fascia5
costo_kwh_fascia5
0.250
0.299
0.276
0.001
1
�\KWh
HORIZONTAL

CHOOSER
6
620
248
665
Perdita_efficienza_annuale_pannello
Perdita_efficienza_annuale_pannello
0.3 0.5 0.8 1
1

TEXTBOX
272
652
542
764
GSE Prezzi Minimi Garantiti Kw Immessi\ntariffe minime garantite dal gse 2011 per impianti piccoli\nFascia 1 (inferiori a 0.5 Mwh) 0.103 �\\KWh \nFascia 2 (da 0.5 Mwh a 1 Mwh) 0.086 �\\KWh\nFascia 3 (da 1 Mwh a 2 Mwh)   0.076 �\\KWh\n\n\n
11
0.0
1

SLIDER
795
521
1029
554
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
5

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
6
217
215
262
Aumento_%annuo_consumi
Aumento_%annuo_consumi
-1 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9
0

BUTTON
5
29
76
62
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
6
101
215
134
NumeroAgenti
NumeroAgenti
1
100
100
1
1
NIL
HORIZONTAL

SLIDER
795
476
1029
509
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
1516
443
1967
703
9

PLOT
608
20
1319
432
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
1047
440
1499
701
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
800
444
1057
478
Attualizzazione
14
15.0
1

MONITOR
1326
110
1455
155
kw INSTALLATI 2012
kW2012
17
1
11

MONITOR
1326
328
1455
373
kw INSTALLATI 2016
kW2016
17
1
11

MONITOR
1325
387
1457
432
kw INSTALLATI TOT
kWTOT
17
1
11

MONITOR
1326
160
1454
205
kw INSTALLATI 2013
kW2013\n
17
1
11

MONITOR
1327
216
1455
261
kw INSTALLATI 2014
kW2014
17
1
11

MONITOR
1327
274
1455
319
kw INSTALLATI 2015
kW2015
17
1
11

SWITCH
590
521
770
554
Incentivi_Installazione
Incentivi_Installazione
0
1
-1000

CHOOSER
588
566
771
611
%_Incentivi_Installazione
%_Incentivi_Installazione
1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
18

MONITOR
1469
217
1665
262
INCENTIVI INSTALLAZIONE 2014
INCENTIVO_INST2014
2
1
11

MONITOR
1468
110
1664
155
INCENTIVI INSTALLAZIONE 2012
INCENTIVO_INST2012
2
1
11

MONITOR
1469
163
1665
208
INCENTIVI INSTALLAZIONE 2013
INCENTIVO_INST2013
2
1
11

MONITOR
1469
274
1665
319
INCENTIVI INSTALLAZIONE 2015
INCENTIVO_INST2015
2
1
11

MONITOR
1467
330
1663
375
INCENTIVI INSTALLAZIONE 2016
INCENTIVO_INST2016
2
1
11

MONITOR
1466
384
1665
429
INCENTIVI INSTALLAZIONE TOTALI
INCENTIVO_INSTOT
200
1
11

MONITOR
1676
108
1818
153
INCENTIVI  2012
INCENTIVO_PRO2012
17
1
11

MONITOR
1677
165
1820
210
INCENTIVI 2013
INCENTIVO_PRO2013
17
1
11

MONITOR
1678
219
1818
264
INCENTIVI 2014
INCENTIVO_PRO2014
17
1
11

MONITOR
1678
277
1817
322
INCENTIVI 2015
INCENTIVO_PRO2015
17
1
11

MONITOR
1678
329
1819
374
INCENTIVI 2016
INCENTIVO_PRO2016
17
1
11

MONITOR
1679
387
1821
432
INCENTIVI 
INCENTIVO_PROTOT
200
1
11

MONITOR
1836
109
1962
154
TOTALE SPESA 2012
TOT_SPESA2012
17
1
11

MONITOR
1837
164
1962
209
TOTALE SPESA 2013
TOT_SPESA2013
17
1
11

MONITOR
1837
220
1962
265
TOTALE SPESA 2014
TOT_SPESA2014
17
1
11

MONITOR
1837
274
1961
319
TOTALE SPESA 2015
TOT_SPESA2015
17
1
11

MONITOR
1837
333
1965
378
TOTALE SPESA 2016
TOT_SPESA2016
17
1
11

MONITOR
1838
385
1964
430
SPESA TOTALE
TOT_SPESA
200
1
11

SWITCH
587
623
770
656
Varia_Tariffe_Incetivanti
Varia_Tariffe_Incetivanti
1
1
-1000

CHOOSER
585
663
771
708
%_Variazione_Tariffe
%_Variazione_Tariffe
-30 -29 -28 -27 -26 -25 -24 -23 -22 -21 -20 -19 -18 -17 -16 -15 -14 -13 -12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
30

TEXTBOX
595
446
745
464
Strumenti incentivi
14
105.0
1

SWITCH
6
353
193
386
LeggiSerieStoriche
LeggiSerieStoriche
0
1
-1000

TEXTBOX
1328
86
1478
104
POTENZA INSTALLATA
11
55.0
0

TEXTBOX
1471
87
1660
115
SPESA INCENTIVI INSTALLAZIONE
11
0.0
1

TEXTBOX
1678
88
1838
116
SPESA INCENTIVI PRODUZIONE
11
0.0
1

TEXTBOX
1843
87
1993
105
TOTALE SPESA
11
115.0
0

SWITCH
590
478
777
511
Incentivi_Dinamici
Incentivi_Dinamici
1
1
-1000

@#$#@#$#@
## CREDITS AND REFERENCES

Croce Luca crocelu@libero.it
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
  <experiment name="experiment0" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="Riduzione_anno_%costo_pannello">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Dinamici">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Installazione">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M2_Disposizione">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_Prestiti">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia1">
      <value value="0.278"/>
    </enumeratedValueSet>
    <steppedValueSet variable="%_Incentivi_Installazione" first="1" step="1" last="20"/>
    <enumeratedValueSet variable="Varia_Tariffe_Incetivanti">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Budget_Medio_MiliaiaEuro">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tecnologia_Pannello">
      <value value="&quot;Monocristallini&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Variazione_Tariffe">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media%_copertura_consumi_richiesta">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variazione_annuale_prezzi_elettricita">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia2">
      <value value="0.162"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumeroAgenti">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Costo_Medio_kwP">
      <value value="4300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Irradiazione_media_annua_kwh_kwp">
      <value value="1350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Aumento_%annuo_consumi">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia3">
      <value value="0.194"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Perdita_efficienza_annuale_pannello">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia5">
      <value value="0.276"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Consumo_medio_annuale_KWh">
      <value value="15200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Manutenzione_anno_%costo_totale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LeggiSerieStoriche">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tasso_lordo_rendimento_BOT">
      <value value="2.133"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percentuale_Interessi_Prestito">
      <value value="4.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia4">
      <value value="0.246"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment1" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="Tasso_lordo_rendimento_BOT">
      <value value="2.147"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Riduzione_anno_%costo_pannello">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia1">
      <value value="0.278"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumeroAgenti">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Installazione">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tecnologia_Pannello">
      <value value="&quot;Monocristallini&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Media%_copertura_consumi_richiesta">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variazione_annuale_prezzi_elettricita">
      <value value="1.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="M2_Disposizione">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Budget_Medio_MiliaiaEuro">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Costo_Medio_kwP">
      <value value="4300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Consumo_medio_annuale_KWh">
      <value value="15200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Incentivi_Dinamici">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Incentivi_Installazione">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Irradiazione_media_annua_kwh_kwp">
      <value value="1350"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia3">
      <value value="0.194"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia4">
      <value value="0.246"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Anni_Restituzione_Prestiti">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Perdita_efficienza_annuale_pannello">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percentuale_Interessi_Prestito">
      <value value="4.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LeggiSerieStoriche">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%_Variazione_Tariffe">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Varia_Tariffe_Incetivanti">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Manutenzione_anno_%costo_totale">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia2">
      <value value="0.162"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Aumento_%annuo_consumi">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="costo_kwh_fascia5">
      <value value="0.276"/>
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
