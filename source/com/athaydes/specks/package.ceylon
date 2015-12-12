"# specks

 **specks** enables a different way to check that your Ceylon code works.

 Instead of writing traditional tests, you write specifications.

 The main difference is the focus: specifications focus on behaviour and outcomes, while unit tests focus on interactions and,
 most of the time, implementation details.

 For example, here's a very simple Specification written with specks:

     testExecutor (`class SpecksTestExecutor`)
     test
     shared Specification simpleSpec() => Specification {
         expectations {
             expect(max { 1, 2, 3 }, equalTo(3))
         }
     };

 > The `testExecutor` annotation can be added to a function, but also to a class or package...
   so you can avoid having to add it to every function.

 A more complete specification would include a description, some examples, and a clear separation between what's being tested and what is being
 asserted.

     test
     shared Specification aGoodSpec() => Specification {
         feature {
             description = \"The String.take() method returns at most n characters, for any given n >= 0\";
        
             when(String sample, Integer n) => [sample.take(n), n];
        
             // just a few examples for brevity
             examples = {
                 [\"\", 0],
                 [\"\", 1],
                 [\"abc\", 0],
                 [\"abc\", 1],
                 [\"abc\", 5],
                 [\"abc\", 1k]
             };
        
             ({Character*} result, Integer n) => expect(result.size, toBe(atMost(n)))
         }
     };

 > The `toBe(..)` function just returns the given matcher and is added only to improve readability

 Notice that the `when` function runs with every example. If any example fails, the next ones would run anyway,
 so you would know exactly which cases pass and which fail.

 A *property-based testing* approach can sometimes be a very good complement for manually-picked sample tests!
 For the previous example, this is certainly true.

 Luckily, `specks` has great support for *quickCheck*-style testing:

     test
     shared Specification propertyBasedSpec() => Specification {
         forAll((String sample, Integer n)
             => expect(sample.take(n).size, toBe(atMost(n < 0 then 0 else n))))
     };
 
 This test will run the given function with 100 different, randomly-chosen values.

"
shared package com.athaydes.specks;
