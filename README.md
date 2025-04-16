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
{
  foo = s: "foo";
  bar = s: seq [s.foo "bar"];
} 
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
  rules = {
    string = s: seq [
      (field "start" s.string_start)
      (field "content" s.string_content)
      (field "end" s.string_end)
    ];
  };
}
```
  
  </td>
  </tr>

  <tr>
  <td>Precedences</td>
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
</table>
