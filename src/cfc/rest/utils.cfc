/**
* Utility Functions
*
* @displayname Utils
* @hint Various utilities that can be reused in various functions
* @author Jason A. Everling
*/
component output="false"
{

    /**
    * Returns an http error code message in JSON format
    *
    * @code the error code
    * @details the The message detail
    * @extended more information regarding the error
    * @author Jason A. Everling
    * @return numeric the generated number
    */
    public function createHttpMsg(required numeric code, required string details, string extended = "")
    {
        if (extended == '') {
            result = '{"Return Code": "' & code & '", "Details": "' & details & '"}';
        } else {
            result = '{"Return Code": "' & code & '", "Details": "' & details & '", "Extended": "' & extended & '"}';
        }
        return result;
    }

    /**
     * Generates a new Sonis ID
     *
     * @lastname the persons last name
     * @author Jason A. Everling
     * @return numeric the generated number
     */
    public function generateID(required string lastname)
    {

        if (len(rtrim(lastname)) == 0) {
            result = '{"Return Code": 401, "Details": "Invalid Lastname", "Extended": "A lastname is required"}';
        }
        sql = new query();
        sql.setDatasource(session.dsname);
        sql.SetName("sql");
        ln = left(ucase(lastname),2);
        matched = true;
        while (matched)
        {
            sonisid = ln & RandRange(1000000, 9999000);
            stmt = "SELECT soc_sec FROM name WHERE rtrim(soc_sec) = ':sonisid'";
            sql.addParam(name="sonisid",value=sonisid,cfsqltype="varchar");
            matcher = sql.execute(sql=stmt).getResult();
            if (matcher.recordcount EQ 0) {
                matched = false;
            }
        }
        result = sonisid;
        return '{"NewID": "' & result & '"}';
    }

    /**
     * Generates a random _rid for use in tables
     *
     * @suffix Either a 0 or 1 suffixed to number to match Sonis rid's
     * @author Jason A. Everling
     * @return numeric the generated number
     */
    public function generateRID(required string suffix)
    {
        today = dateformat(now(),'yymmdd');
        randr = RandRange(100000000, 999999999);
        if (suffix == "0" or suffix == "1") {
            rid = today & randr & suffix;
            result = '{"NewRID": "' & rid & '"}';
        } else {
            result = '{"Return Code": 401, "Details": "Invalid suffix"}';
        }
        return result;
    }

    /**
     * Generates a random uuid value
     *
     *
     * @format string either cf or guid format, defaults to cf
     * @author Jason A. Everling
     * @return numeric the generated number
     */
    public function generateUUID(required string format)
    {
        result = "";
        if (rtrim(lower(format)) == "cf" or not rtrim(lower(format)) == "guid") {
            result = '{"Return Code": 401, "Details": "Invalid Format", "Extended": "Either of (cf, guid) is REQUIRED for this function, type specified:  "' & format & '}';
        }
        if (format == "guid") {
            newguid = insert("-", CreateUUID(), 23);
            result = '{"NewGUID": "' & newguid & '"}';
        } else {
            newuuid = CreateUUID();
            result = '{"NewUUID": "' & newuuid & '"}';
        }
        return result;
    }

    /**
    * Converts a list to struct, a sister to listToArray
    *
    * @list A list of key=value pairs separated by a semi-colon
    * @author Jason A. Everling
    * @return struct the generated struct
    */
    public function listToStruct(required string list)
    {
        result = {};
        item = 0;
        delimiter = ";";
        tmpList = arrayNew(1);
        if (ArrayLen(arguments) > 1) {
            delimiter = arguments[2];
        }
        tmpList = listToArray(list, delimiter);
        for (item = 1; item <= ArrayLen(tmpList); item = item + 1) {
            if (!structkeyexists(result, trim(ListFirst(tmpList[item], "=")))) {
                StructInsert(result, trim(ListFirst(tmpList[item], "=")), trim(ListLast(tmpList[item], "=")));
            }
        }
        return result;
    }

    /**
    * Determines if the 'attribute' passed is a valid column name with the table
    *
    * @attribute the column name
    * @table the table name to check
    * @author Jason A. Everling
    * @return boolean
    */
    public function isValidAttribute(required string attribute, required string table)
    {
        validColumn = false;
        qry = session.objDB.execQuery("SELECT TOP 1 * FROM " & table);
        columnNames = qry.ColumnList;
        validColumn = listFind(columnNames, uCase(attribute));
        if (validColumn > 0) {
            return true;
        }
        return false;
    }

    /**
    * Removes a specified 'amount' of characters from a strings end
    *
    * @value string to be cut
    * @amount amount to be cut by starting from the right
    * @author Jason A. Everling
    * @return string the new value
    */
    public function cutString(required string value, required numeric amount)
    {
        value = rtrim(value);
        result = left(value, len(value) - amount);
        return result;
    }
}
