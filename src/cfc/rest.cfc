/**
* Sonis Restful API Endpoint
*
* @displayname Rest
* @hint Run various API methods and functions
* @author Jason A. Everling
* @todo lots more custom functions to be added
*/
component output="false" {

    remote function v1() output=false {
        try {
            //include "common/rest/header.cfm"; // Not used in prod
            // Setup the request
            include "../application.cfm";
            cfheader(name = "Content-Type", value = "application/json;charset=UTF-8");
            objValid = CreateObject("component", "CFC.rest.validate");
            utils = CreateObject("component", "CFC.rest.utils");
            sessionLength = objValid.validateSession();
            hasHeaders = objValid.validateHeaders();
            if (!isBoolean(hasHeaders)) {
                return hasHeaders;
                exit;
            }
            // Setup vars
            session.dsname = sonis.ds;
            session.wwwroot = ExpandPath("./");
            session.apiUser = lCase(getHttpRequestData().headers["X-SONIS-USER"]);
            variables.apiToken = getHttpRequestData().headers["X-SONIS-PWD"];
            variables.output = "";
            variables.action = "";
            if (getHTTPRequestData().method == 'GET') {
                variables.action = "GET";
                variables.object = url.object;
                variables.method = url.method;
                variables.builtin = url.builtin;
                variables.argumentdata = utils.listToStruct(url.argumentdata);
            }
            if (getHTTPRequestData().method == 'POST') {
                variables.action = "POST";
                variables.apiJSON = getHTTPRequestData().content;
                variables.apiData = deserializeJSON(ToString(apiJSON));
                // Build local variables from JSON data
                for (key in apiData) {
                    setVariable(key, apiData[key]);
                }
            }
            variables.meth = method;
            variables.contentType = "application/json;charset=UTF-8";
            if (!isDefined('session.retries')) {
                session.retries = 0;
            }
            // Object is a builtin Sonis function
            if (!isDefined('builtin')) {
                variables.builtin = false;
            }
            // Begin authorization sequence
            objLogin = CreateObject("component", "CFC.rest.login");
            isAuthenticated = objLogin.apiAuthorization(variables.apiToken);
            // Throttle login attempts
            if (session.retries >= webopt.login_retries) {
                locked = objLogin.disableLogin(session.apiUser);
                if (!locked) {
                    msg = utils.createHttpMsg(417, "Expectation Failed", "Please contact the site administrator");
                    writeOutput(msg);
                    exit;
                }
            }
            // Check if disabled or locked
            isDisabled = objLogin.verifyCredentials(session.apiUser, variables.apiToken, '', 'security');
            if (isDisabled) {
                variables.result = utils.createHttpMsg(401, "Account Disabled");
            } else if (!isAuthenticated) {
                if (isDefined('session.retries') && session.retries >= 0) {
                    session.retries = session.retries + 1;
                }
                variables.result = utils.createHttpMsg(401, "Unauthorized");
            } else {
                // We got a authorization, hooray, let's return some data
                session.retries = 0;
                if (!builtin) {
                    cfinvoke(component = "CFC.rest." &  object, method =  variables.meth, returnvariable = "result") {
                        if (variables.action == 'GET') {
                            for (i in variables.argumentdata) {
                                cfinvokeargument(name = i, value = argumentdata[i]);
                            }
                        }
                        if (variables.action == 'POST') {
                            for (i in apiData.argumentdata) {
                                cfinvokeargument(name = i, value = apiData.argumentdata[i]);
                            }
                        }
                    };
                } else {
                    cfinvoke(component = "CFC." &  object, method =  variables.meth, returnvariable = "result") {
                        cfinvokeargument(name = sonis_ds, value = sonis.ds);
                        cfinvokeargument(name = MainDir, value = MainDir);
                        if (variables.action == 'GET') {
                            for (i in variables.argumentdata) {
                                cfinvokeargument(name = i, value = argumentdata[i]);
                            }
                        }
                        if (variables.action == 'POST') {
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
