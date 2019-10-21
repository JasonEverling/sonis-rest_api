/**
* Sonis SOAP API Endpoint
*
* @displayname SoapAPI
* @hint Run various API methods and functions
* @wsVersion 1
* @author Jason A. Everling
* @todo Create better injection detection so were not relying on the client. Update to support version 2 of axis.
*/
component output="false"
{

    this.utils = CreateObject("component", "CFC.rest.utils");
    this.objLogin = CreateObject("component", "CFC.rest.login");
    this.objValid = CreateObject("component", "CFC.rest.validate");

    /**
    * The SOAP API runner, call doAPISomething
    *
    * @author Jason A. Everling
    * @user api username
    * @pass api password
    * @comp the component to use
    * @meth the method within the component
    * @hasReturnVariable either "yes" or "no" if returns
    * @argumentdata a simple array of arrays containing data for the method, i.e [["soc_sec","1234567"],["preferred","true"]]
    * @return array|mixed the results returned from the method
    * @todo Create better error handling results, cleanup
    */
    remote any function doAPISomething(required string user="", required string pass="", required string comp="", required string meth="", string hasReturnVariable="yes", required array argumentdata="") output=false {

        try {
            include "../../application.cfm";
            this.objValid.validateSession(); // Validate api session, shorter than app defined
            session.dsname = sonis.ds;
            session.apiUser = lCase(user);
            this.apiToken = pass;
            this.apiData = argumentdata;
            this.returns = lcase(hasReturnVariable);
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
                savecontent variable="result" {
                    cfinvoke(component = comp, method = meth, returnvariable = "getresults") {
                        // Sonis methods require sonis_ds and MainDir, let's just pass them
                        cfinvokeargument(name = 'sonis_ds', value = session.dsname);
                        cfinvokeargument(name = 'MainDir', value = MainDir);
                        // Loop through argumentdata and set for the method
                        for (i = 1; i <= ArrayLen(this.apiData); i++) {
                            cfinvokeargument(name = this.apiData[i][1], value = this.apiData[i][2]);
                        }
                    }
                }
                if (this.returns == 'no') {
                    // Cleanup whitespaces, line feeds and carriage returns
                    return REReplace(this.apiData, "[\s]+", "Chr(13)Chr(10)", "ALL");
                } else if (this.returns == 'yes') {
                    return getresults;
                } else {
                    throw(type = "Invalid Parameter", message = "The hasReturnVariable parameter must be either yes or no");
                }
            }
        } catch (any e) {
            savecontent variable="result" {
                error_type = rtrim(e.type);
                error_msg = rtrim(e.message);
                error_detail = rtrim(e.detail);
                msg = '{"Error Type": #error_type#, "Error Message": #error_msg#, "Error Detail": #error_detail#}';
                writeOutput(msg);
            }
        }
        return result;
    }
}
