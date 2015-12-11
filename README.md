# specks

**specks** enables a different way to check that your Ceylon code works.

Instead of writing traditional tests, you write specifications.

The main difference is the focus: specifications focus on behaviour and outcomes, while unit tests focus on interactions and, most of the time, implementation details.

For example, here's a very simple Specification written with ``specks``:

```ceylon
testExecutor (`class SpecksTestExecutor`)
test
shared Specification simpleSpec() => Specification {
    expectations {
        expect(max { 1, 2, 3 }, equalTo(3))
    }
};
```

> The `testExecutor` annotation can be added to a function, but also to a class or package...
  so you can avoid having to add it to every function.

A more complete specification would include a description, some examples, and a clear separation between what's being tested and what is being
asserted.

```ceylon
test
shared Specification aGoodSpec() => Specification {
    feature {
        description = "The String.take() method returns at most n characters, for any given n > 0";
        
        when(String sample, Integer n) => [sample.take(n), n];
        
        // just a few examples for brevity
        examples = {
            ["", 0],
            ["", 1],
            ["abc", 0],
            ["abc", 1],
            ["abc", 5],
            ["abc", 1k]
        };
        
        ({Character*} result, Integer n) => expect(result.size, toBe(atMost(n)))
    }
};
```

> The `toBe(..)` function just returns the given matcher and is added only to improve readability

Notice that the `when` function runs with every example. If any example fails, the next ones would run anyway,
so you would know exactly which cases pass and which fail.

A *property-based testing* approach can sometimes be a very good complement for manually-picked sample tests!
For the previous example, this is certainly true.

Luckily, `specks` has great support for *quickCheck*-style testing:

```ceylon
test
shared Specification propertyBasedSpec() => Specification {
    forAll((String sample, Integer n)
        => expect(sample.take(n).size, toBe(atMost(n < 0 then 0 else n))))
};
```

This test will run the given function with 100 different, randomly-chosen values.

> For more information about property-based testing, see the sections below for the `forAll` and `propertyCheck` functions.

## Running tests with specks

First of all, import Specks in your module.ceylon file:

```ceylon
import com.athaydes.specks "0.2.0"
```

To run a Specification using Ceylon's testing framework, you just need to annotate your function/class/package/module with the ``testExecutor`` annotation so the test will be run using the ``SpecksTestExecutor``:

```ceylon
testExecutor(`class SpecksTestExecutor`)
shared package my.package;
```

> Notice that testExecutor support started with Ceylon 1.1.0, so you can't use this with 1.0

## Writing specifications

Specifications are just collections of `Block`s. You can create Blocks with the
following built-in functions: `expectations`, `feature`, `errorCheck`,
`forAll` and `propertyCheck` (but you may also create your own blocks!).

### expectations

This is the simplest Block. It consists of a series of one or more `expect`
 or `expectCondition` statements as in the following example:

```ceylon
expectations {
    expect([].first, sameAs(null)),
    expectCondition(2 > 1),
    expect([1].first, equalTo(1)),
    expect([5, 4, 3, 2, 1, 0].first, equalTo(5)),
    expect(('x'..'z').first, equalTo('x')),
    expect(['a', 'b'].cycled.first, equalTo('a'))
}
```

> To make the expressions above read even more like English, you can use the *cosmetic*
  functions `to` and `toBe`, as in `expect(a, toBe(equalTo(b)));` or
  `expect(a, to(contain(b)));`.

As in the other blocks, a `description` field is optional:

```ceylon
expectations {
    description = "Iterable.first expectations";
    expect([].first, toBe(sameAs(null)))
}
```

### feature

The `feature` Block can be used to specify more complex scenarios because it clearly separates a test's inputs, stimulus and expected results.

Its main attraction is that it supports *examples*, enabling example-based testing.

Example of a full feature:

```ceylon
feature {
    description = "BankAccounts support deposits and withdrawals";

    function when(Float toDeposit, Float toWithdraw, Float finalBalance) {
        value account = BankAccount();
        account.deposit(toDeposit);
        value afterDepositBalance = account.balance;
        account.withdraw(toWithdraw);
        return [toDeposit, afterDepositBalance, account.balance, finalBalance];
    }
    
    examples = {
        [100.0, 20.0, 80.0],
        [33.0k, 31.5k, 1.5k]
    };
    
    (Float toDeposit, Float afterDeposit, Float afterWithdrawal, Float finalBalance)
        => expect(afterDeposit, equalTo(toDeposit)),
    (Float toDeposit, Float afterDeposit, Float afterWithdrawal, Float finalBalance)
        => expect(afterWithdrawal, equalTo(finalBalance))
}
```

