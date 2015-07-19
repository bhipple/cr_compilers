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
Parse Trees and Derivations:
- Has Terminals at the leaves
- Has non-terminals at the interior nodes
- An in-order traversal of the leaves of the parse-tree gives the original input string
- The parse tree shows the association of the operations, while the input string does not

Left-most derivation: At each step building the parse tree, replace the left-most non-terminal of the input string

Equivalent notion of a right-most derivation

Note that for every parse tree, a right-most derivation and a left-most derivation generate equivalent parse trees.
