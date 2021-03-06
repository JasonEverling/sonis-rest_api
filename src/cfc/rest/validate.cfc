/**
* Utility Functions around validation
*
* @displayname Validate
* @hint Various validation utilities that can be reused in various functions
* @author Jason A. Everling
*/
component output="false"
{

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
                result = session.objUtils.createHttpMsg(400, "Bad Request", "X-SONIS-USER Header is missing");
            }
            if (!StructKeyExists(getHttpRequestData().headers, "X-SONIS-PWD")) {
                result = session.objUtils.createHttpMsg(400, "Bad Request", "X-SONIS-PWD Header is missing");
            }
            if (!isJSON(getHTTPRequestData().content)) {
                result = session.objUtils.createHttpMsg(400, "Bad Request", "Payload is not valid JSON");
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
            if (session.expires < Now()) {
                structClear(session);
            }
            result = DateAdd("s", length, Now());
        }
        return result;
    }
}
