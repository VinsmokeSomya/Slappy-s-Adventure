using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "LevelCollection", menuName = "Level Collection", order = 200)]
public class LevelCollection : ScriptableObject {
    public Level[] levels;

    public int GetGemSum() {
        int sum = 0;
        foreach (Level level in levels) {
            sum += LevelUtils.GetGems(level.id);
        }

        return sum;
    }
}
