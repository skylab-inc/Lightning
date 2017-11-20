//
//  ServerTests.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 10/30/16.
//
//

import Foundation
import XCTest
@testable import HTTP

class RouterTests: XCTestCase {

    private func sendRequest(path: String, method: String, status: Int = 200) {
        let session = URLSession(configuration: .default)
        let jsonResponse = ["message": "Message received!"]
        let rootUrl = "http://localhost:3000"
        let jsonRequest = ["message": "Message to server!"]
        let responseExpectation = expectation(
            description: "Did not receive a response for path: \(path)"
        )
        let urlString = rootUrl + path
        let url = URL(string: urlString)!
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if method == "POST" {
            req.httpBody = try! JSONSerialization.data(withJSONObject: jsonRequest)
        }
        session.dataTask(with: req) { (data, urlResp, err) in
            responseExpectation.fulfill()
            if let err = err {
                XCTFail("Error on response: \(err)")
            }
            guard let data = data else {
                XCTFail("No data returned")
                return
            }
            if method == "POST" {
                guard let stringBody = try? JSONSerialization.jsonObject(with: data) else {
                    XCTFail("Problem deserializing body")
                    fatalError()
                }
                guard let body = stringBody as? [String:String] else {
                    XCTFail("Body not well formed json")
                    fatalError()
                }
                XCTAssert(body == jsonResponse, "Received body \(body) != json \(jsonResponse)")
            }
        }.resume()
    }

    func testRouting() {
        let requestExpectation = expectation(description: "Did not receive any request.")
        let userExpectation = expectation(description: "Did not receive a user request.")
        let loginExpectation = expectation(description: "Did not receive a login request.")

        var someRequest = false
        let jsonResponse = ["message": "Message received!"]

        let app = Router().map { request in
            if !someRequest {
                requestExpectation.fulfill()
                someRequest = true
            }
            return request
        }

        let api = Router()
        let comics = Router()

        func middleware1(request: Request) -> Request {
            return request
        }

        func middleware2(request: Request) -> Request {
            return request
        }

        // Authentication
        let authentication = Router()
            .map(middleware1)
            .map(middleware2)
            .filter { _ in true }

        authentication.post("/login") { request in
            loginExpectation.fulfill()
            return try! Response(json: jsonResponse)
        }

        authentication.post("/register") { request in
            return Response(status: .ok)
        }

        // Users
        let users = Router()

        users.get { request in
            userExpectation.fulfill()
            return try! Response(json: jsonResponse)
        }

        api.add(authentication)
        api.add("/users", users)
        api.add("/comics", comics)

        authentication.post("/login2") { _ in
            return try! Response(json: jsonResponse)
        }

        let notFound = Router()
        notFound.any { request in
            return Response(status: .notFound)
        }

        app.add("/v1.0", api)
        app.add(notFound)

        let server = HTTP.Server(delegate: app)
        server.listen(host: "0.0.0.0", port: 3000)

        sendRequest(path: "/v1.0/users", method: "GET")
        sendRequest(path: "/v1.0/login", method: "POST")
        sendRequest(path: "/v1.0/login2", method: "POST")
        sendRequest(path: "/v1.0/login3", method: "GET")

        waitForExpectations(timeout: 1) { error in
            server.stop()
        }
    }

    func testMiddleware() {
        let a = Router()
        let b = a.filter { request in
            return request.uri.path == "/test"
        }.map { request in
            XCTAssert(request.uri.path == "/test", "Filter did not work.")
            return Request(
                method: request.method,
                uri: request.uri,
                version: request.version,
                rawHeaders: request.rawHeaders,
                body: Array("Hehe, changin' the body.".utf8)
            )
        }

        a.any { request in
            XCTAssert(request.body.count == 0, "Body was transformed but should not have been.")
            return Response(status: .notFound)
        }

        b.get { request in
            XCTAssert(
                "Hehe, changin' the body." == String(
                    data: Data(request.body),
                    encoding: .utf8
                )!,
                "Body did not match expected transformed body."
            )
            return Response(status: .ok)
        }

        sendRequest(path: "/test", method: "GET")
        sendRequest(path: "/not_test", method: "GET", status: 404)

        a.add(b)

        let server = HTTP.Server(delegate: a)
        server.listen(host: "0.0.0.0", port: 3000)
        waitForExpectations(timeout: 1) { error in
            server.stop()
        }
    }

}

extension RouterTests {
    static var allTests = [
        ("testRouting", testRouting),
        ("testMiddleware", testMiddleware)
    ]
}
