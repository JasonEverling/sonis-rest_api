<!--- The Sonis RESTFul API Endpoint--->
<cfscript>
        //include "common/rest/header.cfm"; // Not used in prod
        // Setup the request
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
        session.dsname = "#sonis.ds#";
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
                "#key#" = "#apiData[key]#";
            }
        }

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
                writeOutput("'{Return Code"": 417, ""Details"": ""Expectation Failed"", ""Extended"": ""Please contact the site administrator""}'");
                exit;
            }
        }
        // Check if disabled or locked
        isDisabled = objLogin.verifyCredentials(session.apiUser, variables.apiToken, '', 'security');
        if (isDisabled) {
            variables.result = '{"Return Code": 401, "Details": "Account Disabled"}';
        } else if (!isAuthenticated) {
                if (isDefined('session.retries') && session.retries >= 0) {
                    session.retries = session.retries + 1;
                }
                variables.result = '{"Return Code": 401, "Details": "Unauthorized"}';
        } else {
            // We got a authorization, hooray, let's return some data
            session.retries = 0;
            if (!builtin) {
                cfinvoke(component = "CFC.rest.#object#", method = "#method#", returnvariable = "result") {
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
                cfinvoke(component = "CFC.rest.#object#", method = "#method#", returnvariable = "result") {
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
            writeOutput(serializeJSON(variables.result, "struct"));
        } else {
            writeOutput(variables.result);
        }
        //include "common/rest/footer.cfm"; // Not used in prod
</cfscript>
