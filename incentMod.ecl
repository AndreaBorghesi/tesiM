:- [titoli_press].
:- [opere_press].
:- [ricet_press].
:- lib(eplex).
:- lib(matrix_util).
:- lib(listut).
:- lib(util).
%:- [magnitudo].
:- [limiti].
:- lib(var_name).
:- [aaai11].
:- [costi_impianti].
:- [crea_csv].
:- import append/3 from eclipse_language.
:- [incentivi].
:- [misc].
:- [sub_problem].
:- [nogoods].



% Vecchio goal, sulla potenza: va accoppiato con il predicato outcome/1 sulle potenze in aaai11.pl 
ppow(L):- aaai(max((1-L)*ric(9)-L*costo),_,2300).


:- dynamic pareto_front/3.

pareto(Type,File):-
    retract_all(pareto_front(_,_,_)),
    (Type=ele -> energia_elettrica_richiesta(EnergiaElettricaRichiesta),
                 EnergiaTermicaRichiesta=0
                 %FileName = 'pareto_ele.txt'
              ;  energia_termica_richiesta(EnergiaTermicaRichiesta),
                 EnergiaElettricaRichiesta=0
                 %FileName = 'pareto_term.txt'
    ),
    (
        aaai(max(ric(9)),_,EnergiaElettricaRichiesta,EnergiaTermicaRichiesta,Ricettori,Costo),
        nth1(9,Ricettori,QualitaAria),eplex:eplex_var_get(QualitaAria,typed_solution,ValoreQualitaAria),
        assert(pareto_front(0,ValoreQualitaAria,Costo)), fail
    ;   true %pareto_front(0,QualitaAria,Costo)
    ),
    (
        aaai(min(costo),_,EnergiaElettricaRichiesta,EnergiaTermicaRichiesta,RicettoriMinC,CostoMinC),
        nth1(9,RicettoriMinC,QualitaAriaMinC),eplex:eplex_var_get(QualitaAriaMinC,typed_solution,ValoreQualitaAriaMinC),
        assert(pareto_front(1,ValoreQualitaAriaMinC,CostoMinC)), fail
    ;   true %pareto_front(1,QualitaAriaMinC,CostoMinC)
    ),
    pareto(Type,0,1),
    piani_pareto(Type),
    csv_pareto(File).

pareto(_,Min,Max):- Max-Min<1e-11,!.
pareto(Type,Min,Max):-
    (Type=ele -> energia_elettrica_richiesta(EnergiaElettricaRichiesta),
                 EnergiaTermicaRichiesta=0
              ;  energia_termica_richiesta(EnergiaTermicaRichiesta),
                 EnergiaElettricaRichiesta=0),
    L is (Max+Min)/2,
    (
        aaai(max((1-L)*ric(9)-L*costo),_,EnergiaElettricaRichiesta,EnergiaTermicaRichiesta,Ricettori,Costo),
        nth1(9,Ricettori,QualitaAria),eplex:eplex_var_get(QualitaAria,typed_solution,ValoreQualitaAria),
        assert(pareto_front(L,ValoreQualitaAria,Costo)), fail
    ;   pareto_front(L,ValoreQualitaAria,Costo)
    ),
    pareto_front(Min,_AriaMin,CostoMin),
    (Costo<CostoMin ->  pareto(Type,Min,L) ; true),
    pareto_front(Max,AriaMax,_CostoMax),
    (ValoreQualitaAria>AriaMax ->  pareto(Type,L,Max) ; true).
    
% dato il fronte di Pareto fornito con fatti pareto_front/3,
% salva i piani in opportune cartelle
piani_pareto(Type):-
    findall(pareto_front(L,Aria,Costo),pareto_front(L,Aria,Costo),Lripetizioni),
    sort([2],<,Lripetizioni,ParetoFront),
    piani_pareto_loop(Type,ParetoFront,0).

piani_pareto_loop(_,[],_).
piani_pareto_loop(Type,[pareto_front(L,_,_)|ParetoFront],Num):-
    concat_string([pareto,Num],Folder),
    ottimizza(Type,_,_,Folder,_,_,max((1-L)*ric(9)-L*costo)),
    Num1 is Num+1,
    piani_pareto_loop(Type,ParetoFront,Num1).

richiesta_energia(ele,Elettrica,0):- energia_elettrica_richiesta(Elettrica).
richiesta_energia(term,0,Termica):- energia_termica_richiesta(Termica).


grafico_tot(Type,Anno):-
    fonti(Type,Fonti),
    (Type=ele -> FileName = 'pareto_ele.txt'
              ;  FileName = 'pareto_term.txt'
    ),
    open(FileName,write,File),
    stampa_riga_csv(File,["L","Qualita` Aria","Costo","Piano"|Fonti]),
    piano_ampliato(Type,Anno),
    pareto(Type,File),
    piano(Type,Anno),
    ottimizza(Type,QualitaAriaPiano,CostoPiano,"piano"), CostoPianoMln is CostoPiano/1e6,
    stampa_riga_csv(File,["piano" ,QualitaAriaPiano,    ""     ,CostoPianoMln  ]),
    piano_ampliato(Type,Anno),
    ottimizza(Type,QualitaAriaDomina1,CostoDomina1,"pari_aria",_,QualitaAriaPiano,min(costo)), % Punto Domina1, con qualita` dell'aria pari al piano
    CostoDomina1Mln is CostoDomina1/1e6,
    stampa_riga_csv(File,["pari aria" ,QualitaAriaDomina1,   CostoDomina1Mln]),
    ottimizza(Type,QualitaAriaDomina2,CostoDomina2,"pari_costo",CostoPiano,_,max(ric(9))),  % Punto Domina2, con costo pari al piano
    CostoDomina2Mln is CostoDomina2/1e6,
    stampa_riga_csv(File,["pari costo" ,QualitaAriaDomina2,   CostoDomina2Mln]),
    (   singole_fonti(Type,File)
    ;   close(File)
    ).

ottimizza(Type,QualitaAria,Costo,Folder):-
    ottimizza(Type,QualitaAria,Costo,Folder,_,_).
ottimizza(Type,QualitaAria,Costo,Folder,Budget,MinQualitaAria):-
    L=0.5,
    ottimizza(Type,QualitaAria,Costo,Folder,Budget,MinQualitaAria,max((1-L)*ric(9)-L*costo)).
ottimizza(Type,QualitaAria,Costo,Folder,Budget,MinQualitaAria,FunzioneObiettivo):-
    shelf_create(risultato(_Aria,_Costo),Shelf),
    richiesta_energia(Type,EnergiaElettricaRichiesta,EnergiaTermicaRichiesta),
    (   create_folder(Folder),cd(Folder),
        aaai(FunzioneObiettivo,Budget,EnergiaElettricaRichiesta,EnergiaTermicaRichiesta,Ricettori,Costo,MinQualitaAria),
        nth1(9,Ricettori,RicettoreQualitaAria), eplex:eplex_var_get(RicettoreQualitaAria,typed_solution,QualitaAria), 
        shelf_set(Shelf,1,QualitaAria),
        shelf_set(Shelf,2,Costo),
        cd(".."),
        fail
    ;   shelf_get(Shelf,1,QualitaAria),
        shelf_get(Shelf,2,Costo)
    ).

% Nuovo goal, sull'energia: va accoppiato con il predicato outcome/1 sulle energie in aaai11.pl 
p(L):- 
    energia_elettrica_richiesta(EnergiaElettricaRichiesta),
    energia_termica_richiesta(EnergiaTermicaRichiesta),
    aaai(max((1-L)*ric(9)-L*costo),_,EnergiaElettricaRichiesta,EnergiaTermicaRichiesta).
ele(L):- energia_elettrica_richiesta(EnergiaElettricaRichiesta), aaai(max((1-L)*ric(9)-L*costo),_,EnergiaElettricaRichiesta,0).
term(L):- energia_termica_richiesta(EnergiaTermicaRichiesta), aaai(max((1-L)*ric(9)-L*costo),_,0,EnergiaTermicaRichiesta).
% Questo 177.27 e` stato calcolato cosi`:
% - Per ogni fonte energetica faccio la differenza fra la potenza obiettivo al 2013 (nell'ipotesi del 20%)
%   e la stima al 2010.
% - Per ogni fonte energetica, calcolo i ktep/MW
% - prodotto delle 2 cose scritte sopra mi da` l'energia da installare per ogni fonte
% - faccio la somma per tutte le fonti
% Il 290 per il termico, invece, e` calcolato su dati sbagliati per cui e` del tutto arbitrario

