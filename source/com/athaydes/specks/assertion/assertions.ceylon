import ceylon.language.meta {
    type
}
import ceylon.language.meta.model {
    Type
}

import com.athaydes.specks {
    success,
    Success,
    errorCheck
}
import com.athaydes.specks.matcher {
    identicalTo,
    toBe,
    Matcher
}

"The result of making an assertion."
shared alias AssertionResult => AssertionFailure | Success;

"The result of a failed assertion"
shared alias AssertionFailure => String;

"Express an expectation that the actual value should match some condition
 according to the given matcher.

 For example, if you expect a value to be 5 and to exist (ie. not to be null):

     expect(actual, toBe(equalTo(5)));
     expect(actual, to(exist));
 "
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

"Creates an assertion that is successful only if a `when` function throws a [[Throwable]]
 with the [[expectedType]].

 This assertion is commonly used with the [[errorCheck]] block."
see(`function errorCheck`)
shared AssertionResult expectToThrow(Type<Exception> expectedType)(Throwable? result) {

    AssertionResult verifyActualException(Throwable result) {
        if (type(result).exactly(expectedType)) {
            return success;
        } else {
            value resultType = platformIndependentName(result);
            value expectedTypeName = platformIndependentName(expectedType);
            return "expected ``expectedTypeName`` but threw ``resultType``";
        }
    }

    if (exists result) {
        return verifyActualException(result);
    } else {
        return "no Exception thrown";
    }
}


