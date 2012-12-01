:-[csv2pl].


%versione semplice: restituisce la media degli incentivi di installazione, budget incentivi e outcome energetico
sim_result(AvgIncIns,AvgOutcome):-
	[risultati_sintetici],
	findall(I,result(I,_,_,_,_),IncentiviInst),
	findall(O,result(_,_,_,_,O),Outcomes),
	length(IncentiviInst,NumRes),
	sum(IncentiviInst,SumIncIns),
	sum(Outcomes,SumOutcome),
	AvgIncIns is SumIncIns/NumRes,
	%occorre tenere conto del fattore di scala
	%ho stimato il fattore di scala eseguendo diverse simulazioni e confrontando il risultato con il valore delle simulazioni presentate in ecms12
	%AvgOutcome is SumOutcome/(NumRes).  ----- versione base non scalata
	AvgOutcome is (((SumOutcome/(NumRes*1000))-48.798)*(795/(57.675-48.798))+405).
	
%questa versione restituisce l'outcome medio prodotto dalle diverse tipologie di incentivi
sim_result_fr(Tipologie,AvgOutcomes,AvgBudgets):-
	[risultati_sintetici_new],
	srfb(Tipologie,[],AvgBudgets),
	srf(Tipologie,[],AvgOutcomes).

srf([],AvgOutcomes,AvgOutcomes).
srf([T|Tipologie],AvgOutTemp,AvgOutcomes):-
	findall(O,result_new(T,_,_,_,_,_,O),Outcomes),
	length(Outcomes,Len), sum(Outcomes,SumOutcome),
	
	%nessun fattore di scala
	AvgOutcome is SumOutcome/(Len*1000),
	%fattore di scala estremamente grezzo
	%AvgOutcome is (((SumOutcome/(Len*1000))-44.500)*(795/(54.000-44.500))+405),
	
	append(AvgOutTemp,[AvgOutcome],AvgOutcomesN),
	srf(Tipologie,AvgOutcomesN,AvgOutcomes).
	
srfb([],AvgBudgets,AvgBudgets).
srfb([T|Tipologie],AvgBudgetTemp,AvgBudgets):-
	findall(BI,result_new(T,_,_,_,BI,_,_),BudgetsI),
	findall(BF,result_new(T,_,_,_,_,BF,_),BudgetsF),
	length(BudgetsI,Len), sum(BudgetsI,SumBudgetsI), sum(BudgetsF,SumBudgetsF),
	
	%per ora il budget medio utilizzato da un tipo di incentivo è calcolato
	%semplicemente come la differenza media tra il budget iniziale e quello finale
	AvgBudgetR is (SumBudgetsI*1000000-SumBudgetsF)/Len,
	
	append(AvgBudgetTemp,[AvgBudgetR],AvgBudgetsN),
	srfb(Tipologie,AvgBudgetsN,AvgBudgets).
	
%predicato per testare l'output del primo simulatore
avg_out(IncPer):-
	open('ris.txt',write,outfile),
	[simResValori],
	findall(O,result(_,IncPer,_,_,O),Outcomes),
	length(Outcomes,Len), sum(Outcomes,SumOutcome),
	AvgOut is SumOutcome/Len,
	write_tee("Avg. out per "), write_tee(IncPer),
 	write_tee("come perc. ---->"), write_tee(AvgOut),
	close(outfile).

%predicato per calcolare output medio con il primo sim, per incentivi crescenti da 2 a 30 (i risultati della sim devono essere in simResValori.pl)
avg:-
	avg_out(2), avg_out(4), avg_out(6), avg_out(8), avg_out(10),
	avg_out(12), avg_out(14), avg_out(16), avg_out(18), avg_out(20),
	avg_out(22), avg_out(24), avg_out(26), avg_out(28), avg_out(30).
	
