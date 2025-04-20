# nix2tree-sitter

Obscure way to generate grammar.json without needing JS(hit) using Nix

## Usage

See the [API docs](API.md).

## Comparison to JS DSL

<table border="0">
  <tr>
  <th>Syntax/Language</th>
  <th>Javascript</th>
  <th>Nix</th>
  </tr>

  <tr>
  <th>Rule definition</th>
  <td>

```js
{
  foo: $ => "foo",
  bar: $ => seq($.foo, "bar"),
}
```

  </td>
  <td>

```nix
[
  (rule "foo" (s: "foo"));
  (rule "bar" (s: seq [s.foo "bar"]));
]
```

  </td>
  </tr>

  <tr>
  <th>Externals</th>
  <td>

```js
{
  externals: $ => [
    $.string_start,
    $.string_content,
    $.string_end,
  ],
  rules: {
    string: $ => seq(
      field("start", $.string_start),
      field("content", $.string_content),
      field("end", $.string_end),
    ),
  },
}
```

  </td>
  <td>

```nix
{
  externals = [
    "string_start"
    "string_content"
    "string_end"
  ];
  rules = [
    (rule "string" (s: seq [
      (field "start" s.string_start)
      (field "content" s.string_content)
      (field "end" s.string_end)
    ]));
  ];
}
```

  </td>
  </tr>

  <tr>
  <th>Precedences</th>
  <td>

```js
$ => prec(1, "foo")
$ => prec.left("bar")
$ => prec.right("buzz")
```

  </td>
  <td>

```nix
s: prec 1 "foo"
```

```nix
s: prec.left 0 "bar"
```

```nix
s: prec.right 0 "buzz"
```

  </td>
  </tr>

  <tr>
  <th>Aliasing</th>
  <td>

```js
$ => alias("foo", $.bar)
$ => alias("foo", "bar")
```

  </td>
  <td>

```nix
s: alias "foo" (s "bar")
```
```nix
s: alias "foo" "bar"
```

  </td>
  </tr>

  <tr>
  <th>Regex</th>
  <td>

```js
$ => /(foo|bar)/
$ => /(foo|bar)/i
```

  </td>
  <td>

```nix
s: R"(foo|bar)"
```
```nix
s: regexWithFlags "i" "(foo|bar)"
```

  </td>
  </tr>
</table>
