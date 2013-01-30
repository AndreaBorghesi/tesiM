:- lib(eplex).
:- lib(util).
:- eplex_instance(sub).
:- eplex_instance(sub_out).

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
    
%predicato per creare tante variabili quanti gli elementi nella lista passata come primo argomento
crea_var_sub([],[],_,_):- !.
crea_var_sub([_|L],[P|T],LB,UB):-
    sub:(P $:: LB..UB),
    crea_var_sub(L,T,LB,UB).
    
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

%dalla lista contentente i valori dei budget positivi ( costi ) o negativi ( ricavi ) vengono eliminati i ricavi sostituiti 
%ipotizzando il totale consumo del budget disponibile ( budgetPV )
exclude_plus([],_,List,List).
exclude_plus([B|Budgets],BudgetPV,ListTemp,List):-
	( B >= 0 -> BF = B ; BF = BudgetPV ),
	append(ListTemp,[BF],ListNew),
	exclude_plus(Budgets,BudgetPV,ListNew,List).
	

%predicato che svolge la funzione dei precedenti sub_problem: assegna nel modo migliore il Budget disponibile tentando di massimizzare l'Out; le relazioni Budget-Out sono apprese attraverso le simulazioni e inserite all'interno del modello 
%i parametri passati sono i tipi di incentivazione, il budget per il PV e l'outcome atteso dal PV
assegna_fondi(TipiInc,BudgetPV,ExpOut):-
	
	%ad ogni tipo di incentivo assegno una variabile che rappresenta il costo ( 0..50mln )
	crea_var_names_sub(TipiInc,Budgets,0,50),
	%ad ogni tipo di incentivo assegno una variabile che rappresenta l'outcome ( 0..60MW )
	crea_var_names_sub(TipiInc,Outs,0,60),
	
	%creo vincoli che modellano l'approssimazione lineare
	piecewise_linear_model(TipiInc,Budgets,Outs,[],Auxs),
	
	%la somma dei fondi assegnati ad ogni incentivo deve essere minore del budget per il PV
	sub:(sum(Budgets) $=< BudgetPV ),
	
	%inserisco in liste apposite le variabili ausiliarie che devono formare SOS2 (un SOS2 per tipo di incentivo)
	get_aux_sos(Auxs,AuxA,AuxCI,AuxR,AuxG,"A"),
	
	%la funzione obiettivo cerca di massimizzare la produzione energetica
	sub:(VarObiettivo $= (sum(Outs))),
	sub:eplex_solver_setup(max(sum(Outs)),VarObiettivo,[dual_solution(yes),use_var_names(yes),sos2(AuxA),sos2(AuxCI),sos2(AuxG),sos2(AuxR)],[deviating_bounds,bounds,new_constraint]),
	
%	sub:eplex_solve(Out),
	
	writeln_tee("------Assegnazione Fondi-------"),
	write_tee("BudgetPV: "), writeln_tee(BudgetPV),
	write_tee("Expected Outcome: "), writeln_tee(ExpOut),
	
	write_tee("Budget vars: "), writeln_tee(Budgets),
	write_tee("Out vars: "), writeln_tee(Outs),
	writeln_tee("Auxiliary vars A: "), pretty_print_list(AuxA,"AuxA",1),
	writeln_tee("Auxiliary vars CI: "), pretty_print_list(AuxCI,"AuxCI",1),
	writeln_tee("Auxiliary vars R: "), pretty_print_list(AuxR,"AuxR",1),
	writeln_tee("Auxiliary vars G: "), pretty_print_list(AuxG,"AuxG",1),
	
	sub:eplex_get(constraints,Constraints),
	pretty_print_list(Constraints,"Constraint",1),
	
	sub:eplex_var_get(VarObiettivo,typed_solution,VarObiettivoVal),  
    write_tee("Out Value: "), writeln_tee(VarObiettivoVal),
    
    writeln_tee("------Duale-------"),
    sub:eplex_get(dual_solution,Dual),
    write_tee("Dual -> "), writeln_tee(Dual),
	
	writeln_tee("Assegnazione fondi completata").
	

%inserisce all'interno del modello le relazioni tra budget e outcome ricavate dalle simulazioni e approssimate con funzioni lineari a tratti
piecewise_linear_model([],_,_,AuxF,AuxF):-!.
piecewise_linear_model([Tipo|TipiInc],[B|Budgets],[O|Outs],AuxT,AuxF):-
	%ricava i punti che definiscono la spezzata per il tipo di incentivo
	punti(Tipo,Punti),
	%creo tante variabili ausiliarie quanti sono i punti che caratterizzano l'incentivo
	crea_var_sub(Punti,Auxs,0,1),
	%le variabili ausiliarie sono inserite in una lista per usi successivi (SOS2)
	append(AuxT,[Auxs],AuxN),
	
	%estrai dalla lista di punti le liste per ascisse e ordinate
	extract_coord(Punti,[],Xs,[],Ys),
	
	%ai valori delle ordinate (Ys) sottrai il valore minimo (per ogni tipo di incentivo), in modo da ottenere come outcome totale la differenza rispetto al caso in cui non ci sia fondo incentivante (e non il valore assoluto)
