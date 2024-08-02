using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PostProcessingManager : MonoBehaviour
{
    public Volume globalVolume;
    
    [Header("Chromatic Aberration Settings")]
    public float defaultChromaticAberration = 0f;
    public float flashModeChromaticAberration = 1f;
    public float chromaticAberrationChangeSpeed = 4f;

    private ChromaticAberration chromaticAberration;

    void Start()
    {
        if (globalVolume == null)
        {
            globalVolume = GameObject.Find("Global Volume").GetComponent<Volume>();
        }

        if (globalVolume != null && globalVolume.profile.TryGet(out chromaticAberration))
        {
            chromaticAberration.intensity.value = defaultChromaticAberration;
        }
        else
        {
            Debug.LogError("ChromaticAberration effect not found in the Volume Profile!");
        }
    }

    public void IncreaseChromaticAberration()
    {
        if (chromaticAberration != null)
        {
            chromaticAberration.intensity.value = Mathf.Lerp(chromaticAberration.intensity.value, flashModeChromaticAberration, chromaticAberrationChangeSpeed * Time.deltaTime);
        }
    }

    public void DecreaseChromaticAberration()
    {
        if (chromaticAberration != null)
        {
            chromaticAberration.intensity.value = Mathf.Lerp(chromaticAberration.intensity.value, defaultChromaticAberration, chromaticAberrationChangeSpeed * Time.deltaTime);
        }
    }
}