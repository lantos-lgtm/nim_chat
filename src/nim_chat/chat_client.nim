import 
    strutils,
    async, asyncnet, asyncdispatch,
    threadpool, thread,
    net,
    chat_shared,
    std/sysrand,
    openssl,
    jsony

var
    counter: uint32

type
    Client* = object
        socket: AsyncSocket
        host*:IpAddress
        port*: Port
        key: Key
        nonce: Nonce
        ctx: SslContext

# initialize the SSL context, verify selfsigned cert and then wrap the client socket with the ssl context.
proc initCTX(client: var Client, certFile: string) =
    client.ctx = newContext(certFile=certFile, verifyMode= CVerifyPeer)
    discard SSL_CTX_load_verify_locations(client.ctx.context, certFile ,"")
    client.ctx.wrapSocket(client.socket)

proc handleIncomingPacket(client: var Client) {.async.} =
    var line = await client.socket.recvLine()
    var meta_message = line.passMetaMessage()
    counter = meta_message.message.cipherMessage(client.key)

proc sendMessage(client: var Client, msg: string) {.async.} =
    var meta_message: MetaMessage
    meta_message.message.message = msg 
    meta_message.message.nonce = client.nonce
    meta_message.message.counter = meta_message.message.cipherMessage(client.key)
    counter = meta_message.message.counter
    await client.socket.send(meta_message.toJson() & "\r\L")

proc startClient*(args: seq[string]) {.async.} =
    echo "[+] starting server..."
    var
        client: Client
        host: IpAddress
        port: Port 
        certFile = "cert.pem"

    if args.len > 1:
        host = args[1].parseIpAddress()

    if args.len > 2:
        port = Port (args[2].parseInt())
    defer:
        client.socket.close()

    await client.socket.connect(address = $(host), port = port)
    client.initCTX(certFile)
    echo "[+] server joined... at": host

    while true:
        var key: string
        if key.len == 32:
            copyMem(client.key[0].addr, key[0].addr, 32)
            break
        echo "please enter ",32 - key.len, " bytes more bytes to make a key"
        key = stdin.readLine()

    discard urandom(client.nonce)

    var messageFlowVar = spawn stdin.readLine()
    while true:
        if messageFlowVar.isReady():
            asyncCheck client.sendMessage(^messageFlowVar)
        await client.handleIncomingPacket()