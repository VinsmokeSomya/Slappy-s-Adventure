using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class VoiceClip {
    public AudioClip[] clips;
    [Range(0f, 1f)] public float playChance = 1f;

    public AudioClip Pick() {
        return clips[Random.Range(0, clips.Length)];
    }

    public bool ShouldPlay() {
        return Random.Range(0f, 1f) <= playChance;
    }

    public void VoiceOneShot(AudioSource source) {
        if (ShouldPlay()) source.PlayOneShot(Pick());
    }
}
