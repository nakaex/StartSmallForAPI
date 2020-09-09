//
//  GitHubAPI.swift
//  StartSmallForAPI
//
//  Created by 中江洋史 on 2020/09/02.
//  Copyright © 2020 中江洋史. All rights reserved.
//

import Foundation

enum Either<Left, Right> {
    case left(Left)
    case right(Right)
    var left: Left? {
        switch self {
        case let .left(x):
            return x

        case .right:
            return nil
        }
    }
    var right: Right? {
        switch self {
        case .left:
            return nil

        case let .right(x):
            return x
        }
    }
}

struct GitHubZen {
    let text: String
    static func from(response: Response) -> Either<TransformError, GitHubZen> {
        switch response.statusCode {
        case .ok:
            guard let string = String(data: response.payload, encoding: .utf8) else {
                return .left(.malformedData(debugInfo: "not UTF-8 string"))
            }
            return .right(GitHubZen(text: string))
        default:
            return .left(.unexpectedStatusCode(
                debugInfo: "\(response.statusCode)")
            )
        }
    }
    static func fetch(
        // コールバック経由で、接続エラーか変換エラーか GitHubZen のいずれかを受け取れるようにする。
        _ block: @escaping (Either<Either<ConnectionError, TransformError>, GitHubZen>) -> Void

        // コールバックの引数の型が少しわかりづらいが、次の3パターンになる。
        //
        // - 接続エラーの場合     → .left(.left(ConnectionEither))
        // - 変換エラーの場合     → .left(.right(TransformError))
        // - 正常に取得できた場合 → .right(GitHubZen)
    ) {
        // URL が生成できない場合は不正な URL エラーを返す
        let urlString = "https://api.github.com/zen"
        guard let url = URL(string: urlString) else {
            block(.left(.left(.malformedURL(debugInfo: urlString))))
            return
        }

        // GitHub Zen API は何も入力パラメータがないので入力は固定値になる。
        let input: Input = (
            url: url,
            queries: [],
            headers: [:],
            methodAndPayload: .get
        )

        // GitHub Zen API を呼び出す。
        WebAPI.call(with: input) { output in
            switch output {
            case let .noResponse(connectionError):
                // 接続エラーの場合は、接続エラーを渡す。
                block(.left(.left(connectionError)))

            case let .hasResponse(response):
                // レスポンスがわかりやすくなるように GitHubZen へと変換する。
                let errorOrZen = GitHubZen.from(response: response)

                switch errorOrZen {
                case let .left(error):
                    // 変換エラーの場合は、変換エラーを渡す。
                    block(.left(.right(error)))

                case let .right(zen):
                    // 正常に変換できた場合は、GitHubZen オブジェクトを渡す。
                    block(.right(zen))
                }
            }
        }
    }
    enum TransformError {
        case unexpectedStatusCode(debugInfo: String)
        case malformedData(debugInfo: String)
    }
}

enum GitHubZenResponse {
    case success(GitHubZen)
    case failure(GitHubZen.TransformError)
}

struct GitHubUser: Codable {
    let id: Int
    let login: String


    /// レスポンスから GitHubUser オブジェクトへ変換する関数。
    static func from(response: Response) -> Either<TransformError, GitHubUser> {
        switch response.statusCode {
        // HTTP ステータスが OK だったら、ペイロードの中身を確認する。
        case .ok:
            do {
                // User API は JSON 形式の文字列を返すはずので Data を JSON として
                // 解釈してみる。
                let jsonDecoder = JSONDecoder()
                let user = try jsonDecoder.decode(GitHubUser.self, from: response.payload)

                // もし、内容を JSON として解釈できたなら、
                // その文字列から GitHubUser を作って返す（エラーではない型は右なので .right を使う）
                return .right(user)
            }
            catch {
                // もし、Data が JSON 文字列でなければ、何か間違ったデータを受信してしまったのかもしれない。
                // この場合は、malformedData エラーを返す（エラーの型は左なので .left を使う）。
                return .left(.malformedData(debugInfo: "\(error)"))
            }

        // もし、HTTP ステータスコードが OK 以外であれば、エラーとして扱う。
        // たとえば、GitHub API を呼び出しすぎたときは 200 OK ではなく 403 Forbidden が
        // 返るのでこちらにくる。
        default:
            // エラーの内容がわかりやすいようにステータスコードを入れて返す。
            return .left(.unexpectedStatusCode(debugInfo: "\(response.statusCode)"))
        }
    }


    /// GitHub User API の変換で起きうるエラーの一覧。
    enum TransformError {
        /// ペイロードが壊れた JSON だった場合のエラー。
        case malformedData(debugInfo: String)

        /// HTTP ステータスコードが OK 以外だった場合のエラー。
        case unexpectedStatusCode(debugInfo: String)
    }
}
