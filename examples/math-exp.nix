with (import ../.);
grammar {
  name = "math";
  rules = [
    (rule "number" (s: R"\\d+(\\.\\d+)?"))
  ];
}
