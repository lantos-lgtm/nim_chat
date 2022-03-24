import 
    strutils,
    async, asyncnet, net,
    chat_server, chat_shared,
    openssl

type
    Client* = object
        socket: AsyncSocket
        host*:IpAddress
        port*: Port
        key: Key
        ctx: SslContext

# initialize the SSL context, verify selfsigned cert and then wrap the client socket with the ssl context.
proc initCTX(client: var Client, certFile: string) =
    client.ctx = newContext(certFile=certFile, verifyMode= CVerifyPeer)
    discard SSL_CTX_load_verify_locations(client.ctx.context, certFile ,"")
    client.ctx.wrapSocket(client.socket)

proc handleIncomingPacket(client: var Client) {.async.} =
    var line = await client.socket.recvLine()
    var meta_message = line.passMetaMessage()
    meta_message.message.cipherMessage(client.key)

proc startClient*(args: seq[string]) {.async.} =
    echo "[+] starting server..."
    var
        client: Client
        server: Server
        certFile = "cert.pem"

    if args.len > 1:
        server.host = args[1].parseIpAddress()

    if args.len > 2:
        server.port = Port (args[2].parseInt())

    client.initCTX(certFile)
    echo "[+] server joined... at": server.host

    while true:
        await client.handleIncomingPacket()