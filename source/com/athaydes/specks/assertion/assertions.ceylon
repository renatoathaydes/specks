import ceylon.language.meta {
    type
}
import ceylon.language.meta.model {
    Type
}

import com.athaydes.specks.matcher {
    Matcher,
    identicalTo,
    toBe
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

"Expect that a condition evaluates to true.
 
 This is a shortcut for:
 
 <code>
     expect(expectedToBeTrue, toBe(identicalTo(true)));
 </code>"
shared AssertionResult expectCondition(Boolean expectedToBeTrue)
        => expect(expectedToBeTrue, toBe(identicalTo(true)));

"Platform independent name of an Exception"
shared String platformIndependentName(Type<Exception>|Throwable exception) =>
        exception.string.replace("::", ".");

shared AssertionResult expectToThrow(Type<Exception> expectedException)(Throwable? result) {

    AssertionResult verifyActualException(Throwable result) {
        if (type(result).exactly(expectedException)) {
            return assertionSuccess;
        } else {
            value resultType = platformIndependentName(result);
            value expectedType = platformIndependentName(expectedException);
            return AssertionFailure("expected ``expectedType`` but threw ``resultType``");
        }
    }

    if (exists result) {
        return verifyActualException(result);
    } else {
        return AssertionFailure("no Exception thrown");
    }
}


