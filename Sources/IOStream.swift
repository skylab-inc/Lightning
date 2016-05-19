//
//  IOStream.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/1/16.
//
//

import Dispatch

public protocol IOStream {
    
    var fd: FileDescriptor { get }
    
    var loop: RunLoop { get }
    
    var channel: dispatch_io_t { get }
    
    
    // Listeners
    var readListeners: [(result: [UInt8]) -> ()] { get set }
    
    var writeListeners: [(unwrittenData: [UInt8]?) -> ()] { get set }
    
    var closeListeners: [(error: Error?) -> ()] { get set }
    
    var writingCompleteListeners: [(error: Error?) -> ()] { get set }
    
    
    // Callback registration
    
    /// Registering a callback with onRead will automatically begin the stream
    func onRead(_: (result: [UInt8]) ->()) -> IOStream
    
    func onClose(_: (error: Error?) -> ()) -> IOStream
    
    func onWrite(_: (unwrittenData: [UInt8]?) -> ()) -> IOStream
    
    func onWritingComplete(_: (error: Error?) -> ()) -> IOStream

    // Write
    func write(buffer: [UInt8])
    
}

extension IOStream {
    
    func dispatchRead(result: [UInt8]) {
        readListeners.forEach { listener in
            listener(result: result)
        }
    }
    
    func dispatchClose(error: Error?) {
        closeListeners.forEach { listener in
            listener(error: error)
        }
    }
    
    func dispatchWrite(unwrittenData: [UInt8]?) {
        writeListeners.forEach { listener in
            listener(unwrittenData: unwrittenData)
        }
    }
    
    func dispatchWritingComplete(error: Error?) {
        writingCompleteListeners.forEach { listener in
            listener(error: error)
        }
    }
    
}

public extension IOStream {
    
    public func onRead(_ read: (result: [UInt8]) ->()) -> IOStream {
        var stream = self
        stream.readListeners.append(read)
        return stream
    }
    
    public func onClose(_ close: (error: Error?) -> ()) -> IOStream {
        var stream = self
        stream.closeListeners.append(close)
        return stream
    }
    
    public func onWrite(_ write: (unwrittenData: [UInt8]?) -> ()) -> IOStream {
        var stream = self
        stream.writeListeners.append(write)
        return stream
    }
    
    public func onWritingComplete(_ writingComplete: (error: Error?) -> ()) -> IOStream {
        var stream = self
        stream.writingCompleteListeners.append(writingComplete)
        return stream
    }
    
    func startRead(minBytes: Int = 1) {
        dispatch_io_set_low_water(channel, minBytes);
        dispatch_io_read(channel, off_t(), size_t(INT_MAX), dispatch_get_main_queue()) { done, data, error in
            
            if let data = data {
                // First attempt to return the buffer
                var p = UnsafePointer<Void>(nil)
                var size: size_t = 0
                _ = dispatch_data_create_map(data, &p, &size)
                let buffer = Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(p), count: size))
                
                if buffer.count > 0 {
                    self.dispatchRead(result: buffer)
                }
            }
            
            if done {
                // Reading is complete, check for errors
                if error == 0 {
                    self.dispatchClose(error: nil)
                } else {
                    self.dispatchClose(error: Error(rawValue: error))
                }
            }
        }
    }
    
    public func write(buffer: [UInt8]) {
        buffer.withUnsafeBufferPointer { buffer in
            
            // Allocate dispatch data
            guard let dispatchData = dispatch_data_create(buffer.baseAddress, buffer.count, dispatch_get_main_queue(), nil) else {
                dispatchWritingComplete(error: .noMemory)
                return
            }
            
            // Schedule write operation
            dispatch_io_write(channel, off_t(), dispatchData, dispatch_get_main_queue()) { done, data, error in
                
                if let data = data {
                    
                    // Get unwritten data
                    var p = UnsafePointer<Void>(nil)
                    var size: size_t = 0
                    _ = dispatch_data_create_map(data, &p, &size)
                    let buffer = Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(p), count: size))
                    
                    if buffer.count > 0 {
                        self.dispatchWrite(unwrittenData: buffer)
                    } else {
                        self.dispatchWrite(unwrittenData: nil)
                    }
                    
                } else {
                    self.dispatchWrite(unwrittenData: nil)
                }
                
                if done {
                    // Writing is complete, check for errors
                    if error == 0 {
                        self.dispatchWritingComplete(error: nil)
                    } else {
                        self.dispatchWritingComplete(error: Error(rawValue: error))
                    }
                }
            }
        }
    }
}
