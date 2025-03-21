@isTest
private class ADG_ScheduleJobPathValidate_Test {
    static testMethod void test() {        
         Test.startTest();
         ADG_ScheduleJobPathValidate scheduleJobPath = new ADG_ScheduleJobPathValidate();   
         system.schedule('Test Schedule Job Path Validate', '0 0 23 * * ?', scheduleJobPath);
         Test.stopTest();
    }
}