%:-[risultati_sintetici].
:-[csv2pl].
%:-[costi_tot].

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
	
%predicato per testare l'output del simulatore
avg_out(IncPer):-
	open('ris.txt',write,outfile),
	[simResValori],
	findall(O,result(_,IncPer,_,_,O),Outcomes),
	length(Outcomes,Len), sum(Outcomes,SumOutcome),
	AvgOut is SumOutcome/Len,
	write_tee("Avg. out per "), write_tee(IncPer),
 	write_tee("come perc. ---->"), write_tee(AvgOut),
	close(outfile).

avg:-
	avg_out(2), avg_out(4), avg_out(6), avg_out(8), avg_out(10),
	avg_out(12), avg_out(14), avg_out(16), avg_out(18), avg_out(20),
	avg_out(22), avg_out(24), avg_out(26), avg_out(28), avg_out(30).
	
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

avgn:-
	[risultati_sintetici_new],
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
	
	
