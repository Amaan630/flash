using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public interface IBehavior
{
    bool CanExecute();
    void Execute();
    void Interrupt();
    void Resume();
}