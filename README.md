# specks

**specks** enables a different way to check that your Ceylon code works.

Instead of writing traditional tests, you write specifications.

The main difference is the focus: specifications focus on behaviour and outcomes, while unit tests focus on interactions and, most of the time, implementation details.

For example, here's a simple Specification written with ``specks``:

```ceylon
testExecutor(`class SpecksTestExecutor`)
test shared Specification ceylonOperatorIsSymmetric() =>
    Specification {
        feature {
            description = "== operator should be symmetric";
            examples = { ["a", "a"], ["", ""] };
            when(String s1, String s2) => [s1, s2];
            (String s1, String s2) => expect(s1, equalTo(s2))(),
            (String s1, String s2) => expect(s2, equalTo(s1))()
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

## Writing specifications

Specifications are just collections of `Block`s. You can create Blocks with the functions `expectations`, `feature` and `errorCheck` (but you could also create your own blocks!).

### expectations

This is the simplest Block. It consists of a series of one or more `expect` statements as in the following example:

```ceylon
expectations {
    expect([].first, sameAs(null)),
    expect([1].first, equalTo(1)),
    expect([5, 4, 3, 2, 1, 0].first, equalTo(5)),
    expect(('x'..'z').first, equalTo('x')),
    expect(['a', 'b'].cycled.first, equalTo('a'))
}
```

As in the other blocks, a `description` field is optional:

```ceylon
expectations {
    description = "Iterable.first expectations";
    expect([].first, sameAs(null))
}
```

### feature

The `feature` Block can be used to specify more complex scenarios because it clearly separates a test's inputs, stimulus and expected results.

Its main attractive is that it supports *examples*, enabling data-driven specifications.

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
    examples = [[100.0, 20.0, 80.0], [33.0k, 31.5k, 1.5k]];
    (Float toDeposit, Float afterDeposit, Float afterWithdrawal, Float finalBalance)
        => expect(afterDeposit, equalTo(toDeposit)) (),
    (Float toDeposit, Float afterDeposit, Float afterWithdrawal, Float finalBalance)
        => expect(afterWithdrawal, equalTo(finalBalance)) ()
}
``` 


