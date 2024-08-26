using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class ReactiveBehavior : IBehavior
{
    [SerializeField]
    private string reactionName;
    
    [SerializeField]
    private float reactionDuration;

    public bool CheckCondition() {
        throw new NotImplementedException();
    }

    public bool CanExecute() {
        throw new NotImplementedException();
    }

    public void Execute() {
        throw new NotImplementedException();
    }

    public void Interrupt() {
        throw new NotImplementedException();
    }

    public void Resume() {
        throw new NotImplementedException();
    }
}