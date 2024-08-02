using UnityEngine;

public class PlayerControls : MonoBehaviour
{
    [System.Serializable]
    public class KeyboardControls
    {
        public KeyCode forward = KeyCode.W;
        public KeyCode backward = KeyCode.S;
        public KeyCode strafeLeft = KeyCode.A;
        public KeyCode strafeRight = KeyCode.D;
        public KeyCode run = KeyCode.LeftControl;
        public KeyCode flashMode = KeyCode.LeftShift;
        public KeyCode slowMotion = KeyCode.Space;
    }

    [System.Serializable]
    public class MouseControls
    {
        public float sensitivityX = 2f;
        public float sensitivityY = 2f;
    }

    public KeyboardControls keyboard;
    public MouseControls mouse;

    public bool IsMovingForward() => Input.GetKey(keyboard.forward);
    public bool IsMovingBackward() => Input.GetKey(keyboard.backward);
    public bool IsStrafingLeft() => Input.GetKey(keyboard.strafeLeft);
    public bool IsStrafingRight() => Input.GetKey(keyboard.strafeRight);
    public bool IsRunning() => Input.GetKey(keyboard.run);
    public bool IsFlashModeActive() => Input.GetKey(keyboard.flashMode);
    public bool IsSlowMotionActive() => Input.GetKey(keyboard.slowMotion);

    public float GetMouseX() => Input.GetAxis("Mouse X") * mouse.sensitivityX;
    public float GetMouseY() => Input.GetAxis("Mouse Y") * mouse.sensitivityY;

    public bool IsMoving() => IsMovingForward() || IsMovingBackward() || IsStrafingLeft() || IsStrafingRight();

    public Vector3 GetMovementVector()
    {
        Vector3 movement = Vector3.zero;
        if (IsMovingForward()) movement += Vector3.forward;
        if (IsMovingBackward()) movement += Vector3.back;
        if (IsStrafingLeft()) movement += Vector3.left;
        if (IsStrafingRight()) movement += Vector3.right;
        return movement.normalized;
    }
}