/**
 * @description Unit tests for AccountSearchController.
 */
@IsTest
private class AccountSearchControllerTest {

    @TestSetup
    static void makeData() {
        insert new List<Account>{
            new Account(
                Name='Acme Corporation',
                Industry='Technology',
                Phone='415-555-0100',
                AnnualRevenue=5000000
            ),
            new Account(
                Name='Acme Supplies',
                Industry='Manufacturing',
                Phone='415-555-0101',
                AnnualRevenue=1200000
            ),
            new Account(
                Name='Beta Industries',
                Industry='Finance',
                Phone='212-555-0200',
                AnnualRevenue=9800000
            ),
            new Account(
                Name='Gamma Global',
                Industry='Retail',
                Phone='310-555-0300',
                AnnualRevenue=750000
            ),
            new Account(
                Name='Delta Dynamics',
                Industry='Healthcare',
                Phone='650-555-0400',
                AnnualRevenue=3300000
            )
        };
    }

    @IsTest
    static void testSearchByPartialName_returnsMatches() {
        List<Account> results =
            AccountSearchController.searchAccounts('Acme');

        System.assertEquals(2, results.size());
    }

    @IsTest
    static void testSearchByExactName_returnsSingleRecord() {
        List<Account> results =
            AccountSearchController.searchAccounts('Beta Industries');

        System.assertEquals(1, results.size());
        System.assertEquals('Beta Industries', results[0].Name);
    }

    @IsTest
    static void testReturnedFields_arePopulated() {
        List<Account> results =
            AccountSearchController.searchAccounts('Gamma Global');

        System.assertEquals(1, results.size());

        Account acc = results[0];

        System.assertNotEquals(null, acc.Id);
        System.assertEquals('Gamma Global', acc.Name);
        System.assertEquals('Retail', acc.Industry);
        System.assertEquals('310-555-0300', acc.Phone);
    }

    @IsTest
    static void testSearchWithNullTerm_returnsAllAccounts() {
        List<Account> results =
            AccountSearchController.searchAccounts(null);

        System.assertEquals(5, results.size());
    }

    @IsTest
    static void testSearchWithEmptyString_returnsAllAccounts() {
        List<Account> results =
            AccountSearchController.searchAccounts('');

        System.assertEquals(5, results.size());
    }

    @IsTest
    static void testSearchWithBlankSpaces_returnsAllAccounts() {
        List<Account> results =
            AccountSearchController.searchAccounts('   ');

        System.assertEquals(5, results.size());
    }

    @IsTest
    static void testSearchWithNoMatch_returnsEmptyList() {
        List<Account> results =
            AccountSearchController.searchAccounts('ZZZNOMATCH999');

        System.assertEquals(0, results.size());
    }

    @IsTest
    static void testSoqlInjectionAttempt_doesNotThrow() {

        String maliciousInput = 'OR Name LIKE';

        List<Account> results =
            AccountSearchController.searchAccounts(maliciousInput);

        System.assertNotEquals(null, results);
    }

    @IsTest
    static void testSearchResults_areOrderedByNameAscending() {

        List<Account> results =
            AccountSearchController.searchAccounts(null);

        System.assertEquals(5, results.size());

        for(Integer i = 0; i < results.size() - 1; i++) {
            System.assert(
                results[i].Name <= results[i + 1].Name
            );
        }
    }

    @IsTest
    static void testSearch_isCaseInsensitive() {

        List<Account> upper =
            AccountSearchController.searchAccounts('DELTA');

        List<Account> lower =
            AccountSearchController.searchAccounts('delta');

        System.assertEquals(1, upper.size());
        System.assertEquals(1, lower.size());
        System.assertEquals('Delta Dynamics', upper[0].Name);
    }
}