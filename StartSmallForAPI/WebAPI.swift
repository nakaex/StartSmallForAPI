//
//  WebAPI.swift
//  StartSmallForAPI
//
//  Created by 中江洋史 on 2020/09/02.
//  Copyright © 2020 中江洋史. All rights reserved.
//

import Foundation

typealias Input = Request

typealias Request = (
    url: URL,
    queries:[URLQueryItem],
    headers:[String:String],
    methodAndPayload:HTTPMethodAndPayload
)

enum HTTPMethodAndPayload {
    case get
    
    var method:String {
        switch self {
        case .get:
            return "get"
        }
    }
    
    var body: Data? {
        switch self {
        case .get:
            return nil
        }
    }
}

enum WebAPI {
    static func call(with input: Input, _ block: @escaping (Output) -> Void) {
        let urlRequest = self.createURLRequest(by: input)
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, urlResponse, error) in
            let output = self.createOutput(
                data: data,
                urlResponse: urlResponse as? HTTPURLResponse,
                error: error
            )
            block(output)
        }
        task.resume()
    }
    static func call(with input: Input) {
        self.call(with: input) { _ in
        }
    }
    static private func createURLRequest(by input: Input) -> URLRequest {
        var request = URLRequest(url: input.url)

        request.httpMethod = input.methodAndPayload.method

        request.httpBody = input.methodAndPayload.body

        request.allHTTPHeaderFields = input.headers

        return request
    }
    static private func createOutput(
        data: Data?,
        urlResponse: HTTPURLResponse?,
        error: Error?
    ) -> Output {
        guard let data = data, let response = urlResponse else {
            return .noResponse(.noDataOrNoResponse(debugInfo: error.debugDescription))
        }

        var headers: [String: String] = [:]
        for (key, value) in response.allHeaderFields.enumerated() {
            headers[key.description] = String(describing: value)
        }

        return .hasResponse((
            statusCode: .from(code: response.statusCode),
            headers: headers,
            payload: data
        ))
    }
}

enum Output {
    case hasResponse(Response)
    case noResponse(ConnectionError)
}

enum ConnectionError {
    case noDataOrNoResponse(debugInfo: String)
    case malformedURL(debugInfo: String)
}

typealias Response = (
    statusCode: HTTPStatus,
    headers:[String:String],
    payload: Data
)

enum HTTPStatus {
    case ok
    case notFound
    case unsupported(code: Int)
    static func from(code: Int) -> HTTPStatus {
        switch code {
        case 200:
            return .ok
        case 404:
            return .notFound
        default:
            return .unsupported(code:code)
        }
    }
}
