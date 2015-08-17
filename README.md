##Coursera / Stanford Course on Compilers with Alex Aiken
https://class.stanford.edu/courses/Engineering/Compilers/Fall2014/courseware

https://www.coursera.org/course/compilers

###Notes on tools
Run the compiler with:

`/usr/class/cs143/bin/coolc [-o fileout] file1.cl file2.cl ... filen.cl`

Run the compiled program with:

`/usr/class/cs143/bin/spim -file file.s

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

###Week 4
#####Predictive Parsers
LL(k) grammars that look ahead to the next few tokens and always choose the correct production rule.
 - No backtracking!

LL(k) means left-to-right with leftmost derivation and k-token lookahead.

In LL(1), there is only one choice of production at each step.

Because of these limitations, we have to `left factor` the grammar by removing common prefixes on production rules.
For example, 
```
E -> T + E | T
T -> int | int * T | (E)
Becomes:
E -> TX
X -> + E | epsilon
T -> intY | (E)
Y -> *T | epsilon
```
We can then construct a parsing table such that the rows correspond to symbols (X, Y, E, etc), columns correspond to terminals, and the cell at [row][col] says what production rule to apply when the input has that col value and the top of the parsing stack is the element at row.

#####First Sets
How to construct LL(1) parsing tables using first sets.

`First(X) = {t | X-> *tAlpha} U {epsilon | X ->* epsilon}`

Algorithm:
```
1. First(t) = { t }, for any terminal t
2. epsilon is in First(X) if X -> epsilon or X -> A1..AN and epsilon is in First(Ai) for i in [1,n]
3. First(alpha) is a subset of First(X) if X -> A1..ANalpha and epsilon is in Ai for i in [1,n]
```
For the previous grammar, we can compute the first sets:
 * First(E) = First(T)
 * First(T) = { (, int }
 * First(X) = { +, epsilon }
 * First(Y) = { *, epsilon }

#####Follow Sets
t is in the follow set of X if there is some derivation such that t can appear immediately after the derivation of X
`Follow(X) = { t | S ->* Beta X t delta}`

If X -> AB, then:
 * First(B) is a subset of Follow(A)
 * Follow(X) is a subset of Follow(B)
 * If B has an epsilon production, then Follow(X) is a subset of Follow(A)
 * If S is the start symbol, then $ is in Follow(S)

Note that epsilon never appears in follow sets, so a follow set is just a set of terminals
Algorithm:
```
1. $ in Follow(S)
2. First(Beta) - {epsilon} in Follow(X)
    for each production A -> alpha X Beta
3. Follow(A) in Follow(X)
    for each production A -> alpha X Beta where epsilon in First(Beta)
```
For the previous grammer and first sets, we compute the follow sets:

We can denote certain properties, such as:
 * Follow(X) subset Follow(E)
 * Follow(E) subset Follow(X) => Follow(X) == Follow(E)
 * Follow(T) subset First(X)
 * Follow(T) subset Follow(E)
 * Follow(Y) subset Follow(T)
 * Follow(T) subset Follow(Y) => Follow(T) == Follow(Y)

And the actual sets:
 * Follow(E) = { $, ) }
 * Follow(X) = { $, ) }
 * Follow(T) = { +,  $, ) }
 * Follow(Y) = { +, $, ) }
 * Follow('(') = { (, int }
 * Follow(')') = { +, $, ) }
 * Follow('+') = { (, int }
 * Follow('*') = { (, int }
 * Follow(int) = { *, +, $, ) }

#####LL(1) Parsing Tables
Rules: For each production A -> alpha,
 1. For each termianl t in First(alpha), do T[A, t] = alpha
 2. If epsilon in First(alpha), for each t in Follow(A) do T[A, t] = alpha
 3. If epsilon in First(alpha and $ in Follow(A), do T[A, $] = alpha

If any entry in the parsing table is multiply defined, then the grammar G is not LL(1)

The only way to prove that a grammar is LL(1) is to build the parsing table. That said, here are some quick ways to guarantee a grammar is NOT LL(1):
 * Not left-factored, or
 * Left recursive, or
 * Ambiguous

Most programming language CFGs are not LL(1).  LL(1) grammars are too weak.

####Bottom-Up Parsing
This is more general than (deterministic) top-down parsing, while being just as efficient.  This is the preferrred method for most parser generator tools.

Don't need left-factored grammars.

Bottom up parsing reduces a string to the start symbol by inverting productions.

**A bottom-up parser traces a rightmost derivation in reverse** by using reductions instead of productions.

#####Shift-Reduce Parsing
This is the primary strategy used by all bottom up parsers.

Two move types:
 * Shift move reads one token of input
 * Reduce move applies an inverse production at the right end of the left string

The left string is implemented by a stack, since we only do reduce operations immediately to the left of the |. Shift operations simply push a new character onto the stack.

**In shift-reduce parsing, handles appear only at the top of the stack, never inside**

**For any grammar, the set of viable prefixes is a regular language.**

Algorithm for recognizing viable prefixes of a grammar G:
1. Add a dummy production S' -> S to G
2. The NFA states are the items of G, including the extra production
  * The input to the NFA is the stack, and it will say yes if the stack is a valid prefix and no otherwise
3. For item E -> alpha . X Beta, with X either a terminal or non-terminal, add transition:
  * E -> alpha . X beta ->X E -> alpha X . beta, for input X
  * Add this kind of move for every move in the grammar
4. For item E -> alpha . X Beta and production X -> Gamma, with X a non-terminal, add transition:
  * E -> alpha . X Beta ->e X -> . Gamma
5. Every state in this automaton is an accepting state.
6. Start state is S' -> .S

#####SLR Parsing
LR(0) parsing: assume that:
  * the stack contains alpha
  * next input is t
  * DFA on input alpha terminates in state s

Then we need to reduce X -> B if:
  * s contains item X -> B.

And we need to shift if:
  * s contains item X -> B.tw
  * equivalent to saying s has a transition labeled t

SLR Parsing Algorithm:
1. Let M be a DFA for viable prefixes of G
2. Let |x1...xn$ be initial configuration
3. Repeat until configuration is S|$
  * Let alpha|w be current configuration
  * Run M on current stack alpha
  * If M accepts alpha with items i, let a be next input
    * Shift if X -> B . a y epsilon i
    * Reduce if X -> B . epsilon i and a in Follow(X)
    * Report parsing error if neither applies

######SLR Improvements
To avoid repeating work, we will remember the state of the automaton on each prefix of the stack, so the stack comtains `<symbol, dfa state>` pairs.  The state is the result of running the DFA on all the symbols to the left of it.  To get started, we store `<dummy, start>` on the bottom of the stack.

Define a table `goto[i, A] = j if state_i ->A state_j`

Modify the shift x operation to push `<a, x>` on the stack, where `a` is the current input and `x` is a DFA state

The reduce X -> alpha operation stays the same as before.

Complete SLR algorithm:
```
Let I = w$ be initial input
Let j = 0
Let DFA state 1 have item S' -> .S
Let stack = <dummy, 1>
repeat
  case action[top_state(stack), I[j]] of
        shift k: push <I[j++], k>
        reduce X -> A:
            pop |A| pairs,
            push <X, goto[top_state(stack), X]>
        accept: halt normally
        error: halt and report error
```
