using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class FlipbookPlayer : MonoBehaviour {
    [SerializeField] private Sprite[] pages = {};
    [SerializeField] private Sprite[] subpages = {};
    [SerializeField] private float showTime = 1.5f;
    [SerializeField] private float fadeTime = 0.5f;
    [SerializeField] private float animateSubpageTime = 0.5f;

    [SerializeField] private CanvasGroup group;
    [SerializeField] private Image image, prevImage;
    [SerializeField] private Button button;

    [SerializeField] private AudioClip clip;

    public bool ended = false;
    private int current = 0;

    private float subTime = 0f;
    private bool isSubPage = false;

    void Awake() {
        ended = false;
        current = 0;
        group.alpha = 1;
        image.sprite = pages[0];
        button.onClick.AddListener(Clicked);
    }

    void Start() {
        StartCoroutine(INext());
    }

    void Update() {
        subTime += Time.deltaTime;
        if(subTime > animateSubpageTime && HasSubPage()) {
            subTime = 0f;
            isSubPage = !isSubPage;
            image.sprite = isSubPage ? subpages[current] : pages[current];
        }
    }

    private bool HasSubPage() {
        if (subpages.Length <= current) return false;
        return subpages[current] is not null;
    }


    public void End() {
        StopAllCoroutines();
        current = pages.Length - 1;
        image.sprite = pages[pages.Length - 1];
        group.alpha = 1f;
    }

    private void Clicked() {
        if (ended) return;
        StopAllCoroutines();
        group.alpha = 1;
        StartCoroutine(INext());
    }

    IEnumerator INext() {
        current++;
        subTime = 0f;
        isSubPage = false;
        if (current >= pages.Length) {
            ended = true;
            yield break;
        }
        else AudioControl.Broadcast(clip);

        prevImage.sprite = pages[current - 1];
        group.alpha = 0;
        image.sprite = pages[current];

        float t = 0f;
        while(t < fadeTime) {
            yield return null;
            t += Time.deltaTime;
            group.alpha = t / fadeTime;
        }
        group.alpha = 1;

        yield return new WaitForSeconds(showTime);
        if(!ended) StartCoroutine(INext());
    }
}
