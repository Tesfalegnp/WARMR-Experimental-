
:- use_module(library(apply)).

/* =========================================================
   1. DATABASE
   ---------------------------------------------------------
   Our input database contains family relationships.
   Each parent/2 fact represents a relationship between
   two people.
   ========================================================= */

family_database([
    parent(abel, hana),
    parent(hana, sami),
    parent(hana, lidiya),
    parent(bereket, sara),
    parent(sara, noah)
]).


/* =========================================================
   2. LANGUAGE BIAS
   ---------------------------------------------------------
   These rules restrict the patterns the miner may examine.

   predicates:
       Only parent/2 is allowed.

   modes:
       [-,-] = introduce two new variables.
       [+,-] = reuse an existing variable and introduce
               one new variable.

   connected:
       All literals must share variables through a
       connected relational structure.

   max_literals:
       A pattern may contain at most 2 relationships.

   patterns:
       Candidate patterns to evaluate.
       X, Y and Z are logical variables.
   ========================================================= */

family_language_bias(
    language_bias(
        predicates([parent/2]),

        modes([
            mode(parent, ['-', '-']),
            mode(parent, ['+', '-'])
        ]),

        connected(true),

        max_literals(2),

        patterns([

            % Pattern 1: One parent relationship
            pattern(
                parent_pattern,
                [parent(X, Y)],
                [X, Y]
            ),

            % Pattern 2: Two connected parent relationships
            pattern(
                two_step_parent,
                [parent(X, Y), parent(Y, Z)],
                [X, Y, Z]
            )

        ])
    )
).


/* =========================================================
   3. CHECK LANGUAGE BIAS
   ---------------------------------------------------------
   A candidate must satisfy:
     1. Allowed predicates.
     2. Declared argument modes.
     3. Connectivity restriction.
     4. Maximum number of literals.
   ========================================================= */

candidate_allowed(
    language_bias(
        predicates(Predicates),
        modes(Modes),
        connected(Connected),
        max_literals(MaxLiterals),
        _
    ),
    pattern(_, Goals, _)
) :-

    % Check the maximum number of relationships.
    length(Goals, NumberOfLiterals),
    NumberOfLiterals =< MaxLiterals,

    % Check whether all predicates are allowed.
    all_predicates_allowed(Goals, Predicates),

    % Check whether the candidate follows its modes.
    mode_sequence_ok(Goals, Modes, [], _),

    % Check whether the relationships are connected.
    (
        Connected = false
        ;
        Connected = true,
        connected_goals(Goals)
    ).


/* Check every predicate against the allowed list. */

all_predicates_allowed([], _).

all_predicates_allowed([Goal | Rest], Allowed) :-
    functor(Goal, Name, Arity),
    memberchk(Name/Arity, Allowed),
    all_predicates_allowed(Rest, Allowed).


/* =========================================================
   4. CHECK TYPE / MODE RESTRICTIONS
   ---------------------------------------------------------
   This small experiment uses two mode symbols:

      '-' = a new variable must be introduced.
      '+' = an existing variable must be reused.

   Example:
      parent(X,Y) : [-,-]
      parent(Y,Z) : [+,-]

   The second relationship reuses Y and introduces Z.

   The mode check assumes atomic arguments, as in this
   family example.
   ========================================================= */

mode_sequence_ok([], _, Seen, Seen).

mode_sequence_ok([Goal | Rest], Modes, Seen0, Seen) :-

    functor(Goal, Predicate, Arity),

    % Find an allowed mode declaration.
    member(mode(Predicate, ModeSpec), Modes),

    length(ModeSpec, Arity),

    % Check each argument according to its mode.
    arguments_follow_modes(
        1,
        Arity,
        Goal,
        ModeSpec,
        Seen0,
        Seen1
    ),

    % Continue with the next relationship.
    mode_sequence_ok(Rest, Modes, Seen1, Seen).


arguments_follow_modes(
    Position,
    Arity,
    _Goal,
    _Modes,
    Seen,
    Seen
) :-
    Position > Arity,
    !.

arguments_follow_modes(
    Position,
    Arity,
    Goal,
    Modes,
    Seen0,
    Seen
) :-

    arg(Position, Goal, Argument),
    nth1(Position, Modes, Mode),

    (
        % '-' means the argument must be a new variable.
        Mode = '-',
        var(Argument),
        \+ variable_already_seen(Argument, Seen0),

        Seen1 = [Argument | Seen0]

        ;

        % '+' means the argument must reuse an existing
        % variable.
        Mode = '+',
        var(Argument),
        variable_already_seen(Argument, Seen0),

        Seen1 = Seen0
    ),

    NextPosition is Position + 1,

    arguments_follow_modes(
        NextPosition,
        Arity,
        Goal,
        Modes,
        Seen1,
        Seen
    ).


variable_already_seen(Variable, [Existing | _]) :-
    Variable == Existing,
    !.

variable_already_seen(Variable, [_ | Rest]) :-
    variable_already_seen(Variable, Rest).


/* =========================================================
   5. CHECK CONNECTIVITY
   ---------------------------------------------------------
   Every relationship must be connected to the others
   through at least one shared variable.

   Example:
       parent(X,Y), parent(Y,Z)  = connected

       parent(X,Y), car(Z,W)     = disconnected
   ========================================================= */

connected_goals([]).

connected_goals([First | Rest]) :-

    term_variables(First, InitialVariables),

    grow_connected(
        Rest,
        InitialVariables,
        1,
        ConnectedCount
    ),

    length([First | Rest], TotalCount),

    ConnectedCount =:= TotalCount.


