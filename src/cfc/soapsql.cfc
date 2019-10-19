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
    * @sql sql statement
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
                qry = replaceNoCase(this.sql, ';', 'all');
                qry = replaceNoCase(qry, 'ALTER', 'all');
                qry = replaceNoCase(qry, 'DROP', 'all');
                qry = replaceNoCase(qry, 'TRUNCATE', 'all');
                result = stmt.execute(sql = qry).getResult();
            }
        } catch (any e) {
            savecontent variable="result" {
                error_type = rtrim(e.type);
                error_msg = rtrim(e.message);
                error_detail = rtrim(e.detail);
                writeOutput("Error Type: " & error_type & Chr(10) & "Error Message: " & error_msg & Chr(10) & "Error Detail: " & error_detail);
            }
        }
        return result;
    }
}