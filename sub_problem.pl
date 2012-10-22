:- lib(eplex).
:- lib(util).
:- eplex_instance(sub).

	
%come parametri vengono passati gli incentivi assegnati dal master, l'outcome atteso e quello ottenuto attraverso la simulazione
%versione funzionante con la versione iniziale del primo simulatore e il fattore di scala corretto 
sub_problem(IncPerc,OutcomeAtteso,SimOutcome):-

	DeltaOut is OutcomeAtteso-SimOutcome,
	
	%l'uscita attesa insegue la differenza tra l'outcome atteso e quello simulato
	sub:eplex_solver_setup(min(DeltaOut-FunzInc)),
	sub:eplex_set(dual_solution,yes),
	
	%creazione variabili
	sub:(DeltaInc $:: 0..40),
	sub:integers(DeltaInc),
	
	%vincoli derivanti dal master
	%sub:(IncPer $>= IncPerc ),
	
	%relazione tra pecentuale incentivi e l'outcome simulato: rilassamento ricavato tramite regressione lineare
	%OutcomePV = m*IncPer+q, m=2645MW q=405MW
	sub:( FunzInc $= (DeltaInc)*2645*0.01 ),
	
	sub:(DeltaOut $>= FunzInc ),
	
	sub:(Out $= DeltaOut-FunzInc ),
	sub:eplex_solve(Out),
	
	%open('ris.txt',write,out),
	
	
	writeln_tee("------Sub Problem-------"),
	write_tee("Differenza tra outcome atteso e simulato: "), writeln_tee(DeltaOut),
	sub:eplex_var_get(Out,typed_solution,OutVal),  
    write_tee("Out value: "), writeln_tee(OutVal),
    sub:eplex_var_get(FunzInc,typed_solution,FunzIncVal),  
    sub:eplex_var_get(DeltaInc,typed_solution,DeltaIncVal), 
    write_tee("FunzInc value: "), writeln_tee(FunzIncVal),
    NewIncPerc is IncPerc+DeltaIncVal,
    %se il nuovo valore di incentivo coincide col vecchio aumento comunque di 1 ( se l'outcome richiesto 
    %fosse stato ottenuto sub_probl non sarebbe stato chiamato )
    (NewIncPerc == IncPerc
    -> NNewIncPerc is NewIncPerc+1
    ; NNewIncPerc = NewIncPerc
    ),
    sub:eplex_var_get(NNewIncPerc,typed_solution,IPVal),  
    write_tee("IncPer value: "), writeln_tee(IPVal),
    write_tee("Delta IncPer value: "), writeln_tee(DeltaIncVal),
    
    
	%close(outfile),
	
	
	%inserisci nuovo vincolo su percentuale incentivi in nogood
	open('nogoods.pl',update,nogoodfile),
	seek(nogoodfile,end_of_file),
	write(nogoodfile,"nogoods(\"Impianti fotovoltaici\","), %in realtà il tipo di nogood deve essere passato come parametro a sub_probl
	write(nogoodfile,IPVal), write(nogoodfile,").\n"),
	
	close(nogoodfile).
	

