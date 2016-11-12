//
//  ServerTests.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 10/30/16.
//
//

import Foundation
import XCTest
import HTTP
@testable import Drift

class RouterTests: XCTestCase {
    
    func testRouting() {
        #if !os(Linux)
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
            
            app.start(host: "0.0.0.0", port: 3000)
            
            let session = URLSession(configuration: .default)
            let rootUrl = "http://localhost:3000"
            let jsonRequest = ["message": "Message to server!"]

            func sendRequest(path: String, method: String) {
                let responseExpectation = expectation(description: "Did not receive a response for path: \(path)")
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
                        let body = try! JSONSerialization.jsonObject(with: data) as! [String:String]
                        XCTAssert(body == jsonResponse, "Received body \(body) != json \(jsonResponse)")
                    }
                }.resume()
            }
            
            sendRequest(path: "/v1.0/users", method: "GET")
            sendRequest(path: "/v1.0/login", method: "POST")
            sendRequest(path: "/v1.0/login2", method: "POST")
            sendRequest(path: "/v1.0/login3", method: "GET")

            waitForExpectations(timeout: 1)
        #endif
    }
    
}

extension RouterTests {
    static var allTests = [
        ("testRouting", testRouting),
    ]
}
