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
            throw(type = "Invalid Lastname", message = "A lastname is required");
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
        return result;
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
            result = today & randr & suffix;
        } else {
            result = "Invalid suffix";
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
            throw(type = "Invalid Format", message = "Either of (cf, guid) is REQUIRED for this function, type specified:  " & format);
        }
        if (format == "guid") {
            result = insert("-", CreateUUID(), 23);
        } else {
            result = CreateUUID();
        }
        return result;
    }
}