% Stampa in quale modo si pessimizza ciascuno dei ricettori, sapendo che si devono fare NumOpere diverse
% (Stampa 23 ricettori, se il numero cambia, va cambiato)
peggiora_ricettori(NumOpere):-
    between(1,23,R), ricet_opere(R,NumOpere,_,_,_), fail.



% Predicato per AAAI.
% parte da valuta_piano e in piu` impone i seguenti vincoli
% 1. primary/secondary activities
% 2. budget
% 3. expected outcome. Per questo, usa le magnitudo
% 4. differenziazione?

% L'outcome e` in MW
% il budget e` in euro
aaai(Obiettivo,Budget,Outcome,OutcomeTermico):-
    aaai(Obiettivo,Budget,Outcome,OutcomeTermico,_,_).
aaai(Obiettivo,Budget,Outcome,OutcomeTermico,Ricettori,ValoreCosto):-
    aaai(Obiettivo,Budget,Outcome,OutcomeTermico,Ricettori,ValoreCosto,_,_).
aaai(Obiettivo,Budget,Outcome,OutcomeTermico,Ricettori,ValoreCosto,MinQualitaAria):-
    aaai(Obiettivo,Budget,Outcome,OutcomeTermico,Ricettori,ValoreCosto,MinQualitaAria,_).
aaai(Obiettivo,Budget,Outcome,OutcomeTermico,Ricettori,ValoreCosto,MinQualitaAria,VarObiettivo):-
    functor(Obiettivo,Direzione,1),
    FunzObiettivo =.. [Direzione,VarObiettivo],
	%eplex:eplex_solver_setup(FunzObiettivo),
    %eplex:eplex_set(dual_solution,yes),
    
    % Creazione Pressioni
    pressioni(TitoliPress),
    length(TitoliPress,NumPress),
    crea_var(NumPress,Pressioni,-1000000,1000000),

%%%%%%%%%%% Creazione Opere %%%%%%%%%%%%%%%
    findall(OperePress,m_opere_press(_,_,OperePress),LoLOperePress),
    length(LoLOperePress,NumOpere),
    findall(TitOpere,opere_press(_,TitOpere,_),TitoliOpere),
    crea_var_names(TitoliOpere,Opere,0,1000000),
%    eplex:integers(Opere),
    outcome(Outcomes),
    eplex:(Outcomes*Opere $= EnergiaProdotta),
    eplex:(EnergiaProdotta $= Outcome),

    outcome_termico(OutcomesTermici),
    eplex:(OutcomesTermici*Opere $= EnergiaTermicaProdotta),
    eplex:(EnergiaTermicaProdotta $= OutcomeTermico),

    % Impongo il vincolo di primary/secondary activities (vincolo 1).
   primary_secondary_activities(Opere,TitoliOpere,[]),
    %length(Rilassati,NumRilassati), %NumRilassati>20, NumRilassati<50, writeln(numrilassati(NumRilassati)),
    
%%%%%%%%%%%%  Creazione incentivi %%%%%%%%%%%%%%%%%%%
    %incentivi(TitoliInc),
    %length(TitoliInc,NumInc),
    %crea_var(NumInc,Incentivi,0,100000000000),
    
    incentivi(TitoliInc),
    length(TitoliInc,NumInc),
    %con la variabile incentivi rappresento il valore totale degli incentivi che deve essere minore del budget per gli incentivi al PV
    crea_var(NumInc,Incentivi,0,1000000000),
    crea_var(NumInc,IncPerc,0,40),
    
    eplex:integers(IncPerc),
    
    %budget fotovoltaico ( in teoria è indicato dalla regione e dell'ordine di qualche Mln di euro l'anno )
    eplex:(BudgetPV $:: 0..1000000000),
    eplex:(BudgetPV $= 5000000 ),
    
    %relazione tra percentuale incentivi e totale incentivi 
    name_variable("Impianti fotovoltaici",OperaPV,TitoliOpere,Opere),
	%inc_constraint(OperaPV,"Impianti fotovoltaici",IncPerc,Incentivi,TitoliInc),

    % Vincolo di costo
    cost_constraint(Opere,TitoliOpere,CostTerm),
    
    % somma degli incentivi
    sum_inc(Incentivi,IncTot),
    
    %eplex:(CostTerm$=Costo),	 %versione precedente 
    %eplex:(CostTerm $=< Budget), %versione precedente  
    		
    eplex:(CostTerm+IncTot$=Costo),											
    eplex:(CostTerm+IncTot+BudgetPV $=< Budget),  %vincolo su costi e incentivi
    
    %costo_opere(CostoOpere),
    %eplex:(CostoOpere*Opere $=< Budget),

    % Vincolo di diversificazione
    vincolo_min_max(Opere,TitoliOpere),

%    vincolo_rinnovabili(Opere,TitoliOpere,TermineEnergiaRinnovabile),  Questo mi sembra obsoleto, considerando che c'e` anche l'energia termica adesso
%    eplex:(TermineEnergiaRinnovabile $>= 0.3 * EnergiaProdotta),

    azzera_opere_terziarie(Opere,TitoliOpere),

