//
//  HTTPParser.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/27/16.
//
//

import Foundation
//import CHTTPParser

//
//func dataCallback(parserPointer: UnsafeMutablePointer<http_parser>?, dataPointer: UnsafePointer<Int8>?, length: Int) -> Int32 {
//    
//    return 0
//}


//public var ORDINARY: Int32 { get }
//public var CONTROL: Int32 { get }
//public var BACKSPACE: Int32 { get }
//public var NEWLINE: Int32 { get }
//public var TAB: Int32 { get }
//public var VTAB: Int32 { get }
//public var RETURN: Int32 { get }

//enum CharacterType: UInt8 {
//    case newline = 0x0a
//}
//
//public struct HTTPRequest {
//    
//    let headers: [String] = []
//    
//}
//
//
//public class HTTPStream  {
//    
//    private var socket: TCPSocket
//    private var buffer: [UInt8] = []
//    private var lines: [String] = []
//    
//    public init(socket: TCPSocket) {
//        self.socket = socket
//    }
//}
//
//public struct LineState {
//    let value: [UInt8]
//    let partialValue: [UInt8]
//}
//
//
//extension HTTPStream: ObservableType {
//    public typealias E = HTTPRequest
//    public func subscribe<O: ObserverType where O.E == E>(observer: O) -> Disposable {
//        
//        let subscription = self.socket
//            .read()
//            .scan(seed: LineState(value: [], partialValue: [])) { lastState, newBuffer in
//                let newPartial = lastState.partialValue + newBuffer
//                for i in 0..<newPartial.count {
//                    if newPartial[i] == CharacterType.newline.rawValue {
//                        let endOfLinePart = newPartial.prefix(upTo: i)
//                        let beginningOfLinePart = Array(newPartial.suffix(from: i + 1))
//                        return LineState(
//                            value: lastState.partialValue + endOfLinePart,
//                            partialValue: beginningOfLinePart
//                        )
//                    }
//                }
//                return LineState(
//                    value: lastState.value,
//                    partialValue: lastState.partialValue + newBuffer
//                )
//            }.subscribe()
//        
//        

//            .subscribe(
//            onNext: { incomingBuffer in
//                
//                self.buffer = self.buffer + incomingBuffer
//                for i in 0..<self.buffer.count {
//                    if self.buffer[i] == CharacterType.newline.rawValue {
//                        let line = String(bytes: self.buffer.prefix(upTo: i), encoding: NSUTF8StringEncoding)! // yolo
//                        self.lines.append(line)
//                        
//                        // TODO: This is probably so far from efficient it's crazy.
//                        // Probably we'll just keep the buffer and an index. Then we 
//                        // can toss the whole buffer once at the end of the message.
//                        self.buffer = Array(self.buffer.suffix(from: i + 1))
//                    }
//                }
//                
//                
//                while true {
//                    
//                    
//                    
//                    
//                    
////                    guard self.buffer.count >= MessageHeader.length else {
////                        return
////                    }
////                    
////                    let header = MessageHeader(buffer: Array(self.buffer.prefix(upTo: MessageHeader.length)))
////                    
////                    let length: Int
////                    switch header.type {
////                    case .coordUpdate: length = CoordUpdate.length
////                    case .longTestMessage: length = LongTestMessage.length
////                    }
////                    
////                    guard self.buffer.count >= MessageHeader.length + length else {
////                        return
////                    }
////                    
////                    // Produce the next element
////                    let messageStart = MessageHeader.length
////                    let body = Array(self.buffer[messageStart..<(messageStart + length)])
////                    observer.onNext(element: Message(header: header, payload: body))
////                    
////                    self.buffer = Array(self.buffer.suffix(from: messageStart + length))
//                }
//                
//            },
//            onError: { (error) in
//                observer.onError(error: error)
//            },
//            onCompleted: {
//                if !self.buffer.isEmpty {
//                    // Ended mid-message
//                    observer.onError(error: Error(rawValue: -1))
//                } else {
//                    observer.onCompleted()
//                }
//            }
//        )
        
