<p align="center">
<img src="https://cloud.githubusercontent.com/assets/6432361/15267819/634be4ee-1981-11e6-9ad6-71f47c633e50.png" width="224" alt="Edge">
<br/>Serverside non-blocking IO <b>in Swift</b><br/>
Ask questions on our <a href="https://swiftedge.slack.com">Slack</a>!<br/>
</p>


# Edge
Edge is an HTTP Server and TCP Client/Server framework written in Swift and inspired by Node.js. It runs on both OS X and Linux. Like Node.js, Edge uses an event-driven, non-blocking I/O model. In the same way that Node.js uses [libuv](http://libuv.org) to implement this model, Edge uses [libdispatch](https://github.com/apple/swift-corelibs-libdispatch). 

This makes Edge fast and efficient, but it also means that Edge applications can naturally make use of libdispatch to easily offload heavy processing to a background thread.

# Installation

Edge is available as a Swift 3 package (No current 2.2 support). Simply add Edge as a dependency to your Swift Package.

```Swift
import PackageDescription

let package = Package(
    name: "MyProject",
    dependencies: [
        .Package(url: "https://github.com/TheArtOfEngineering/Edge.git", majorVersion: 0, minor: 0)
    ]
)
```

# Usage

### TCP
```Swift
import Edge
import Foundation

let loop = RunLoop()
var server = TCPServer(loop: loop)
    
try server.bind(host: "0.0.0.0", port: 50000)
    
try server.listen { clientConnection in
    clientConnection.read(onRead: { buffer in
        let message = String(bytes: buffer, encoding: NSUTF8StringEncoding)!
        print("Client says \(message)!")
    }, onComplete: { error in
        print("Oh, no!")
    }
}
  
RunLoop.runAll()
```


### Edge is not Node.js

Edge is not meant to fulfill all of the roles of Node.js. Node.js is a JavaScript runtime, while Edge is a TCP/Web server framework. The Swift compiler and package manager, combined with third-party Swift packages, make it uncessary to build that functionality into Edge.
