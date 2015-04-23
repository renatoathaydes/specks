import com.athaydes.specks.assertion {
    expect,
    expectCondition,
    AssertionResult,
    expectToThrow
}
import com.athaydes.specks.matcher {
    equalTo,
    Matcher,
    containEvery,
    to
}



"Run the module `com.athaydes.specks`."
shared void run() {
    
    void myFunction(Integer i, Integer j) {
        if (i <= 0 || j <= 0) {
            throw Exception();
        }
    }
    
    "Example custom matcher"
    function sorted<Item>(Boolean ascending) 
            given Item satisfies Comparable<Item>
            => object satisfies Matcher<{Item*}> {
        
        value compare = ascending
                then ((Item i, Item prev) => i <= prev)
                else ((Item i, Item prev) => i > prev);
        
        shared actual AssertionResult matches({Item*} actual) {
            if (is {Item+} actual, actual.size > 1) {
                variable value prev = actual.first;
                for (pair in zipPairs(1..actual.size, actual.rest)) {
                    value [index, item] = pair;
                    if (compare(item, prev)) {
                        return "Not sorted at index ``index``: [``item``]";
                    }
                    prev = item;
                }
            }
            return success;
        }
    };
    
    [Specification {
        feature {
            description = "== operator should be symmetric";
            examples = { ["a", "a"], ["", ""] };
            when(String s1, String s2) => [s1, s2];
            (String s1, String s2) => expect(s1, equalTo(s2))(),
            (String s1, String s2) => expect(s2, equalTo(s1))()
        }
    },
    Specification {
        feature {
            description = "Ceylon operators to work";
            when() => [];
            () => expectCondition(2 + 2 == 4),
            () => expectCondition(2 < 4)
        },
        feature {
            description = "Bad expressions to fail";
            when() => [];
            () => expectCondition(2 + 2 == 8),
            () => expectCondition(2 > 4)
        },
        feature {
            description = "More examples";
            when(Integer a, Integer b) => [a, b];
            examples = { [1, 2], [5, 10], [25, 50] };
            (Integer a, Integer b) => expect(2 * a, equalTo(b))()
        },
        feature {
            description = "Using generated examples";
            examples = { generateIntegers().sequence() };
            when(Integer* ints) => sort(ints);
            (Integer* ints) => expect(ints, sorted<Integer>(true))()
        },
        errorCheck {
            description = "when we call throw";
            function when() { throw; }
            expectToThrow(`Exception`)
        },
        errorCheck {
            description = "Error when not given at least one positive integer";
            examples = { [-4, 0], [0, -1], [-2, -3], [0, 0] };
            when = myFunction;
            expectToThrow(`Exception`)
        }
    }, Specification {
        feature {
            description = "Ceylon [*].first should return either the first element or null for empty Sequences";
            when() => [];
            expect([1].first, equalTo(1)),
            expect([5, 4, 3, 2, 1, 0].first, equalTo(5)),
            expect([1, 2, 3].first, equalTo(1))
        },
        feature {
            description = "Ceylon [*].first to work with String[]";
            when() => [];
            expect(["A"].first, equalTo("A")),
            expect(["B", "C", "D"].first, equalTo("B"))
        },
        feature {
            description = "";
            when() => [];
            expect(1..10, to(containEvery(1..10)))
        }
    }
    ].collect((Specification speck) => print(speck.run()));
    
}
