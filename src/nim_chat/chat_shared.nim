import 
    ../constantine/constantine/ciphers/chacha20,
    jsony

type
    Key* =  array[32, byte]
    Nonce* = array[12, byte]
    Message* = object
        nonce*: Nonce
        counter*: uint32
        message*: string
    MetaMessage* = object
        client, server: string
        message*: Message
        counter*: uint32

proc cipherMessage*(msg: var Message, key: Key): uint32 =
    chacha20_cipher(key, msg.counter, msg.nonce, msg.message)

proc passMetaMessage*(msg: string): MetaMessage =
    try:
        result = msg.fromJson(MetaMessage)
    except:
        echo "[-]failed to pass packet"
        echo msg

proc buildMessage*(msg: MetaMessage): string =
    try:
        result = msg.toJson()
    except:
        echo "[-]failed to build message"