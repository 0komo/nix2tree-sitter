# Based on DerekStride/tree-sitter-math

with (import ../.);
let
  PREC = builtins.mapAttrs (name: value: prec.left value) {
    addition = 1;
    multiplication = 2;
    exponent = 3;
  };
  FIELD = {
    left = field "left";
    right = field "right";
  };
in
grammar {
  name = "math";
  rules = [
    (rule "expression" (s: s._expression))

    (rule "_expression" (
      s:
      choice [
        s.variable
        s.number
        s.sum
        s.subtraction
        s.product
        s.division
        s.exponent
        s._parenthesized_expression
      ]
    ))

    (rule "sum" (
      s:
      PREC.addition (seq [
        (FIELD.left s._expression)
        "+"
        (FIELD.right s._expression)
      ])
    ))

    (rule "subtraction" (
      s:
      PREC.addition (seq [
        (FIELD.left s._expression)
        "-"
        (FIELD.right s._expression)
      ])
    ))

    (rule "product" (
      s:
      PREC.multiplication (seq [
        (FIELD.left s._expression)
        "*"
        (FIELD.right s._expression)
      ])
    ))

    (rule "division" (
      s:
      PREC.multiplication (seq [
        (FIELD.left s._expression)
        "/"
        (FIELD.right s._expression)
      ])
    ))

    (rule "exponent" (
      s:
      PREC.exponent (seq [
        (field "base" s._expression)
        "**"
        (field "exponent" s._expression)
      ])
    ))

    (rule "_parenthesized_expression" (
      s:
      seq [
        "("
        s._expression
        ")"
      ]
    ))

    (rule "number" (s: R ''\d+(\.\d+)?''))
    (rule "variable" (s: R ''([a-zA-Z$][0-9a-zA-Z_]*)''))
  ];
}
