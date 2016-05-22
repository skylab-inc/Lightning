//
//  IOStream.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 5/1/16.
//
//

import Dispatch
import RxSwift

public protocol WritableIOStream: class {
    
    var fd: FileDescriptor { get }
    
    var loop: RunLoop { get }
    
    var channel: dispatch_io_t { get }
    
    func write(buffer: [UInt8]) -> Observable<[UInt8]>

}

public extension WritableIOStream {
    
    func write(buffer: [UInt8]) -> Observable<[UInt8]> {
        return Observable.create { (observer) -> Disposable in
            buffer.withUnsafeBufferPointer { buffer in
                
                // Allocate dispatch data
                guard let dispatchData = dispatch_data_create(buffer.baseAddress, buffer.count, dispatch_get_main_queue(), nil) else {
                    // Emit error as the channel was never open.
                    observer.onError(error: Error.noMemory)
                    return
                }
                
                // Schedule write operation
                dispatch_io_write(self.channel, off_t(), dispatchData, dispatch_get_main_queue()) { done, data, error in
                    
                    if error != 0 {
                        // If there was an error emit the error.
                        observer.onError(error: Error(rawValue: error))
                    }
                    
                    log.debug(data)
                    if let data = data where data !== dispatch_data_empty {
                        // Get unwritten data
                        var p = UnsafePointer<Void>(nil)
                        var size: size_t = 0
                        _ = dispatch_data_create_map(data, &p, &size)
                        let buffer = Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(p), count: size))
                        
                        // Emit the unwritten data as next
                        observer.onNext(element: buffer)
                    }
                    
                    if done {
                        if error == 0 {
                            // If the done param is set and there is no error,
                            // all data has been written, emit writing end.
                            // DO NOT emit end otherwise!
                            observer.onCompleted()
                        } else {
                            // Must be an unrecoverable error, close the channel.
                            // TODO: Maybe don't close if you want half-open channel
                            dispatch_io_close(self.channel, 0)
                        }
                    }
                }
            }
            return AnonymousDisposable {
                dispatch_io_close(self.channel, 0)
            }
        }
    }
}


public protocol ReadableIOStream: class {
    
    var fd: FileDescriptor { get }
    
    var loop: RunLoop { get }
    
    var channel: dispatch_io_t { get }

    func read(minBytes: Int) -> Observable<[UInt8]>
    
}

public extension ReadableIOStream {
    
    func read(minBytes: Int = 1) -> Observable<[UInt8]> {
        return Observable.create { (observer) -> Disposable in
            dispatch_io_set_low_water(self.channel, minBytes);
            dispatch_io_read(self.channel, off_t(), size_t(INT_MAX), dispatch_get_main_queue()) { done, data, error in
                
                if error != 0 {
                    // If there was an error emit the error.
                    observer.onError(error: Error(rawValue: error))
                }
                
                // Deliver data if it is non-empty
                log.verbose("Read data: " + String(data))
                if let data = data where data !== dispatch_data_empty {
                    var p = UnsafePointer<Void>(nil)
                    var size: size_t = 0
                    _ = dispatch_data_create_map(data, &p, &size)
                    let buffer = Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(p), count: size))
                    
                    observer.onNext(element: buffer)
                }

                if done {
                    if error == 0 {
                        // If the done param is set and there is no error,
                        // all data has been read, emit end.
                        // DO NOT emit end otherwise!
                        observer.onCompleted()
                    }
                    
                    // It's done close the channel
                    // TODO: Maybe don't close if you want half-open channel
                    dispatch_io_close(self.channel, 0)
                }
            }
            return AnonymousDisposable {
                dispatch_io_close(self.channel, 0)
            }
        }
    }
}
