%miscellaneous utilities
:-[csv2pl].

%%%%%%%%%%%%%%%   CONSTRAINTS  %%%%%%%%%%%%%%%%%%%%%%%%%
%scrittura nel fil fr_cons.pl dei valori per un'assegnazione ottimale dei fondi ai vari incentivi: per ora dal problema principale saranno intepretati come vincoli ad assegnare ai diversi un budget maggiore o uguale di quello specificato
%con la forma: fr_constr("tipologia incentivo",valore).
write_cons_file(_,[],[]).
write_cons_file(frcons,[T|TipiInc],[V|Values]):-
	
	ValF is V*1000000,
	
	write(frcons,"fr_constr(\'"), write(frcons,T), write(frcons,"\',"),
	write(frcons,ValF), write(frcons,").\n"),
	write_cons_file(frcons,TipiInc,Values).


%%%%%%%%%%%%% PRINT %%%%%%%%%%%%%%%%%%%
%predicato per stampare lunghe liste in formato più leggibile
pretty_print_list([],_,_):-!.
pretty_print_list([H|T],ElementName,N):-
	write_tee(ElementName), write_tee(" "), 
	write_tee(N), write_tee(" : "), writeln_tee(H),
	NN is N+1,
	pretty_print_list(T,ElementName,NN). 

	
	
%%%%%%%%%%%% PIECEWISE APPROX. %%%%%%%%%%%%%%%%%%
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
	
	
	


%predicato che restituisce il budget e l'outcome calcolati dal piano 
budget_outcomePV(BudgetPV,OutcomePV):-
	%converte in formato pl il file generato dal ottimizzatore
	csv2pl('costi_tot',[a,b,c,d,e]),
	%compila il file modificato
	[costi_tot],
	
	findall(B,costi_tot("Impianti fotovoltaici",_,_,B,_),PV),
	first(PV,BudgetPV),
	findall(O,costi_tot("Impianti fotovoltaici",O,_,_,_),PV2),
	first(PV2,OutcomePV).

first([H|_],H).
    
%predicato che restituisce gli incentivi per il fotovoltaico
incPV([],[],_).
incPV([I|Incentivi],[T|Titoli],IncentiviPV):-
	T == "Impianti fotovoltaici", !,
	IncentiviPV = I,
	%eplex:eplex_var_get(I,typed_solution,IncentiviPV),
	incPV(Incentivi,Titoli,IncentiviPV).
incPV([_|Incentivi],[_|Titoli],IncentiviPV):-
	incPV(Incentivi,Titoli,IncentiviPV).

%trova il tipo di finanziamento regionale che produce più energia
best_fr(Tipologie,Outcomes,BestT,BestO):-
	BestO is max(Outcomes),
	find_best_type(Tipologie,Outcomes,BestO,BestT).
	
find_best_type([],[],_,_).
find_best_type([T|Tipologie],[BestO|Outcomes],BestO,T):-!,
	find_best_type(Tipologie,Outcomes,BestO,_).
find_best_type([_|Tipologie],[_|Outcomes],BestO,BestT):-
	find_best_type(Tipologie,Outcomes,BestO,BestT).
	
	
	
%cambia il segno agli elementi di una lista
change_sign([],L,L).
change_sign([H|T],LT,L):-
	HN is -H,
	append(LT,[HN],LN),
	change_sign(T,LN,L).
	
	
%%%%%%%%%%%%%%%%%% CLEANING %%%%%%%%%%%%%%%%%
%invocazioni multiple di gest_inc possono incorrere in conflitti con i file precedentemente generati --> pulizia manuale
clean_fr:-
	res_fr_cons,
	res_rel.
		
%predicato per azzerare i valori del file fr_cons.pl
res_fr_cons:-
	tipi_inc_PV(TipiInc),
	open('fr_cons.pl',write,frcons),
	write_cons(TipiInc),
	write_ricavi(TipiInc),
	close(frcons).
	
write_cons([]).
write_cons([H|T]):-
	write(frcons,"fr_constr(\'"), write(frcons,H), write(frcons,"\',"),
	write(frcons,0), write(frcons,").\n"),
	write_cons(T).
	
write_ricavi([]).
write_ricavi([H|T]):-
	write(frcons,"fr_ricavo(\'"), write(frcons,H), write(frcons,"\',"),
	write(frcons,0), write(frcons,").\n"),
	write_ricavi(T).

%predicato per cancellare i valori dal file rel.pl
res_rel:-
	open('rel.pl',write,frel),
	write(frel,"%rel(\'Tipo incentivo\',Outcome,BudgetPV consumato)"),
	close(frel).
	
	
%%%%%%%%%%%%%%%  USEFUL CONVERSIONS (SIMULATIONS) %%%%%%%%%%%%%%%
%converte i file .pl generati dal simulatore in file .csv ( relazione budget-out )
pl2csv:-
	[temp],
	findall((B,O),result_new(_,_,_,_,B,_,O),L),
	open('result_list.csv',write,fout),
	write(fout,"Budget,Out\n"),
	write_lns(L,fout),
	close(fout).
	
write_lns([],_).
write_lns([(B,O)|T],fout):-
	write(fout,B), write(fout,","),
	write(fout,O), write(fout,"\n"),
	write_lns(T,fout).
	
%questa versione lavora con i risultati prodotti considerando anche l'interazione sociale ( solo sensibilità ) ( relazione sensibilità-out )
pl2csv_soc(Tipo):-
	[temp],
	findall((O,S),result_new(Tipo,_,_,_,_,_,O,_,S),L),
	open('result_list.csv',write,fout),
	write(fout,"Sens,Out\n"),
	write_lns_soc(L,fout),
	close(fout).
	
write_lns_soc([],_).
write_lns_soc([(O,S)|T],fout):-
	write(fout,S), write(fout,","),
	write(fout,O), write(fout,"\n"),
	write_lns_soc(T,fout).
	
%questa versione lavora con i risultati prodotti considerando anche l'interazione sociale ( solo raggio ) ( relazione raggio-out )
pl2csv_socr(Tipo):-
	[temp],
	findall((O,R),result_new(Tipo,_,_,_,_,_,O,R,_),L),
	open('result_list.csv',write,fout),
	write(fout,"Raggio,Out\n"),
	write_lns_socr(L,fout),
	close(fout).
	
write_lns_socr([],_).
write_lns_socr([(O,R)|T],fout):-
	write(fout,R), write(fout,","),
	write(fout,O), write(fout,"\n"),
	write_lns_socr(T,fout).
	
%viene considerata la relazione tra il budget disponibile e quello effettivamente speso 
pl2csv_b:-
	[temp],
	findall((B,S),result_new(_,_,_,_,B,S,_),L),
	open('result_list.csv',write,fout),
	write(fout,"Budget,Spesa\n"),
	write_lnsb(L,fout),
	close(fout).
	
write_lnsb([],_).
write_lnsb([(B,S)|T],fout):-
	write(fout,B), write(fout,","),
	O is (B-S/1000000),
	write(fout,O), write(fout,"\n"),
	write_lnsb(T,fout).
