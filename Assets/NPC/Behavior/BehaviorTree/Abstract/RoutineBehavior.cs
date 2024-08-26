using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class RoutineBehavior : IBehavior
{
    public BehaviorType Type { get; }
    public PersonalityType[] SuitablePersonalities { get; }

    public bool CanExecute()
    {
        throw new NotImplementedException();
    }

    public void Execute()
    {
        throw new NotImplementedException();
    }

    public void Interrupt()
    {
        throw new NotImplementedException();
    }

    public void Resume()
    {
        throw new NotImplementedException();
    }
}