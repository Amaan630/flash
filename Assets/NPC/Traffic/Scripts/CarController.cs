using System.IO;
using System.Text;
using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class CarController : MonoBehaviour
{
    private const float MphToMetersPerSecond = 0.44704f;

    [Header("Traffic")]
    [SerializeField] private TrafficSystem trafficSystem;
    [SerializeField] private TrafficLane currentLane;
    [SerializeField] private bool startAtClosestPoint = true;

    [Header("City Driving")]
    [SerializeField] private float fallbackSpeedLimitMph = 30f;
    [SerializeField] private float speedVarianceMph = 3f;
    [SerializeField] private float accelerationMphPerSecond = 8f;
    [SerializeField] private float brakingMphPerSecond = 24f;
    [SerializeField] private float jerkMetersPerSecondCubed = 12f;
    [SerializeField] private float turnRateDegreesPerSecond = 150f;
    [SerializeField] private float lookAheadSeconds = 1.2f;
    [SerializeField] private float minimumLookAheadMeters = 7f;

    [Header("Blockers")]
    [SerializeField] private LayerMask blockingMask = ~0;
    [SerializeField] private float blockerLookAheadMeters = 18f;
    [SerializeField] private float blockerBrakeDistanceMeters = 8f;
    [SerializeField] private float blockedStopBufferMeters = 2.5f;
    [SerializeField] private float blockedHardStopDistanceMeters = 0.75f;
    [SerializeField] private Vector3 blockerBoxHalfExtents = new Vector3(0.9f, 0.45f, 0.75f);

    [Header("Lane Changes")]
    [SerializeField] private bool allowLaneChanges = true;
    [SerializeField] private bool allowCruisingLaneChanges = true;
    [SerializeField] private bool preferLeftLaneChanges;
    [SerializeField] private float laneChangeLengthMeters = 18f;
    [SerializeField] private float laneChangeClearanceMeters = 16f;
    [SerializeField] private float laneChangeCooldownSeconds = 4f;
    [SerializeField] private float noCruisingLaneChangeNearLaneEndMeters = 22f;
    [SerializeField] private Vector2 cruisingLaneChangeInterval = new Vector2(8f, 18f);

    [Header("Intersections")]
    [SerializeField] private float intersectionRequestDistance = 7f;
    [SerializeField] private float nextLanePlanDistance = 30f;
    [SerializeField] private float intersectionSlowdownDistance = 26f;
    [SerializeField] private float straightIntersectionMph = 22f;
    [SerializeField] private float mildTurnMph = 18f;
    [SerializeField] private float sharpTurnMph = 10f;
    [SerializeField] private float fullStopDistance = 3f;

    [Header("Debug")]
    [SerializeField] private bool drawDebug = true;
    [SerializeField] private bool verboseDebugLogs;
    [SerializeField] private bool writeTrafficTraceLog = true;
    [SerializeField] private float traceLogIntervalSeconds = 0.2f;
    [SerializeField] private int maxBlockerHitDetails = 16;
    [SerializeField] private TrafficLane plannedNextLane;
    [SerializeField] private string slowdownReason;
    [SerializeField] private string lastDebugEvent;
    [SerializeField] private string lastBlockerName;

    private Rigidbody rb;
    private float laneDistance;
    private float currentSpeedMetersPerSecond;
    private float currentAccelerationMetersPerSecond;
    private float personalSpeedOffsetMph;
    private bool isChangingLanes;
    private TrafficLane laneChangeFromLane;
    private TrafficLane laneChangeToLane;
    private float laneChangeStartDistance;
    private float laneChangeTargetStartDistance;
    private float laneChangeProgress;
    private float nextCruisingLaneChangeTime;
    private float lastLaneChangeTime;
    private TrafficLane reservedIntersectionLane;
    private TrafficLane pendingIntersectionExitLane;
    private bool wasBlockedLastFrame;
    private StreamWriter traceLogWriter;
    private string traceLogPath;
    private float nextTraceLogTime;
    private float lastBaseDesiredSpeed;
    private float lastFinalDesiredSpeed;
    private float lastApproachSpeedLimit;
    private float lastStopApproachSpeedLimit;
    private float lastBlockerDistance;
    private float lastBlockerBrakeFactor;
    private float lastLookAheadDistance;
    private float lastTurnAngleToTarget;
    private bool lastNeededIntersectionPermission;
    private bool lastReservedIntersection;
    private bool lastBlockerFound;
    private bool lastTriedLaneChangeForBlocker;
    private Vector3 lastTargetPoint;
    private Vector3 lastToTarget;
    private Vector3 lastMoveDelta;
    private string lastBlockerHitDetails;

    public TrafficLane CurrentLane => currentLane;
    public float CurrentSpeedMph => currentSpeedMetersPerSecond / MphToMetersPerSecond;
    public string SlowdownReason => slowdownReason;

    private void Awake()
    {
        rb = GetComponent<Rigidbody>();
        rb.useGravity = false;
        rb.isKinematic = true;
        rb.interpolation = RigidbodyInterpolation.Interpolate;
        rb.collisionDetectionMode = CollisionDetectionMode.ContinuousSpeculative;
        rb.constraints = RigidbodyConstraints.FreezeRotationX | RigidbodyConstraints.FreezeRotationZ | RigidbodyConstraints.FreezePositionY;
        maxBlockerHitDetails = Mathf.Max(0, maxBlockerHitDetails);
        personalSpeedOffsetMph = Random.Range(-speedVarianceMph, speedVarianceMph);
        ScheduleNextCruisingLaneChange();
    }

    private void Start()
    {
        OpenTraceLog();

        if (trafficSystem == null)
        {
            trafficSystem = GetComponentInParent<TrafficSystem>();
        }

        if (trafficSystem == null)
        {
            trafficSystem = FindObjectOfType<TrafficSystem>();
        }

        if (trafficSystem == null)
        {
            Debug.LogWarning($"{name} has no TrafficSystem. Put a TrafficSystem on the TRAFFIC parent.", this);
            return;
        }

        if (currentLane == null)
        {
            currentLane = trafficSystem.GetRandomLane();
        }

        if (currentLane == null)
        {
            Debug.LogWarning($"{name} has no TrafficLane.", this);
            return;
        }

        laneDistance = startAtClosestPoint ? currentLane.ProjectDistance(transform.position) : 0f;
        SnapToLane();
        WriteTrafficSetupSnapshot();
    }

    private void FixedUpdate()
    {
        if (trafficSystem == null || currentLane == null)
        {
            ApplySpeed(0f);
            MoveForward();
            return;
        }

        float desiredSpeed = GetDesiredSpeedMetersPerSecond();
        lastBaseDesiredSpeed = desiredSpeed;
        lastFinalDesiredSpeed = desiredSpeed;
        lastApproachSpeedLimit = float.PositiveInfinity;
        lastStopApproachSpeedLimit = float.PositiveInfinity;
        lastBlockerDistance = -1f;
        lastBlockerBrakeFactor = 1f;
        lastNeededIntersectionPermission = false;
        lastReservedIntersection = false;
        lastBlockerFound = false;
        lastTriedLaneChangeForBlocker = false;
        lastBlockerHitDetails = "not checked this frame";
        slowdownReason = "";
        PlanNextLaneIfNeeded();

        lastApproachSpeedLimit = GetApproachSpeedMetersPerSecond();
        desiredSpeed = Mathf.Min(desiredSpeed, lastApproachSpeedLimit);

        lastNeededIntersectionPermission = NeedsIntersectionPermission();

        if (lastNeededIntersectionPermission)
        {
            lastReservedIntersection = TryReserveIntersection();
        }

        if (lastNeededIntersectionPermission && !lastReservedIntersection)
        {
            slowdownReason = "intersection";
            lastStopApproachSpeedLimit = GetStopApproachSpeedMetersPerSecond();
            desiredSpeed = Mathf.Min(desiredSpeed, lastStopApproachSpeedLimit);
        }
        else if (FindBlockerAhead(out float blockerDistance, out Collider blocker))
        {
            slowdownReason = "blocked";
            lastBlockerName = blocker != null ? blocker.name : "";
            lastBlockerDistance = blockerDistance;
            lastBlockerFound = true;

            bool startedAvoidanceLaneChange = false;

            if (!isChangingLanes && CanCruisingLaneChange())
            {
                lastTriedLaneChangeForBlocker = true;
                startedAvoidanceLaneChange = TryStartLaneChange();
            }

            if (!startedAvoidanceLaneChange)
            {
                desiredSpeed = Mathf.Min(desiredSpeed, GetBlockedApproachSpeedMetersPerSecond(blockerDistance));

                if (blockerDistance <= blockedHardStopDistanceMeters)
                {
                    currentSpeedMetersPerSecond = 0f;
                    currentAccelerationMetersPerSecond = 0f;
                    desiredSpeed = 0f;
                }
            }
        }
        else
        {
            lastBlockerName = "";

            if (wasBlockedLastFrame)
            {
                currentAccelerationMetersPerSecond = Mathf.Max(0f, currentAccelerationMetersPerSecond);
            }
        }

        wasBlockedLastFrame = lastBlockerFound;
        lastFinalDesiredSpeed = desiredSpeed;
        ApplySpeed(desiredSpeed);
        SteerAndMove();
        WriteTraceFrame();
    }

    public void SetLane(TrafficLane lane)
    {
        currentLane = lane;

        if (currentLane == null)
        {
            return;
        }

        laneDistance = currentLane.ProjectDistance(transform.position);
        SnapToLane();
    }

    private float GetDesiredSpeedMetersPerSecond()
    {
        float speedLimitMph = currentLane != null ? currentLane.SpeedLimitMph : fallbackSpeedLimitMph;
        return Mathf.Max(3f, speedLimitMph + personalSpeedOffsetMph) * MphToMetersPerSecond;
    }

    private bool NeedsIntersectionPermission()
    {
        if (currentLane == null || reservedIntersectionLane == currentLane)
        {
            return false;
        }

        return currentLane.IsAtEnd(laneDistance, intersectionRequestDistance);
    }

    private void PlanNextLaneIfNeeded()
    {
        if (currentLane == null || plannedNextLane != null || isChangingLanes)
        {
            return;
        }

        if (currentLane.IsAtEnd(laneDistance, nextLanePlanDistance))
        {
            plannedNextLane = currentLane.PickNextLane();
            LogTrafficEvent($"planned next lane: {LaneName(currentLane)} -> {LaneName(plannedNextLane)}");
        }
    }

    private float GetApproachSpeedMetersPerSecond()
    {
        if (currentLane == null || isChangingLanes || !currentLane.IsAtEnd(laneDistance, intersectionSlowdownDistance))
        {
            return float.PositiveInfinity;
        }

        float distanceToEnd = Mathf.Max(0f, currentLane.Length - laneDistance);

        if (plannedNextLane == null)
        {
            return GetSpeedForDistanceToTarget(0f, distanceToEnd);
        }

        float turnAngle = Vector3.Angle(currentLane.GetEndForward(), plannedNextLane.GetStartForward());
        float targetMph = GetTargetMphForTurn(turnAngle);
        float targetSpeed = targetMph * MphToMetersPerSecond;
        return GetSpeedForDistanceToTarget(targetSpeed, distanceToEnd);
    }

    private float GetStopApproachSpeedMetersPerSecond()
    {
        float distanceToEnd = currentLane == null ? 0f : Mathf.Max(0f, currentLane.Length - laneDistance);
        return distanceToEnd <= fullStopDistance
            ? 0f
            : GetSpeedForDistanceToTarget(0f, distanceToEnd);
    }

    private float GetBlockedApproachSpeedMetersPerSecond(float blockerDistance)
    {
        float stoppingDistance = Mathf.Max(0f, blockerDistance - blockedStopBufferMeters);
        float blockedSpeed = stoppingDistance <= 0f
            ? 0f
            : GetSpeedForDistanceToTarget(0f, stoppingDistance);

        float brakeFactor = Mathf.InverseLerp(0f, blockerBrakeDistanceMeters, stoppingDistance);
        lastBlockerBrakeFactor = brakeFactor;
        return blockedSpeed;
    }

    private float GetSpeedForDistanceToTarget(float targetSpeed, float distance)
    {
        float braking = Mathf.Max(0.1f, brakingMphPerSecond * MphToMetersPerSecond);
        float comfortableSpeed = Mathf.Sqrt(targetSpeed * targetSpeed + 2f * braking * Mathf.Max(0f, distance));
        return Mathf.Max(targetSpeed, comfortableSpeed);
    }

    private float GetTargetMphForTurn(float turnAngle)
    {
        if (turnAngle < 20f)
        {
            return straightIntersectionMph;
        }

        if (turnAngle < 70f)
        {
            return mildTurnMph;
        }

        return sharpTurnMph;
    }

    private bool TryReserveIntersection()
    {
        if (trafficSystem.CanEnterNextIntersection(this, currentLane))
        {
            reservedIntersectionLane = currentLane;
            return true;
        }

        return false;
    }

    private void ApplySpeed(float desiredSpeedMetersPerSecond)
    {
        if (desiredSpeedMetersPerSecond <= 0.01f && currentSpeedMetersPerSecond <= 0.01f)
        {
            currentSpeedMetersPerSecond = 0f;
            currentAccelerationMetersPerSecond = 0f;
            return;
        }

        float desiredAcceleration = desiredSpeedMetersPerSecond < currentSpeedMetersPerSecond
            ? -brakingMphPerSecond * MphToMetersPerSecond
            : accelerationMphPerSecond * MphToMetersPerSecond;

        currentAccelerationMetersPerSecond = Mathf.MoveTowards(
            currentAccelerationMetersPerSecond,
            desiredAcceleration,
            jerkMetersPerSecondCubed * Time.fixedDeltaTime);

        currentSpeedMetersPerSecond += currentAccelerationMetersPerSecond * Time.fixedDeltaTime;

        if (desiredAcceleration < 0f && currentSpeedMetersPerSecond < desiredSpeedMetersPerSecond)
        {
            currentSpeedMetersPerSecond = desiredSpeedMetersPerSecond;
        }
        else if (desiredAcceleration > 0f && currentSpeedMetersPerSecond > desiredSpeedMetersPerSecond)
        {
            currentSpeedMetersPerSecond = desiredSpeedMetersPerSecond;
        }

        currentSpeedMetersPerSecond = Mathf.Max(0f, currentSpeedMetersPerSecond);
    }

    private void SteerAndMove()
    {
        laneDistance += currentSpeedMetersPerSecond * Time.fixedDeltaTime;
        HandleLaneEnd();

        if (allowCruisingLaneChanges && CanCruisingLaneChange() && Time.time >= nextCruisingLaneChangeTime)
        {
            TryStartLaneChange();
            ScheduleNextCruisingLaneChange();
        }

        float lookAheadDistance = Mathf.Max(minimumLookAheadMeters, currentSpeedMetersPerSecond * lookAheadSeconds);
        lastLookAheadDistance = lookAheadDistance;
        Vector3 targetPoint = GetLaneTargetPoint(laneDistance + lookAheadDistance);
        lastTargetPoint = targetPoint;
        Vector3 toTarget = targetPoint - rb.position;
        toTarget.y = 0f;
        lastToTarget = toTarget;
        lastTurnAngleToTarget = toTarget.sqrMagnitude > 0.001f
            ? Vector3.SignedAngle(transform.forward, toTarget.normalized, Vector3.up)
            : 0f;

        if (toTarget.sqrMagnitude > 0.001f)
        {
            Quaternion targetRotation = Quaternion.LookRotation(toTarget.normalized, Vector3.up);
            rb.MoveRotation(Quaternion.RotateTowards(rb.rotation, targetRotation, turnRateDegreesPerSecond * Time.fixedDeltaTime));
        }

        MoveForward();
        UpdateLaneChange();
    }

    private void HandleLaneEnd()
    {
        if (isChangingLanes || !currentLane.IsAtEnd(laneDistance, 0.2f))
        {
            return;
        }

        TrafficLane previousLane = currentLane;
        TrafficLane nextLane = plannedNextLane != null ? plannedNextLane : currentLane.PickNextLane();

        if (nextLane == null)
        {
            currentSpeedMetersPerSecond = 0f;
            currentAccelerationMetersPerSecond = 0f;
            laneDistance = currentLane.Length;
            slowdownReason = "dead end";
            LogTrafficEvent($"dead end at lane {LaneName(currentLane)}. No auto-connected next lane.");
            return;
        }

        LogTrafficEvent($"starting lane transition: {LaneName(previousLane)} -> {LaneName(nextLane)}");
        laneChangeFromLane = previousLane;
        laneChangeToLane = nextLane;
        laneChangeStartDistance = previousLane.Length;
        laneChangeTargetStartDistance = 0f;
        laneChangeProgress = 0f;
        isChangingLanes = true;
        pendingIntersectionExitLane = previousLane;
        reservedIntersectionLane = null;
        plannedNextLane = null;
    }

    private void MoveForward()
    {
        lastMoveDelta = transform.forward * currentSpeedMetersPerSecond * Time.fixedDeltaTime;
        rb.MovePosition(rb.position + lastMoveDelta);
    }

    private Vector3 GetLaneTargetPoint(float distance)
    {
        if (!isChangingLanes || laneChangeFromLane == null || laneChangeToLane == null)
        {
            return currentLane.GetPoint(distance);
        }

        float distanceSinceLaneChangeStart = Mathf.Max(0f, distance - laneChangeStartDistance);
        float sourceDistance = laneChangeStartDistance + distanceSinceLaneChangeStart;
        float targetDistance = laneChangeTargetStartDistance + distanceSinceLaneChangeStart;
        Vector3 fromPoint = laneChangeFromLane.GetPoint(sourceDistance);
        Vector3 toPoint = laneChangeToLane.GetPoint(targetDistance);
        float t = Mathf.SmoothStep(0f, 1f, Mathf.Clamp01(laneChangeProgress / laneChangeLengthMeters));
        return Vector3.Lerp(fromPoint, toPoint, t);
    }

    private void UpdateLaneChange()
    {
        if (!isChangingLanes)
        {
            return;
        }

        laneChangeProgress += currentSpeedMetersPerSecond * Time.fixedDeltaTime;

        if (laneChangeProgress < laneChangeLengthMeters)
        {
            return;
        }

        currentLane = laneChangeToLane;
        laneDistance = currentLane.ProjectDistance(rb.position);
        trafficSystem.ExitIntersection(this, pendingIntersectionExitLane);
        LogTrafficEvent($"finished lane transition. Current lane={LaneName(currentLane)}, laneDistance={laneDistance:0.0}/{currentLane.Length:0.0}, speed={CurrentSpeedMph:0.0} mph");
        laneChangeFromLane = null;
        laneChangeToLane = null;
        laneChangeProgress = 0f;
        isChangingLanes = false;
        reservedIntersectionLane = null;
        pendingIntersectionExitLane = null;
        plannedNextLane = null;
        lastLaneChangeTime = Time.time;
    }

    private bool FindBlockerAhead(out float distance, out Collider blocker)
    {
        distance = blockerLookAheadMeters;
        blocker = null;
        Vector3 origin = rb.position + Vector3.up * 0.9f;
        RaycastHit[] hits = Physics.BoxCastAll(
            origin,
            blockerBoxHalfExtents,
            transform.forward,
            rb.rotation,
            blockerLookAheadMeters,
            blockingMask,
            QueryTriggerInteraction.Ignore);

        bool found = false;
        StringBuilder hitDetails = new StringBuilder();
        int detailCount = 0;

        foreach (RaycastHit hit in hits)
        {
            string reason = trafficSystem.GetTrafficBlockerReason(hit.collider, this, out bool blocksTraffic);

            if (detailCount < maxBlockerHitDetails)
            {
                hitDetails.Append("#");
                hitDetails.Append(detailCount + 1);
                hitDetails.Append(" collider=");
                hitDetails.Append(hit.collider != null ? hit.collider.name : "None");
                hitDetails.Append(" root=");
                hitDetails.Append(hit.collider != null ? hit.collider.transform.root.name : "None");
                hitDetails.Append(" distance=");
                hitDetails.Append(hit.distance.ToString("0.00"));
                hitDetails.Append(" reason=");
                hitDetails.Append(reason);
                hitDetails.AppendLine();
            }

            detailCount++;

            if (!blocksTraffic)
            {
                continue;
            }

            if (!found || hit.distance < distance)
            {
                distance = hit.distance;
                blocker = hit.collider;
                found = true;
            }
        }

        if (detailCount > maxBlockerHitDetails)
        {
            hitDetails.Append("... ");
            hitDetails.Append(detailCount - maxBlockerHitDetails);
            hitDetails.AppendLine(" more blocker sensor hits omitted");
        }

        lastBlockerHitDetails = hitDetails.Length > 0 ? hitDetails.ToString() : "no collider hits";
        return found;
    }

    private bool TryStartLaneChange()
    {
        if (!allowLaneChanges || Time.time < lastLaneChangeTime + laneChangeCooldownSeconds)
        {
            return false;
        }

        TrafficLane targetLane = trafficSystem.FindAdjacentLane(
            currentLane,
            rb.position,
            preferLeftLaneChanges,
            laneChangeClearanceMeters,
            blockingMask,
            this);

        if (targetLane == null)
        {
            LogTrafficEvent($"wanted lane change from {LaneName(currentLane)} but no clear adjacent lane was found");
            return false;
        }

        LogTrafficEvent($"starting lane change: {LaneName(currentLane)} -> {LaneName(targetLane)}");
        laneChangeFromLane = currentLane;
        laneChangeToLane = targetLane;
        laneChangeStartDistance = currentLane.ProjectDistance(rb.position);
        laneChangeTargetStartDistance = targetLane.ProjectDistance(rb.position);
        laneChangeProgress = 0f;
        isChangingLanes = true;
        plannedNextLane = null;
        return true;
    }

    private bool CanCruisingLaneChange()
    {
        if (!allowLaneChanges || isChangingLanes || currentLane == null)
        {
            return false;
        }

        if (Time.time < lastLaneChangeTime + laneChangeCooldownSeconds)
        {
            return false;
        }

        float distanceToLaneEnd = currentLane.Length - laneDistance;
        return distanceToLaneEnd > noCruisingLaneChangeNearLaneEndMeters;
    }

    private void ScheduleNextCruisingLaneChange()
    {
        float min = Mathf.Min(cruisingLaneChangeInterval.x, cruisingLaneChangeInterval.y);
        float max = Mathf.Max(cruisingLaneChangeInterval.x, cruisingLaneChangeInterval.y);
        nextCruisingLaneChangeTime = Time.time + Random.Range(min, max);
    }

    private void SnapToLane()
    {
        Vector3 point = currentLane.GetPoint(laneDistance);
        Vector3 forward = currentLane.GetForward(laneDistance);
        rb.position = new Vector3(point.x, rb.position.y, point.z);
        rb.rotation = Quaternion.LookRotation(forward, Vector3.up);
        reservedIntersectionLane = null;
        isChangingLanes = false;
        plannedNextLane = null;
        pendingIntersectionExitLane = null;
        LogTrafficEvent($"snapped to lane {LaneName(currentLane)}, laneDistance={laneDistance:0.0}/{currentLane.Length:0.0}");
    }

    private void LogTrafficEvent(string message)
    {
        lastDebugEvent = message;

        if (verboseDebugLogs)
        {
            Debug.Log($"[TrafficCar] {name}: {message}", this);
        }

        WriteTraceLine($"EVENT {Time.time:0.000} {message}");
    }

    private string LaneName(TrafficLane lane)
    {
        return lane != null ? lane.name : "None";
    }

    private void OnDrawGizmosSelected()
    {
        if (!drawDebug || currentLane == null)
        {
            return;
        }

        Vector3 position = Application.isPlaying && rb != null ? rb.position : transform.position;
        Vector3 forward = Application.isPlaying ? transform.forward : currentLane.GetForward(currentLane.ProjectDistance(position));
        Vector3 origin = position + Vector3.up * 0.9f;

        Gizmos.color = string.IsNullOrEmpty(slowdownReason) ? Color.green : Color.red;
        Gizmos.matrix = Matrix4x4.TRS(origin + forward * blockerLookAheadMeters * 0.5f, Quaternion.LookRotation(forward, Vector3.up), Vector3.one);
        Gizmos.DrawWireCube(Vector3.zero, new Vector3(blockerBoxHalfExtents.x * 2f, blockerBoxHalfExtents.y * 2f, blockerLookAheadMeters));
        Gizmos.matrix = Matrix4x4.identity;
    }

    private void OpenTraceLog()
    {
        if (!writeTrafficTraceLog || traceLogWriter != null)
        {
            return;
        }

        try
        {
            string projectRoot = Directory.GetParent(Application.dataPath).FullName;
            string logDirectory = Path.Combine(projectRoot, "Logs");
            Directory.CreateDirectory(logDirectory);
            string safeName = MakeSafeFileName(name);
            traceLogPath = Path.Combine(logDirectory, $"TrafficTrace_{safeName}_{System.DateTime.Now:yyyyMMdd_HHmmss}.log");
            traceLogWriter = new StreamWriter(traceLogPath, false, Encoding.UTF8);
            traceLogWriter.AutoFlush = true;
            WriteTraceLine($"Traffic trace started for {name}");
            WriteTraceLine($"Unity time={System.DateTime.Now:O}");
            WriteTraceLine($"Scene object path={GetTransformPath(transform)}");
            WriteTraceLine($"Initial position={FormatVector(transform.position)} rotation={FormatVector(transform.eulerAngles)} scale={FormatVector(transform.lossyScale)}");
        }
        catch (System.Exception exception)
        {
            traceLogPath = "";
            traceLogWriter = null;
            Debug.LogWarning($"Could not open traffic trace log for {name}: {exception.Message}", this);
        }
    }

    private void WriteTraceFrame()
    {
        if (traceLogWriter == null || Time.time < nextTraceLogTime)
        {
            return;
        }

        nextTraceLogTime = Time.time + Mathf.Max(0.02f, traceLogIntervalSeconds);

        StringBuilder builder = new StringBuilder();
        builder.AppendLine("----- Traffic Frame -----");
        builder.AppendLine($"time={Time.time:0.000} fixedTime={Time.fixedTime:0.000} frame={Time.frameCount}");
        builder.AppendLine($"car={name} pos={FormatVector(rb.position)} rot={FormatVector(rb.rotation.eulerAngles)} forward={FormatVector(transform.forward)} moveDelta={FormatVector(lastMoveDelta)}");
        builder.AppendLine($"speedMph={CurrentSpeedMph:0.00} accelMps2={currentAccelerationMetersPerSecond:0.00} baseDesiredMph={MetersPerSecondToMph(lastBaseDesiredSpeed):0.00} finalDesiredMph={MetersPerSecondToMph(lastFinalDesiredSpeed):0.00}");
        builder.AppendLine($"slowdown={(string.IsNullOrEmpty(slowdownReason) ? "none" : slowdownReason)} blockerFound={lastBlockerFound} blockerName={(string.IsNullOrEmpty(lastBlockerName) ? "none" : lastBlockerName)} blockerDistance={lastBlockerDistance:0.00} blockerBrakeFactor={lastBlockerBrakeFactor:0.00} triedLaneChangeForBlocker={lastTriedLaneChangeForBlocker}");
        builder.AppendLine($"intersectionNeeded={lastNeededIntersectionPermission} intersectionReserved={lastReservedIntersection} reservedLane={LaneName(reservedIntersectionLane)} pendingExitLane={LaneName(pendingIntersectionExitLane)}");
        builder.AppendLine($"approachLimitMph={FormatMphLimit(lastApproachSpeedLimit)} stopLimitMph={FormatMphLimit(lastStopApproachSpeedLimit)}");
        builder.AppendLine($"currentLane={DescribeLane(currentLane, laneDistance)}");
        builder.AppendLine($"plannedNext={DescribeLane(plannedNextLane, 0f)}");
        builder.AppendLine($"changing={isChangingLanes} from={LaneName(laneChangeFromLane)} to={LaneName(laneChangeToLane)} progress={laneChangeProgress:0.00}/{laneChangeLengthMeters:0.00} startDistance={laneChangeStartDistance:0.00} targetStartDistance={laneChangeTargetStartDistance:0.00}");
        builder.AppendLine($"lookAhead={lastLookAheadDistance:0.00} targetPoint={FormatVector(lastTargetPoint)} toTarget={FormatVector(lastToTarget)} targetDistance={lastToTarget.magnitude:0.00} signedTurnAngle={lastTurnAngleToTarget:0.00}");
        builder.AppendLine("nextLanes=" + DescribeNextLanes(currentLane));
        builder.AppendLine("blockerSensorHits:");
        builder.AppendLine(lastBlockerHitDetails);
        WriteTraceLine(builder.ToString());
    }

    private void WriteTrafficSetupSnapshot()
    {
        if (traceLogWriter == null || trafficSystem == null)
        {
            return;
        }

        StringBuilder builder = new StringBuilder();
        builder.AppendLine("===== Traffic Setup Snapshot =====");
        builder.AppendLine($"trafficSystem={trafficSystem.name} path={GetTransformPath(trafficSystem.transform)} laneCount={trafficSystem.Lanes.Count}");
        builder.AppendLine($"carSettings fallbackMph={fallbackSpeedLimitMph:0.0} speedVarianceMph={speedVarianceMph:0.0} accelMphPerSecond={accelerationMphPerSecond:0.0} brakingMphPerSecond={brakingMphPerSecond:0.0} jerk={jerkMetersPerSecondCubed:0.0} turnRate={turnRateDegreesPerSecond:0.0}");
        builder.AppendLine($"blockerSettings mask={blockingMask.value} lookAhead={blockerLookAheadMeters:0.0} brakeDistance={blockerBrakeDistanceMeters:0.0} stopBuffer={blockedStopBufferMeters:0.0} hardStopDistance={blockedHardStopDistanceMeters:0.0} boxHalfExtents={FormatVector(blockerBoxHalfExtents)}");
        builder.AppendLine($"intersectionSettings requestDistance={intersectionRequestDistance:0.0} planDistance={nextLanePlanDistance:0.0} slowdownDistance={intersectionSlowdownDistance:0.0} fullStopDistance={fullStopDistance:0.0} straightMph={straightIntersectionMph:0.0} mildMph={mildTurnMph:0.0} sharpMph={sharpTurnMph:0.0}");
        builder.AppendLine($"laneChangeSettings allow={allowLaneChanges} cruising={allowCruisingLaneChanges} length={laneChangeLengthMeters:0.0} clearance={laneChangeClearanceMeters:0.0} cooldown={laneChangeCooldownSeconds:0.0} noCruiseNearEnd={noCruisingLaneChangeNearLaneEndMeters:0.0}");

        foreach (TrafficLane lane in trafficSystem.Lanes)
        {
            builder.AppendLine(DescribeLane(lane, 0f));
            builder.AppendLine("  next=" + DescribeNextLanes(lane));
        }

        WriteTraceLine(builder.ToString());
    }

    private void WriteTraceLine(string message)
    {
        if (traceLogWriter == null)
        {
            return;
        }

        traceLogWriter.WriteLine(message);
    }

    private string DescribeLane(TrafficLane lane, float distance)
    {
        if (lane == null)
        {
            return "None";
        }

        return $"{lane.name} distance={distance:0.00}/{lane.Length:0.00} distanceToEnd={Mathf.Max(0f, lane.Length - distance):0.00} point={FormatVector(lane.GetPoint(distance))} forward={FormatVector(lane.GetForward(distance))} start={FormatVector(lane.GetStartPoint())} end={FormatVector(lane.GetEndPoint())} startForward={FormatVector(lane.GetStartForward())} endForward={FormatVector(lane.GetEndForward())} speedLimitMph={lane.SpeedLimitMph:0.0}";
    }

    private string DescribeNextLanes(TrafficLane lane)
    {
        if (lane == null)
        {
            return "None";
        }

        StringBuilder builder = new StringBuilder();
        builder.Append(lane.NextLanes.Count);
        builder.Append(" [");

        for (int i = 0; i < lane.NextLanes.Count; i++)
        {
            if (i > 0)
            {
                builder.Append(", ");
            }

            builder.Append(LaneName(lane.NextLanes[i]));
        }

        builder.Append("]");
        return builder.ToString();
    }

    private string FormatMphLimit(float metersPerSecond)
    {
        return float.IsPositiveInfinity(metersPerSecond)
            ? "unlimited"
            : $"{MetersPerSecondToMph(metersPerSecond):0.00}";
    }

    private float MetersPerSecondToMph(float metersPerSecond)
    {
        return metersPerSecond / MphToMetersPerSecond;
    }

    private string FormatVector(Vector3 value)
    {
        return $"({value.x:0.00}, {value.y:0.00}, {value.z:0.00})";
    }

    private string MakeSafeFileName(string value)
    {
        StringBuilder builder = new StringBuilder(value.Length);
        char[] invalidCharacters = Path.GetInvalidFileNameChars();

        foreach (char character in value)
        {
            builder.Append(System.Array.IndexOf(invalidCharacters, character) >= 0 ? '_' : character);
        }

        return builder.Length > 0 ? builder.ToString() : "TrafficCar";
    }

    private string GetTransformPath(Transform target)
    {
        if (target == null)
        {
            return "";
        }

        StringBuilder builder = new StringBuilder(target.name);
        Transform parent = target.parent;

        while (parent != null)
        {
            builder.Insert(0, parent.name + "/");
            parent = parent.parent;
        }

        return builder.ToString();
    }

    private void OnDisable()
    {
        if (traceLogWriter == null)
        {
            return;
        }

        WriteTraceLine($"Traffic trace ended for {name} at time={Time.time:0.000}");
        traceLogWriter.Dispose();
        traceLogWriter = null;
    }
}
