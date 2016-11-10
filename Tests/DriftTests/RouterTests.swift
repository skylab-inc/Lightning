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
            
            let app = App(host: "0.0.0.0", port: 3000)
            let root = Router().map { request in
                requestExpectation.fulfill()
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
                return Response(status: .ok)
            }
            
            authentication.post("/register") { request in
                return Response(status: .ok)
            }
            
            // Users
            let users = Router()
            
            users.get { request in
                userExpectation.fulfill()
                return try! Response(json: [
                    "Tyler",
                    "Kyle",
                    "Thomas"
                ])
            }

            api.filter("/").add(authentication)
            api.add("/users", users)
            api.add("/comics", comics)
            
            let notFound = Router()
            notFound.any { request in
                requestExpectation.fulfill()
                return Response(status: .notFound)
            }
            
            app.add("/v1.0", api)
            app.add("/", root)
            app.add(notFound)
            
            app.start()
            
            let json = ["message": "Message to server!"]
            let jsonResponse = ["message": "Message received!"]
            
            let session = URLSession(configuration: .default)
            let urlString = "http://localhost:3000"
            let url = URL(string: urlString)!
            let responseExpectation = expectation(description: "Did not receive a response from server.")
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try! JSONSerialization.data(withJSONObject: json)
            session.dataTask(with: req) { (data, urlResp, err) in
                responseExpectation.fulfill()
                if let err = err {
                    XCTFail("Error on response: \(err)")
                }
                guard let data = data else {
                    XCTFail("No data returned")
                    return
                }
                let body = try! JSONSerialization.jsonObject(with: data) as! [String:String]
                XCTAssert(body == jsonResponse, "Received body \(body) != json \(jsonResponse)")
            }.resume()
            
            waitForExpectations(timeout: 1)
        #endif
    }
    
}

extension RouterTests {
    static var allTests = [
        ("testRouting", testRouting),
    ]
}
