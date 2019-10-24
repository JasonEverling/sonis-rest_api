/**
* Sonis Restful API Endpoint
*
* @displayname Rest
* @hint Run various API methods and functions
* @author Jason A. Everling
* @todo lots more custom functions to be added
*/
component output="false" {

    // Set as global session vars since we dont have a modifiable application.cfc
    session.objDB = CreateObject("component", "CFC.rest.database");
    session.objUtils = CreateObject("component", "CFC.rest.utils");

    remote function v1() output=false {

        this.objValid = CreateObject("component", "CFC.rest.validate");
        this.objLogin = CreateObject("component", "CFC.rest.login");

        try {
            // Setup the request
            include "../application.cfm";
            cfheader(name = "Content-Type", value = "application/json;charset=UTF-8");
            this.objValid.validateSession(); // Validate api session, shorter than app defined
            hasHeaders = this.objValid.validateHeaders();
            if (!isBoolean(hasHeaders)) {
                return hasHeaders;
                exit;
            }
            // Setup vars
            session.dsname = sonis.ds;
            session.wwwroot = ExpandPath("../");
            session.retries = (session.retries) ?: 0;
            session.apiUser = lCase(getHttpRequestData().headers["X-SONIS-USER"]);
            variables.apiToken = getHttpRequestData().headers["X-SONIS-PWD"];
            variables.contentType = "application/json;charset=UTF-8";
            variables.output = "";
            variables.verb = "";
            if (getHTTPRequestData().method == 'GET') {
                variables.verb = "GET";
                variables.object = url.object;
                variables.action = url.action;
                variables.builtin = url.builtin;
                variables.argumentdata = session.objUtils.listToStruct(url.argumentdata);
            }
            if (getHTTPRequestData().method == 'POST') {
                variables.verb = "POST";
                variables.apiJSON = getHTTPRequestData().content;
                variables.apiData = deserializeJSON(ToString(apiJSON));
                // Build local variables from JSON data
                for (key in apiData) {
                    setVariable(key, apiData[key]);
                }
            }
            // Object is a builtin Sonis function, MUST be after 'apiData' is processed
            variables.builtin = (builtin) ?: false;
            // Begin authorization sequence
            isAuthenticated = this.objLogin.apiAuthorization(variables.apiToken);
            // Throttle login attempts
            if (session.retries >= webopt.login_retries) {
                locked = this.objLogin.disableLogin(session.apiUser);
                if (!locked) {
                    msg = session.objUtils.createHttpMsg(417, "Expectation Failed", "Please contact the site administrator");
                    writeOutput(msg);
                    exit;
                }
            }
            // Check if disabled or locked
            isDisabled = this.objLogin.verifyCredentials(session.apiUser, variables.apiToken, '', 'security');
            if (isDisabled) {
                variables.result = session.objUtils.createHttpMsg(401, "Account Disabled");
            } else if (!isAuthenticated) {
                if (isDefined('session.retries') && session.retries >= 0) {
                    session.retries = session.retries + 1;
                }
                variables.result = session.objUtils.createHttpMsg(401, "Unauthorized");
            } else {
                // We got a authorization, hooray, let's return some data
                session.retries = 0;
                if (!builtin) {
                    cfinvoke(component = "CFC.rest." &  object, method =  action, returnvariable = "result") {
                        if (variables.verb == 'GET') {
                            for (i in variables.argumentdata) {
                                cfinvokeargument(name = i, value = argumentdata[i]);
                            }
                        }
                        if (variables.verb == 'POST') {
                            for (i in apiData.argumentdata) {
                                cfinvokeargument(name = i, value = apiData.argumentdata[i]);
                            }
                        }
                    };
                } else {
                    cfinvoke(component = "CFC." &  object, method =  action, returnvariable = "result") {
                        cfinvokeargument(name = sonis_ds, value = sonis.ds);
                        cfinvokeargument(name = MainDir, value = MainDir);
                        if (variables.verb == 'GET') {
                            for (i in variables.argumentdata) {
                                cfinvokeargument(name = i, value = argumentdata[i]);
                            }
                        }
                        if (variables.verb == 'POST') {
                            for (i in apiData.argumentdata) {
                                cfinvokeargument(name = i, value = apiData.argumentdata[i]);
                            }
                        }
                    };
                }
            }
            if (isQuery(variables.result)) {
                result = serializeJSON(variables.result, "struct");
            }
        } catch (any e) {
            savecontent variable="result" {
                error_type = rtrim(e.type);
                error_msg = rtrim(e.message);
                error_detail = rtrim(e.detail);
                msg = '{"Error Type": "' & error_type & '", "Error Message": "' & error_msg & '", "Error Detail": "' & error_detail & '"}';
                writeOutput(msg);
            }
        }
        return result;
    }
}
