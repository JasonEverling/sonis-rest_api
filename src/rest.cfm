<!--- not used in prod
<cfinclude template = "common/rest/header.cfm" />
--->
<!--- Setup the request --->
<cfscript>
    cfheader(name="Content-Type", value="application/json;charset=UTF-8");
    objValid = CreateObject("component", "CFC.rest.validate");
    sessionLength = objValid.validateSession();
    hasHeaders = objValid.validateHeaders();
    if (!isBoolean(hasHeaders)) {
        return hasHeaders;
        exit;
    }
</cfscript>

<cfset session.dsname = "#sonis.ds#" />
<cfset session.wwwroot = ExpandPath( "./" ) />
<cfset session.apiUser = lCase(getHttpRequestData().headers["X-SONIS-USER"]) />
<cfset variables.apiToken = getHttpRequestData().headers["X-SONIS-PWD"] />
<cfset variables.apiJSON = getHTTPRequestData().content />
<cfset variables.apiData = deserializeJSON(ToString(apiJSON)) />
<cfset variables.contentType = "application/json;charset=UTF-8" />
<cfif NOT isDefined('session.retries')>
    <cfset session.retries = 0 />
</cfif>

<!--- Object is a builtin Sonis function --->
<cfif NOT isDefined('builtin')>
    <cfset variables.builtin = false />
</cfif>

<!--- Build local variables from JSON data --->
<cfloop collection="#apiData#" item="key">
    <cfset "#key#" = "#apiData[key]#" />
</cfloop>

<!--- Get authorization to continue --->
<cfinvoke component = "CFC.rest.login" method = "apiAuthorization" returnvariable = "isAuthenticated">
        <cfinvokeargument name = "token"  value = '#apiToken#' />
</cfinvoke>

<!--- Throttle login attempts --->
<cfif #session.retries# GTE #webopt.login_retries#>
    <cfinvoke component = "CFC.rest.login" method = "disableLogin" returnvariable = "locked">
        <cfinvokeargument name = "user"  value = '#session.apiUser#' />
    </cfinvoke>
    <cfif NOT #locked#>
        <cfoutput>
            '{Return Code": 417, "Details": "Expectation Failed", "Extended": "Please contact the site administrator"}'
        </cfoutput>
        <cfabort>
    </cfif>
</cfif>

<!--- Check if disabled or locked --->
<cfinvoke component = "CFC.rest.login" method = "verifyCredentials" returnvariable = "isDisabled">
    <cfinvokeargument name = "user"  value = '#session.apiUser#' />
    <cfinvokeargument name = "password"  value = '#variables.apiToken#' />
    <cfinvokeargument name = "type"  value = '' />
    <cfinvokeargument name = "credential"  value = 'security' />
</cfinvoke>

<cfif #isDisabled#>
    <cfset variables.result = '{"Return Code": 401, "Details": "Account Disabled"}' />
<cfelseif '#isAuthenticated#' eq false>
    <cfif isDefined('session.retries') AND #session.retries# GTE 0>
        <cfset session.retries = #session.retries# + 1>
    </cfif>
    <cfset variables.result = '{"Return Code": 401, "Details": "Unauthorized"}' />
<cfelse>
<!--- We got a authorization, hooray --->
    <cfset session.retries = 0 />
    <cfif '#builtin#' eq false>
        <cfinvoke component = "CFC.rest.#object#" method = "#method#" returnvariable = "result">
            <cfloop collection="#apiData.argumentdata#" item="i">
                <cfinvokeargument name = "#i#" value = "#apiData.argumentdata[i]#" />
            </cfloop>
        </cfinvoke>
    <cfelse>
        <cfinvoke component = "CFC.#object#" method = "#method#" returnvariable = "result">
            <cfinvokeargument name = "sonis_ds" value = '#sonis.ds#' />
            <cfinvokeargument name = "MainDir" value = '#MainDir#' />
            <cfloop collection="#apiData.argumentdata#" item="i">
                <cfinvokeargument name = "#i#" value = "#apiData.argumentdata[i]#" />
            </cfloop>
        </cfinvoke>
    </cfif>
</cfif>

<cfif isQuery(result)>
    <cfoutput>
        #serializeJSON(result, "struct")#
    </cfoutput>
<cfelse>
    <cfoutput>
        #result#
    </cfoutput>
</cfif>
<!--- not used in prod
<cfinclude template="common/rest/footer.cfm" />
--->
