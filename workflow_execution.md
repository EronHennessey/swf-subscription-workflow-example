# About SWF Workflow Execution

Workflow executions follow a pattern of decider and activity events.  The lifecycle of a workflow goes like this:

decider event: WorkflowExecutionStarted

    This begins the workflow

decider event: DecisionTaskScheduled
decider event: DecisionTaskStarted

    These events occur right after the workflow execution is started.

decider event: DecisionTaskComplete

    This event is spawned when you signal a completed decision task.

You can start activities from within a decider.  To do so, you schedule the activity.  Once you do this, activity tasks are generated, which can be polled for

activity event: 
