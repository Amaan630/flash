using UnityEngine;
using System.Collections.Generic;

[RequireComponent(typeof(Rigidbody))]
public class CarController : MonoBehaviour
{
    [Header("Movement Settings")]
    public float maxSpeed = 10f;
    public float acceleration = 5f;
    public float deceleration = 10f;
    public float turnSpeed = 90f; // Degrees per second
    
    [Header("Detection Settings")]
    public float frontDetectionDistance = 15f;
    public float sideDetectionDistance = 5f;
    public float stopDistance = 2f;
    public LayerMask obstacleLayer; // Set this in the inspector to include cars and other obstacles
    public LayerMask roadLayer; // Layer for road detection
    
    [Header("Debug Visualization")]
    public bool showDebugRays = true;
    public Color rayColorNormal = Color.green;
    public Color rayColorHit = Color.red;

    private float currentSpeed;
    private Vector3 currentDirection;
    private Rigidbody rb;
    private bool isAtIntersection = false;
    private IntersectionController currentIntersection;
    private Transform carModel;
    private Quaternion targetRotation;
    private bool isTurning = false;
    private Vector3 nextWaypoint;
    private bool hasNextWaypoint = false;
    private float stuckTimer = 0f;
    private float stuckThreshold = 5f;
    private Vector3 lastPosition;
    private bool isWaitingAtRedLight = false;

    private void Start()
    {
        rb = GetComponent<Rigidbody>();
        rb.useGravity = false;
        rb.constraints = RigidbodyConstraints.FreezeRotation | RigidbodyConstraints.FreezePositionY;

        if (transform.childCount > 0)
        {
            carModel = transform.GetChild(0);
        }
        else
        {
            Debug.LogError("Car has no children. Cannot determine forward direction.");
        }

        UpdateForwardDirection();
        lastPosition = transform.position;
    }

    private void UpdateForwardDirection()
    {
        currentDirection = transform.forward;
    }

    private void FixedUpdate()
    {
        // Check if car is stuck
        CheckIfStuck();
        
        // Always check for obstacles
        CheckForObstacles();

        // Handle movement based on current state
        if (!isAtIntersection && !isTurning)
        {
            // Normal driving on road
            StayOnRoad();
            Move();
        }
        else if (isAtIntersection)
        {
            HandleIntersection();
        }

        if (isTurning)
        {
            Turn();
        }
    }

    private void CheckIfStuck()
    {
        // If car hasn't moved significantly in a while, it might be stuck
        if (Vector3.Distance(transform.position, lastPosition) < 0.1f && currentSpeed > 0.5f)
        {
            stuckTimer += Time.fixedDeltaTime;
            if (stuckTimer > stuckThreshold)
            {
                // Try to unstuck by slightly moving to the side
                Vector3 sideStep = transform.right * Random.Range(-1f, 1f);
                rb.MovePosition(rb.position + sideStep * 0.5f);
                stuckTimer = 0f;
            }
        }
        else
        {
            stuckTimer = 0f;
            lastPosition = transform.position;
        }
    }

    private void StayOnRoad()
    {
        // Cast rays to the sides to detect road edges
        RaycastHit hitLeft, hitRight;
        bool hitLeftRoad = Physics.Raycast(transform.position, -transform.right, out hitLeft, sideDetectionDistance, roadLayer);
        bool hitRightRoad = Physics.Raycast(transform.position, transform.right, out hitRight, sideDetectionDistance, roadLayer);

        if (showDebugRays)
        {
            Debug.DrawRay(transform.position, -transform.right * sideDetectionDistance, hitLeftRoad ? rayColorHit : rayColorNormal);
            Debug.DrawRay(transform.position, transform.right * sideDetectionDistance, hitRightRoad ? rayColorHit : rayColorNormal);
        }

        // If we're about to leave the road, steer back
        if (!hitLeftRoad && hitRightRoad)
        {
            // Steer right
            transform.Rotate(Vector3.up, 0.5f);
        }
        else if (hitLeftRoad && !hitRightRoad)
        {
            // Steer left
            transform.Rotate(Vector3.up, -0.5f);
        }
        
        // Cast a ray forward to check if we're approaching the end of the road
        RaycastHit hitForward;
        if (!Physics.Raycast(transform.position, transform.forward, out hitForward, frontDetectionDistance, roadLayer))
        {
            // We're approaching the end of the road, slow down
            AdjustSpeed(maxSpeed * 0.5f);
            
            // Look for a turn
            LookForTurn();
        }
    }

    private void LookForTurn()
    {
        // Cast rays in different directions to find where the road continues
        RaycastHit hit;
        Vector3[] directions = new Vector3[] { transform.right, -transform.right };
        
        foreach (Vector3 dir in directions)
        {
            if (Physics.Raycast(transform.position, dir, out hit, sideDetectionDistance * 2, roadLayer))
            {
                if (!isTurning)
                {
                    StartTurn(dir);
                    break;
                }
            }
        }
    }

