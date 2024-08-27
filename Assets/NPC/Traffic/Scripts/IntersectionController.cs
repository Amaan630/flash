using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Collider))]
public class IntersectionController : MonoBehaviour
{
    public bool canTurnRight = true;
    public bool canTurnLeft = true;
    public bool canGoStraight = true;

    public enum TrafficLightState
    {
        Red,
        Yellow,
        Green
    }

    public TrafficLightState currentStateNorthSouth = TrafficLightState.Red;
    public TrafficLightState currentStateEastWest = TrafficLightState.Green;

    public float greenDuration = 30f;
    public float yellowDuration = 5f;
    public float redDuration = 35f; // Slightly longer to account for yellow in the other direction

    private void Start()
    {
        StartCoroutine(TrafficLightCycle());
    }

    private void OnTriggerEnter(Collider other)
    {
        CarController car = other.GetComponent<CarController>();
        if (car != null)
        {
            car.ApproachIntersection(this);
        }
    }

    private void OnTriggerExit(Collider other)
    {
        CarController car = other.GetComponent<CarController>();
        if (car != null)
        {
            car.ExitIntersection();
        }
    }

    public Vector3 GetRandomValidDirection()
    {
        Vector3[] possibleDirections = new Vector3[3];
        int validDirections = 0;

        if (canGoStraight)
        {
            possibleDirections[validDirections++] = transform.forward;
        }
        if (canTurnRight)
        {
            possibleDirections[validDirections++] = transform.right;
        }
        if (canTurnLeft)
        {
            possibleDirections[validDirections++] = -transform.right;
        }

        if (validDirections == 0)
        {
            Debug.LogWarning("No valid directions at intersection: " + gameObject.name);
            return transform.forward;
        }

        return possibleDirections[Random.Range(0, validDirections)];
    }

    private IEnumerator TrafficLightCycle()
    {
        while (true)
        {
            // North-South Green, East-West Red
            currentStateNorthSouth = TrafficLightState.Green;
            currentStateEastWest = TrafficLightState.Red;
            yield return new WaitForSeconds(greenDuration);

            // North-South Yellow, East-West Red
            currentStateNorthSouth = TrafficLightState.Yellow;
            yield return new WaitForSeconds(yellowDuration);

            // North-South Red, East-West Green
            currentStateNorthSouth = TrafficLightState.Red;
            currentStateEastWest = TrafficLightState.Green;
            yield return new WaitForSeconds(greenDuration);

            // North-South Red, East-West Yellow
            currentStateEastWest = TrafficLightState.Yellow;
            yield return new WaitForSeconds(yellowDuration);
        }
    }

    public TrafficLightState GetLightState(Vector3 approachDirection)
    {
        // Assuming the intersection's forward is North, right is East
        float dot = Vector3.Dot(transform.forward, approachDirection);
        if (Mathf.Abs(dot) > 0.707f) // cos(45°), to determine if closer to N-S or E-W
        {
            return currentStateNorthSouth;
        }
        else
        {
            return currentStateEastWest;
        }
    }
}