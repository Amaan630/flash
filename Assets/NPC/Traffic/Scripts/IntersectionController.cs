using UnityEngine;
using System.Collections;
using System.Collections.Generic;

[RequireComponent(typeof(Collider))]
public class IntersectionController : MonoBehaviour
{
    [Header("Intersection Configuration")]
    public bool canTurnRight = true;
    public bool canTurnLeft = true;
    public bool canGoStraight = true;
    public bool isTJunction = false;
    public bool isDeadEnd = false;
    
    // [Header("Traffic Light Settings")]
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
    
    [Header("Visual Indicators")]
    public GameObject northSouthLightObject;
    public GameObject eastWestLightObject;
    public Material redMaterial;
    public Material yellowMaterial;
    public Material greenMaterial;
    
    [Header("Waypoints")]
    public List<Transform> entryPoints = new List<Transform>();
    public List<Transform> exitPoints = new List<Transform>();
    
    private Dictionary<Transform, List<Transform>> validExitsByEntry = new Dictionary<Transform, List<Transform>>();
    private bool isInitialized = false;

    private void Start()
    {
        StartCoroutine(TrafficLightCycle());
        InitializeWaypoints();
        UpdateLightVisuals();
    }
    
    private void InitializeWaypoints()
    {
        if (isInitialized) return;
        
        // For each entry point, determine valid exit points
        foreach (Transform entry in entryPoints)
        {
            List<Transform> validExits = new List<Transform>();
            
            foreach (Transform exit in exitPoints)
            {
                // Skip if entry and exit are the same road (no U-turns)
                if (Vector3.Dot(entry.forward, -exit.forward) > 0.9f)
                    continue;
                
                // Determine if this is a left turn, right turn, or straight
                Vector3 entryToExit = exit.position - entry.position;
                float dot = Vector3.Dot(entry.right, entryToExit.normalized);
                float forwardDot = Vector3.Dot(entry.forward, entryToExit.normalized);
                
                bool isRightTurn = dot > 0.5f;
                bool isLeftTurn = dot < -0.5f;
                bool isStraight = forwardDot > 0.5f;
                
                // Add to valid exits if the turn type is allowed
                if ((isRightTurn && canTurnRight) || 
                    (isLeftTurn && canTurnLeft) || 
                    (isStraight && canGoStraight))
                {
                    validExits.Add(exit);
                }
            }
            
            validExitsByEntry[entry] = validExits;
        }
        
        isInitialized = true;
    }

    private void OnTriggerEnter(Collider other)
    {
        CarController car = other.GetComponent<CarController>();
        if (car != null)
        {
            car.ApproachIntersection(this);
            
            // Find the closest exit point for this car
            if (exitPoints.Count > 0)
            {
                // Find the entry point this car is coming from
                Transform closestEntry = FindClosestEntryPoint(other.transform.position, other.transform.forward);
                
                if (closestEntry != null && validExitsByEntry.ContainsKey(closestEntry))
                {
                    List<Transform> validExits = validExitsByEntry[closestEntry];
                    if (validExits.Count > 0)
                    {
                        // Choose a random valid exit
                        Transform chosenExit = validExits[Random.Range(0, validExits.Count)];
                        car.SetNextWaypoint(chosenExit.position);
                    }
                }
            }
        }
    }
    
    private Transform FindClosestEntryPoint(Vector3 position, Vector3 direction)
    {
        Transform closest = null;
        float closestDot = -1f;
        
        foreach (Transform entry in entryPoints)
        {
            Vector3 toEntry = (entry.position - position).normalized;
            float dot = Vector3.Dot(direction, toEntry);
            
            // Higher dot product means the car is more aligned with this entry point
            if (dot > closestDot)
            {
                closestDot = dot;
                closest = entry;
            }
        }
        
        return closest;
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
        List<Vector3> possibleDirections = new List<Vector3>();
        
        if (canGoStraight && !isDeadEnd)
        {
            possibleDirections.Add(transform.forward);
        }
        
        if (canTurnRight)
        {
            possibleDirections.Add(transform.right);
        }
        
        if (canTurnLeft && !isTJunction)
        {
            possibleDirections.Add(-transform.right);
        }
        
        if (possibleDirections.Count == 0)
        {
            Debug.LogWarning("No valid directions at intersection: " + gameObject.name);
            return transform.forward;
        }
        
        return possibleDirections[Random.Range(0, possibleDirections.Count)];
    }

    private IEnumerator TrafficLightCycle()
    {
        while (true)
        {
            // North-South Green, East-West Red
            currentStateNorthSouth = TrafficLightState.Green;
            currentStateEastWest = TrafficLightState.Red;
            UpdateLightVisuals();
            yield return new WaitForSeconds(greenDuration);

            // North-South Yellow, East-West Red
            currentStateNorthSouth = TrafficLightState.Yellow;
            UpdateLightVisuals();
            yield return new WaitForSeconds(yellowDuration);

            // North-South Red, East-West Green
            currentStateNorthSouth = TrafficLightState.Red;
            currentStateEastWest = TrafficLightState.Green;
            UpdateLightVisuals();
            yield return new WaitForSeconds(greenDuration);

            // North-South Red, East-West Yellow
            currentStateEastWest = TrafficLightState.Yellow;
            UpdateLightVisuals();
            yield return new WaitForSeconds(yellowDuration);
        }
    }
    
    private void UpdateLightVisuals()
    {
        if (northSouthLightObject != null)
        {
            Renderer renderer = northSouthLightObject.GetComponent<Renderer>();
            if (renderer != null)
            {
                switch (currentStateNorthSouth)
                {
                    case TrafficLightState.Red:
                        renderer.material = redMaterial;
                        break;
                    case TrafficLightState.Yellow:
                        renderer.material = yellowMaterial;
                        break;
                    case TrafficLightState.Green:
                        renderer.material = greenMaterial;
                        break;
                }
            }
        }
        
        if (eastWestLightObject != null)
        {
            Renderer renderer = eastWestLightObject.GetComponent<Renderer>();
            if (renderer != null)
            {
                switch (currentStateEastWest)
                {
                    case TrafficLightState.Red:
                        renderer.material = redMaterial;
                        break;
                    case TrafficLightState.Yellow:
                        renderer.material = yellowMaterial;
                        break;
                    case TrafficLightState.Green:
                        renderer.material = greenMaterial;
                        break;
                }
            }
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
    
    private void OnDrawGizmos()
    {
        // Draw entry points
        Gizmos.color = Color.blue;
        foreach (Transform entry in entryPoints)
        {
            if (entry != null)
            {
                Gizmos.DrawSphere(entry.position, 1f);
                Gizmos.DrawRay(entry.position, entry.forward * 3f);
            }
        }
        
        // Draw exit points
        Gizmos.color = Color.green;
        foreach (Transform exit in exitPoints)
        {
            if (exit != null)
            {
                Gizmos.DrawSphere(exit.position, 1f);
                Gizmos.DrawRay(exit.position, exit.forward * 3f);
            }
        }
        
        // Draw intersection bounds
        Gizmos.color = Color.yellow;
        Collider col = GetComponent<Collider>();
        if (col != null && col is BoxCollider)
        {
            BoxCollider box = col as BoxCollider;
            Gizmos.DrawWireCube(transform.position + box.center, box.size);
        }
    }
}