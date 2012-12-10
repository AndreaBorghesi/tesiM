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
