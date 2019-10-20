component displayname="database" author="Jason Everling" hint="A database utility" output="false"
{

    public function execQuery(required string stmt, required array params = [])
    {
        utils = CreateObject("component", "utils");
        sql = new query();
        sql.setDatasource(session.dsname);
        sql.SetName("sql");
        if (arrayIsDefined(params, 1)) {
            for (i = 1; i <= ArrayLen(params); i++) {
                pname = params[i][1];
                pvalue = params[i][2];
                if (arrayIsDefined(params[i], 3)) {
                    ptype = params[i][3];
                } else {
                    ptype = "varchar";
                }
                sql.addParam(name = pname, value = pvalue, cfsqltype = ptype);
            }
            result = sql.execute(sql = stmt).getResult();
        } else if (arrayIsEmpty(params)) {
            result = sql.execute(sql = stmt).getResult();
        } else {
            result = utils.createHttpMsg(400, "Bad Request", "Must be an array of arrays, example, [[your param, its value],[another param, its value]]");
        }
        return result;
    }
}