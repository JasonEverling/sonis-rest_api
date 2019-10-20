component displayname="soapsql" author="Jason Everling" hint="Sonis SOAP SQL Endpoint" output="false"
{

    this.utils = CreateObject("component", "CFC.rest.utils");
    this.objLogin = CreateObject("component", "CFC.rest.login");
    this.objValid = CreateObject("component", "CFC.rest.validate");

    /**
    * Sonis SOAP SQL runner
    *
    * @author Jason A. Everling
    * @user api username
    * @pass api password
    * @sql sql statement, you are responsible for injection prevention
    * @todo Create better injection detection so were not relying on the client
    * @return array|mixed the sql results
    */
    remote any function doSQLSomething(required string user="", required string pass="", required string sql="") output=false {
        try {
            include "../../application.cfm";
            this.objValid.validateSession();
            session.dsname = sonis.ds;
            session.apiUser = lCase(user);
            this.apiToken = pass;
            this.sql = sql;
            if (!isDefined('session.retries')) {
                session.retries = 0;
            }

            // Begin authorization sequence
            isAuthenticated = this.objLogin.apiAuthorization(this.apiToken);
            if (session.retries >= webopt.login_retries) {
                locked = this.objLogin.disableLogin(session.apiUser);
                if (!locked) {
                    throw(type = "Expectation Failed", message = "Please contact the site administrator");
                }
            }
            // Disabled or locked
            isDisabled = this.objLogin.verifyCredentials(session.apiUser, this.apiToken, '', 'security');
            if (isDisabled) {
                throw(type = "Account Disabled", message = "This API account is disabled");
            } else if (!isAuthenticated) {
                if (isDefined('session.retries') && session.retries >= 0) {
                    session.retries = session.retries + 1;
                }
                throw(type = "Invalid Credentials", message = "The API credentials are invalid");
            } else {
                // Authorized
                session.retries = 0;
                stmt = new query();
                stmt.setDatasource(session.dsname);
                stmt.SetName("stmt");
                eval = ReFindNoCase(
                        "([^a-zA-Z]ALTER[^a-zA-Z]|
                        [^a-zA-Z]CREATE[^a-zA-Z]|
                        [^a-zA-Z]DELETE[^a-zA-Z]|
                        [^a-zA-Z]EXEC[^a-zA-Z]|
                        [^a-zA-Z]EXECUTE[^a-zA-Z]|
                        [^a-zA-Z]DROP[^a-zA-Z]|
                        [^a-zA-Z]INSERT[^a-zA-Z]|
                        [^a-zA-Z]UPDATE[^a-zA-Z]|
                        [^a-zA-Z]TRUNCATE[^a-zA-Z])",
                        this.sql,
                        ,
                        "ALL");
                if (eval == 0) {
                    result = stmt.execute(sql = qry).getResult();
                } else {
                    throw(type = "Invalid Statement", message = "Check your SQL statement for invalid characters");
                }
            }
        } catch (any e) {
            savecontent variable="result" {
                error_type = rtrim(e.type);
                error_msg = rtrim(e.message);
                error_detail = rtrim(e.detail);
                error_code = rtrim(e.nativeerrorcode);
                error_state = rtrim(e.sqlstate);
                error_sql = rtrim(e.sql);
                error_query = rtrim(e.queryerror);
                writeOutput("Error Type: " & error_type & Chr(10) & "Error Message: " & error_msg & Chr(10) & "Error Detail: " & error_detail & Chr(10) & "Error Code" & error_code & Chr(10) & "Error State" & error_state & Chr(10) & "Error SQL" & error_sql & Chr(10) & "Error Query" & error_query & Chr(10));
            }
        }
        return result;
    }
}
