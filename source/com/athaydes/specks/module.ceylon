"# specks

 **specks** enables a different way to check that your Ceylon code works.

 Instead of writing traditional tests, you write specifications.

 The main difference is the focus: specifications focus on behaviour and outcomes, while unit tests focus on interactions and, most of the time, implementation details.

 For example, here's a very simple Specification written with `specks`:

     testExecutor (\`class SpecksTestExecutor\`)
     test
     shared Specification simpleSpec() => Specification {
         expectations {
             expect(max { 1, 2, 3 }, equalTo(3))
         }
     };

 > The `testExecutor` annotation can be added to a function, but also to a class or package...
  so you can avoid having to add it to every function.

  For more information, visit Specks' [GitHub page](https://github.com/renatoathaydes/specks)."
module com.athaydes.specks "0.7.1" {
	shared import ceylon.test "1.3.3.1";
	shared import ceylon.random "1.3.3";
	import ceylon.logging "1.3.3";
}
