using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

[CreateAssetMenu(fileName = "Level", menuName = "Level", order = 200)]
public class Level : ScriptableObject {
    public int id = -1;

    public string introScene;
    public string gameScene;
    public string endScene;
    public string trueEndScene;

    public int maxGems = 5;

    public GameObject previewPrefab;

    public bool alwaysUnlocked = false;
    public bool hidden = false;

    public UnlockCriteria unlocks;

    public bool IsHidden() {
        return hidden; //will be useful later for seasonal levels (probably)
    }

    public bool IsLocked(LevelCollection lc) {
        if(alwaysUnlocked) return false;

        int totalg = lc.GetGemSum();
        if(unlocks.totalMinGems > totalg) return true;

        foreach(Level l in unlocks.prevLevel) {
            if(!LevelUtils.GetCleared(l.id)) return true;
            if(unlocks.prevLevelMinGems > LevelUtils.GetGems(l.id)) return true;
        }

        return false;
    }

    [System.Serializable]
    public struct UnlockCriteria {
        public Level[] prevLevel;
        public int prevLevelMinGems;
        public int totalMinGems;
    }
}
