component displayname="name" author="Jason Everling" hint="Functions related to the name table" output="false"
{

    db = CreateObject("component", "database");
    utils = CreateObject("component", "utils");

    /**
    * Gets a persons name attribute
    *
    * @author Jason A. Everling
    * @user Username
    * @type Type of username, either soc_sec, ldap, or email
    * @attribute The attribute being retrieved
    * @return string the value
    */
    public function getNameAttribute(required string user, required string type, required string attribute)
    {
        if (type == "soc_sec") {
            where = "WHERE soc_sec = :user";
        } else if (type == "ldap") {
            where = "WHERE ldap_id = :user";
        } else if (type == "email") {
            where = "INNER JOIN address a ON name.soc_sec = a.soc_sec AND a.preferred = '1' WHERE a.email = :user";
        } else {
            return utils.createHttpMsg(400, "Bad Request");
        }
        if (utils.isValidAttribute(attribute, "name")) {
            params = [["user", user],["attribute", attribute]];
            stmt = "OPEN SYMMETRIC KEY SSN_Key_01
                    DECRYPTION BY CERTIFICATE SSN
                    SELECT rtrim(" & attribute & ") as " & attribute & " " & "
                    FROM name " & where;
            result = db.execQuery(stmt, params);
        } else {
            result = utils.createHttpMsg(400, "Bad Request");
        }
        return result;
    }

    /**
    * Updates a persons name attribute
    *
    * @author Jason A. Everling
    * @user Username
    * @type Type of username, either soc_sec, ldap, or email
    * @attribute The attribute being updated
    * @value The attribute value
    * @return boolean
    */
    public function updateNameAttribute(required string user, required string type, required string attribute, required string newvalue)
    {
        if (type == "soc_sec") {
            where = "WHERE soc_sec = :user";
        } else if (type == "ldap") {
            where = "WHERE ldap_id = :user";
        } else if (type == "email") {
            where = "FROM name n INNER JOIN address a ON n.soc_sec = a.soc_sec AND a.preferred = '1' WHERE a.email = :user";
        } else {
            return utils.createHttpMsg(400, "Bad Request");
        }
        if (utils.isValidAttribute(attribute, "name")) {
            params = [["user", user],["attribute", attribute],["newvalue", newvalue]];
            stmt = "UPDATE name
                    SET " & attribute & " = :newvalue " & where & " SELECT @@RowCount AS affected";
            result = db.execQuery(stmt, params);
            if (result.affected > 0) {
                return utils.createHttpMsg(202, "Accepted");
            }
            return utils.createHttpMsg(204, "No Change");
        } else {
            return utils.createHttpMsg(400, "Bad Request");
        }
    }

}