// RequestParser.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import CHTTPParser

typealias RequestContext = UnsafeMutablePointer<RequestParserContext>

struct RequestParserContext {
    var method: Method! = nil
    var uri: URI! = nil
    var version: Version = Version(major: 0, minor: 0)
    var headers: [String : String] = [:]
    var body: [UInt8] = []

    var currentURI = ""
    var buildingHeaderName = ""
    var currentHeaderName = ""
    var completion: (Request) -> Void

    init(completion: (Request) -> Void) {
        self.completion = completion
    }
}

var requestSettings: http_parser_settings = {
    var settings = http_parser_settings()
    http_parser_settings_init(&settings)

    settings.on_url              = onRequestURL
    settings.on_header_field     = onRequestHeaderField
    settings.on_header_value     = onRequestHeaderValue
    settings.on_headers_complete = onRequestHeadersComplete
    settings.on_body             = onRequestBody
    settings.on_message_complete = onRequestMessageComplete

    return settings
}()

public final class RequestParser {
    let context: RequestContext
    var parser = http_parser()
    var onRequest: ((Request) -> Void)?

    public init(onRequest: ((Request) -> Void)? = nil) {
        self.onRequest = onRequest
        context = RequestContext(allocatingCapacity: 1)
        context.initialize(with: RequestParserContext { request in
            self.onRequest?(request)
        })
        resetParser()
    }

    deinit {
        context.deallocateCapacity(1)
    }

    func resetParser() {
        http_parser_init(&parser, HTTP_REQUEST)
        parser.data = UnsafeMutablePointer<Void>(context)
    }

    public func parse(_ data: Data) throws {
        let bytesParsed = http_parser_execute(&parser, &requestSettings, UnsafePointer(data.bytes), data.count)
        guard bytesParsed == data.count else {
            resetParser()
            let errorName = http_errno_name(http_errno(parser.http_errno))!
            let errorDescription = http_errno_description(http_errno(parser.http_errno))!
            let error = ParseError(description: "\(String(validatingUTF8: errorName)!): \(String(validatingUTF8: errorDescription)!)")
            throw error
        }
    }
}

extension RequestParser {
    public func parse(_ convertible: DataConvertible) throws {
        try parse(convertible.data)
    }
}

func onRequestURL(_ parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    return RequestContext(parser!.pointee.data).withPointee { requestContext in
        guard let uri = String(pointer: data!, length: length) else {
            return 1
        }

        requestContext.currentURI += uri
        return 0
    }
}

func onRequestHeaderField(_ parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    return RequestContext(parser!.pointee.data).withPointee { requestContext in
        guard let headerName = String(pointer: data!, length: length) else {
            return 1
        }

        if requestContext.currentHeaderName != "" {
            requestContext.currentHeaderName = ""
        }

        requestContext.buildingHeaderName += headerName
        return 0
    }
}

func onRequestHeaderValue(_ parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    return RequestContext(parser!.pointee.data).withPointee { requestContext in
        guard let headerValue = String(pointer: data!, length: length) else {
            return 1
        }

        if requestContext.currentHeaderName == "" {
            requestContext.currentHeaderName = requestContext.buildingHeaderName
            requestContext.buildingHeaderName = ""

            if requestContext.headers[requestContext.currentHeaderName] != nil {
                let previousHeaderValue = requestContext.headers[requestContext.currentHeaderName] ?? ""
                requestContext.headers[requestContext.currentHeaderName] = previousHeaderValue + ", "
            }
        }

        let previousHeaderValue = requestContext.headers[requestContext.currentHeaderName] ?? ""
        requestContext.headers[requestContext.currentHeaderName] = previousHeaderValue + headerValue

        return 0
    }
}

func onRequestHeadersComplete(_ parser: Parser?) -> Int32 {
    return RequestContext(parser!.pointee.data).withPointee { requestContext in
        requestContext.method = Method(code: Int(parser!.pointee.method))
        let major = Int(parser!.pointee.http_major)
        let minor = Int(parser!.pointee.http_minor)
        requestContext.version = Version(major: major, minor: minor)

        guard let uri = try? URI(requestContext.currentURI) else {
            return 1
        }

        requestContext.uri = uri
        requestContext.currentURI = ""
        requestContext.buildingHeaderName = ""
        requestContext.currentHeaderName = ""
        return 0
    }
}

func onRequestBody(_ parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    RequestContext(parser!.pointee.data).withPointee { requestContext in
        let buffer = UnsafeBufferPointer<UInt8>(start: UnsafePointer(data), count: length)
        requestContext.body += Data(Array(buffer))
        return
    }

    return 0
}

func onRequestMessageComplete(_ parser: Parser?) -> Int32 {
    return RequestContext(parser!.pointee.data).withPointee { requestContext in
        let request = Request(
            method: requestContext.method,
            uri: requestContext.uri,
            version: requestContext.version,
            headers: requestContext.headers,
            body: requestContext.body
        )

        requestContext.completion(request)

        requestContext.method = nil
        requestContext.uri = nil
        requestContext.version = Version(major: 0, minor: 0)
        requestContext.headers = [:]
        requestContext.body = []
        return 0
    }
}
