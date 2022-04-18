import 
    strutils,
    asyncnet, asyncdispatch,
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
        socket: AsyncSocket
        host*: IpAddress
        port*: Port
        key: Key
        nonce: Nonce
        ctx: SslContext

# initialize the SSL context, verify selfsigned cert and then wrap the client socket with the ssl context.
proc initCTX(client: var Client, certFile: string) =
    client.ctx = newContext(certFile=certFile, verifyMode= CVerifyPeer)
    discard SSL_CTX_load_verify_locations(client.ctx.context, certFile , $client.host)
    client.ctx.wrapSocket(client.socket)

proc handleIncomingPacket(client: Client): Future[bool] {.async.} =
    var line = await client.socket.recvLine()
    echo "blocked incoming"
    if line.len == 0:
       return false
    var meta_message = line.passMetaMessage()
    counter = meta_message.message.cipherMessage(client.key)
    echo meta_message.message.message
    return true

proc sendMessage(client: Client, msg: string) {.async.} =
    var meta_message: MetaMessage
    meta_message.message.message = msg 
    meta_message.message.nonce = client.nonce
    meta_message.message.counter = counter
    counter = meta_message.message.cipherMessage(client.key)
    await client.socket.send(meta_message.toJson() & "\r\L")

proc incoming(client: Client) {.async.} =
    while true:
        if not await client.handleIncomingPacket():
            echo "[-] lost connection to server"
            break

proc outGoing(client: Client) {.async.} =
    # this is broken
    # https://github.com/nim-lang/Nim/issues/11564
    var messageFV = spawn stdin.readLine()
    while true:
        if messageFV.isReady():
            await client.sendMessage(^messageFV)
            messageFV = spawn stdin.readLine()
        asyncdispatch.poll()

proc startClient*(args: seq[string]) {.async.} =
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

    client.socket = newAsyncSocket()
    defer:
        client.socket.close()

    client.initCTX(certFile)
    await client.socket.connect(address = $(host), port = port)
    echo "[+] server joined... at ": host

    # loop to prompt client for 128 bit key
    while true:
        if key.len * 8 == 32 * 8:
            copyMem(client.key[0].addr, key[0].addr, 32)
            break
        echo "[!] please enter ", 32 - key.len, " bytes more bytes to make a 256 bit key"
        key = stdin.readLine()
    # fill nonce with random bytes
    discard urandom(client.nonce)
    # main loops wait for client receiving and sending

    await all([incoming(client), outGoing(client)])