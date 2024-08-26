using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ScheduleManager
{
    private NPCController npc;
    private float currentTime;

    public ScheduleManager(NPCController npcController)
    {
        npc = npcController;
    }

    private bool IsWorkTime()
    {
        return currentTime >= npc.AssignedWork.StartTime && currentTime < npc.AssignedWork.EndTime;
    }

    public void UpdateSchedule()
    {
        if (IsWorkTime() || true)
        {
            AssignBehavior(npc.AssignedWork);
        }
        else
        {
            AssignBehavior(SelectLeisureActivity());
        }
    }

    private void AssignBehavior(RoutineBehavior behavior)
    {
        if (behavior.Type == BehaviorType.Work)
        {
            // Handle work-specific logic
        }
        else if (behavior.Type == BehaviorType.Leisure)
        {
            // Handle leisure-specific logic
        }
        
        npc.behaviorManager.SetCurrentBehavior(behavior);
    }

    private RoutineBehavior SelectLeisureActivity()
    {
        return new ExploringActivity();
        // Use PersonalityTraits to select a suitable leisure activity
        // based on the NPC's personality
    }
}