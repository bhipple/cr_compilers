##Coursera / Stanford Course on Compilers with Alex Aiken
https://class.stanford.edu/courses/Engineering/Compilers/Fall2014/courseware

https://www.coursera.org/course/compilers

###Week 1
####Phases of Compilation:
- Lexical Analysis
- Parsing
- Semantic Analysis
- Optimization
- Code Generation

####On languages
Application domains have conflicting needs, and programmer training is the dominant cost for a new language.  Consequently it's hard to change existing languages, since they have many programmers to train.  Together, this explains why we have so many languages, and why new ones are always coming out.

####COOL - Classroom Object Oriented Language
#####Features
- Abstraction
- Static Typing
- Reuse (inheritance)
- Automatic memory management
- And more!
- Compiles COOL programs into MIPS Assembly Language

#####Five programming assignments:
- Write a Cool program and interpreter
- Lexical Analysis
- Parsing
- Semantic Analysis
- Code Generation
#####Syntax
- Ends in file extension.cl
- Everything terminated by ;
- A program consists of a list of class declarations
- coolc is the compiler invocation

#### Lexing
Goes through the file and generates <Token Class, String> pairs for the Parser
##### Token Classes
- Whitespace
- Operator
- Keywords
- Identifiers
- Numbers
- etc.
- Partitions the input string into lexemes, and identifies the token of each lexeme.  Sometimes requires look-ahead, though we want to bound this with good language design

##### Regular Expressions and Formal Languages
Let Sigma be a set of characters (an alphabet). A language over Sigma is a set of strings of characters drawn from Signa.

For a language over an alphabet Sigma, we define a regular language with a Grammar
```
    R = epsilon
      | 'c' such that c is in Sigma
      | R + R
      | RR
      | R*
```

#### Lexical Specifications
An "if" token is the concatentation of two single characters `'i''f'`. Most tools will let us write this as `'if'`

`digit = '0' + '1' + '2' + '3' + '4' + '5' + '6' + '7' + '8' + '9'`

`number = digit digit*`

There is a very common pattern AA*.  Most tools let us simplify this to A^+

`letter = 'a' + 'b' + 'c' + 'd' . . . 'z' + 'A' + . . . + 'Z'` (Shorthand: [a-zA-Z])

`identifier = letter(letter + digit)*`

`whitespace = ' ' + '\t\ + '\n'`

When resolving ambiguities,
- Maximal Munch: Regexes are greedy
- Token classes are given priorities (keywords > identifiers, for example)
- Good algorithms are known, which require only a single pass and very few operations at each char

#### Lexing Process
Lexical Specification -> Regular expressions -> NFA -> DFA -> Table-driven implementation of DFA

### Week 2
#### Finite Automata
Regular expressions provide the specification; finite automata provide the implementation.

A finite automaton consists of:
- An input alphabet Sigma
- A finite set of states S
- A start state n
- A set of accepting states F <= S
- A set of transitions f(state, input) -> state


Converting a RegExp to a Nondeterministic Finite Automata

####DFA Implementation
Use a matrix where every row is a state and every column is an input of the alphabet

Basic idea with a state transition matrix:
```
i = 0;
state = 0;
while(input[i]) {
    state = A[state, input[i++]];
}
```

As a memory optimization, we often implement it in the adjacency list approach, with each state sharing the vector of states to go to if they are identical.

### Week 3
#### Parse Trees and Derivations
- Has Terminals at the leaves
- Has non-terminals at the interior nodes
- An in-order traversal of the leaves of the parse-tree gives the original input string
- The parse tree shows the association of the operations, while the input string does not

Left-most derivation: At each step building the parse tree, replace the left-most non-terminal of the input string

Equivalent notion of a right-most derivation

Note that for every parse tree, a right-most derivation and a left-most derivation generate equivalent parse trees.

#### Resolving Ambiguities
A grammar is ambiguous if it has more than one parse tree for some string (e.g., there is more than one right-most or left-most derivation for some string).

Ambiguous languages are ill-defined. The most direct solution to this is to rewrite the CFG to generate the same language in an unambiguous way

```
E -> E' + E | E'
E' -> id * E' | id | (E) * E' | (E)
```
The above unambiguously parses `id * id + id`, with * having precedence over +.

