public with sharing class ClientResource {
    public String userName;
    public String password;
    public String token;
    
    public ClientResource(String u, String p, String t) {
        this.userName = u;
        this.password = p;
        this.token = t;
    }
}