%%%%%%%%%% Creazione Ricettori %%%%%%%%%%%%%%%%%%
    findall(RicetPress,m_ricet_press(_,RicetPress),LoLRicetPress),
    length(LoLRicetPress,NumRicet),
    crea_var(NumRicet,Ricettori,-1000000,1000000),

    nth1(9,Ricettori,QualitaAria),
    eplex:(QualitaAria $>= MinQualitaAria),

    % Calcolo la trasposta
    %length(LoLOperePress,N1), LoLOperePress=[RIGA|_], length(RIGA,N2),
    matrix(NumOpere,NumPress,LoLOperePress,LoLPressOpere),

    somma_righe(Ricettori,Pressioni,LoLRicetPress),
    somma_righe(Pressioni,Opere,LoLPressOpere),

%    unifica(Opere,Magnitudo),

%    eplex:(sum(Opere) $= NumOpereComm),


    %nth1(IndiceRicet,Ricettori,X),
    obiettivo(Obiettivo,EnergiaProdotta,EnergiaTermicaProdotta,Costo,Ricettori,FunObiettivo), 
    eplex:(VarObiettivo $= FunObiettivo),
    
    %nogood_constraint_read/2 trova i vincoli nogood generati da benders_dec e inseriti dentro nogoods.pl
    [nogoods],
    nogood_constraint_read(IncPerc,TitoliInc),
    
    %eplex:eplex_solve(VarObiettivo),
    eplex:eplex_solver_setup(FunzObiettivo,VarObiettivo,[dual_solution(yes)],[deviating_bounds,bounds,new_constraint]),
    
    inc_constraint(OperaPV,"Impianti fotovoltaici",IncPerc,Incentivi,TitoliInc),
    %occorrerebbe anche un vincolo che leghi gli incentivi totali al budget per il fotovoltaico --> incentiviPV <= budgetPV
    
    %perchè non posso chiamarlo qui senza avere problemi?
    %eplex:eplex_solve(VarObiettivo),
    
%    findall(TitRicet,ricet_press(TitRicet,_),TitoliRicet),
%    print_solution(Ricettori,TitoliRicet)
    open('ris.txt',write,outfile),
    writeln_tee("====================== Opere ======================"),
    somma_liste(Outcomes,OutcomesTermici,OutcomesTotali),
    print_solution_opere(Opere,TitoliOpere,OutcomesTotali),

    csv_opere_ricettori(Opere,TitoliOpere),
    csv_costi_tot(Opere,TitoliOpere),
    csv_energie(Opere,TitoliOpere,Outcomes),
    csv_costi_dett(Opere,TitoliOpere),
    csv_tabella_arpa(Opere,TitoliOpere,Outcomes,OutcomesTermici),

    writeln_tee("====================== Pressioni ======================"),
    print_solution(Pressioni,TitoliPress),

    writeln_tee("====================== Ricettori ======================"),
    findall(TitRicet,ricet_press(TitRicet,_),TitoliRicet),
    print_solution(Ricettori,TitoliRicet),
    
    writeln_tee("====================== Incentivi 	======================"),
    print_solution(Incentivi,TitoliInc),
    writeln_tee("====================== Incentivi Percentuale======================"),
    print_solution(IncPerc,TitoliInc),

    
    writeln_tee("====================== Obiettivi ======================"),
    %le 2 righe successive al posto della terza altrimenti stampa la variabile VarObiettivo e non solo il suo valore
    eplex:eplex_var_get(VarObiettivo,typed_solution,ValVarOb),  
    write_tee('Obiettivo: '), write_tee(Obiettivo), write_tee(' = '),  writeln_tee(ValVarOb),
    %write_tee('Obiettivo: '), write_tee(Obiettivo), write_tee(' = '),  writeln_tee(VarObiettivo), 
    eplex:eplex_var_get(Costo,typed_solution,ValoreCosto),  writeln_tee(costo(ValoreCosto)),
    eplex:eplex_var_get(EnergiaProdotta,typed_solution,ValoreEnergiaProdotta),  writeln_tee(energia(ValoreEnergiaProdotta)),
    
    
    %benders dec
    name_variable("Impianti fotovoltaici",IncPercPV,TitoliInc,IncPerc),
    name_variable("Impianti fotovoltaici",IncentiviPV,TitoliInc,Incentivi),
    eplex:eplex_var_get(IncentiviPV,typed_solution,ValoreIncentiviPV),
    eplex:eplex_var_get(IncPercPV,typed_solution,ValoreIncPercPV),
    eplex:eplex_var_get(BudgetPV,typed_solution,ValoreBudgetPV),
    
    budget_outcomePV(CostoPV,OutcomePV),
	writeln_tee("====================== PV info ======================"),
	write_tee("Percentuale incentivi"), write_tee(':\t'), writeln_tee(ValoreIncPercPV),
	write_tee("Spesa incentivi stanziati ( costi impianti*percentuale incentivi )"), write_tee(':\t'), writeln_tee(ValoreIncentiviPV),
	write_tee("Costo totale fotovoltaico ( costi impianti )"), write_tee(':\t'), writeln_tee(CostoPV),
	write_tee("Budget stanziato dalla regione per gli incentivi al fotovoltaico"), write_tee(':\t'), writeln_tee(ValoreBudgetPV),
	write_tee("Outcome da fotovoltaico richiesto"), write_tee(':\t'), writeln_tee(OutcomePV),
    %benders_dec(IncPercPV,IncentiviPV,OutcomePV),
    
    writeln_tee("====================== Fine ======================"),
    close(outfile).

