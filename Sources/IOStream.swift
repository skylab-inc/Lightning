//
//  IOStream.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/1/16.
//
//

import Foundation

public protocol IOStream {
    
    var fd: FileDescriptor {
        get
    }
    
    var loop: RunLoop {
        get
    }
    
    var readChannel: dispatch_io_t { get set }
    
    func read(minBytes: Int, onRead: (buffer: UnsafeBufferPointer<Int8>) -> ())
    
    func write(buffer: UnsafeBufferPointer<Int8>, onWrite: (() -> ())?)
    
}

public extension IOStream {
    
    public func read(minBytes: Int = 1, onRead: (buffer: UnsafeBufferPointer<Int8>) -> ()) {
        let readingChannel = dispatch_io_create(DISPATCH_IO_STREAM, fd.rawValue, dispatch_get_main_queue()) { error in
            if error != 0 {
                print("Error: \(error)")
            }
        }
        dispatch_io_set_low_water(readingChannel, minBytes);
        dispatch_io_read(readingChannel, off_t(), size_t(INT_MAX), dispatch_get_main_queue()) { done, data, error in
            if error != 0 {
                print("Error: \(error)")
            }
            if done {
                return
            }
            _ = readingChannel
            var p = UnsafePointer<Void>(nil)
            var size: size_t = 0
            _ = dispatch_data_create_map(data, &p, &size)
            let buffer = UnsafeBufferPointer<Int8>(start: UnsafePointer<Int8>(p), count: size)
            onRead(buffer: buffer)
        }
    }
    
    public func write(buffer: UnsafeBufferPointer<Int8>, onWrite: (() -> ())? = nil) {
        let writeChannel = dispatch_io_create(DISPATCH_IO_STREAM, fd.rawValue, dispatch_get_main_queue()) { error in
            if error != 0 {
                print("Error: \(error)")
            }
        }
        let dispatchData = dispatch_data_create(buffer.baseAddress, buffer.count, dispatch_get_main_queue(), nil)
        dispatch_io_write(writeChannel, off_t(), dispatchData, dispatch_get_main_queue()) { done, data, error in
            if error != 0 {
                print("Error: \(error)")
            }
            onWrite?()
            if done {
                return
            }
            _ = writeChannel
        }
    }
}
