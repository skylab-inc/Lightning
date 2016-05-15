//
//  IOStream.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/1/16.
//
//

import Dispatch

public protocol IOStream {
    
    var fd: FileDescriptor {
        get
    }
    
    var loop: RunLoop {
        get
    }
    
    var channel: dispatch_io_t { get }
    
    func read(minBytes: Int, onRead: (result: [UInt8]) -> (), onComplete: (error: Error?) -> ())
    
    func write(buffer: [UInt8], onWrite: ((unwrittenData: [UInt8]?) -> ())?, onComplete: ((error: Error?) -> ())?)
    
}

public extension IOStream {
    
    public func read(minBytes: Int = 1, onRead: (result: [UInt8]) -> (), onComplete: (error: Error?) -> ()) {
        dispatch_io_set_low_water(channel, minBytes);
        dispatch_io_read(channel, off_t(), size_t(INT_MAX), dispatch_get_main_queue()) { done, data, error in
            
            if let data = data {
                
                // First attempt to return the buffer
                var p = UnsafePointer<Void>(nil)
                var size: size_t = 0
                _ = dispatch_data_create_map(data, &p, &size)
                let buffer = Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(p), count: size))
                
                if buffer.count > 0 {
                    onRead(result: buffer)
                }
            }
            
            if done {
                // Reading is complete, check for errors
                if error == 0 {
                    onComplete(error: nil)
                } else {
                    onComplete(error: Error(rawValue: error))
                }
            }
        }
    }
    
    public func write(buffer: [UInt8], onWrite: ((unwrittenData: [UInt8]?) -> ())? = nil, onComplete: ((error: Error?) -> ())? = nil) {
        buffer.withUnsafeBufferPointer { buffer in
            
            // Allocate dispatch data
            guard let dispatchData = dispatch_data_create(buffer.baseAddress, buffer.count, dispatch_get_main_queue(), nil) else {
                onComplete?(error: .noMemory)
                return
            }
            
            // Schedule write operation
            dispatch_io_write(channel, off_t(), dispatchData, dispatch_get_main_queue()) { done, data, error in
                
                if let onWrite = onWrite, data = data {
                    
                    // Get unwritten data
                    var p = UnsafePointer<Void>(nil)
                    var size: size_t = 0
                    _ = dispatch_data_create_map(data, &p, &size)
                    let buffer = Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(p), count: size))
                    
                    if buffer.count > 0 {
                        onWrite(unwrittenData: buffer)
                    } else {
                        onWrite(unwrittenData: nil)
                    }
                }
                
                if done {
                    // Writing is complete, check for errors
                    if error == 0 {
                        onComplete?(error: nil)
                    } else {
                        onComplete?(error: Error(rawValue: error))
                    }
                }
            }
        }
    }
}