    private void HandleIntersection()
    {
        if (currentIntersection == null) return;
        
        IntersectionController.TrafficLightState lightState = currentIntersection.GetLightState(currentDirection);
        
        if (lightState == IntersectionController.TrafficLightState.Red)
        {
            // Stop at red light
            AdjustSpeed(0);
            isWaitingAtRedLight = true;
        }
        else if (lightState == IntersectionController.TrafficLightState.Yellow)
        {
            // Slow down at yellow light if not already in intersection
            if (!isWaitingAtRedLight)
            {
                AdjustSpeed(maxSpeed * 0.3f);
            }
            else
            {
                // If we were waiting at a red light, keep waiting
                AdjustSpeed(0);
            }
        }
        else if (lightState == IntersectionController.TrafficLightState.Green)
        {
            // Go at green light
            isWaitingAtRedLight = false;
            
            if (!isTurning && !hasNextWaypoint)
            {
                // Choose a direction based on the intersection's options
                Vector3 newDirection = currentIntersection.GetRandomValidDirection();
                StartTurn(newDirection);
            }
            else if (hasNextWaypoint)
            {
                // Move towards the next waypoint
                Vector3 directionToWaypoint = (nextWaypoint - transform.position).normalized;
                StartTurn(directionToWaypoint);
            }
        }
    }

    private void Move()
    {
        Vector3 movement = currentDirection * currentSpeed * Time.fixedDeltaTime;
        rb.MovePosition(rb.position + movement);
    }

    private void StartTurn(Vector3 newDirection)
    {
        targetRotation = Quaternion.LookRotation(newDirection, Vector3.up);
        isTurning = true;
    }

    private void Turn()
    {
        transform.rotation = Quaternion.RotateTowards(transform.rotation, targetRotation, turnSpeed * Time.deltaTime);
        UpdateForwardDirection();

        if (Quaternion.Angle(transform.rotation, targetRotation) < 0.1f)
        {
            isTurning = false;
            hasNextWaypoint = false;
            
            // If we were at an intersection, we're now exiting it
            if (isAtIntersection)
            {
                ExitIntersection();
            }
        }
    }

    private void CheckForObstacles()
    {
        // Cast multiple rays in a fan pattern to better detect obstacles
        float raySpread = 15f; // degrees
        int rayCount = 3;
        
        bool obstacleDetected = false;
        float closestObstacleDistance = frontDetectionDistance;
        
        for (int i = 0; i < rayCount; i++)
        {
            float angle = (i - (rayCount - 1) / 2f) * raySpread;
            Vector3 rayDirection = Quaternion.Euler(0, angle, 0) * currentDirection;
            
            RaycastHit hit;
            if (Physics.Raycast(transform.position, rayDirection, out hit, frontDetectionDistance, obstacleLayer))
            {
                obstacleDetected = true;
                closestObstacleDistance = Mathf.Min(closestObstacleDistance, hit.distance);
                
                if (showDebugRays)
                {
                    Debug.DrawRay(transform.position, rayDirection * hit.distance, rayColorHit);
                }
            }
            else if (showDebugRays)
            {
                Debug.DrawRay(transform.position, rayDirection * frontDetectionDistance, rayColorNormal);
            }
        }
        
        if (obstacleDetected)
        {
            // Calculate target speed based on distance to obstacle
            float distanceToObstacle = closestObstacleDistance - stopDistance;
            float targetSpeed = Mathf.Clamp(maxSpeed * (distanceToObstacle / frontDetectionDistance), 0, maxSpeed);
            AdjustSpeed(targetSpeed);
            
            // If very close to obstacle, try to steer around it
            if (closestObstacleDistance < stopDistance * 1.5f && !isAtIntersection)
            {
                // Check if there's space to the left or right
                RaycastHit leftHit, rightHit;
                bool canGoLeft = !Physics.Raycast(transform.position, -transform.right, out leftHit, sideDetectionDistance, obstacleLayer);
                bool canGoRight = !Physics.Raycast(transform.position, transform.right, out rightHit, sideDetectionDistance, obstacleLayer);
                
                if (canGoLeft && !canGoRight)
                {
                    transform.Rotate(Vector3.up, -1f);
                }
                else if (!canGoLeft && canGoRight)
                {
                    transform.Rotate(Vector3.up, 1f);
                }
                else if (canGoLeft && canGoRight)
                {
                    // Choose randomly
                    transform.Rotate(Vector3.up, Random.Range(0, 2) == 0 ? -1f : 1f);
                }
            }
        }
        else
        {
            // No obstacles, drive at max speed if not at intersection
            if (!isAtIntersection || (isAtIntersection && currentIntersection.GetLightState(currentDirection) == IntersectionController.TrafficLightState.Green))
            {
                AdjustSpeed(maxSpeed);
            }
        }
    }

    private void AdjustSpeed(float targetSpeed)
    {
        if (currentSpeed > targetSpeed)
        {
            currentSpeed = Mathf.Max(targetSpeed, currentSpeed - deceleration * Time.fixedDeltaTime);
        }
        else
        {
            currentSpeed = Mathf.Min(targetSpeed, currentSpeed + acceleration * Time.fixedDeltaTime);
        }
    }

    public void ApproachIntersection(IntersectionController intersection)
    {
        currentIntersection = intersection;
        isAtIntersection = true;
        
        // Immediately check the light state
        IntersectionController.TrafficLightState lightState = intersection.GetLightState(currentDirection);
        if (lightState != IntersectionController.TrafficLightState.Green)
        {
            AdjustSpeed(0);
            isWaitingAtRedLight = true;
        }
    }

    public void ExitIntersection()
    {
        isAtIntersection = false;
        currentIntersection = null;
        isWaitingAtRedLight = false;
        AdjustSpeed(maxSpeed);
    }
    
    public void SetNextWaypoint(Vector3 waypoint)
    {
        nextWaypoint = waypoint;
        hasNextWaypoint = true;
    }
    
    private void OnDrawGizmos()
    {
        if (hasNextWaypoint)
        {
            Gizmos.color = Color.blue;
            Gizmos.DrawLine(transform.position, nextWaypoint);
            Gizmos.DrawSphere(nextWaypoint, 0.5f);
        }
    }
}