with (import ./.);
grammar {
  name = "a";
  inline = s: [
    s.a
  ];
  rules = [
    (rule "b" (s: s.a))
    (rule "a" (s: "a"))
  ];
}
