# specks

Specks enables a different way to check that your Ceylon code works.

Instead of writing traditional tests, you write specifications.

The main difference is the focus: specifications focus on behaviour, while unit tests focus on outcomes.

For example, here's a simple Specification written with ``specks``:

```ceylon
    Specification {
        "Ceylon == operator is transitive";
        ExpectAll {
            { ["a", "a"], ["", ""] };
            (String s1, String s2) => s1 == s2,
            (String s1, String s2) => s2 == s1
        }
    };
```

## All about Expectations

In ``specks``, there are different types of Expectations you can express:

### Expect

Simplest form:

```ceylon
Expect {
    () => 2 + 2 == 4,
    () => 2 < 4
}
```

Using ``Comparison``:

```ceylon
Expect {
    equal -> [2 + 2, 4],
    smaller -> [2, 4]
}
```

This form allows for better error messages as the values of the parameters are known.

For example, this Specification:

```ceylon
Expect {
    equal -> [2 + 2, 8]
}
```

Would result in a failure with nice error message: ``Failed: 4 is not equal to 8``.

You can combine different kinds of expectations:

```ceylon
Expect {
    () => 2 + 2 == 4,
    equal -> [2 + 2, 4]
}
```

### ExpectAll

Allows the use of examples, as shown below:

```ceylon
ExpectAll {
    { [1, 2], [5, 10], [25, 50] };
    (Integer a, Integer b) => 2 * a == b
}
```

Every function within the ``ExpectAll`` block will be run with all the examples provided, so running the above example would result in the function ``2 * a == b`` being run with ``a = 1, b = 2``, ``a = 5, b = 10``, and ``a = 25, b = 40``.

Notice that ``ExpectAll`` is type-safe, so the arguments of the expectation functions must match the types of the examples.

### ExpectToThrow

Just as important as knowing your code works, is knowing that it fails when it should, in the way it should.

For that, you can use ``ExpectToThrow``:

```ceylon
ExpectToThrow {
    `Exception`;
    void() { throw; }
}
```

### More examples

```ceylon
Specification {
    "Ceylon [*].first Speck";
    Expect {
        function() {
            String? first = [].first;
            return first is Null;
        },
        equal -> { [1].first, 1 },
        equal -> { [5, 4, 3, 2, 1, 0].first, 5 },
        equal -> { [1, 2, 3].first, 1 }
    },
    Expect {
        equal -> { ["A"].first, "A" },
        equal -> { ["B", "C", "D"].first, "B" }
    }
}
```

