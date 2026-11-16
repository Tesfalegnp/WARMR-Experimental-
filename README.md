# WARMR Experimental

A small SWI-Prolog experiment over family relationships. It demonstrates a
two-edge relational pattern and counts both complete matches and distinct
ancestor bindings.

## Current scope

[`family.pl`](family.pl) defines five `parent/2` facts and the pattern:

```prolog
parent(Ancestor, Parent),
parent(Parent, Descendant).
```

`warmr_style_frequency/4` returns the complete matching substitutions and their
count, then the distinct ancestor keys and their count. With the included facts,
there are three complete substitutions but only two distinct ancestor keys.

This is a small WARMR-style frequency demonstration, not a complete WARMR
implementation. It does not generate or refine candidate patterns, perform a
search over patterns, or apply a support threshold.

## Requirements

- SWI-Prolog (tested with version 10.0.0)
- Micromamba, Mamba, or Conda for the optional environment setup below

## Setup

Create an isolated environment with micromamba:

```sh
micromamba create -y -n warmr-experiment -c conda-forge swi-prolog
```

If SWI-Prolog is already installed, this setup step is not needed.

## Run

From the project directory, run:

```sh
swipl -q -s family.pl -g run_experiment -t halt
```

For the micromamba environment created above:

```sh
micromamba run -n warmr-experiment swipl -q -s family.pl -g run_experiment -t halt
```

In the local environment used to verify this project, the command is:

```sh
"$HOME/.local/bin/micromamba" run -p "$HOME/.local/share/warmr-experiment-env" swipl -q -s family.pl -g run_experiment -t halt
```

Expected output:

```text
Complete substitutions (3): [(abel,hana,sami),(abel,hana,lidiya),(bereket,sara,noah)]
Distinct ancestor keys (2): [abel,bereket]
```

The relational query can also be run interactively:

```prolog
?- parent(Ancestor, Parent), parent(Parent, Descendant).
```

It yields `(abel, hana, sami)`, `(abel, hana, lidiya)`, and
`(bereket, sara, noah)`. Counting the full tuples gives three matches;
projecting to `Ancestor` and removing duplicates gives two key bindings.