% You tried predicate aaai with some values for Budget, Electrical and thermal energy,
% it failed and you do not know why?
% ask predicate why_not(Budget,Electrical,Thermal).
% It will un-assign one of the three variables and print the minimum and maximum allowed value
% for such variable
why_not(Budget,Outcome,OutcomeTermico):-
    Params=[Budget,Outcome,OutcomeTermico],
    ParamNames=[costo,energia,termica],

    findall(Value,
        (   substitute_var0(I,Params,X,NewParams),
            nth0(I,ParamNames,ParName),
            append([min(ParName)|NewParams],[_,_,_,Value],AllParameters),
            Goal =.. [aaai|AllParameters],
            (call(Goal) -> true ; Value = fail)
        ),Minimums),
    findall(Value,
        (   substitute_var0(I,Params,X,NewParams),
            nth0(I,ParamNames,ParName),
            append([max(ParName)|NewParams],[_,_,_,Value],AllParameters),
            Goal =.. [aaai|AllParameters],
            (call(Goal) -> true ; Value = fail)
        ),Maximums),

    print_intervals(Params,ParamNames,Minimums,Maximums).

substitute_var0(0,[_|T],X,[X|T]).
substitute_var0(N,[H|T],X,[H|T1]):-
    (var(N) -> true ; N>0),
    substitute_var0(N1,T,X,T1), N is N1+1.


print_intervals(Params,ParamNames,Minimums,Maximums):-
    open('why_not.csv',write,File),
    writeln(" ==== POSSIBLE INTERVALS ==== "),
(
    nth1(I,Params,_,Rest),
    nth1(I,ParamNames,Name,RestNames),
    nth1(I,Minimums,Min),
    nth1(I,Maximums,Max),
    (foreach(Par,Rest), foreach(Name,RestNames), param(File) do
        write_tee(File,Name), write('='), write(File,','),
        write_tee(File,Par), write_tee(File,',')
    ),
    write_tee(File,' --> '), write(Name), write(' in '), writeln(Min..Max),
    write(File,','),
    stampa_riga_csv(File,[Name,Min,Max]),
    fail
;   close(File)).


obiettivo(max(T),Energia,Termica,Costo,Ricettori,F):- funzione_obiettivo(T,Energia,Termica,Costo,Ricettori,F).
obiettivo(min(T),Energia,Termica,Costo,Ricettori,F):- funzione_obiettivo(T,Energia,Termica,Costo,Ricettori,F).

funzione_obiettivo(energia,Energia,_,_,_,Energia):-!.
funzione_obiettivo(termica,_,Termica,_,_,Termica):-!.
funzione_obiettivo(costo,_,_,Costo,_,Costo):-!.
funzione_obiettivo(electric,Energia,_,_,_,Energia):-!.
funzione_obiettivo(thermal,_,Termica,_,_,Termica):-!.
funzione_obiettivo(cost,_,_,Costo,_,Costo):-!.
funzione_obiettivo(ric(IndiceRicet),_,_,_,Ricettori,X):-!, nth1(IndiceRicet,Ricettori,X).
funzione_obiettivo(rec(IndiceRicet),_,_,_,Ricettori,X):-!, nth1(IndiceRicet,Ricettori,X).
funzione_obiettivo(A+B,Energia,Termica,Costo,Ricettori,FA+FB):-!,
    funzione_obiettivo(A,Energia,Termica,Costo,Ricettori,FA),
    funzione_obiettivo(B,Energia,Termica,Costo,Ricettori,FB).
funzione_obiettivo(A-B,Energia,Termica,Costo,Ricettori,FA-FB):-!,
    funzione_obiettivo(A,Energia,Termica,Costo,Ricettori,FA),
    funzione_obiettivo(B,Energia,Termica,Costo,Ricettori,FB).
funzione_obiettivo(C*X,Energia,Termica,Costo,Ricettori,C*F):- ground(C),!,
    funzione_obiettivo(X,Energia,Termica,Costo,Ricettori,F).
funzione_obiettivo(X*C,Energia,Termica,Costo,Ricettori,C*F):- ground(C),!,
    funzione_obiettivo(X,Energia,Termica,Costo,Ricettori,F).
funzione_obiettivo(_,_,_,_,_,_):- errore('Funzione obiettivo non lineare').

errore(X):- writeln(X), fail.

% prendo lo stesso modello di valuta_piano e provo a vedere se funziona quadratic programming
quadratic(IndiceRicet,Gap,Ottimo):-
     eplex:eplex_solver_setup(min(X*X)),
    eplex:eplex_set(dual_solution,yes),

    magnitudo(Magnitudo),
    length(Magnitudo,NumMag),     writeln(num_magnitudo(NumMag)),

    % Creazione Pressioni
    pressioni(TitoliPress),
    length(TitoliPress,NumPress),
    crea_var(NumPress,Pressioni,-10000,10000),

    % Creazione Opere
    findall(OperePress,m_opere_press(_,_,OperePress),LoLOperePress),
    length(LoLOperePress,NumOpere),
%    crea_var(NumOpere,Opere,0,100),
    crea_var_gap(NumOpere,Opere,Magnitudo,Gap),
    writeln(num_opere(NumOpere)),
%    eplex:integers(Opere),

    % Creazione Ricettori
    findall(RicetPress,m_ricet_press(_,RicetPress),LoLRicetPress),
    length(LoLRicetPress,NumRicet),
    crea_var(NumRicet,Ricettori,-10000,10000),

    % Calcolo la trasposta
    %length(LoLOperePress,N1), LoLOperePress=[RIGA|_], length(RIGA,N2),
    matrix(NumOpere,NumPress,LoLOperePress,LoLPressOpere),

    somma_righe(Ricettori,Pressioni,LoLRicetPress),
    somma_righe(Pressioni,Opere,LoLPressOpere),

%    unifica(Opere,Magnitudo),

%    eplex:(sum(Opere) $= NumOpereComm),

    nth1(IndiceRicet,Ricettori,X),
    eplex:(X$>=1), % Aggiungo un vincolo in modo che non mi dia 0
    eplex:eplex_solve(Ottimo), % Cambio la variabile, senno` potrebbe fallire (visto che non ottimizzo piu` X, ma X^2)
%    findall(TitRicet,ricet_press(TitRicet,_),TitoliRicet),
%    print_solution(Ricettori,TitoliRicet)
    writeln("====================== Opere ======================"),
    findall(TitOpere,opere_press(_,TitOpere,_),TitoliOpere),
    print_solution(Opere,TitoliOpere),

    writeln("====================== Pressioni ======================"),
    print_solution(Pressioni,TitoliPress),

    writeln("====================== Ricettori ======================"),
    findall(TitRicet,ricet_press(TitRicet,_),TitoliRicet),
    print_solution(Ricettori,TitoliRicet).
    

