import ceylon.test {
    test,
    testExecutor
}
import com.athaydes.specks {
    SpecksTestExecutor,
    Specification,
    expectations
}
import com.athaydes.specks.assertion {
    expect,
    expectCondition
}
import com.athaydes.specks.matcher {
    equalTo
}

testExecutor (`class SpecksTestExecutor`)
shared class Samples() {

    test
    shared Specification simpleSpec() => Specification {
        expectations {
            expect(max { 1, 2, 3 }, equalTo(3))
        }
    };
    
    

}
