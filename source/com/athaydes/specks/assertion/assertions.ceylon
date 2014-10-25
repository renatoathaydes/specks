import com.athaydes.specks.matcher {
    Matcher
}

"The result of making an assertion."
shared abstract class AssertionResult() of assertionSuccess|AssertionFailure {}

"The result of a successfull assertion"
shared object assertionSuccess extends AssertionResult() {}

"The result of a failed assertion"
shared class AssertionFailure(shared String errorMessage)
        extends AssertionResult() { string = errorMessage; }

"Express an expectation that the actual value should match some condition
 according to the given matcher.
 
 For example, if you expect a value to be null:
 
 <code>
 expect(actual, toBe(equalTo(5)));
 expect(actual, to(exist));
 </code>"
shared AssertionResult expect<Element>(Element actual, Matcher<Element> matcher)
        => matcher.matches(actual);