ricet_opere(IndiceRicet,NumOpereComm,Pressioni,Opere,Ricettori) :-
     eplex:eplex_solver_setup(min(X)),

    % Creazione Pressioni
    pressioni(TitoliPress),
    length(TitoliPress,NumPress),
    crea_var(NumPress,Pressioni,-100,100),

    % Creazione Opere
    findall(OperePress,m_opere_press(_,_,OperePress),LoLOperePress),
    length(LoLOperePress,NumOpere),
    crea_var(NumOpere,Opere,0,1),
    eplex:integers(Opere),

    % Creazione Ricettori
    findall(RicetPress,m_ricet_press(_,RicetPress),LoLRicetPress),
    length(LoLRicetPress,NumRicet),
    crea_var(NumRicet,Ricettori,-100,100),

    % Calcolo la trasposta
    %length(LoLOperePress,N1), LoLOperePress=[RIGA|_], length(RIGA,N2),
    matrix(NumOpere,NumPress,LoLOperePress,LoLPressOpere),

    somma_righe(Ricettori,Pressioni,LoLRicetPress),
    somma_righe(Pressioni,Opere,LoLPressOpere),

    eplex:(sum(Opere) $= NumOpereComm),

    nth1(IndiceRicet,Ricettori,X),
    eplex:eplex_solve(X),

    % Stampa solo Ricettore -> Opere
    findall(TitRicet,ricet_press(TitRicet,_),TitoliRicet),
    nth1(IndiceRicet,TitoliRicet,TitoloRicettoreSel),
    write(TitoloRicettoreSel), write(' -> '),
    findall(TitOpere,opere_press(_,TitOpere,_),TitoliOpere),
    print_solution(Opere,TitoliOpere).

% Per il confronto con Fabrizio:
% produco una tabella che per ogni coppia opera-ricettore
% mi dice come va il ricettore se faccio 1 di quell'opera
tabella :-
     eplex:eplex_solver_setup(max(X)),

    % Creazione Pressioni
    pressioni(TitoliPress),
    length(TitoliPress,NumPress),
    crea_var(NumPress,Pressioni,-100,100),

    % Creazione Opere
    findall(OperePress,m_opere_press(_,_,OperePress),LoLOperePress),
    length(LoLOperePress,NumOpere),
    crea_var(NumOpere,Opere,0,1),
    eplex:integers(Opere),

    % Creazione Ricettori
    findall(RicetPress,m_ricet_press(_,RicetPress),LoLRicetPress),
    length(LoLRicetPress,NumRicet),
    crea_var(NumRicet,Ricettori,-100,100),

    % Calcolo la trasposta
    %length(LoLOperePress,N1), LoLOperePress=[RIGA|_], length(RIGA,N2),
    matrix(NumOpere,NumPress,LoLOperePress,LoLPressOpere),

    somma_righe(Ricettori,Pressioni,LoLRicetPress),
    somma_righe(Pressioni,Opere,LoLPressOpere),

    eplex:(sum(Opere) $= 1),

    open("risultato_lineare.csv",write,csv),
    Comma=",",
    write(csv,Comma),

    findall(TitRicet,ricet_press(TitRicet,_),TitoliRicet),
    csv_list(TitoliRicet,csv,Comma), nl(csv),


    findall(TitOpere,opere_press(_,TitOpere,_),TitoliOpere),

    nth1(IndiceOpera,Opere,X),
    nth1(IndiceOpera,TitoliOpere,NomeOpera),

    write(csv,'"'),write(csv,NomeOpera), write(csv,'"'), write(csv,Comma),

    eplex:eplex_solve(X),

    csv_list_solution(Ricettori,csv,Comma),
    nl(csv),

    false.
tabella :- close(csv).

/*  % STAMPA TUTTI I DATI
    writeln("=== Opere ==="),
    findall(TitOpere,opere_press(TitOpere,_),TitoliOpere),
    print_solution(Opere,TitoliOpere),

    writeln("=== Pressioni ==="),
    print_solution(Pressioni,TitoliPress),

    writeln("=== Ricettori ==="),
    findall(TitRicet,ricet_press(TitRicet,_),TitoliRicet),
    print_solution(Ricettori,TitoliRicet),

    nth1(IndiceRicet,LoLRicetPress,RigaOut),
    stampa_lista(RigaOut),
    writeln(x(X)).
*/

