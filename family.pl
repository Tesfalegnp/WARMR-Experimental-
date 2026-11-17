
/* ========================================================
   1. DATABASE FACTS
   ========================================================
*/

parent(abel, hana).
parent(hana, sami).
parent(hana, lidiya).
parent(bereket, sara).
parent(sara, noah).


/* ========================================================
   2. RELATIONAL PATTERN DEFINITION
   ========================================================
*/

find_three_generation_chain(X, Y, Z) :-
    parent(X, Y),
    parent(Y, Z).


/* ========================================================
   3. FREQUENCY CALCULATION
   ========================================================
*/

calculate_pattern_frequency( CompleteMatches, MatchCount, AncestorKeys, KeyFrequency ) :-

    % Step 1: Collect all complete pattern matches.
    findall(
        (X, Y, Z),
        find_three_generation_chain(X, Y, Z),
        CompleteMatches
    ),

    % Step 2: Count all complete substitutions.
    length(CompleteMatches, MatchCount),

    % Step 3: Find distinct ancestor keys (unique X values).
    setof(
        X,
        Y^Z^find_three_generation_chain(X, Y, Z),
        AncestorKeys
    ),

    % Step 4: Count the distinct ancestor keys.
    length(AncestorKeys, KeyFrequency).


/* ========================================================
   4. RUN THE EXPERIMENT
   ========================================================
*/

run_frequency_experiment :-

    % Calculate complete matches and distinct key frequency.
    calculate_pattern_frequency( CompleteMatches, MatchCount, AncestorKeys,  KeyFrequency ),

    % Display all complete substitutions.
    format('Complete matching substitutions (~d): ~w~n', [MatchCount, CompleteMatches] ),

    % Display unique ancestor keys.
    format( 'Distinct ancestor keys (~d): ~w~n', [KeyFrequency, AncestorKeys]).
