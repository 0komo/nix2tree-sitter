with (import ./.);
grammar {
  name = "a";
  rules = [
    (rule "b" (s: s.a))
    (rule "a" (s: "a"))
  ];
}
