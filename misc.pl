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
	AvgOutcome is SumOutcome/(NumRes*100)+400.
	
%predicato per testing
avg_out(IncPer):-
	open('ris.txt',write,outfile),
	[simResValori],
	findall(O,result(_,IncPer,_,_,O),Outcomes),
	length(Outcomes,Len), sum(Outcomes,SumOutcome),
	AvgOut is SumOutcome/Len,
	write_tee("Avg. out per "), write_tee(IncPer),
 	write_tee("come perc. ---->"), write_tee(AvgOut),
	close(outfile).
	
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
	
	
