using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class CarController : MonoBehaviour
{
    public float maxSpeed = 10f;
    public float acceleration = 5f;
    public float deceleration = 10f;
    public float turnSpeed = 90f; // Degrees per second
    public float detectionDistance = 10f;
    public float stopDistance = 2f;
    public LayerMask obstacleLayer; // Set this in the inspector to include cars and other obstacles

    private float currentSpeed;
    private Vector3 currentDirection;
    private Rigidbody rb;
    private bool isAtIntersection = false;
    private IntersectionController currentIntersection;
    private Transform firstChild;
    private Quaternion targetRotation;
    private bool isTurning = false;

    private void Start()
    {
        rb = GetComponent<Rigidbody>();
        rb.useGravity = false;
        rb.constraints = RigidbodyConstraints.FreezeRotation | RigidbodyConstraints.FreezePositionY;

        if (transform.childCount > 0)
        {
            firstChild = transform.GetChild(0);
        }
        else
        {
            Debug.LogError("Car has no children. Cannot determine forward direction.");
        }

        UpdateForwardDirection();
    }

    private void UpdateForwardDirection()
    {
        if (firstChild != null)
        {
            currentDirection = -firstChild.right;
        }
    }

    private void FixedUpdate()
    {
        CheckForObstacles();

        if (!isAtIntersection && !isTurning)
        {
            Move();
        }
        else if (isAtIntersection && currentIntersection.GetLightState(currentDirection) == IntersectionController.TrafficLightState.Green)
        {
            if (!isTurning)
            {
                StartTurn(currentIntersection.GetRandomValidDirection());
            }
        }

        if (isTurning)
        {
            Turn();
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
            isAtIntersection = false;
            currentIntersection = null;
        }
    }

    private void CheckForObstacles()
    {
        RaycastHit hit;
        if (Physics.Raycast(transform.position, currentDirection, out hit, detectionDistance, obstacleLayer))
        {
            float distanceToObstacle = hit.distance - stopDistance;
            float targetSpeed = Mathf.Clamp(maxSpeed * (distanceToObstacle / detectionDistance), 0, maxSpeed);
            AdjustSpeed(targetSpeed);
        }
        else
        {
            AdjustSpeed(maxSpeed);
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
        
        if (intersection.GetLightState(currentDirection) != IntersectionController.TrafficLightState.Green)
        {
            AdjustSpeed(0);
        }
    }

    public void ExitIntersection()
    {
        if (!isTurning)
        {
            isAtIntersection = false;
            currentIntersection = null;
            AdjustSpeed(maxSpeed);
        }
    }
}