%versione per il secondo simulatore: dalle simulazioni effettuate vengono estrapolate le relazioni tra il budget assegnato ad un tipo di 
%incentivo e l'outcome energetico corrispondente, dalle quali vengono poi ricavati i vincoli da passare al problema principale
sub_problem_fr(TipiInc,BudgetPV):-
	
	%suppongo che in un file (rel.pl) siano presenti le relazioni tra la tipologia di incentivo, l'outcome energetico ottenibile e 
	%a quanto ammonti il finanziamento necessario ( in euro )
	%i valori ottenuti rappresentano la produzione energetica nel caso tutto il budget energetico venisse assegnato ad un solo tipo di incentivo
	[rel]
	get_outcomes(TipiInc,[],OutsInc),
	get_budgets(TipiInc,[],BudgetsInc),
	
	%ad ogni tipo di incentivo assegno una variabile intera che rappresenta la "percentuale" effettivamente realizzata di tale incentivo
	crea_var_names(TipiInc,VarInc,0,100),
	
	%le variabili sono intere e la loro somma deve essere 100
	sub:integers(VarInc),
	sub:(sum(VarInc) $= 100 ),
	
	%la somma dei costi per ogni tipo di incentivo moltiplicati per la percentuale di realizzazione deve essere minore al budget per il PV
	sub:(sum(VarInc*BudgetsInc) $=< BudgetPV*100 ),
	
	%la funzione obiettivo cerca di rendere massimo l'outcome energetico totale sommando i contribuiti dei vari tipi di incentivi correttamente pesati
	sub:eplex_solver_setup(max(sum(VarInc*OutsInc))),
	sub:eplex_set(dual_solution,yes),
	
	sub:(Out $= sum(VarInc*OutsInc)/100 ),
	sub:eplex_solve(Out),
	
	
	writeln_tee("------Sub Problem-------"),
	write_tee("BudgetPV: "), writeln_tee(BudgetPV),
	sub:eplex_var_get(Out,typed_solution,OutVal),  
    write_tee("Out value: "), writeln_tee(OutVal),
	print_var_inc(VarInc,TipiInc,BudgetsInc,OutsInc),
	
	%scrittura nel file fr_cons.pl dei valori ottenuti per i fondi da assegnare ai vari incentivi
	open('fr_cons.pl',write,frcons),
	write_cons_file(TipiInc,VarInc,BudgetsInc),
	close(frcons).
	
	
%ricavo dal file rel.pl le relazioni tra tipo di incentivo e outcome energetico -> rel("Conto interessi",53.445,2500000)
get_outcomes([],Outs,Outs).
get_outcomes([T|TipiInc],OutTemp,Outs):-
	rel(T,Outcome,_),
	append([Outcome],OutTemp,OutsN),
	get_outcomes(TipiInc,OutsN,Outs).
	
%ricavo dal file rel.pl le relazioni tra tipo di incentivo e budget consumato -> rel("Conto interessi",53.445,2500000)
get_budgets([],Budgets,Budgets).
get_budgets([T|TipiInc],BudgetTemp,Budgets):-
	rel(T,_,Budget),
	append([Budget],BudgetTemp,BudgetsN),
	get_budgets(TipiInc,BudgetsN,Budgets).
	
%predicato per creare variabili con nome, adattato dalla versione originale di modello.ecl
crea_var_names([],[],_,_):- !.
crea_var_names([Name|Names],[P|T],LB,UB):-
    sub:(P $:: LB..UB),
    set_var_name(P,Name),
    crea_var_names(Names,T,LB,UB).
    
%stampa le percentuali di budget assegnate ai vari incentivi
print_var_inc([],[],[],[]).
print_var_inc([V|VarInc],[T|TipiInc],[B|BudgetsInc],[O|OutsInc]):-
	sub:eplex_var_get(V,typed_solution,VV),
	write_tee("Tipologia incentivo: "), write_tee(T), write_tee(" - Percentuale: "), write_tee(VV),
	BV is VV*B/100,  OV is VV*O/100,
	write_tee(" - Contributo costo: "), write_tee(BV), writeln_tee(" - Contributo outcome: "), write_tee(OV),
	print_var_inc(VarInc,TipiInc,BudgetsInc,OutsInc).

%scrittura dei vincoli che verranno presi in considerazione dal modello principale nel file fr_cons.pl
%con la forma: fr_constr("tipologia incentivo",valore).
write_cons_file([],[],[]).
write_cons_file([T|TipiInc],[V|VarInc],[B|BudgetsInc]):-
	sub:eplex_var_get(V,typed_solution,VV),
	Val is VV*B/100,
	write(frcons,"fr_constr(\""), write(frcons,T), write(frcons,"\","),
	write(frcons,Val), write(frcons,").\n"),
	write_cons_file(TipiInc,VarInc,BudgetsInc).

	
