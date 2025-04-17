## `tree-sitter.alias` {#function-library-tree-sitter.alias}

Alternates a name of rule in the syntax tree.
If the name is specified with a symbol (as in `alias s.foo (s "bar")`),
then the aliased rule appeared as a named node.
And if the name is specified with a literal string, then
the aliased rule appeared as a anonymous node.

### Type

```
alias :: Rule -> String or Symbol -> Rule
```

### Example

```nix
s: alias s.foo (s "bar")
s: alias s.foo "bar"
```

## `tree-sitter.blank` {#function-library-tree-sitter.blank}

A blank/empty rule.

### Type

```
blank :: Rule
```

### Example

```nix
s: choice ["foo" blank]
# Or, alternatively
s: optional "foo"
```

## `tree-sitter.field` {#function-library-tree-sitter.field}

Assigns a field to a children of a rule.

### Type

```
field :: String -> Rule -> Rule
```

### Example

```nix
s: seq [
  (field "foo" (alias "foo" (s "foo"))
  (field "bar" (optional (alias "bar" (s "bar"))))
]
```

## `tree-sitter.choice` {#function-library-tree-sitter.choice}

Creates a rule that matches one of a set possibilites.

### Type

```
choice :: ListOf Rule -> Rule
```

### Example

```nix
s: choice [
  "foo"
  "bar"
]
```

## `tree-sitter.optional` {#function-library-tree-sitter.optional}

Creates a rule that matches zero or one occurance of a given rule.

### Type

```
optional :: Rule -> Rule
```

### Example

```nix
s: optional "foo"
```

## `tree-sitter.prec` {#function-library-tree-sitter.prec}

Marks a rule with a numerical precedence.

### Type

```
prec :: Number -> Rule -> Rule
```

### Example

```nix
s: prec 10 "foo"
```

## `tree-sitter.prec.dynamic` {#function-library-tree-sitter.prec.dynamic}

Marks a rule with a numerical precedence that's applied at runtime.

### Type

```
prec.dynamic :: Number -> Rule -> Rule
```

### Example

```nix
s: prec.dynamic 10 "foo"
```

## `tree-sitter.prec.left` {#function-library-tree-sitter.prec.left}

Marks a rule with a numerical precedence and left-associative.

### Type

```
prec.left :: Number -> Rule -> Rule
```

### Example

```nix
s: prec.left 0 "foo" # Default in the JS DSL
s: prec.left 10 "bar"
```

## `tree-sitter.prec.right` {#function-library-tree-sitter.prec.right}

Marks a rule with a numerical precedence and right-associative.

### Type

```
prec.right :: Number -> Rule -> Rule
```

### Example

```nix
s: prec.right 0 "foo" # Default in the JS DSL
s: prec.right 10 "bar"
```

## `tree-sitter.repeat` {#function-library-tree-sitter.repeat}

Creates a rule that matches zero-or-more occurences of a given rule.

### Type

```
repeat :: Rule -> Rule
```

### Example

```nix
s: repeat "foo"
```

## `tree-sitter.repeat1` {#function-library-tree-sitter.repeat1}

Creates a rule that matches one-or-more occurences of a given rule.

### Type

```
repeat1 :: Rule -> Rule
```

### Example

```nix
s: repeat1 "foo"
```

## `tree-sitter.seq` {#function-library-tree-sitter.seq}

Creates a rule that matches any number of other rules, one after another.

### Type

```
seq :: ListOf Rule -> Rule
```

### Example

```nix
s: seq [
  "foo"
  " "
  "bar"
]
```

## `tree-sitter.sym` {#function-library-tree-sitter.sym}

Creates a rule that references to a node from the syntax tree.

### Type

```
sym :: String -> Symbol
```

### Example

```nix
s: sym "foo"
```

## `tree-sitter.reserved` {#function-library-tree-sitter.reserved}

Overrides the global reserved word set with the given wordset.

### Type

```
reserved :: String -> Rule -> Rule
```

## `tree-sitter.token` {#function-library-tree-sitter.token}

Marks a given rule as producing only a single token.

### Type

```
token :: Rule -> Rule
```

### Example

```nix
s: token (choice [
  "foo"
  "bar"
])
```

## `tree-sitter.token.immediate` {#function-library-tree-sitter.token.immediate}

Same as `token`, except it doesn't recognize rules in `extras` as valid syntax if there's any.

### Type

```
token.immediate :: Rule -> Rule
```

## `tree-sitter.regex` {#function-library-tree-sitter.regex}

Creates a rule that matches a [Rust regex](https://docs.rs/regex/1.1.8/regex/#syntax) pattern.

### Type

```
regex :: String -> Rule
```

### Example

```nix
s: regex "(foo|bar)"
```

## `tree-sitter.regexWithFlags` {#function-library-tree-sitter.regexWithFlags}

Same as `regex`, except it accepts [regex flags](https://docs.rs/regex/1.1.8/regex/#grouping-and-flags)
to change the regex behavior.

### Type

```
regexWithFlags :: String -> String -> Rule
```

### Example

```nix
s: regexWithFlags "ix" ''
(
  # Matches foo
  foo
  |
  # Matches bar
  bar
)
''
```

## `tree-sitter.R` {#function-library-tree-sitter.R}

Alias to `regex`.

### Type

```
R :: String -> Rule
```

## `tree-sitter.grammar` {#function-library-tree-sitter.grammar}

Creates a grammar.

### Type

```
grammar :: Grammar -> Set
Grammar :: {
  name :: String
  rules :: AttrsOf (AttrsOf Symbol -> Rule)
  conflicts? :: AttrsOf Symbol -> ListOf Symbol
  inline? :: AttrsOf Symbol -> ListOf Symbol
  extras? :: AttrsOf Symbol -> ListOf Rule
  externals? :: ListOf String
  precedences? :: AttrsOf Symbol -> ListOf (ListOf String)
  word? :: AttrsOf Symbol -> Symbol
  supertypes? :: AttrsOs Symbol -> ListOf Symbol
  reserved? :: AttrsOf (AttrsOf Symbol -> Rule)
}
```

### Example

```nix
grammar {
  name = "foo";
  rules = {
    toplevel = s: "foo";
  };
}
```
