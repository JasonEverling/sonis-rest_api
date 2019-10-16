component displayname="person" author="Jason Everling" hint="Functions related to the person" output="false"
{

/**
 * Returns the details of a person
 *
 * @author Jason A. Everling
 * @user Persons identifier
 * @type Type of identifier, soc_sec, ldap, or email
 * @return array
 */
    public function getDetails(required string user, required string type) returnFormat="json"
    {
        if (type == "soc_sec") {
            filter = "WHERE n.soc_sec = :user";
        } else if (type == "ldap") {
            filter = "WHERE n.ldap_id = :user";
        } else if (type == "email") {
            filter = "WHERE a.e_mail = :user OR a.e_mail2 = :user";
        } else {
            return false;
        }
        sql = new query();
        sql.setDatasource("#session.dsname#");
        sql.SetName("sql");
        sql.addParam(name="user",value=user,cfsqltype="varchar");
        stmt = "SELECT rtrim(n.soc_sec) as soc_sec, rtrim(n.last_name) as last_name, rtrim(n.first_name) as first_name, rtrim(n.mi) as mi, n.disabled, rtrim(n.prefix) as prefix, rtrim(n.suffix) as suffix, rtrim(n.maiden) as maiden, CONVERT(VARCHAR, n.birthdate, 23) AS birthdate, dbo.udf_getAge(n.birthdate, GETDATE()) AS age, n.citizen, n.gender, rtrim(g.gender_txt) as gender_txt, rtrim(n.ethnic_cod) as ethnic_cod, rtrim(e.ethnic_txt) as ethnic_txt,
                            n.mar_cod, rtrim(mar.mar_txt) as mar_txt, n.veteran, rtrim(n.div_cod) as div_cod, rtrim(d.div_txt) as div_txt, n.dept_cod, rtrim(dept.dept_txt) as dept_txt, rtrim(n.camp_cod) as camp_cod, rtrim(c.camp_txt) as camp_txt, n.level_, rtrim(l.level_txt) as level_txt, rtrim(n.nickname) as nickname,
                            n.show_email ,n. show_phone ,n.show_addr ,n.show_wkphn, n.iped_stat, rtrim(n.acadstat_cod) as acadstat_cod, rtrim(n.affiliation_cod) as affiliation_cod, rtrim(n.Driver_License) as Driver_License, rtrim(n.dl_state) as dl_state, n.BA_Degree, rtrim(n.other_name) as other_name, rtrim(n.ldap_id) as ldap_id,
                            n.military_cod, rtrim(CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, n.SSN))) AS ssn, rtrim(CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, n.PIN))) AS pin, n.employer_rid, m.mod_stat, rtrim(ms.mod_txt) as mod_txt,
                            rtrim(a.e_mail) as e_mail, rtrim(a.e_mail2) as e_mail2, dbo.udf_getNumeric(a.phone) AS phone, dbo.udf_getNumeric(a.cell_phone) AS cell_phone, a.cell_provider, dbo.udf_getNumeric(a.work_phone) AS work_phone, rtrim(a.st_addr) as st_addr, rtrim(a.add_add2) as add_add2, rtrim(a.city) as city, rtrim(a.state) as state, rtrim(a.zip) as zip, rtrim(a.country) as country, rtrim(a.memo) as memo
                    FROM name n
                        LEFT JOIN address a ON n.soc_sec = a.soc_sec AND a.preferred = '1'
                        LEFT JOIN ethnic e ON n.ethnic_cod = e.ethnic_cod
                        LEFT JOIN gender g ON n.gender = g.gender_cod
                        LEFT JOIN marital mar ON n.mar_cod = mar.mar_cod
                        LEFT JOIN nmmodst m ON n.soc_sec = m.soc_sec
                        LEFT JOIN modstat ms ON m.mod_stat = ms.mod_stat
                        LEFT JOIN campus c ON n.camp_cod = c.camp_cod
                        LEFT JOIN division d ON n.div_cod = d.div_cod
                        LEFT JOIN dept ON n.dept_cod = dept.dept_cod
                        LEFT JOIN level_ l ON n.level_ = l.level_ " & filter;
        result = sql.execute(sql=stmt).getResult();
        return result;
    }

/**
 * Updates a persons password/pin
 *
 * @author Jason A. Everling
 * @user Username
 * @password Password
 * @type Type of username, either soc_sec, ldap, or email
 * @return boolean
 */
    public function updateCredentials(required string user, required string password, required string type) returnFormat="json"
    {

        if (isAuthenticated) {
            if (type == "soc_sec") {
                filter = "WHERE soc_sec = :user";
            } else if (type == "ldap") {
                filter = "WHERE ldap_id = :user";
            } else if (type == "email") {
                filter = "FROM name n INNER JOIN address a ON n.soc_sec = a.soc_sec AND a.preferred = '1' WHERE a.email = :user";
            } else {
                return false;
            }
            sql = new query();
            sql.setDatasource("#session.dsname#");
            sql.SetName("sql");
            sql.addParam(name = "user", value = user, cfsqltype = "varchar");
            sql.addParam(name = "password", value = password, cfsqltype = "varchar");
            stmt = "OPEN SYMMETRIC KEY SSN_Key_01
                    DECRYPTION BY CERTIFICATE SSN
                    UPDATE name
                    SET pin = EncryptByKey(Key_Guid('SSN_Key_01'),:password) " & filter & " SELECT @@RowCount AS affected";
            qryresult = sql.execute(sql = stmt).getResult();
            if (qryresult.affected GT 0) {
                return true;
            }
            return false;
        }
        return {"Error": "Invalid Credentials"};
    }

/**
 * Returns true or false if credentials are valid
 *
 * @author Jason A. Everling
 * @user Username
 * @password Password
 * @type Type of username, either soc_sec, ldap, or email
 * @return boolean true or false
 */
    public function verifyCredentials(required string user, required string password, required string type, string credential) returnFormat="json"
    {

        if (isAuthenticated) {
            isSecurity = false;
            if (credential == "security") {
                isSecurity = true;
            }
            sql = new query();
            sql.setDatasource("#session.dsname#");
            sql.SetName("sql");
            sql.addParam(name = "user", value = user, cfsqltype = "varchar");
            sql.addParam(name = "password", value = password, cfsqltype = "varchar");
            if (type == "soc_sec") {
                filter = "WHERE n.soc_sec = :user AND n.pin = :password AND n.disabled = '0'";
            } else if (type == "ldap") {
                filter = "WHERE n.ldap_id = :user AND n.pin = :password AND n.disabled = '0'";
            } else if (type == "email") {
                filter = "INNER JOIN address a ON n.soc_sec = a.soc_sec AND a.preferred = '1' WHERE a.e_mail = :user AND n.pin = :password AND n.disabled = '0'";
            } else {
                return false;
            }
            stmt = "SELECT n.soc_sec, n.disabled, CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, n.PIN)) AS pin FROM name n " & filter;
            if (isSecurity) {
                stmt = "SELECT s.user_id, s.disabled, CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, s.password)) AS password
                        FROM security s
                        WHERE s.user_id = :user AND s.password = :password AND s.disabled = '0'";
            }
            result = sql.execute(sql = stmt).getResult();
            if (result.affected > 0) {
                return true;
            }
            return false;
        }
        return {"Error": "Invalid Credentials"};
    }
}