%predicato per testare l'output del secondo sim. ( con finanaziamenti regionali )
avg_outn(Fr,Br,IncPer):-
	open('ris.txt',write,outfile),
	findall(O,result_new(Fr,_,IncPer,_,Br,_,O),Outcomes),
	findall(I,result_new(Fr,I,IncPer,_,Br,_,_),Incentivi),
	findall(B,result_new(Fr,_,IncPer,_,Br,B,_),BudgFinali),
	length(Outcomes,Len), sum(Outcomes,SumOutcome),
	sum(Incentivi,SumIncentivi), sum(BudgFinali,SumBudgFinali),
	AvgOut is SumOutcome/Len,
	AvgInc is SumIncentivi/Len,
	AvgBudFin is SumBudgFinali/Len,
	write_tee("Avg. out con fin. "), write_tee(Fr),
	write_tee(" ,budget reg. "), write_tee(Br),
	write_tee(" ,percentuale incentivi "), write_tee(IncPer),
	write_tee(" ,valore incentivi(?) "), write_tee(AvgInc),
	write_tee(" e budget reg. finale "), write_tee(AvgBudFin),
 	write_tee(" ---->"), write_tee(AvgOut), writeln_tee(" "),
	close(outfile).
	
%predicato per calcolare output medio con il secondo sim, per incentivi crescenti da 2,10,20,30 con le cinque modalità di finanziamento
%(i risultati della sim devono essere in risultati_sintetici_new.pl)
avgn:-
	%[risultati_sintetici_new],
	[simulazioneLungaResultNew],
	
	avg_outn('Nessuno',0,2), avg_outn('Asta',0,2), avg_outn('Conto interessi',0,2),
	avg_outn('Rotazione',0,2), avg_outn('Garanzia',0,2),
	avg_outn('Nessuno',5,2), avg_outn('Asta',5,2), avg_outn('Conto interessi',5,2),
	avg_outn('Rotazione',5,2), avg_outn('Garanzia',5,2),
	avg_outn('Nessuno',10,2), avg_outn('Asta',10,2), avg_outn('Conto interessi',10,2),
	avg_outn('Rotazione',10,2), avg_outn('Garanzia',10,2),
	
	avg_outn('Nessuno',0,10), avg_outn('Asta',0,10), avg_outn('Conto interessi',0,10),
	avg_outn('Rotazione',0,10), avg_outn('Garanzia',0,10),
	avg_outn('Nessuno',5,10), avg_outn('Asta',5,10), avg_outn('Conto interessi',5,10),
	avg_outn('Rotazione',5,10), avg_outn('Garanzia',5,10),
	avg_outn('Nessuno',10,10), avg_outn('Asta',10,10), avg_outn('Conto interessi',10,10),
	avg_outn('Rotazione',10,10), avg_outn('Garanzia',10,10),
	
	avg_outn('Nessuno',0,20), avg_outn('Asta',0,20), avg_outn('Conto interessi',0,20),
	avg_outn('Rotazione',0,20), avg_outn('Garanzia',0,20),
	avg_outn('Nessuno',5,20), avg_outn('Asta',5,20), avg_outn('Conto interessi',5,20),
	avg_outn('Rotazione',5,20), avg_outn('Garanzia',5,20),
	avg_outn('Nessuno',10,20), avg_outn('Asta',10,20), avg_outn('Conto interessi',10,20),
	avg_outn('Rotazione',10,20), avg_outn('Garanzia',10,20),
	
	avg_outn('Nessuno',0,30), avg_outn('Asta',0,30), avg_outn('Conto interessi',0,30),
	avg_outn('Rotazione',0,30), avg_outn('Garanzia',0,30),
	avg_outn('Nessuno',5,30), avg_outn('Asta',5,30), avg_outn('Conto interessi',5,30),
	avg_outn('Rotazione',5,30), avg_outn('Garanzia',5,30),
	avg_outn('Nessuno',10,30), avg_outn('Asta',10,30), avg_outn('Conto interessi',10,30),
	avg_outn('Rotazione',10,30), avg_outn('Garanzia',10,30).
	
