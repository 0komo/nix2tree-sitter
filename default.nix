let
  inherit (builtins)
    length
    typeOf
    tryEval
    trace
    foldl'
    listToAttrs
    match
    mapAttrs
    filter
    attrValues
    ;

  traceWarning = msg: v: trace "Warning: ${msg}" v;

  throwError = error: msg: throw "${error} -> ${msg}";
  typeError = throwError "TypeError";

  typeOfValue = value: if (typeOf value) != "set" || !value ? type then null else value.type;

  tryEvalOrError = v: (tryEval v).success || v;
  tryEvalListOrError =
    v: foldl' (x: y: if x == null || x != true && (tryEval y).success then true else x) null v;

  normalize =
    value:
    let
      valueType = typeOf value;
    in
    assert valueType == "set" || typeError "Invalid rule: a ${valueType}";
    if valueType == "null" then
      typeError "Null value"
    else if valueType == "string" then
      {
        type = "STRING";
        inherit value;
      }
    else if (typeOf value.type) == "string" then
      value
    else
      null;
in
rec {
  alias =
    rule: value:
    let
      rule' = normalize rule;
    in
    assert tryEval;
    let
      result = {
        type = "ALIAS";
        content = rule';
        named = false;
        value = null;
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
    else if (typeOfValue value) == "SYMBOL" then
      result
      // {
        named = true;
        value = value.name;
      }
    else
      null;

  blank = {
    type = "BLANK";
  };

  field =
    name: rule:
    let
      rule' = normalize rule;
    in
    assert tryEvalOrError rule';
    {
      type = "FIELD";
      inherit name;
      content = rule';
    };

  choice =
    choices:
    let
      choices' = map normalize choices;
    in
    assert tryEvalListOrError choices';
    {
      type = "CHOICE";
      members = choices';
    };

  optional =
    value:
    choice [
      value
      blank
    ];

  prec = {
    __functor =
      self: number: rule:
      let
        rule' = normalize rule;
      in
      assert tryEvalOrError rule';
      {
        type = "PREC";
        value = number;
        content = rule';
      };
  };

  prec.dynamic =
    number: rule:
    let
      rule' = normalize rule;
    in
    assert tryEvalOrError rule';
    {
      type = "PREC_DYNAMIC";
      value = number;
      content = rule';
    };

  prec.left =
    number: rule:
    let
      rule' = normalize rule;
    in
    assert tryEvalOrError rule';
    {
      type = "PREC_LEFT";
      value = number;
      content = rule';
    };

  prec.right =
    number: rule:
    let
      rule' = normalize rule;
    in
    assert tryEvalOrError rule';
    {
      type = "PREC_RIGHT";
      value = number;
      content = rule';
    };

  repeat =
    rule:
    let
      rule' = normalize rule;
    in
    assert tryEvalOrError rule';
    {
      type = "REPEAT";
      content = rule';
    };

  repeat1 =
    rule:
    let
      rule' = normalize rule;
    in
    assert tryEvalOrError rule';
    {
      type = "REPEAT1";
      content = rule';
    };

  seq =
    seqs:
    let
      seqs' = map normalize seqs;
    in
    assert tryEvalListOrError seqs';
    {
      type = "SEQ";
      members = map normalize seqs;
    };

  sym = name: {
    type = "SYMBOL";
    inherit name;
  };

  reserved =
    wordset: rule:
    let
      rule' = normalize rule;
    in
    assert
      (typeOf wordset) == "string"
      || throwError "Error" "Invalid reserved word set name: a ${typeOf wordset}";
    assert tryEvalOrError rule';
    {
      type = "RESERVED";
      content = rule';
      context_name = wordset;
    };

  token = {
    __functor =
      value:
      let
        value' = normalize value;
      in
      assert tryEvalOrError value';
      {
        type = "TOKEN";
        content = value';
      };
  };

  token.immediate =
    value:
    let
      value' = normalize value;
    in
    assert tryEvalOrError value';
    {
      type = "IMMEDIATE_TOKEN";
      content = value';
    };

  regex = pattern: {
    type = "PATTERN";
    value = pattern;
  };

  regexWithFlags =
    pattern: flags:
    (regex pattern)
    // {
      inherit flags;
    };

  R = regex;

  grammar =
    {
      name,
      rules,
      conflicts ? (_: [ ]),
      inline ? (_: [ ]),
      extras ? (_: [ (R "\\s") ]),
      externals ? [ ],
      precedences ? (_: [ ]),
      word ? null,
      supertypes ? (_: [ ]),
      reserved ? { },
    }:
    let
      externals' =
        if (typeOf externals) == "list" then
          map (symbol: sym symbol) externals
        else
          typeError "Invalid `externals' value: a ${typeOf externals}";

      ruleSet =
        (mapAttrs (name: value: sym name) rules)
        // (listToAttrs (
          map (s: {
            inherit (s) name;
            value = s;
          }) externals'
        ));

      name' =
        if (match "[a-zA-Z_][[:alnum:]]*" name) != null then
          name
        else
          throwError "Error" "`name' must start with any alphabet characters or an underscore and cannot contain a non-word characters";

      rules' = mapAttrs (
        name: lambda:
        if (typeOf lambda) != "lambda" then
          throwError "Error" "Grammar rules must all be lambdas. `${name}' rule is not"
        else
          let
            rule = lambda ruleSet;
          in
          if rule == null then throwError "Error" "`${name}' rule returned null" else normalize rule
      ) rules;

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
            if nthFoundSimiliarSym > 1 then traceWarning "duplicate inline rule `${s.name}'" false else true
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
    assert (length (attrValues rules)) != 0 || throwError "Error" "Grammar must at least have one rule";
    {
      grammar = {
        name = name';
        rules = rules';
        extras = extras';
        conflicts = conflicts';
        precedences = precedences';
        externals = externals';
        inline = inline';
        supertypes = supertypes';
        reserved = reserved';
      } // (if word' != null then { word = word'; } else { });
    };
}
