trigger ADG_ContractProUserCount on Contact (after update, after insert, after delete, after undelete) {
  ADG_ContractProUtils.updateLoginCounts(
    Trigger.operationType,
    Trigger.newMap,
    Trigger.oldMap
  );
}