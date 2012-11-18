:- lib(eplex).
:- lib(util).
:- eplex_instance(sub).
:- eplex_instance(sub_out).

	
	
%PRIMO SIMULATORE
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
	

%SECONDO SIMULATORE
%versione per il secondo simulatore: dalle simulazioni effettuate vengono estrapolate le relazioni tra il budget assegnato ad un tipo di 
%incentivo e l'outcome energetico corrispondente, dalle quali vengono poi ricavati i vincoli da passare al problema principale
sub_problem_fr(TipiInc,BudgetPV,BudgetsInc,OutsInc,OutValF):-
	
	%suppongo che in un file (rel.pl) siano presenti le relazioni tra la tipologia di incentivo, l'outcome energetico ottenibile e 
	%a quanto ammonti il finanziamento necessario ( in euro )
	%i valori ottenuti rappresentano la produzione energetica nel caso tutto il budget energetico venisse assegnato ad un solo tipo di incentivo
	[rel],
	get_outcomes(TipiInc,[],OutsInc),
	get_budgets(TipiInc,[],BudgetsInc),
		
	%ad ogni tipo di incentivo assegno una variabile intera che rappresenta la "percentuale" effettivamente realizzata di tale incentivo
	crea_var_names_sub(TipiInc,VarInc,0,100),
	
	%sub:integers(VarInc),
	sub:(sum(VarInc) $>= 100 ),
	
	%la somma dei costi per ogni tipo di incentivo moltiplicati per la percentuale di realizzazione deve essere minore al budget per il PV
	sub:((VarInc*BudgetsInc) $=< BudgetPV*100) ,
	
	%CostiInc sono le spese da stanziare per finanziare gli incentivi senza considerare i possibili guadagni
	exclude_plus(BudgetsInc,BudgetPV,[],CostiInc),
	%questo vincolo richiede che a prescindere dai possibili ricavi la spesa iniziale sia minore di BudgetPV -------> DISCUTERE SE NECESSARIO
	sub:((VarInc*CostiInc) $=< BudgetPV*100), 
	
	%la funzione obiettivo cerca di rendere massimo l'outcome energetico totale sommando i contribuiti dei vari tipi di incentivi correttamente pesati
	sub:eplex_solver_setup(max(VarInc*OutsInc)),
	sub:eplex_set(dual_solution,yes),
	
	sub:eplex_solve(Out),
	
	writeln_tee("------Sub Problem-------"),
	write_tee("BudgetPV: "), writeln_tee(BudgetPV),
	sub:eplex_var_get(Out,typed_solution,OutVal),  
    OutValF is OutVal/100,
    
	print_var_inc(VarInc,TipiInc,BudgetsInc,OutsInc,0,CostoTot),
	write_tee("Costo totale incentivi "), writeln_tee(CostoTot),
	write_tee("Out value: "), writeln_tee(OutValF),
	
	writeln_tee("------Duale-------"),
    sub:eplex_get(dual_solution,Dual),
    write_tee("Dual -> "), writeln_tee(Dual),
	
	%scrittura nel file fr_cons.pl dei valori ottenuti per i fondi da assegnare ai vari incentivi
	%in fr_cons.pl scrivo anche i ricavi ottenuti dai diversi incentivi
	open('fr_cons.pl',write,frcons),
	write_cons_file(TipiInc,VarInc,BudgetsInc,BudgetPV),
	write_cons_ricavi_file(TipiInc,VarInc,BudgetsInc,BudgetPV),
	close(frcons).
	
	
%ricavo dal file rel.pl le relazioni tra tipo di incentivo e outcome energetico -> rel("Conto interessi",53.445,2500000)
get_outcomes([],Outs,Outs).
get_outcomes([T|TipiInc],OutTemp,Outs):-
	findall(O,rel(T,O,_),OS),
	first(OS,Outcome),
	append(OutTemp,[Outcome],OutsN),
	get_outcomes(TipiInc,OutsN,Outs).
	
%ricavo dal file rel.pl le relazioni tra tipo di incentivo e budget consumato -> rel("Conto interessi",53.445,2500000)
get_budgets([],Budgets,Budgets).
get_budgets([T|TipiInc],BudgetTemp,Budgets):-
	rel(T,_,Budget),
	append(BudgetTemp,[Budget],BudgetsN),
	get_budgets(TipiInc,BudgetsN,Budgets).
	
