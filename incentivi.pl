%lista di incentivi per il primo modello
incentivi(["Impianti fotovoltaici","Impianti solari termodinamici"]).

%lista delle tipologie di incentivazione per il sedondo modello
tipi_inc_PV(['Asta','Conto interessi','Rotazione','Garanzia']).



%lista dei punti che definiscono la linea spezzata con cui approssimare le curve per i vari incentivi ricavate con R
%punti(Tipo Incentivo,[Lista Punti:(Budget mln euro,Outcome MW)])
punti('Asta',[(1,21.789),(33.99,23.358),(40,23.334)]).
punti('Conto interessi',[(1,23.109),(2.53,25.270),(40,25.247)]).
punti('Rotazione',[(1,21.950),(31.96,25.031),(40,25.386)]).
punti('Garanzia',[(1,21.834),(13.74,23.398),(35.22,23.494),(40,23.457)]).

%valori di outcome con budget 0mln 
base_value('Nessuno',21.664).
%base_value('Asta',21.742).
%base_value('Conto interessi',21.668).
%base_value('Rotazione',21.850).
%base_value('Garanzia',21.717).
%base_value('Asta',0).
%base_value('Conto interessi',0).
%base_value('Rotazione',0).
%base_value('Garanzia',0).
