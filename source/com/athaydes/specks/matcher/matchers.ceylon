import com.athaydes.specks.assertion {
    AssertionResult,
    assertionSuccess,
    AssertionFailure
}

"Base class of all **specks** matchers.
 
 A matcher can be used to verify that a value matches some expected result."
shared abstract class Matcher<Element>(
    "Expected value"
    shared Element? expected) {

    "Checks if the actual value matches an expected value."
    shared formal AssertionResult matches(Element actual);
    
}

"A utility matcher that may be combined with other matchers to make a combined matcher
 or just make expectations more readable, as in:
 
 <code>
     expect(actual, to(exist));
     expect([1,2,3], to(contain(3)));
 </code>"
shared Matcher<Element> to<Element>(Matcher<Element>+ wrappedMatchers)
        => AndMatcher(*wrappedMatchers);

"An alias for [[to]].
 
 Example usage:
 
 <code>
     expect(actual, toBe(equalTo(a), largerThan(b));
 </code>"
shared Matcher<Element> toBe<Element>(Matcher<Element>+ wrappedMatchers)
        => to(*wrappedMatchers);

"A utility matcher that reverses the result of another matcher, as in:
 
 <code>
     expect(actual, not(to(exist)));
     expect([1,2,3], not(to(contain(10))));
 </code>"
shared Matcher<Element> not<Element>(Matcher<Element> wrappedMatcher)
        => WrapperMatcher { wrappedMatcher; reverseResult = true; };

"A matcher that succeeds only if the actual value is larger than the expected value"
shared Matcher<Element> largerThan<Element>(Element expected)
        given Element satisfies Comparable<Element>
        => ComparisonMatcher(expected, larger);

"A matcher that succeeds only if the actual value is smaller than the expected value"
shared Matcher<Element> smallerThan<Element>(Element expected)
        given Element satisfies Comparable<Element>
        => ComparisonMatcher(expected, smaller);

"A matcher that succeeds only if the actual value exists, ie. the expected value is not null."
shared Matcher<Anything> exist = ExistenceMatcher { mustExist = true; };

"A matcher that succeeds only if the actual value is equal to the expected value,
 when compared with the [[Comparable.compare]] method."
see(`function identicalTo`)
shared Matcher<Element> equalTo<Element>(Element expected)
        given Element satisfies Comparable<Element>&Object
        => ComparisonMatcher(expected, equal);

"A matcher that succeeds only if the actual value **is** the expected value when compared
 by identity (see [[Identifiable]]).
 
 Example:
 
 <code>
     expect(1, toBe(identicalTo(1)));
 </code>"
see(`function equalTo`, `interface Identifiable`)
shared Matcher<Element> identicalTo<Element>(Element expected)
        given Element satisfies Identifiable
        => IdentityMatcher(expected);

"A matcher that succeeds only if the actual Iterable is empty."
shared Matcher<{Anything*}> empty()
        => EmptyMatcher<{Anything*}>();

"A matcher that succeeds only if the actual Iterable has the expected size."
shared Matcher<{Anything*}> haveSize(Integer expectedSize)
        => HasSizeMatcher<{Anything*}>(expectedSize);

"A matcher that succeeds only if the given element is part of a [[Category]].
 
 Example:
 
 <code>
     expect([1,2,3], to(contain(3)));
 </code>"
shared Matcher<Seq> contain<Seq, Element>(Element element)
        given Seq satisfies Category<Element>
        given Element satisfies Object
        => ContainsMatcher<Seq, Element>(element);

"A matcher that succeeds only if every one of the given elements are part of a [[Category]].
 
 Example:
 
 <code>
     expect('a'..'z', to(containEvery('x'..'z')));
 </code>"
see(`function Category.containsEvery`)
shared Matcher<Seq> containEvery<Seq, Element>({Element*} elements)
        given Seq satisfies Category<Element>
        given Element satisfies Object
        => ContainsEveryMatcher<Seq, Element>(elements);

"A matcher that succeeds only if at least one of the given elements are part of a [[Category]].
 
 Example:
 
 <code>
     expect('a'..'z', to(containAny('x'..'z')));
 </code>"
see(`function Category.containsAny`)
shared Matcher<Seq> containAny<Seq, Element>({Element*} elements)
        given Seq satisfies Category<Element>
        given Element satisfies Object
        => ContainsAnyMatcher<Seq, Element>(elements);

"A matcher that succeeds only if the actual collection contains exactly the same elements
 as the given Sequence.
 
 Examples:
 
 <code>
     // this succeeds
     expect('1'..'4', to(containSameAs([1, 2, 3, 4])));
 
     // this will fail
     expect('4'..'1', to(containSameAs([1, 2, 3, 4])));
 </code>"
shared Matcher<{Element*}> containSameAs<Element>({Element*} elements)
        given Element satisfies Object
        => ContainsSameElementsMatcher<Element>(elements);

"A matcher that succeeds only if the actual collection contains only elements
 also present in the given iterable.
 
 Examples:
 
 <code>
     expect(('1'..'100').map((i) => i % 2), to(containOnly(0, 1)));
 </code>"
shared Matcher<{Element*}> containOnly<Element>(Element* elements)
        given Element satisfies Object
        => ContainsOnlyMatcher<Element>(elements);

/**************** Matcher implementation classes ********************/

class AndMatcher<Element>(Matcher<Element>+ matchers)
        extends Matcher<Element>(null) {
    
    shared actual AssertionResult matches(Element actual) {
        for (matcher in matchers) {
            value result = matcher.matches(actual);
            if (! result === assertionSuccess) {
                return result;
            }
        }
        return assertionSuccess;
    }
    
}

class WrapperMatcher<Element>(Matcher<Element> wrappedMatcher, Boolean reverseResult)
        extends Matcher<Element>(wrappedMatcher.expected) {
    
    shared actual AssertionResult matches(Element actual) {
        value result = wrappedMatcher.matches(actual);
        if (reverseResult) {
            if (result == assertionSuccess) {
                return AssertionFailure("should have failed");
            } else {
                return assertionSuccess;
            }
        } else {
            return result;
        }
    }
    
}

class ExistenceMatcher(Boolean mustExist) extends Matcher<Anything>(null) {
    
    shared actual AssertionResult matches(Anything actual) {
        if (exists actual, !mustExist) {
            return AssertionFailure("expected to be null, but exists: ``actual``");
        } else if (is Null actual, mustExist) {
            return AssertionFailure("expected to exist but was null");
        }
        return assertionSuccess;
    }
    
}

class ComparisonMatcher<Element>(Element expected, Comparison expectedResult)
        extends Matcher<Element>(expected)
        given Element satisfies Comparable<Element> {
    
    shared actual AssertionResult matches(Element actual) {
        if (actual <=> expected != expectedResult) {
            return AssertionFailure("``actual`` is not ``strFor(expectedResult)`` ``expected``");
        }
        return assertionSuccess;
    }
    
}

class IdentityMatcher<Element>(Element expected)
        extends Matcher<Element>(expected)
        given Element satisfies Identifiable {
    
    shared actual AssertionResult matches(Element actual) {
        if (! actual === expected) {
            return AssertionFailure("expected ``expected`` but was ``actual``");
        }    
        return assertionSuccess;
    }
    
}

class BooleanMatcher(Boolean expected)
        extends Matcher<Boolean>(expected) {
    
    shared actual AssertionResult matches(Boolean actual) {
        if (actual != expected) {
            return AssertionFailure("expected ``expected`` but got ``actual``");
        }
        return assertionSuccess;
    }
    
}

class EmptyMatcher<Seq>()
        extends Matcher<Seq>(null)
        given Seq satisfies Iterable<Anything> {
    
    shared actual AssertionResult matches(Seq actuals) {
        if (actuals.empty) {
            return assertionSuccess;
        } else {
            return AssertionFailure("iterable is not empty");
        }
    }
    
}

class HasSizeMatcher<Seq>(Integer expectedSize)
        extends Matcher<Seq>(null)
        given Seq satisfies Iterable<Anything> {
    
    shared actual AssertionResult matches(Seq actuals) {
        value actualSize = actuals.size;
        if (actualSize == expectedSize) {
            return assertionSuccess;
        } else {
            return AssertionFailure("expected iterable of size ``expectedSize`` but was ``actualSize``");
        }
    }
    
}


class ContainsMatcher<Seq, Element>(Element expected)
        extends Matcher<Seq>(null)
        given Seq satisfies Category<Element>
        given Element satisfies Object {
    
    shared actual AssertionResult matches(Seq actuals) {
        if (! expected in actuals) {
            return AssertionFailure("element ``expected`` not in ``actuals``");
        }
        return assertionSuccess;
    }
    
}

class ContainsEveryMatcher<Seq, Element>({Element*} expected)
        extends Matcher<Seq>(null)
        given Seq satisfies Category<Element>
        given Element satisfies Object {
    
    shared actual AssertionResult matches(Seq actuals) {
        if (!actuals.containsEvery(expected)) {
            return AssertionFailure("not all ``actuals`` are part of ``expected``");
        }
        return assertionSuccess;
    }
    
}

class ContainsAnyMatcher<Seq, Element>({Element*} expected)
        extends Matcher<Seq>(null)
        given Seq satisfies Category<Element>
        given Element satisfies Object {
    
    shared actual AssertionResult matches(Seq actuals) {
        if (!actuals.containsAny(expected)) {
            return AssertionFailure("none of ``actuals`` is part of ``expected``");
        }
        return assertionSuccess;
    }
    
}

class ContainsSameElementsMatcher<Element>({Element*} expected)
        extends Matcher<{Element*}>(null)
        given Element satisfies Object {
    
    shared actual AssertionResult matches({Element*} actuals) {
        if (actuals.size != expected.size) {
            return AssertionFailure("expected List of size ``expected.size`` \
                                     but was ``actuals.size``");
        }
        variable Integer index = 0;
        for (actual -> expectedItem in zipEntries(actuals, expected)) {
            if (actual != expectedItem) {
                return AssertionFailure("element at index ``index`` should be \
                                         ``expectedItem`` but was ``actual``");
            }
            index++;
        }
        return assertionSuccess;
    }
    
}

class ContainsOnlyMatcher<Element>({Element*} expected)
        extends Matcher<{Element*}>(null)
        given Element satisfies Object {
    
    shared actual AssertionResult matches({Element*} actuals) {
        for (Element actual in actuals) {
            if (! actual in expected) {
                return AssertionFailure("unexpected item '``actual``'");    
            }
        }
        return assertionSuccess;
    }
    
}

String strFor(Comparison key) {
    switch (key)
    case (equal) { return "equal to"; }
    case (larger) { return "larger than"; }
    case (smaller) { return "smaller than"; }
}