The test *stimulus* is implemented by the `when` function, which takes each item given in
the examples as its parameters, and returns a `Tuple` which is used as the parameters
of the assertion function(s).

All examples are run regardless of whether a previous example has failed, so that after a
test is run, you know exactly which examples are ok and which are not.

> All example-based Blocks have a `maxFailuresAllowed` parameter which can be used to
  limit how many failures should be allowed before `specks` stops trying further examples.

#### Example generators

Additionally, you may use generator functions to create input for the test.

`specks` currently supports the following generator functions:

* `{Integer+} rangeOfIntegers(
				Integer count = 100,
				Integer lowerBound = -1M,
				Integer higherBound = 1M)`: generates a deterministic stream of
				Integers that includes the lower and higher bounds, with the other
				items approximately evenly distributed in between.

* `{Integer+} randomIntegers(
                Integer count = 100,
                Integer lowerBound = -1M,
                Integer higherBound = 1M,
                Random random = defaultRandom)`: generates a random stream of Integers between lower and higher bounds.

* `{String+} randomStrings(
				Integer count = 100,
				Integer shortest = 0,
				Integer longest = 100,
				[Character+] allowedChars = '\{#20}'..'\{#7E}',
				Random random = defaultRandom)`: generates a random stream of Strings according to the parameters given.

