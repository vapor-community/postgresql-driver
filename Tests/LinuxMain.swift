#if os(Linux)

import XCTest
@testable import FluentPostgreSQLTestSuite

XCTMain([
    testCase(PostgreSQLDriverTests.allTests),
])

#endif