%predicato per creare variabili con nome, adattato dalla versione originale di modello.ecl
crea_var_names_sub([],[],_,_):- !.
crea_var_names_sub([Name|Names],[P|T],LB,UB):-
    sub:(P $:: LB..UB),
    set_var_name(P,Name),
    crea_var_names_sub(Names,T,LB,UB).
    
crea_var_names_sub_out([],[],_,_):- !.
crea_var_names_sub_out([Name|Names],[P|T],LB,UB):-
    sub_out:(P $:: LB..UB),
    set_var_name(P,Name),
    crea_var_names_sub_out(Names,T,LB,UB).
    
%stampa le percentuali di budget assegnate ai vari incentivi
print_var_inc([],[],[],[],CostoTot,CostoTot).
print_var_inc([V|VarInc],[T|TipiInc],[B|BudgetsInc],[O|OutsInc],Costo,CostoTot):-
	sub:eplex_var_get(V,typed_solution,VV),
	write_tee("Tipologia incentivo: "), write_tee(T), write_tee(" - Percentuale: "), write_tee(VV),
	BV is VV*B/100,  OV is VV*O/100,
	write_tee(" - Contributo costo: "), write_tee(BV), write_tee(" - Contributo outcome: "), writeln_tee(OV),
	CostoNew is Costo+BV,
	print_var_inc(VarInc,TipiInc,BudgetsInc,OutsInc,CostoNew,CostoTot).
	
print_var_inc_out([],[],[],[],CostoTot,CostoTot).
print_var_inc_out([V|VarInc],[T|TipiInc],[B|BudgetsInc],[O|OutsInc],Costo,CostoTot):-
	sub_out:eplex_var_get(V,typed_solution,VV),
	write_tee("Tipologia incentivo: "), write_tee(T), write_tee(" - Percentuale: "), write_tee(VV),
	BV is VV*B/100,  OV is VV*O/100,
	write_tee(" - Contributo costo: "), write_tee(BV), write_tee(" - Contributo outcome: "), writeln_tee(OV),
	CostoNew is Costo+BV,
	print_var_inc_out(VarInc,TipiInc,BudgetsInc,OutsInc,CostoNew,CostoTot).

%scrittura dei vincoli che verranno presi in considerazione dal modello principale nel file fr_cons.pl
%con la forma: fr_constr("tipologia incentivo",valore).
write_cons_file([],[],[],_).
write_cons_file([T|TipiInc],[V|VarInc],[B|BudgetsInc],BudgetPV):-
	sub:eplex_var_get(V,typed_solution,VV),
	Val is VV*B/100,
	%se il valore ottenuto è negativo esso rappresenta il guadagno ottenuto tramite l'incentivo: questo valore non rappresenta
	%il budget da stanziare per tale incentivo ( come il problema principale si attende ); stimo quindi che per produrre un tale guadagno
	%il fondo rotazione utilizzi tutto il budget disponibile ( BudgetPV )
	( Val >= 0 -> ValF is Val ; ValF is BudgetPV ),
	write(frcons,"fr_constr(\'"), write(frcons,T), write(frcons,"\',"),
	write(frcons,ValF), write(frcons,").\n"),
	write_cons_file(TipiInc,VarInc,BudgetsInc,BudgetPV).

%scrittura dei valori dei ricavi dagi incentivi
%con la forma: fr_ricavo("tipologia incentivo",valore).
write_cons_ricavi_file([],[],[],_).
write_cons_ricavi_file([T|TipiInc],[V|VarInc],[B|BudgetsInc],BudgetPV):-
	sub:eplex_var_get(V,typed_solution,VV),
	Val is VV*B/100,
	%se il valore ottenuto è positivo significa che l'incentivo non genera ricavi, mentre se è negativo il ricavo è costituito dal guadagno
	%ottenuto ( Val ) sommato ai costi per l'incentivo ( anche qui suppongo che vengano interamente coperti )
	( Val >= 0 -> ValF is 0 ; ValF is BudgetPV-Val ),
	write(frcons,"fr_ricavo(\'"), write(frcons,T), write(frcons,"\',"),
	write(frcons,ValF), write(frcons,").\n"),
	write_cons_ricavi_file(TipiInc,VarInc,BudgetsInc,BudgetPV).	
	
	
