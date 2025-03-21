@isTest
private class SG_Account_LU_Test {

        static testMethod void sampleTestMethod()
    {
        Account obj = new Account();
        obj.name = 'test';
                // TODO: add required fields to object for validation rules, etc
                insert obj;

        // TODO: write proper assertions!!

                update obj;

                delete obj;
        }
}