%vincolo_rinnovabili(Opere,TitoliOpere,EnergiaRinnovabile):-
vincolo_rinnovabili([],[],0).
vincolo_rinnovabili([Op|Opere],[Titolo|TitoliOpere],Op+EnergiaRinnovabile):-   % ATTENZIONE CHE QUI LA MAGNITUDO VIENE CONSIDERATA IN MW, QUINDI IL COEFFICIENTE E` 1
    rinnovabile(Titolo),!,
    vincolo_rinnovabili(Opere,TitoliOpere,EnergiaRinnovabile).
vincolo_rinnovabili([_|Opere],[_|TitoliOpere],EnergiaRinnovabile):-
    vincolo_rinnovabili(Opere,TitoliOpere,EnergiaRinnovabile).
    

azzera_opere_terziarie([],[]).
azzera_opere_terziarie([Opera|Opere],[Titolo|TitoliOpere]):-
    ((prim_sec(Titolo,_,_) ; prim_sec(_,Titolo,_))
        ->  true
        ;   eplex:(Opera $= 0)
    ),
    azzera_opere_terziarie(Opere,TitoliOpere).

primary_secondary_activities(Opere,TitOpere,Rilassati):-
    primary_secondary_activities(Opere,TitOpere,Opere,TitOpere,Rilassati,_).

primary_secondary_activities([],_,_,_,[],0):-!.
primary_secondary_activities([OperaSec|OpereSec],[TitOperaSec|TitOpereSec],OperePrim,TitOperePrim,RilassatiOut,NumRil):-
    opere_primarie(OperaSec,TitOperaSec,OperePrim,TitOperePrim,PrimarieCoinvolte,CoeffPrimarieCoinvolte),
    (CoeffPrimarieCoinvolte=[] -> RilassatiOut=RilassatiTemp, NumRil=NumRilTemp
    ;    (eplex:(CoeffPrimarieCoinvolte*PrimarieCoinvolte $= OperaSec),  RilassatiOut=RilassatiTemp, NumRil=NumRilTemp
%             ;  NumRil>0, RilassatiOut=[TitOperaSec|RilassatiTemp], NumRilTemp is NumRil-1
         )
    ),
    primary_secondary_activities(OpereSec,TitOpereSec,OperePrim,TitOperePrim,RilassatiTemp,NumRilTemp).

% Trova le opere primarie corrispondenti all'opera secondaria
% opere_primarie(OperaSec,TitOperaSec,OperePrim,TitToperePrim,PrimarieCoinvolte,CoeffPrimarieCoinvolte)
opere_primarie(_,_,[],[],[],[]):- !.
opere_primarie(OperaSec,TitOperaSec,[OpPrim|OperePrim],[TitOperaPrim|TitToperePrim], 
                                    [OpPrim|PrimarieCoinvolte],[Coeff|CoeffPrimarieCoinvolte]):-
    prim_sec(TitOperaPrim,TitOperaSec,AltoMedioBasso),
    conv_amb(AltoMedioBasso,Coeff),Coeff\=0,!,
    opere_primarie(OperaSec,TitOperaSec,OperePrim,TitToperePrim,PrimarieCoinvolte,CoeffPrimarieCoinvolte).
opere_primarie(OperaSec,TitOperaSec,[_|OperePrim],[_|TitToperePrim], 
                                    PrimarieCoinvolte,CoeffPrimarieCoinvolte):-
    opere_primarie(OperaSec,TitOperaSec,OperePrim,TitToperePrim,PrimarieCoinvolte,CoeffPrimarieCoinvolte).

%%%%%%%%%%%% cost constraint %%%%%%%%%%%%%%%
cost_constraint([],[],0).
cost_constraint([Opera|Opere],[Titolo|TitoliOpere],CostoOpera+CostTermTemp):-
    prim_sec(Titolo,_,_),!, % considero solo il costo delle opere primarie
    costo_opera(Opera,Titolo,CostoOpera),
    cost_constraint(Opere,TitoliOpere,CostTermTemp).
cost_constraint([_|Opere],[_|TitoliOpere],CostTermTemp):-
    cost_constraint(Opere,TitoliOpere,CostTermTemp).
    
    
%%%%%%%%%%%%% somma incentivi %%%%%%%%%%%%%%%%%%
sum_inc([],0).
sum_inc([Incentivo|Incentivi],IncTermTot):-
	sum_inc(Incentivi,IncTermTemp),
	IncTermTot = IncTermTemp+Incentivo.
	
%%%%%%%%%%% relazione incentivi totali e percentuale  %%%%%%%%%%
inc_constraint(_,_,[],[],[]).
inc_constraint(Opera,Titolo,[IP|IncentPerc],[IT|IncenTot],[Titolo|TitoliInc]):-!,
	costi_impianti(Titolo,_,_,CostoInvestimentoIniziale,_,_),
	%costo_opera(Opera,Titolo,CostoOpera),
	%Inc = IP*CostoOpera/100,
	
	%non è una bella soluzione: lego gli incentivi al valore finale di Opera, non alla variabile stessa
	eplex:eplex_var_get(Opera,typed_solution,ValoreOpera),
	Inc = IP*CostoInvestimentoIniziale*ValoreOpera*0.01,
	
	eplex:(IT $= Inc ),
	
	inc_constraint(Opera,Titolo,IncentPerc,IncenTot,TitoliInc).
inc_constraint(Opera,Titolo,[_|IncentPerc],[_|IncenTot],[_|TitoliInc]):-
	inc_constraint(Opera,Titolo,IncentPerc,IncenTot,TitoliInc).
	
	
%%%%%%%%% restituisce un opera a partire dal suo titolo  %%%%%%%%%
get_opera_by_titolo([],[],_,_).
get_opera_by_titolo([Opera|Opere],[Tit|Titoli],Titolo,OperaOut):-
	Tit == Titolo, !,
	OperaOut = Opera,
	get_opera_by_titolo(Opere,Titoli,Titolo,OperaOut).
get_opera_by_titolo([_|Opere],[_|Titoli],Titolo,OperaOut):-
	get_opera_by_titolo(Opere,Titoli,Titolo,OperaOut).
	
%%%%%%%%%%% vincolo di prova per gli incentivi : assegno valore arbitrario minimo per inc al fotovoltaico %%%%%%%%%%%%%%
test_inc_constraint([],[]).
test_inc_constraint([Inc|Incentivi],[Tit|TitoliInc]):-
	( Tit == "Impianti fotovoltaici" 
		-> eplex:(Inc $>= 100000)
		; true
	),
	test_inc_constraint(Incentivi,TitoliInc).
    

%%%%%%%%%%%% FORMULA PER IL COSTO DI UN'OPERA. FORNISCE UN TERMINE %%%%%%%%%%%%%%%%%%%%
costo_opera(Opera,Titolo,CostoOpera):-
    (costi_impianti(Titolo,_CostoUnitarioGestione,_,CostoInvestimentoIniziale,_,_VitaMedia)
        ->  CostoOpera=CostoInvestimentoIniziale*Opera
            %(VitaMedia>0
            %    -> CostoOpera=(CostoUnitarioGestione+CostoInvestimentoIniziale/VitaMedia)*Opera
            %    ;  CostoOpera=(CostoUnitarioGestione)*Opera
            %)
        ;   CostoOpera=0,
            write(Titolo), writeln(' senza costo')
    ).

geq_list([],[]).
geq_list([H|T],[V|LV]):-
    eplex:(H $>= V),
    geq_list(T,LV).

vincolo_min_max(Opere,TitoliOpere):-
    totale_opere_min_max(Opere,TitoliOpere,EspressioneTot,VariabileTot),
    eplex:(VariabileTot $= EspressioneTot).

% Impongo che le opere per cui voglio avere bilanciamento (quelle per cui ho un fatto min_max_opera)
% siano nei limiti fram Min e Max (in percentuale) rispetto al totale delle opere per cui ho
% questi fatti.
% Ad esempio, potrei volere fare dal 10% al 30% delle opere che producono energia,
% cosi` diversifico le fonti di energia. In questo caso avro` per ciascuna di queste opere
% un fatto min_max_opera(NomeOpera,10,30).
% Metto in EspressioneTot l'espressione del totale
% (la somma delle opere per cui c'e` un min_max_opera)
% e in VarTot una variabile che rappresentera` poi questo valore.
% Si dovra` quindi imporre subito dopo un VarTot $= EspressioneTot
totale_opere_min_max([],[],0,_).
totale_opere_min_max([Opera|Opere],[Titolo|TitoliOpere],EspressioneTot,VarTot):-
    % Valori minimi e massimi assoluti
    (min_max_opera(Titolo,MinAss,MaxAss)
        ->  (nonvar(MinAss) -> eplex:(Opera $>= MinAss) ; true),
            (nonvar(MaxAss) -> eplex:(Opera $=< MaxAss) ; true)
        ;   true
    ),
    % Valori minimi e massimi in percentuale
    (min_max_opera_perc(Titolo,Min,Max)
        ->  eplex:(Opera $>= Min/100*VarTot),
            eplex:(Opera $=< Max/100*VarTot),
            EspressioneTot = Opera+EspressioneTemp
        ;   EspressioneTot = EspressioneTemp
    ),
    totale_opere_min_max(Opere,TitoliOpere,EspressioneTemp,VarTot).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

