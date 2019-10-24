/**
* Name Functions
*
* @displayname Name
* @hint Functions related to the name table
* @author Jason A. Everling
*/
component extends="person" output="false"
{

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
            return session.objUtils.createHttpMsg(400, "Bad Request");
        }
        if (session.objUtils.isValidAttribute(attribute, "name")) {
            params = [["user", user],["attribute", attribute]];
            stmt = "OPEN SYMMETRIC KEY SSN_Key_01
                    DECRYPTION BY CERTIFICATE SSN
                    SELECT rtrim(" & attribute & ") as " & attribute & " " & "
                    FROM name " & where;
            result = session.objDB.execQuery(stmt, params);
        } else {
            result = session.objUtils.createHttpMsg(400, "Bad Request");
        }
        return result;
    }

    /**
    * Gets a persons name attributes
    *
    * @author Jason A. Everling
    * @user Username
    * @type Type of username, either soc_sec, ldap, or email
    * @attributes a comma-seperated list of attributes to get, i.e "attributes": "first_name, last_name"
    * @return string the value
    */
    public function getNameAttributes(required string user, required string type, required string attributes)
    {
        attributes = replaceNoCase(attributes, ', ',',', 'all');
        attrArray = listToArray(attributes, ',');
        if (type == "soc_sec") {
            where = "WHERE soc_sec = :user";
        } else if (type == "ldap") {
            where = "WHERE ldap_id = :user";
        } else if (type == "email") {
            where = "INNER JOIN address a ON name.soc_sec = a.soc_sec AND a.preferred = '1' WHERE a.email = :user";
        } else {
            return session.objUtils.createHttpMsg(400, "Bad Request");
        }
        validColumns = [];
        isValid = true;
        for (attribute in attrArray) {
            if (session.objUtils.isValidAttribute(attribute, "name")) {
                arrayAppend(validColumns,attribute);
            } else {
                isValid = false;
                break;
            }
        }
        if (isValid) {
            params = [["user", user]];
            stmt = "OPEN SYMMETRIC KEY SSN_Key_01
                    DECRYPTION BY CERTIFICATE SSN
                    SELECT " & arrayToList(validColumns) & " " & "
                    FROM name " & where;
            result = session.objDB.execQuery(stmt, params);
        } else {
            result = session.objUtils.createHttpMsg(400, "Invalid attribute specified");
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
            return session.objUtils.createHttpMsg(400, "Bad Request");
        }
        if (session.objUtils.isValidAttribute(attribute, "name")) {
            params = [["user", user],["attribute", attribute],["newvalue", newvalue]];
            stmt = "UPDATE name
                    SET " & attribute & " = :newvalue " & where & " SELECT @@RowCount AS affected";
            result = session.objDB.execQuery(stmt, params);
            if (result.affected > 0) {
                return session.objUtils.createHttpMsg(202, "Accepted");
            }
            return session.objUtils.createHttpMsg(204, "No Change");
        } else {
            return session.objUtils.createHttpMsg(400, "Bad Request");
        }
    }

    /**
    * Update a persons name attributes
    *
    * @author Jason A. Everling
    * @user Username
    * @type Type of username, either soc_sec, ldap, or email
    * @attributes a json array (with the value of 'attributes') of arrays in attribute: value format, i.e {"attributes": {"first_name": "John", "last_name": "Doe"}}
    * @return string the value
    */
    public function updateNameAttributes(required string user, required string type, required array attributes)
    {
        attributes = replacenocase(attributes, ', ',',', 'all');
        attrArray = listToArray(attributes, ',');
        if (type == "soc_sec") {
            where = "WHERE soc_sec = :user";
        } else if (type == "ldap") {
            where = "WHERE ldap_id = :user";
        } else if (type == "email") {
            where = "FROM name n INNER JOIN address a ON n.soc_sec = a.soc_sec AND a.preferred = '1' WHERE a.email = :user";
        } else {
            return session.objUtils.createHttpMsg(400, "Bad Request");
        }
        validColumns = [];
        isValid = true;
        for (attribute in attrArray) {
            if (session.objUtils.isValidAttribute(attribute, "name")) {
                arrayAppend(validColumns,attribute);
            } else {
                isValid = false;
                break;
            }
        }
        if (isValid) {
            params = [["user", user],["attribute", attribute],["newvalue", newvalue]];
            orig = "UPDATE name SET " & attribute & " = :newvalue " & where & " SELECT @@RowCount AS affected";
            stmt = "SELECT " & arrayToList(validColumns) & " " & "
                    FROM name " & where;
            result = session.objDB.execQuery(stmt, params);
        } else {
            result = session.objUtils.createHttpMsg(400, "Invalid attribute specified");
        }
        return result;
    }

}