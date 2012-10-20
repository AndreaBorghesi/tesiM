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
sub_problem_fr():-

.

