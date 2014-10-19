# specks

Specks enables a different way to check that your Ceylon code works.

Instead of writing traditional tests, you write specifications.

The main difference is the focus: specifications focus on behaviour and outcomes, while unit tests focus on interactions and, most of the time, implementation details.

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

Notice that if the first expectation function (``s1 == s2``) failed, the next would run anyway, so you would know exactly which cases pass and which fail.

Contrast that with your normal unit test:

```ceylon
test void commonUnitTest() {
    value s1 = "a";
    value s2 = "a";
    value s3 = "";
    value s4 = "";
    assertEquals(s1, s2);
    assertEquals(s2, s1);
    assertEquals(s3, s4);
    assertEquals(s4, s3);
}
```

It's not very clear what is being tested.
If the first assertion fails, you have no way of knowing whether the next ones actually would pass or not, so you might enter a cycle where you
run a test, fix the error, then another error comes up and when you fix it the previous one comes back, and so on!

Now imagine the usual real-world scenario when you invariably have many examples you need to test, and on each example you might have many "assertions" to make, and you can see that this just doesn't scale.

With ``specks``, the number of examples you need to test doesn't make any difference on how you write your tests. Just declare the examples by hand as shown in the first example above, or create a **examples generator** function (or use one provided by ``specks``), and your expectation functions will be run against **all** of them, whether some fail or not.

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

Simplest form - expectations are expressed as functions which return a Boolean (`true` for pass, `false` for fail):

```ceylon
Expect {
    "simple comparisons to work";
    () => 2 + 2 == 4,
    () => 2 < 4
}
```

Preferred form: Using ``Comparison`` -> { values to compare }:

```ceylon
Expect {
    "simple comparisons to work";
    equal -> [2 + 2, 4],
    smaller -> [2, 4]
}
```

This form allows for better error messages as the values of the parameters are known.

At least 2 items must be provided in each entry's item, and the comparison of each item with the next is expected to yield `true`
for the test to succeed.

The following example passes:

```ceylon
Expect {
    "items to be in ascending order";
    smaller -> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
}
```

The following example fails:

```ceylon
Expect {
    "items to be in ascending order";
    smaller -> [1, 2, 4, 3, 5, 6, 7, 8, 9, 10]
}
```

The error message is very descriptive:

```
Expect 'items to be in ascending order' failed: 4 is not smaller than 3
```

You can combine different kinds of expectations:

```ceylon
Expect {
    "simple comparisons to work";
    () => 2 + 2 == 4,
    equal -> [2 + 2, 4],
    larger -> [ 3 + 3, 3 + 2, 3 + 1, 3 + 0]
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

The preferred form, however, is to use `Comparison`, as for `Expect`, so you get excellent error messages if the test fails:

```ceylon
ExpectAll {
    "examples should pass";
    examples = { [1, 2], [5, 10], [25, 50] };
    (Integer a, Integer b) => equal -> { 2 * a, b }
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
    (Integer* ints) => equal -> { sort(ints).sequence, ints }
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

### ExpectAllToThrow

Finally, we have the version of ``ExpectToThrow`` which accepts examples:

```ceylon
ExpectAllToThrow {
    `MyException`;
    "when not given at least one positive integer";
    { [-4, 0], [0, -1], [-2, -3], [0, 0] };
    myFunction, // a function declared elsewhere that takes 2 Integers as arguments
    void needsOnePositiveInteger(Integer i, Integer j) {
        if (i <= 0 || j <= 0) {
            throw MyException("Not given a positive integer");
        }
    }
}
```


### Example: testing Sequence.first

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

