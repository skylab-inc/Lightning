// Parser.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2016 Edge
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
import Foundation

typealias CParserPointer = UnsafeMutablePointer<http_parser>
typealias RawParserPointer = UnsafeMutablePointer<RawParser>

private func bridge<T: AnyObject>(_ obj: T) -> UnsafeMutableRawPointer {
    return Unmanaged.passUnretained(obj).toOpaque()
}

private func bridge<T: AnyObject>(_ ptr: UnsafeMutableRawPointer) -> T {
    return Unmanaged<T>.fromOpaque(ptr).takeUnretainedValue()
}

struct ParseError: Error {
    let description: String
}

public class RequestParser {
    private let parser: FullMessageParser!
    var onRequest: ((Request) -> Void)?

    init(onRequest: ((Request) -> Void)? = nil) {
        self.onRequest = onRequest
        self.parser = FullMessageParser(type: HTTP_REQUEST)
        self.parser.onComplete = { [weak self] parseState in
            guard let uri = URL(string: parseState.uri) else {
                throw ParseError(description: "URL not valid.")
            }

            let request = Request(
                method: Method(code: parseState.method),
                uri: uri,
                version: Version(major: parseState.version.major, minor: parseState.version.minor),
                rawHeaders: parseState.rawHeaders,
                body: parseState.body
            )
            self?.onRequest?(request)
        }
    }

    public func parse(_ data: Data) throws {
        try parser.parse(data)
    }

}

public class ResponseParser {
    private let parser: FullMessageParser
    var onResponse: ((Response) -> Void)?

    init(onResponse: ((Response) -> Void)? = nil) {
        self.onResponse = onResponse
        self.parser = FullMessageParser(type: HTTP_RESPONSE)
        self.parser.onComplete = { [weak self] parseState in
            let response = Response(
                version: Version(major: parseState.version.major, minor: parseState.version.minor),
                status: Status(code: parseState.statusCode),
                rawHeaders: parseState.rawHeaders,
                body: parseState.body
            )
            self?.onResponse?(response)
        }
    }

    public func parse(_ data: Data) throws {
        try parser.parse(data)
    }

}

private final class FullMessageParser {

    struct ParseState {

        var version: (major: Int, minor: Int) = (0, 0)
        var rawHeaders: [String] = []
        var body: Data = Data()

        // Response
        var statusCode: Int! = nil
        var statusPhrase = ""

        // Request
        var method: Int! = nil
        var uri = ""

    }

    var state = ParseState()
    var onComplete: ((ParseState) throws -> ())?
    let rawParser: RawParser

    init(type: http_parser_type, onComplete: ((ParseState) throws -> ())? = nil) {
        self.onComplete = onComplete
        self.rawParser = RawParser(type: type)
        self.rawParser.delegate = self
    }

    func parse(_ data: Data) throws {
        try rawParser.parse(data)
    }

}

extension FullMessageParser: RawParserDelegate {

    func onMessageBegin() throws {
        // No state change
    }

    func onURL(data: UnsafeBufferPointer<UInt8>) throws {
        guard let uri = String(bytes: data, encoding: .utf8) else {
            throw ParseError(description: "URI could not be encoded as UTF8.")
        }
        state.uri += uri
    }

    func onStatus(data: UnsafeBufferPointer<UInt8>) throws {
        guard let partialStatusPhrase = String(bytes: data, encoding: .utf8) else {
            throw ParseError(description: "Status phrase could not be encoded as UTF8.")
        }
        state.statusPhrase += partialStatusPhrase
    }

    func onHeaderField(data: UnsafeBufferPointer<UInt8>) throws {
        guard let partialHeaderField = String(bytes: data, encoding: .utf8) else {
            throw ParseError(description: "Header field could not be encoded as UTF8.")
        }
        if state.rawHeaders.count % 2 == 0 {
            state.rawHeaders.append("")
        }
        state.rawHeaders[state.rawHeaders.count - 1] += partialHeaderField
    }

