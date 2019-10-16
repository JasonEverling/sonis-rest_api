component displayname="utils" author="Jason Everling" hint="Utility Functions for API processing" output="false"
{

    /**
     * Generates a new Sonis ID
     *
     * @lastname the persons last name
     * @author Jason A. Everling
     * @return integer the generated number
     */
    public function generateID(required string lastname)
    {

        if (len(rtrim(lastname)) == 0) {
            result = '{"Return Code": 401, "Details": "Invalid Lastname", "Extended": "A lastname is required"}';
        }
        sql = new query();
        sql.setDatasource("#session.dsname#");
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
     * @return integer the generated number
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
     * @return integer the generated number
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
}
