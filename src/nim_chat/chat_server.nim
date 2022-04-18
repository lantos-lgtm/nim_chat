import 
    strutils, sequtils, strformat,
    asyncdispatch, asyncnet, net,
    os,
    tables

type
    Server* = object
        socket: AsyncSocket 
        host*: IpAddress
        port*: Port
        ctx: SslContext
        # clients: seq[AsyncSocket]
        counter: uint32

var 
    clients: TableRef[string, AsyncSocket] = newTable[string, AsyncSocket]() 

proc initCTX(server: var Server, certFile, keyFile: string) =
    server.ctx = newContext(certFile=certFile, keyFile=keyFile)
    server.ctx.wrapSocket(server.socket)

proc sendMessageToClients(line: string) {.async.}=
    for client in clients.values:
        await client.send(line  &  "\r\L")

proc handleClient(clientID: string, client: AsyncSocket) {.async.} =
    while true:
        var line = await client.recvLine()
        if line.len == 0: 
            # client disconnected
            line = fmt"[-] client ${clientID} disconnected"
            echo line
            clients.del(clientId)
            await sendMessageToClients(line)
            break
        await sendMessageToClients(line)
            
proc genClientID(clientID: string, count: int): string =
    var c = count
    {.gcsafe.}:
        echo clients.keys().toSeq()
        if clients.hasKey(clientID & ":" & $c):
            return genClientID(clientID, c + 1)
    return clientID & ":" & $c

proc startServer*(args: seq[string]) {.async.} =
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
        echo "[!] please generate new keyFile or certFile with"
        echo "[!] openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout " & keyFile & " -out " & certFile
        echo "[!] and bind them to docker container if needed"
        quit()

    server.socket = newAsyncSocket()
    server.socket.setSockOpt(OptReuseAddr, true)
    server.socket.setSockOpt(OptReusePort, true)
    server.socket.bindAddr(server.port, $(server.host))
    server.socket.listen()
    defer:
        server.socket.close()

    server.initCTX(certFile, keyFile)
    echo "[+] server started... listening at ": server.socket.getLocalAddr()

    # var fts: seq[Future[void]] = []
    while true:
        var 
            clientAddr: string
            client: AsyncSocket
        try:
            (clientAddr, client) = await server.socket.acceptAddr()
            clientAddr = genClientID(clientAddr, 0)
            echo "[+] client connected to server from: " & $clientAddr
            server.ctx.wrapConnectedSocket(client, handshakeAsServer)
            clients[clientAddr] = client
            asyncCheck handleClient(clientAddr, client)
        except:
            echo "[-] ", getCurrentExceptionMsg()