    func onHeaderValue(data: UnsafeBufferPointer<UInt8>) throws {
        guard let partialHeaderValue = String(bytes: data, encoding: .utf8) else {
            throw ParseError(description: "Header value could not be encoded as UTF8.")
        }
        if state.rawHeaders.count % 2 == 1 {
            state.rawHeaders.append("")
        }
        state.rawHeaders[state.rawHeaders.count - 1] += partialHeaderValue
    }

    func onHeadersComplete(
        method: Int,
        statusCode: Int,
        majorVersion: Int,
        minorVersion: Int
    ) throws -> HeadersCompleteDirective {
        state.statusCode = statusCode
        state.version = (major: majorVersion, minor: minorVersion)
        state.method = method
        return .none
    }

    func onBody(data: UnsafeBufferPointer<UInt8>) throws {
        state.body += Array(data)
    }

    func onMessageComplete() throws {
        try onComplete?(state)
        // Reset state
        state = ParseState()
    }

    func onChunkHeader() throws {
        // No state change
    }

    func onChunkComplete() throws {
        // No state change
    }

}

public enum HeadersCompleteDirective {
    case none
    case noBody
    case noBodyNoFurtherResponses
}

public protocol RawParserDelegate: class {

    func onMessageBegin() throws
    func onMessageComplete() throws

    func onURL(data: UnsafeBufferPointer<UInt8>) throws
    func onStatus(data: UnsafeBufferPointer<UInt8>) throws
    func onHeaderField(data: UnsafeBufferPointer<UInt8>) throws
    func onHeaderValue(data: UnsafeBufferPointer<UInt8>) throws

    func onHeadersComplete(
        method: Int,
        statusCode: Int,
        majorVersion: Int,
        minorVersion: Int
    ) throws -> HeadersCompleteDirective

    func onBody(data: UnsafeBufferPointer<UInt8>) throws

    func onChunkHeader() throws
    func onChunkComplete() throws

}

public final class RawParser {

    // Sneaky sneaky, I'm a meanie.
    // Here I create a constant private pointer to our "constant" http_parser
    // The can be therefore mutated through the pointer, but only within the RawParser.
    let parser = http_parser()
    private let parserPointer: UnsafeMutablePointer<http_parser>

    var type: http_parser_type
    fileprivate weak var delegate: RawParserDelegate?

    public init(type: http_parser_type, delegate: RawParserDelegate? = nil) {
        self.type = type
        self.delegate = delegate
        parserPointer = withUnsafeMutablePointer(to: &parser) { $0 }
        reset()
    }

    func reset() {
        http_parser_init(parserPointer, self.type)

        // Set self as the context. self must be a reference type.
        parserPointer.pointee.data = bridge(self)
    }

    public func parse(_ data: Data) throws {
        try data.withUnsafeBytes { (convertedPointer: UnsafePointer<Int8>) in
            let bytesParsed = http_parser_execute(
                parserPointer,
                &requestSettings,
                convertedPointer,
                data.count
            )
            guard bytesParsed == data.count else {
                reset()
                let errorName = http_errno_name(http_errno(parser.http_errno))!
                let errorDescription = http_errno_description(http_errno(parser.http_errno))!
                let error = ParseError(
                    description: "\(String(validatingUTF8: errorName)!):" +
                    " \(String(validatingUTF8: errorDescription)!)"
                )
                throw error
            }
        }
    }

}

var requestSettings: http_parser_settings = {
    var settings = http_parser_settings()
    http_parser_settings_init(&settings)

    settings.on_message_begin    = onMessageBegin
    settings.on_url              = onURL
    settings.on_status           = onStatus
    settings.on_header_field     = onHeaderField
    settings.on_header_value     = onHeaderValue
    settings.on_headers_complete = onHeadersComplete
    settings.on_body             = onBody
    settings.on_message_complete = onMessageComplete
    settings.on_chunk_header     = onChunkHeader
    settings.on_chunk_complete   = onChunkComplete

    return settings
}()

// MARK: C function pointer spring boards
private func onMessageBegin(_ parser: CParserPointer?) -> Int32 {
    let rawParser: RawParser = bridge(parser!.pointee.data)
    do {
        try rawParser.delegate?.onMessageBegin()
    } catch {
        return 1
    }
    return 0
}

