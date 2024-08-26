using UnityEngine;
using System.Collections.Generic;

public class NPCController : MonoBehaviour
{
    public PersonalityType Personality;
    
    public List<ReactiveBehavior> assignedReactions = new List<ReactiveBehavior>();
    
    public WorkBehavior assignedWork;

    public BehaviorManager behaviorManager;
    private ScheduleManager scheduleManager;

    public IReadOnlyList<ReactiveBehavior> AssignedReactions => assignedReactions.AsReadOnly();
    public WorkBehavior AssignedWork => assignedWork;

    void Start()
    {
        behaviorManager = new BehaviorManager(this);
        scheduleManager = new ScheduleManager(this);
    }

    void Update()
    {
        scheduleManager.UpdateSchedule();
        behaviorManager.ExecuteCurrentBehavior();
    }
}