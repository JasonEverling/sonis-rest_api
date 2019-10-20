component displayname="name" author="Jason Everling" hint="Functions related to the name table" output="false"
{

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
            filter = "WHERE soc_sec = :user";
        } else if (type == "ldap") {
            filter = "WHERE ldap_id = :user";
        } else if (type == "email") {
            filter = "INNER JOIN address a ON name.soc_sec = a.soc_sec AND a.preferred = '1' WHERE a.email = :user";
        } else {
            return utils.createHttpMsg(400, "Bad Request");
        }
        sql = new query();
        sql.setDatasource(session.dsname);
        sql.SetName("sql");
        sql.addParam(name = "user", value = user, cfsqltype = "varchar");
        sql.addParam(name = "attribute", value = attribute, cfsqltype = "varchar");
        columnNames = sql.execute(sql = "SELECT TOP 1 * FROM name").getResult().ColumnList;
        validColumn = listFind(columnNames, uCase(attribute));
        if (validColumn > 0) {
            stmt = "OPEN SYMMETRIC KEY SSN_Key_01
                    DECRYPTION BY CERTIFICATE SSN
                    SELECT rtrim(" & attribute & ") as " & attribute & " " & "
                    FROM name " & filter;
            result = sql.execute(sql = stmt).getResult();
        } else {
            result = utils.createHttpMsg(400, "Bad Request");
        }
        return result;
    }
    /**
    * Updates a persons attribute
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
            filter = "WHERE soc_sec = :user";
        } else if (type == "ldap") {
            filter = "WHERE ldap_id = :user";
        } else if (type == "email") {
            filter = "FROM name n INNER JOIN address a ON n.soc_sec = a.soc_sec AND a.preferred = '1' WHERE a.email = :user";
        } else {
            return utils.createHttpMsg(400, "Bad Request");
        }
        sql = new query();
        sql.setDatasource(session.dsname);
        sql.SetName("sql");
        sql.addParam(name = "user", value = user, cfsqltype = "varchar");
        sql.addParam(name = "attribute", value = attribute, cfsqltype = "varchar");
        sql.addParam(name = "newvalue", value = newvalue, cfsqltype = "varchar");
        columnNames = sql.execute(sql = "SELECT TOP 1 * FROM name").getResult().ColumnList;
        validColumn = listFind(columnNames, uCase(attribute));
        if (validColumn > 0) {
            stmt = "UPDATE name
                    SET " & attribute & " = :newvalue " & filter & " SELECT @@RowCount AS affected";
            result = sql.execute(sql = stmt).getResult();
            if (result.affected > 0) {
                return utils.createHttpMsg(202, "Accepted");
            }
            return utils.createHttpMsg(204, "No Change");
        } else {
            return utils.createHttpMsg(400, "Bad Request");
        }
    }
}