private func onURL(_ parser: CParserPointer?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    let rawParser: RawParser = bridge(parser!.pointee.data)
    do {
        try data?.withMemoryRebound(to: UInt8.self, capacity: length) { convertedPointer in
            try rawParser
                .delegate?
                .onURL(data: UnsafeBufferPointer(start: convertedPointer, count: length))
        }
    } catch {
        return 1
    }
    return 0
}

private func onStatus(_ parser: CParserPointer?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    let rawParser: RawParser = bridge(parser!.pointee.data)
    do {
        try data?.withMemoryRebound(to: UInt8.self, capacity: length) { convertedPointer in
            try rawParser
                .delegate?
                .onStatus(data: UnsafeBufferPointer(start: convertedPointer, count: length))
        }
    } catch {
        return 1
    }
    return 0
}

private func onHeaderField(
        _ parser: CParserPointer?,
        data: UnsafePointer<Int8>?,
        length: Int
    ) -> Int32 {
    let rawParser: RawParser = bridge(parser!.pointee.data)
    do {
        try data?.withMemoryRebound(to: UInt8.self, capacity: length) { convertedPointer in
            try rawParser
                .delegate?
                .onHeaderField(data: UnsafeBufferPointer(start: convertedPointer, count: length))
        }
    } catch {
        return 1
    }
    return 0
}

private func onHeaderValue(
        _ parser: CParserPointer?,
        data: UnsafePointer<Int8>?,
        length: Int
    ) -> Int32 {
    let rawParser: RawParser = bridge(parser!.pointee.data)
    do {
        try data?.withMemoryRebound(to: UInt8.self, capacity: length) { convertedPointer in
            try rawParser
                .delegate?
                .onHeaderValue(data: UnsafeBufferPointer(start: convertedPointer, count: length))
        }
    } catch {
        return 1
    }
    return 0
}

private func onHeadersComplete(_ cParserPointer: CParserPointer?) -> Int32 {
    let rawParser: RawParser = bridge(cParserPointer!.pointee.data)

    let method = Int(rawParser.parser.method)
    let statusCode = Int(rawParser.parser.status_code)
    let majorVersion = Int(rawParser.parser.http_major)
    let minorVersion = Int(rawParser.parser.http_minor)

    do {
        let directive = try rawParser.delegate?.onHeadersComplete(
            method: method,
            statusCode: statusCode,
            majorVersion: majorVersion,
            minorVersion: minorVersion
        )
        switch directive {
        case .none: return 0
        case .none?: return 0
        case .noBody?: return 1
        case .noBodyNoFurtherResponses?: return 2
        }
    } catch {
        return 3 // on_headers_complete is a special snowflake
    }
}

private func onBody(_ cParserPointer: CParserPointer?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    let rawParser: RawParser = bridge(cParserPointer!.pointee.data)
    do {
        try data?.withMemoryRebound(to: UInt8.self, capacity: length) { convertedPointer in
            try rawParser
                .delegate?
                .onBody(data:UnsafeBufferPointer(start: convertedPointer, count: length))
        }
    } catch {
        return 1
    }
    return 0
}

private func onMessageComplete(_ cParserPointer: CParserPointer?) -> Int32 {
    let rawParser: RawParser = bridge(cParserPointer!.pointee.data)
    do {
        try rawParser.delegate?.onMessageComplete()
    } catch {
        return 1
    }
    return 0
}

private func onChunkHeader(_ cParserPointer: CParserPointer?) -> Int32 {
    let rawParser: RawParser = bridge(cParserPointer!.pointee.data)
    do {
        try rawParser.delegate?.onChunkHeader()
    } catch {
        return 1
    }
    return 0
}

private func onChunkComplete(_ cParserPointer: CParserPointer?) -> Int32 {
    let rawParser: RawParser = bridge(cParserPointer!.pointee.data)
    do {
        try rawParser.delegate?.onChunkComplete()
    } catch {
        return 1
    }
    return 0
}
