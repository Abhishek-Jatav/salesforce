/**
 * @description Apex controller for the Live Account Search LWC.
 *              Provides a cacheable SOQL search method secured with
 *              WITH SECURITY_ENFORCED and field-level sharing enforcement.
 * @author      Abhishek
 */
public with sharing class AccountSearchController {

    /**
     * @description Searches Account records whose Name contains the supplied
     *              keyword using a SOQL LIKE expression.
     *              Returns up to 50 matching records ordered by Name.
     *
     * @param  searchTerm  The substring to search for within Account Name.
     *                     Pass an empty string or null to return the first
     *                     50 accounts (alphabetically).
     * @return             List of Account records with Name, Industry,
     *                     Phone, and AnnualRevenue populated.
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> searchAccounts(String searchTerm) {
        String keyword = String.isBlank(searchTerm)
            ? '%'
            : '%' + String.escapeSingleQuotes(searchTerm.trim()) + '%';

        return [
            SELECT Id,
                   Name,
                   Industry,
                   Phone,
                   AnnualRevenue
              FROM Account
             WHERE Name LIKE :keyword
             WITH SECURITY_ENFORCED
             ORDER BY Name ASC
             LIMIT 50
        ];
    }
}
