public with sharing class ADG_ScheduleJobPathValidate implements Schedulable
{
    public void execute(SchedulableContext ctx) 
    {
        ADG_BatchJobPathValidate jobPathValidate = new ADG_BatchJobPathValidate(); 
        database.executebatch(jobPathValidate);
    }
}