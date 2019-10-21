/**
* Grouped People Functions
*
* @displayname People
* @hint Functions related multiple persons
* @author Jason A. Everling
*/
component extends="person" output="false"
{

    db = createObject("component", "database");
    utils = CreateObject("component", "utils");

    /**
     * Same as person.getAttributes but instead for a group of people
     *
     * @author Jason A. Everling
     * @modstat mod_stat code
     * @affiliation affiliation_cod code
     * @dept dept_cod code
     * @level level_ code
     * @includeSSN true or false to also include the SSN in the results, default = false
     * @includePIN true or false to also include the PIN in the results, default = false
     * @return array
     */
    public function getPeopleAttributes(required string modstat, required string affiliation = "", required string dept = "", required string level = "", required boolean includeSSN = false, required boolean includePIN = false)
    {
        if (includeSSN || includeSSN == 1) {
            includeSSN = "rtrim(CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, n.SSN))) AS ssn, ";
        } else {
            includeSSN = "";
        }
        if (includePIN || includePIN == 1) {
            includePIN = "rtrim(CONVERT(char, DECRYPTBYKEYAUTOCERT(CERT_ID('SSN'), NULL, n.PIN))) AS pin, ";
        } else {
            includePIN = "";
        }
        params = [["mod_stat", uCase(modstat)]];
        where = "WHERE m.mod_stat = :mod_stat";
        if (affiliation != "") {
            where = where & " AND n.affiliation_cod = :affiliation_cod";
            params.append(["affiliation_cod", uCase(affiliation)]);
        }
        if (dept != "") {
            where = where & " AND n.dept_cod = :dept_cod";
            params.append(["dept_cod", uCase(dept)]);
        }
        if (level != "") {
            where = where & " AND n.level_ = :level_";
            params.append(["level_", uCase(level)]);
        }
        stmt = "SELECT rtrim(n.soc_sec) as soc_sec, rtrim(n.last_name) as last_name, rtrim(n.first_name) as first_name, rtrim(n.mi) as mi, n.disabled, rtrim(n.prefix) as prefix, rtrim(n.suffix) as suffix, rtrim(n.maiden) as maiden, CONVERT(VARCHAR, n.birthdate, 23) AS birthdate, dbo.udf_getAge(n.birthdate, GETDATE()) AS age, n.citizen, n.gender, rtrim(g.gender_txt) as gender_txt, rtrim(n.ethnic_cod) as ethnic_cod, rtrim(e.ethnic_txt) as ethnic_txt,
                            n.mar_cod, rtrim(mar.mar_txt) as mar_txt, n.veteran, rtrim(n.div_cod) as div_cod, rtrim(d.div_txt) as div_txt, n.dept_cod, rtrim(dept.dept_txt) as dept_txt, rtrim(n.camp_cod) as camp_cod, rtrim(c.camp_txt) as camp_txt, n.level_, rtrim(l.level_txt) as level_txt, rtrim(n.nickname) as nickname,
                            n.show_email ,n. show_phone ,n.show_addr ,n.show_wkphn, n.iped_stat, rtrim(n.acadstat_cod) as acadstat_cod, rtrim(n.affiliation_cod) as affiliation_cod, rtrim(n.Driver_License) as Driver_License, rtrim(n.dl_state) as dl_state, n.BA_Degree, rtrim(n.other_name) as other_name, rtrim(n.ldap_id) as ldap_id,
                            n.military_cod, " & includeSSN & includePIN & " n.employer_rid, m.mod_stat, rtrim(ms.mod_txt) as mod_txt,
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
                        LEFT JOIN level_ l ON n.level_ = l.level_ " & where;
        result = db.execQuery(stmt, params);
        return result;
    }
}
