//
//  GitHubAPITests.swift
//  StartSmallForAPITests
//
//  Created by 中江洋史 on 2020/09/02.
//  Copyright © 2020 中江洋史. All rights reserved.
//

import XCTest
@testable import StartSmallForAPI

class GitHubAPITests: XCTestCase {
    func testZenFetch() {
        let expectation = self.expectation(description: "API")

        GitHubZen.fetch { errorOrZen in
            switch errorOrZen {
            case let .left(error):
                XCTFail("\(error)")

            case let .right(zen):
                XCTAssertNotNil(zen)
            }

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10)
    }
    
    func testZenFetchTwice() {
        let expectation = self.expectation(description: "API")

        GitHubZen.fetch { errorOrZen in
            switch errorOrZen {
            case let .left(error):
                XCTFail("\(error)")

            case .right(_):
                GitHubZen.fetch { errorOrZen in
                    switch errorOrZen {
                    case let .left(error):
                        XCTFail("\(error)")

                    case let .right(zen):
                        XCTAssertNotNil(zen)
                        expectation.fulfill()
                    }
                }
            }
        }

        self.waitForExpectations(timeout: 10)
    }
    func testUser() throws {
        // レスポンスを定義。
        let response: Response = (
            // 200 OK が必要。
            statusCode: .ok,

            // 必要なヘッダーは特にない。
            headers: [:],

            // API レスポンスを GitHubUser へ変換できるか試すだけなので、
            // 適当な ID とログイン名を指定。
            payload: try JSONSerialization.data(withJSONObject: [
                "id": 1,
                "login": "octocat"
            ])
        )

        switch GitHubUser.from(response: response) {
        case let .left(error):
            // ここにきてしまったらわかりやすいようにする。
            XCTFail("\(error)")

        case let .right(user):
            // ID とログイン名が正しく変換できたことを確認する。
            XCTAssertEqual(user.id, 1)
            XCTAssertEqual(user.login, "octocat")
        }
    }
}
