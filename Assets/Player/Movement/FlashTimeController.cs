using UnityEngine;

public class FlashTimeController : MonoBehaviour
{
    public float maxSuperSpeed = 10f;
    public float minSuperSpeed = 5f;
    public float acceleration = 5f;
    public float timeSlowFactor = 0.1f;
    public float normalTimeScale = 1f;

    [Header("Time Transition Settings")]
    public float timeScaleTransitionSeconds = 0.15f;

    public float chromaticAberrationSpeed = 10f;

    [Header("Field of View Settings")]
    public float defaultFOV = 60f;
    public float flashModeFOV = 90f;
    public float fovChangeSpeed = 10f;

    private bool isInFlashMode = false;
    private bool isInSlowMotion = false;
    private float currentSuperSpeed;
    private float lastFlashActivationTime;
    private float baseFixedDeltaTime = 0.02f;
    private float targetTimeScale = 1f;

    private Camera playerCamera;
    private PostProcessingManager postProcessingManager;

    public bool IsInFlashMode => isInFlashMode;
    public bool IsInSlowMotion => isInSlowMotion;

    private void Awake()
    {
        baseFixedDeltaTime = Time.timeScale > 0f ? Time.fixedDeltaTime / Time.timeScale : Time.fixedDeltaTime;
        targetTimeScale = normalTimeScale;
    }

    private void Start()
    {
        playerCamera = Camera.main;
        if (playerCamera == null)
        {
            Debug.LogError("No main camera found!");
        }

        postProcessingManager = FindObjectOfType<PostProcessingManager>();
        if (postProcessingManager == null)
        {
            Debug.LogError("PostProcessingManager not found in the scene!");
        }
    }

    private void Update()
    {
        UpdateTimeScaleTransition();
    }

    private void OnDisable()
    {
        isInFlashMode = false;
        isInSlowMotion = false;
        targetTimeScale = normalTimeScale;
        SetTimeScaleImmediate(normalTimeScale);
    }

    public void ActivateFlashMode(bool isMoving)
    {
        if (!isInFlashMode)
        {
            currentSuperSpeed = minSuperSpeed;
            lastFlashActivationTime = Time.time;
        }
        isInFlashMode = true;
        UpdateTimeScale(isMoving);
    }

    public void DeactivateFlashMode()
    {
        isInFlashMode = false;
        isInSlowMotion = false;
        SetTargetTimeScale(normalTimeScale);
        UpdateChromaticAberration(0f);
    }

    public void ToggleSlowMotion(bool slowMotionActive)
    {
        isInSlowMotion = slowMotionActive && isInFlashMode;
        UpdateTimeScale(true);
    }

    private void UpdateTimeScale(bool isMoving)
    {
        if (isInFlashMode)
        {
            if (isInSlowMotion || !isMoving)
            {
                SetTargetTimeScale(timeSlowFactor);
                UpdateChromaticAberration(1f);
            }
            else
            {
                SetTargetTimeScale(normalTimeScale);
                UpdateChromaticAberration(0.5f);
            }
        }
        else
        {
            SetTargetTimeScale(normalTimeScale);
            UpdateChromaticAberration(0f);
        }
    }

    private void SetTargetTimeScale(float scale)
    {
        targetTimeScale = Mathf.Max(0.0001f, scale);
    }

    private void UpdateTimeScaleTransition()
    {
        if (Mathf.Approximately(Time.timeScale, targetTimeScale))
        {
            SetTimeScaleImmediate(targetTimeScale);
            return;
        }

        if (timeScaleTransitionSeconds <= 0f)
        {
            SetTimeScaleImmediate(targetTimeScale);
            return;
        }

        float transitionRange = Mathf.Max(Mathf.Abs(normalTimeScale - timeSlowFactor), 0.01f);
        float nextTimeScale = Mathf.MoveTowards(Time.timeScale, targetTimeScale, transitionRange / timeScaleTransitionSeconds * Time.unscaledDeltaTime);
        SetTimeScaleImmediate(nextTimeScale);
    }

    private void SetTimeScaleImmediate(float scale)
    {
        Time.timeScale = scale;
        Time.fixedDeltaTime = baseFixedDeltaTime * Time.timeScale;
    }

    private void UpdateChromaticAberration(float targetIntensity)
    {
        if (postProcessingManager != null)
        {
            if (targetIntensity > 0)
            {
                postProcessingManager.IncreaseChromaticAberration();
            }
            else
            {
                postProcessingManager.DecreaseChromaticAberration();
            }
        }
    }

    public float GetCurrentSpeed(float baseSpeed)
    {
        if (isInFlashMode)
        {
            float accelerationTime = Time.time - lastFlashActivationTime;
            currentSuperSpeed = Mathf.Min(minSuperSpeed + acceleration * accelerationTime, maxSuperSpeed);
            return isInSlowMotion ? currentSuperSpeed * timeSlowFactor : currentSuperSpeed;
        }
        return baseSpeed;
    }

    public float GetSpeedMultiplier(float baseSpeed)
    {
        return GetCurrentSpeed(baseSpeed) / baseSpeed;
    }

    public void UpdateFOV()
    {
        if (playerCamera != null)
        {
            float targetFOV = isInFlashMode ? flashModeFOV : defaultFOV;
            playerCamera.fieldOfView = Mathf.MoveTowards(playerCamera.fieldOfView, targetFOV, fovChangeSpeed * Time.unscaledDeltaTime);
        }
    }
}
