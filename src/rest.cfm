<cfinclude template = "common/rest/header.cfm" />
<cfheader name="Content-Type" value="application/json;charset=UTF-8">

<cfif NOT StructKeyExists(GetHttpRequestData().Headers, "X-SONIS-AUTHN")>
    <cfset variables.result = 'Return Code": 400, "Details": "Bad Request", "Extended": "X-SONIS-AUTHN Header is missing"}' />
</cfif>
<cfif NOT isJSON(getHTTPRequestData().content)>
    <cfset variables.result = '{"Return Code": 400, "Details": "Bad Request", "Extended": "Payload is not valid JSON"}' />
</cfif>

<cfset session.dsname = "#sonis.ds#" />
<cfset session.wwwroot = ExpandPath( "./" ) />
<cfset variables.contentType = "application/json;charset=UTF-8" />
<cfset variables.apiToken = getHttpRequestData().headers["X-SONIS-AUTHN"] />
<cfset variables.apiJSON = getHTTPRequestData().content />
<cfset variables.apiData = deserializeJSON(ToString(apiJSON)) />
<!--- Object is a builtin Sonis function --->
<cfif NOT isDefined('builtin')>
    <cfset variables.builtin = false />
</cfif>

<cfloop collection="#apiData#" item="key">
    <cfset "#key#" = "#apiData[key]#" />
</cfloop>

<!--- Get authorization to continue --->
<cfinvoke component = "CFC.rest.Login" method = "apiAuthorization" returnvariable = "isAuthenticated">
        <cfinvokeargument name = "token"  value = '#apiToken#' />
</cfinvoke>

<cfif '#isAuthenticated#' eq false>
    <cfset variables.result = '{"Return Code": 401, "Details": "Unauthorized"}' />
<cfelse>
    <cfif '#builtin#' eq false>
        <cfinvoke component = "CFC.rest.#object#" method = "#method#" returnvariable = "result">
            <cfloop collection="#apiData.argumentdata#" item="i">
                <cfinvokeargument name = "#i#" value = "#apiData.argumentdata[i]#" />
            </cfloop>
        </cfinvoke>
    <cfelse>
        <cfinvoke component = "CFC.#object#" method = "#method#" returnvariable = "result">
            <cfinvokeargument name = "sonis_ds" value = '#sonis.ds#' />
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

<cfinclude template="common/rest/footer.cfm" />
