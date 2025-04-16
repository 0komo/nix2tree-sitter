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
  <th>

```js
{
  foo: $ => "foo",
  bar: $ => seq($.foo, "bar"),
}
```

  </th>
  <th>

```nix
{
  foo = s: "foo";
  bar = s: seq [s.foo "bar"];
} 
```

  </th>
  </tr>

  <tr>
  <th>Externals</th>
  <th>

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

  </th>
  <th>

```nix
{
  externals = [
    "string_start"
    "string_content"
    "string_end"
  ];
  rules = {
    string = s: seq [
      (field "start" s.string_start)
      (field "content" s.string_content)
      (field "end" s.string_end)
    ];
  };
}
```
  
  </th>
  </tr>

  <tr>
  <th>Precedences</th>
  <th>

```js
$ => prec(1, "foo")
$ => prec.left("bar")
$ => prec.right("buzz")
```

  </th>
  <th>

```nix
s: prec 1 "foo"
```
```nix
s: prec.left 0 "bar"
```
```nix
s: prec.right 0 "buzz"
```

  </th>
</table>
