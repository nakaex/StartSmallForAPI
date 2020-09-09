//
//  StartSmallForAPITests.swift
//  StartSmallForAPITests
//
//  Created by 中江洋史 on 2020/09/02.
//  Copyright © 2020 中江洋史. All rights reserved.
//

import XCTest
@testable import StartSmallForAPI

class StartSmallForAPITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testRequest() {
        let input:Request = (
            url:URL(string: "https://api.github.com/zen")!,
            queries:[],
            headers:[:],
            methodAndPayload:.get
        )
        WebAPI.call(with: input)
    }
    
    func testResopnse() {
        let response: Response = (
            statusCode: .ok,
            headers: [:],
            payload: "this is a response text".data(using: .utf8)!
        )

        let errorOrZen = GitHubZen.from(response: response)

        switch errorOrZen {
        case let .left(error):
            XCTFail("\(error)")

        case let .right(zen):
            XCTAssertEqual(zen.text, "this is a response text")
        }
    }
    
    func testAsync() {
        let expectation = self.expectation(description: "非同期に待つ")
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 10)
    }
    
    func testRequestAndResopnse() {
        let expectation = self.expectation(description: "API を待つ")
        let input: Input = (
            url: URL(string: "https://api.github.com/zen")!,
            queries: [],
            headers: [:],
            methodAndPayload: .get
        )

        WebAPI.call(with: input) { output in
            switch output {
            case let .noResponse(connectionError):
                XCTFail("\(connectionError)")


            case let .hasResponse(response):
                let errorOrZen = GitHubZen.from(response: response)
                XCTAssertNotNil(errorOrZen.right)
            }
            
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