% Add another relationship if it shares a variable
% with the relationships already visited.

grow_connected([], _, Count, Count).

grow_connected(Goals, SeenVariables, Count0, Count) :-

    select(Goal, Goals, Remaining),

    term_variables(Goal, GoalVariables),

    shares_variable(GoalVariables, SeenVariables),

    !,

    append(SeenVariables, GoalVariables, NewSeen),

    Count1 is Count0 + 1,

    grow_connected(
        Remaining,
        NewSeen,
        Count1,
        Count
    ).


shares_variable([Variable | _], Seen) :-
    variable_already_seen(Variable, Seen),
    !.

shares_variable([_ | Rest], Seen) :-
    shares_variable(Rest, Seen).


/* =========================================================
   6. MATCH A CANDIDATE AGAINST THE DATABASE
   ---------------------------------------------------------
   Instead of reading facts from the whole Prolog program,
   this experiment checks only the supplied database list.
   ========================================================= */

goals_match(Database, Goals) :-
    maplist(goal_matches(Database), Goals).


goal_matches(Database, Goal) :-
    member(Fact, Database),
    Goal = Fact.


/* =========================================================
   7. CALCULATE FREQUENCY
   ---------------------------------------------------------
   We calculate two different quantities:

   CompleteMatches:
       All successful variable substitutions.

   DistinctKeys:
       Unique bindings of the selected key variable.

   WARMR-style support is based on distinct key bindings.

   key_index(1) means the first variable is the key.
   For our pattern, that variable is X.
   ========================================================= */

evaluate_candidate(
    Database,
    key_index(KeyIndex),
    MinFreq,
    pattern(Name, Goals, Variables),
    result(
        Name,
        Goals,
        CompleteMatches,
        MatchCount,
        DistinctKeys,
        KeyFrequency,
        Status
    )
) :-

    % Select the key variable using its position.
    nth1(KeyIndex, Variables, KeyVariable),

    % Collect all complete substitutions.
    findall(
        Variables,
        goals_match(Database, Goals),
        CompleteMatches
    ),

    length(CompleteMatches, MatchCount),

    % Collect all matching key bindings.
    findall(
        KeyVariable,
        goals_match(Database, Goals),
        AllKeys
    ),

    % Remove duplicate key values.
    sort(AllKeys, DistinctKeys),

    length(DistinctKeys, KeyFrequency),

    % Compare the key frequency with minimum frequency.
    (
        KeyFrequency >= MinFreq
        ->
        Status = frequent
        ;
        Status = infrequent
    ).


/* =========================================================
   8. RUN THE MINER
   ---------------------------------------------------------
   Inputs:
       Database
       Key variable position
       Minimum frequency
       Language bias

   Processing:
       1. Read candidate patterns.
       2. Apply language bias.
       3. Evaluate accepted candidates.
       4. Calculate complete matches and key frequency.
       5. Compare frequency with MinFreq.
   ========================================================= */

warmr_style_mine(
    Database,
    KeySpec,
    MinFreq,
    Bias,
    results(Results, Rejected)
) :-

    Bias = language_bias(_, _, _, _, patterns(Candidates)),

    % Separate accepted and rejected candidates.
    include(
        candidate_allowed(Bias),
        Candidates,
        Accepted
    ),

    exclude(
        candidate_allowed(Bias),
        Candidates,
        Rejected
    ),

    % Evaluate every accepted candidate.
    maplist(
        evaluate_candidate(Database, KeySpec, MinFreq),
        Accepted,
        Results
    ).


/* =========================================================
   9. DISPLAY RESULTS
   ========================================================= */

print_result(
    result(
        Name,
        Goals,
        CompleteMatches,
        MatchCount,
        DistinctKeys,
        KeyFrequency,
        Status
    )
) :-

    format('~n----------------------------------------~n'),

    format('Pattern name: ~w~n', [Name]),

    format('Candidate query: '),
    term_variables(Goals, QueryVariables),
    anonymous_variable_names(QueryVariables, VariableNames),
    write_term(Goals, [variable_names(VariableNames)]),
    nl,

    format(
        'Complete substitutions (~d): ~w~n',
        [MatchCount, CompleteMatches]
    ),

    format(
        'Distinct key bindings (~d): ~w~n',
        [KeyFrequency, DistinctKeys]
    ),

    format('Frequency status: ~w~n', [Status]).


anonymous_variable_names([], []).

anonymous_variable_names([Variable | Rest], ['_'=Variable | Names]) :-
    anonymous_variable_names(Rest, Names).


print_results([]).

print_results([Result | Rest]) :-
    print_result(Result),
    print_results(Rest).


/* =========================================================
   10. EXPERIMENT CONFIGURATION / MAIN ENTRY POINT
   ---------------------------------------------------------
   Change these values to perform another experiment.
   ========================================================= */

run_experiment :-

    % Input 1: Database
    family_database(Database),

    % Input 2: Key variable (first pattern variable = X)
    KeySpec = key_index(1),

    % Input 3: Minimum frequency (absolute key count)
    MinFreq = 2,

    % Input 4: Language bias
    family_language_bias(Bias),

    format('~n========== WARMR-STYLE EXPERIMENT ==========~n'),

    format('Minimum frequency: ~d~n', [MinFreq]),

    format('Key variable position: ~w~n', [KeySpec]),

    % Run the experiment.
    warmr_style_mine(
        Database,
        KeySpec,
        MinFreq,
        Bias,
        results(Results, _Rejected)
    ),

    % Display the accepted candidate results.
    print_results(Results),

    format('~n========== EXPERIMENT COMPLETED ==========~n').
