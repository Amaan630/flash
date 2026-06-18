using System.Collections.Generic;
using UnityEngine;

public class TrafficLane : MonoBehaviour
{
    [Header("Lane Segment")]
    [SerializeField] private List<Transform> points = new List<Transform>();
    [SerializeField] private float speedLimitMph = 30f;
    [SerializeField] private float laneWidth = 3.5f;

    [Header("Debug")]
    [SerializeField] private bool drawGizmos = true;
    [SerializeField] private Color centerColor = Color.cyan;
    [SerializeField] private Color edgeColor = Color.white;
    [SerializeField] private Color connectionColor = Color.yellow;

    private readonly List<Vector3> samples = new List<Vector3>();
    private readonly List<float> sampleDistances = new List<float>();
    private readonly List<TrafficLane> nextLanes = new List<TrafficLane>();
    private float length;
    private bool cacheDirty = true;

    public float SpeedLimitMph => speedLimitMph;
    public float LaneWidth => laneWidth;
    public float Length
    {
        get
        {
            RebuildCacheIfNeeded();
            return length;
        }
    }

    public IReadOnlyList<TrafficLane> NextLanes => nextLanes;

    private void OnValidate()
    {
        speedLimitMph = Mathf.Max(1f, speedLimitMph);
        laneWidth = Mathf.Max(0.5f, laneWidth);
        cacheDirty = true;
    }

    private void Awake()
    {
        RebuildCacheIfNeeded();
    }

    public void SetConnections(IEnumerable<TrafficLane> lanes)
    {
        nextLanes.Clear();

        foreach (TrafficLane lane in lanes)
        {
            if (lane != null && lane != this && !nextLanes.Contains(lane))
            {
                nextLanes.Add(lane);
            }
        }
    }

    public TrafficLane PickNextLane()
    {
        if (nextLanes.Count == 0)
        {
            return null;
        }

        if (nextLanes.Count == 1)
        {
            return nextLanes[0];
        }

        return nextLanes[Random.Range(0, nextLanes.Count)];
    }

    public Vector3 GetPoint(float distance)
    {
        RebuildCacheIfNeeded();

        if (samples.Count == 0)
        {
            return transform.position;
        }

        if (samples.Count == 1)
        {
            return samples[0];
        }

        distance = Mathf.Clamp(distance, 0f, length);

        for (int i = 1; i < samples.Count; i++)
        {
            if (sampleDistances[i] < distance)
            {
                continue;
            }

            float previousDistance = sampleDistances[i - 1];
            float segmentLength = sampleDistances[i] - previousDistance;
            float t = segmentLength <= 0.001f ? 0f : (distance - previousDistance) / segmentLength;
            return Vector3.Lerp(samples[i - 1], samples[i], t);
        }

        return samples[samples.Count - 1];
    }

    public Vector3 GetForward(float distance)
    {
        Vector3 from = GetPoint(distance);
        Vector3 to = GetPoint(Mathf.Min(distance + 1f, Length));
        Vector3 direction = to - from;
        direction.y = 0f;

        if (direction.sqrMagnitude <= 0.001f)
        {
            to = GetPoint(Mathf.Max(distance - 1f, 0f));
            direction = from - to;
            direction.y = 0f;
        }

        return direction.sqrMagnitude > 0.001f ? direction.normalized : transform.forward;
    }

    public Vector3 GetStartPoint()
    {
        RebuildCacheIfNeeded();
        return samples.Count > 0 ? samples[0] : transform.position;
    }

    public Vector3 GetEndPoint()
    {
        RebuildCacheIfNeeded();
        return samples.Count > 0 ? samples[samples.Count - 1] : transform.position;
    }

    public Vector3 GetStartForward()
    {
        return GetForward(0f);
    }

    public Vector3 GetEndForward()
    {
        return GetForward(Mathf.Max(0f, Length - 1f));
    }

    public bool IsAtEnd(float distance, float threshold)
    {
        return Length > 0.001f && distance >= Length - threshold;
    }

