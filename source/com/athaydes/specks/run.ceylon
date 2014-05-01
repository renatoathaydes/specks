
"Run the module `com.athaydes.specks`."
shared void run() {
    [Specification {
        "Ceylon == operator is transitive";
        ExpectAll {
            { ["a", "a"], ["", ""] };
            (String s1, String s2) => s1 == s2,
            (String s1, String s2) => s2 == s1
        }
    },
    Specification {
        "Some examples";
        Expect {
            () => 2 + 2 == 4,
            () => 2 < 4
        },
        Expect {
            equal -> [2 + 2, 4],
            smaller -> [2, 4]
        },
        Expect {
            () => 2 + 2 == 4,
            equal -> [2 + 2, 4]
        },
        Expect {
            () => 2 + 2 == 8,
            equal -> [2 + 2, 8]
        },
        ExpectAll {
            { [1, 2], [5, 10], [25, 50] };
            (Integer a, Integer b) => 2 * a == b
        },
        ExpectToThrow {
            `Exception`;
            void() { throw; }
        }
    }, Specification {
        "Ceylon [*].first Speck";
        Expect {
            function() {
                String? first = [].first;
                return first is Null;
            },
            equal -> { [1].first, 1 },
            equal -> { [5, 4, 3, 2, 1, 0].first, 5 },
            equal -> { [1, 2, 3].first, 1 }
        },
        Expect {
            equal -> { ["A"].first, "A" },
            equal -> { ["B", "C", "D"].first, "B" }
        }
    }
    ].collect((Specification speck) => print(speck.run()));
}
