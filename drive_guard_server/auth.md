package for auth: https://pkg.go.dev/github.com/golang-jwt/jwt#pkg-overview

server is responsible for issuing tokens on sign in, and parsing and validating them on an action


standard claim defintions can be found here: https://datatracker.ietf.org/doc/html/rfc7519#section-4.1


auth todos 

- [ ] fix the claims 
    - add expiration time 
    - make sure the signing works 
    - etc 
- [ ] impl refresh tokens (clients getting new tokens after they expire) 
- [ ] maybe add MAC addresses to the claim?
- [ ] https for web server

