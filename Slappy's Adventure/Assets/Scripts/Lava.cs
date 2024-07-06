using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Lava : MonoBehaviour {
    private const float SWORD_VELOCITY = 35f;

    [Header("Effects")]
    [SerializeField] private GameObject lavaSplashFx;
    [SerializeField] private GameObject playerBurnFx;

    [Header("Sounds")]
    [SerializeField] private AudioClip swordhitSound;

    private float hitCooldown = 0f;

    private void OnCollisionEnter(Collision collision) {
        if (collision.gameObject.CompareTag("Sword")) {
            Rigidbody rigid = GameControl.main.player.sword.rigid;
            Vector3 yeet = -collision.GetContact(0).normal;

            if (hitCooldown < Time.timeSinceLevelLoad + 0.2f) {
                Fx(lavaSplashFx, collision.GetContact(0).point, Quaternion.LookRotation(yeet));
                hitCooldown = Time.timeSinceLevelLoad;
            }
            rigid.velocity = yeet * SWORD_VELOCITY;
        }
        else if (collision.gameObject.CompareTag("Player")) {
            //todo
        }
    }

    //todo pool fx
    public void Fx(GameObject fx) {
        Fx(fx, transform.position, transform.rotation);
    }

    public void Fx(GameObject fx, Vector3 position, Quaternion rotation) {
        if (fx == null) return;
        Instantiate(fx, position, rotation);
    }
}
