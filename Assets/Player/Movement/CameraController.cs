using UnityEngine;

public class CameraController : MonoBehaviour
{
    public Transform playerBody;
    public PostProcessingManager postProcessingManager;

    [Header("Field of View Settings")]
    public float defaultFOV = 60f;
    public float flashModeFOV = 75f;
    public float fovChangeSpeed = 2f;

    private float xRotation = 0f;
    private Camera cam;
    private PlayerControls controls;

    void Start()
    {
        LockCursor();
        cam = GetComponent<Camera>();
        cam.fieldOfView = defaultFOV;
        controls = GetComponentInParent<PlayerControls>();

        if (postProcessingManager == null)
        {
            postProcessingManager = FindObjectOfType<PostProcessingManager>();
            if (postProcessingManager == null)
            {
                Debug.LogError("PostProcessingManager not found in the scene!");
            }
        }
    }

    void Update()
    {
        HandleMouseLook();
        HandleFlashModeEffects();
    }

    private void LockCursor()
    {
        Cursor.lockState = CursorLockMode.Locked;
    }

    private void HandleMouseLook()
    {
        float mouseX = controls.GetMouseX();
        float mouseY = controls.GetMouseY();

        xRotation -= mouseY;
        xRotation = Mathf.Clamp(xRotation, -90f, 90f);

        transform.localRotation = Quaternion.Euler(xRotation, 0f, 0f);
        playerBody.Rotate(Vector3.up * mouseX);
    }

    private void HandleFlashModeEffects()
    {
        if (controls.IsFlashModeActive())
        {
            postProcessingManager.IncreaseChromaticAberration();
            IncreaseFOV();
        }
        else
        {
            postProcessingManager.DecreaseChromaticAberration();
            DecreaseFOV();
        }
    }

    private void IncreaseFOV()
    {
        cam.fieldOfView = Mathf.Lerp(cam.fieldOfView, flashModeFOV, fovChangeSpeed * Time.deltaTime);
    }

    private void DecreaseFOV()
    {
        cam.fieldOfView = Mathf.Lerp(cam.fieldOfView, defaultFOV, fovChangeSpeed * Time.deltaTime);
    }
}