using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BehaviorManager
{
    private NPCController npc;
    private IBehavior currentBehavior;
    private Stack<IBehavior> interruptedBehaviors = new Stack<IBehavior>();

    public BehaviorManager(NPCController npcController)
    {
        npc = npcController;
    }

    public void ExecuteCurrentBehavior()
    {
        // Check for reactive behaviors
        // foreach (var reaction in npc.AssignedReactions)
        // {
        //     if (reaction.CanExecute())
        //     {
        //         InterruptCurrentBehavior();
        //         currentBehavior = reaction;
        //         break;
        //     }
        // }

        // Execute current behavior
        if (currentBehavior != null && currentBehavior.CanExecute())
        {
            currentBehavior.Execute();
        }
        else
        {
            ResumeInterruptedBehavior();
        }
    }

    public void SetCurrentBehavior(IBehavior behavior)
    {
        if (currentBehavior != null)
        {
            InterruptCurrentBehavior();
        }
        currentBehavior = behavior;
    }

    private void InterruptCurrentBehavior()
    {
        if (currentBehavior != null)
        {
            currentBehavior.Interrupt();
            interruptedBehaviors.Push(currentBehavior);
        }
    }

    private void ResumeInterruptedBehavior()
    {
        if (interruptedBehaviors.Count > 0)
        {
            currentBehavior = interruptedBehaviors.Pop();
            currentBehavior.Resume();
        }
    }
}