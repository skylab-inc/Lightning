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

class ServerTests: XCTestCase {

    private func sendRequest(path: String, method: String) {
        let json = ["message": "Message to server!"]
        let session = URLSession(configuration: .default)
        let rootUrl = "http://localhost:3000"
        let responseExpectation = expectation(
            description: "Did not receive a response for path: \(path)"
        )
        let urlString = rootUrl + path
        let url = URL(string: urlString)!
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if method == "POST" {
            do {
                req.httpBody = try JSONSerialization.data(withJSONObject: json)
            } catch e {
                XCTFail(e)
            }
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
            guard let body = try? JSONSerialization.jsonObject(with: data)
                as? [String:String] else {
                    XCTFail("Problem with body")
                    return
            }
            XCTAssert(body == jsonResponse, "Received body \(body) != json \(jsonResponse)")
        }.resume()
    }

    func testServer() {
        #if !os(Linux)
            let json = ["message": "Message to server!"]
            let jsonResponse = ["message": "Message received!"]

            let postRequestExpectation = expectation(description: "Did not receive a POST request.")
            let getRequestExpectation = expectation(description: "Did not receive a GET request.")
            func handleRequest(request: Request) -> Response {
                if request.method == .post {
                    guard let body = try? JSONSerialization.jsonObject(with: data)
                        as? [String:String] else {
                            XCTFail("Problem with body")
                            return
                    }
                    XCTAssert(body == json, "Received body \(body) != json \(json)")
                    postRequestExpectation.fulfill()
                } else if request.method == .get {
                    getRequestExpectation.fulfill()
                }
                return try! Response(json: jsonResponse)
            }

            let server = HTTP.Server()
            server.listen(host: "0.0.0.0", port: 3000).startWithNext { client in

                let requestStream = client
                    .read()
                    .map(handleRequest)

                requestStream.onNext { response in
                    let writeStream = client.write(response)
                    writeStream.onFailed { err in
                        XCTFail(String(describing: err))
                    }
                    writeStream.start()
                }

                requestStream.onFailed { clientError in
                    XCTFail("ClientError: \(clientError)")
                }

                requestStream.onCompleted {

                }

                requestStream.start()
            }

            sendRequest(path: "", method: "POST")
            sendRequest(path: "", method: "GET")

            waitForExpectations(timeout: 1)
        #endif
    }

}

extension ServerTests {
    static var allTests = [
        ("testServer", testServer),
    ]
}
