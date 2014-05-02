# specks

Specks enables a different way to check that your Ceylon code works.

Instead of writing traditional tests, you write specifications.

The main difference is the focus: specifications focus on behaviour, while unit tests focus on outcomes.

For example, here's a simple Specification written with ``specks``:

```ceylon
testExecutor(`class SpecksTestExecutor`)
test shared Specification ceylonOperatorIsSymmetric() =>
    Specification {
        ExpectAll {
            description = "The == operator should be symmetric";
            examples = { ["a", "a"], ["", ""] };
            (String s1, String s2) => s1 == s2,
            (String s1, String s2) => s2 == s1
        }
    };
```

## Running tests with specks

To run a Specification using Ceylon's testing framework, you just need to annotate your function/class/package/module with the ``testExecutor`` annotation so the test will be run using the ``SpecksTestExecutor``:

```ceylon
testExecutor(`class SpecksTestExecutor`)
shared package my.package;
```

> Notice that testExecutor support started with Ceylon 1.1.0, so you can't use this with 1.0


## All about Expectations

In ``specks``, there are different types of Expectations you can express:

### Expect

Simplest form:

```ceylon
Expect {
    "simple comparisons to work";
    () => 2 + 2 == 4,
    () => 2 < 4
}
```

Using ``Comparison``:

```ceylon
Expect {
    "simple comparisons to work";
    equal -> [2 + 2, 4],
    smaller -> [2, 4]
}
```

This form allows for better error messages as the values of the parameters are known.

For example, this Specification:

```ceylon
Expect {
    "bad comparisons to work!";
    equal -> [2 + 2, 8]
}
```

Would result in a failure with a nicer error message:

```
Expect 'bad comparisons to work!' Failed: 4 is not equal to 8
```

You can combine different kinds of expectations:

```ceylon
Expect {
    "simple comparisons to work";
    () => 2 + 2 == 4,
    equal -> [2 + 2, 4]
}
```

### ExpectAll

Allows the use of examples, as shown below:

```ceylon
ExpectAll {
    "examples should pass";
    { [1, 2], [5, 10], [25, 50] };
    (Integer a, Integer b) => 2 * a == b
}
```

If you wish, you can explicitly "tell" readers of the speck what the first line is (examples):

```ceylon
ExpectAll {
    "examples should pass";
    examples = { [1, 2], [5, 10], [25, 50] };
    (Integer a, Integer b) => 2 * a == b
}
```

Every function within the ``ExpectAll`` block will be run with all the examples provided, so running the above example would result in the function ``2 * a == b`` being run with ``a = 1, b = 2``, ``a = 5, b = 10``, and ``a = 25, b = 50``.

Notice that ``ExpectAll`` is type-safe, so the arguments of the expectation functions must match the types of the examples.

#### Examples generators

You can use generators to provide examples for your tests:

```ceylon
ExpectAll {
    "generated integers to be sorted";
    examples = { generateIntegers().sequence };
    (Integer* ints) => sort(ints).sequence == ints
}
```

### ExpectToThrow

Just as important as knowing your code works, is knowing that it fails when it should, in the way it should.

For that, you can use ``ExpectToThrow``:

```ceylon
ExpectToThrow {
    `Exception`;
    "when we call throw";
    void() { throw; }
}
```

### More examples

```ceylon
"Ceylon [*].first Speck"
shared test Specification firstSpeck() =>
    Specification {
        Expect {
            "Ceylon [*].first should return either the first element
             or null for empty Sequences";
            function() {
                String? first = [].first;
                return first is Null;
            },
            equal -> { [1].first, 1 },
            equal -> { [5, 4, 3, 2, 1, 0].first, 5 },
            equal -> { [1, 2, 3].first, 1 }
        },
        Expect {
            "Ceylon [*].first to work with String[]";
            equal -> { ["A"].first, "A" },
            equal -> { ["B", "C", "D"].first, "B" }
        }
    }
```

