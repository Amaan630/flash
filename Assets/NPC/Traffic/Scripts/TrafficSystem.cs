using System.Collections.Generic;
using UnityEngine;

public class TrafficSystem : MonoBehaviour
{
    [Header("Lane Discovery")]
    [SerializeField] private float connectionRadius = 10f;
    [SerializeField] private float maxForwardTurnAngle = 135f;
    [SerializeField] private float adjacentLaneSearchRadius = 5f;
    [SerializeField] private float minimumAdjacentDirectionDot = 0.75f;

    [Header("Intersection Flow")]
    [SerializeField] private float intersectionRadius = 12f;
    [SerializeField] private float intersectionReleaseDelay = 1.2f;
    [SerializeField] private int maxCarsPerIntersection = 1;

    private readonly List<TrafficLane> lanes = new List<TrafficLane>();
    private readonly List<RuntimeIntersection> intersections = new List<RuntimeIntersection>();
    private readonly Dictionary<TrafficLane, RuntimeIntersection> laneEndIntersections = new Dictionary<TrafficLane, RuntimeIntersection>();

    public IReadOnlyList<TrafficLane> Lanes => lanes;

    private void Awake()
    {
        Rebuild();
    }

    [ContextMenu("Rebuild Traffic")]
    public void Rebuild()
    {
        lanes.Clear();
        intersections.Clear();
        laneEndIntersections.Clear();

        lanes.AddRange(GetComponentsInChildren<TrafficLane>());
        lanes.RemoveAll(lane => lane == null || !lane.HasEnoughPoints());

        BuildLaneConnections();
        BuildIntersections();
    }

    public TrafficLane GetRandomLane()
    {
        if (lanes.Count == 0)
        {
            Rebuild();
        }

        return lanes.Count > 0 ? lanes[Random.Range(0, lanes.Count)] : null;
    }

    public TrafficLane FindAdjacentLane(TrafficLane currentLane, Vector3 position, bool preferLeft, float clearanceDistance, LayerMask blockingMask, CarController requester)
    {
        if (currentLane == null)
        {
            return null;
        }

        TrafficLane bestLeft = null;
        TrafficLane bestRight = null;
        float bestLeftDistance = float.PositiveInfinity;
        float bestRightDistance = float.PositiveInfinity;
        Vector3 currentForward = currentLane.GetForward(currentLane.ProjectDistance(position));

        foreach (TrafficLane candidate in lanes)
        {
            if (candidate == null || candidate == currentLane)
            {
                continue;
            }

            float candidateDistanceAlongLane = candidate.ProjectDistance(position);
            Vector3 candidatePoint = candidate.GetPoint(candidateDistanceAlongLane);
            Vector3 candidateForward = candidate.GetForward(candidateDistanceAlongLane);

            if (Vector3.Dot(currentForward, candidateForward) < minimumAdjacentDirectionDot)
            {
                continue;
            }

            Vector3 toCandidate = candidatePoint - position;
            toCandidate.y = 0f;
            float distance = toCandidate.magnitude;

            if (distance > adjacentLaneSearchRadius)
            {
                continue;
            }

            if (!IsDrivingSpaceClear(candidate, position, clearanceDistance, blockingMask, requester))
            {
                continue;
            }

            float side = Vector3.Dot(Vector3.Cross(Vector3.up, currentForward), toCandidate.normalized);

            if (side < 0f && distance < bestLeftDistance)
            {
                bestLeft = candidate;
                bestLeftDistance = distance;
            }
            else if (side > 0f && distance < bestRightDistance)
            {
                bestRight = candidate;
                bestRightDistance = distance;
            }
        }

        return preferLeft ? bestLeft ?? bestRight : bestRight ?? bestLeft;
    }

    public bool CanEnterNextIntersection(CarController car, TrafficLane lane)
    {
        if (lane == null || !laneEndIntersections.TryGetValue(lane, out RuntimeIntersection intersection))
        {
            return true;
        }

        return intersection.TryEnter(car);
    }

    public void ExitIntersection(CarController car, TrafficLane previousLane)
    {
        if (previousLane == null || !laneEndIntersections.TryGetValue(previousLane, out RuntimeIntersection intersection))
        {
            return;
        }

        intersection.Exit(car);
    }

    public bool IsDrivingSpaceClear(TrafficLane lane, Vector3 nearPosition, float clearanceDistance, LayerMask blockingMask, CarController requester)
    {
        if (lane == null)
        {
            return false;
        }

        float distanceAlongLane = lane.ProjectDistance(nearPosition);
        Vector3 point = lane.GetPoint(distanceAlongLane);
        Vector3 forward = lane.GetForward(distanceAlongLane);
        Vector3 center = point + forward * (clearanceDistance * 0.5f) + Vector3.up * 1.1f;
        Vector3 halfExtents = new Vector3(lane.LaneWidth * 0.45f, 0.7f, clearanceDistance * 0.5f);
        Quaternion rotation = Quaternion.LookRotation(forward, Vector3.up);
        Collider[] hits = Physics.OverlapBox(center, halfExtents, rotation, blockingMask, QueryTriggerInteraction.Ignore);

        foreach (Collider hit in hits)
        {
            if (!IsTrafficBlocker(hit, requester))
            {
                continue;
            }

            return false;
        }

        return true;
    }

