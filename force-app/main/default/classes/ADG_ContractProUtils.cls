public class ADG_ContractProUtils {
  public static void updateLoginCounts(
      System.TriggerOperation triggerEvent,
      Map<Id, Contact> newContacts,
      Map<Id, Contact> oldContacts
  ) {
  
  
    List<Account> toBeUpdated = new List<Account>();
    Map<Id, Account> accountMap = new Map<Id, Account>();
    
    if (newContacts != null) {
      for(Contact c: newContacts.values()) {
        if(c.accountId != null) {
          Account account = new Account(
            Id = c.AccountId,
            ContractPro_Login_Count__c = 0
          );
          accountMap.put(c.AccountId, account);
        }
      }
    }

    if (oldContacts != null) {
      for(Contact c: oldContacts.values()) {
        if(c.accountId != null) {
          Account account = new Account(
            Id = c.AccountId,
            ContractPro_Login_Count__c = 0
          );
          accountMap.put(c.AccountId, account);
        }
      }
    }

    System.debug('accountMap: ' + accountMap);

    List<AggregateResult> results = [
      SELECT AccountId, COUNT(Id) total
      FROM Contact
      WHERE AccountId IN :accountMap.keySet()
      AND ContractPro_Account_Enabled__c = true
      GROUP BY AccountId
    ];

    System.debug('results: ' + results);
    for (AggregateResult result: results) {
      Id accountId = (Id)result.get('AccountId');
      if (accountId != null) {
        Decimal total = (Decimal)result.get('total');
        accountMap.get(accountId).ContractPro_Login_Count__c = total;
      }
    }


    update accountMap.values();
  }
}