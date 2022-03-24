
import 
    os, async,
    nim_chat/[chat_client, chat_server]

proc main(args: seq[string]) {.async.} =
    case args[0]
    of "start":
        asyncCheck startServer(args)
    of "connect":
        asyncCheck startClient(args)
    else:
        echo """ 
        > start 0.0.0.0
        > connect 0.0.0.0
        """

asyncCheck main(commandLineParams())