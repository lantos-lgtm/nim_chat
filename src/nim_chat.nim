
import 
    os,
    asyncdispatch,
    nim_chat/[chat_client, chat_server]

proc main(args: seq[string]) {.async.} =

    if args.len > 1:
        case args[0]
        of "start":
            await startServer(args)
        of "startl":
            await all([startServer(args), startClient(args)])
        of "connect":
            await startClient(args)

    echo """ 
[+] help
    > command ip port
    > start 0.0.0.0 1234
    > startl 0.0.0.0 1234
    > connect 0.0.0.0 1234
[!] WARNING THIS DOES NO NOT CHECK FOR POISENED MESSAGES
    """

waitFor main(commandLineParams())