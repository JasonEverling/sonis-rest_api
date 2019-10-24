/**
* Authentication Functions
*
* @displayname Login
* @hint Functions related to authentication
* @author Jason A. Everling
*/
component output="false"
{

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
        stmt = "SELECT s.user_id, s.disabled
                FROM security s
                WHERE s.user_id = :user AND CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, s.password)) = :token AND s.disabled = '0'";
        params = [["user", session.apiUser],["token", token]];
        result = session.objDB.execQuery(stmt, params);
        if (result.RecordCount > 0) {
            return true;
        }
        return false;
    }

    /**
    * Disables an account login
    *
    * @author Jason A. Everling
    * @user The account to be disabled
    * @return boolean true or false
    */
    public function disableLogin(required string user)
    {
        error = false;
        params = [["user", user]];
        stmt = "UPDATE security SET disabled = 1 WHERE user_id = :user";
        try {
            session.objDB.execQuery(stmt, params);
        } catch (any e) {
            error = true;
        }
        if (error == false) {
            return true;
        }
        return false;
    }

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
    public function verifyCredentials(required string user, required string password, required string type, string credential = "")
    {

        isSecurity = false;
        if (credential == "security") {
            isSecurity = true;
        }
        if (type == "soc_sec") {
            where = "WHERE n.soc_sec = :user AND n.pin = :password AND n.disabled = '0'";
        } else if (type == "ldap") {
            where = "WHERE n.ldap_id = :user AND n.pin = :password AND n.disabled = '0'";
        } else if (type == "email") {
            where = "INNER JOIN address a ON n.soc_sec = a.soc_sec AND a.preferred = '1' WHERE a.e_mail = :user AND n.pin = :password AND n.disabled = '0'";
        } else {
            return false;
        }
        params = [["user", session.apiUser],["password", password]];
        stmt = "SELECT n.soc_sec, n.disabled, CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, n.PIN)) AS pin FROM name n " & where;
        if (isSecurity) {
            stmt = "SELECT s.user_id, s.disabled, CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, s.password)) AS password
                    FROM security s
                    WHERE s.user_id = :user AND CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, s.password)) = :password AND s.disabled = '0'";
        }
        result = session.objDB.execQuery(stmt, params);
        if (result.RecordCount > 0) {
            return true;
        }
        return false;
    }
}
