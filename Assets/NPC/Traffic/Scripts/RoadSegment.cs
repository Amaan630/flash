using UnityEngine;
using System.Collections.Generic;

public class RoadSegment : MonoBehaviour
{
    [Header("Road Properties")]
    public float roadWidth = 8f;
    public bool isTwoWay = true;
    public bool isDeadEnd = false;
    
    [Header("Waypoints")]
    public Transform startPoint;
    public Transform endPoint;
    public List<Transform> laneWaypoints = new List<Transform>();
    
    [Header("Debug Visualization")]
    public bool showRoadBounds = true;
    public Color roadBoundsColor = Color.white;
    
    private void Start()
    {
        // Auto-create waypoints if none exist
        if (laneWaypoints.Count == 0)
        {
            CreateDefaultWaypoints();
        }
        
        // Ensure this object has a collider for road detection
        if (GetComponent<Collider>() == null)
        {
            BoxCollider roadCollider = gameObject.AddComponent<BoxCollider>();
            roadCollider.isTrigger = false; // Physical collider for road detection
            
            // Set size based on road properties
            Vector3 size = transform.localScale;
            size.y = 0.1f; // Thin collider
            roadCollider.size = size;
        }
    }
    
    private void CreateDefaultWaypoints()
    {
        if (startPoint == null || endPoint == null)
        {
            Debug.LogError("Road segment " + gameObject.name + " is missing start or end point!");
            return;
        }
        
        // Create waypoints along the road
        Vector3 roadDirection = (endPoint.position - startPoint.position).normalized;
        float roadLength = Vector3.Distance(startPoint.position, endPoint.position);
        
        int waypointCount = Mathf.Max(2, Mathf.FloorToInt(roadLength / 10f)); // One waypoint every 10 units
        
        for (int i = 0; i < waypointCount; i++)
        {
            float t = (float)i / (waypointCount - 1);
            Vector3 position = Vector3.Lerp(startPoint.position, endPoint.position, t);
            
            // Create waypoint object
            GameObject waypointObj = new GameObject("Waypoint_" + i);
            waypointObj.transform.position = position;
            waypointObj.transform.forward = roadDirection;
            waypointObj.transform.parent = transform;
            
            laneWaypoints.Add(waypointObj.transform);
        }
        
        // If two-way road, create waypoints for the opposite direction
        if (isTwoWay)
        {
            roadDirection = -roadDirection;
            
            for (int i = 0; i < waypointCount; i++)
            {
                float t = (float)i / (waypointCount - 1);
                Vector3 position = Vector3.Lerp(endPoint.position, startPoint.position, t);
                position += transform.right * (roadWidth / 2f); // Offset to create a second lane
                
                // Create waypoint object
                GameObject waypointObj = new GameObject("Waypoint_Return_" + i);
                waypointObj.transform.position = position;
                waypointObj.transform.forward = roadDirection;
                waypointObj.transform.parent = transform;
                
                laneWaypoints.Add(waypointObj.transform);
            }
        }
    }
    
    public Transform GetNextWaypoint(Vector3 currentPosition, Vector3 currentDirection)
    {
        if (laneWaypoints.Count == 0)
            return null;
        
        // Find the closest waypoint in the direction of travel
        Transform closestWaypoint = null;
        float closestDistance = float.MaxValue;
        float bestDirectionMatch = -1f;
        
        foreach (Transform waypoint in laneWaypoints)
        {
            Vector3 toWaypoint = waypoint.position - currentPosition;
            float distance = toWaypoint.magnitude;
            
            // Check if this waypoint is in the direction of travel
            float directionMatch = Vector3.Dot(currentDirection, toWaypoint.normalized);
            
            // Only consider waypoints in front of the car
            if (directionMatch > 0)
            {
                // If we have multiple close waypoints, prefer the one that best matches our direction
                if (distance < closestDistance || (Mathf.Approximately(distance, closestDistance) && directionMatch > bestDirectionMatch))
                {
                    closestDistance = distance;
                    closestWaypoint = waypoint;
                    bestDirectionMatch = directionMatch;
                }
            }
        }
        
        return closestWaypoint;
    }
    
    private void OnDrawGizmos()
    {
        if (showRoadBounds)
        {
            Gizmos.color = roadBoundsColor;
            
            // Draw road bounds
            if (startPoint != null && endPoint != null)
            {
                Vector3 roadDirection = (endPoint.position - startPoint.position).normalized;
                Vector3 roadRight = Vector3.Cross(Vector3.up, roadDirection).normalized;
                
                Vector3 startLeft = startPoint.position - roadRight * (roadWidth / 2f);
                Vector3 startRight = startPoint.position + roadRight * (roadWidth / 2f);
                Vector3 endLeft = endPoint.position - roadRight * (roadWidth / 2f);
                Vector3 endRight = endPoint.position + roadRight * (roadWidth / 2f);
                
                // Draw road outline
                Gizmos.DrawLine(startLeft, startRight);
                Gizmos.DrawLine(startRight, endRight);
                Gizmos.DrawLine(endRight, endLeft);
                Gizmos.DrawLine(endLeft, startLeft);
                
                // Draw center line
                Gizmos.color = Color.yellow;
                Gizmos.DrawLine(startPoint.position, endPoint.position);
            }
            
            // Draw waypoints
            Gizmos.color = Color.cyan;
            foreach (Transform waypoint in laneWaypoints)
            {
                if (waypoint != null)
                {
                    Gizmos.DrawSphere(waypoint.position, 0.5f);
                    Gizmos.DrawRay(waypoint.position, waypoint.forward * 2f);
                }
            }
        }
    }
} 