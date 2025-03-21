({
    loadWorkOrderDetails: function (component, event, helper) {
        var recordId = component.get("v.recordId");

        var action = component.get("c.loadWorkOrderLineItems");
        action.setParams({
            'workOrderId': recordId
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === 'SUCCESS' && component.isValid()) {
                var returnValue = response.getReturnValue();
                if (returnValue) {
                    component.set("v.workOrderDetails", returnValue.workOrderDetails);
                    component.set("v.listOfWorkOrderChildDetials", returnValue.lineItemsList);
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            } else {
                console.log("state: " + state + "; component.isValid: " + component.isValid());
            }
        });
        $A.enqueueAction(action);
    }
})