crea_var(NumPress,Pressioni,LB,UB):-
    length(Pressioni,NumPress),
    eplex:(Pressioni $:: LB..UB).

crea_var_gap(NumPress,Pressioni,Lval,Gap):-
    length(Pressioni,NumPress),
    var_domain_gap(Pressioni,Lval,Gap).

crea_var_names([],[],_,_):- !.
crea_var_names([Name|Names],[P|Pressioni],LB,UB):-
    eplex:(P $:: LB..UB),
    set_var_name(P,Name),
    crea_var_names(Names,Pressioni,LB,UB).

var_domain_gap([],[],_).
var_domain_gap([P|Pressioni],[V|Lval],Gap):-
    LB is max(V-Gap,0),
    UB is min(V+Gap,100),
    eplex:(P $:: LB..UB),
    var_domain_gap(Pressioni,Lval,Gap).

crea_var_gap_excl(NumPress,Pressioni,Lval,Gap,Excluded,Titoli):-
    length(Pressioni,NumPress),
    var_domain_gap_excl(Pressioni,Lval,Gap,Excluded,Titoli).

var_domain_gap_excl([],[],_,_,_).
var_domain_gap_excl([_|Pressioni],[_|Lval],Gap,Excluded,[Tit|Titoli]):-
    member(Tit,Excluded),!,
    var_domain_gap_excl(Pressioni,Lval,Gap,Excluded,Titoli).
var_domain_gap_excl([P|Pressioni],[V|Lval],Gap,Excluded,[_|Titoli]):-
    LB is max(V-Gap,0),
    UB is min(V+Gap,100),
    eplex:(P $:: LB..UB),
    var_domain_gap_excl(Pressioni,Lval,Gap,Excluded,Titoli).

% vincolo(ListaVarOutput,ListaVarInput,Matrice)
somma_righe([],_,[]).
somma_righe([Out|Lout],Lin,[Row|Mat]):-
    %length(Row,NumRow),
    %length(Lin,NumLin),
    eplex:(Row*Lin $= Out),
    somma_righe(Lout,Lin,Mat).

imponi_limiti([],[]).
imponi_limiti([Tit|TitoliRicet],[R|Ricettori]):-
    once(limite(Tit,Limite)),
    eplex:(R $>= Limite),
    imponi_limiti(TitoliRicet,Ricettori).

imponi_limiti_fakevar([],[],_).
imponi_limiti_fakevar([Tit|TitoliRicet],[R|Ricettori],Fake):-
    once(limite(Tit,Limite)),
    eplex:(R+Fake $>= Limite),
    imponi_limiti_fakevar(TitoliRicet,Ricettori,Fake).


name_variable(Name,_,[],_):- !, write(Name), writeln(" not found"), fail.
name_variable(Name,X,[Name|_],[X|_]):-!.
name_variable(Name,X,[_|Names],[_|Vars]):-
    name_variable(Name,X,Names,Vars).

somma_liste([],[],[]).
somma_liste([A|LA],[B|LB],[S|LS]):-
    S is A+B,
    somma_liste(LA,LB,LS).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% STAMPE %%%%%%%%%%%%%%%%%%%%%%%%%%%

print_solution(P,Tit):- print_solution(1,P,Tit).
print_solution(_,[],[]).
print_solution(N,[Pressione|Pressioni],[Titolo|Titoli]):-
    (eplex:eplex_var_get(Pressione,typed_solution,Val),
     Val \= 0
        ->      write_tee(N), write_tee('. '), write_tee(Titolo), write_tee(':\t'), writeln_tee(Val)
        ;   true
    ),
    N1 is N+1,
    print_solution(N1,Pressioni,Titoli).

% print_solution_opere(Opere,Titoli,Outcome)
% Gli outcome servono per evidenziare le opere che producono l'outcome
% (e.g., le opere che producono energia in un piano energetico)
print_solution_opere([],[],[]).
print_solution_opere([Opera|Opere],[Titolo|Titoli],[Outcome|Outcomes]):-
    (eplex:eplex_var_get(Opera,typed_solution,Val),
     Val > 0
        ->  (Outcome > 0 ->     boldface ; true),
            write_tee(Titolo), write_tee(':\t'), write_tee(Val),
            (unita_impianto(Titolo,Unita) -> write_tee(Unita) ; true),
            nl_tee,
            (Outcome > 0 ->     normal_font ; true)
        ;   true
    ),
    print_solution_opere(Opere,Titoli,Outcomes).

write_tee(X):- write_tee(outfile,X).
writeln_tee(X):- writeln_tee(outfile,X).
nl_tee:- nl_tee(outfile).

write_tee(File,X):- write(X), write(File,X).
writeln_tee(File,X):- writeln(X), writeln(File,X).
nl_tee(File):- nl, nl(File).

unita_impianto(Titolo,Unita):-
    costi_impianti(Titolo,_,_,_,UnitaEuro,_), nonvar(UnitaEuro),
    (append_strings("\342\202\254/",Unita,UnitaEuro) % Se c'e` un "euro/" lo tolgo
                        -> true
                        ;  Unita=UnitaEuro
    ).

print_eplex_vars([]).
print_eplex_vars([H|T]):-
    write(H), eplex:eplex_var_get(H,solution,X),
    writeln(X),
    print_eplex_vars(T).

print_lists([],[],[]).
print_lists([H|T],[S|LSlack],[H1|T1]):-
    writeln(H),
%    term_variables(H,Vars),
%    print_eplex_vars(Vars),
    writeln(S->H1),
    print_lists(T,LSlack,T1).

stampa_lista([]):- nl.
stampa_lista([X|T]):- write(X), write(','), stampa_lista(T).

% Questa versione non sembra affidabile: usa l'altra (stampa_duale(1))
stampa_duale:-
    writeln("====================== Duale ======================"),
    eplex:eplex_get(constraints,Constraints),
    eplex:eplex_get(dual_solution,Dual),
    eplex:eplex_get(slack,Slack),
    print_lists(Constraints,Slack,Dual).

stampa_duale(N):-
    eplex:eplex_get(num_rows,N),!.