    public float ProjectDistance(Vector3 worldPosition)
    {
        RebuildCacheIfNeeded();

        if (samples.Count < 2)
        {
            return 0f;
        }

        float bestDistance = 0f;
        float bestSqrDistance = float.PositiveInfinity;

        for (int i = 1; i < samples.Count; i++)
        {
            Vector3 a = samples[i - 1];
            Vector3 b = samples[i];
            Vector3 segment = b - a;
            float segmentSqrLength = segment.sqrMagnitude;

            if (segmentSqrLength <= 0.001f)
            {
                continue;
            }

            float t = Mathf.Clamp01(Vector3.Dot(worldPosition - a, segment) / segmentSqrLength);
            Vector3 closest = Vector3.Lerp(a, b, t);
            float sqrDistance = (worldPosition - closest).sqrMagnitude;

            if (sqrDistance < bestSqrDistance)
            {
                bestSqrDistance = sqrDistance;
                bestDistance = sampleDistances[i - 1] + Vector3.Distance(a, closest);
            }
        }

        return Mathf.Clamp(bestDistance, 0f, Length);
    }

    public bool HasEnoughPoints()
    {
        return points.Count >= 2 && points[0] != null && points[points.Count - 1] != null;
    }

    private void RebuildCacheIfNeeded()
    {
        if (!cacheDirty)
        {
            return;
        }

        samples.Clear();
        sampleDistances.Clear();
        length = 0f;

        List<Vector3> validPoints = new List<Vector3>();

        foreach (Transform point in points)
        {
            if (point != null)
            {
                validPoints.Add(point.position);
            }
        }

        if (validPoints.Count == 0)
        {
            cacheDirty = false;
            return;
        }

        if (validPoints.Count == 1)
        {
            samples.Add(validPoints[0]);
            sampleDistances.Add(0f);
            cacheDirty = false;
            return;
        }

        int subdivisionsPerSegment = 10;

        for (int i = 0; i < validPoints.Count - 1; i++)
        {
            for (int step = 0; step < subdivisionsPerSegment; step++)
            {
                float t = step / (float)subdivisionsPerSegment;
                AddSample(CatmullRom(validPoints, i, t));
            }
        }

        AddSample(validPoints[validPoints.Count - 1]);
        cacheDirty = false;
    }

    private void AddSample(Vector3 sample)
    {
        if (samples.Count > 0)
        {
            length += Vector3.Distance(samples[samples.Count - 1], sample);
        }

        samples.Add(sample);
        sampleDistances.Add(length);
    }

    private Vector3 CatmullRom(List<Vector3> validPoints, int segmentIndex, float t)
    {
        Vector3 p0 = validPoints[Mathf.Max(segmentIndex - 1, 0)];
        Vector3 p1 = validPoints[segmentIndex];
        Vector3 p2 = validPoints[Mathf.Min(segmentIndex + 1, validPoints.Count - 1)];
        Vector3 p3 = validPoints[Mathf.Min(segmentIndex + 2, validPoints.Count - 1)];

        float t2 = t * t;
        float t3 = t2 * t;

        return 0.5f * (
            2f * p1 +
            (-p0 + p2) * t +
            (2f * p0 - 5f * p1 + 4f * p2 - p3) * t2 +
            (-p0 + 3f * p1 - 3f * p2 + p3) * t3);
    }

    private void OnDrawGizmos()
    {
        if (!drawGizmos)
        {
            return;
        }

        cacheDirty = true;
        RebuildCacheIfNeeded();

        if (samples.Count < 2)
        {
            return;
        }

        Gizmos.color = centerColor;

        for (int i = 1; i < samples.Count; i++)
        {
            Gizmos.DrawLine(samples[i - 1], samples[i]);
        }

        DrawLaneEdges();
        DrawConnections();
    }

    private void DrawLaneEdges()
    {
        Gizmos.color = edgeColor;
        float halfWidth = laneWidth * 0.5f;

        for (int i = 1; i < samples.Count; i++)
        {
            Vector3 previousForward = (samples[i] - samples[i - 1]).normalized;
            Vector3 previousRight = Vector3.Cross(Vector3.up, previousForward).normalized;

            Vector3 aLeft = samples[i - 1] - previousRight * halfWidth;
            Vector3 aRight = samples[i - 1] + previousRight * halfWidth;
            Vector3 bLeft = samples[i] - previousRight * halfWidth;
            Vector3 bRight = samples[i] + previousRight * halfWidth;

            Gizmos.DrawLine(aLeft, bLeft);
            Gizmos.DrawLine(aRight, bRight);
        }
    }

    private void DrawConnections()
    {
        Gizmos.color = connectionColor;

        foreach (TrafficLane nextLane in nextLanes)
        {
            if (nextLane == null)
            {
                continue;
            }

            Gizmos.DrawLine(GetEndPoint(), nextLane.GetStartPoint());
        }
    }
}
