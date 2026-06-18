using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

[DisallowMultipleComponent]
[RequireComponent(typeof(FlashTimeController))]
[DefaultExecutionOrder(100)]
public class FlashRunMusicController : MonoBehaviour
{
    private const float MinimumPitch = 0.05f;

    [Header("Tracks")]
    [SerializeField] private AudioSource musicSource;
    [SerializeField] private AudioClip[] flashRunTracks = new AudioClip[0];
    [SerializeField] private bool preloadTracksOnAwake = true;
    [SerializeField] private bool waitForPreloadedAudio = true;
    [SerializeField, Range(0f, 1f)] private float maxVolume = 0.8f;
    [SerializeField, Min(0f)] private float fadeInSeconds = 0.35f;
    [SerializeField, Min(0f)] private float fadeOutSeconds = 5f;

    [Header("Flash Time")]
    [SerializeField] private bool slowMusicDuringFlashTime = true;
    [SerializeField, Range(MinimumPitch, 1f)] private float flashTimePitch = 0.65f;
    [SerializeField, Min(0f)] private float pitchBlendSeconds = 0.25f;

#if UNITY_EDITOR
    [Header("Editor Setup")]
    [SerializeField] private bool autoLoadDefaultTracks = true;
#endif

    private FlashTimeController flashTimeController;
    private AudioSource audioSource;
    private bool wasInFlashMode;
    private int lastTrackIndex = -1;

    private void Awake()
    {
        flashTimeController = GetComponent<FlashTimeController>();
        EnsureAudioSource();
        ConfigureAudioSource();

#if UNITY_EDITOR
        AutoLoadDefaultTracksIfNeeded();
#endif

        if (preloadTracksOnAwake)
        {
            PreloadTracks();
        }
    }

    private void OnDisable()
    {
        if (audioSource == null)
        {
            return;
        }

        audioSource.Stop();
        audioSource.volume = 0f;
        audioSource.pitch = 1f;
        wasInFlashMode = false;
    }

    private void Update()
    {
        if (flashTimeController == null || audioSource == null)
        {
            return;
        }

        bool isInFlashMode = flashTimeController.IsInFlashMode;

        if (isInFlashMode)
        {
            if (!wasInFlashMode)
            {
                StartOrResumeFlashRunMusic();
            }

            UpdateActiveMusic();
        }
        else
        {
            FadeOutMusic();
        }

        wasInFlashMode = isInFlashMode;
    }

    private void StartOrResumeFlashRunMusic()
    {
        if (!HasPlayableTracks())
        {
            return;
        }

        if (!audioSource.isPlaying)
        {
            PlayRandomTrack(true);
        }
    }

    private void UpdateActiveMusic()
    {
        if (!HasPlayableTracks())
        {
            return;
        }

        if (!audioSource.isPlaying)
        {
            PlayRandomTrack(audioSource.clip == null);
        }

        float deltaTime = Time.unscaledDeltaTime;
        audioSource.volume = MoveTowards(audioSource.volume, maxVolume, maxVolume, fadeInSeconds, deltaTime);
        audioSource.pitch = MoveTowards(audioSource.pitch, GetTargetPitch(), 1f, pitchBlendSeconds, deltaTime);
    }

    private void FadeOutMusic()
    {
        if (!audioSource.isPlaying)
        {
            audioSource.pitch = 1f;
            return;
        }

        float deltaTime = Time.unscaledDeltaTime;
        audioSource.volume = MoveTowards(audioSource.volume, 0f, maxVolume, fadeOutSeconds, deltaTime);
        audioSource.pitch = MoveTowards(audioSource.pitch, 1f, 1f, pitchBlendSeconds, deltaTime);

        if (audioSource.volume <= 0.001f)
        {
            audioSource.Stop();
            audioSource.clip = null;
            audioSource.pitch = 1f;
        }
    }

    private void PlayRandomTrack(bool fadeIn)
    {
        int trackIndex = GetRandomTrackIndex();
        if (trackIndex < 0)
        {
            return;
        }

        lastTrackIndex = trackIndex;
        audioSource.clip = flashRunTracks[trackIndex];
        audioSource.volume = fadeIn ? 0f : maxVolume;
        audioSource.pitch = GetTargetPitch();
        audioSource.Play();
    }

