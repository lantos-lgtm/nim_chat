
import 
    os, threadpool, 
    nim_chat/[chat_client, chat_server]

proc main(args: seq[string]) {.thread.} =

    if args.len > 1:
        case args[0]
        of "start":
            spawn startServer(args)
            sync()
            return
        of "startl":
            spawn startServer(args)
            spawn startClient(args)
            sync()
        of "connect":
            spawn startClient(args)
            sync()
            return

    echo """ 
[+] help
    > command ip port
    > start 0.0.0.0 1234
    > startl 0.0.0.0 1234
    > connect 0.0.0.0 1234
[!] WARNING THIS DOES NO NOT CHECK FOR POISENED MESSAGES
    """

main(commandLineParams())