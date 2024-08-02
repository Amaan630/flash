using UnityEngine;

public class PlayerController : MonoBehaviour
{
    [Header("MOUSE LOOK")]
    public Vector2 verticalLookLimit = new Vector2(-85, 85);
    public float smooth = 0.5f;

    private float xRot;
    public Transform cam;

    [Header("MOVEMENT")]
    public bool physicsController = false;
    public float walkSpeed = 1;
    public float runSpeed = 3;
    private float currentSpeed;

    [Header("SIGHT")]
    public bool sight = true;
    public GameObject sightPrefab;

    public bool hideCursor = false;

    private CharacterController controller;
    private Animator camAnimator;
    private string lastAnim;
    private string curAnim;

    private FlashTimeController flashTimeController;
    private PlayerControls controls;

    private Vector3 velocity;

    public float GetCurrentSpeed()
    {
        return velocity.magnitude;
    }

    private void OnDisable()
    {
        Cursor.visible = true;
    }

    void Start()
    {
        controller = GetComponent<CharacterController>();
        camAnimator = GetComponentInChildren<Camera>().GetComponent<Animator>();
        flashTimeController = GetComponent<FlashTimeController>();
        controls = GetComponent<PlayerControls>();

        if (hideCursor)
        {
            Cursor.visible = false;
            Cursor.lockState = CursorLockMode.Locked;
        }
        else
        {
            Cursor.visible = true;
            Cursor.lockState = CursorLockMode.None;
        }

        if (sight)
        {
            GameObject sightObj = Instantiate(sightPrefab);
            sightObj.transform.SetParent(transform.parent);
        }
    }

    void Update()
    {
        CameraLook();
        HandleMovementInput();
        HandleFlashMode();
        flashTimeController.UpdateFOV();
    }

    float refVelX;
    float refVelY;
    float xRotSmooth;
    float yRotSmooth;

    void CameraLook()
    {
        float mouseX = controls.GetMouseX();
        float mouseY = controls.GetMouseY();

        xRot -= mouseY;
        xRot = Mathf.Clamp(xRot, verticalLookLimit.x, verticalLookLimit.y);

        xRotSmooth = Mathf.SmoothDamp(xRotSmooth, xRot, ref refVelX, smooth);
        yRotSmooth = Mathf.SmoothDamp(yRotSmooth, mouseX, ref refVelY, smooth);

        cam.localRotation = Quaternion.Euler(xRotSmooth, 0, 0);
        transform.Rotate(Vector3.up * yRotSmooth);
    }

    void HandleMovementInput()
    {
        if (flashTimeController.IsInFlashMode)
        {
            currentSpeed = flashTimeController.GetCurrentSpeed(walkSpeed);
        }
        else if (controls.IsRunning())
        {
            currentSpeed = runSpeed;
        }
        else
        {
            currentSpeed = walkSpeed;
        }

        if (controls.IsMoving())
        {
            curAnim = currentSpeed > walkSpeed ? "CamShakeRun" : "CamShakeWalk";
        }
        else
        {
            curAnim = "CamShakeIdle";
        }

        if (curAnim != lastAnim)
        {
            camAnimator.CrossFadeInFixedTime(curAnim, 0.3f);
        }

        lastAnim = curAnim;
    }

    void HandleFlashMode()
    {
        bool isMoving = controls.IsMoving();

        if (controls.IsFlashModeActive())
        {
            flashTimeController.ActivateFlashMode(isMoving);
            
            if (!isMoving)
            {
                flashTimeController.ToggleSlowMotion(true);
            }
            else if (controls.IsSlowMotionActive())
            {
                flashTimeController.ToggleSlowMotion(true);
            }
            else
            {
                flashTimeController.ToggleSlowMotion(false);
            }
        }
        else
        {
            flashTimeController.DeactivateFlashMode();
        }
    }

    private void FixedUpdate()
    {
        Vector3 moveDirection = controls.GetMovementVector();
        
        // Convert movement from local space to world space based on camera orientation
        moveDirection = transform.TransformDirection(moveDirection);
        
        // Remove any vertical component to keep movement on the horizontal plane
        moveDirection.y = 0;
        moveDirection.Normalize();

        velocity = moveDirection * currentSpeed;

        controller.Move(moveDirection * currentSpeed * 0.01f);

        if (!controller.isGrounded)
        {
            if (Physics.SphereCast(transform.position, controller.radius, -transform.up, out RaycastHit hitInfo, 50, -1, QueryTriggerInteraction.Ignore))
            {
                transform.position = new Vector3(transform.position.x, hitInfo.point.y + controller.height / 2 + controller.skinWidth, transform.position.z);
            }
        }
    }
}