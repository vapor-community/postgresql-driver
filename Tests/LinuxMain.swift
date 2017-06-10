import XCTest
@testable import PostgreSQLDriverTests

XCTMain([
    testCase(FluentPostgreSQLTests.allTests),
    testCase(SubsetTests.allTests)
])