    public bool IsTrafficBlocker(Collider hit, CarController requester)
    {
        return GetTrafficBlockerReason(hit, requester, out bool blocksTraffic) != null && blocksTraffic;
    }

    public string GetTrafficBlockerReason(Collider hit, CarController requester, out bool blocksTraffic)
    {
        blocksTraffic = false;

        if (hit == null)
        {
            return "null collider";
        }

        if (requester != null && hit.GetComponentInParent<CarController>() == requester)
        {
            return "ignored: own car";
        }

        if (hit.GetComponentInParent<TrafficLane>() != null ||
            hit.GetComponentInParent<TrafficSystem>() != null)
        {
            return "ignored: traffic setup object";
        }

        TrafficObstacle obstacle = hit.GetComponentInParent<TrafficObstacle>();

        if (obstacle != null)
        {
            blocksTraffic = true;
            return $"blocks: TrafficObstacle on {obstacle.name}";
        }

        CarController car = hit.GetComponentInParent<CarController>();

        if (car != null)
        {
            blocksTraffic = true;
            return $"blocks: traffic car {car.name}";
        }

        return "ignored: unmarked collider";
    }

    private void BuildLaneConnections()
    {
        foreach (TrafficLane lane in lanes)
        {
            List<TrafficLane> next = new List<TrafficLane>();
            Vector3 laneEnd = lane.GetEndPoint();
            Vector3 laneForward = lane.GetEndForward();

            foreach (TrafficLane candidate in lanes)
            {
                if (candidate == lane)
                {
                    continue;
                }

                float distance = Vector3.Distance(laneEnd, candidate.GetStartPoint());

                if (distance > connectionRadius)
                {
                    continue;
                }

                float angle = Vector3.Angle(laneForward, candidate.GetStartForward());

                if (angle > maxForwardTurnAngle)
                {
                    continue;
                }

                next.Add(candidate);
            }

            lane.SetConnections(next);
        }
    }

    private void BuildIntersections()
    {
        foreach (TrafficLane lane in lanes)
        {
            RuntimeIntersection intersection = FindOrCreateIntersection(lane.GetEndPoint());
            intersection.AddLane(lane);
            laneEndIntersections[lane] = intersection;
        }
    }

    private RuntimeIntersection FindOrCreateIntersection(Vector3 position)
    {
        foreach (RuntimeIntersection intersection in intersections)
        {
            if (Vector3.Distance(intersection.Center, position) <= intersectionRadius)
            {
                intersection.AddPoint(position);
                return intersection;
            }
        }

        RuntimeIntersection newIntersection = new RuntimeIntersection(position, maxCarsPerIntersection, intersectionReleaseDelay);
        intersections.Add(newIntersection);
        return newIntersection;
    }

    private void OnDrawGizmosSelected()
    {
        if (!Application.isPlaying)
        {
            Rebuild();
        }

        Gizmos.color = Color.yellow;

        foreach (RuntimeIntersection intersection in intersections)
        {
            Gizmos.DrawWireSphere(intersection.Center, intersectionRadius);
        }
    }

    private class RuntimeIntersection
    {
        private readonly Queue<CarController> waitingCars = new Queue<CarController>();
        private readonly HashSet<CarController> queuedCars = new HashSet<CarController>();
        private readonly HashSet<CarController> carsInside = new HashSet<CarController>();
        private readonly List<TrafficLane> lanes = new List<TrafficLane>();
        private readonly int maxCarsInside;
        private readonly float releaseDelay;
        private float nextEntryTime;

        public RuntimeIntersection(Vector3 center, int maxCarsInside, float releaseDelay)
        {
            Center = center;
            this.maxCarsInside = Mathf.Max(1, maxCarsInside);
            this.releaseDelay = Mathf.Max(0f, releaseDelay);
        }

        public Vector3 Center { get; private set; }

        public void AddPoint(Vector3 point)
        {
            Center = Vector3.Lerp(Center, point, 0.5f);
        }

        public void AddLane(TrafficLane lane)
        {
            if (lane != null && !lanes.Contains(lane))
            {
                lanes.Add(lane);
            }
        }

        public bool TryEnter(CarController car)
        {
            if (car == null)
            {
                return false;
            }

            if (carsInside.Contains(car))
            {
                return true;
            }

            if (!queuedCars.Contains(car))
            {
                waitingCars.Enqueue(car);
                queuedCars.Add(car);
            }

            RemoveMissingQueuedCars();

            if (waitingCars.Count == 0 || waitingCars.Peek() != car)
            {
                return false;
            }

            if (carsInside.Count >= maxCarsInside || Time.time < nextEntryTime)
            {
                return false;
            }

            waitingCars.Dequeue();
            queuedCars.Remove(car);
            carsInside.Add(car);
            nextEntryTime = Time.time + releaseDelay;
            return true;
        }

        public void Exit(CarController car)
        {
            if (car == null)
            {
                return;
            }

            carsInside.Remove(car);
            queuedCars.Remove(car);
        }

        private void RemoveMissingQueuedCars()
        {
            while (waitingCars.Count > 0 && waitingCars.Peek() == null)
            {
                waitingCars.Dequeue();
            }
        }
    }
}
