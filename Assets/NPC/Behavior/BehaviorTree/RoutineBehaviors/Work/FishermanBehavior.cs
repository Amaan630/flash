using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "FishermanBehavior", menuName = "NPC/Behavior/BehaviorTree/RoutineBehaviors/Work/FishermanBehavior")]
public class FishermanBehavior : WorkBehavior
{
    [SerializeField] private float fishCatchRate = 0.1f; // fish per second
    private float fishCaught;

    public new PersonalityType[] SuitablePersonalities => throw new System.NotImplementedException();

    public new void PerformWork()
    {
        fishCaught += fishCatchRate * Time.deltaTime;
        Debug.Log($"Fisherman caught {fishCaught} fish so far.");
    }
}