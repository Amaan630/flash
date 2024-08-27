using UnityEngine;

public class DayNightCycle : MonoBehaviour
{
    [Tooltip("How many minutes in real-time should represent one hour in-game")]
    public float minutesPerHour = 1f;

    [Tooltip("The hour to start the day (0-23)")]
    public int startHour = 6;

    private float timeElapsed = 0f;
    private float rotationSpeed;

    void Start()
    {
        // Set initial rotation based on start hour
        transform.rotation = Quaternion.Euler((startHour / 24f) * 360f - 90f, 170f, 0);

        // Calculate rotation speed
        // We want to complete a full 360 degree rotation in 24 game hours
        rotationSpeed = 360f / (24f * minutesPerHour * 60f);
    }

    void Update()
    {
        timeElapsed += Time.deltaTime;
        float rotationAmount = timeElapsed * rotationSpeed;

        transform.rotation = Quaternion.Euler(rotationAmount - 90f, 170f, 0);

        // Reset timeElapsed if we've completed a full day
        if (timeElapsed >= 24f * minutesPerHour * 60f)
        {
            timeElapsed = 0f;
        }
    }

    public float GetCurrentHour()
    {
        return (timeElapsed / (minutesPerHour * 60f) + startHour) % 24f;
    }
}