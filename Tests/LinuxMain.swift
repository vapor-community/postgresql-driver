#if os(Linux)

import XCTest
@testable import PostgreSQLDriverTests

XCTMain([
    testCase(FluentMySQLTests.allTests)
])

#endif
