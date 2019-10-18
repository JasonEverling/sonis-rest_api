component displayname="validate" author="Jason Everling" hint="Utility Functions around validation" output="false"
{

    utils = CreateObject("component", "utils");

    /**
    * Validates required headers are set
    *
    * @author Jason A. Everling
    * @return mixed true if valid, error message if not
    */
    public function validateHeaders()
    {
        if (!StructKeyExists(getHttpRequestData().headers, "X-SONIS-USER") || !isJSON(getHTTPRequestData().content) || !StructKeyExists(getHttpRequestData().headers, "X-SONIS-PWD")) {
            if (!StructKeyExists(getHttpRequestData().headers, "X-SONIS-USER")) {
                result = utils.createHttpMsg(400, "Bad Request", "X-SONIS-USER Header is missing");
            }
            if (!StructKeyExists(getHttpRequestData().headers, "X-SONIS-PWD")) {
                result = utils.createHttpMsg(400, "Bad Request", "X-SONIS-PWD Header is missing");
            }
            if (!isJSON(getHTTPRequestData().content)) {
                result = utils.createHttpMsg(400, "Bad Request", "Payload is not valid JSON");
            }
            return result;
        } else {
            return true;
        }
    }

    /**
    * Sets the session limit for this API
    *
    * @author Jason A. Everling
    * @length Amount in seconds
    * @return boolean true or false
    */
    public function validateSession(numeric length)
    {
        length = 300;
        result = DateAdd("s", length, Now());
        if (!isDefined('session.expires')) {
            result = DateAdd("s", length, Now());
        } else {
            if (#session.expires# < Now()) {
                structClear(session);
            }
            result = DateAdd("s", length, Now());
        }
        return result;
    }
}