%predicato per calcolare output medio con il secondo sim, con le cinque modalità di finanziamento e senza incentivi (oltre al finanziamento)
avgnz:-
	[risultati_sintetici_new],
	%[simulazioneLungaResultNewNoInc],
	
	%avg_outn('Nessuno',0,1), avg_outn('Asta',0,1), avg_outn('Conto interessi',0,1),
	%avg_outn('Rotazione',0,1), avg_outn('Garanzia',0,1),
	%avg_outn('Nessuno',5,1), avg_outn('Asta',5,1), avg_outn('Conto interessi',5,1),
	%avg_outn('Rotazione',5,1), avg_outn('Garanzia',5,1),
	%avg_outn('Nessuno',10,1), avg_outn('Asta',10,1), avg_outn('Conto interessi',10,1),
	%avg_outn('Rotazione',10,1), avg_outn('Garanzia',10,1).
	avg_outn('Asta',0,1), 
	avg_outn('Asta',2,1), 
	avg_outn('Asta',5,1), 
	avg_outn('Asta',7,1), 
	avg_outn('Asta',8,1), 
	%avg_outn('Conto interessi',5,1),
	%avg_outn('Rotazione',5,1), avg_outn('Garanzia',5,1),
	avg_outn('Asta',10,1),
	avg_outn('Asta',11,1), 
	avg_outn('Asta',12,1),  
	%avg_outn('Conto interessi',10,1),
	%avg_outn('Rotazione',10,1), avg_outn('Garanzia',10,1),
	avg_outn('Asta',15,1). 
	%avg_outn('Conto interessi',15,1),
	%avg_outn('Rotazione',15,1), avg_outn('Garanzia',15,1),
	%avg_outn('Conto interessi',20,1),
	%avg_outn('Rotazione',20,1), avg_outn('Garanzia',20,1),
	%avg_outn('Conto interessi',30,1),
	%avg_outn('Rotazione',30,1), avg_outn('Garanzia',30,1).
	%avg_outn('Nessuno',20,1), avg_outn('Asta',20,1), avg_outn('Conto interessi',20,1),
	%avg_outn('Rotazione',20,1), avg_outn('Garanzia',20,1),
	%avg_outn('Nessuno',40,1), avg_outn('Asta',40,1), avg_outn('Conto interessi',40,1),
	%avg_outn('Rotazione',40,1), avg_outn('Garanzia',40,1).
	
%calcola output medio con il secondo sim, con le 4 modalità di finanziamento e senza incentivi, budget crescenti
avgs:-
	[simulazioneLungaResultNewNoInc2],
	avg_outn('Asta',5,1), avg_outn('Conto interessi',5,1),
	avg_outn('Rotazione',5,1), avg_outn('Garanzia',5,1),
	avg_outn('Asta',7.5,1), avg_outn('Conto interessi',7.5,1),
	avg_outn('Rotazione',7.5,1), avg_outn('Garanzia',7.5,1),
	avg_outn('Asta',10,1), avg_outn('Conto interessi',10,1),
	avg_outn('Rotazione',10,1), avg_outn('Garanzia',10,1),
	avg_outn('Asta',15,1), avg_outn('Conto interessi',15,1),
	avg_outn('Rotazione',15,1), avg_outn('Garanzia',15,1),
	avg_outn('Asta',20,1), avg_outn('Conto interessi',20,1),
	avg_outn('Rotazione',20,1), avg_outn('Garanzia',20,1),
	avg_outn('Asta',25,1), avg_outn('Conto interessi',25,1),
	avg_outn('Rotazione',25,1), avg_outn('Garanzia',25,1),
	avg_outn('Asta',30,1), avg_outn('Conto interessi',30,1),
	avg_outn('Rotazione',30,1), avg_outn('Garanzia',30,1).
	
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
	

%invocazioni multiple di benders_dec_fr possono incorrere in conflitti con i file precedentemente generati --> pulizia manuale
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
	
%fissato il tipo di incentivo,calcola la varianza degli outcome ottenuti dal simulatore per un determinato budget
calc_variance(Tipo,Budget):-
	[risultati_sintetici_new],
	findall(O,result_new(Tipo,_,_,_,Budget,_,O),L),
	open('ris.txt',write,outfile),
	length(L,NL),   sum(L,SumL),
	Mean is SumL/NL,  %prima calcolo il valore medio
	sum_square_diff(L,Mean,0,SumSD),
	Variance is SumSD/(NL-1),
	write_tee(outfile,"Variance: "),  writeln_tee(outfile,Variance),
	close(outfile).
	
%somma dei quadrati delle differenze dal valore medio
sum_square_diff([],_,Sum,Sum).
sum_square_diff([H|T],Mean,Sum0,Sum):-
	ST is Sum0 + (H-Mean)*(H-Mean),
	sum_square_diff(T,Mean,ST,Sum).
	
