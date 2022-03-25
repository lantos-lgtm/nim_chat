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

proc cipherMessage*(msg: var Message, key: Key): uint32 =
    if msg.message.len == 0:
        return msg.counter
    var
        m: seq[byte] = @[]
    m.setLen(msg.message.len())
    copyMem(m[0].addr, msg.message[0].addr, m.len)
    result = chacha20_cipher(key, msg.counter, msg.nonce, m)
    copyMem(msg.message[0].addr, m[0].addr, m.len)

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