Another such example are if-then-else expressions where the else is optional:
```
E -> if E then E
   | if E then E else E
   | OTHER
```
Generally, we want every `else` to match the closest unmatched `then`.
```
E -> MatchedIf
   | UnmatchedIf

MatchedIf -> if E then MatchedIf else MatchedIf
           | OTHER

UnmatchedIf -> if E then E
             | if E then MatchedIf else UnmatchedIf
```
This will do the correct thing on a statement like `if then if then else`

We could rewrite grammars to be unambiguous, but in practice it's often much harder to understand. An alternative approach is to write the grammar unambiguously, and then use a tool that allows specifiying associativity or precedence to disambiguate.

#### Error Handling
Should:
- Report errors accurately and clearly
- Recover from an error quickly
- Not slow down compilation of valid code

Three kinds of error handling:
- Panic Mode
    Simplest and most common method used today
    When an error is detected, the parser discards tokens until one with a clear role is found, then continues from there.
    Looks for "syunchronizing tokens", typically the statement or expression terminators
    Bison has a terminal symbol "error" to describe how much input to skip:

    `E --> int | E + E | (E) | error int | (error)`

    First try the three normal productions. If none work, throw away input until we get to the next integer or a bracketed error
- Error Productions
    Add a rule `E --> EE`
    Specify known common mistakes in the grammar that programmers make.
    This is the mechanism by which compiler warners are generated, where the compiler warns the programmer about some piece of code but accepts it anyway.

- Automatic local or global correction
    Trying to find a correct "nearby" program, by doing token insertions and deletions (edit distance).
    This is hard to implement, nearby is not necessarily the 'correct' program, and most importantly this will slow down the parsing of correct programs.
    The most famous example is the PL/C compiler, which is able to compile almost anything
    Complex error recovery was more important a few decades ago, when users could only compile once per day. In this scenario, they wanted the compiler to catch as many errors as possible in each iteration.

#### Abstract Syntax Trees
Like a parse tree, but with some details abstracted away (parse trees are too verbose)

Remove redundant nodes like single-successor nodes, parenthesis (tree structure shows order already)

#### Parsing Algorithms
##### Recursive Descent
Top-down parsing algorithm that constructs the parse tree from the top and from left to right.

Consider the grammer
```
E -> T | T + E
T -> int | int * T | (E)
```
We start with the top-level non-terminal E, and try the production rules for E in order.  When a production fails, we have to do some backtracking.

We keep applying rules until we get to a terminal, at which point we check to see if we can consume legitimately from the input stream. If the input stream matches, great; if not, we have to backtrack up a node and try the next production rule.

```
bool term(TOKEN tok) { return *next++ == tok; }`
bool Sn() { ... }
bool S() { ... }
```
Functions that determine if we can produce a given terminal, if we can match the nth production of S, or if we can match any production of S, respectively.

Here's a complete example of a CFG plus a recursive descent parser implementation:
```
E -> T | T + E
T -> int | int * T | (E)

bool term(TOKEN tok) { return *next++ == tok; }

bool E1() { return T(); }
bool E2() { return T() && term(PLUS) && E(); }

bool E() { TOKEN *save = next; return (next = save, E1())
                                   || (next = save, E2()); }

bool T1() { return term(INT); }
bool T2() { return term(INT) && term(TIMES) && T(); }
bool T3() { return term(OPEN) && E() && term(CLOSE); }

bool T() { TOKEN *save = next; return (next = save, T1())
                                   || (next = save, T2())
                                   || (next = save, T3()); }
```
Limitations: If a production for non-terminal X succeeds, there's no way to backtrack and try a different production for X later. There are recursive descent algorithms that support "full" backtracking, with substantially more complicated implementations. We can get around this problem when we have a grammar where for any non-terminal at most one production can succeed through `left-factoring`.

##### Left Recursion
A left-resursive grammar has a non-terminal S, as in `S -> Sa`, where you have a production that has the same symbol in the leftmost position.  This causes the above algorithm to get stuck in an infinite loop.

Consider the left-resursive grammar `S-> Sa | b`.  S generates all strings starting with a `b` and followed by any number of `a`.  This recursion wants to create the leftmost symbol last.

Can rewrite using right-recursion: `S -> bS'`, `S' -> aS' | e`, which works with our left-recursive descent algorithm.

Watch out for delayed left-recursion:
```
S -> Xa | b
A -> Sc | d
```
The Dragon Book has some algorithms for eliminating the non-obvious left recursive problem above.  This means that, in principle, there are automated ways to remove left-recursion. In practice, people do it by hand so that they can still work with their grammar.

Recursive descent is often used in production compilers, including gcc.