%secondo sottoproblema per il SECONDO SIMULATORE: cerco di calcolare quanto deve aumentare il bugetPV affinché l'outcome prodotto dal simulatore
%coincida con quello previsto dall'ottimizzatore
sub_problem_fr_out(TipiInc,BudgetPV,OutExp,BudgetsInc,OutsInc):-

	%ad ogni tipo di incentivo assegno una variabile intera che rappresenta la "percentuale" effettivamente realizzata di tale incentivo
	crea_var_names_sub_out(TipiInc,VarInc,0,100),
	%variabile che rappresenta la differenza di budget richiesta per l'outcome richiesto
	sub_out:(DiffBudget $:: 0..30000000), %30 Mln
	
	sub_out:(sum(VarInc) $>= 100 ),
	
	%la somma dei costi per ogni tipo di incentivo moltiplicati per la percentuale di realizzazione deve essere minore al nuovo budget per il PV
	sub_out:((VarInc*BudgetsInc) $=< (BudgetPV+DiffBudget)*100) ,
	
	%CostiInc sono le spese da stanziare per finanziare gli incentivi senza considerare i possibili guadagni
	exclude_plus(BudgetsInc,BudgetPV,[],CostiInc),
	%questo vincolo richiede che a prescindere dai possibili ricavi la spesa iniziale sia minore di BudgetPV -------> DISCUTERE SE NECESSARIO
	sub_out:((VarInc*CostiInc) $=< (BudgetPV+DiffBudget)*100), 
	
	%l'outcome prodotto deve coincidere con quello atteso
	sub_out:((VarInc*OutsInc) $>= OutExp*100 ), 
	sub_out:(SimOut*100 $= (VarInc*OutsInc)),
	
	%la funzione obiettivo cerca di rendere minimo l'aumento di budget PV
	sub_out:eplex_solver_setup(min(DiffBudget)),
	sub_out:eplex_set(dual_solution,yes),
	
	sub_out:eplex_solve(Out),
	
	writeln_tee("------Sub Problem-out-------"),
	writeln_tee("------Stima aumento budget necessario-------"),
	write_tee("BudgetPV: "), writeln_tee(BudgetPV),
	write_tee("Outcome atteso: "), writeln_tee(OutExp),
	sub_out:eplex_var_get(Out,typed_solution,OutVal),  
	sub_out:eplex_var_get(SimOut,typed_solution,SimOutVal),  
	write_tee("Outcome simulato: "), writeln_tee(SimOutVal),

	print_var_inc_out(VarInc,TipiInc,BudgetsInc,OutsInc,0,CostoTot),
	write_tee("Costo totale incentivi "), writeln_tee(CostoTot),
	
	sub_out:eplex_var_get(DiffBudget,typed_solution,DiffBudgetVal),  
	write_tee("Aumento budget necessario: "), writeln_tee(DiffBudgetVal),
	
	write_tee("Out value: "), writeln_tee(OutVal),
	
	writeln_tee("------Duale-------"),
    sub_out:eplex_get(dual_solution,Dual),
    write_tee("Dual -> "), writeln_tee(Dual),
	
	writeln_tee("--------------------").
	
	
	
