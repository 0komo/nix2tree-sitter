with import ./.;
grammar {
  name = "a";
  rules = {
    top = s: optional s.down;
    down = s: R".+";
  };
}
