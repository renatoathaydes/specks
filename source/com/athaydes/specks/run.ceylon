


"Run the module `com.athaydes.specks`."
shared void run() {
    void show(Integer i) {
        print("``i`` -> " + toBinary(i).string);
    }
    
    for (i in -2..2) {
        show(i);
    }
    
    show(-129);
    show(-128);
    show(-127);
    show(-126);
    show(126);
    show(127);
    show(128);
    
    /*
    void myFunction(Integer i, Integer j) {
        if (i <= 0 || j <= 0) {
            throw Exception();
        }
    }
    
    [Specification {
        ExpectAll {
            "== operator should be symmetric";
            { ["a", "a"], ["", ""] };
            (String s1, String s2) => s1 == s2,
            (String s1, String s2) => s2 == s1
        }
    },
    Specification {
        Expect {
            "Ceylon operators to work";
            () => 2 + 2 == 4,
            () => 2 < 4
        },
        Expect {
            "Ceylon operators to work";
            equal -> [2 + 2, 4],
            smaller -> [2, 4]
        },
        Expect {
            "Ceylon operators to work";
            () => 2 + 2 == 4,
            equal -> [2 + 2, 4]
        },
        Expect {
            "Bad expressions to fail";
            () => 2 + 2 == 8,
            equal -> [2 + 2, 8]
        },
        ExpectAll {
            "More examples";
            examples = { [1, 2], [5, 10], [25, 50] };
            (Integer a, Integer b) => 2 * a == b
        },
        ExpectAll {
            "Using generated examples";
            examples = { generateIntegers().sequence() };
            (Integer* ints) => sort(ints) == ints
        },
        ExpectToThrow {
            `Exception`;
            "when we call throw";
            void() { throw; }
        },
        ExpectAllToThrow {
            `Exception`;
            "when not given at least one positive integer";
            { [-4, 0], [0, -1], [-2, -3], [0, 0] };
            myFunction,
            void(Integer i, Integer j) {
                if (i <= 0 || j <= 0) {
                    throw Exception("Not given a positive integer");
                }
            }
        }
    }, Specification {
        Expect {
            "Ceylon [*].first should return either the first element or null for empty Sequences";
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
    ].collect((Specification speck) => print(speck.run()));
    */
}
