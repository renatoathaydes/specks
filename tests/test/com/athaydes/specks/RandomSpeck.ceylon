import ceylon.collection {
    HashSet,
    unlinked,
    Hashtable
}
import ceylon.test {
    test,
    testExecutor
}

import com.athaydes.specks {
    SpecksTestExecutor,
    Specification,
    Random,
    scale,
    feature,
    errorCheck
}
import com.athaydes.specks.assertion {
    expect,
    expectToThrow
}
import com.athaydes.specks.matcher {
    toBe,
    equalTo,
    identicalTo,
    largerThan,
    smallerThan
}

[Integer[]+] partition({Integer+} ints, Integer partitionsCount, variable Integer low, Integer step) {
    variable value high = low + step;
    value partitions = (1..partitionsCount).collect((_) {
        value p = ints.select((element) => low <= element < high);
        low += step;
        high += step;   
        return p; 
    });
    return partitions;
}

Value nonNull<Value>(Value? val)
        given Value satisfies Object {
    assert(exists val);
    return val;
}

Boolean naturalDistribution({Integer+} ints) {
    value partitions = partition(ints, 16, -2 * (2^52), 2^50);
    
    variable Integer left = 0;
    variable Integer right = partitions.size - 1;
    
    while (left < right) {
        value rightPartitionSize = nonNull(partitions[right]?.size).float;
        value leftPartitionSize = nonNull(partitions[left]?.size).float;
        
        if (rightPartitionSize < 0.9 * leftPartitionSize ||
            rightPartitionSize > 1.1 * leftPartitionSize) {
            print("Natural distribution - FAIL: Partitions not naturally distributed: ``partitions.map((it) => it.size)``");
            return false;
        }
        left++;
        right--;
    }
    if (sum(partitions*.size) != ints.size) {
        print("Natural distribution - FAIL: Not all samples fall into expected range");
        return false;
    }
    return true;
}

Boolean uniformDistribution({Integer+} ints) {
    value partitions = partition(ints, 8, -(2^52), 2^50);
    
    value minPartitionSize = 0.9 * partitions.first.size;
    value maxPartitionSize = 1.1 * partitions.first.size;
    
    for (partition in partitions.rest) {
        if (partition.size.float < minPartitionSize ||
            partition.size.float > maxPartitionSize) {
            print("Uniform distribution - FAIL: Partitions not uniformly distributed: ``partitions.map((it) => it.size)``");
            return false;
        }
    }
    if (sum(partitions*.size) != ints.size) {
        print("Uniform distribution - FAIL: Not all samples fall into expected range");
        return false;
    }
    return true;
}

Integer uniqueElements(Object[] elements) {
    value set = HashSet(unlinked, Hashtable((elements.size/0.75).integer+1), elements);
    return set.size;
}


{Integer+} successiveDiff({Integer+} ints) {
    variable value prev = ints.first;
    value result = ints.rest.map((it) { value result = it - prev; prev = it; return result; });
    assert(is {Integer+} result);
    return result;
}

testExecutor(`class SpecksTestExecutor`)
class RandomSpeck() {
    
    value random = Random();
    
    function randomIntegers(Integer count, Integer(Integer) scale = (Integer int) => int) 
            => (1..count).collect((_) => scale(random.nextInteger()));
    
    // should mirror the value used in Random
    Integer maxInt = 2^52;
    
    shared test Specification scaleSpeck() => Specification {
        feature {
            description = "CeylonDoc examples to be correct";
            when() => [];
            () => expect(scale(0), toBe(equalTo(0))),
            () => expect(scale(2^52, -10, 10), toBe(equalTo(10))),
            () => expect(scale(-(2^52), -10, 10), toBe(equalTo(-10)))
        },
        feature {
            description = "Integers can be scaled to within a given range";
            
            when(Integer int, Integer min, Integer max, Integer expected) 
                    => [scale(int, min, max), expected];
            
            examples = [
                [0, -5, 5, 0], [-maxInt, -5, 5, -5], [maxInt, -5, 5, 5], 
                [-maxInt/2, -6, 6, -3], [maxInt/2, -6, 6, 3],
                [-maxInt/3, -6, 6, -2], [maxInt/3, -6, 6, 1],
                [5, 5, 5, 5], [0, -10, -10, -10]];
            
            (Integer result, Integer expected)
                    => expect(result, toBe(equalTo(expected)))
        },
        errorCheck {
            description = "If maximum < minimum";
            examples = [[10, 0], [-1, -2], [100, 10]];
            when(Integer min, Integer max) => scale(0, min, max);
            expectToThrow(`Exception`)
        }
    };
    
    value testIntegers = randomIntegers(100k);
    
    shared test Specification randomIntegersReturnsApparentlyRandomValues() => Specification { 
        feature {
            description = "Random integers are generated with uniform distribution";
            when() => [];
            () => expect(uniformDistribution(testIntegers),
                toBe(identicalTo(true)))
        },
        feature {
            description = "The difference between successive values has natural distribution";
            when() => [];
            () => expect(naturalDistribution(successiveDiff(testIntegers)),
                toBe(identicalTo(true)))
        },
        feature {
            description = "Nearly no repitition within a million integers";
            when() => [];
            () => expect(uniqueElements(randomIntegers(1M)),
                toBe(largerThan(1M - 5), smallerThan(1M + 5)))
        }
    };
    
}