%test per il calcolo del duale del sottoproblema ( secondo simulatore )
sub_dual(Budget):-
	BudgetPV is Budget*1000000,
	%creo le due variabili p1 e p2 ( anche valori negativi )
	sub:(P1 $:: -100000..100000),
	sub:(P2 $:: -100000..100000),
	
	%tipi incentivi ricavati da file
	tipi_inc_PV(TipiInc),
	
	%dal file rel.pl estraggo i valori per i coefficienti di budget e outcome
	[rel],
	get_outcomes(TipiInc,[],OutsInc),
	get_budgets(TipiInc,[],BudgetsInc),
	
	%vincoli ( ricavati manualmente ) per il duale del sottoproblema definito in sub_probl_fr
	sub:(P2 $=< 0),
	sub:(P1 $>= 0),
	
	%vincoli aggiunti tutti insieme --> non funziona
	%SumBudgets is sum(BudgetsInc),
	%SumOuts is sum(OutsInc),
	%sub:( SumBudgets*P1+4*P2 $>= SumOuts ),
	
	%vincoli aggiunti singolarmente
	change_sign(OutsInc,[],OutsIncNeg),
	dual_cons(OutsInc,BudgetsInc,P1,P2),	
	
	%funz. obiettivo
	sub:eplex_solver_setup(min(BudgetPV*P1*100+100*P2)),
	
	%risoluzione
	sub:eplex_solve(Out),
	
	open('ris.txt',write,outfile),
	writeln_tee("------Sub Problem Dual-------"),
	write_tee("BudgetPV: "), writeln_tee(BudgetPV),
	write_tee("OutsInc"), writeln_tee(OutsInc),
	write_tee("BudgetsInc"), writeln_tee(BudgetsInc),
	sub:eplex_var_get(P1,typed_solution,VP1),
	sub:eplex_var_get(P2,typed_solution,VP2),
	write_tee("P1: "), writeln_tee(VP1),
	write_tee("P2: "), writeln_tee(VP2),
	sub:eplex_var_get(Out,typed_solution,OutVal),
	OutValF is OutVal/100,
	write_tee("Out value: "), writeln_tee(OutValF),
	sub:eplex_get(constraints,Cons),
	write_tee("Constraints: "), writeln_tee(Cons),
	close(outfile).
	
dual_cons([],[],_,_).
dual_cons([O|Outs],[B|Budgs],P1,P2):-
	sub:( B*P1+P2 $=< O),
	dual_cons(Outs,Budgs,P1,P2).
	
%test per convertire il SP in forma standard: max(z) ---> -(min(-w))   
%PROBLEMA: risultati diversi da sub_probl_fr()
sub_primal(Budget):-

	BudgetPV is Budget*1000000,

	tipi_inc_PV(TipiInc),
	
	[rel],
	get_outcomes(TipiInc,[],OutsInc),
	get_budgets(TipiInc,[],BudgetsInc),
		
	%ad ogni tipo di incentivo assegno una variabile intera che rappresenta la "percentuale" effettivamente realizzata di tale incentivo
	crea_var_names_sub(TipiInc,VarInc,0,100),
	%sub:integers(VarInc),
	
	%le variabili sono intere e la loro somma deve essere 100
	sub:(sum(VarInc) $>= 100 ),
	
	%la somma dei costi per ogni tipo di incentivo moltiplicati per la percentuale di realizzazione deve essere minore al budget per il PV
	sub:((VarInc*BudgetsInc) $=< BudgetPV*100) ,
	
	%la funzione obiettivo cerca di rendere massimo l'outcome energetico totale sommando i contribuiti dei vari tipi di incentivi correttamente pesati
	change_sign(OutsInc,[],OutsIncNeg),
	%sub:eplex_solver_setup(min(-(VarInc*OutsIncNeg))),
	sub:eplex_solver_setup(min(-(VarInc*OutsInc))),
	sub:eplex_set(dual_solution,yes),
	
	sub:eplex_solve(Out),
	
	open('ris.txt',write,outfile),
	writeln_tee("------Sub Problem-------"),
	write_tee("OutsInc"), writeln_tee(OutsInc),
	write_tee("OutsIncNeg"), writeln_tee(OutsIncNeg),
	write_tee("BudgetsInc"), writeln_tee(BudgetsInc),
	write_tee("BudgetPV: "), writeln_tee(BudgetPV),
	sub:eplex_var_get(Out,typed_solution,OutVal),  
    OutValF is OutVal/100,
	print_var_inc(VarInc,TipiInc,BudgetsInc,OutsInc,0,CostoTot),
	write_tee("Costo totale incentivi "), writeln_tee(CostoTot),
	write_tee("Out value: "), writeln_tee(OutValF),
	writeln_tee("------Duale-------"),
    sub:eplex_get(dual_solution,Dual),
    write_tee("Dual -> "), writeln_tee(Dual),
    
    close(outfile).

%dalla lista contentente i valori dei budget positivi ( costi ) o negativi ( ricavi ) vengono eliminati i ricavi sostituiti 
%ipotizzando il totale consumo del budget disponibile ( budgetPV )
exclude_plus([],_,List,List).
exclude_plus([B|Budgets],BudgetPV,ListTemp,List):-
	( B >= 0 -> BF = B ; BF = BudgetPV ),
	append(ListTemp,[BF],ListNew),
	exclude_plus(Budgets,BudgetPV,ListNew,List).
