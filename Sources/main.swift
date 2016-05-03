//
//  main.swift
//  Edge
//
//  Created by Tyler Fleming Cloutier on 4/17/16.
//
//

let loop = RunLoop()
var server = TCPServer(loop: loop)
var clientServers = [TCPServer]()

try server.bind(host: "localhost", port: 50000)
try server.listen { clientConnection in
    clientServers.append(clientConnection)
    clientConnection.read { buffer in
        print(String(cString: buffer.baseAddress!))
    }
}

let stdin = Pipe(loop: loop, fd: .stdin)
stdin.read { buffer in
    clientServers.forEach { server in
        server.write(buffer: buffer)
    }
}

RunLoop.runAll()