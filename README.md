# nim_chat

Simple chat that is written in mostly pure nim

# starting a server
## Docker
build the repo
```bash
docker build
```
then create key pairs
```bash
mkdir keys
cd keys
openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout key.pem -out cert.pem
```
then run the docker server
```bash
docker run -it --rm -p 1234:1234 -v $(pwd)/keys:/data nimchat start 0.0.0.0 1234 
```
## normal
```bash
mkdir keys
cd keys
openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout key.pem -out cert.pem
cd ..
nimble build
./bin/nimchat start 0.0.0.0 1234 
```

# Joining a Server

## normal
```bash
mkdir keys
cd keys
openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout key.pem -out cert.pem
cd ..
nimble build
./bin/nimchat connect 0.0.0.0 1234 
```
