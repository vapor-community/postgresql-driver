#if os(Linux)

import XCTest
@testable import FluentPostgreSQLTests

XCTMain([
    testCase(DriverTests.allTests),
    testCase(JoinTests.allTests),
    testCase(SchemaTests.allTests),
    testCase(SerializerTests.allTests)
])

#endif
