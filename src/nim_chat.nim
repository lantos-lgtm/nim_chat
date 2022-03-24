
import 
    os, threadpool, 
    nim_chat/[chat_client, chat_server]

proc main(args: seq[string]) {.thread.} =
    case args[0]
    of "start":
        spawn startServer(args)
        spawn startClient(args)
        sync()
    of "connect":
        spawn startClient(args)
        sync()
    else:
        echo """ 
        > start 0.0.0.0
        > connect 0.0.0.0
        """

main(commandLineParams())