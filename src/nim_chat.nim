
# import 
#     os, threadpool,
#     nim_chat/[chat_client, chat_server]

# proc main(args: seq[string]) {.thread.} =
#     case args[0]
#     of "start":
#         spawn startServer(args)
#         spawn startClient(args)
#         sync()
#     of "connect":
#         spawn startClient(args)
#         sync()
#     else:
#         echo """ 
#         > start 0.0.0.0
#         > connect 0.0.0.0
#         """

# main(commandLineParams())

import os, threadpool, net, openssl

proc handle(client: Socket) {.thread.} =
    while true:
        var line = client.recvLine()
        echo line

proc clientThread() {.thread.} =
    var
        socket = newSocket()
        ctx = newContext(certFile= "cert.pem", verifyMode=CVerifyPeer)
    ctx.wrapSocket(socket)
    discard SSL_CTX_load_verify_locations(ctx.context, "cert.pem", "127.0.0.1")
    socket.connect("127.0.0.1", Port(1234))

    while true:
        socket.send("Hello, world!" & "\r\L")
    
proc severThread(){.thread.} =
    var
        socket = newSocket()
        ctx: SslContext
    
    socket.setSockOpt(OptReuseAddr, true)
    socket.setSockOpt(OptReusePort, true)
    socket.bindAddr( Port(1234), "127.0.0.1")
    socket.listen() 
    ctx = newContext(certFile = "cert.pem", keyFile = "key.pem")
    ctx.wrapSocket(socket)


    while true:
        var
            client = newSocket()
            clientAddr = ""
        socket.acceptAddr(client, clientAddr)
        echo client.isSsl()
        # ctx.wrapConnectedSocket(client, handshakeAsServer)
        spawn handle(client)

proc main()  =
    spawn severThread()
    spawn clientThread()

    sync()

main()