//        return AnonymousDisposable {
//            subscription.dispose()
//        }
//    }
//}


//struct HTTPParser {
//    
//    let parserBuffer = [UInt8](repeating: 0, count: strideof(http_parser))
//    let parserPointer: UnsafeMutablePointer<http_parser>
//    let settingsBuffer = [UInt8](repeating: 0, count: strideof(http_parser_settings))
//    let settingsPointer: UnsafeMutablePointer<http_parser_settings>
//    
////    var offset: Int = 0
//    
//    var requestRegex = "^([A-Z-]+) ([^ ]+) HTTP\\/(\\d)\\.(\\d)$"
//    
//    init() {
//        parserPointer = UnsafeMutablePointer<http_parser>(parserBuffer)
//        http_parser_init(parserPointer, HTTP_REQUEST)
//        
//        settingsPointer = UnsafeMutablePointer<http_parser_settings>(settingsBuffer)
//        settingsPointer.pointee.on_body = dataCallback
//        settingsPointer.pointee.on_url = dataCallback
//        settingsPointer.pointee.on_status = dataCallback
//        settingsPointer.pointee.on_header_field = dataCallback
//
//    }
//    
//    func execute(buffer: [UInt8]) {
//        
//        for i in 0..<buffer.count {
//            if buffer[i] == CharacterType.newline.rawValue {
//                
//            }
//        }
//        
//        let converted = buffer.map { Int8.init($0) }
//        let numParsed = http_parser_execute(parserPointer, settingsPointer, converted, buffer.count)
//    }
    
//    func consumeLine() {
//        var end = this.end,
//        chunk = this.chunk;
//        for (var i = this.offset; i < end; i++) {
//            if (chunk[i] === 0x0a) { // \n
//                var line = this.line + chunk.toString('ascii', this.offset, i);
//                if (line.charAt(line.length - 1) === '\r') {
//                    line = line.substr(0, line.length - 1);
//                }
//                this.line = '';
//                this.offset = i + 1;
//                return line;
//            }
//        }
//        //line split over multiple chunks
//        this.line += chunk.toString('ascii', this.offset, this.end);
//        this.offset = this.end;
//    }
//    
//    func parseRequestLine() {
//        
//    }
    
//    HTTPParser.prototype.REQUEST_LINE = function () {
//    var line = this.consumeLine();
//    if (!line) {
//    return;
//    }
//    var match = requestExp.exec(line);
//    if (match === null) {
//    var err = new Error('Parse Error');
//    err.code = 'HPE_INVALID_CONSTANT';
//    throw err;
//    }
//    this.info.method = this._compatMode0_11 ? match[1] : methods.indexOf(match[1]);
//    if (this.info.method === -1) {
//    throw new Error('invalid request method');
//    }
//    if (match[1] === 'CONNECT') {
//    this.info.upgrade = true;
//    }
//    this.info.url = match[2];
//    this.info.versionMajor = +match[3];
//    this.info.versionMinor = +match[4];
//    this.body_bytes = 0;
//    this.state = 'HEADER';
//    };
//    
//    var responseExp = /^HTTP\/(\d)\.(\d) (\d{3}) ?(.*)$/;
//    HTTPParser.prototype.RESPONSE_LINE = function () {
//    var line = this.consumeLine();
//    if (!line) {
//    return;
//    }
//    var match = responseExp.exec(line);
//    if (match === null) {
//    var err = new Error('Parse Error');
//    err.code = 'HPE_INVALID_CONSTANT';
//    throw err;
//    }
//    this.info.versionMajor = +match[1];
//    this.info.versionMinor = +match[2];
//    var statusCode = this.info.statusCode = +match[3];
//    this.info.statusMessage = match[4];
//    // Implied zero length.
//    if ((statusCode / 100 | 0) === 1 || statusCode === 204 || statusCode === 304) {
//    this.body_bytes = 0;
//    }
//    this.state = 'HEADER';
//    };
    
//}