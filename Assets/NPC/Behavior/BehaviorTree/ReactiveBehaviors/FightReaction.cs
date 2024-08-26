using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class FightReaction : ReactiveBehavior
{
    [SerializeField] private float fightDuration = 2f;
    private bool isColliding = false;
    private bool isFighting = false;
    private float fightStartTime;

    public new bool CheckCondition()
    {
        return isColliding && !isFighting;
    }

    public new bool CanExecute()
    {
        return !isFighting;
    }

    public new void Execute()
    {
        // StartCoroutine(FightCoroutine());
        FightCoroutine();
    }

    public new void Interrupt()
    {
        // For now, we'll allow the fight to continue even if interrupted
        Debug.Log("Fight interrupted, but continuing...");
    }

    public new void Resume()
    {
        // Nothing to do here, as we're not interrupting the fight
        Debug.Log("Resuming fight (if it was still ongoing)");
    }

    private IEnumerator FightCoroutine()
    {
        isFighting = true;
        fightStartTime = Time.time;

        Debug.Log("Started fighting!");

        while (Time.time - fightStartTime < fightDuration)
        {
            Debug.Log("Fighting in progress...");
            yield return new WaitForSeconds(0.5f); // Log every half second
        }

        Debug.Log("Finished fighting!");
        isFighting = false;
    }

    private void OnCollisionEnter(Collision collision)
    {
        isColliding = true;
    }

    private void OnCollisionExit(Collision collision)
    {
        isColliding = false;
    }
}