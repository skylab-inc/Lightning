//
//  UVStuff.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/1/16.
//
//

import Foundation

//var getAddressInfoStruct = uv_getaddrinfo_t()
//func getAddressInfoCallback(
//    getAddressInfoStruct: UnsafeMutablePointer<uv_getaddrinfo_t>!,
//    status: Int32,
//    addressInfo: UnsafeMutablePointer<addrinfo>!)
//{
//    print("addr_info")
//    if status < 0 {
//        fatalError(String(cString: uv_strerror(status)))
//    }
//    let tcpHandle = UnsafeMutablePointer<uv_tcp_t>(malloc(strideof(uv_tcp_t)))
//    let connectionRequest = UnsafeMutablePointer<uv_connect_t>(malloc(strideof(uv_connect_t)))
//    uv_tcp_init(uv_default_loop(), tcpHandle)
//    uv_tcp_connect(connectionRequest, tcpHandle, addressInfo.pointee.ai_addr, connectCallback)
//}
//
//func connectCallback(connectionRequest: UnsafeMutablePointer<uv_connect_t>!, status: Int32) {
//    print("connect")
//    if status < 0 {
//        fatalError(String(cString: uv_strerror(status)))
//    }
//    let writeRequest = UnsafeMutablePointer<uv_write_t>(malloc(strideof(uv_write_t)))
//
//    let message = "asdf"
//    var messageArray = Array(message.nulTerminatedUTF8.map{Int8.init($0)})
//    messageArray.withUnsafeMutableBufferPointer { messagePointer in
//        var buffer = uv_buf_t()
//        buffer.base = messagePointer.baseAddress!
//        buffer.len = messagePointer.count
//
//        uv_write(writeRequest, connectionRequest.pointee.handle, &buffer, 1, writeCallback)
//
//        uv_read_start(connectionRequest.pointee.handle, onAllocCallback, readCallback)
//    }
//    free(connectionRequest)
//}
//
//func writeCallback(writeRequest: UnsafeMutablePointer<uv_write_t>!, status: Int32) {
//    print("write")
//    if status < 0 {
//        fatalError(String(cString: uv_strerror(status)))
//    }
//    free(writeRequest)
//}
//
//func onAllocCallback(handle: UnsafeMutablePointer<uv_handle_t>!, suggestedSize: Int, buffer: UnsafeMutablePointer<uv_buf_t>!) {
//    print("alloc")
//    buffer.pointee.base = UnsafeMutablePointer<Int8>(malloc(suggestedSize))
//    buffer.pointee.len = suggestedSize
//}
//
//func readCallback(tcpStream: UnsafeMutablePointer<uv_stream_t>!, numRead: Int, buffer: UnsafePointer<uv_buf_t>!) {
//    print("read")
//    if numRead < 0 {
//        let errorCode = uv_errno_t(Int32(numRead))
//        if errorCode == UV_EOF {
//            uv_read_stop(tcpStream)
//        } else {
//            fatalError(String(cString: uv_strerror(Int32(numRead))))
//        }
//        if (numRead > 0) {
//            let bufferPointer = UnsafeBufferPointer(start: buffer.pointee.base, count: numRead)
//            let message = String(cString: bufferPointer.baseAddress!)
//            print(message)
//        }
//    }
//    free(buffer.pointee.base)
//}
//
//var hints = addrinfo(
//    ai_flags: 0,
//    ai_family: AF_INET,
//    ai_socktype: SOCK_STREAM,
//    ai_protocol: IPPROTO_TCP,
//    ai_addrlen: 0,
//    ai_canonname: nil,
//    ai_addr: nil,
//    ai_next: nil
//)
//uv_getaddrinfo(uv_default_loop(), &getAddressInfoStruct, getAddressInfoCallback, "0.0.0.0", "50000", &hints)
//
//func getAddrInfo(
//    loop: uv_loop_t,
//    request: uv_getaddrinfo_t,
//    hostname: String,
//    port: String,
//    hints: addrinfo,
//    completionHandler: (getAddressInfoStruct: uv_getaddrinfo_t, status: Int, addrInfo: addrinfo))
//{
//
////    uv_getaddrinfo(&loop, &getAddressInfoStruct, getAddressInfoCallback, "0.0.0.0", "50000", &hints)
//
//
//}
//
//
//print("uv_run")
//uv_run(uv_default_loop(), UV_RUN_DEFAULT)