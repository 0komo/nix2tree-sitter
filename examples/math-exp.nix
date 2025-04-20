with (import ../.);
grammar {
  name = "math";
  rules = {
    number = s: R"\\d+(\\.\\d+)?";
    b = s: "";
  };
}