%	base_value(Tipo,YMin),
	%oppure per sottolineare la differenza rispetto al caso in cui nessuna metodologia incentivante sia fornita sottrarre il valore di out in caso di nessun incentivo
	base_value('Nessuno',YMin),
	subtract_y(Ys,YMin,[],YsSub),
	
	%vincoli per le variabili ausiliarie per approssimare la relazione budget-out con una curva lineare a tratti
	sub:(sum(Auxs) $=< 1),
	sub:(B $= (Auxs*Xs) ),
	sub:(O $= (Auxs*YsSub) ),
	
	write_tee("-- Tipo inc: "), writeln_tee(Tipo),
	write_tee("---->>> Auxs: "), writeln_tee(Auxs),
	
	piecewise_linear_model(TipiInc,Budgets,Outs,AuxN,AuxF).
	
%estrae da una lista di punti (x,y) due liste, una contenente le ascisse e l'altra le ordinate
extract_coord([],Xs,Xs,Ys,Ys).
extract_coord([(PX,PY)|Punti],XsTemp,Xs,YsTemp,Ys):-
	append(XsTemp,[PX],XsNew),
	append(YsTemp,[PY],YsNew),
	extract_coord(Punti,XsNew,Xs,YsNew,Ys).
	
%i gruppi di variabili ausiliarie (uno per incentivo) sono nella lista Auxs nell'ordine A,CI,R,G
get_aux_sos([],_,_,_,_,_):-!.
get_aux_sos([AuxA|Auxs],AuxA,AuxCI,AuxR,AuxG,"A"):-!,
	get_aux_sos(Auxs,AuxA,AuxCI,AuxR,AuxG,"CI").
get_aux_sos([AuxCI|Auxs],AuxA,AuxCI,AuxR,AuxG,"CI"):-!,
	get_aux_sos(Auxs,AuxA,AuxCI,AuxR,AuxG,"R").
get_aux_sos([AuxR|Auxs],AuxA,AuxCI,AuxR,AuxG,"R"):-!,
	get_aux_sos(Auxs,AuxA,AuxCI,AuxR,AuxG,"G").
get_aux_sos([AuxG|Auxs],AuxA,AuxCI,AuxR,AuxG,"G"):-!,
	get_aux_sos(Auxs,AuxA,AuxCI,AuxR,AuxG,_).
	
%sottrae un valore base BV ad ogni elemento della lista L 
subtract_y([],_,LL,LL):-!.
subtract_y([H|T],BV,L,LL):-
	V is H-BV,
	append(L,[V],LN),
	subtract_y(T,BV,LN,LL).
	
%definizione del master problem per benders dec
%sono fissati i fondi per i diversi incentivi e lascio libere le variabili ausiliare che legano budget e out
assegna_fondi_master(TipiInc,BudgetPV,ExpOut,FixedBudgetA,FixedBudgetCI,FixedBudgetR,FixedBudgetG):-
	open('ris.txt',write,outfile),
	
	%ad ogni tipo di incentivo assegno una variabile che rappresenta l'outcome ( 0..60MW )
	crea_var_names_sub(TipiInc,Outs,0,60),
	
	%creo vincoli che modellano l'approssimazione lineare
	piecewise_linear_model(TipiInc,[FixedBudgetA,FixedBudgetCI,FixedBudgetR,FixedBudgetG],Outs,[],Auxs),
	
	%inserisco in liste apposite le variabili ausiliarie che devono formare SOS2 (un SOS2 per tipo di incentivo)
	get_aux_sos(Auxs,AuxA,AuxCI,AuxR,AuxG,"A"),
	
	%la funzione obiettivo cerca di massimizzare la produzione energetica
	sub:(VarObiettivo $= (sum(Outs))),
	sub:eplex_solver_setup(max(sum(Outs)),VarObiettivo,[dual_solution(yes),use_var_names(yes),sos2(AuxA),sos2(AuxCI),sos2(AuxG),sos2(AuxR)],[deviating_bounds,bounds,new_constraint]),
	
	writeln_tee("------Assegnazione Fondi-------"),
	write_tee("BudgetPV: "), writeln_tee(BudgetPV),
	write_tee("Expected Outcome: "), writeln_tee(ExpOut),
	
	write_tee("Budget vars: "), writeln_tee(Budgets),
	write_tee("Out vars: "), writeln_tee(Outs),
	writeln_tee("Auxiliary vars A: "), pretty_print_list(AuxA,"AuxA",1),
	writeln_tee("Auxiliary vars CI: "), pretty_print_list(AuxCI,"AuxCI",1),
	writeln_tee("Auxiliary vars R: "), pretty_print_list(AuxR,"AuxR",1),
	writeln_tee("Auxiliary vars G: "), pretty_print_list(AuxG,"AuxG",1),
	
	sub:eplex_get(constraints,Constraints),
	pretty_print_list(Constraints,"Constraint",1),
	
	sub:eplex_var_get(VarObiettivo,typed_solution,VarObiettivoVal),  
    write_tee("Out Value: "), writeln_tee(VarObiettivoVal),
    
    writeln_tee("------Duale-------"),
    sub:eplex_get(dual_solution,Dual),
    write_tee("Dual -> "), writeln_tee(Dual),
	
	writeln_tee("Assegnazione fondi completata"),
	close(outfile).
