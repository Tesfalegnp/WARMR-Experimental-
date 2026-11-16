parent(abel, hana).
parent(hana, sami).
parent(hana, lidiya).
parent(bereket, sara).
parent(sara, noah).

two_step_parent(Ancestor, Parent, Descendant) :-
	parent(Ancestor, Parent),
	parent(Parent, Descendant).

warmr_style_frequency(CompleteMatches, MatchCount, AncestorKeys, KeyFrequency) :-
	findall((Ancestor, Parent, Descendant),
			two_step_parent(Ancestor, Parent, Descendant),
			CompleteMatches),
	length(CompleteMatches, MatchCount),
	setof(Ancestor,
		  Parent^Descendant^two_step_parent(Ancestor, Parent, Descendant),
		  AncestorKeys),
	length(AncestorKeys, KeyFrequency).

run_experiment :-
	warmr_style_frequency(CompleteMatches, MatchCount, AncestorKeys, KeyFrequency),
	format('Complete substitutions (~d): ~w~n', [MatchCount, CompleteMatches]),
	format('Distinct ancestor keys (~d): ~w~n', [KeyFrequency, AncestorKeys]).