> the excellent [ceylon-random](https://github.com/jvasileff/ceylon-random),
  library, by @jvasileff, is used to generate random Strings. The default Random instance
  just delegates to the platform-specific pseudo-random generator.

### errorCheck

As important as to know that your code works when it should, is to know it fails in the
way you expect. For that, you can use `errorCheck` Blocks.

Here's one of the simplest possible `errorCheck` blocks you may write:

```ceylon
errorCheck {
    description = "Dividing 1 by 0 results in an Exception";
    function when() => 1 / 0;
    expectToThrow(`Exception`)
}
```

## Property-based testing

There are two `Block` functions which facilitate property-based testing in `specks`
(similar to Haskell's [Quickcheck](https://wiki.haskell.org/Introduction_to_QuickCheck1)).

### forAll

The `forAll` Block is the simplest way to write property-based specifications.

It can be used in a very simple manner:

```ceylon
forAll((String sample) => expect(sample.reversed.reversed, equalTo(sample)))
```

Or you can be more verbose when necessary:

```ceylon
forAll {
    description = "The reverse of a reversed String is the String itself";
    sampleCount = 1k;
    maxFailuresAllowed = 50;
    generators = [ randomStrings ];
    assertion(String sample) => expect(sample.reversed.reversed, equalTo(sample));
}
```

### propertyCheck

The `propertyCheck` Block allows writing more advanced property-based tests. Similar to `feature`,
the separation between test stimulus and assertions is enforced:

```ceylon
propertyCheck {
    description = "The addition operation is commutative";
    sampleCount = 10k;
    when(Integer a, Integer b, Integer c) => [(a + b) + c, a + (b + c)];
    (Integer left, Integer right) => expect(left, equalTo(right))
}
```

As in the `feature` block, the `when` function must return a tuple of values which will be passed as
arguments to the assertion function(s).

## Asserting behavior

As you can see in the examples above, all blocks have some kind of assertion(s).

This is natural, as the main purpose of any test is to assert that a system behaves
in a certain way.

To make assertions with `specks`, you have two options.

The first option is to use instances of `Matcher<Element>` together with the `expect` helper function, which we have already met above.

```ceylon
expect(('x'..'z').first, equalTo('x'));
```

It is also possible to assert simple boolean conditions with the
`expectCondition` function:

* in `expectations` blocks:

```ceylon
expectations {
    expectCondition(2 > 1),
    expectCondition(false) // will fail
}
```

* in `feature` blocks:

```ceylon
feature {
    when() => []; // the when function is mandatory
    () => expectCondition(false) // will fail
}
```

However, this is not the preferred way of making assertions because in case of failure,
the error message will be quite unhelpful:

```
Feature failed: expected true but was false
```

When you use `Matcher`s, both the expected and actual values are known, so you can get
very good error messages.

For example:

```ceylon
feature {
    description = "[item, ...].first returns item";
    when(Integer a, Integer b, Comparison expectedResult)
            => [a <=> b, expectedResult];
    examples = [[1, 2, smaller], [2, 3, larger]];
    (Comparison actual, Comparison expectedResult)
            => expect(actual, toBe(sameAs(expectedResult)))
}
```

```
Feature '[item, ...].first returns item' failed:
smaller is not as expected: larger [2, 3, larger]
```

The example(s) which failed is shown at the end of the message.

You can create `Matcher`s with the following built-in functions
(or just create your own, of course):

### Value Matchers

#### equalTo

Asserts that a `Comparable` value is equal to some expected value, as assessed by calling
the `compare` method (or, equivalently, using the `<=>` operator).

```ceylon
expect(2 + 2, equalTo(4));
```

#### sameAs

Asserts that a value of any type (including `Null`) is the same as another by using the `equals` method (ie. the `==` operator), or ensuring that both values are `null`.

```ceylon
expect([1, 2, 3], sameAs([1, 2, 3]));
expect([].first, sameAs(null));
```

#### identicalTo

Asserts that a value of type `Identifiable` (which includes all sub-types of `Basic`)
is **identical** to another by using the `===` operator.

```ceylon
expect(reference1, identicalTo(reference2));
```

#### largerThan

Asserts that a `Comparable` value is larger than some expected value, as assessed
by calling the `compare` method (or, equivalently, using the `<=>` operator).

```ceylon
expect(2 + 2, largerThan(3));
```

> `largerThan` is clearly nicer to read when used with `toBe`:
  `expect(2 + 2, toBe(largerThan(3)));`

#### smallerThan

Asserts that a `Comparable` value is smaller than some expected value,
as assessed by calling the `compare` method (or, equivalently, using the `<=>` operator).

```ceylon
expect(2 + 2, smallerThan(5));
```

#### atLeast

Asserts that a `Comparable` value is at least some expected value,
as assessed by calling the `compare` method (or, equivalently, using the `<=>` operator).

```ceylon
expect(2 + 2, atLeast(4));
```

#### atMost

Asserts that a `Comparable` value is at most some expected value,
as assessed by calling the `compare` method (or, equivalently, using the `<=>` operator).

```ceylon
expect(2 + 2, atMost(4));
```

#### exist

Asserts that a value exists (ie. it is not `null`). *Used with `to` just to read better*.

```ceylon
expect(functionMayReturnNull(), to(exist));
```

### Matcher modifiers

#### to

Re-applies another `Matcher`. Used to improve readability.

```ceylon
expect([1, 2, 3], to(contain(2)));
```

#### toBe

Re-applies another `Matcher`. Used to improve readability.

```ceylon
expect(1 + 1, toBe(equalTo(2)));
```

#### not

Negates another `Matcher`.

```ceylon
expect(true, not(equalTo(false)));
```

### Matchers for Iterable values

#### empty

Asserts that an Iterable is empty.

```ceylon
expect({1, 2, 3}, empty); // should fail
```

#### haveSize

Asserts that an Iterable has a certain size.

```ceylon
expect({1, 2, 3}, to(haveSize(3)));
```

#### contain

Asserts that an Iterable contains a certain element.

```ceylon
expect({1, 2, 3}, to(contain(2)));
```

#### containEvery

Asserts that an Iterable contains every element of another Iterable.

```ceylon
expect('a'..'z', to(containEvery('x'..'z')));
```

#### containAny

Asserts that an Iterable contains any of the elements of another Iterable.

```ceylon
expect('a'..'z', to(containAny('x'..'z')));
```

#### containSameAs

Asserts that an Iterable contains the same elements, in the same other,
as another Iterable.

```ceylon
expect('a'..'z', to(containSameAs('x'..'z')));
```

#### containOnly

Asserts that an Iterable only contains the elements of another Iterable,
in any quantity.

```ceylon
expect(('1'..'100').map((i) => i % 2), to(containOnly(0, 1)));
```
