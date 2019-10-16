component displayname="login" author="Jason Everling" hint="Functions related to authentication" output="false"
{

    /**
     * Returns true or false if credentials are valid
     *
     * @author Jason A. Everling
     * @user Username
     * @password Password
     * @type Type of username, either soc_sec, ldap, or email
     * @credential Set to "security" if validating security credentials, blank otherwise
     * @return boolean true or false
     */
    public function verifyCredentials(required string user, required string password, required string type, string credential) returnFormat="json"
    {

        if (isAuthenticated) {
            isSecurity = false;
            if (credential == "security") {
                isSecurity = true;
            }
            sql = new query();
            sql.setDatasource("#session.dsname#");
            sql.SetName("sql");
            sql.addParam(name = "user", value = user, cfsqltype = "varchar");
            sql.addParam(name = "password", value = password, cfsqltype = "varchar");
            if (type == "soc_sec") {
                filter = "WHERE n.soc_sec = :user AND n.pin = :password AND n.disabled = '0'";
            } else if (type == "ldap") {
                filter = "WHERE n.ldap_id = :user AND n.pin = :password AND n.disabled = '0'";
            } else if (type == "email") {
                filter = "INNER JOIN address a ON n.soc_sec = a.soc_sec AND a.preferred = '1' WHERE a.e_mail = :user AND n.pin = :password AND n.disabled = '0'";
            } else {
                return false;
            }
            stmt = "SELECT n.soc_sec, n.disabled, CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, n.PIN)) AS pin FROM name n " & filter;
            if (isSecurity) {
                stmt = "SELECT s.user_id, s.disabled, CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, s.password)) AS password
                        FROM security s
                        WHERE s.user_id = :user AND CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, s.password)) = :password AND s.disabled = '0'";
            }
            result = sql.execute(sql = stmt).getResult();
            if (result.affected > 0) {
                return true;
            }
            return false;
        }
        return {"Error": "Invalid Credentials"};
    }

    /**
    * Returns true or false if api token is valid, follows api* pattern
    *
    * @author Jason A. Everling
    * @token API Token, can either be sent in body or header
    * @return boolean true or false
    */
    public function apiAuthorization(required string token)
    {

        if (len(rtrim(token)) == 0) {
            throw(type = "Invalid Token", message = "Token is required");
        }
        sql = new query();
        sql.setDatasource("#session.dsname#");
        sql.SetName("sql");
        sql.addParam(name="token",value=token,cfsqltype="varchar");
        stmt = "SELECT s.user_id, s.disabled
                FROM security s
                WHERE s.user_id LIKE 'api%' AND CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, s.password)) = :token AND s.disabled = '0'";
        result = sql.execute(sql=stmt).getResult();
        if (result.RecordCount > 0) {
            return true;
        }
        return false;
    }
}
