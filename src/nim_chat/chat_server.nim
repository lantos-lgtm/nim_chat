import strutils, os
import async, asyncnet, net

type
    Server* = object
        socket: AsyncSocket
        host*:IpAddress
        port*: Port
        ctx: SslContext


proc initCTX(server: var Server, certFile, keyFile: string) =
    server.ctx = newContext(certFile=certFile, keyFile=keyFile)
    server.ctx.wrapSocket(server.socket)

proc handleClient(server: Server, client: AsyncSocket) {.async.} =
    discard

proc startServer*(args: seq[string]) {.async.} =
    echo "[+] starting server..."
    var
        server: Server
        certFile = "cert.pem"
        keyFile = "key.pem"

    if args.len > 1:
        server.host = args[1].parseIpAddress()

    if args.len > 2:
        server.port = Port (args[2].parseInt())

    if not (keyFile.fileExists() or certFile.fileExists()):
        echo "[-] keyFile or certFile not found"
        echo "generate with"
        echo "openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout " & keyFile & " -out " & certFile

    server.socket = newAsyncSocket()
    server.socket.setSockOpt(OptReuseAddr, true)
    server.socket.setSockOpt(OptReusePort, true)
    server.socket.bindAddr(server.port, $(server.host))
    server.socket.listen()

    server.initCTX(certFile, keyFile)
    echo "[+] server started... listening at": server.socket.getLocalAddr()

    while true:
        var (clientAddr, client) = await server.socket.acceptAddr()
        echo "client connected to server from: " & $clientAddr
        server.ctx.wrapConnectedSocket(client, handshakeAsServer)
        asyncCheck server.handleClient(client)
