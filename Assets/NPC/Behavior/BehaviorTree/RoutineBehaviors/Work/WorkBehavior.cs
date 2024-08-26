using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class WorkBehavior : RoutineBehavior
{
    public new BehaviorType Type => BehaviorType.Work;
    
    [SerializeField] protected string jobTitle;
    [SerializeField] protected float startTime; // in hours, e.g., 9.0 for 9:00 AM
    [SerializeField] protected float endTime;   // in hours, e.g., 17.0 for 5:00 PM

    public string JobTitle => jobTitle;
    public float StartTime => startTime;
    public float EndTime => endTime;

    public void PerformWork()
    {
        Debug.Log($"Performing work as {JobTitle}");
    }

    public new void Execute()
    {
        Debug.Log($"Working as {JobTitle}");
        PerformWork();
    }

    public new bool CanExecute() => true;

    public new void Interrupt()
    {
        Debug.Log($"Interrupting work as {JobTitle}");
    }

    public new void Resume()
    {
        Debug.Log($"Resuming work as {JobTitle}");
    }
}