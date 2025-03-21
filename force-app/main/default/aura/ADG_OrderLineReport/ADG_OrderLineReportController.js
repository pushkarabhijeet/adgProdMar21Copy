({
  doInit: function (component, event, helper) {
    helper.loadWorkOrderDetails(component, event, helper);
  },

  childElementDropdown: function (component, event, helper) {
    var items = component.get("v.listOfWorkOrderChildDetials");
    var component_target = event.currentTarget;
    var index = component_target.dataset.value;
    try {
      items[index].expanded = !items[index].expanded;
    } catch (err) {
      console.log("error" + err);
    }
    component.set("v.listOfWorkOrderChildDetials", items);
  },
});