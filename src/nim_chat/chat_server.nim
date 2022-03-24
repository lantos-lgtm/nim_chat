import 
    strutils, os,
    threadpool, locks,
    net,
    chat_client

type
    Server* = object
        socket:Socket 
        host*:IpAddress
        port*: Port
        ctx: SslContext
        # clients: seq[Socket]
        counter: uint32

var 
    clientsLock : Lock
    clients: seq[Socket]
    # clientsChannel: Channel[seq[Socket]]

proc initCTX(server: var Server, certFile, keyFile: string) =
    server.ctx = newContext(certFile=certFile, keyFile=keyFile)
    server.ctx.wrapSocket(server.socket)

proc handleClient(client: Socket) {.thread.} =
    while true:
        var line = client.recvLine()
        if line.len == 0: 
            # client disconnected
            discard 
            line = "client disconnected"
 
        withLock(clientsLock):
            {.gcsafe.}:
            # echo clientsChannel.recv().len
                for client in clients:
                    client.send(line  &  "\r\L")
            

proc startServer*(args: seq[string]) {.thread.} =
    echo "[+] starting server..."
    var
        server:  Server
        certFile = "cert.pem"
        keyFile = "key.pem"
    if args.len > 1:
        server.host = args[1].parseIpAddress()

    if args.len > 2:
        server.port = Port (args[2].parseInt())

    if not (keyFile.fileExists() or certFile.fileExists()):
        echo "[-] keyFile or certFile not found"
        echo "please generate new keyFile or certFile with"
        echo "openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout " & keyFile & " -out " & certFile
        quit()

    server.socket = newSocket()
    server.socket.setSockOpt(OptReuseAddr, true)
    server.socket.setSockOpt(OptReusePort, true)
    server.socket.bindAddr(server.port, $(server.host))
    server.socket.listen()
    defer:
        server.socket.close()

    server.initCTX(certFile, keyFile)
    echo "[+] server started... listening at": server.socket.getLocalAddr()

    while true:
        var 
            clientAddr: string
            client: Socket
        server.socket.acceptAddr(client, clientAddr)
        echo "client connected to server from: " & $clientAddr
        # server.ctx.wrapConnectedSocket(client, handshakeAsServer)
        withLock(clientsLock):
            {.gcsafe.}:
                clients.add(client)
        spawn handleClient(client)