let
  inherit (builtins)
    length
    typeOf
    warn
    foldl'
    listToAttrs
    match
    mapAttrs
    filter
    attrValues
    toJSON
    replaceStrings
    tail
    head
    ;

  throwError = error: msg: throw "${error} -> ${msg}";
  typeError = throwError "TypeError";

  typeOfValue = value: if (typeOf value) != "set" || !value ? type then null else value.type;

  normalize =
    value:
    let
      valueType = typeOf value;
    in
    assert valueType != "null" || typeError "Null value";
    assert valueType == "set" || valueType == "string" || typeError "Invalid rule: a ${valueType}";
    if valueType == "string" then
      {
        type = "STRING";
        inherit value;
      }
    else if typeOf value.type == "string" then
      value
    else
      null;

  concatStringsWithSep = a: b: foldl' (x: y: x + a + y) (head b) (tail b);
in
rec {
  _internal = {
    version = "0.0.1";
    inherit
      normalize
      ;
  };

  /**
    Alternates a name of rule in the syntax tree.
    If the name is specified with a symbol (as in `alias s.foo (s "bar")`),
    then the aliased rule appeared as a named node.
    And if the name is specified with a literal string, then
    the aliased rule appeared as a anonymous node.

    # Type

    ```
    alias :: Rule -> String or Symbol -> Rule
    ```

    # Example

    ```nix
    s: alias s.foo (s "bar")
    s: alias s.foo "bar"
    ```
  */
  alias =
    rule: value:
    let
      result = {
        type = "ALIAS";
        content = normalize rule;
        named = false;
      };
      valueType = typeOf value;
    in
    assert
      valueType == "string"
      || valueType == "set"
      || throwError "Error" "Invalid alias value: a ${valueType}";
    if valueType == "string" then
      result
      // {
        value = value;
      }
    else if typeOfValue value == "SYMBOL" then
      result
      // {
        named = true;
        value = value.name;
      }
    else
      null; # TODO: unreachable, might need some refactor

  /**
    A blank/empty rule.

    # Type

    ```
    blank :: Rule
    ```

    # Example

    ```nix
    s: choice ["foo" blank]
    # Or, alternatively
    s: optional "foo"
    ```
  */
  blank = {
    type = "BLANK";
  };

  /**
    Assigns a field to a children of a rule.

    # Type

    ```
    field :: String -> Rule -> Rule
    ```

    # Example

    ```nix
    s: seq [
      (field "foo" (alias "foo" (s "foo"))
      (field "bar" (optional (alias "bar" (s "bar"))))
    ]
    ```
  */
  field = name: rule: {
    type = "FIELD";
    inherit name;
    content = normalize rule;
  };

  /**
    Creates a rule that matches one of a set possibilites.

    # Type

    ```
    choice :: ListOf Rule -> Rule
    ```

    # Example

    ```nix
    s: choice [
      "foo"
      "bar"
    ]
    ```
  */
  choice = choices: {
    type = "CHOICE";
    members = map normalize choices;
  };

  /**
    Creates a rule that matches zero or one occurance of a given rule.

    # Type

    ```
    optional :: Rule -> Rule
    ```

    # Example

    ```nix
    s: optional "foo"
    ```
  */
  optional =
    value:
    choice [
      value
      blank
    ];

  /**
    Marks a rule with a numerical precedence.

    # Type

    ```
    prec :: Number -> Rule -> Rule
    ```

    # Example

    ```nix
    s: prec 10 "foo"
    ```
  */
  prec = {
    __functor = self: number: rule: {
      type = "PREC";
      value = number;
      content = normalize rule;
    };
  };

  /**
    Marks a rule with a numerical precedence that's applied at runtime.

    # Type

    ```
    prec.dynamic :: Number -> Rule -> Rule
    ```

    # Example

    ```nix
    s: prec.dynamic 10 "foo"
    ```
  */
  prec.dynamic = number: rule: {
    type = "PREC_DYNAMIC";
    value = number;
    content = normalize rule;
  };

  /**
    Marks a rule with a numerical precedence and left-associative.

    # Type

    ```
    prec.left :: Number -> Rule -> Rule
    ```

    # Example

    ```nix
    s: prec.left 0 "foo" # Default in the JS DSL
    s: prec.left 10 "bar"
    ```
  */
  prec.left = number: rule: {
    type = "PREC_LEFT";
    value = number;
    content = normalize rule;
  };

  /**
    Marks a rule with a numerical precedence and right-associative.

    # Type

    ```
    prec.right :: Number -> Rule -> Rule
    ```

    # Example

    ```nix
    s: prec.right 0 "foo" # Default in the JS DSL
    s: prec.right 10 "bar"
    ```
  */
  prec.right = number: rule: {
    type = "PREC_RIGHT";
    value = number;
    content = normalize rule;
  };

  /**
    Creates a rule that matches zero-or-more occurences of a given rule.

    # Type

    ```
    repeat :: Rule -> Rule
    ```

    # Example

    ```nix
    s: repeat "foo"
    ```
  */
  repeat = rule: {
    type = "REPEAT";
    content = normalize rule;
  };

  /**
    Creates a rule that matches one-or-more occurences of a given rule.

    # Type

    ```
    repeat1 :: Rule -> Rule
    ```

    # Example

    ```nix
    s: repeat1 "foo"
    ```
  */
  repeat1 = rule: {
    type = "REPEAT1";
    content = normalize rule;
  };

  /**
    Creates a rule that matches any number of other rules, one after another.

    # Type

    ```
    seq :: ListOf Rule -> Rule
    ```

    # Example

    ```nix
    s: seq [
      "foo"
      " "
      "bar"
    ]
    ```
  */
  seq = seqs: {
    type = "SEQ";
    members = map normalize seqs;
  };

  /**
    Creates a rule that references to a node from the syntax tree.

    # Type

    ```
    sym :: String -> Symbol
    ```

    # Example

    ```nix
    s: sym "foo"
    ```
  */
  sym = name: {
    type = "SYMBOL";
    inherit name;
  };

  /**
    Overrides the global reserved word set with the given wordset.

    # Type

    ```
    reserved :: String -> Rule -> Rule
    ```
  */
  reserved =
    wordset: rule:
    assert
      (typeOf wordset) == "string"
      || throwError "Error" "Invalid reserved word set name: a ${typeOf wordset}";
    {
      type = "RESERVED";
      content = rule;
      context_name = wordset;
    };

  /**
    Marks a given rule as producing only a single token.

    # Type

    ```
    token :: Rule -> Rule
    ```

    # Example

    ```nix
    s: token (choice [
      "foo"
      "bar"
    ])
    ```
  */
  token = {
    __functor = self: value: {
      type = "TOKEN";
      content = value;
    };
  };

  /**
    Same as `token`, except it doesn't recognize rules in `extras` as valid syntax if there's any.

    # Type

    ```
    token.immediate :: Rule -> Rule
    ```
  */
  token.immediate = value: {
    type = "IMMEDIATE_TOKEN";
    content = normalize value;
  };

  /**
    Creates a rule that matches a [Rust regex](https://docs.rs/regex/1.1.8/regex/#syntax) pattern.

    # Type

    ```
    regex :: String -> Rule
    ```

    # Example

    ```nix
    s: regex "(foo|bar)"
    ```
  */
  regex = pattern: {
    type = "PATTERN";
    value = pattern;
  };

  /**
    Same as `regex`, except it accepts [regex flags](https://docs.rs/regex/1.1.8/regex/#grouping-and-flags)
    to change the regex behavior.

    # Type

    ```
    regexWithFlags :: String -> String -> Rule
    ```

    # Example

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
  */
  regexWithFlags =
    flags: pattern:
    (regex pattern)
    // {
      inherit flags;
    };

  /**
    Alias to `regex`.

    # Type

    ```
    R :: String -> Rule
    ```
  */
  R = regex;

  /**
    Creates a rule with a name.

    # Type

    ```
    rule :: String -> (AttrsOf Symbol -> Rule) -> NamedRule
    ```
  */
  rule = name: r: {
    inherit name;
    rule = r;
  };

  /**
    Creates a grammar.

    # Type

    ```
    grammar :: Grammar -> Set
    Grammar :: {
      name :: String;
      rules :: ListOf NamedRule;
      conflicts? :: AttrsOf Symbol -> ListOf Symbol;
      inline? :: AttrsOf Symbol -> ListOf Symbol;
      extras? :: AttrsOf Symbol -> ListOf Rule;
      externals? :: ListOf String;
      precedences? :: AttrsOf Symbol -> ListOf (ListOf String);
      word? :: AttrsOf Symbol -> Symbol;
      supertypes? :: AttrsOs Symbol -> ListOf Symbol;
      reserved? :: AttrsOf (AttrsOf Symbol -> Rule);
    }
    ```

    # Example

    ```nix
    grammar {
      name = "foo";
      rules = {
        toplevel = s: "foo";
      };
    }
    ```
  */
  grammar =
    {
      name,
      rules,
      conflicts ? (s: [ ]),
      inline ? (s: [ ]),
      extras ? (s: [ (R "\\s") ]),
      externals ? [ ],
      precedences ? (s: [ ]),
      word ? null,
      supertypes ? (s: [ ]),
      reserved ? { },
    }:
    let
      externals' =
        if (typeOf externals) == "list" then
          map (symbol: sym symbol) externals
        else
          typeError "Invalid `externals' value: a ${typeOf externals}";

      ruleSet =
        (listToAttrs (
          map (s: {
            inherit (s) name;
            value = sym s.name;
          }) rules
        ))
        // (listToAttrs (
          map (s: {
            inherit (s) name;
            value = s;
          }) externals'
        ))
        // {
          __functor = self: name: sym name;
        };

      name' =
        if (match "[a-zA-Z_][[:alnum:]]*" name) != null then
          name
        else
          throwError "Error" "`name' must start with any alphabet characters or an underscore and cannot contain a non-word characters";

      rules' =
        "{"
        + (
          concatStringsWithSep "," (
            map (
              x:
              assert
                typeOf x.rule == "lambda"
                || throwError "Error" "All rules must all be lambdas. `${x.name}' does not";
              "\"${x.name}\":${toJSON (normalize (x.rule ruleSet))}"
            ) rules
          )
          + "}"
        );
      reserved' = mapAttrs (
        name: lambda:
        if (typeOf lambda) != "lambda" then
          throwError "Error" "Grammar reserved word sets must all be lambdas. `${name}' is not"
        else
          let
            list = lambda ruleSet;
          in
          if (typeOf list) != "list" then
            throwError "Error" "Grammar reserved word set lambdas must return list of rules. `${name}' does not"
          else
            map normalize list
      ) reserved;

      extras' = map normalize (extras ruleSet);

      word' = if word != null then word ruleSet else null;

      conflicts' =
        let
          rules = conflicts ruleSet;
        in
        map (set: map (s: (normalize s).name) set) rules;

      inline' =
        let
          rules = inline ruleSet;
        in
        map (s: s.name) (
          filter (
            s:
            let
              nthFoundSimiliarSym = foldl' (x: y: if s.name == y.name then x + 1 else x) 0 (attrValues rules);
            in
            if nthFoundSimiliarSym > 1 then warn "duplicate inline rule `${s.name}'" false else true
          ) rules
        );

      supertypes' =
        let
          rules = supertypes ruleSet;
        in
        map (s: s.name) rules;

      precedences' =
        let
          rules = precedences ruleSet;
        in
        map (l: map normalize l) rules;
    in
    assert (length rules) != 0 || throwError "Error" "Grammar must at least have one rule";
    replaceStrings [ "\"<rules>\"" ] [ rules' ] (
      toJSON ({
        name = name';
        rules = "<rules>";
        extras = extras';
        conflicts = conflicts';
        precedences = precedences';
        externals = externals';
        inline = inline';
        supertypes = supertypes';
        reserved = reserved';
      }
      // (if word' != null then { word = word'; } else { }))
    );
}