    private int GetRandomTrackIndex()
    {
        List<int> playableIndexes = new List<int>();

        for (int i = 0; i < flashRunTracks.Length; i++)
        {
            if (IsTrackPlayable(flashRunTracks[i]))
            {
                playableIndexes.Add(i);
            }
        }

        if (playableIndexes.Count == 0)
        {
            return -1;
        }

        if (playableIndexes.Count == 1)
        {
            return playableIndexes[0];
        }

        int randomPlayableIndex = Random.Range(0, playableIndexes.Count);
        int selectedTrackIndex = playableIndexes[randomPlayableIndex];

        if (selectedTrackIndex == lastTrackIndex)
        {
            selectedTrackIndex = playableIndexes[(randomPlayableIndex + 1) % playableIndexes.Count];
        }

        return selectedTrackIndex;
    }

    private bool HasPlayableTracks()
    {
        if (flashRunTracks == null)
        {
            return false;
        }

        for (int i = 0; i < flashRunTracks.Length; i++)
        {
            if (IsTrackPlayable(flashRunTracks[i]))
            {
                return true;
            }
        }

        return false;
    }

    private bool HasAssignedTracks()
    {
        if (flashRunTracks == null)
        {
            return false;
        }

        for (int i = 0; i < flashRunTracks.Length; i++)
        {
            if (flashRunTracks[i] != null)
            {
                return true;
            }
        }

        return false;
    }

    private bool IsTrackPlayable(AudioClip track)
    {
        if (track == null)
        {
            return false;
        }

        if (!waitForPreloadedAudio)
        {
            return true;
        }

        return track.loadState == AudioDataLoadState.Loaded;
    }

    private void PreloadTracks()
    {
        if (flashRunTracks == null)
        {
            return;
        }

        for (int i = 0; i < flashRunTracks.Length; i++)
        {
            AudioClip track = flashRunTracks[i];
            if (track != null && track.loadState == AudioDataLoadState.Unloaded)
            {
                track.LoadAudioData();
            }
        }
    }

    private float GetTargetPitch()
    {
        if (slowMusicDuringFlashTime && flashTimeController.IsInSlowMotion)
        {
            return Mathf.Max(MinimumPitch, flashTimePitch);
        }

        return 1f;
    }

    private float MoveTowards(float current, float target, float fullRange, float duration, float deltaTime)
    {
        if (duration <= 0f)
        {
            return target;
        }

        return Mathf.MoveTowards(current, target, (fullRange / duration) * deltaTime);
    }

    private void ConfigureAudioSource()
    {
        if (audioSource == null)
        {
            return;
        }

        audioSource.playOnAwake = false;
        audioSource.loop = false;
        audioSource.spatialBlend = 0f;
        audioSource.volume = 0f;
    }

    private void EnsureAudioSource()
    {
        audioSource = musicSource;

        if (audioSource == null)
        {
            audioSource = gameObject.AddComponent<AudioSource>();
            musicSource = audioSource;
        }
    }

#if UNITY_EDITOR
    private void Reset()
    {
        EnsureAudioSource();
        ConfigureAudioSource();
        AutoLoadDefaultTracksIfNeeded();
    }

    private void OnValidate()
    {
        maxVolume = Mathf.Clamp01(maxVolume);
        flashTimePitch = Mathf.Clamp(flashTimePitch, MinimumPitch, 1f);
        fadeInSeconds = Mathf.Max(0f, fadeInSeconds);
        fadeOutSeconds = Mathf.Max(0f, fadeOutSeconds);
        pitchBlendSeconds = Mathf.Max(0f, pitchBlendSeconds);
        AutoLoadDefaultTracksIfNeeded();
    }

    private void AutoLoadDefaultTracksIfNeeded()
    {
        if (!autoLoadDefaultTracks || HasAssignedTracks())
        {
            return;
        }

        AudioClip[] defaultTracks =
        {
            AssetDatabase.LoadAssetAtPath<AudioClip>("Assets/Music/closing-the-wormhole-the-flash.mp3"),
            AssetDatabase.LoadAssetAtPath<AudioClip>("Assets/Music/no-time-the-flash.mp3"),
            AssetDatabase.LoadAssetAtPath<AudioClip>("Assets/Music/the-fastest-man-alive-the-flash.mp3")
        };

        List<AudioClip> loadedTracks = new List<AudioClip>();
        for (int i = 0; i < defaultTracks.Length; i++)
        {
            if (defaultTracks[i] != null)
            {
                loadedTracks.Add(defaultTracks[i]);
            }
        }

        if (loadedTracks.Count == 0)
        {
            return;
        }

        flashRunTracks = loadedTracks.ToArray();

        if (!Application.isPlaying)
        {
            EditorUtility.SetDirty(this);
        }
    }
#endif
}
