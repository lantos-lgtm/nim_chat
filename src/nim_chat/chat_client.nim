import 
    strutils,
    # async, asyncnet, asyncdispatch,
    threadpool, 
    net,
    chat_shared,
    std/sysrand,
    openssl,
    jsony

var
    counter: uint32

type
    Client* = object
        # socket: AsyncSocket
        socket: Socket
        host*:IpAddress
        port*: Port
        key: Key
        nonce: Nonce
        ctx: SslContext

# initialize the SSL context, verify selfsigned cert and then wrap the client socket with the ssl context.
proc initCTX(client: var Client, certFile: string) =
    client.ctx = newContext(certFile=certFile, verifyMode= CVerifyPeer)
    discard SSL_CTX_load_verify_locations(client.ctx.context, certFile , $client.host)
    client.ctx.wrapSocket(client.socket)

proc handleIncomingPacket(client: Client): bool =
    var line = client.socket.recvLine()
    if line.len == 0:
       return false
    var meta_message = line.passMetaMessage()
    counter = meta_message.message.cipherMessage(client.key)
    echo meta_message.message.message
    return true

proc sendMessage(client: Client, msg: string) =
    var meta_message: MetaMessage
    meta_message.message.message = msg 
    meta_message.message.nonce = client.nonce
    meta_message.message.counter = counter
    counter = meta_message.message.cipherMessage(client.key)
    client.socket.send(meta_message.toJson() & "\r\L")

proc incomingThread(client: Client) {.thread.} =
    while true:
        if not client.handleIncomingPacket():
            echo "[-] lost connection to server"
            break

proc outGoingThread(client: Client) {.thread.} =
    while true:
        var message = stdin.readLine()
        client.sendMessage(message)

proc startClient*(args: seq[string]) {.thread.} =
    var
        client: Client
        host: IpAddress
        port: Port 
        certFile = "cert.pem"
        key: string

    if args.len > 1:
        host = args[1].parseIpAddress()

    if args.len > 2:
        port = Port (args[2].parseInt())

    client.socket = newSocket()
    defer:
        client.socket.close()

    client.initCTX(certFile)
    client.socket.connect(address = $(host), port = port)
    echo "[+] server joined... at ": host

    while true:
        if key.len * 8 == 32 * 8:
            copyMem(client.key[0].addr, key[0].addr, 32)
            break
        echo "[!] please enter ", 32 - key.len, " bytes more bytes to make a 256 bit key"
        key = stdin.readLine()

    discard urandom(client.nonce)

    spawn incomingThread(client)
    spawn outGoingThread(client)
    sync()
