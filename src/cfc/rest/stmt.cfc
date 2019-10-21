/**
* SQL Statement Utility
*
* @displayname Stmt
* @hint Custom data requests using sql statements
* @author Jason A. Everling
*/
component output="false"
{

    /**
    * Run a raw sql query against the datasource,
    * drop, truncate, and semi-colons are not allowed.
    *
    * @sqlcmd a valid sql query
    * @author Jason A. Everling
    * @return query the query results
    */
    public function run(required string sql) {
        stmt = new query();
        stmt.setDatasource("#session.dsname#");
        stmt.SetName("stmt");
        qry = replaceNoCase(sql, ';', '', 'all');
        qry = replaceNoCase(qry, 'ALTER', '', 'all');
        qry = replaceNoCase(qry, 'DROP', '', 'all');
        qry = replaceNoCase(qry, 'TRUNCATE', '', 'all');
        result = stmt.execute(sql = qry).getResult();
        return result;
    }
}