stampa_duale(N):-
    eplex:eplex_get(dual_solution([N]),[Dual]),
    ((Dual =< -0.01; Dual >= 0.01)
    ->
        write(N), write(': '),
        eplex:eplex_get(constraints([N]),Constraints),
        eplex:eplex_get(slack([N]),Slack),
        writeln(Constraints),
        writeln(Slack -> Dual)
    ;   true),
    N1 is N+1,
    stampa_duale(N1).

csv_list([],File,Comma):-
    write(File,Comma).
csv_list([H|T],File,Comma):-
    write(File,'"'),
    write(File,H),
    write(File,'"'),
    write(File,Comma),
    csv_list(T,File,Comma).



csv_list_solution([],File,Comma):-
    write(File,Comma).
csv_list_solution([H|T],File,Comma):-
    eplex:eplex_var_get(H,typed_solution,Val),
    write(File,Val),
    write(File,Comma),
    csv_list_solution(T,File,Comma).

%%%%%%%%%%%%%% CONVERSIONE FRA I FORMATI %%%%%%%%%%%%%%%%%%%%%%%%%%
colore(X,0):- var(X),!. % Se e` una variabile, diventa 0
colore(a,0.75). % Alto positivo
colore(m,0.5). % Medio positivo
colore(b,0.25). % Basso positivo
colore(h,-0.75). % Per i negativi uso i termini inglesi: high
colore(i,-0.5). % intermediate
colore(l,-0.25). % low

conv_amb(N,N):- number(N), !.
conv_amb(a,0.75).
conv_amb(m,0.5).
conv_amb(b,0.25).


m_opere_press(A,Titolo,Lista):-
    opere_press(A,Titolo,ListaCol),
    lista_colori(ListaCol,Lista).
m_ricet_press(Titolo,Lista):-
    ricet_press(Titolo,ListaCol),
    lista_colori(ListaCol,Lista).

lista_colori([],[]).
lista_colori([C|ListaCol],[V|ListaVal]):-
    colore(C,V),
    lista_colori(ListaCol,ListaVal).

unifica([],[]).
unifica([H|T],[H|T1]):-
    unifica(T,T1).

print_len(L):- length(L,N), writeln(N).

boldface :- write('\033[1m').
normal_font:- write('\033[0m').

%%%%%%%%%%%%%%%%%  Benders decomposition %%%%%%%%%%%%%%%%%%%%%
% benders_dec/3 ha come parametri la percentuale di incentivi, gli incentivi totali in euro e l'energia elettrica attesa in MW
%modalità d'uso: inizialmente invocare predicato aaai/4 che fornisce un valore casuale (0) per gli incentivi e un outcome energetico atteso(Mw);
%succesivamente fare qualche simulazione con i valori indicati da aaai/4 e poi invocare benders_dec/3  sempre con tali valori
benders_dec(PercInc,Incentivi,Outcome):-
	open('ris.txt',write,outfile),
	
	%prima di chiamare il predicato benders_dec/3 occorre aver effettuato le simulazioni con i parametri forniti da aaai/4
	sim_result(AvgIncIns,AvgOutcome),
	
	writeln_tee(""),
	writeln_tee("========= Benders decomposition ========="),
	writeln_tee("===== Valori forniti al simulatore ====="),
	write_tee("Percentuale incentivi"), write_tee(':\t'), writeln_tee(PercInc),
	write_tee("Totale incentivi"), write_tee(':\t'), writeln_tee(Incentivi),
	write_tee("Outcome atteso"), write_tee(':\t'), writeln_tee(Outcome),
	writeln_tee("===== Valori medi ottenuti dal simulatore con gli incentivi forniti ====="),
	write_tee("Valore medio incentivi"), write_tee(':\t'), writeln_tee(AvgIncIns),
	write_tee("Outcome medio"), write_tee(':\t'), writeln_tee(AvgOutcome),
	
	%a questo punto viene confrontata la produzione di energia effettiva e quella attesa
	%occorre tenere conto del fattore di scala tra simulatore e pianificatore -> fattore inserito nel predicato sim_result/2
	( AvgOutcome >= Outcome 
	-> 	writeln_tee("===== Opt. sol. =====")
	; 	sub_problem(PercInc,Outcome,AvgOutcome)
	),
	
	close(outfile).
	
%questa versione riguarda il secondo simulatore --> vengono tenuti in considerazione anche il budget per il PV messo a disposizione dalla regione
%(passato come argomento in Mln di euro) e differenti metodi di incentivazione, in particolare: 1) nessun incentivo 2) asta fondo perduto
%3) conto interessi 4) rotazione 5) garanzia
benders_dec_fr(BudgetPV,Outcome):-
	open('ris.txt',write,outfile),
	
	append(['Nessuno','Asta','Conto interessi','Rotazione','Garanzia'],[],Tipologie),
	%prima di chiamare il predicato benders_dec_fr occorre aver effettuato le simulazioni con i parametri forniti da aaai/4
	sim_result_fr(Tipologie,AvgOutcomes),
	writeln_tee("===== Valori medi ottenuti dal simulatore per i vari tipi di incentivi  ====="),
	write_tee("Budget PV regionale (Mln di euro): "), writeln_tee(BudgetPV),
	print_result_fr(Tipologie,AvgOutcomes),
	
	close(outfile).

% generate_cut/1 crea un nuovo vincolo per gli incentivi -------- predicato usato solo a fini di test 
generate_cut(Incentivi,Value):-
	writeln_tee("===== Generating bender cuts ====="),
	%eplex:eplex_var_get(Incentivi,typed_solution,IncPrec),
	writeln_tee("===== Adding cut ... ====="),
	eplex:(Incentivi $>= 100000+Value),
	writeln_tee(Incentivi).  %taglio molto banale
	
%lettura dei vincoli nogood da file
nogood_constraint_read(IncPerc,Titoli):-
	findall((T,LB),nogoods(T,LB),List),
	add_cons(List,IncPerc,Titoli).

%il nuovo vincolo viene aggiunto all'istanza eplex
add_cons([],_,_).
add_cons([(Titolo,LB)|T],IncPerc,Titoli):-
	name_variable(Titolo,IncPercSel,Titoli,IncPerc),
	eplex:(IncPercSel $>= LB),
	add_cons(T,IncPerc,Titoli).
	
%stampa gli outcomes medi per le varie tipologie di incentivazione ( secondo simulatore )
print_result_fr([],[]).
print_result_fr([T|Tipologie],[O|Outcomes]):-
	write_tee("Tipologia incentivazione: "), write_tee(T),
	write_tee("  Outcome medio: "), writeln_tee(O),
	print_result_fr(Tipologie,Outcomes).
	
